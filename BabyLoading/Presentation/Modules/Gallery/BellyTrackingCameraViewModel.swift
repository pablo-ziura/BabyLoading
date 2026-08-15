import AVFoundation
import Foundation
import Observation

enum BellyTrackingCameraAuthorizationState: Equatable {
    case idle
    case requesting
    case authorized
    case denied
    case unavailable
    case failed
}

@Observable
@MainActor
final class BellyTrackingCameraViewModel {
    let hasReferenceImage: Bool

    var authorizationState: BellyTrackingCameraAuthorizationState = .idle
    var isShowingReference: Bool
    var referenceOpacity = 0.35
    var isCapturing = false
    var errorMessage: String?

    @ObservationIgnored private let sessionController = BellyTrackingCameraSessionController()

    var session: AVCaptureSession {
        sessionController.session
    }

    var cameraDevice: AVCaptureDevice? {
        sessionController.cameraDevice
    }

    init(hasReferenceImage: Bool) {
        self.hasReferenceImage = hasReferenceImage
        isShowingReference = hasReferenceImage
    }

    func prepareSession() async {
        guard sessionController.isCameraAvailable else {
            authorizationState = .unavailable
            return
        }

        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            await configureAndStartSession()
        case .notDetermined:
            authorizationState = .requesting
            let granted = await requestCameraAccess()
            authorizationState = granted ? .idle : .denied

            if granted {
                await configureAndStartSession()
            }
        case .denied, .restricted:
            authorizationState = .denied
        @unknown default:
            authorizationState = .failed
        }
    }

    func stopSession() {
        sessionController.stopRunning()
    }

    func clearError() {
        errorMessage = nil
    }

    func capturePhoto(
        captureRotationAngle: CGFloat,
        save: AsyncBellyTrackingCaptureHandler
    ) async -> Bool {
        guard authorizationState == .authorized else { return false }

        isCapturing = true
        defer { isCapturing = false }

        do {
            let capturedData = try await sessionController.capturePhoto(
                rotationAngle: captureRotationAngle
            )
            guard await save(capturedData) else {
                errorMessage = String(
                    localized: "camera.bellyTracking.errorSave",
                    defaultValue: "We couldn't save your belly tracking photo."
                )
                return false
            }

            return true
        } catch {
            errorMessage = String(
                localized: "camera.bellyTracking.errorCapture",
                defaultValue: "We couldn't capture the photo. Please try again."
            )
            return false
        }
    }

    private func configureAndStartSession() async {
        do {
            try await sessionController.prepareSession()
            authorizationState = .authorized
            sessionController.startRunning()
        } catch {
            authorizationState = .failed
            errorMessage = String(
                localized: "camera.bellyTracking.errorCapture",
                defaultValue: "We couldn't capture the photo. Please try again."
            )
        }
    }

    private func requestCameraAccess() async -> Bool {
        await withCheckedContinuation { continuation in
            AVCaptureDevice.requestAccess(for: .video) { granted in
                continuation.resume(returning: granted)
            }
        }
    }
}

private enum BellyTrackingCameraSessionError: LocalizedError {
    case noCameraDevice
    case cannotCreateInput
    case cannotAddInput
    case cannotAddOutput
    case invalidPhotoData
    case alreadyCapturing

    var errorDescription: String? {
        switch self {
        case .noCameraDevice:
            return "No back camera is available on this device."
        case .cannotCreateInput:
            return "The camera input could not be created."
        case .cannotAddInput:
            return "The camera input could not be added to the session."
        case .cannotAddOutput:
            return "The photo output could not be added to the session."
        case .invalidPhotoData:
            return "The camera returned an invalid photo."
        case .alreadyCapturing:
            return "A photo capture is already in progress."
        }
    }
}

private final class BellyTrackingCameraSessionController: NSObject, @unchecked Sendable {
    nonisolated(unsafe) let session = AVCaptureSession()
    nonisolated(unsafe) private let photoOutput = AVCapturePhotoOutput()
    nonisolated(unsafe) var cameraDevice: AVCaptureDevice?
    private let sessionQueue = DispatchQueue(label: "com.babyloading.bellyTracking.cameraSession")
    private let captureLock = NSLock()
    nonisolated(unsafe) private var isConfigured = false
    nonisolated(unsafe) private var captureCompletion: ((Result<Data, Error>) -> Void)?

    nonisolated var isCameraAvailable: Bool {
        AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) != nil
    }

    nonisolated func prepareSession() async throws {
        try await withCheckedThrowingContinuation { continuation in
            sessionQueue.async {
                do {
                    if !self.isConfigured {
                        try self.configureSession()
                    }

                    DispatchQueue.main.async {
                        continuation.resume(returning: ())
                    }
                } catch {
                    DispatchQueue.main.async {
                        continuation.resume(throwing: error)
                    }
                }
            }
        }
    }

    nonisolated func startRunning() {
        sessionQueue.async {
            guard self.isConfigured, !self.session.isRunning else { return }
            self.session.startRunning()
        }
    }

    nonisolated func stopRunning() {
        sessionQueue.async {
            guard self.session.isRunning else { return }
            self.session.stopRunning()
        }
    }

    nonisolated func capturePhoto(rotationAngle: CGFloat) async throws -> Data {
        try await withCheckedThrowingContinuation { continuation in
            capturePhoto(rotationAngle: rotationAngle) { result in
                continuation.resume(with: result)
            }
        }
    }

    nonisolated private func configureSession() throws {
        session.beginConfiguration()
        defer { session.commitConfiguration() }

        session.sessionPreset = .photo

        guard let cameraDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) else {
            throw BellyTrackingCameraSessionError.noCameraDevice
        }
        self.cameraDevice = cameraDevice

        guard let cameraInput = try? AVCaptureDeviceInput(device: cameraDevice) else {
            throw BellyTrackingCameraSessionError.cannotCreateInput
        }

        guard session.canAddInput(cameraInput) else {
            throw BellyTrackingCameraSessionError.cannotAddInput
        }
        session.addInput(cameraInput)

        try cameraDevice.lockForConfiguration()
        defer { cameraDevice.unlockForConfiguration() }
        cameraDevice.videoZoomFactor = 1

        guard session.canAddOutput(photoOutput) else {
            throw BellyTrackingCameraSessionError.cannotAddOutput
        }
        session.addOutput(photoOutput)
        photoOutput.maxPhotoQualityPrioritization = .quality
        isConfigured = true
    }

    nonisolated private func capturePhoto(
        rotationAngle: CGFloat,
        completion: @escaping (Result<Data, Error>) -> Void
    ) {
        captureLock.lock()
        let isBusy = captureCompletion != nil
        if !isBusy {
            captureCompletion = completion
        }
        captureLock.unlock()

        guard !isBusy else {
            completion(.failure(BellyTrackingCameraSessionError.alreadyCapturing))
            return
        }

        sessionQueue.async {
            if let connection = self.photoOutput.connection(with: .video),
               connection.isVideoRotationAngleSupported(rotationAngle) {
                connection.videoRotationAngle = rotationAngle
            }

            let settings: AVCapturePhotoSettings
            if self.photoOutput.availablePhotoCodecTypes.contains(.hevc) {
                settings = AVCapturePhotoSettings(
                    format: [AVVideoCodecKey: AVVideoCodecType.hevc]
                )
            } else {
                settings = AVCapturePhotoSettings()
            }
            settings.photoQualityPrioritization = self.photoOutput.maxPhotoQualityPrioritization
            self.photoOutput.capturePhoto(with: settings, delegate: self)
        }
    }

    nonisolated private func finishCapture(with result: Result<Data, Error>) {
        captureLock.lock()
        let completion = captureCompletion
        captureCompletion = nil
        captureLock.unlock()

        DispatchQueue.main.async {
            completion?(result)
        }
    }
}

extension BellyTrackingCameraSessionController: AVCapturePhotoCaptureDelegate {
    nonisolated func photoOutput(
        _ output: AVCapturePhotoOutput,
        didFinishProcessingPhoto photo: AVCapturePhoto,
        error: Error?
    ) {
        if let error {
            finishCapture(with: .failure(error))
            return
        }

        guard let data = photo.fileDataRepresentation() else {
            finishCapture(with: .failure(BellyTrackingCameraSessionError.invalidPhotoData))
            return
        }

        finishCapture(with: .success(data))
    }
}
