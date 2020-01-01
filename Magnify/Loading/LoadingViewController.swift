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
        CameraManager.shared.prepareCamera()
            .done {
                let carouselViewController = CarouselViewController.instantiate()
                carouselViewController.modalPresentationStyle = .fullScreen
                self.present(carouselViewController, animated: true, completion: nil)
            }.cauterize()
    }
}
