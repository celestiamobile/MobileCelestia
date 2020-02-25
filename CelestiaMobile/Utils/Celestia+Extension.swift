//
//  Celestia+Extension.swift
//  CelestiaMobile
//
//  Created by Li Linfeng on 2020/2/24.
//  Copyright © 2020 李林峰. All rights reserved.
//

import CelestiaCore

extension BodyInfo {
    init(selection: CelestiaSelection) {
        self.init(name: CelestiaAppCore.shared.simulation.universe.name(for: selection),
                  overview: overviewForSelection(selection))
    }
}

// MARK: singleton
private var core: CelestiaAppCore?

extension CelestiaAppCore {
    static var shared: CelestiaAppCore {
        if core == nil {
            core = CelestiaAppCore()
        }
        return core!
    }
}

extension CelestiaSelection {
    convenience init?(item: CelestiaBrowserItem) {
        let object = item.entry
        if let star = object as? CelestiaStar {
            self.init(star: star)
        } else if let dso = object as? CelestiaDSO {
            self.init(dso: dso)
        } else if let b = object as? CelestiaBody {
            self.init(body: b)
        } else if let l = object as? CelestiaLocation {
            self.init(location: l)
        } else {
            return nil
        }
    }
}

private var solBrowserRoot: CelestiaBrowserItem = {
    let universe = CelestiaAppCore.shared.simulation.universe
    let sol = universe.find("Sol")
    return CelestiaBrowserItem(name: universe.starCatalog.starName(sol.star!), catEntry: sol.star!, provider: universe)
}()

private var starsBrowserRoot: CelestiaBrowserItem = {
    let core = CelestiaAppCore.shared
    let universe = core.simulation.universe

    func updateAccumulation(result: inout [String : CelestiaBrowserItem], star: CelestiaStar) {
        let name = universe.starCatalog.starName(star)
        result[name] = CelestiaBrowserItem(name: name, catEntry: star, provider: universe)
    }

    let nearest = CelestiaStarBrowser(kind: .nearest, simulation: core.simulation).stars().reduce(into: [String : CelestiaBrowserItem](), updateAccumulation)
    let brightest = CelestiaStarBrowser(kind: .brightest, simulation: core.simulation).stars().reduce(into: [String : CelestiaBrowserItem](), updateAccumulation)
    let hasPlanets = CelestiaStarBrowser(kind: .starsWithPlants, simulation: core.simulation).stars().reduce(into: [String : CelestiaBrowserItem](), updateAccumulation)

    let nearestName = NSLocalizedString("Nearest Stars", comment: "")
    let brightestName = NSLocalizedString("Brightest Stars", comment: "")
    let hasPlanetsName = NSLocalizedString("Stars With Planets", comment: "")
    let stars = CelestiaBrowserItem(name: NSLocalizedString("Stars", comment: ""), children: [
        nearestName : CelestiaBrowserItem(name: nearestName, children: nearest),
        brightestName : CelestiaBrowserItem(name: brightestName, children: brightest),
        hasPlanetsName : CelestiaBrowserItem(name: hasPlanetsName, children: hasPlanets),
    ])
    return stars
}()

private var dsoBrowserRoot: CelestiaBrowserItem = {
    let core = CelestiaAppCore.shared
    let universe = core.simulation.universe

    let typeMap = [
        "SB" : NSLocalizedString("Galaxies (Barred Spiral)", comment: ""),
        "S" : NSLocalizedString("Galaxies (Spiral)", comment: ""),
        "E" : NSLocalizedString("Galaxies (Elliptical)", comment: ""),
        "Irr" : NSLocalizedString("Galaxies (Irregular)", comment: ""),
        "Neb" : NSLocalizedString("Nebulae", comment: ""),
        "Glob" : NSLocalizedString("Globulars", comment: ""),
        "Open cluster" : NSLocalizedString("Open Clusters", comment: ""),
        "Unknown" : NSLocalizedString("Unknown", comment: ""),
    ]

    func updateAccumulation(result: inout [String : CelestiaBrowserItem], item: (key: String, value: [String : CelestiaBrowserItem])) {
        let fullName = typeMap[item.key]!
        result[fullName] = CelestiaBrowserItem(name: fullName, children: item.value)
    }

    let prefixes = ["SB", "S", "E", "Irr", "Neb", "Glob", "Open cluster"]

    var tempDict = prefixes.reduce(into: [String : [String : CelestiaBrowserItem]]()) { $0[$1] = [String : CelestiaBrowserItem]() }

    let catalog = universe.dsoCatalog
    catalog.forEach({ (dso) in
        let matchingType = prefixes.first(where: {dso.type.hasPrefix($0)}) ?? "Unknown"
        let name = catalog.dsoName(dso)
        if tempDict[matchingType] != nil {
            tempDict[matchingType]![name] = CelestiaBrowserItem(name: name, catEntry: dso, provider: universe)
        }
    })

    let results = tempDict.reduce(into: [String : CelestiaBrowserItem](), updateAccumulation)
    return CelestiaBrowserItem(name: NSLocalizedString("Deep Sky Objects", comment: ""), children: results)
}()

var browserRoots: [CelestiaBrowserItem] {
    return [solBrowserRoot, starsBrowserRoot, dsoBrowserRoot]
}

var renderInfo: String {
    return CelestiaAppCore.shared.renderInfo
}

extension CelestiaDSOCatalog {
    subscript(index: Int) -> CelestiaDSO {
        get {
            return object(at: index)
        }
    }
}

public struct CelestiaDSOCatalogIterator: IteratorProtocol {
    private let catalog: CelestiaDSOCatalog
    private var index = 0

    public typealias Element = CelestiaDSO

    init(catalog: CelestiaDSOCatalog) {
        self.catalog = catalog
    }

    mutating public func next() -> CelestiaDSO? {
        defer { index += 1 }
        if index >= catalog.count {
            return nil
        }
        return catalog[index]
    }
}

extension CelestiaDSOCatalog: Sequence {
    public typealias Iterator = CelestiaDSOCatalogIterator

    public __consuming func makeIterator() -> CelestiaDSOCatalogIterator {
        return CelestiaDSOCatalogIterator(catalog: self)
    }
}

private func overviewForSelection(_ selection: CelestiaSelection) -> String {
    if let body = selection.body {
        return overviewForBody(body)
    } else if let star = selection.star {
        return overviewForStar(star)
    } else if let dso = selection.dso {
        return overviewForDSO(dso)
    } else {
        return NSLocalizedString("No overview available.", comment: "")
    }
}

private func overviewForBody(_ body: CelestiaBody) -> String {
    let core = CelestiaAppCore.shared
    var str = ""

    if body.isEllipsoid {
        str += String(format: NSLocalizedString("Equatorial radius: %@", comment: ""), body.radius.radiusString)
    } else {
        str += String(format: NSLocalizedString("Size: %@", comment: ""), body.radius.radiusString)
    }

    let orbit = body.orbit(at: core.simulation.time)
    let rotation = body.rotation(at: core.simulation.time)

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

        let unit: String

        if rotPeriod < 2.0 {
            rotPeriod *= 24.0
            dayLength *= 24.0

            unit = NSLocalizedString("hours", comment: "")
        } else {
            unit = NSLocalizedString("days", comment: "")
        }
        str += "\n"
        str += String(format: NSLocalizedString("Sidereal rotation period: %.2f %@", comment: ""), rotPeriod, unit)
        if dayLength != 0 {
            str += "\n"
            str += String(format: NSLocalizedString("Length of day: %.2f %@", comment: ""), dayLength, unit)
        }
    }

    if body.hasRings {
        str += "\n"
        str += NSLocalizedString("Has rings", comment: "")
    }
    if body.hasAtmosphere {
        str += "\n"
        str += NSLocalizedString("Has atmosphere", comment: "")
    }

    return str
}

private func overviewForStar(_ star: CelestiaStar) -> String {
    let core = CelestiaAppCore.shared
    var str = ""

    let time = core.simulation.time

    let celPos = star.position(at: time).offet(from: .zero)
    let eqPos = Astro.ecliptic(toEquatorial: Astro.cel(toJ2000Ecliptic: celPos))
    let sph = Astro.rect(toSpherical: eqPos)

    let hms = DMS(decimal: sph.dx)
    str += String(format: NSLocalizedString("RA: %dh %dm %.2fs", comment: ""), hms.hours, abs(hms.minutes), abs(hms.seconds))

    str += "\n"

    str += "\n"
    let dms = DMS(decimal: sph.dy)
    str += String(format: NSLocalizedString("Dec: %d° %d′ %.2f″", comment: ""), dms.degrees, abs(dms.minutes), abs(dms.seconds))

    return str
}

private func overviewForDSO(_ dso: CelestiaDSO) -> String {
    var str = ""

    let celPos = dso.position
    let eqPos = Astro.ecliptic(toEquatorial: Astro.cel(toJ2000Ecliptic: celPos))
    var sph = Astro.rect(toSpherical: eqPos)

    let hms = DMS(decimal: sph.dx)
    str += String(format: NSLocalizedString("RA: %dh %dm %.2fs", comment: ""), hms.hours, abs(hms.minutes), abs(hms.seconds))

    str += "\n"
    var dms = DMS(decimal: sph.dy)
    str += String(format: NSLocalizedString("Dec: %d° %d′ %.2f″", comment: ""), dms.degrees, abs(dms.minutes), abs(dms.seconds))

    let galPos = Astro.equatorial(toGalactic: eqPos)
    sph = Astro.rect(toSpherical: galPos)

    str += "\n"
    dms = DMS(decimal: sph.dx)
    str += String(format: NSLocalizedString("L: %d° %d′ %.2f″", comment: ""), dms.degrees, abs(dms.minutes), abs(dms.seconds))

    str += "\n"
    dms = DMS(decimal: sph.dy)
    str += String(format: NSLocalizedString("B: %d° %d′ %.2f″", comment: ""), dms.degrees, abs(dms.minutes), abs(dms.seconds))

    return str
}

fileprivate extension Float {
    var radiusString: String {
        if self < 1 {
            return String(format: NSLocalizedString("%d \(NSLocalizedString("m", comment: ""))", comment: ""), Int(self * 1000))
        }
        return String(format: NSLocalizedString("%d \(NSLocalizedString("km", comment: ""))", comment: ""), Int(self))
    }
}
