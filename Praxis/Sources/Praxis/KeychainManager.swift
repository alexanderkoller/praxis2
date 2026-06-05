import Foundation
import Security

enum KeychainManager {
    private static let service = "de.praxis.app"
    private static let account = "db-key"

    static func databaseKey() throws -> String {
        if let existing = try read() { return existing }
        let key = try generate()
        try store(key)
        return key
    }

    private static func read() throws -> String? {
        let query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: account,
            kSecReturnData: true,
            kSecMatchLimit: kSecMatchLimitOne,
        ]
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        switch status {
        case errSecSuccess:
            guard let data = result as? Data, let key = String(data: data, encoding: .utf8) else {
                throw KeychainError.invalidData
            }
            return key
        case errSecItemNotFound:
            return nil
        default:
            throw KeychainError.osStatus(status)
        }
    }

    private static func generate() throws -> String {
        var bytes = [UInt8](repeating: 0, count: 32)
        let status = SecRandomCopyBytes(kSecRandomDefault, bytes.count, &bytes)
        guard status == errSecSuccess else { throw KeychainError.osStatus(status) }
        return bytes.map { String(format: "%02x", $0) }.joined()
    }

    private static func store(_ key: String) throws {
        guard let data = key.data(using: .utf8) else { throw KeychainError.invalidData }
        let attributes: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: account,
            kSecAttrAccessible: kSecAttrAccessibleWhenUnlockedThisDeviceOnly,
            kSecValueData: data,
        ]
        let status = SecItemAdd(attributes as CFDictionary, nil)
        guard status == errSecSuccess else { throw KeychainError.osStatus(status) }
    }
}

enum KeychainError: Error {
    case invalidData
    case osStatus(OSStatus)
}
