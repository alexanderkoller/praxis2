import XCTest
import CryptoKit
@testable import Praxis

final class DocumentEncryptionTests: XCTestCase {

    private var testKey: SymmetricKey {
        SymmetricKey(size: .bits256)
    }

    func testEncryptDecryptRoundTrip() throws {
        let original = Data("Arztbrief vom 12. Mai 2025".utf8)
        let key = testKey
        let encrypted = try DocumentEncryption.encrypt(original, using: key)
        let decrypted = try DocumentEncryption.decrypt(encrypted, using: key)
        XCTAssertEqual(decrypted, original)
    }

    func testEncryptedDataLongerThanPlaintext() throws {
        let original = Data(repeating: 0xAB, count: 100)
        let encrypted = try DocumentEncryption.encrypt(original, using: testKey)
        // 12-byte nonce + plaintext + 16-byte authentication tag
        XCTAssertEqual(encrypted.count, original.count + 28)
    }

    func testDecryptWithWrongKeyThrows() throws {
        let original = Data("sensitive".utf8)
        let keyA = testKey
        let keyB = testKey  // different key, generated fresh
        let encrypted = try DocumentEncryption.encrypt(original, using: keyA)
        XCTAssertThrowsError(try DocumentEncryption.decrypt(encrypted, using: keyB))
    }

    func testDecryptTamperedCiphertextThrows() throws {
        let original = Data("test".utf8)
        let key = testKey
        var encrypted = try DocumentEncryption.encrypt(original, using: key)
        // Flip a bit in the middle of the ciphertext
        encrypted[encrypted.count / 2] ^= 0xFF
        XCTAssertThrowsError(try DocumentEncryption.decrypt(encrypted, using: key))
    }

    func testFileKeyFromValidHex() throws {
        let hex = String(repeating: "a3", count: 32)  // 64 chars = 32 bytes
        let key = try DocumentEncryption.fileKey(from: hex)
        XCTAssertEqual(key.bitCount, 256)
    }

    func testFileKeyFromInvalidHexThrows() {
        XCTAssertThrowsError(try DocumentEncryption.fileKey(from: "notvalidhex"))
    }

    func testFileKeyFromShortHexThrows() {
        // Only 16 bytes, not 32
        XCTAssertThrowsError(try DocumentEncryption.fileKey(from: String(repeating: "ab", count: 16)))
    }

    func testFileKeyIsDeterministic() throws {
        let hex = String(repeating: "5f", count: 32)
        let key1 = try DocumentEncryption.fileKey(from: hex)
        let key2 = try DocumentEncryption.fileKey(from: hex)
        let data = Data("deterministic".utf8)
        let encrypted = try DocumentEncryption.encrypt(data, using: key1)
        let decrypted = try DocumentEncryption.decrypt(encrypted, using: key2)
        XCTAssertEqual(decrypted, data)
    }
}
