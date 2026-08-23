@preconcurrency import AVFoundation
import SwiftUI
import UIKit

struct BellyTrackingCameraPreview: UIViewRepresentable {
    let source: any BellyTrackingCameraPreviewSourceProtocol
    @Binding var captureRotationAngle: CGFloat

    func makeCoordinator() -> Coordinator {
        Coordinator(captureRotationAngle: $captureRotationAngle)
    }

    func makeUIView(context: Context) -> BellyTrackingPreviewView {
        let view = BellyTrackingPreviewView()
        view.videoPreviewLayer.videoGravity = .resizeAspectFill
        view.onCaptureRotationAngleChanged = { [weak coordinator = context.coordinator] rotationAngle in
            DispatchQueue.main.async {
                guard let coordinator else { return }

                if coordinator.captureRotationAngle.wrappedValue != rotationAngle {
                    coordinator.captureRotationAngle.wrappedValue = rotationAngle
                }
            }
        }
        source.connect(to: view)
        return view
    }

    func updateUIView(_ previewView: BellyTrackingPreviewView, context: Context) {
        context.coordinator.captureRotationAngle = $captureRotationAngle
    }

    final class Coordinator {
        var captureRotationAngle: Binding<CGFloat>

        init(captureRotationAngle: Binding<CGFloat>) {
            self.captureRotationAngle = captureRotationAngle
        }
    }
}

final class BellyTrackingPreviewView: UIView, BellyTrackingCameraPreviewTargetProtocol {
    var onCaptureRotationAngleChanged: ((CGFloat) -> Void)?
    private var rotationCoordinator: AVCaptureDevice.RotationCoordinator?

    override static var layerClass: AnyClass {
        AVCaptureVideoPreviewLayer.self
    }

    var videoPreviewLayer: AVCaptureVideoPreviewLayer {
        // swiftlint:disable:next force_cast
        layer as! AVCaptureVideoPreviewLayer
    }

    nonisolated func setSession(_ session: AVCaptureSession) {
        Task { @MainActor [weak self] in
            guard let self else { return }

            videoPreviewLayer.session = session
            if rotationCoordinator == nil,
               let cameraInput = session.inputs.first(where: { $0 is AVCaptureDeviceInput })
                as? AVCaptureDeviceInput {
                rotationCoordinator = AVCaptureDevice.RotationCoordinator(
                    device: cameraInput.device,
                    previewLayer: videoPreviewLayer
                )
            }
            updatePreviewGeometry()
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        updatePreviewGeometry()
    }

    private func updatePreviewGeometry() {
        guard !bounds.isEmpty else { return }

        let previewRotationAngle = rotationCoordinator?.videoRotationAngleForHorizonLevelPreview ?? 0
        if let connection = videoPreviewLayer.connection,
           connection.isVideoRotationAngleSupported(previewRotationAngle) {
            connection.videoRotationAngle = previewRotationAngle
        }

        let captureRotationAngle = rotationCoordinator?.videoRotationAngleForHorizonLevelCapture ?? 0
        onCaptureRotationAngleChanged?(captureRotationAngle)
    }
}
