import SwiftUI
import PhotosUI
#if canImport(UIKit)
import UIKit
#endif

struct GalleryView: View {
    var viewModel: BabyProgressViewModel
    @State private var selectedItems: [PhotosPickerItem] = []

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {

                // MARK: - Header
                Text("Galería de ecografías")
                    .font(.system(.title2, design: .rounded))
                    .fontWeight(.bold)
                    .foregroundStyle(.white)
                    .padding(.top, 24)

                // MARK: - Photo Grid
                LazyVGrid(columns: columns, spacing: 12) {

                    // Existing photos
                    ForEach(Array(viewModel.photosData.enumerated()), id: \.offset) { index, photoData in
                        if let uiImage = UIImage(data: photoData) {
                            ZStack(alignment: .topTrailing) {
                                Color.clear
                                    .frame(height: 180)
                                    .overlay {
                                        Image(uiImage: uiImage)
                                            .resizable()
                                            .scaledToFill()
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
                            }
                            .transition(.scale.combined(with: .opacity))
                        }
                    }

                    // Add photo button
                    PhotosPicker(
                        selection: $selectedItems,
                        maxSelectionCount: 10,
                        matching: .images
                    ) {
                        VStack(spacing: 10) {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 32))
                                .foregroundStyle(.white.opacity(0.7))

                            Text("Añadir foto")
                                .font(.system(.caption, design: .rounded))
                                .fontWeight(.medium)
                                .foregroundStyle(.white.opacity(0.7))
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
                }
                .padding(.horizontal)

                // MARK: - Placeholder hint
                if viewModel.photosData.isEmpty {
                    VStack(spacing: 8) {
                        Image(systemName: "photo.on.rectangle.angled")
                            .font(.system(size: 40))
                            .foregroundStyle(.white.opacity(0.4))

                        Text("Aquí aparecerán tus ecografías 📸")
                            .font(.system(.body, design: .rounded))
                            .foregroundStyle(.white.opacity(0.6))

                        Text("Toca el + para subir tu primera foto")
                            .font(.system(.caption, design: .rounded))
                            .foregroundStyle(.white.opacity(0.4))
                    }
                    .padding(.top, 40)
                }

                Spacer(minLength: 100)
            }
            .frame(maxWidth: 600)
            .frame(maxWidth: .infinity)
        }
        .onChange(of: selectedItems) { _, newItems in
            handlePhotoSelection(newItems)
        }
    }

    // MARK: - Photo Handling

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
}

#Preview {
    ZStack {
        GradientBackground()
        GalleryView(viewModel: BabyProgressViewModel())
    }
}
