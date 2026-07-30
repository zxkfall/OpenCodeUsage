import Foundation

func getAppGroupId() -> String? {
    if let id = Bundle.main.object(forInfoDictionaryKey: "AppGroupIdentifier") as? String,
       !id.contains("$(") {
        return id
    }
    if FileManager.default.containerURL(
        forSecurityApplicationGroupIdentifier: "com.flywinter.opencode-usage-bar"
    ) != nil {
        return "com.flywinter.opencode-usage-bar"
    }
    return nil
}
