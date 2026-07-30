import Foundation

func getAppGroupId() -> String? {
    // $(TeamIdentifierPrefix) is resolved by Xcode at build time
    if let id = Bundle.main.object(forInfoDictionaryKey: "AppGroupIdentifier") as? String,
       !id.contains("$(") {
        return id
    }
    // Fallback for debug builds without proper signing
    if let containerURL = FileManager.default.containerURL(
        forSecurityApplicationGroupIdentifier: "com.flywinter.opencode.usage-bar"
    ) {
        return "com.flywinter.opencode.usage-bar"
    }
    return nil
}
