@testable import GalleryFeature
@preconcurrency import AVFoundation
import Foundation

struct BellyTrackingCaptureServiceSnapshot: Sendable {
    let requestAccessCallCount: Int
    let prepareCallCount: Int
    let startCallCount: Int
    let stopCallCount: Int
    let captureCallCount: Int
    let captureRotationAngle: CGFloat?
}

actor BellyTrackingCaptureServiceStub: BellyTrackingCaptureServiceProtocol {
    nonisolated let previewSource: any BellyTrackingCameraPreviewSourceProtocol =
        BellyTrackingCameraPreviewSourceStub()

    private let cameraIsAvailable: Bool
    private let currentAuthorizationStatus: AVAuthorizationStatus
    private let requestAccessResult: Bool
    private let shouldFailPreparation: Bool
    private let capturedData: Data
    private let shouldFailCapture: Bool
    private let suspendRequestAccess: Bool
    private let suspendPreparation: Bool
    private let suspendCapture: Bool

    private var requestAccessContinuation: CheckedContinuation<Bool, Never>?
    private var preparationContinuation: CheckedContinuation<Void, Never>?
    private var captureContinuation: CheckedContinuation<Void, Never>?
    private var requestAccessCallCount = 0
    private var prepareCallCount = 0
    private var startCallCount = 0
    private var stopCallCount = 0
    private var captureCallCount = 0
    private var captureRotationAngle: CGFloat?

    init(
        isCameraAvailable: Bool = true,
        authorizationStatus: AVAuthorizationStatus = .authorized,
        requestAccessResult: Bool = true,
        shouldFailPreparation: Bool = false,
        capturedData: Data = Data([0x01]),
        shouldFailCapture: Bool = false,
        suspendRequestAccess: Bool = false,
        suspendPreparation: Bool = false,
        suspendCapture: Bool = false
    ) {
        cameraIsAvailable = isCameraAvailable
        currentAuthorizationStatus = authorizationStatus
        self.requestAccessResult = requestAccessResult
        self.shouldFailPreparation = shouldFailPreparation
        self.capturedData = capturedData
        self.shouldFailCapture = shouldFailCapture
        self.suspendRequestAccess = suspendRequestAccess
        self.suspendPreparation = suspendPreparation
        self.suspendCapture = suspendCapture
    }

    func isCameraAvailable() -> Bool {
        cameraIsAvailable
    }

    func authorizationStatus() -> AVAuthorizationStatus {
        currentAuthorizationStatus
    }

    func requestAccess() async -> Bool {
        requestAccessCallCount += 1
        if suspendRequestAccess {
            return await withCheckedContinuation { continuation in
                requestAccessContinuation = continuation
            }
        }
        return requestAccessResult
    }

    func prepareSession() async throws {
        prepareCallCount += 1
        if suspendPreparation {
            await withCheckedContinuation { continuation in
                preparationContinuation = continuation
            }
        }
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

    func capturePhoto(rotationAngle: CGFloat) async throws -> Data {
        captureCallCount += 1
        captureRotationAngle = rotationAngle
        if suspendCapture {
            await withCheckedContinuation { continuation in
                captureContinuation = continuation
            }
        }
        if shouldFailCapture {
            throw BellyTrackingCaptureServiceStubError.requestedFailure
        }
        return capturedData
    }

    func resumeRequestAccess() {
        requestAccessContinuation?.resume(returning: requestAccessResult)
        requestAccessContinuation = nil
    }

    func resumePreparation() {
        preparationContinuation?.resume()
        preparationContinuation = nil
    }

    func resumeCapture() {
        captureContinuation?.resume()
        captureContinuation = nil
    }

    func snapshot() -> BellyTrackingCaptureServiceSnapshot {
        BellyTrackingCaptureServiceSnapshot(
            requestAccessCallCount: requestAccessCallCount,
            prepareCallCount: prepareCallCount,
            startCallCount: startCallCount,
            stopCallCount: stopCallCount,
            captureCallCount: captureCallCount,
            captureRotationAngle: captureRotationAngle
        )
    }
}

private struct BellyTrackingCameraPreviewSourceStub: BellyTrackingCameraPreviewSourceProtocol {
    func connect(to target: any BellyTrackingCameraPreviewTargetProtocol) {}
}

actor BellyTrackingSaveGate {
    private var continuation: CheckedContinuation<Bool, Never>?
    private var callCount = 0
    private var data: Data?

    func save(_ data: Data) async -> Bool {
        callCount += 1
        self.data = data
        return await withCheckedContinuation { continuation in
            self.continuation = continuation
        }
    }

    func resume(with result: Bool) {
        continuation?.resume(returning: result)
        continuation = nil
    }

    func snapshot() -> BellyTrackingSaveSnapshot {
        BellyTrackingSaveSnapshot(callCount: callCount, data: data)
    }
}

struct BellyTrackingSaveSnapshot: Equatable, Sendable {
    let callCount: Int
    let data: Data?
}

private enum BellyTrackingCaptureServiceStubError: Error {
    case requestedFailure
}
