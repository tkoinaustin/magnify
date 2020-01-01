//
//  CameraViewController.swift
//  Magnify
//
//  Created by Tom Nelson on 11/2/19.
//  Copyright © 2019 TKO Solutions. All rights reserved.
//

import UIKit

class CameraViewController: UIViewController {
    
    private enum DisplayMode {
        case camera
        case picture
    }
    
    private enum TorchMode {
        case off
        case on
    }
    
    private enum ZoomMode {
        case none
        case some
    }

    private(set) var tapGestureRecognizer: UITapGestureRecognizer?
    private var formatter1 = NumberFormatter()
    private var formatter3 = NumberFormatter()
//    private var currentAnchor: CGPoint!
    weak var delegate: CameraManagerDelegate?
    private var displayMode: DisplayMode = .camera { didSet {
        switch displayMode {
            case .camera:
//                self.resetButton.isEnabled = false
                self.resetButton.setTitle("Reset", for: .normal)
                CameraManager.shared.torch = true
                self.flashView.alpha = 0
                self.photoView.image = nil
                self.photoView.isHidden = true
            case .picture:
                self.photoView.transform = .identity
                self.photoView.frame = self.view.frame
                self.resetButton.isEnabled = true
                self.resetButton.setTitle("Clear", for: .normal)
        }
    }}
    
    private var torchMode: TorchMode = .off
    private var zoomMode: ZoomMode = .none
    
    private func setResetState() {
        switch (self.torchMode, self.zoomMode, self.displayMode) {
        case (.off, .none, .camera):
                self.resetButton.isEnabled = false
                resetView.layer.borderColor = UIColor.clear.cgColor
            default:
                self.resetButton.isEnabled = true
                resetView.layer.borderColor = UIColor.label.cgColor
        }
    }
    
    var startingWidth: CGFloat = 0
    var fullWidth: CGFloat = 1000
    var deltaX: CGFloat = 0
    var deltaY: CGFloat = 0

    @IBOutlet private weak var resetButton: UIButton!
    @IBOutlet private weak var contentView: UIView!
    @IBOutlet private weak var flashView: UIView!
    @IBOutlet private weak var photoView: UIImageView!
    @IBOutlet private weak var zoomFactorLabel: UILabel!
    @IBOutlet private weak var brightnessLabel: UILabel!
    @IBAction func resetAction(_ sender: UIButton) {
        switch self.displayMode {
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
    
    class func instantiate() -> CameraViewController {
        return CameraViewController.storyboard("Camera")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(tapped))
        self.contentView.addGestureRecognizer(tapGestureRecognizer)
     
        let cameraPanGestureRecognizer = UIPanGestureRecognizer(target: CameraManager.shared, action: #selector(CameraManager.panGesture(_:)))
        self.contentView.addGestureRecognizer(cameraPanGestureRecognizer)
        
        self.formatter1.numberStyle = .decimal
        self.formatter1.locale = .current
        self.formatter1.maximumFractionDigits = 1
        self.formatter1.minimumFractionDigits = 1
        
        self.formatter3.numberStyle = .decimal
        self.formatter3.locale = .current
        self.formatter3.maximumFractionDigits = 1
        self.formatter3.minimumFractionDigits = 3

        let directions: [UISwipeGestureRecognizer.Direction] = [.right, .left, .up, .down]
        for direction in directions {
            let gesture = UISwipeGestureRecognizer(target: CameraManager.shared, action: #selector(CameraManager.swipeGesture(_:)))
            gesture.direction = direction
            gesture.delegate = CameraManager.shared
            self.contentView.addGestureRecognizer(gesture)
        }
        
        let picturePinchGestureRecognizer = UIPinchGestureRecognizer(target: self, action: #selector(pictureZoomed))
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
        let ratio = self.photoView.frame.width / self.contentView.frame.width
        let translation = sender.translation(in: sender.view)
        let moveRightMax = max(-self.photoView.frame.minX, 0)
        let moveLeftMax = min(self.photoView.bounds.width - self.photoView.frame.maxX, 0)
        let moveX = min(max(translation.x, moveLeftMax),moveRightMax)
        let moveDownMax = max(-self.photoView.frame.minY, 0)
        let moveUpMax = min(self.photoView.bounds.height - self.photoView.frame.maxY, 0)
        let moveY = min(max(translation.y, moveUpMax),moveDownMax)
        let anchor = self.photoView.layer.anchorPoint
        
        self.photoView.layer.anchorPoint = CGPoint(x: anchor.x - moveX / self.photoView.frame.width, y: anchor.y - moveY / self.photoView.frame.height )
        let x = self.formatter3.string(from: moveX * ratio as NSNumber) ?? "?"
        let y = self.formatter3.string(from: moveY * ratio as NSNumber) ?? "?"
        print("\(self.anchor), scale move: (\(x), \(y)), \(self.extents)")
        sender.setTranslation(.zero, in: sender.view)
    }
    
    @objc private func pictureZoomed(_ sender: UIPinchGestureRecognizer) {
        switch self.displayMode {
            case .camera: (CameraManager.shared.zoomGesture(sender))
            case .picture: (self.zoomPicture(sender))
        }
    }
    
    private func zoomPicture(_ sender: UIPinchGestureRecognizer) {
        let ratio = self.photoView.frame.width / self.contentView.frame.width
        let scale = ratio * sender.scale < 1.0 ? 1.0 / ratio : sender.scale
        var moveX: CGFloat = 0
        var moveY: CGFloat = 0
        let unzoomedWidth = self.photoView.bounds.width
        let unzoomedHeight = self.photoView.bounds.height
        switch sender.state {
            case .began:
                print(self.extents)
            case .changed:
                self.photoView.transform = self.photoView.transform.scaledBy(x: scale, y: scale)
                
                if self.photoView.frame.minX > 0 { moveX = -self.photoView.frame.minX }
                else if self.photoView.frame.maxX < unzoomedWidth { moveX = unzoomedWidth - self.photoView.frame.maxX }
                
                if self.photoView.frame.minY > 0 { moveY = -self.photoView.frame.minY }
                else if self.photoView.frame.maxY < unzoomedHeight { moveY = unzoomedHeight - self.photoView.frame.maxY }
                
                if moveX != 0 || moveY != 0 {
                    print("adjusting center by (\(moveX), \(moveY))")
                    self.photoView.transform = self.photoView.transform.translatedBy(x: moveX, y: moveY)
                }
                
                sender.scale = 1.0
            case .ended:
                print(self.extents)
                print("Done with zoom")
            default: ()
        }
     }
    
    private func setAnchor(_ view: UIView) -> CGPoint {
        let ratio = (view.frame.width - view.bounds.width) / view.frame.width
        let nozoomCenter = CGPoint(x: view.bounds.midX, y: view.bounds.midY)
        let zoomedCenter = CGPoint(x: view.frame.midX, y: view.frame.midY)
        let delta = nozoomCenter - zoomedCenter
        let adjustedDelta = delta * ratio
        let anchorPixels = nozoomCenter + adjustedDelta
        let x = max(min(anchorPixels.x / view.bounds.width, 1), 0)
        let y = max(min(anchorPixels.y / view.bounds.height, 1), 0)
        let anchor = CGPoint(x: x, y: y)
        print("\nbounds: \(view.bounds)")
        print("frame: \(view.frame)")
        print("ratio: \(ratio)")
        print("delta: \(delta)")
        print("adjustedDelta: \(adjustedDelta)")
        print("anchorPixels: \(anchorPixels)")
        print("anchor: \(anchor)\n")
        return anchor
    }

    var extents: String {
        let left = Int(self.photoView.frame.minX)
        let top = Int(self.photoView.frame.minY)
        let right = Int(self.photoView.frame.maxX)
        let bottom = Int(self.photoView.frame.maxY)
//        return "Left: \(left), Right: \(right), Top: \(top), Bottom: \(bottom)"
        return "origin: (\(left), \(top)), size: (\(right - left), \(bottom - top))"
    }
    
    var anchor: String {
        let point = self.photoView.layer.anchorPoint
        let x = self.formatter3.string(from: point.x as NSNumber) ?? "?"
        let y = self.formatter3.string(from: point.y as NSNumber) ?? "?"
        return "anchor: (\(x), \(y))"
    }

    @objc private func takePhotoAction() {
        self.displayMode = .picture
        _ = self.activityIndicator().show()
        flash {
            CameraManager.shared.captureImage()
                .done { [weak self] data in
                    guard let this = self else { return }
                    CameraManager.shared.torch = false
                    this.photoView.image = UIImage(data: data)
                    this.photoView.isHidden = false
                    this.photoView.layer.anchorPoint = CGPoint(x: 0.5, y: 0.5)
                    this.photoView.transform = .identity
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
        self.displayMode = .camera
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

extension CameraViewController: CameraManagerDelegate {
    func zoomFactor(_ zoom: CGFloat) {
        self.zoomMode = zoom == 1.0 ? .none : .some
        self.zoomFactorLabel.text = self.formatter1.string(from: zoom as NSNumber)
        self.setResetState()
    }
    
    func brightness(_ brightness: Float) {
        let bright = Int(max(brightness * 100, 0))
        self.torchMode = .on
        if bright == 0 {
            self.brightnessLabel.text = "Off"
            self.torchMode = .off
        } else if bright == 100 {
            self.brightnessLabel.text = "Full"
        } else {
            self.brightnessLabel.text = "\(bright)%"
        }
        self.setResetState()
    }

    func cameraDidChangeOrientation(_ deviceOrientation: UIDeviceOrientation) {
        
    }

}

