import Foundation
import Security

protocol SessionStore {
    func save(_ session: AuthSession) throws
    func load() throws -> AuthSession?
    func clear() throws
}

final class KeychainSessionStore: SessionStore {
    private let service = "com.eunchan.GONE.session"
    private let account = "auth-session"

    func save(_ session: AuthSession) throws {
        let data = try JSONEncoder().encode(
            StoredSession(accessToken: session.accessToken, refreshToken: session.refreshToken)
        )
        try clear()
        let status = SecItemAdd([
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: account,
            kSecValueData: data
        ] as CFDictionary, nil)
        guard status == errSecSuccess else { throw KeychainError(status: status) }
    }

    func load() throws -> AuthSession? {
        var result: AnyObject?
        let status = SecItemCopyMatching([
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: account,
            kSecReturnData: true,
            kSecMatchLimit: kSecMatchLimitOne
        ] as CFDictionary, &result)

        if status == errSecItemNotFound { return nil }
        guard status == errSecSuccess, let data = result as? Data else {
            throw KeychainError(status: status)
        }

        let stored = try JSONDecoder().decode(StoredSession.self, from: data)
        return AuthSession(accessToken: stored.accessToken, refreshToken: stored.refreshToken)
    }

    func clear() throws {
        let status = SecItemDelete([
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: account
        ] as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError(status: status)
        }
    }
}

private struct StoredSession: Codable {
    let accessToken: String
    let refreshToken: String?
}

private struct KeychainError: LocalizedError {
    let status: OSStatus
    var errorDescription: String? { "Keychain error: \(status)" }
}
