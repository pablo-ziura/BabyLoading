import CloudBackup
import FirebaseFirestore
import Foundation

enum FirestoreMutationEncoder {
    static func fields(for payload: BackupMutationPayload, previous: DocumentSnapshot) throws -> [String: Any]? {
        if previous.data()?["isDeleted"] as? Bool == true { return nil }
        var fields: [String: Any]
        switch payload {
        case let .create(log):
            if previous.exists {
                guard log.isDeleted else { return nil }
                fields = ["isDeleted": true]
            } else {
                fields = try Firestore.Encoder().encode(log)
            }
        case let .edit(_, week, notes):
            guard previous.exists else { throw BackupFailure.invalidData }
            fields = ["weekNumber": week as Any? ?? NSNull(), "notes": notes as Any? ?? NSNull()]
        case .delete:
            guard previous.exists else { throw BackupFailure.invalidData }
            fields = ["isDeleted": true]
        case let .image(_, url):
            guard previous.exists else { throw BackupFailure.invalidData }
            fields = ["remoteImageUrl": url]
        case let .lastPeriodDay(day): fields = ["lastPeriodDay": day as Any? ?? NSNull()]
        case let .cadence(days): fields = ["cadenceDays": days]
        }
        fields["schemaVersion"] = 1
        fields["updatedAt"] = FieldValue.serverTimestamp()
        return fields
    }
}
