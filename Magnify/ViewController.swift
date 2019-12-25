//
//  ViewController.swift
//  Magnify
//
//  Created by Tom Nelson on 11/2/19.
//  Copyright © 2019 TKO Solutions. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    
    enum displayMode {
        case camera
        case picture
    }

    private(set) var tapGestureRecognizer: UITapGestureRecognizer?
//    private(set) var pinchGestureRecognizer: UIPinchGestureRecognizer?
    private var formatter = NumberFormatter()
    private var currentAnchor: CGPoint!
    weak var delegate: CameraManagerDelegate?
    private var mode: displayMode = .camera { didSet {
        switch mode {
            case .camera:
                self.resetButton.setTitle("Reset", for: .normal)
                CameraManager.shared.torch = true
                self.flashView.alpha = 0
                self.photoView.image = nil
                self.photoView.isHidden = true
            case .picture:
                self.photoView.transform = .identity
                self.photoView.frame = self.view.frame
                self.resetButton.setTitle("Clear", for: .normal)
        }
    }}

    var startingWidth: CGFloat = 0
    var fullWidth: CGFloat = 1000
    var deltaX: CGFloat = 0
    var deltaY: CGFloat = 0

    @IBOutlet weak var resetButton: UIButton!
    @IBOutlet private weak var contentView: UIView!
    @IBOutlet private weak var flashView: UIView!
    @IBOutlet private weak var photoView: UIImageView!
    @IBOutlet private weak var zoomFactorLabel: UILabel!
    @IBOutlet private weak var brightnessLabel: UILabel!
    @IBAction func resetAction(_ sender: UIButton) {
        switch self.mode {
            case .camera: CameraManager.shared.reset()
            case .picture: self.clearPhotoAction()
        }
    }
    @IBOutlet weak var lightView: UIVisualEffectView! { didSet {
        lightView.layer.cornerRadius = 15
        lightView.layer.masksToBounds = true
        lightView.layer.borderWidth = 0.5
        lightView.layer.borderColor = UIColor.black.cgColor
    }}
    @IBOutlet weak var zoomView: UIVisualEffectView!  { didSet {
           zoomView.layer.cornerRadius = 15
           zoomView.layer.masksToBounds = true
           zoomView.layer.borderWidth = 0.5
           zoomView.layer.borderColor = UIColor.black.cgColor
    }}
    @IBOutlet weak var resetView: UIVisualEffectView! { didSet {
        resetView.layer.cornerRadius = 30
        resetView.layer.masksToBounds = true
        resetView.layer.borderWidth = 0.5
        resetView.layer.borderColor = UIColor.black.cgColor
    }}

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(tapped))
        self.contentView.addGestureRecognizer(tapGestureRecognizer)
     
//        let cameraPinchGestureRecognizer = UIPinchGestureRecognizer(target: self, action: #selector(picturePinched(_:)))
//        self.contentView.addGestureRecognizer(cameraPinchGestureRecognizer)

        let cameraPanGestureRecognizer = UIPanGestureRecognizer(target: CameraManager.shared, action: #selector(CameraManager.panGesture(_:)))
        self.contentView.addGestureRecognizer(cameraPanGestureRecognizer)
        
        self.formatter.numberStyle = .decimal
        self.formatter.locale = .current
        self.formatter.maximumFractionDigits = 1
        self.formatter.minimumFractionDigits = 1

        let directions: [UISwipeGestureRecognizer.Direction] = [.right, .left, .up, .down]
        for direction in directions {
            let gesture = UISwipeGestureRecognizer(target: CameraManager.shared, action: #selector(CameraManager.swipeGesture(_:)))
            gesture.direction = direction
            gesture.delegate = CameraManager.shared
            self.contentView.addGestureRecognizer(gesture)
        }
        
        let picturePinchGestureRecognizer = UIPinchGestureRecognizer(target: self, action: #selector(picturePinched(_:)))
        self.view.addGestureRecognizer(picturePinchGestureRecognizer)
        let picturePanGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(picturePanned(_:)))
        self.view.addGestureRecognizer(picturePanGestureRecognizer)

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
        self.takePhotoAction()
    }
    
    @objc func picturePanned(_ sender: UIPanGestureRecognizer) {
        let translation = sender.translation(in: sender.view)
        let moveRightMax = max(-self.photoView.frame.minX, 0)
        let moveLeftMax = min(375 - self.photoView.frame.maxX, 0)
        let moveX = min(max(translation.x, moveLeftMax),moveRightMax)
        let moveDownMax = max(-self.photoView.frame.minY, 0)
        let moveUpMax = min(812 - self.photoView.frame.maxY, 0)
        let moveY = min(max(translation.y, moveUpMax),moveDownMax)
//        self.photoView.center = CGPoint(x: self.photoView.center.x + moveX, y: self.photoView.center.y + moveY)
//        print("moveX: \(moveX), moveY: \(moveY)")
//        print(self.extents)
//        sender.setTranslation(.zero, in: sender.view)
        self.photoView.transform = self.photoView.transform.translatedBy(x: moveX, y: moveY)
        sender.setTranslation(.zero, in: sender.view)
    }
    
    @objc private func picturePinched(_ sender: UIPinchGestureRecognizer) {
        let ratio = self.photoView.frame.width / self.contentView.frame.width
        let scale = ratio * sender.scale < 1.0 ? 1.0 / ratio : sender.scale
 
        switch sender.state {
            case .began:
                print(self.extents)
                let startingWidth = self.photoView.frame.maxX - self.photoView.frame.minX
                fullWidth = startingWidth - 375
                deltaX = -self.photoView.frame.midX + self.photoView.bounds.midX
                deltaY = -self.photoView.frame.midY + self.photoView.bounds.midY
            case .changed:
                self.photoView.transform = self.photoView.transform.scaledBy(x: scale, y: scale)
                
//                let moveRightMax = max(-self.photoView.frame.minX, 0)
//                let moveLeftMax = min(375 - self.photoView.frame.maxX, 0)
//                let moveX = min(max(translation.x, moveLeftMax),moveRightMax)
//                let moveDownMax = max(-self.photoView.frame.minY, 0)
//                let moveUpMax = min(812 - self.photoView.frame.maxY, 0)
//                let moveY = min(max(translation.y, moveUpMax),moveDownMax)

                
                let currentWidth = self.photoView.frame.maxX - self.photoView.frame.minX
                if fullWidth > 0 {
                    let moveX = (1 - scale) * deltaX * (currentWidth - 375) / fullWidth
                    let moveY = (1 - scale) * deltaY * (currentWidth - 375) / fullWidth
                    self.photoView.center = CGPoint(x: self.photoView.center.x + moveX, y: self.photoView.center.y + moveY)
                    print("moveX: \(moveX), moveY: \(moveY), scale: \(scale)")
                }
                sender.scale = 1.0
            case .ended:
                print(self.extents)
                print("Done with zoom")
            default: ()
        }
//        print(self.extents)
     }
    
    var extents: String {
        let left = Int(self.photoView.frame.minX)
        let top = Int(self.photoView.frame.minY)
        let right = Int(self.photoView.frame.maxX)
        let bottom = Int(self.photoView.frame.maxY)
        return "Left: \(left), Right: \(right), Top: \(top), Bottom: \(bottom)"
    }

    @objc private func takePhotoAction() {
        self.mode = .picture
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
        self.mode = .camera
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

extension ViewController: CameraManagerDelegate {
    func zoomFactor(_ zoom: CGFloat) {
        self.zoomFactorLabel.text = self.formatter.string(from: zoom as NSNumber)
    }
    
    func brightness(_ brightness: Float) {
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

