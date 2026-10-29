import Foundation

enum SigningError: Error {
    case usage(String)
    case invalidProject(String)
}

guard CommandLine.arguments.count == 4 || CommandLine.arguments.count == 5 else {
    throw SigningError.usage("configure_signing.swift <project.xcproj> <identity> <profile> [extension-profile]")
}

let projectURL = URL(fileURLWithPath: CommandLine.arguments[1])
let identity = CommandLine.arguments[2]
let profile = CommandLine.arguments[3]
let extensionProfile = CommandLine.arguments.count == 5 ? CommandLine.arguments[4] : nil
let data = try Data(contentsOf: projectURL)
guard var project = try JSONSerialization.jsonObject(with: data, options: [.json5Allowed]) as? [String: Any],
      var targets = project["targets"] as? [[String: Any]] else {
    throw SigningError.invalidProject("Missing targets")
}

func configure(_ settings: inout [String: Any], profile: String) {
    if settings["CODE_SIGN_STYLE"] as? String == "Automatic" {
        settings["CODE_SIGN_STYLE"] = "Manual"
    }
    if settings["CODE_SIGN_IDENTITY"] as? String == "Apple Development" {
        settings["CODE_SIGN_IDENTITY"] = identity
    }
    if settings["PROVISIONING_PROFILE_SPECIFIER"] as? String == "" {
        settings["PROVISIONING_PROFILE_SPECIFIER"] = profile
    }
}

for index in targets.indices {
    guard let name = targets[index]["name"] as? String,
          var settings = targets[index]["build-settings"] as? [String: Any] else {
        throw SigningError.invalidProject("Missing target name or build settings")
    }
    var targetProfile = profile
    if name == "NotificationServiceExtension", let extensionProfile {
        targetProfile = extensionProfile
    }
    configure(&settings, profile: targetProfile)
    targets[index]["build-settings"] = settings
    if var configurations = targets[index]["specialized-configurations"] as? [[String: Any]] {
        for configurationIndex in configurations.indices {
            if var settings = configurations[configurationIndex]["build-settings"] as? [String: Any] {
                configure(&settings, profile: targetProfile)
                configurations[configurationIndex]["build-settings"] = settings
            }
        }
        targets[index]["specialized-configurations"] = configurations
    }
}

project["targets"] = targets
let output = try JSONSerialization.data(withJSONObject: project, options: [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes])
try output.write(to: projectURL, options: .atomic)
