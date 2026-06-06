import CryptoKit
import Foundation

final class DocumentStorage: @unchecked Sendable {
    static let shared = DocumentStorage()

    private let documentsDir: URL
    private let keyProvider: () throws -> SymmetricKey

    init(documentsDir: URL? = nil, keyProvider: (() throws -> SymmetricKey)? = nil) {
        let appSupport = FileManager.default.urls(
            for: .applicationSupportDirectory, in: .userDomainMask
        ).first!
        self.documentsDir = documentsDir
            ?? appSupport.appendingPathComponent("Praxis/documents")
        self.keyProvider = keyProvider ?? {
            let hex = try KeychainManager.databaseKey()
            return try DocumentEncryption.fileKey(from: hex)
        }
        try? FileManager.default.createDirectory(
            at: self.documentsDir, withIntermediateDirectories: true
        )
    }

    func store(data: Data, for documentID: UUID) throws {
        let key = try keyProvider()
        let encrypted = try DocumentEncryption.encrypt(data, using: key)
        try encrypted.write(to: encryptedURL(for: documentID), options: .atomic)
    }

    func retrieve(for documentID: UUID) throws -> Data {
        let encrypted = try Data(contentsOf: encryptedURL(for: documentID))
        let key = try keyProvider()
        return try DocumentEncryption.decrypt(encrypted, using: key)
    }

    private func encryptedURL(for id: UUID) -> URL {
        documentsDir.appendingPathComponent("\(id.uuidString).enc")
    }
}
