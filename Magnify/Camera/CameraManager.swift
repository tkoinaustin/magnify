import UIKit
import AVFoundation
import PromiseKit

protocol CameraManagerDelegate: class {
    func cameraDidChangeOrientation(_ deviceOrientation: UIDeviceOrientation)
    func zoomFactor(_ zoom: CGFloat)
    func brightness(_ brightness: Float)
}

enum CameraManagerError: Error {
    case noSession
    case noConnection
    case noCameraDevice
    case noPhotoData
    case noPhotoCaptureDelegate
    case genericError(String)
    case none
    case uninitialized
    
    var message: String {
        switch self {
            case .noSession: return "Unable to create camera session"
            case .noConnection: return "No connection made"
            case .noCameraDevice: return "No camera available"
            case .noPhotoData: return "Picture has no data"
            case .noPhotoCaptureDelegate: return "Camera has no photo capture delegate set"
            case .genericError(let msg): return "Processing error: \(msg)"
            case .none: return "No error"
            case .uninitialized: return "Camera manager has not been initialized"
        }
    }
}

class CameraManager: NSObject {
    
    
    enum PrimaryAction {
        case zoom
        case torch
        case undefined
    }

    static let shared = CameraManager()
    weak var delegate: CameraManagerDelegate?
    private var action: PrimaryAction = .undefined

    private var lastZoomFactor: CGFloat = 1.0
    private var lastTorchBrightness: Float = 0.0
    private var videoOrientation: AVCaptureVideoOrientation{
        get{
            if let orientation = AVCaptureVideoOrientation(rawValue: UIDevice.current.orientation.rawValue) {
                return orientation;
            }else{
                return .portrait
            }
        }
    }
    
    private (set) var managerError = CameraManagerError.uninitialized
    private var captureSession: AVCaptureSession?
    private var camera: AVCaptureDevice?
    private var cameraInput: AVCaptureDeviceInput?
    private var videoDataOutput: AVCaptureVideoDataOutput?
    private var photoOutput: AVCapturePhotoOutput?
    private var previewLayer: AVCaptureVideoPreviewLayer?
    private var photoCaptureDelegate: PhotoCaptureDelegate?
    private var flashMode = AVCaptureDevice.FlashMode.off
        
    deinit {
        if let captureSession = self.captureSession, captureSession.isRunning {
            captureSession.stopRunning()
        }
        NotificationCenter.default.removeObserver(self)
    }
    
    var hasTorch: Bool {
        get {
            return self.cameraInput?.device.hasTorch ?? false
        }
    }

    var torch: Bool {
        get {
            guard let device = self.cameraInput?.device else { return false }
            return device.hasFlash
        }
        set {
            guard let device = self.cameraInput?.device else { return }
            guard device.hasTorch else { return }
            do {
                try device.lockForConfiguration() ; defer { device.unlockForConfiguration() }
                if newValue {
                    if self.lastTorchBrightness > 0.0 {
                        try device.setTorchModeOn(level: self.lastTorchBrightness)
                    } else {
                        device.torchMode = .off
                    }
                } else {
                    device.torchMode = .off
                }
            } catch {
                print("Torch could not be set")
            }

        }
    }
    
    func reset() {
        guard let device = self.cameraInput?.device else { return }

        func zoom(scale: CGFloat) {
            do {
                try device.lockForConfiguration() ; defer { device.unlockForConfiguration() }
                device.videoZoomFactor = scale
                self.delegate?.zoomFactor(scale)
            } catch {
                debugPrint("\(error.localizedDescription)")
            }
        }
        
        func torch(scale: Float) {
            if device.hasTorch {
                do {
                    try device.lockForConfiguration() ; defer { device.unlockForConfiguration() }
                    self.delegate?.brightness(scale)
                    if scale > 0.0 {
                        try device.setTorchModeOn(level: scale)
                    } else {
                        device.torchMode = .off
                    }
                    
                    device.unlockForConfiguration()
                } catch {
                    print("Torch could not be used")
                }
            } else {
                print("Torch is not available")
            }
        }

        self.lastZoomFactor = 1.0
        zoom(scale: self.lastZoomFactor)
        self.lastTorchBrightness = 0.0
        torch(scale: self.lastTorchBrightness)
        self.action = .undefined
    }
    
    func prepareCamera() -> Promise<Void> {
        switch self.managerError {
            case .none: return Promise()
            default: break
        }
        
        let prepareQueue = DispatchQueue.init(label: "prepareQueue")
        self.captureSession = AVCaptureSession()
        self.captureSession?.sessionPreset = .photo

        func configureCaptureDevices() throws  {
            let session = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInWideAngleCamera], mediaType: AVMediaType.video, position: .back)
            let cameras = session.devices.compactMap { $0 }
            guard let camera = cameras.first else { self.managerError = .noCameraDevice; throw self.managerError }
            
            self.camera = camera
            try camera.lockForConfiguration()
            camera.focusMode = .continuousAutoFocus
            camera.unlockForConfiguration()
        }
        
        func configureDeviceInputs() throws  {
            guard let captureSession = self.captureSession else { self.managerError = .noSession; throw self.managerError }
            guard let camera = self.camera else { self.managerError = .noCameraDevice; throw self.managerError }

            self.cameraInput = try AVCaptureDeviceInput(device: camera)
            if let video = self.cameraInput, captureSession.canAddInput(video) {
                captureSession.addInput(video)
            } else {
                throw CameraManagerError.noCameraDevice
            }
        }

        func configurePhotoOutput() throws  {
            guard let captureSession = self.captureSession else { self.managerError = .noSession; throw self.managerError }
                        
            self.photoOutput = AVCapturePhotoOutput()
            self.photoOutput!.setPreparedPhotoSettingsArray([AVCapturePhotoSettings(format: [AVVideoCodecKey : AVVideoCodecType.jpeg])], completionHandler: nil)
            
            if captureSession.canAddOutput(self.photoOutput!) { captureSession.addOutput(self.photoOutput!) }
            captureSession.startRunning()
         }
        
        return Promise().done(on: prepareQueue) { _ in
                try configureCaptureDevices()
                try configureDeviceInputs()
                try configurePhotoOutput()
                self.managerError = .none
        }
    }
    
    func startSession() throws {
        guard let captureSession = self.captureSession else { self.managerError = .noSession; throw self.managerError }
        switch self.managerError {
            case .noSession: self.managerError = CameraManagerError.none
            default: break
        }
        guard !captureSession.isRunning else { return }
        captureSession.startRunning()
    }
    
    func stopSession() {
        guard let captureSession = self.captureSession, captureSession.isRunning else { return }
        captureSession.stopRunning()
    }
    
    func displayPreview(on view: UIView) throws {
        // if we have already initialized the preview layer, load it into the current view
        if let preview = self.previewLayer {
            preview.removeFromSuperlayer()
            view.layer.insertSublayer(preview, at: 0)
            preview.frame = view.frame

            return
        }

        // this is the stuff we only want to do once, to initialize the previewLayer
        guard let captureSession = self.captureSession else { self.managerError = .noSession; throw self.managerError }
        if !captureSession.isRunning { captureSession.startRunning() }

        self.previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        self.previewLayer?.videoGravity = AVLayerVideoGravity.resizeAspectFill
        self.previewLayer?.connection?.videoOrientation = .portrait

        // once initialized, load it into the current view
        view.layer.insertSublayer(self.previewLayer!, at: 0)
        self.previewLayer?.frame = view.frame
    }
}

// Gestures

extension CameraManager {
    @objc func swipeGesture(_ gesture: UIGestureRecognizer) {
        if let swipeGesture = gesture as? UISwipeGestureRecognizer {
            switch swipeGesture.direction {
            case .right, .left:
                self.action = .torch
            case .up, .down:
                break
            default:
                self.action = .undefined
            }
        }
    }

    @objc func panGesture(_ sender: UIPanGestureRecognizer) {
        guard let device = self.cameraInput?.device else { return }

        // Return zoom value between the minimum and maximum zoom values
        func zoomBounds(_ factor: CGFloat) -> CGFloat {
            return min(max(factor, 1.0),  10)
        }
        
        func torchBounds(_ factor: Float) -> Float {
            return min(max(factor, -0.2), 1.0)
        }

        func zoom(scale: CGFloat) {
            do {
                try device.lockForConfiguration() ; defer { device.unlockForConfiguration() }
                device.videoZoomFactor = scale
                self.delegate?.zoomFactor(scale)
            } catch {
                debugPrint("\(error.localizedDescription)")
            }
        }

        func torch(scale: Float) {
            if device.hasTorch {
                do {
                    try device.lockForConfiguration() ; defer { device.unlockForConfiguration() }
                    self.delegate?.brightness(scale)
                    if scale > 0.0 {
                        try device.setTorchModeOn(level: scale)
                    } else {
                        device.torchMode = .off
                    }

                    device.unlockForConfiguration()
                } catch {
                    print("Torch could not be used")
                }
            } else {
                print("Torch is not available")
            }
        }

        let translation = sender.translation(in: sender.view)
        let verticalScale = ( (sender.view?.bounds.height)! - translation.y) / (sender.view?.bounds.height)!
        let newVerticalScaleFactor = zoomBounds(verticalScale * self.lastZoomFactor)
        let horizontalScale = Float(translation.x / (sender.view?.bounds.width)! )
        let newHorizontalScaleFactor = torchBounds(horizontalScale + self.lastTorchBrightness)

        switch sender.state {
            case .began: ()
            case .changed:
                if self.action == .zoom {
                    zoom(scale: newVerticalScaleFactor)
                    torch(scale: self.lastTorchBrightness)
                }
                if self.action == .torch {
                    torch(scale: newHorizontalScaleFactor)
                    zoom(scale: self.lastZoomFactor)
            }
            case .ended:
                if self.action == .zoom {
                    self.lastZoomFactor = zoomBounds(newVerticalScaleFactor)
                    zoom(scale: self.lastZoomFactor)
                }
                if self.action == .torch {
                    self.lastTorchBrightness = torchBounds(newHorizontalScaleFactor)
                    torch(scale: self.lastTorchBrightness)
                }
                self.action = .undefined
            default: self.action = .undefined
        }
    }
    
    @objc func zoomGesture(_ sender: UIPinchGestureRecognizer) {
        guard let device = self.cameraInput?.device else { return }

        // Return zoom value between the minimum and maximum zoom values
        func zoomBounds(_ factor: CGFloat) -> CGFloat {
            return min(max(factor, 1.0),  10)
        }
        func zoom(scale: CGFloat) {
            do {
                try device.lockForConfiguration() ; defer { device.unlockForConfiguration() }
                device.videoZoomFactor = scale
                self.delegate?.zoomFactor(scale)
            } catch {
                debugPrint("\(error.localizedDescription)")
            }
        }
        
        let scale = self.lastZoomFactor * sender.scale < 1.0 ? 1.0 / self.lastZoomFactor : self.lastZoomFactor * sender.scale 
        self.lastZoomFactor = zoomBounds(scale)

        switch sender.state {
            case .began:
                zoom(scale: self.lastZoomFactor)
                sender.scale = 1.0
            case .changed:
                zoom(scale: self.lastZoomFactor)
                sender.scale = 1.0
            case .ended:
                zoom(scale: self.lastZoomFactor)
            default: ()
}
     }
}

// Photo Capture
extension CameraManager {
    func captureImage() -> Promise<Data> {
        self.photoCaptureDelegate = PhotoCaptureDelegate()
        
        guard let captureSession = captureSession, captureSession.isRunning else {
            return Promise(error: CameraManagerError.noSession)
        }
        guard let connectionVideo  = self.photoOutput?.connection(with: AVMediaType.video) else {
            return Promise(error: CameraManagerError.noConnection)
        }
        guard let captureDelegate = self.photoCaptureDelegate else {
            return Promise(error: CameraManagerError.noPhotoCaptureDelegate)
        }

        let settings = AVCapturePhotoSettings()
        settings.flashMode = self.flashMode
        connectionVideo.videoOrientation = self.videoOrientation
        self.photoOutput?.capturePhoto(with: settings, delegate: captureDelegate)
        return captureDelegate.onFinish()
    }
}


class PhotoCaptureDelegate: NSObject, AVCapturePhotoCaptureDelegate {
    let deferred = DeferredPromise<Data>()
    
    public func photoOutput(_ output: AVCapturePhotoOutput,
                            didFinishProcessingPhoto photo: AVCapturePhoto,
                            error: Error?) {
        if let error = error {
            self.deferred.reject(CameraManagerError.genericError(error.localizedDescription))
        } else if let photoData = photo.fileDataRepresentation() {
            self.deferred.resolve(photoData)
        } else {
            self.deferred.reject(CameraManagerError.noPhotoData)
        }
    }

    func onFinish() -> Promise<Data> {
        return self.deferred.promise
    }
}

// Notifications
extension CameraManager {
    func registerNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(deviceOrientationDidChange(_:)), name: UIDevice.orientationDidChangeNotification, object: nil)
    }
    
    @objc func deviceOrientationDidChange(_ notification: Notification) {
        handleCameraOrientationChange(UIDevice.current.orientation)
    }
    
    fileprivate func handleCameraOrientationChange(_ deviceOrientation: UIDeviceOrientation) {
        if let delegate = self.delegate {
            delegate.cameraDidChangeOrientation(deviceOrientation)
        }
    }
}


extension CameraManager: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer,
                           shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
}
