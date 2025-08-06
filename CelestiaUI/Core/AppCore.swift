// AppCore.swift
//
// Copyright (C) 2025, Celestia Development Team
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.

import CelestiaCore
import CelestiaFoundation
import Foundation

extension AppCore: @unchecked @retroactive Sendable {}

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

extension DSOCatalog: @retroactive Sequence {
    public typealias Iterator = DSOCatalogIterator

    public __consuming func makeIterator() -> DSOCatalogIterator {
        return DSOCatalogIterator(catalog: self)
    }
}

// MARK: Localization
public func CelestiaString(_ key: StaticString, context: StaticString? = nil, comment: String) -> String {
    let string = key.withUTF8Buffer {
        String(decoding: $0, as: UTF8.self)
    }
    if let context {
        let contextString = context.withUTF8Buffer {
            String(decoding: $0, as: UTF8.self)
        }
        return LocalizedStringContext(string, contextString, "celestia_ui")
    }
    return LocalizedString(string, "celestia_ui")
}

public func CelestiaFilename(_ key: String) -> String {
    return LocalizedFilename(key)
}

// MARK: Bookmark
public final class BookmarkNode: NSObject, @unchecked Sendable {
    public let isFolder: Bool

    public var name: String
    public var url: String
    public var children: [BookmarkNode]

    public init(name: String, url: String, isFolder: Bool, children: [BookmarkNode] = []) {
        self.name = name
        self.url = url
        self.isFolder = isFolder
        self.children = children
        super.init()
    }

    public var isLeaf: Bool {
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

@MainActor
public func readBookmarks() -> [BookmarkNode] {
    guard let supportDirectory = URL.applicationSupport() else {
        return []
    }
    do {
        let data = try Data(contentsOf: supportDirectory.appendingPathComponent("bookmark.json"))
        return try JSONDecoder().decode([BookmarkNode].self, from: data)
    } catch let error {
        print("Bookmark reading error: \(error.localizedDescription)")
        return []
    }
}

@MainActor
public func storeBookmarks(_ bookmarks: [BookmarkNode]) {
    guard let supportDirectory = URL.applicationSupport() else {
        return
    }
    do {
        try JSONEncoder().encode(bookmarks).write(to: supportDirectory.appendingPathComponent("bookmark.json"))
    } catch let error {
        print("Bookmark writing error: \(error.localizedDescription)")
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
            return CelestiaString("No overview available.", comment: "No overview for an object")
        }
    }

    private func overviewForBody(_ body: Body) -> String {
        var lines = [String]()

        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 2
        formatter.usesGroupingSeparator = true

        let radius = body.radius
        let radiusString: String
        let oneMiInKm: Float = 1.609344
        let oneFtInKm: Float = 0.0003048
        if (measurementSystem == .imperial) {
            if (radius >= oneMiInKm) {
                radiusString = String.localizedStringWithFormat(CelestiaString("%@ mi", comment: "Unit mile"), formatter.string(from: Int(radius / oneMiInKm)))
            } else {
                radiusString = String.localizedStringWithFormat(CelestiaString("%@ ft", comment: "Unit foot"), formatter.string(from: Int(radius / oneFtInKm)))
            }
        } else {
            if (radius >= 1) {
                radiusString = String.localizedStringWithFormat(CelestiaString("%@ km", comment: "Unit kilometer"), formatter.string(from: Int(radius)))
            } else {
                radiusString = String.localizedStringWithFormat(CelestiaString("%@ m", comment: "Unit meter"), formatter.string(from: Int(radius * 1000)))
            }
        }

        if body.isEllipsoid {
            lines.append(String.localizedStringWithFormat(CelestiaString("Equatorial radius: %@", comment: ""), radiusString))
        } else {
            lines.append(String.localizedStringWithFormat(CelestiaString("Size: %@", comment: "Size of an object"), radiusString))
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

                unitTemplate = CelestiaString("%@ hours", comment: "")
            } else {
                unitTemplate = CelestiaString("%@ days", comment: "")
            }
            lines.append(String.localizedStringWithFormat(CelestiaString("Sidereal rotation period: %@", comment: ""), String.localizedStringWithFormat(unitTemplate, formatter.string(from: rotPeriod))))
            if dayLength != 0 {
                lines.append(String.localizedStringWithFormat(CelestiaString("Length of day: %@", comment: ""), String.localizedStringWithFormat(unitTemplate, formatter.string(from: dayLength))))
            }
        }

        if body.hasRings {
            lines.append(CelestiaString("Has rings", comment: "Indicate that an object has rings"))
        }
        if body.hasAtmosphere {
            lines.append(CelestiaString("Has atmosphere", comment: "Indicate that an object has atmosphere"))
        }

        let timeline = body.timeline
        if timeline.phaseCount > 0 {
            let startTime = timeline.phase(at: 0).startTime
            let endTime = timeline.phase(at: timeline.phaseCount - 1).endTime

            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = .short
            dateFormatter.timeStyle = .short

            if let startTime {
                lines.append(String.localizedStringWithFormat(CelestiaString("Start time: %@", comment: "Template for the start time of a body, usually a spacecraft"), dateFormatter.string(from: startTime)))
            }
            if let endTime {
                lines.append(String.localizedStringWithFormat(CelestiaString("End time: %@", comment: "Template for the end time of a body, usually a spacecraft"), dateFormatter.string(from: endTime)))
            }
        }

        return lines.joined(separator: "\n")
    }

    private func overviewForStar(_ star: Star) -> String {
        var lines = [String]()

        lines.append(String.localizedStringWithFormat(CelestiaString("Spectral type: %@", comment: ""), star.spectralType))

        let time = simulation.time

        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 2
        formatter.usesGroupingSeparator = true

        let celPos = star.position(at: time).offet(from: .zero)
        let eqPos = AstroUtils.ecliptic(toEquatorial: AstroUtils.cel(toJ2000Ecliptic: celPos))
        let sph = AstroUtils.rect(toSpherical: eqPos)

        let hms = DMS(decimal: AstroUtils.deg(fromRad: sph.dx))
        lines.append(String.localizedStringWithFormat(CelestiaString("RA: %@h %@m %@s", comment: "Equatorial coordinate"), formatter.string(from: hms.hmsHours), formatter.string(from: hms.hmsMinutes), formatter.string(from: hms.hmsSeconds)))

        let dms = DMS(decimal: AstroUtils.deg(fromRad: sph.dy))
        lines.append(String.localizedStringWithFormat(CelestiaString("DEC: %@° %@′ %@″", comment: "Equatorial coordinate"), formatter.string(from: dms.degrees), formatter.string(from: dms.minutes), formatter.string(from: dms.seconds)))

        return lines.joined(separator: "\n")
    }

    private func overviewForDSO(_ dso: DSO) -> String {
        var lines = [String]()

        let description = dso.dsoDescription
        if !description.isEmpty {
            lines.append(dso.dsoDescription)
        }

        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 2
        formatter.usesGroupingSeparator = true

        let celPos = dso.position
        let eqPos = AstroUtils.ecliptic(toEquatorial: AstroUtils.cel(toJ2000Ecliptic: celPos))
        var sph = AstroUtils.rect(toSpherical: eqPos)

        let hms = DMS(decimal: AstroUtils.deg(fromRad: sph.dx))
        lines.append(String.localizedStringWithFormat(CelestiaString("RA: %@h %@m %@s", comment: "Equatorial coordinate"), formatter.string(from: hms.hmsHours), formatter.string(from: hms.hmsMinutes), formatter.string(from: hms.hmsSeconds)))

        var dms = DMS(decimal: AstroUtils.deg(fromRad: sph.dy))
        lines.append(String.localizedStringWithFormat(CelestiaString("DEC: %@° %@′ %@″", comment: "Equatorial coordinate"), formatter.string(from: dms.degrees), formatter.string(from: dms.minutes), formatter.string(from: dms.seconds)))

        let galPos = AstroUtils.equatorial(toGalactic: eqPos)
        sph = AstroUtils.rect(toSpherical: galPos)

        dms = DMS(decimal: AstroUtils.deg(fromRad: sph.dx))
        lines.append(String.localizedStringWithFormat(CelestiaString("L: %@° %@′ %@″", comment: "Galactic coordinates"), formatter.string(from: dms.degrees), formatter.string(from: dms.minutes), formatter.string(from: dms.seconds)))

        dms = DMS(decimal: AstroUtils.deg(fromRad: sph.dy))
        lines.append(String.localizedStringWithFormat(CelestiaString("B: %@° %@′ %@″", comment: "Galactic coordinates"), formatter.string(from: dms.degrees), formatter.string(from: dms.minutes), formatter.string(from: dms.seconds)))

        return lines.joined(separator: "\n")
    }
}

