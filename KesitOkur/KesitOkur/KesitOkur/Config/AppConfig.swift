import Foundation

enum AppConfig {
    static func value(for key: String) -> String? {
        // First try to get from environment
        if let envPath = Bundle.main.path(forResource: ".env", ofType: nil),
           let envContent = try? String(contentsOfFile: envPath, encoding: .utf8) {
            let lines = envContent.components(separatedBy: .newlines)
            for line in lines {
                let parts = line.components(separatedBy: "=")
                if parts.count == 2 && parts[0].trimmingCharacters(in: .whitespaces) == key {
                    return parts[1].trimmingCharacters(in: .whitespaces)
                }
            }
        }
        
        // Fallback to Info.plist
        return Bundle.main.infoDictionary?[key] as? String
    }
    
    // Firebase Configuration
    static var firebaseApiKey: String? { value(for: "FIREBASE_API_KEY") }
    static var firebaseAuthDomain: String? { value(for: "FIREBASE_AUTH_DOMAIN") }
    static var firebaseProjectId: String? { value(for: "FIREBASE_PROJECT_ID") }
    static var firebaseStorageBucket: String? { value(for: "FIREBASE_STORAGE_BUCKET") }
    static var firebaseMessagingSenderId: String? { value(for: "FIREBASE_MESSAGING_SENDER_ID") }
    static var firebaseAppId: String? { value(for: "FIREBASE_APP_ID") }
    static var firebaseMeasurementId: String? { value(for: "FIREBASE_MEASUREMENT_ID") }
}
