import Foundation
import Photos
#if canImport(UIKit)
    import UIKit
#endif

enum PhotoLibraryExportStatus: Equatable {
    case saved
    case permissionDenied
    case failed
}

protocol PhotoLibraryExporterProtocol {
    func saveImageData(_ data: Data) async -> PhotoLibraryExportStatus
}

struct PhotoLibraryExporter: PhotoLibraryExporterProtocol {
    func saveImageData(_ data: Data) async -> PhotoLibraryExportStatus {
        let authorizationStatus = await resolvedAuthorizationStatus()
        print("📷 [PhotoLibraryExporter] authorizationStatus -> \(authorizationStatus.rawValue)")
        guard authorizationStatus.canAddAssets else {
            print("⚠️ [PhotoLibraryExporter] Photo library access denied")
            return .permissionDenied
        }

        #if canImport(UIKit)
            guard let image = UIImage(data: data) else {
                print("⚠️ [PhotoLibraryExporter] Failed to decode image data")
                return .failed
            }

            return await saveImageToPhotoLibrary(image)
        #else
            return .failed
        #endif
    }

    private func resolvedAuthorizationStatus() async -> PHAuthorizationStatus {
        let currentStatus = PHPhotoLibrary.authorizationStatus(for: .addOnly)
        guard currentStatus == .notDetermined else {
            return currentStatus
        }

        return await withCheckedContinuation { continuation in
            PHPhotoLibrary.requestAuthorization(for: .addOnly) { status in
                continuation.resume(returning: status)
            }
        }
    }

    #if canImport(UIKit)
        @MainActor
        private func saveImageToPhotoLibrary(_ image: UIImage) async -> PhotoLibraryExportStatus {
            await withCheckedContinuation { continuation in
                PhotoAlbumSaveCoordinator.save(image: image) { error in
                    if let error {
                        print("⚠️ [PhotoLibraryExporter] Failed to write image to photo library: \(error.localizedDescription)")
                        continuation.resume(returning: .failed)
                    } else {
                        print("💾 [PhotoLibraryExporter] Image saved to photo library")
                        continuation.resume(returning: .saved)
                    }
                }
            }
        }
    #endif

}

private extension PHAuthorizationStatus {
    var canAddAssets: Bool {
        switch self {
        case .authorized, .limited:
            return true
        case .notDetermined, .denied, .restricted:
            return false
        @unknown default:
            return false
        }
    }
}

#if canImport(UIKit)
    @MainActor
    private final class PhotoAlbumSaveCoordinator: NSObject {
        private let completion: (Error?) -> Void

        private init(completion: @escaping (Error?) -> Void) {
            self.completion = completion
        }

        static func save(image: UIImage, completion: @escaping (Error?) -> Void) {
            let coordinator = PhotoAlbumSaveCoordinator(completion: completion)
            let context = Unmanaged.passRetained(coordinator).toOpaque()
            UIImageWriteToSavedPhotosAlbum(
                image,
                coordinator,
                #selector(PhotoAlbumSaveCoordinator.image(_:didFinishSavingWithError:contextInfo:)),
                context
            )
        }

        @objc
        private func image(
            _ image: UIImage,
            didFinishSavingWithError error: NSError?,
            contextInfo: UnsafeMutableRawPointer?
        ) {
            guard let contextInfo else {
                completion(error)
                return
            }

            let coordinator = Unmanaged<PhotoAlbumSaveCoordinator>.fromOpaque(contextInfo).takeRetainedValue()
            coordinator.completion(error)
        }
    }
#endif
