import Foundation
import Photos

enum PhotoLibraryExportResult: Equatable, Sendable {
    case saved
    case permissionDenied
    case failed
}

protocol PhotoLibraryExportingProtocol: Sendable {
    func saveImageData(_ data: Data) async -> PhotoLibraryExportResult
}

struct PhotoLibraryExporter: PhotoLibraryExportingProtocol {
    func saveImageData(_ data: Data) async -> PhotoLibraryExportResult {
        let authorizationStatus = await PHPhotoLibrary.requestAuthorization(for: .addOnly)
        guard authorizationStatus == .authorized || authorizationStatus == .limited else {
            return .permissionDenied
        }

        do {
            try await PHPhotoLibrary.shared().performChanges {
                let creationRequest = PHAssetCreationRequest.forAsset()
                creationRequest.addResource(with: .photo, data: data, options: nil)
            }
            return .saved
        } catch {
            return .failed
        }
    }
}
