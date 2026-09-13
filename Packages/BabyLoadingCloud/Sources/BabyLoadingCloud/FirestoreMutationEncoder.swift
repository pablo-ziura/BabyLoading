import CloudBackup
import FirebaseFirestore
import Foundation

enum FirestoreMutationEncoder {
    static func fields(for payload: BackupMutationPayload, previous: DocumentSnapshot) throws -> [String: Any]? {
        if previous.data()?["isDeleted"] as? Bool == true { return nil }
        if requiresExistingDocument(payload), !previous.exists { throw BackupFailure.invalidData }
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
            fields = ["weekNumber": week as Any? ?? NSNull(), "notes": notes as Any? ?? NSNull()]
        case let .weekNumber(_, value):
            fields = ["weekNumber": value as Any? ?? NSNull()]
        case let .notes(_, value):
            fields = ["notes": value as Any? ?? NSNull()]
        case .delete:
            fields = ["isDeleted": true]
        case let .image(_, url):
            fields = ["remoteImageUrl": url]
        case let .lastPeriodDay(day): fields = ["lastPeriodDay": day as Any? ?? NSNull()]
        case let .cadence(days): fields = ["cadenceDays": days]
        }
        fields["schemaVersion"] = 1
        fields["updatedAt"] = FieldValue.serverTimestamp()
        return fields
    }

    private static func requiresExistingDocument(_ payload: BackupMutationPayload) -> Bool {
        switch payload {
        case .create, .lastPeriodDay, .cadence: false
        default: true
        }
    }

}
