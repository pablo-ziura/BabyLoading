import SwiftUI
import PhotosUI
#if canImport(UIKit)
import UIKit
#endif

struct ContentView: View {
    @State private var viewModel = BabyProgressViewModel()
    @State private var selectedItem: PhotosPickerItem?
    @Environment(\.scenePhase) private var scenePhase

    private let gradientTop = Color(red: 1.0, green: 0.75, blue: 0.82)
    private let gradientBottom = Color(red: 0.78, green: 0.72, blue: 0.96)

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [gradientTop, gradientBottom],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 24) {

                    // MARK: - Header
                    VStack(spacing: 8) {
                        Text("Baby Loading…")
                            .font(.system(.largeTitle, design: .rounded))
                            .fontWeight(.bold)
                            .foregroundStyle(.white)

                        Text("¿Cuándo es el gran día?")
                            .font(.headline)
                            .foregroundStyle(.white.opacity(0.85))
                    }
                    .padding(.top, 30)

                    // MARK: - Photo Section
                    photoSection
                        .padding(.horizontal)

                    // MARK: - Date Picker
                    DatePicker(
                        "Fecha del evento",
                        selection: $viewModel.eventDate,
                        in: Date.now...,
                        displayedComponents: [.date]
                    )
                    .datePickerStyle(.graphical)
                    .environment(\.locale, .current)
                    .tint(.pink)
                    .padding()
                    .background(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                    .shadow(color: .black.opacity(0.1), radius: 12, y: 6)
                    .padding(.horizontal)

                    // MARK: - Set Date Button
                    Button {
                        viewModel.updateDate(viewModel.eventDate)
                    } label: {
                        Text("Fijar fecha ✨")
                            .font(.headline)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                LinearGradient(
                                    colors: [.pink, .purple.opacity(0.8)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .clipShape(Capsule())
                            .shadow(color: .pink.opacity(0.4), radius: 10, y: 5)
                    }
                    .padding(.horizontal, 40)
                    .padding(.top, 8)

                    // MARK: - Pregnancy Info
                    if let days = viewModel.daysRemaining {
                        VStack(spacing: 10) {
                            Text("⏳ Faltan **\(days) días**")
                                .font(.title3)
                                .foregroundStyle(.primary)

                            if let week = viewModel.pregnancyWeek {
                                Text("Semana **\(week)** de embarazo")
                                    .font(.headline)
                                    .foregroundStyle(.secondary)
                            }

                            if let size = viewModel.babySizeString {
                                Divider()
                                    .padding(.horizontal, 40)
                                Text("Tu bebé ahora es del tamaño de \(size)")
                                    .font(.subheadline)
                                    .lineLimit(2)
                                    .multilineTextAlignment(.center)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .multilineTextAlignment(.center)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                        .padding(.horizontal)
                    }

                    Spacer(minLength: 30)
                }
            }
        }
        .onChange(of: selectedItem) { _, newItem in
            handlePhotoSelection(newItem)
        }
    }

    // MARK: - Photo Section View

    @ViewBuilder
    private var photoSection: some View {
        if let photoData = viewModel.photoData,
           let uiImage = UIImage(data: photoData) {
            // Photo loaded — show it
            ZStack(alignment: .topTrailing) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(height: 220)
                    .frame(maxWidth: .infinity)
                    .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                    .shadow(color: .black.opacity(0.15), radius: 12, y: 6)

                // Delete button
                Button {
                    withAnimation(.spring(duration: 0.3)) {
                        selectedItem = nil
                        viewModel.deletePhoto()
                    }
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .symbolRenderingMode(.palette)
                        .foregroundStyle(.white, .black.opacity(0.5))
                        .padding(12)
                }
            }
            .transition(.scale.combined(with: .opacity))
        } else {
            // No photo — show placeholder with picker
            PhotosPicker(selection: $selectedItem, matching: .images) {
                VStack(spacing: 12) {
                    Image(systemName: "photo.on.rectangle.angled")
                        .font(.system(size: 40))
                        .foregroundStyle(.white.opacity(0.8))

                    Text("Sube tu ecografía 📸")
                        .font(.headline)
                        .foregroundStyle(.white)

                    Text("Toca para elegir una foto")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.6))
                }
                .frame(maxWidth: .infinity)
                .frame(height: 160)
                .background(.ultraThinMaterial.opacity(0.6))
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .strokeBorder(.white.opacity(0.3), style: StrokeStyle(lineWidth: 2, dash: [8, 6]))
                )
            }
            .transition(.scale.combined(with: .opacity))
        }
    }

    // MARK: - Photo Handling

    private func handlePhotoSelection(_ item: PhotosPickerItem?) {
        guard let item else { return }
        Task {
            if let data = try? await item.loadTransferable(type: Data.self) {
                await MainActor.run {
                    withAnimation(.spring(duration: 0.4)) {
                        viewModel.savePhoto(data)
                    }
                }
            }
        }
    }
}

#Preview {
    ContentView()
}
