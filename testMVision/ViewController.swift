//
//  ViewController.swift
//  testMVision
//
//  Created by Tarek El Ghoul on 17/11/2019.
//  Copyright © 2019 Tarek El Ghoul. All rights reserved.
//

import UIKit
import Vision
import VisionKit
import TesseractOCR
import Alamofire
import SimplePDF
import SwiftyJSON

class ViewController: UIViewController, VNDocumentCameraViewControllerDelegate, G8TesseractDelegate {
    
    @IBOutlet var imageView: BoundingBoxImageView!
    @IBOutlet var textView: UITextView!
    @IBOutlet var scanButton: UIButton!
    @IBOutlet weak var pdfButton: UIButton!
    
    private var pdfFilePath: String?
    var imageCroped: UIImage?
    
    var textRecognitionRequest = VNRecognizeTextRequest(completionHandler: nil)
    private let textRecognitionWorkQueue = DispatchQueue(label: "TextRecognitionQueue", qos: .userInitiated, attributes: [], autoreleaseFrequency: .workItem)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        pdfButton.isHidden = true
        
        
        
        textView.textContainerInset = UIEdgeInsets(top: 10, left: 8, bottom: 10, right: 8)
        textView.layer.cornerRadius = 10.0
        
        imageView.layer.cornerRadius = 10.0
        scanButton.layer.cornerRadius = 10.0
        
        scanButton.addTarget(self, action: #selector(scanDocument), for: .touchUpInside)
    }
    
    func progressImageRecognition(for tesseract: G8Tesseract) {
        print("Recognition Progress \(tesseract.progress) %")
    }
    func performImageRecognition(_ image: UIImage){
        
        if let tesseract = G8Tesseract(language: "ara") {
            tesseract.engineMode = .cubeOnly
            tesseract.image = image
            tesseract.recognize()
            textView.text = tesseract.recognizedText
            
        }
        
    }
    func uploadImage(_ image : UIImage) {
        
        let imageData = image.jpegData(compressionQuality: 1)
                       Alamofire.upload(multipartFormData: { (MultipartFormData) in
                           MultipartFormData.append(imageData!, withName: "myImage", fileName: "image.jpeg", mimeType: "image/jpeg")
                       }, usingThreshold: SessionManager.multipartFormDataEncodingMemoryThreshold, to:"http://172.20.10.6:8000/"+"upload", method: .post, headers: nil) { (result: SessionManager.MultipartFormDataEncodingResult) in
                           switch result {
                           case .failure(let error):
                               print(error)
                           case . success(request: let upload, streamingFromDisk: _, streamFileURL: _):
                            let sv = UIViewController.displaySpinner(onView: self.view)
                                upload.responseJSON { response in
                                    
                                    let JsonResp = JSON(response.result.value)
                                    let textRec = JsonResp["text"].stringValue
                                    let imgDec = JsonResp["img"].stringValue
                                    self.textView.text = textRec
                                    if let decodeData = Data(base64Encoded: imgDec, options: .ignoreUnknownCharacters) {
                                        self.imageCroped = UIImage(data: decodeData)
                                    }
                                    
                                    self.pdfButton.isHidden = false
                                }
                            UIViewController.removeSpinner(spinner: sv)
                               upload.uploadProgress(closure: { (progress) in
                                   print(progress)
                               }
                                   
                               )}
                       }
        
    }
    
    func genereatePDF() -> String?{
        
    let a4PaperSize = CGSize(width: 595, height: 842)
    let pdf = SimplePDF(pageSize: a4PaperSize)
        pdf.setContentAlignment(.center)
        pdf.addText("Carte d'identité nationale", font: UIFont(name: "Courier", size: 70.0)!, textColor: .black)
        pdf.addLineSpace(30)
        pdf.setContentAlignment(.left)
        pdf.addLineSeparator()
        pdf.addLineSpace(20.0)
        let logoImage = imageCroped!
        pdf.addImage(logoImage)
        
        pdf.addText(self.textView.text, font: UIFont(name: "Courier", size: 25.0)!, textColor: .black)
        pdf.addLineSpace(3.0)
        let pdfData = pdf.generatePDFdata()
        let resourceDocPath = (FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)).first as! URL
        let pdfNameFromUrl = "CIN.pdf"
        let actualPath = resourceDocPath.appendingPathComponent(pdfNameFromUrl)
        do {
            try pdfData.write(to: actualPath, options: .atomic)
            print("pdf successfully saved!")
        } catch {
            print("Pdf could not be saved")
        }
        return actualPath.path
    }
        
    
    @objc func scanDocument() {
        let scannerViewController = VNDocumentCameraViewController()
        scannerViewController.delegate = self
        present(scannerViewController, animated: true)
    }

    
    private func processImage(_ image: UIImage) {
        imageView.image = image
        imageView.removeExistingBoundingBoxes()
        uploadImage(image)
    
    }

   
    
    // MARK: - VNDocumentCameraViewControllerDelegate
    func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFinishWith scan: VNDocumentCameraScan) {
        // Make sure the user scanned at least one page
        guard scan.pageCount >= 1 else {
            // You are responsible for dismissing the VNDocumentCameraViewController.
            controller.dismiss(animated: true)
            return
        }
        
        let originalImage = scan.imageOfPage(at: 0)
        let fixedImage = reloadedImage(originalImage)
        
        // You are responsible for dismissing the VNDocumentCameraViewController.
        controller.dismiss(animated: true)
        
        // Process the image
        processImage(fixedImage)
    }
    
    func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFailWithError error: Error) {
        // The VNDocumentCameraViewController failed with an error.
        // For now, we'll print it, but you should handle it appropriately in your app.
        print(error)
        
        // You are responsible for dismissing the VNDocumentCameraViewController.
        controller.dismiss(animated: true)
    }
    
    func documentCameraViewControllerDidCancel(_ controller: VNDocumentCameraViewController) {
        // You are responsible for dismissing the VNDocumentCameraViewController.
        controller.dismiss(animated: true)
    }
    
  
    
    func reloadedImage(_ originalImage: UIImage) -> UIImage {
        guard let imageData = originalImage.jpegData(compressionQuality: 1),
            let reloadedImage = UIImage(data: imageData) else {
                return originalImage
        }
        return reloadedImage
    }
    
    @IBAction func generatePdfTapped(_ sender: Any) {
        self.convert1()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let path = self.pdfFilePath else {
            fatalError()
        }
        
        if let destinationVC =  segue.destination as? PdfPreviewViewController {
           
                destinationVC.pdfFilePath = path
            
        }
    }
    
    @objc func navigate() {
        self.performSegue(withIdentifier: "PdfPreview", sender: nil)
    }
    
    @objc func convert1() {
        guard let path = self.genereatePDF() else {
            return
        }
        
        self.pdfFilePath = path
        self.navigate()
    }
}

extension UIViewController {
    class func displaySpinner(onView : UIView) -> UIView {
        let spinnerView = UIView.init(frame: onView.bounds)
        spinnerView.backgroundColor = UIColor.init(red: 0.5, green: 0.5, blue: 0.5, alpha: 0.5)
        let ai = UIActivityIndicatorView.init(style: .large)
        ai.startAnimating()
        ai.center = spinnerView.center

        DispatchQueue.main.async {
            spinnerView.addSubview(ai)
            onView.addSubview(spinnerView)
        }

        return spinnerView
    }

    class func removeSpinner(spinner :UIView) {
        DispatchQueue.main.async {
            spinner.removeFromSuperview()
        }
    }
}

extension String {

    func base64ToImage() -> UIImage? {

        if let url = URL(string: self),let data = try? Data(contentsOf: url),let image = UIImage(data: data) {
            return image
        }

        return nil

    }
}
