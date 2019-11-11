//
//  LoadingViewController.swift
//  Magnify
//
//  Created by Tom Nelson on 11/10/19.
//  Copyright © 2019 TKO Solutions. All rights reserved.
//

import UIKit
import PromiseKit

class LoadingViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
//        _ = self.activityIndicator().show()
        CameraManager.shared.prepareCamera()
            .done {
                let storyboard = UIStoryboard(name: "Main", bundle: Bundle.main)
                if let cameraViewController = self.storyboard?.instantiateViewController(withIdentifier: "CameraViewController") as? ViewController {
                    cameraViewController.modalPresentationStyle = .fullScreen
                    self.present(cameraViewController, animated: true, completion: nil)
                }
                }.cauterize()
    }
}
