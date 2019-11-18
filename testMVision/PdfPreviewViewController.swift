//
//  PdfPreviewViewController.swift
//  testMVision
//
//  Created by Tarek El Ghoul on 18/11/2019.
//  Copyright © 2019 Tarek El Ghoul. All rights reserved.
//

import UIKit

class PdfPreviewViewController: UIViewController {

@IBOutlet weak var webView: UIWebView!
private var shareButton: UIBarButtonItem!

var pdfFilePath: String?

override func viewDidLoad() {
    super.viewDidLoad()

    // Do any additional setup after loading the view.
}

@objc func share() {
    guard let path = self.pdfFilePath else {
        return
    }
    
    let fileURL = NSURL(fileURLWithPath: path)
    let activityViewController = UIActivityViewController(activityItems: [fileURL], applicationActivities: nil)
    activityViewController.popoverPresentationController?.sourceView = self.view // so that iPads won't crash
    
    // exclude some activity types from the list (optional)
    activityViewController.excludedActivityTypes = [ UIActivity.ActivityType.postToFacebook ]
    
    // present the view controller
    self.present(activityViewController, animated: true, completion: nil)
}

override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    
    guard let path = self.pdfFilePath else {
        fatalError()
    }
    
    var fileSize: UInt64 = 0
    
    do {
        let attr = try FileManager.default.attributesOfItem(atPath: path)
        fileSize = attr[FileAttributeKey.size] as! UInt64
    } catch {
        fatalError(error.localizedDescription)
    }
    fileSize = fileSize / 1024
    self.title = "File size: \(fileSize) KiB"
    
    let url = URL(fileURLWithPath: path)
    self.webView.loadRequest(URLRequest(url: url))
    
    self.shareButton = UIBarButtonItem(title: "Share", style: .plain, target: self, action: #selector(share))
    self.navigationItem.rightBarButtonItem = self.shareButton
}

}
