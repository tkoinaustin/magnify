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
    private(set) var pinchGestureRecognizer: UIPinchGestureRecognizer?
    private var formatter = NumberFormatter()
    weak var delegate: CameraManagerDelegate?
    private var mode: displayMode = .camera { didSet {
        switch mode {
            case .camera:
                self.resetButton.setTitle("Reset", for: .normal)
            case .picture:
                self.photoView.frame = self.view.frame
                self.resetButton.setTitle("Clear", for: .normal)
        }
    }}

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
            self.contentView.addGestureRecognizer(gesture)
        }
        
        let pinchGestureRecognizer = UIPinchGestureRecognizer(target: self, action: #selector(pinched(_:)))
        self.view.addGestureRecognizer(pinchGestureRecognizer)
        self.pinchGestureRecognizer = pinchGestureRecognizer

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
    
    @objc private func pinched(_ sender: UIPinchGestureRecognizer) {
//        print("sender.scale: \(sender.scale)")
//        let startingwidth = self.contentView.frame.width
//        let currentwidth = self.photoView.frame.width
        let ratio = self.photoView.frame.width / self.contentView.frame.width
//        print ("\(ratio): \(sender.scale)")
        let scale = ratio * sender.scale < 1.0 ? 1.0 / ratio : sender.scale
//        print("scale: \(scale)\n")

        switch sender.state {
            case .began: ()
            case .changed:
                self.photoView.transform = self.photoView.transform.scaledBy(x: scale, y: scale)
                sender.scale = 1.0
            case .ended: ()
            default: ()
        }
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

