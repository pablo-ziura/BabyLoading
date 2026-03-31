import Foundation
import Photos

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
        guard authorizationStatus.canAddAssets else {
            return .permissionDenied
        }

        return await withCheckedContinuation { continuation in
            PHPhotoLibrary.shared().performChanges {
                let creationRequest = PHAssetCreationRequest.forAsset()
                creationRequest.addResource(with: .photo, data: data, options: nil)
            } completionHandler: { success, error in
                if success, error == nil {
                    continuation.resume(returning: .saved)
                } else {
                    continuation.resume(returning: .failed)
                }
            }
        }
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
