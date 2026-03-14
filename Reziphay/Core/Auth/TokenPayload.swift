import Foundation

struct TokenPayload {
    let sub: String
    let sessionId: String
    let roles: [AppRole]
    let activeRole: AppRole
    let exp: Date

    var isExpired: Bool { Date() >= exp }
    var expiresIn: TimeInterval { exp.timeIntervalSinceNow }

    static func decode(from jwt: String) -> TokenPayload? {
        let parts = jwt.split(separator: ".")
        guard parts.count == 3 else { return nil }

        var payload = String(parts[1])
        // Pad base64
        while payload.count % 4 != 0 { payload += "=" }

        guard let data = Data(base64Encoded: payload, options: .ignoreUnknownCharacters),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return nil
        }

        guard let sub = json["sub"] as? String,
              let sessionId = json["sessionId"] as? String,
              let exp = json["exp"] as? TimeInterval else {
            return nil
        }

        let rolesRaw = json["roles"] as? [String] ?? []
        let roles = rolesRaw.compactMap { AppRole(rawValue: $0) }
        let activeRole = (json["activeRole"] as? String).flatMap { AppRole(rawValue: $0) } ?? .ucr

        return TokenPayload(
            sub: sub,
            sessionId: sessionId,
            roles: roles,
            activeRole: activeRole,
            exp: Date(timeIntervalSince1970: exp)
        )
    }
}
