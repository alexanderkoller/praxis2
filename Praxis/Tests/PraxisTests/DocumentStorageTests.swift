import XCTest
import CryptoKit
@testable import Praxis

final class DocumentStorageTests: XCTestCase {

    private var tempDir: URL!
    private var storage: DocumentStorage!
    private let fixedKey = SymmetricKey(size: .bits256)

    override func setUpWithError() throws {
        tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        let key = fixedKey
        storage = DocumentStorage(documentsDir: tempDir, keyProvider: { key })
    }

    override func tearDownWithError() throws {
        try FileManager.default.removeItem(at: tempDir)
    }

    // MARK: - File existence

    func testStoreCreatesEncFileOnDisk() throws {
        let id = UUID()
        try storage.store(data: Data("test".utf8), for: id)
        let encPath = tempDir.appendingPathComponent("\(id.uuidString).enc")
        XCTAssertTrue(FileManager.default.fileExists(atPath: encPath.path))
    }

    func testStoreDoesNotCreatePlaintextFile() throws {
        let id = UUID()
        let plaintext = Data("Therapiebericht".utf8)
        try storage.store(data: plaintext, for: id)
        // Only the .enc file should exist — not any .pdf or raw file
        let contents = try FileManager.default.contentsOfDirectory(atPath: tempDir.path)
        XCTAssertEqual(contents, ["\(id.uuidString).enc"])
    }

    // MARK: - File contents are encrypted

    func testOnDiskDataIsNotPlaintext() throws {
        let id = UUID()
        let plaintext = Data("Geheimnis".utf8)
        try storage.store(data: plaintext, for: id)
        let onDisk = try Data(contentsOf: tempDir.appendingPathComponent("\(id.uuidString).enc"))
        XCTAssertNotEqual(onDisk, plaintext)
    }

    func testOnDiskDataIsLongerThanPlaintext() throws {
        let id = UUID()
        let plaintext = Data("Kurz".utf8)
        try storage.store(data: plaintext, for: id)
        let onDisk = try Data(contentsOf: tempDir.appendingPathComponent("\(id.uuidString).enc"))
        // AES-GCM adds 12-byte nonce + 16-byte tag
        XCTAssertEqual(onDisk.count, plaintext.count + 28)
    }

    // MARK: - Round-trip through filesystem

    func testStoreAndRetrieveRoundTrip() throws {
        let id = UUID()
        let original = Data("Arztbrief".utf8)
        try storage.store(data: original, for: id)
        let retrieved = try storage.retrieve(for: id)
        XCTAssertEqual(retrieved, original)
    }

    func testTwoDocumentsStoredIndependently() throws {
        let id1 = UUID()
        let id2 = UUID()
        let data1 = Data("Dokument 1".utf8)
        let data2 = Data("Dokument 2".utf8)
        try storage.store(data: data1, for: id1)
        try storage.store(data: data2, for: id2)
        XCTAssertEqual(try storage.retrieve(for: id1), data1)
        XCTAssertEqual(try storage.retrieve(for: id2), data2)
    }

    func testEachEncryptionProducesDifferentCiphertext() throws {
        let id1 = UUID()
        let id2 = UUID()
        let same = Data("identical content".utf8)
        try storage.store(data: same, for: id1)
        try storage.store(data: same, for: id2)
        let onDisk1 = try Data(contentsOf: tempDir.appendingPathComponent("\(id1.uuidString).enc"))
        let onDisk2 = try Data(contentsOf: tempDir.appendingPathComponent("\(id2.uuidString).enc"))
        // AES-GCM uses a random nonce, so identical plaintexts produce different ciphertexts
        XCTAssertNotEqual(onDisk1, onDisk2)
    }

    // MARK: - Error cases

    func testRetrieveNonExistentThrows() {
        XCTAssertThrowsError(try storage.retrieve(for: UUID()))
    }

    func testRetrieveWithWrongKeyThrows() throws {
        let id = UUID()
        try storage.store(data: Data("secret".utf8), for: id)
        let wrongKey = SymmetricKey(size: .bits256)
        let wrongStorage = DocumentStorage(documentsDir: tempDir, keyProvider: { wrongKey })
        XCTAssertThrowsError(try wrongStorage.retrieve(for: id))
    }

    func testRetrieveTamperedFileThrows() throws {
        let id = UUID()
        try storage.store(data: Data("tamper test".utf8), for: id)
        let encPath = tempDir.appendingPathComponent("\(id.uuidString).enc")
        var onDisk = try Data(contentsOf: encPath)
        onDisk[onDisk.count / 2] ^= 0xFF
        try onDisk.write(to: encPath)
        XCTAssertThrowsError(try storage.retrieve(for: id))
    }
}
