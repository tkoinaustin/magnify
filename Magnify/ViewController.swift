//
//  ViewController.swift
//  Magnify
//
//  Created by Tom Nelson on 11/2/19.
//  Copyright © 2019 TKO Solutions. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

//    private let camera = CameraManager()
    private(set) var tapGestureRecognizer: UITapGestureRecognizer?
    private(set) var dblTapGestureRecognizer: UITapGestureRecognizer?
    private var formatter = NumberFormatter()
    weak var delegate: CameraManagerDelegate?

    @IBOutlet private weak var contentView: UIView!
    @IBOutlet private weak var flashView: UIView!
    @IBOutlet private weak var photoView: UIImageView!
    @IBOutlet private weak var zoomFactorLabel: UILabel!
    @IBOutlet private weak var brightnessLabel: UILabel!
    @IBAction func resetAction(_ sender: UIButton) {
        CameraManager.shared.reset()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
//        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(tapped))
//        tapGestureRecognizer.delegate = self
//        self.view.addGestureRecognizer(tapGestureRecognizer)
//        self.tapGestureRecognizer = tapGestureRecognizer
     
        let dblTapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(doubleTapped))
//        dblTapGestureRecognizer.delegate = self
        dblTapGestureRecognizer.numberOfTouchesRequired = 2
        self.contentView.addGestureRecognizer(dblTapGestureRecognizer)
        self.dblTapGestureRecognizer = dblTapGestureRecognizer

        let panGestureRecognizer = UIPanGestureRecognizer(target: CameraManager.shared, action: #selector(CameraManager.panGesture(_:)))
        self.contentView.addGestureRecognizer(panGestureRecognizer)
        self.formatter.numberStyle = .decimal
        self.formatter.locale = .current
        self.formatter.maximumFractionDigits = 1
        self.formatter.minimumFractionDigits = 1

        let directions: [UISwipeGestureRecognizer.Direction] = [.right, .left, .up, .down]
        for direction in directions {
            let gesture = UISwipeGestureRecognizer(target: CameraManager.shared, action: #selector(CameraManager.swipeGesture(_:)))
            gesture.direction = direction
            gesture.delegate = CameraManager.shared
            self.view.addGestureRecognizer(gesture)
        }
        
        self.flashView.alpha = 0
        CameraManager.shared.delegate = self
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        self.photoView.frame = self.view.frame
        do {
            defer {
                self.activityIndicator().hide()
            }
            try CameraManager.shared.startSession()
            try CameraManager.shared.displayPreview(on: self.contentView)
        } catch {
            var message: String
            switch CameraManager.shared.managerError {
                case .none: message = "Error starting session"
                default: message = CameraManager.shared.managerError.message
            }
            self.showAlert(title: "Error", message: message)
                .done { _ in
                    print("Failed to initialize: \(message)")
                }.cauterize()
        }
    }
    
    @objc private func tapped() {
        if Int(self.flashView.alpha) == 0 {
//            self.clearPhotoAction()
//        } else {
            self.takePhotoAction()
        }
    }
    
    @objc private func doubleTapped() {
        if Int(self.flashView.alpha) == 1 {
            self.clearPhotoAction()
//        } else {
//            self.takePhotoAction()
        }
    }
    
    @objc private func takePhotoAction() {
        _ = self.activityIndicator().show()
        flash {
            CameraManager.shared.captureImage()
                .done { [weak self] data in
                    guard let this = self else { return }
                    CameraManager.shared.torch = false
                    this.photoView.image = UIImage(data: data)
                    this.photoView.isHidden = false
                    this.flashView.alpha = 1
                }.catch {error in
                    let message = (error as? CameraManagerError)?.message ?? "Something went wrong"
                    self.showAlert(title: "Error taking picture", message: message)
                        .done { _ in
                            print("Error taking picture: \(message)")
                    }.cauterize()
            }.finally {
                self.activityIndicator().hide()
            }
        }
    }
    
    @objc private func clearPhotoAction() {
        CameraManager.shared.torch = true
        self.flashView.alpha = 0
        self.photoView.image = nil
        self.photoView.isHidden = true
    }

    private func flash(completion: (() -> Void)? = nil) {
        UIView.animate(withDuration: 0.1, animations: {
            self.flashView.alpha = 1
        }) { _ in
            UIView.animate(withDuration: 0.1, animations: {
                self.flashView.alpha = 0
            }) { finished in
                completion?()
            }
        }
    }
}

//extension ViewController: UIGestureRecognizerDelegate {
//    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer,
//             shouldRequireFailureOf otherGestureRecognizer: UIGestureRecognizer) -> Bool {
//       // Don't recognize a single tap until a double-tap fails.
//       if gestureRecognizer == self.tapGestureRecognizer &&
//              otherGestureRecognizer == self.dblTapGestureRecognizer {
//          return true
//       }
//       return false
//    }
//}
extension ViewController: CameraManagerDelegate {
    func zoomFactor(_ zoom: CGFloat) {
        self.zoomFactorLabel.text = self.formatter.string(from: zoom as NSNumber)
    }
    
    func brightness(_ brightness: Float) {
        print("Brightness: \(brightness)")
        let bright = Int(max(brightness * 100, 0))
        if bright == 0 {
            self.brightnessLabel.text = "Off"
        } else if bright == 100 {
            self.brightnessLabel.text = "Full"
        } else {
            self.brightnessLabel.text = "\(bright)%"
        }
    }

    func cameraDidChangeOrientation(_ deviceOrientation: UIDeviceOrientation) {
        
    }

}

