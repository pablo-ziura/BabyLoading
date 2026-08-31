@preconcurrency import AVFoundation
import CoreGraphics
import Foundation
import Observation

public typealias AsyncBellyTrackingCaptureHandler = @MainActor @Sendable (Data) async -> Bool
typealias BellyTrackingCameraDismissHandler = @MainActor @Sendable () -> Void

enum BellyTrackingCameraAuthorizationState: Equatable, Sendable {
    case idle
    case requesting
    case authorized
    case denied
    case unavailable
    case failed
}

enum BellyTrackingCameraLifecycleState: Equatable, Sendable {
    case idle
    case preparing
    case ready
    case capturing
    case saving
    case closed
}

@MainActor
@Observable
final class BellyTrackingCameraViewModel {
    let hasReferenceImage: Bool

    private(set) var authorizationState: BellyTrackingCameraAuthorizationState = .idle
    private(set) var lifecycleState: BellyTrackingCameraLifecycleState = .idle
    var isShowingReference: Bool
    var referenceOpacity = 0.35
    private(set) var errorMessage: String?

    @ObservationIgnored private let captureService: any BellyTrackingCaptureServiceProtocol
    @ObservationIgnored private var preparationTask: Task<Void, Never>?
    @ObservationIgnored private var captureTask: Task<Void, Never>?
    @ObservationIgnored private var stopTask: Task<Void, Never>?
    @ObservationIgnored private var generation = 0
    @ObservationIgnored private var didRequestStop = false
    @ObservationIgnored private var didEmitDismissal = false

    var previewSource: any BellyTrackingCameraPreviewSourceProtocol {
        captureService.previewSource
    }

    var isCapturing: Bool {
        lifecycleState == .capturing || lifecycleState == .saving
    }

    var isDismissalDisabled: Bool {
        lifecycleState == .saving
    }

    init(
        hasReferenceImage: Bool,
        captureService: any BellyTrackingCaptureServiceProtocol
    ) {
        self.hasReferenceImage = hasReferenceImage
        self.captureService = captureService
        isShowingReference = hasReferenceImage
    }

    func activate() {
        guard lifecycleState == .idle else { return }

        generation &+= 1
        let operationGeneration = generation
        lifecycleState = .preparing
        preparationTask = Task { @MainActor [weak self] in
            await self?.prepareSession(generation: operationGeneration)
        }
    }

    func capturePhoto(
        captureRotationAngle: CGFloat,
        save: @escaping AsyncBellyTrackingCaptureHandler,
        onSaved: @escaping BellyTrackingCameraDismissHandler
    ) {
        guard lifecycleState == .ready else { return }

        let operationGeneration = generation
        lifecycleState = .capturing
        errorMessage = nil
        captureTask = Task { @MainActor [weak self] in
            await self?.capturePhoto(
                captureRotationAngle: captureRotationAngle,
                generation: operationGeneration,
                save: save,
                onSaved: onSaved
            )
        }
    }

    func close(onClosed: @escaping BellyTrackingCameraDismissHandler = {}) {
        guard lifecycleState != .saving, lifecycleState != .closed else { return }

        generation &+= 1
        preparationTask?.cancel()
        captureTask?.cancel()
        preparationTask = nil
        captureTask = nil
        lifecycleState = .closed
        requestStopIfNeeded()
        emitDismissal(using: onClosed)
    }

    func clearError() {
        errorMessage = nil
    }

    private func prepareSession(generation operationGeneration: Int) async {
        guard await captureService.isCameraAvailable() else {
            guard isCurrent(operationGeneration, lifecycle: .preparing) else { return }
            authorizationState = .unavailable
            lifecycleState = .idle
            preparationTask = nil
            return
        }
        guard isCurrent(operationGeneration, lifecycle: .preparing) else { return }

        switch await captureService.authorizationStatus() {
        case .authorized:
            await configureAndStartSession(generation: operationGeneration)
        case .notDetermined:
            authorizationState = .requesting
            let granted = await captureService.requestAccess()
            guard isCurrent(operationGeneration, lifecycle: .preparing) else { return }

            if granted {
                await configureAndStartSession(generation: operationGeneration)
            } else {
                authorizationState = .denied
                lifecycleState = .idle
                preparationTask = nil
            }
        case .denied, .restricted:
            guard isCurrent(operationGeneration, lifecycle: .preparing) else { return }
            authorizationState = .denied
            lifecycleState = .idle
            preparationTask = nil
        @unknown default:
            guard isCurrent(operationGeneration, lifecycle: .preparing) else { return }
            authorizationState = .failed
            lifecycleState = .idle
            preparationTask = nil
        }
    }

    private func configureAndStartSession(generation operationGeneration: Int) async {
        do {
            try await captureService.prepareSession()
            guard isCurrent(operationGeneration, lifecycle: .preparing) else { return }

            await captureService.startRunning()
            guard isCurrent(operationGeneration, lifecycle: .preparing) else {
                requestStopIfNeeded()
                return
            }

            authorizationState = .authorized
            lifecycleState = .ready
            preparationTask = nil
        } catch {
            guard isCurrent(operationGeneration, lifecycle: .preparing) else { return }
            authorizationState = .failed
            lifecycleState = .idle
            preparationTask = nil
            errorMessage = captureErrorMessage
        }
    }

    private func capturePhoto(
        captureRotationAngle: CGFloat,
        generation operationGeneration: Int,
        save: AsyncBellyTrackingCaptureHandler,
        onSaved: BellyTrackingCameraDismissHandler
    ) async {
        do {
            let capturedData = try await captureService.capturePhoto(
                rotationAngle: captureRotationAngle
            )
            guard isCurrent(operationGeneration, lifecycle: .capturing) else { return }

            lifecycleState = .saving
            let didSave = await save(capturedData)

            if didSave {
                generation &+= 1
                lifecycleState = .closed
                captureTask = nil
                requestStopIfNeeded()
                emitDismissal(using: onSaved)
            } else {
                lifecycleState = .ready
                captureTask = nil
                errorMessage = String(
                    localized: "camera.bellyTracking.errorSave",
                    defaultValue: "We couldn't save your belly tracking photo."
                )
            }
        } catch {
            guard isCurrent(operationGeneration, lifecycle: .capturing) else { return }
            lifecycleState = .ready
            captureTask = nil
            errorMessage = captureErrorMessage
        }
    }

    private func isCurrent(
        _ operationGeneration: Int,
        lifecycle expectedLifecycle: BellyTrackingCameraLifecycleState
    ) -> Bool {
        operationGeneration == generation
            && lifecycleState == expectedLifecycle
            && !Task.isCancelled
    }

    private func requestStopIfNeeded() {
        guard !didRequestStop else { return }

        didRequestStop = true
        let captureService = captureService
        stopTask = Task {
            await captureService.stopRunning()
        }
    }

    private func emitDismissal(using handler: BellyTrackingCameraDismissHandler) {
        guard !didEmitDismissal else { return }

        didEmitDismissal = true
        handler()
    }

    private var captureErrorMessage: String {
        String(
            localized: "camera.bellyTracking.errorCapture",
            defaultValue: "We couldn't capture the photo. Please try again."
        )
    }
}
