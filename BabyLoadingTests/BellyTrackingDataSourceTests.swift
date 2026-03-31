@testable import BabyLoading
import Foundation
import Testing
import UIKit

struct BellyTrackingDataSourceTests {
    @Test func bellyTrackingPersistsManifestAcrossDataSourceInstances() throws {
        let context = try makeContext()
        defer { cleanup(context) }

        let capturedAt = try #require(isoDate("2026-03-01T09:30:00Z"))

        context.dataSource.saveBellyTrackingSettings(BellyTrackingSettings(intervalDays: 14))
        let entry = try #require(
            context.dataSource.saveBellyTrackingPhoto(
                data: makeImageData(color: .systemPink),
                capturedAt: capturedAt,
                pregnancyWeekAtCapture: 22
            )
        )

        let reloadedDataSource = makeDataSource(context: context)

        #expect(reloadedDataSource.fetchBellyTrackingSettings() == BellyTrackingSettings(intervalDays: 14))
        #expect(reloadedDataSource.fetchBellyTrackingEntries() == [entry])
        #expect(reloadedDataSource.fetchBellyTrackingImageData(for: entry.imageFileName) != nil)
        #expect(reloadedDataSource.fetchAllPhotos().count == 1)
    }

    @Test func bellyTrackingEntriesAreReturnedInChronologicalOrder() throws {
        let context = try makeContext()
        defer { cleanup(context) }

        let firstDate = try #require(isoDate("2026-02-10T08:00:00Z"))
        let secondDate = try #require(isoDate("2026-03-10T08:00:00Z"))

        _ = context.dataSource.saveBellyTrackingPhoto(
            data: makeImageData(color: .systemBlue),
            capturedAt: secondDate,
            pregnancyWeekAtCapture: 24
        )
        _ = context.dataSource.saveBellyTrackingPhoto(
            data: makeImageData(color: .systemGreen),
            capturedAt: firstDate,
            pregnancyWeekAtCapture: 20
        )

        let fetchedEntries = context.dataSource.fetchBellyTrackingEntries()

        #expect(fetchedEntries.map(\.capturedAt) == [firstDate, secondDate])
    }

    @Test func deleteBellyTrackingEntryRemovesImageAndEntry() throws {
        let context = try makeContext()
        defer { cleanup(context) }
        let capturedAt = try #require(isoDate("2026-03-20T10:00:00Z"))

        let entry = try #require(
            context.dataSource.saveBellyTrackingPhoto(
                data: makeImageData(color: .systemOrange),
                capturedAt: capturedAt,
                pregnancyWeekAtCapture: 26
            )
        )

        context.dataSource.deleteBellyTrackingEntry(id: entry.id)

        #expect(context.dataSource.fetchBellyTrackingEntries().isEmpty)
        #expect(context.dataSource.fetchBellyTrackingImageData(for: entry.imageFileName) == nil)
    }

    private func makeContext() throws -> DataSourceTestContext {
        let temporaryDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: temporaryDirectory, withIntermediateDirectories: true)

        let suiteName = "BellyTrackingDataSourceTests.\(UUID().uuidString)"
        let userDefaults = try #require(UserDefaults(suiteName: suiteName))
        userDefaults.removePersistentDomain(forName: suiteName)

        return DataSourceTestContext(
            dataSource: BabyProgressDataSource(
                suiteName: suiteName,
                userDefaults: userDefaults,
                fileManager: .default,
                containerURL: temporaryDirectory
            ),
            suiteName: suiteName,
            userDefaults: userDefaults,
            containerURL: temporaryDirectory
        )
    }

    private func makeDataSource(context: DataSourceTestContext) -> BabyProgressDataSource {
        BabyProgressDataSource(
            suiteName: context.suiteName,
            userDefaults: context.userDefaults,
            fileManager: .default,
            containerURL: context.containerURL
        )
    }

    private func cleanup(_ context: DataSourceTestContext) {
        context.userDefaults.removePersistentDomain(forName: context.suiteName)
        try? FileManager.default.removeItem(at: context.containerURL)
    }

    private func isoDate(_ string: String) -> Date? {
        ISO8601DateFormatter().date(from: string)
    }

    private func makeImageData(color: UIColor) -> Data {
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 80, height: 120))
        let image = renderer.image { context in
            color.setFill()
            context.fill(CGRect(origin: .zero, size: CGSize(width: 80, height: 120)))
        }

        return image.jpegData(compressionQuality: 1) ?? Data()
    }
}

private struct DataSourceTestContext {
    let dataSource: BabyProgressDataSource
    let suiteName: String
    let userDefaults: UserDefaults
    let containerURL: URL
}
