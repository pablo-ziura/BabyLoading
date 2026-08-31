@testable import GalleryFeature
@preconcurrency import AVFoundation
import Foundation
import Testing

@MainActor
struct BellyTrackingCameraViewModelTests {
    @Test func unavailableCameraDoesNotConfigureTheSession() async {
        let captureService = BellyTrackingCaptureServiceStub(isCameraAvailable: false)
        let viewModel = makeViewModel(captureService: captureService)

        viewModel.activate()
        await waitUntil { viewModel.authorizationState == .unavailable }

        let snapshot = await captureService.snapshot()
        #expect(snapshot.prepareCallCount == 0)
        #expect(snapshot.startCallCount == 0)
    }

    @Test func deniedAuthorizationDoesNotConfigureTheSession() async {
        let captureService = BellyTrackingCaptureServiceStub(
            authorizationStatus: .notDetermined,
            requestAccessResult: false
        )
        let viewModel = makeViewModel(captureService: captureService)

        viewModel.activate()
        await waitUntil { viewModel.authorizationState == .denied }

        let snapshot = await captureService.snapshot()
        #expect(snapshot.requestAccessCallCount == 1)
        #expect(snapshot.prepareCallCount == 0)
    }

    @Test func authorizedCameraConfiguresAndStartsTheSession() async {
        let captureService = BellyTrackingCaptureServiceStub()
        let viewModel = makeViewModel(captureService: captureService)

        viewModel.activate()
        await waitUntil { viewModel.lifecycleState == .ready }

        #expect(viewModel.authorizationState == .authorized)
        let snapshot = await captureService.snapshot()
        #expect(snapshot.prepareCallCount == 1)
        #expect(snapshot.startCallCount == 1)
    }

    @Test func configurationFailureMapsToFailedPresentationState() async {
        let captureService = BellyTrackingCaptureServiceStub(shouldFailPreparation: true)
        let viewModel = makeViewModel(captureService: captureService)

        viewModel.activate()
        await waitUntil { viewModel.authorizationState == .failed }

        #expect(viewModel.errorMessage != nil)
        let snapshot = await captureService.snapshot()
        #expect(snapshot.startCallCount == 0)
    }

    @Test func closingDuringAuthorizationPreventsPreparationAndStart() async {
        let captureService = BellyTrackingCaptureServiceStub(
            authorizationStatus: .notDetermined,
            suspendRequestAccess: true
        )
        let viewModel = makeViewModel(captureService: captureService)
        var dismissalCount = 0

        viewModel.activate()
        await waitForService(captureService) { $0.requestAccessCallCount == 1 }
        viewModel.close { dismissalCount += 1 }
        await captureService.resumeRequestAccess()
        await settleTasks()

        #expect(viewModel.lifecycleState == .closed)
        #expect(dismissalCount == 1)
        let snapshot = await captureService.snapshot()
        #expect(snapshot.prepareCallCount == 0)
        #expect(snapshot.startCallCount == 0)
        #expect(snapshot.stopCallCount == 1)
    }

    @Test func closingDuringPreparationPreventsLateSessionStart() async {
        let captureService = BellyTrackingCaptureServiceStub(suspendPreparation: true)
        let viewModel = makeViewModel(captureService: captureService)

        viewModel.activate()
        await waitForService(captureService) { $0.prepareCallCount == 1 }
        viewModel.close()
        await captureService.resumePreparation()
        await settleTasks()

        #expect(viewModel.lifecycleState == .closed)
        let snapshot = await captureService.snapshot()
        #expect(snapshot.startCallCount == 0)
        #expect(snapshot.stopCallCount == 1)
    }

    @Test func closingDuringCaptureDiscardsLatePhotoData() async {
        let captureService = BellyTrackingCaptureServiceStub(suspendCapture: true)
        let viewModel = makeViewModel(captureService: captureService)
        var saveCallCount = 0
        var dismissalCount = 0
        await activate(viewModel)

        viewModel.capturePhoto(captureRotationAngle: 90, save: { _ in
            saveCallCount += 1
            return true
        }, onSaved: {
            Issue.record("A cancelled capture must not emit a save dismissal.")
        })
        await waitForService(captureService) { $0.captureCallCount == 1 }
        viewModel.close { dismissalCount += 1 }
        await captureService.resumeCapture()
        await settleTasks()

        #expect(viewModel.lifecycleState == .closed)
        #expect(saveCallCount == 0)
        #expect(dismissalCount == 1)
        #expect(viewModel.errorMessage == nil)
        let snapshot = await captureService.snapshot()
        #expect(snapshot.captureRotationAngle == 90)
        #expect(snapshot.stopCallCount == 1)
    }

    @Test func captureErrorAfterClosingIsIgnored() async {
        let captureService = BellyTrackingCaptureServiceStub(
            shouldFailCapture: true,
            suspendCapture: true
        )
        let viewModel = makeViewModel(captureService: captureService)
        await activate(viewModel)

        viewModel.capturePhoto(captureRotationAngle: 0, save: { _ in true }, onSaved: {})
        await waitForService(captureService) { $0.captureCallCount == 1 }
        viewModel.close()
        await captureService.resumeCapture()
        await settleTasks()

        #expect(viewModel.lifecycleState == .closed)
        #expect(viewModel.errorMessage == nil)
    }

    @Test func closingTwiceStopsAndDismissesOnlyOnce() async {
        let captureService = BellyTrackingCaptureServiceStub()
        let viewModel = makeViewModel(captureService: captureService)
        var dismissalCount = 0
        await activate(viewModel)

        viewModel.close { dismissalCount += 1 }
        viewModel.close { dismissalCount += 1 }
        await settleTasks()

        #expect(dismissalCount == 1)
        let snapshot = await captureService.snapshot()
        #expect(snapshot.stopCallCount == 1)
    }

    @Test func savingIsTheCommitPointAndCompletesExactlyOnce() async {
        let photoData = Data([0x01, 0x02, 0x03])
        let captureService = BellyTrackingCaptureServiceStub(capturedData: photoData)
        let saveGate = BellyTrackingSaveGate()
        let viewModel = makeViewModel(captureService: captureService)
        var closeDismissalCount = 0
        var savedDismissalCount = 0
        await activate(viewModel)

        viewModel.capturePhoto(captureRotationAngle: 90, save: { data in
            await saveGate.save(data)
        }, onSaved: {
            savedDismissalCount += 1
        })
        await waitUntil { viewModel.lifecycleState == .saving }
        viewModel.close { closeDismissalCount += 1 }

        #expect(viewModel.isDismissalDisabled)
        #expect(closeDismissalCount == 0)
        await saveGate.resume(with: true)
        await waitUntil { viewModel.lifecycleState == .closed }
        await settleTasks()

        #expect(await saveGate.snapshot() == BellyTrackingSaveSnapshot(callCount: 1, data: photoData))
        #expect(savedDismissalCount == 1)
        #expect(closeDismissalCount == 0)
        let snapshot = await captureService.snapshot()
        #expect(snapshot.stopCallCount == 1)
    }

    @Test func captureFailureMapsToPresentationError() async {
        let captureService = BellyTrackingCaptureServiceStub(shouldFailCapture: true)
        let viewModel = makeViewModel(captureService: captureService)
        await activate(viewModel)

        viewModel.capturePhoto(captureRotationAngle: 0, save: { _ in
            Issue.record("The save handler must not run after a capture failure.")
            return true
        }, onSaved: {
            Issue.record("A failed capture must not dismiss the camera.")
        })
        await waitUntil { viewModel.lifecycleState == .ready && viewModel.errorMessage != nil }

        #expect(!viewModel.isCapturing)
    }

    private func activate(_ viewModel: BellyTrackingCameraViewModel) async {
        viewModel.activate()
        await waitUntil { viewModel.lifecycleState == .ready }
    }

    private func makeViewModel(
        captureService: any BellyTrackingCaptureServiceProtocol
    ) -> BellyTrackingCameraViewModel {
        BellyTrackingCameraViewModel(
            hasReferenceImage: true,
            captureService: captureService
        )
    }

    private func waitUntil(
        _ condition: @escaping @MainActor () -> Bool
    ) async {
        for _ in 0 ..< 100 where !condition() {
            await Task.yield()
        }
        #expect(condition())
    }

    private func waitForService(
        _ captureService: BellyTrackingCaptureServiceStub,
        condition: (BellyTrackingCaptureServiceSnapshot) -> Bool
    ) async {
        for _ in 0 ..< 100 {
            if condition(await captureService.snapshot()) {
                return
            }
            await Task.yield()
        }
        Issue.record("The capture service did not reach the expected state.")
    }

    private func settleTasks() async {
        for _ in 0 ..< 10 {
            await Task.yield()
        }
    }
}
