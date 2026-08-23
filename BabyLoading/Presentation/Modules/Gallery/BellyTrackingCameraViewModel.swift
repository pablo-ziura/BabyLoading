@preconcurrency import AVFoundation
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

    @ObservationIgnored private let captureService: any BellyTrackingCaptureServiceProtocol

    var previewSource: any BellyTrackingCameraPreviewSourceProtocol {
        captureService.previewSource
    }

    init(
        hasReferenceImage: Bool,
        captureService: any BellyTrackingCaptureServiceProtocol
    ) {
        self.hasReferenceImage = hasReferenceImage
        self.captureService = captureService
        isShowingReference = hasReferenceImage
    }

    func prepareSession() async {
        guard await captureService.isCameraAvailable() else {
            authorizationState = .unavailable
            return
        }

        switch await captureService.authorizationStatus() {
        case .authorized:
            await configureAndStartSession()
        case .notDetermined:
            authorizationState = .requesting
            let granted = await captureService.requestAccess()
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

    func stopSession() async {
        await captureService.stopRunning()
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
            let capturedData = try await captureService.capturePhoto(
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
            try await captureService.prepareSession()
            authorizationState = .authorized
            await captureService.startRunning()
        } catch {
            authorizationState = .failed
            errorMessage = String(
                localized: "camera.bellyTracking.errorCapture",
                defaultValue: "We couldn't capture the photo. Please try again."
            )
        }
    }

}
