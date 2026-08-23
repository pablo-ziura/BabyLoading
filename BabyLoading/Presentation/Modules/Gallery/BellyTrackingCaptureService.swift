@preconcurrency import AVFoundation
import CoreGraphics
import Dispatch
import Foundation

protocol BellyTrackingCameraPreviewSourceProtocol: Sendable {
    func connect(to target: any BellyTrackingCameraPreviewTargetProtocol)
}

protocol BellyTrackingCameraPreviewTargetProtocol: AnyObject {
    func setSession(_ session: AVCaptureSession)
}

protocol BellyTrackingCaptureServiceProtocol: Actor {
    nonisolated var previewSource: any BellyTrackingCameraPreviewSourceProtocol { get }

    func isCameraAvailable() -> Bool
    func authorizationStatus() -> AVAuthorizationStatus
    func requestAccess() async -> Bool
    func prepareSession() throws
    func startRunning()
    func stopRunning()
    func capturePhoto(rotationAngle: CGFloat) async throws -> Data
}

enum BellyTrackingCaptureServiceError: LocalizedError {
    case noCameraDevice
    case cannotCreateInput
    case cannotAddInput
    case cannotAddOutput
    case sessionNotConfigured
    case invalidPhotoData
    case alreadyCapturing

    var errorDescription: String? {
        switch self {
        case .noCameraDevice:
            "No back camera is available on this device."
        case .cannotCreateInput:
            "The camera input could not be created."
        case .cannotAddInput:
            "The camera input could not be added to the session."
        case .cannotAddOutput:
            "The photo output could not be added to the session."
        case .sessionNotConfigured:
            "The camera session is not configured."
        case .invalidPhotoData:
            "The camera returned an invalid photo."
        case .alreadyCapturing:
            "A photo capture is already in progress."
        }
    }
}

actor BellyTrackingCaptureService: BellyTrackingCaptureServiceProtocol {
    nonisolated let previewSource: any BellyTrackingCameraPreviewSourceProtocol

    private let captureSession: AVCaptureSession
    private let photoOutput = AVCapturePhotoOutput()
    private let sessionQueue = DispatchSerialQueue(
        label: "com.babyloading.bellyTracking.captureSession"
    )

    private var activePhotoCaptureDelegate: BellyTrackingPhotoCaptureDelegate?
    private var isConfigured = false

    nonisolated var unownedExecutor: UnownedSerialExecutor {
        sessionQueue.asUnownedSerialExecutor()
    }

    init() {
        let captureSession = AVCaptureSession()
        self.captureSession = captureSession
        previewSource = DefaultBellyTrackingCameraPreviewSource(session: captureSession)
    }

    func isCameraAvailable() -> Bool {
        defaultCameraDevice != nil
    }

    func authorizationStatus() -> AVAuthorizationStatus {
        AVCaptureDevice.authorizationStatus(for: .video)
    }

    func requestAccess() async -> Bool {
        await AVCaptureDevice.requestAccess(for: .video)
    }

    func prepareSession() throws {
        guard !isConfigured else { return }
        guard let cameraDevice = defaultCameraDevice else {
            throw BellyTrackingCaptureServiceError.noCameraDevice
        }

        let cameraInput: AVCaptureDeviceInput
        do {
            cameraInput = try AVCaptureDeviceInput(device: cameraDevice)
        } catch {
            throw BellyTrackingCaptureServiceError.cannotCreateInput
        }

        guard captureSession.canAddInput(cameraInput) else {
            throw BellyTrackingCaptureServiceError.cannotAddInput
        }
        guard captureSession.canAddOutput(photoOutput) else {
            throw BellyTrackingCaptureServiceError.cannotAddOutput
        }

        try cameraDevice.lockForConfiguration()
        cameraDevice.videoZoomFactor = 1
        cameraDevice.unlockForConfiguration()

        captureSession.beginConfiguration()
        captureSession.sessionPreset = .photo
        captureSession.addInput(cameraInput)
        captureSession.addOutput(photoOutput)
        photoOutput.maxPhotoQualityPrioritization = .quality
        captureSession.commitConfiguration()

        isConfigured = true
    }

    func startRunning() {
        guard isConfigured, !captureSession.isRunning else { return }
        captureSession.startRunning()
    }

    func stopRunning() {
        guard captureSession.isRunning else { return }
        captureSession.stopRunning()
    }

    func capturePhoto(rotationAngle: CGFloat) async throws -> Data {
        guard isConfigured else {
            throw BellyTrackingCaptureServiceError.sessionNotConfigured
        }
        guard activePhotoCaptureDelegate == nil else {
            throw BellyTrackingCaptureServiceError.alreadyCapturing
        }

        if let connection = photoOutput.connection(with: .video),
           connection.isVideoRotationAngleSupported(rotationAngle) {
            connection.videoRotationAngle = rotationAngle
        }

        let settings: AVCapturePhotoSettings
        if photoOutput.availablePhotoCodecTypes.contains(.hevc) {
            settings = AVCapturePhotoSettings(
                format: [AVVideoCodecKey: AVVideoCodecType.hevc]
            )
        } else {
            settings = AVCapturePhotoSettings()
        }
        settings.photoQualityPrioritization = photoOutput.maxPhotoQualityPrioritization

        defer { activePhotoCaptureDelegate = nil }
        return try await withCheckedThrowingContinuation { continuation in
            let delegate = BellyTrackingPhotoCaptureDelegate(continuation: continuation)
            activePhotoCaptureDelegate = delegate
            photoOutput.capturePhoto(with: settings, delegate: delegate)
        }
    }

    private var defaultCameraDevice: AVCaptureDevice? {
        AVCaptureDevice.default(
            .builtInWideAngleCamera,
            for: .video,
            position: .back
        )
    }
}

private struct DefaultBellyTrackingCameraPreviewSource: BellyTrackingCameraPreviewSourceProtocol {
    private let session: AVCaptureSession

    init(session: AVCaptureSession) {
        self.session = session
    }

    func connect(to target: any BellyTrackingCameraPreviewTargetProtocol) {
        target.setSession(session)
    }
}

private final class BellyTrackingPhotoCaptureDelegate: NSObject, AVCapturePhotoCaptureDelegate {
    private let continuation: CheckedContinuation<Data, any Error>

    init(continuation: CheckedContinuation<Data, any Error>) {
        self.continuation = continuation
    }

    func photoOutput(
        _ output: AVCapturePhotoOutput,
        didFinishProcessingPhoto photo: AVCapturePhoto,
        error: (any Error)?
    ) {
        if let error {
            continuation.resume(throwing: error)
            return
        }

        guard let data = photo.fileDataRepresentation() else {
            continuation.resume(throwing: BellyTrackingCaptureServiceError.invalidPhotoData)
            return
        }

        continuation.resume(returning: data)
    }
}
