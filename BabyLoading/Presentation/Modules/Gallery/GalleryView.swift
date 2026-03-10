import PhotosUI
import SwiftUI
#if canImport(UIKit)
    import UIKit
#endif

struct GalleryView: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    var viewModel: BabyProgressViewModel
    @State private var selectedItems: [PhotosPickerItem] = []

    private var columns: [GridItem] {
        if dynamicTypeSize.isAccessibilitySize {
            [GridItem(.flexible(), spacing: 12)]
        } else {
            [
                GridItem(.flexible(), spacing: 12),
                GridItem(.flexible(), spacing: 12),
            ]
        }
    }

    var body: some View {
        ZStack {
            GradientBackground()

            ScrollView {
                VStack(spacing: 20) {
                    Text("gallery.title")
                        .font(.system(.title2, design: .rounded))
                        .fontWeight(.bold)
                        .foregroundStyle(.primary)
                        .accessibilityAddTraits(.isHeader)
                        .accessibilityHeading(.h1)
                        .padding(.top, 24)


                    LazyVGrid(columns: columns, spacing: 12) {
                        ForEach(Array(viewModel.photosData.enumerated()), id: \.offset) { index, photoData in
                            if let uiImage = UIImage(data: photoData) {
                                ZStack(alignment: .topTrailing) {
                                    Color.clear
                                        .frame(height: 180)
                                        .overlay {
                                            Image(uiImage: uiImage)
                                                .resizable()
                                                .scaledToFill()
                                                .accessibilityLabel(
                                                    Text(
                                                        photoAccessibilityLabel(
                                                            index: index,
                                                            total: viewModel.photosData.count
                                                        )
                                                    )
                                                )
                                        }
                                        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                                        .shadow(color: .black.opacity(0.12), radius: 8, y: 4)

                                    Button {
                                        withAnimation(.spring(duration: 0.3)) {
                                            viewModel.deleteGalleryPhoto(at: index)
                                        }
                                    } label: {
                                        Image(systemName: "xmark.circle.fill")
                                            .font(.title3)
                                            .symbolRenderingMode(.palette)
                                            .foregroundStyle(.white, .black.opacity(0.5))
                                            .padding(8)
                                    }
                                    .accessibilityLabel(
                                        Text(
                                            deletePhotoAccessibilityLabel(
                                                index: index,
                                                total: viewModel.photosData.count
                                            )
                                        )
                                    )
                                    .accessibilityHint(Text("accessibility.gallery.deletePhotoHint"))
                                }
                                .transition(.scale.combined(with: .opacity))
                            }
                        }

                        PhotosPicker(
                            selection: $selectedItems,
                            maxSelectionCount: 10,
                            matching: .images
                        ) {
                            VStack(spacing: 10) {
                                Image(systemName: "plus.circle.fill")
                                    .font(.system(size: 32))
                                    .foregroundStyle(.primary.opacity(0.75))
                                    .accessibilityHidden(true)

                                Text("gallery.addPhoto")
                                    .font(.system(.caption, design: .rounded))
                                    .fontWeight(.medium)
                                    .foregroundStyle(.primary.opacity(0.75))
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 180)
                            .background(.ultraThinMaterial.opacity(0.5))
                            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 20, style: .continuous)
                                    .strokeBorder(.white.opacity(0.3), style: StrokeStyle(lineWidth: 2, dash: [8, 6]))
                            )
                        }
                        .accessibilityHint(Text("accessibility.gallery.addPhotoHint"))
                    }
                    .padding(.horizontal)

                    if viewModel.photosData.isEmpty {
                        VStack(spacing: 8) {
                            Image(systemName: "photo.on.rectangle.angled")
                                .font(.system(size: 40))
                                .foregroundStyle(.primary.opacity(0.45))
                                .accessibilityHidden(true)

                            Text("gallery.emptyTitle")
                                .font(.system(.body, design: .rounded))
                                .foregroundStyle(.primary.opacity(0.8))

                            Text("gallery.emptySubtitle")
                                .font(.system(.caption, design: .rounded))
                                .foregroundStyle(.secondary)
                        }
                        .padding(.top, 40)
                        .accessibilityElement(children: .combine)
                    }

                    Spacer(minLength: 100)
                }
                .frame(maxWidth: 600)
                .frame(maxWidth: .infinity)
            }
        }
        .onChange(of: selectedItems) { _, newItems in
            handlePhotoSelection(newItems)
        }
    }

    private func handlePhotoSelection(_ items: [PhotosPickerItem]) {
        guard !items.isEmpty else { return }
        Task {
            for item in items {
                if let data = try? await item.loadTransferable(type: Data.self) {
                    await MainActor.run {
                        withAnimation(.spring(duration: 0.4)) {
                            viewModel.addGalleryPhoto(data)
                        }
                    }
                }
            }
            await MainActor.run {
                selectedItems = []
            }
        }
    }

    private func photoAccessibilityLabel(index: Int, total: Int) -> String {
        String(
            format: String(
                localized: "accessibility.gallery.photoPosition",
                defaultValue: "Ultrasound photo %1$d of %2$d"
            ),
            locale: .current,
            index + 1,
            total
        )
    }

    private func deletePhotoAccessibilityLabel(index: Int, total: Int) -> String {
        String(
            format: String(
                localized: "accessibility.gallery.deletePhoto",
                defaultValue: "Delete photo %1$d of %2$d"
            ),
            locale: .current,
            index + 1,
            total
        )
    }
}

#Preview {
    ZStack {
        GradientBackground()
        GalleryView(viewModel: BabyProgressViewModel())
    }
}
