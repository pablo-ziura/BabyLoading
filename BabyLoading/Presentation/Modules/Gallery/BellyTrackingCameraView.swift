import AVFoundation
import SwiftUI
#if canImport(UIKit)
    import UIKit
#endif

struct BellyTrackingCameraView: View {
    private let referenceImageData: Data?
    private let onPhotoCaptured: AsyncBellyTrackingCaptureHandler

    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: BellyTrackingCameraViewModel

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
                defaultValue: "Camera error"
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
            Button(String(localized: "common.ok", defaultValue: "OK"), role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
    }

    private var authorizedCameraView: some View {
        ZStack {
            CameraPreviewView(session: viewModel.session)
                .ignoresSafeArea()

            if let referenceImage, viewModel.hasReferenceImage, viewModel.isShowingReference {
                Image(uiImage: referenceImage)
                    .resizable()
                    .scaledToFill()
                    .opacity(viewModel.referenceOpacity)
                    .ignoresSafeArea()
                    .allowsHitTesting(false)
            }

            BellyTrackingGridOverlay()
                .stroke(.white.opacity(0.25), style: StrokeStyle(lineWidth: 1, dash: [6, 6]))
                .ignoresSafeArea()
                .allowsHitTesting(false)
        }
        .safeAreaInset(edge: .top, spacing: 0) {
            headerBar
                .padding(.horizontal, 20)
                .padding(.top, 12)
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            bottomControls
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 12)
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
                    .font(.system(.headline, design: .rounded))
                    .foregroundStyle(.white)

                Text("camera.bellyTracking.instructions")
                    .font(.system(.caption, design: .rounded))
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
                        .font(.system(.subheadline, design: .rounded))
                        .fontWeight(.semibold)
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
                    .tint(.pink)
                }

                if viewModel.isShowingReference {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("camera.bellyTracking.referenceOpacity")
                            .font(.system(.caption, design: .rounded))
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
                    let didSave = await viewModel.capturePhoto(save: onPhotoCaptured)
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
                            .font(.system(.headline, design: .rounded))
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
                .font(.system(.title3, design: .rounded))
                .fontWeight(.bold)
                .foregroundStyle(.white)

            Text(subtitleKey)
                .font(.system(.body, design: .rounded))
                .multilineTextAlignment(.center)
                .foregroundStyle(.white.opacity(0.8))

            Button(String(localized: "camera.bellyTracking.close", defaultValue: "Close")) {
                dismiss()
            }
            .font(.system(.headline, design: .rounded))
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

    func makeUIView(context: Context) -> PreviewView {
        let view = PreviewView()
        view.videoPreviewLayer.videoGravity = .resizeAspectFill
        view.videoPreviewLayer.session = session
        return view
    }

    func updateUIView(_ uiView: PreviewView, context: Context) {
        uiView.videoPreviewLayer.session = session
    }
}

private final class PreviewView: UIView {
    override class var layerClass: AnyClass {
        AVCaptureVideoPreviewLayer.self
    }

    var videoPreviewLayer: AVCaptureVideoPreviewLayer {
        layer as! AVCaptureVideoPreviewLayer
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
