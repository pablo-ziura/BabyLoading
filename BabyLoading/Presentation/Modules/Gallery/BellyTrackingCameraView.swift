import AVFoundation
import BabyLoadingDesignTokens
import SwiftUI
#if canImport(UIKit)
    import UIKit
#endif

typealias AsyncBellyTrackingCaptureHandler = @MainActor (Data) async -> Bool

struct BellyTrackingCameraView: View {
    private let referenceImageData: Data?
    private let onPhotoCaptured: AsyncBellyTrackingCaptureHandler

    @Environment(\.dismiss) private var dismiss
    @Environment(\.locale) private var locale
    @State private var viewModel: BellyTrackingCameraViewModel
    @State private var captureRotationAngle: CGFloat = 0

    init(
        referenceImageData: Data?,
        onPhotoCaptured: @escaping AsyncBellyTrackingCaptureHandler
    ) {
        self.referenceImageData = referenceImageData
        self.onPhotoCaptured = onPhotoCaptured
        _viewModel = State(initialValue: BellyTrackingCameraViewModel(hasReferenceImage: referenceImageData != nil))
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            switch viewModel.authorizationState {
            case .authorized:
                authorizedCameraView
            case .requesting, .idle:
                ProgressView()
                    .progressViewStyle(.circular)
                    .tint(.white)
            case .denied:
                cameraMessageView(
                    titleKey: "camera.bellyTracking.permissionDeniedTitle",
                    subtitleKey: "camera.bellyTracking.permissionDeniedSubtitle",
                    symbol: "camera.fill.badge.ellipsis"
                )
            case .unavailable:
                cameraMessageView(
                    titleKey: "camera.bellyTracking.unavailableTitle",
                    subtitleKey: "camera.bellyTracking.unavailableSubtitle",
                    symbol: "camera.metering.unknown"
                )
            case .failed:
                cameraMessageView(
                    titleKey: "camera.bellyTracking.errorTitle",
                    subtitleKey: "camera.bellyTracking.errorCapture",
                    symbol: "exclamationmark.triangle.fill"
                )
            }
        }
        .task {
            await viewModel.prepareSession()
        }
        .onDisappear {
            viewModel.stopSession()
        }
        .alert(
            String(
                localized: "camera.bellyTracking.errorTitle",
                defaultValue: "Camera error",
                locale: locale
            ),
            isPresented: Binding(
                get: { viewModel.errorMessage != nil },
                set: { isPresented in
                    if !isPresented {
                        viewModel.clearError()
                    }
                }
            )
        ) {
            Button(String(localized: "common.ok", defaultValue: "OK", locale: locale), role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
    }

    private var authorizedCameraView: some View {
        GeometryReader { proxy in
            let guideSize = BellyTrackingGuideViewport(
                photoAspectRatio: BellyTrackingGuideViewport.defaultPhotoAspectRatio
            )
            .size(in: proxy.size)

            ZStack {
                CameraPreviewView(
                    session: viewModel.session,
                    cameraDevice: viewModel.cameraDevice,
                    captureRotationAngle: $captureRotationAngle
                )
                    .frame(width: guideSize.width, height: guideSize.height)
                    .clipped()

                if let referenceImage, viewModel.hasReferenceImage, viewModel.isShowingReference {
                    Image(uiImage: referenceImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: guideSize.width, height: guideSize.height)
                        .clipped()
                        .opacity(viewModel.referenceOpacity)
                        .allowsHitTesting(false)
                }

                BellyTrackingGridOverlay()
                    .stroke(.white.opacity(0.25), style: StrokeStyle(lineWidth: 1, dash: [6, 6]))
                    .frame(width: guideSize.width, height: guideSize.height)
                    .allowsHitTesting(false)

                Rectangle()
                    .stroke(.white.opacity(0.45), lineWidth: 1)
                    .frame(width: guideSize.width, height: guideSize.height)
                    .allowsHitTesting(false)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .overlay(alignment: .top) {
                headerBar
                    .padding(.horizontal, 20)
                    .padding(.top, 12)
            }
            .overlay(alignment: .bottom) {
                bottomControls
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    .padding(.bottom, 12)
            }
        }
    }

    private var headerBar: some View {
        HStack {
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .padding(12)
                    .background(.black.opacity(0.45), in: Circle())
            }

            Spacer()

            VStack(spacing: 4) {
                Text("camera.bellyTracking.title")
                    .font(BabyLoadingTypography.text(.headline, weight: .semibold))
                    .foregroundStyle(.white)

                Text("camera.bellyTracking.instructions")
                    .font(BabyLoadingTypography.text(.caption))
                    .foregroundStyle(.white.opacity(0.8))
            }
            .multilineTextAlignment(.center)

            Spacer()

            Color.clear
                .frame(width: 44, height: 44)
        }
        .frame(maxWidth: .infinity)
    }

    private var bottomControls: some View {
        VStack(alignment: .leading, spacing: 18) {
            if viewModel.hasReferenceImage {
                HStack(alignment: .center, spacing: 12) {
                    Text("camera.bellyTracking.referenceToggle")
                        .font(BabyLoadingTypography.text(.subheadline, weight: .semibold))
                        .foregroundStyle(.white)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)

                    Spacer(minLength: 12)

                    Toggle(
                        "",
                        isOn: Binding(
                            get: { viewModel.isShowingReference },
                            set: { viewModel.isShowingReference = $0 }
                        )
                    )
                    .labelsHidden()
                    .tint(BabyLoadingColors.selectionAccent)
                }

                if viewModel.isShowingReference {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("camera.bellyTracking.referenceOpacity")
                            .font(BabyLoadingTypography.text(.caption))
                            .foregroundStyle(.white.opacity(0.8))

                        Slider(
                            value: Binding(
                                get: { viewModel.referenceOpacity },
                                set: { viewModel.referenceOpacity = $0 }
                            ),
                            in: 0...0.7
                        )
                        .tint(.white)
                    }
                }
            }

            Button {
                Task {
                    let didSave = await viewModel.capturePhoto(
                        captureRotationAngle: captureRotationAngle,
                        save: onPhotoCaptured
                    )
                    if didSave {
                        dismiss()
                    }
                }
            } label: {
                HStack {
                    Spacer()
                    if viewModel.isCapturing {
                        ProgressView()
                            .progressViewStyle(.circular)
                            .tint(.black)
                    } else {
                        Label("camera.bellyTracking.capture", systemImage: "camera.circle.fill")
                            .font(BabyLoadingTypography.text(.headline, weight: .semibold))
                    }
                    Spacer()
                }
                .padding(.vertical, 16)
                .background(.white, in: Capsule())
                .foregroundStyle(.black)
            }
            .disabled(viewModel.isCapturing)
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.black.opacity(0.55))
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
    }

    private func cameraMessageView(
        titleKey: LocalizedStringKey,
        subtitleKey: LocalizedStringKey,
        symbol: String
    ) -> some View {
        VStack(spacing: 18) {
            Image(systemName: symbol)
                .font(.system(size: 48))
                .foregroundStyle(.white.opacity(0.9))

            Text(titleKey)
                .font(BabyLoadingTypography.text(.title3, weight: .bold))
                .foregroundStyle(.white)

            Text(subtitleKey)
                .font(BabyLoadingTypography.text(.body))
                .multilineTextAlignment(.center)
                .foregroundStyle(.white.opacity(0.8))

            Button(String(localized: "camera.bellyTracking.close", defaultValue: "Close", locale: locale)) {
                dismiss()
            }
            .font(BabyLoadingTypography.text(.headline, weight: .semibold))
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(.white, in: Capsule())
            .foregroundStyle(.black)
        }
        .padding(28)
    }

    private var referenceImage: UIImage? {
        #if canImport(UIKit)
            referenceImageData.flatMap(UIImage.init(data:))
        #else
            nil
        #endif
    }

}

private struct CameraPreviewView: UIViewRepresentable {
    let session: AVCaptureSession
    let cameraDevice: AVCaptureDevice?
    @Binding var captureRotationAngle: CGFloat

    func makeCoordinator() -> Coordinator {
        Coordinator(captureRotationAngle: $captureRotationAngle)
    }

    func makeUIView(context: Context) -> PreviewView {
        let view = PreviewView()
        view.videoPreviewLayer.videoGravity = .resizeAspectFill
        view.onCaptureRotationAngleChanged = { [weak coordinator = context.coordinator] rotationAngle in
            DispatchQueue.main.async {
                guard let coordinator else { return }

                if coordinator.captureRotationAngle.wrappedValue != rotationAngle {
                    coordinator.captureRotationAngle.wrappedValue = rotationAngle
                }
            }
        }
        view.configure(session: session, cameraDevice: cameraDevice)
        return view
    }

    func updateUIView(_ uiView: PreviewView, context: Context) {
        context.coordinator.captureRotationAngle = $captureRotationAngle
        uiView.configure(session: session, cameraDevice: cameraDevice)
    }

    final class Coordinator {
        var captureRotationAngle: Binding<CGFloat>

        init(captureRotationAngle: Binding<CGFloat>) {
            self.captureRotationAngle = captureRotationAngle
        }
    }
}

private final class PreviewView: UIView {
    var onCaptureRotationAngleChanged: ((CGFloat) -> Void)?
    private var rotationCoordinator: AVCaptureDevice.RotationCoordinator?

    override class var layerClass: AnyClass {
        AVCaptureVideoPreviewLayer.self
    }

    var videoPreviewLayer: AVCaptureVideoPreviewLayer {
        // swiftlint:disable:next force_cast
        layer as! AVCaptureVideoPreviewLayer
    }

    func configure(
        session: AVCaptureSession,
        cameraDevice: AVCaptureDevice?
    ) {
        videoPreviewLayer.session = session

        if rotationCoordinator == nil, let cameraDevice {
            rotationCoordinator = AVCaptureDevice.RotationCoordinator(
                device: cameraDevice,
                previewLayer: videoPreviewLayer
            )
        }

        updatePreviewGeometry()
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

private struct BellyTrackingGridOverlay: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()

        let thirdWidth = rect.width / 3
        let thirdHeight = rect.height / 3

        path.move(to: CGPoint(x: thirdWidth, y: 0))
        path.addLine(to: CGPoint(x: thirdWidth, y: rect.height))

        path.move(to: CGPoint(x: thirdWidth * 2, y: 0))
        path.addLine(to: CGPoint(x: thirdWidth * 2, y: rect.height))

        path.move(to: CGPoint(x: 0, y: thirdHeight))
        path.addLine(to: CGPoint(x: rect.width, y: thirdHeight))

        path.move(to: CGPoint(x: 0, y: thirdHeight * 2))
        path.addLine(to: CGPoint(x: rect.width, y: thirdHeight * 2))

        return path
    }
}
