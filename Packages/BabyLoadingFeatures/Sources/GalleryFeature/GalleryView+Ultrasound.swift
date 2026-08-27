#if os(iOS)
import BabyLoadingDesignComponents
import BabyLoadingDesignTokens
import PhotosUI
import SwiftUI
import UltrasoundGallery
import UIKit

extension GalleryView {
    var ultrasoundGallerySection: some View {
        let isImportingPhotos = viewModel.isImportingPhotos

        return VStack(alignment: .leading, spacing: 18) {
            VStack(alignment: .leading, spacing: 6) {
                Text("gallery.title")
                    .font(BabyLoadingTypography.text(.title3, weight: .bold))
                    .accessibilityAddTraits(.isHeader)

                Text("gallery.freePhotosSubtitle")
                    .font(BabyLoadingTypography.text(.subheadline))
                    .foregroundStyle(.secondary)
            }

            LazyVGrid(columns: photoColumns, spacing: 12) {
                ForEach(viewModel.ultrasoundPhotos) { photo in
                    if let uiImage = UIImage(data: photo.data) {
                        ultrasoundPhotoCard(photo, image: uiImage)
                    }
                }

                PhotosPicker(
                    selection: photoPickerSelectionBinding,
                    maxSelectionCount: 10,
                    matching: .images
                ) {
                    VStack(spacing: 10) {
                        if isImportingPhotos {
                            ProgressView()
                                .accessibilityLabel(Text("gallery.addPhoto"))
                        } else {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 32))
                                .foregroundStyle(.primary.opacity(0.75))
                                .accessibilityHidden(true)

                            Text("gallery.addPhoto")
                                .font(BabyLoadingTypography.text(.caption, weight: .medium))
                                .foregroundStyle(.primary.opacity(0.75))
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 180)
                    .background(.ultraThinMaterial.opacity(0.5))
                    .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .strokeBorder(
                                .white.opacity(0.3),
                                style: StrokeStyle(lineWidth: 2, dash: [8, 6])
                            )
                    )
                }
                .disabled(isImportingPhotos)
                .accessibilityHint(Text("accessibility.gallery.addPhotoHint"))
            }
            .animation(.spring(duration: 0.3), value: viewModel.ultrasoundPhotos.map(\.id))

            if viewModel.ultrasoundPhotos.isEmpty {
                emptyUltrasoundGallery
            }
        }
        .softCard()
    }

    private var photoColumns: [GridItem] {
        if dynamicTypeSize.isAccessibilitySize {
            [GridItem(.flexible(), spacing: 12)]
        } else {
            [
                GridItem(.flexible(), spacing: 12),
                GridItem(.flexible(), spacing: 12)
            ]
        }
    }

    private func ultrasoundPhotoCard(_ photo: UltrasoundPhoto, image: UIImage) -> some View {
        ZStack(alignment: .topTrailing) {
            Color.clear
                .frame(height: 180)
                .overlay {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .accessibilityLabel(
                            Text(
                                photoAccessibilityLabel(
                                    index: ultrasoundPhotoIndex(photo),
                                    total: viewModel.ultrasoundPhotos.count
                                )
                            )
                        )
                }
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                .shadow(color: .black.opacity(0.12), radius: 8, y: 4)

            Button {
                Task {
                    await viewModel.deleteUltrasoundPhoto(id: photo.id)
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
                        index: ultrasoundPhotoIndex(photo),
                        total: viewModel.ultrasoundPhotos.count
                    )
                )
            )
            .accessibilityHint(Text("accessibility.gallery.deletePhotoHint"))
        }
        .transition(.scale.combined(with: .opacity))
    }

    private var emptyUltrasoundGallery: some View {
        VStack(spacing: 8) {
            Image("illustration_ultrasound_camera")
                .resizable()
                .scaledToFit()
                .frame(width: 64, height: 64)
                .accessibilityHidden(true)

            Text("gallery.emptyTitle")
                .font(BabyLoadingTypography.text(.body))
                .foregroundStyle(.primary.opacity(0.8))

            Text("gallery.emptySubtitle")
                .font(BabyLoadingTypography.text(.caption))
                .foregroundStyle(.secondary)
        }
        .padding(.top, 12)
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
    }

    private var photoPickerSelectionBinding: Binding<[PhotosPickerItem]> {
        Binding(
            get: { viewModel.selectedPhotoPickerItems },
            set: { viewModel.selectedPhotoPickerItems = $0 }
        )
    }

    private func photoAccessibilityLabel(index: Int, total: Int) -> String {
        String(
            format: String(
                localized: "accessibility.gallery.photoPosition",
                defaultValue: "Ultrasound photo %1$d of %2$d",
                locale: locale
            ),
            locale: locale,
            index + 1,
            total
        )
    }

    private func deletePhotoAccessibilityLabel(index: Int, total: Int) -> String {
        String(
            format: String(
                localized: "accessibility.gallery.deletePhoto",
                defaultValue: "Delete photo %1$d of %2$d",
                locale: locale
            ),
            locale: locale,
            index + 1,
            total
        )
    }

    private func ultrasoundPhotoIndex(_ photo: UltrasoundPhoto) -> Int {
        viewModel.ultrasoundPhotos.firstIndex(where: { $0.id == photo.id }) ?? 0
    }
}
#endif
