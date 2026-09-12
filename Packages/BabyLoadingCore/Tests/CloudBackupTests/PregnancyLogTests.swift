import CloudBackup
import Foundation
import Testing

struct PregnancyLogTests {
    @Test func historicalPhotoRetainsUnknownWeekAndMissingRemoteImage() throws {
        let data = Data("""
        {
            "id": "historical-ultrasound",
            "localImagePath": "gallery/historical.heic",
            "syncStatus": "pending"
        }
        """.utf8)

        let log = try JSONDecoder().decode(PregnancyLog.self, from: data)

        #expect(log.id == "historical-ultrasound")
        #expect(log.weekNumber == nil)
        #expect(log.notes == nil)
        #expect(log.localImagePath == "gallery/historical.heic")
        #expect(log.remoteImageUrl == nil)
        #expect(log.syncStatus == .pending)
    }

    @Test(arguments: [SyncStatus.pending, .uploading, .synced])
    func localRecordRoundTripPreservesItsFields(status: SyncStatus) throws {
        let original = PregnancyLog(
            id: "tracking-photo",
            weekNumber: 24,
            notes: "First movement — primer movimiento",
            localImagePath: "belly-tracking/photo.heic",
            remoteImageUrl: "https://example.com/photo.jpg",
            syncStatus: status
        )

        let data = try JSONEncoder().encode(original)
        let restored = try JSONDecoder().decode(PregnancyLog.self, from: data)

        #expect(restored == original)
    }

    @Test func unsupportedSyncStatusIsRejected() {
        let data = Data("""
        {"id":"photo","syncStatus":"unrecognized"}
        """.utf8)

        #expect(throws: DecodingError.self) {
            try JSONDecoder().decode(PregnancyLog.self, from: data)
        }
    }
}
