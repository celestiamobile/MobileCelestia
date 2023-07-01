//
// AppCore.swift
//
// Copyright © 2023 Celestia Development Team. All rights reserved.
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.
//

import CelestiaCore
import Foundation

extension AppCore: @unchecked Sendable {}

public extension AppCore {
    func receive(_ action: CelestiaAction) {
        if textEnterMode != .normal {
            textEnterMode = .normal
        }
        charEnter(action.rawValue)
    }
}

public extension DSOCatalog {
    subscript(index: Int) -> DSO {
        get {
            return object(at: index)
        }
    }
}

public struct DSOCatalogIterator: IteratorProtocol {
    private let catalog: DSOCatalog
    private var index = 0

    public typealias Element = DSO

    public init(catalog: DSOCatalog) {
        self.catalog = catalog
    }

    mutating public func next() -> DSO? {
        defer { index += 1 }
        if index >= catalog.count {
            return nil
        }
        return catalog[index]
    }
}

extension DSOCatalog: Sequence {
    public typealias Iterator = DSOCatalogIterator

    public __consuming func makeIterator() -> DSOCatalogIterator {
        return DSOCatalogIterator(catalog: self)
    }
}

// MARK: Localization
public func CelestiaString(_ key: String, comment: String, domain: String = "celestia_ui") -> String {
    if key.isEmpty { return key }
    return LocalizedString(key, domain)
}

public func CelestiaFilename(_ key: String) -> String {
    return LocalizedFilename(key)
}

// MARK: Bookmark
public final class BookmarkNode: NSObject {
    public let isFolder: Bool

    @objc public var name: String
    @objc public var url: String
    @objc public var children: [BookmarkNode]

    public init(name: String, url: String, isFolder: Bool, children: [BookmarkNode] = []) {
        self.name = name
        self.url = url
        self.isFolder = isFolder
        self.children = children
        super.init()
    }

    @objc public var isLeaf: Bool {
        return !isFolder
    }
}

extension BookmarkNode: Codable {
    enum CodingKeys: String, CodingKey {
        case name
        case url
        case isFolder
        case children
    }
}

public extension AppCore {
    var currentBookmark: BookmarkNode? {
        let selection = simulation.selection
        if selection.isEmpty {
            return nil
        }
        let name: String
        if let star = selection.star {
            name = simulation.universe.starCatalog.starName(star)
        } else if let body = selection.body {
            name = body.name
        } else if let dso = selection.dso {
            name = simulation.universe.dsoCatalog.dsoName(dso)
        } else if let location = selection.location {
            name = location.name
        } else {
            name = CelestiaString("Unknown", comment: "")
        }
        return BookmarkNode(name: name, url: currentURL, isFolder: false)
    }
}

public func readBookmarks() -> [BookmarkNode] {
    guard let path = NSSearchPathForDirectoriesInDomains(.applicationSupportDirectory, .userDomainMask, true).first else {
        return []
    }
    let bookmarkFilePath = "\(path)/bookmark.json"
    do {
        let data = try Data(contentsOf: URL(fileURLWithPath: bookmarkFilePath))
        return try JSONDecoder().decode([BookmarkNode].self, from: data)
    } catch let error {
        print("Bookmark reading error: \(error.localizedDescription)")
        return []
    }
}

public func storeBookmarks(_ bookmarks: [BookmarkNode]) {
    guard let path = NSSearchPathForDirectoriesInDomains(.applicationSupportDirectory, .userDomainMask, true).first else {
        return
    }
    let bookmarkFilePath = "\(path)/bookmark.json"
    do {
        try JSONEncoder().encode(bookmarks).write(to: URL(fileURLWithPath: bookmarkFilePath))
    } catch let error {
        print("Bookmark writing error: \(error.localizedDescription)")
    }
}

public extension String {
    var toLocalizationTemplate: String {
        // FIXME: this does not fix multiple %s with different indices
        return replacingOccurrences(of: "%s", with: "%@")
    }
}

// MARK: Overview
public extension AppCore {
    func overviewForSelection(_ selection: Selection) -> String {
        if let body = selection.body {
            return overviewForBody(body)
        } else if let star = selection.star {
            return overviewForStar(star)
        } else if let dso = selection.dso {
            return overviewForDSO(dso)
        } else {
            return CelestiaString("No overview available.", comment: "")
        }
    }

    private func overviewForBody(_ body: Body) -> String {
        var lines = [String]()

        let radius = body.radius
        let radiusString: String
        let oneMiInKm: Float = 1.609344
        let oneFtInKm: Float = 0.0003048
        if (measurementSystem == .imperial) {
            if (radius >= oneMiInKm) {
                radiusString = String.localizedStringWithFormat(CelestiaString("%d mi", comment: ""), Int(radius / oneMiInKm))
            } else {
                radiusString = String.localizedStringWithFormat(CelestiaString("%d ft", comment: ""), Int(radius / oneFtInKm))
            }
        } else {
            if (radius >= 1) {
                radiusString = String.localizedStringWithFormat(CelestiaString("%d km", comment: ""), Int(radius))
            } else {
                radiusString = String.localizedStringWithFormat(CelestiaString("%d m", comment: ""), Int(radius * 1000))
            }
        }

        if body.isEllipsoid {
            lines.append(String.localizedStringWithFormat(CelestiaString("Equatorial radius: %s", comment: "").toLocalizationTemplate, radiusString))
        } else {
            lines.append(String.localizedStringWithFormat(CelestiaString("Size: %s", comment: "").toLocalizationTemplate, radiusString))
        }

        let orbit = body.orbit(at: simulation.time)
        let rotation = body.rotation(at: simulation.time)

        let orbitalPeriod: TimeInterval = orbit.isPeriodic ? orbit.period : 0

        if rotation.isPeriodic && body.type != .spacecraft {

            var rotPeriod = rotation.period

            var dayLength: TimeInterval = 0.0

            if orbit.isPeriodic {
                let siderealDaysPerYear = orbitalPeriod / rotPeriod
                let solarDaysPerYear = siderealDaysPerYear - 1.0
                if solarDaysPerYear > 0.0001 {
                    dayLength = orbitalPeriod / (siderealDaysPerYear - 1.0)
                }
            }

            let unitTemplate: String

            if rotPeriod < 2.0 {
                rotPeriod *= 24.0
                dayLength *= 24.0

                unitTemplate = CelestiaString("%.2f hours", comment: "")
            } else {
                unitTemplate = CelestiaString("%.2f days", comment: "")
            }
            lines.append(String.localizedStringWithFormat(CelestiaString("Sidereal rotation period: %s", comment: "").toLocalizationTemplate, String.localizedStringWithFormat(CelestiaString(unitTemplate, comment: ""), rotPeriod)))
            if dayLength != 0 {
                lines.append(String.localizedStringWithFormat(CelestiaString("Length of day: %s", comment: "").toLocalizationTemplate, String.localizedStringWithFormat(CelestiaString(unitTemplate, comment: ""), dayLength)))
            }
        }

        if body.hasRings {
            lines.append(CelestiaString("Has rings", comment: ""))
        }
        if body.hasAtmosphere {
            lines.append(CelestiaString("Has atmosphere", comment: ""))
        }

        let timeline = body.timeline
        if timeline.phaseCount > 0 {
            let startTime = timeline.phase(at: 0).startTime
            let endTime = timeline.phase(at: timeline.phaseCount - 1).endTime

            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = .short
            dateFormatter.timeStyle = .short

            if let startTime {
                lines.append(String.localizedStringWithFormat(CelestiaString("Start time: %s", comment: "").toLocalizationTemplate, dateFormatter.string(from: startTime)))
            }
            if let endTime {
                lines.append(String.localizedStringWithFormat(CelestiaString("End time: %s", comment: "").toLocalizationTemplate, dateFormatter.string(from: endTime)))
            }
        }

        return lines.joined(separator: "\n")
    }

    private func overviewForStar(_ star: Star) -> String {
        var lines = [String]()

        lines.append(String.localizedStringWithFormat(CelestiaString("Spectral type: %s", comment: "").toLocalizationTemplate, star.spectralType))

        let time = simulation.time

        let celPos = star.position(at: time).offet(from: .zero)
        let eqPos = AstroUtils.ecliptic(toEquatorial: AstroUtils.cel(toJ2000Ecliptic: celPos))
        let sph = AstroUtils.rect(toSpherical: eqPos)

        let hms = DMS(decimal: sph.dx)
        lines.append(String.localizedStringWithFormat(CelestiaString("RA: %dh %dm %.2fs", comment: ""), hms.hours, abs(hms.minutes), abs(hms.seconds)))

        let dms = DMS(decimal: sph.dy)
        lines.append(String.localizedStringWithFormat(CelestiaString("DEC: %d° %d′ %.2f″", comment: ""), dms.degrees, abs(dms.minutes), abs(dms.seconds)))

        return lines.joined(separator: "\n")
    }

    private func overviewForDSO(_ dso: DSO) -> String {
        var lines = [String]()

        let description = dso.dsoDescription
        if !description.isEmpty {
            lines.append(dso.dsoDescription)
        }

        let celPos = dso.position
        let eqPos = AstroUtils.ecliptic(toEquatorial: AstroUtils.cel(toJ2000Ecliptic: celPos))
        var sph = AstroUtils.rect(toSpherical: eqPos)

        let hms = DMS(decimal: sph.dx)
        lines.append(String.localizedStringWithFormat(CelestiaString("RA: %dh %dm %.2fs", comment: ""), hms.hours, abs(hms.minutes), abs(hms.seconds)))

        var dms = DMS(decimal: sph.dy)
        lines.append(String.localizedStringWithFormat(CelestiaString("Dec: %d° %d′ %.2f″", comment: ""), dms.degrees, abs(dms.minutes), abs(dms.seconds)))

        let galPos = AstroUtils.equatorial(toGalactic: eqPos)
        sph = AstroUtils.rect(toSpherical: galPos)

        dms = DMS(decimal: sph.dx)
        lines.append(String.localizedStringWithFormat(CelestiaString("L: %d° %d′ %.2f″", comment: ""), dms.degrees, abs(dms.minutes), abs(dms.seconds)))

        dms = DMS(decimal: sph.dy)
        lines.append(String.localizedStringWithFormat(CelestiaString("B: %d° %d′ %.2f″", comment: ""), dms.degrees, abs(dms.minutes), abs(dms.seconds)))

        return lines.joined(separator: "\n")
    }
}

