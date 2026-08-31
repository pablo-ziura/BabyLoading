#if os(iOS)
import BabyLoadingDesignTokens
import SwiftUI
import UIKit

public struct BellyTrackingCameraView: View {
    private let referenceImageData: Data?
    private let onPhotoCaptured: AsyncBellyTrackingCaptureHandler

    @Environment(\.dismiss) private var dismiss
    @Environment(\.locale) private var locale
    @State private var viewModel: BellyTrackingCameraViewModel
    @State private var captureRotationAngle: CGFloat = 0

    public init(
        referenceImageData: Data?,
        onPhotoCaptured: @escaping AsyncBellyTrackingCaptureHandler
    ) {
        self.referenceImageData = referenceImageData
        self.onPhotoCaptured = onPhotoCaptured
        _viewModel = State(
            initialValue: BellyTrackingCameraViewModel(
                hasReferenceImage: referenceImageData != nil,
                captureService: BellyTrackingCaptureService()
            )
        )
    }

    public var body: some View {
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
        .onAppear {
            viewModel.activate()
        }
        .onDisappear {
            viewModel.close()
        }
        .interactiveDismissDisabled(viewModel.isDismissalDisabled)
        .alert(
            String(
                localized: "camera.bellyTracking.errorTitle",
                defaultValue: "Camera error",
                locale: locale
            ),
            isPresented: cameraErrorBinding
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
                BellyTrackingCameraPreview(
                    source: viewModel.previewSource,
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
                        .accessibilityHidden(true)
                }

                BellyTrackingGridOverlay()
                    .stroke(.white.opacity(0.25), style: StrokeStyle(lineWidth: 1, dash: [6, 6]))
                    .frame(width: guideSize.width, height: guideSize.height)
                    .allowsHitTesting(false)
                    .accessibilityHidden(true)

                Rectangle()
                    .stroke(.white.opacity(0.45), lineWidth: 1)
                    .frame(width: guideSize.width, height: guideSize.height)
                    .allowsHitTesting(false)
                    .accessibilityHidden(true)
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
                closeCamera()
            } label: {
                Image(systemName: "xmark")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .padding(12)
                    .background(.black.opacity(0.45), in: Circle())
            }
            .accessibilityLabel(Text("camera.bellyTracking.close"))

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
                .accessibilityHidden(true)
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
                        .accessibilityHidden(true)

                    Spacer(minLength: 12)

                    Toggle(
                        "camera.bellyTracking.referenceToggle",
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
                            .accessibilityHidden(true)

                        Slider(
                            value: Binding(
                                get: { viewModel.referenceOpacity },
                                set: { viewModel.referenceOpacity = $0 }
                            ),
                            in: 0...0.7
                        )
                        .tint(.white)
                        .accessibilityLabel(Text("camera.bellyTracking.referenceOpacity"))
                    }
                }
            }

            Button {
                viewModel.capturePhoto(
                    captureRotationAngle: captureRotationAngle,
                    save: onPhotoCaptured,
                    onSaved: {
                        dismiss()
                    }
                )
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
            .accessibilityLabel(Text("camera.bellyTracking.capture"))
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
                .accessibilityHidden(true)

            Text(titleKey)
                .font(BabyLoadingTypography.text(.title3, weight: .bold))
                .foregroundStyle(.white)

            Text(subtitleKey)
                .font(BabyLoadingTypography.text(.body))
                .multilineTextAlignment(.center)
                .foregroundStyle(.white.opacity(0.8))

            Button(String(localized: "camera.bellyTracking.close", defaultValue: "Close", locale: locale)) {
                closeCamera()
            }
            .font(BabyLoadingTypography.text(.headline, weight: .semibold))
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(.white, in: Capsule())
            .foregroundStyle(.black)
        }
        .padding(28)
    }

    private var cameraErrorBinding: Binding<Bool> {
        Binding(
            get: { viewModel.errorMessage != nil },
            set: { isPresented in
                if !isPresented {
                    viewModel.clearError()
                }
            }
        )
    }

    private var referenceImage: UIImage? {
        referenceImageData.flatMap(UIImage.init(data:))
    }

    private func closeCamera() {
        viewModel.close {
            dismiss()
        }
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
#endif
