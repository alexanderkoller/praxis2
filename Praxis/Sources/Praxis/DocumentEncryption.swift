import CryptoKit
import Foundation

enum DocumentEncryption {
    enum EncryptionError: Error {
        case invalidKeyHex
        case encryptionFailed
    }

    static func fileKey(from keychainHex: String) throws -> SymmetricKey {
        guard let keyBytes = Data(hexString: keychainHex), keyBytes.count == 32 else {
            throw EncryptionError.invalidKeyHex
        }
        let master = SymmetricKey(data: keyBytes)
        return HKDF<SHA256>.deriveKey(
            inputKeyMaterial: master,
            info: Data("praxis-file-encryption".utf8),
            outputByteCount: 32
        )
    }

    static func encrypt(_ data: Data, using key: SymmetricKey) throws -> Data {
        let sealed = try AES.GCM.seal(data, using: key)
        guard let combined = sealed.combined else { throw EncryptionError.encryptionFailed }
        return combined
    }

    static func decrypt(_ data: Data, using key: SymmetricKey) throws -> Data {
        let sealed = try AES.GCM.SealedBox(combined: data)
        return try AES.GCM.open(sealed, using: key)
    }
}

private extension Data {
    init?(hexString: String) {
        let n = hexString.count
        guard n % 2 == 0 else { return nil }
        var data = Data(capacity: n / 2)
        var index = hexString.startIndex
        for _ in 0..<(n / 2) {
            let next = hexString.index(index, offsetBy: 2)
            guard let byte = UInt8(hexString[index..<next], radix: 16) else { return nil }
            data.append(byte)
            index = next
        }
        self = data
    }
}
