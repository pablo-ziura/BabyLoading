@testable import BabyLoading
@preconcurrency import AVFoundation
import Foundation
import Testing

@MainActor
struct BellyTrackingCameraViewModelTests {
    @Test
    func unavailableCameraDoesNotConfigureTheSession() async {
        let captureService = BellyTrackingCaptureServiceStub(isCameraAvailable: false)
        let viewModel = makeViewModel(captureService: captureService)

        await viewModel.prepareSession()

        #expect(viewModel.authorizationState == .unavailable)
        let snapshot = await captureService.snapshot()
        #expect(snapshot.prepareCallCount == 0)
        #expect(snapshot.startCallCount == 0)
    }

    @Test
    func deniedAuthorizationDoesNotConfigureTheSession() async {
        let captureService = BellyTrackingCaptureServiceStub(
            authorizationStatus: .notDetermined,
            requestAccessResult: false
        )
        let viewModel = makeViewModel(captureService: captureService)

        await viewModel.prepareSession()

        #expect(viewModel.authorizationState == .denied)
        let snapshot = await captureService.snapshot()
        #expect(snapshot.requestAccessCallCount == 1)
        #expect(snapshot.prepareCallCount == 0)
    }

    @Test
    func authorizedCameraConfiguresAndStartsTheSession() async {
        let captureService = BellyTrackingCaptureServiceStub()
        let viewModel = makeViewModel(captureService: captureService)

        await viewModel.prepareSession()

        #expect(viewModel.authorizationState == .authorized)
        let snapshot = await captureService.snapshot()
        #expect(snapshot.prepareCallCount == 1)
        #expect(snapshot.startCallCount == 1)
    }

    @Test
    func configurationFailureMapsToFailedPresentationState() async {
        let captureService = BellyTrackingCaptureServiceStub(shouldFailPreparation: true)
        let viewModel = makeViewModel(captureService: captureService)

        await viewModel.prepareSession()

        #expect(viewModel.authorizationState == .failed)
        #expect(viewModel.errorMessage != nil)
        let snapshot = await captureService.snapshot()
        #expect(snapshot.startCallCount == 0)
    }

    @Test
    func captureForwardsRotationAndSavesNativePhotoData() async {
        let photoData = Data([0x01, 0x02, 0x03])
        let captureService = BellyTrackingCaptureServiceStub(capturedData: photoData)
        let viewModel = makeViewModel(captureService: captureService)
        await viewModel.prepareSession()
        var savedData: Data?

        let didSave = await viewModel.capturePhoto(captureRotationAngle: 90) { data in
            savedData = data
            return true
        }

        #expect(didSave)
        #expect(savedData == photoData)
        #expect(!viewModel.isCapturing)
        let snapshot = await captureService.snapshot()
        #expect(snapshot.captureRotationAngle == 90)
    }

    @Test
    func captureFailureMapsToPresentationError() async {
        let captureService = BellyTrackingCaptureServiceStub(shouldFailCapture: true)
        let viewModel = makeViewModel(captureService: captureService)
        await viewModel.prepareSession()

        let didSave = await viewModel.capturePhoto(captureRotationAngle: 0) { _ in
            Issue.record("The save handler must not run after a capture failure.")
            return true
        }

        #expect(!didSave)
        #expect(viewModel.errorMessage != nil)
        #expect(!viewModel.isCapturing)
    }

    @Test
    func stoppingTheModelStopsTheCaptureService() async {
        let captureService = BellyTrackingCaptureServiceStub()
        let viewModel = makeViewModel(captureService: captureService)

        await viewModel.stopSession()

        let snapshot = await captureService.snapshot()
        #expect(snapshot.stopCallCount == 1)
    }

    private func makeViewModel(
        captureService: any BellyTrackingCaptureServiceProtocol
    ) -> BellyTrackingCameraViewModel {
        BellyTrackingCameraViewModel(
            hasReferenceImage: true,
            captureService: captureService
        )
    }
}

private struct BellyTrackingCaptureServiceSnapshot: Sendable {
    let requestAccessCallCount: Int
    let prepareCallCount: Int
    let startCallCount: Int
    let stopCallCount: Int
    let captureRotationAngle: CGFloat?
}

private actor BellyTrackingCaptureServiceStub: BellyTrackingCaptureServiceProtocol {
    nonisolated let previewSource: any BellyTrackingCameraPreviewSourceProtocol =
        BellyTrackingCameraPreviewSourceStub()

    private let cameraIsAvailable: Bool
    private let currentAuthorizationStatus: AVAuthorizationStatus
    private let requestAccessResult: Bool
    private let shouldFailPreparation: Bool
    private let capturedData: Data
    private let shouldFailCapture: Bool

    private var requestAccessCallCount = 0
    private var prepareCallCount = 0
    private var startCallCount = 0
    private var stopCallCount = 0
    private var captureRotationAngle: CGFloat?

    init(
        isCameraAvailable: Bool = true,
        authorizationStatus: AVAuthorizationStatus = .authorized,
        requestAccessResult: Bool = true,
        shouldFailPreparation: Bool = false,
        capturedData: Data = Data([0x01]),
        shouldFailCapture: Bool = false
    ) {
        cameraIsAvailable = isCameraAvailable
        currentAuthorizationStatus = authorizationStatus
        self.requestAccessResult = requestAccessResult
        self.shouldFailPreparation = shouldFailPreparation
        self.capturedData = capturedData
        self.shouldFailCapture = shouldFailCapture
    }

    func isCameraAvailable() -> Bool {
        cameraIsAvailable
    }

    func authorizationStatus() -> AVAuthorizationStatus {
        currentAuthorizationStatus
    }

    func requestAccess() -> Bool {
        requestAccessCallCount += 1
        return requestAccessResult
    }

    func prepareSession() throws {
        prepareCallCount += 1
        if shouldFailPreparation {
            throw BellyTrackingCaptureServiceStubError.requestedFailure
        }
    }

    func startRunning() {
        startCallCount += 1
    }

    func stopRunning() {
        stopCallCount += 1
    }

    func capturePhoto(rotationAngle: CGFloat) throws -> Data {
        captureRotationAngle = rotationAngle
        if shouldFailCapture {
            throw BellyTrackingCaptureServiceStubError.requestedFailure
        }
        return capturedData
    }

    func snapshot() -> BellyTrackingCaptureServiceSnapshot {
        BellyTrackingCaptureServiceSnapshot(
            requestAccessCallCount: requestAccessCallCount,
            prepareCallCount: prepareCallCount,
            startCallCount: startCallCount,
            stopCallCount: stopCallCount,
            captureRotationAngle: captureRotationAngle
        )
    }
}

private struct BellyTrackingCameraPreviewSourceStub: BellyTrackingCameraPreviewSourceProtocol {
    func connect(to target: any BellyTrackingCameraPreviewTargetProtocol) {}
}

private enum BellyTrackingCaptureServiceStubError: Error {
    case requestedFailure
}
