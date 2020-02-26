//
//  Celestia+Extension.swift
//  MobileCelestia
//
//  Created by Li Linfeng on 2020/2/24.
//  Copyright © 2020 李林峰. All rights reserved.
//

import CelestiaCore

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

var solBrowserRoot: CelestiaBrowserItem = {
    let universe = CelestiaAppCore.shared.simulation.universe
    let sol = universe.find("Sol")
    return CelestiaBrowserItem(name: universe.starCatalog.starName(sol.star!), catEntry: sol.star!, provider: universe)
}()

var starBrowserRoot: CelestiaBrowserItem = {
    let core = CelestiaAppCore.shared
    let universe = core.simulation.universe

    func updateAccumulation(result: inout [String : CelestiaBrowserItem], star: CelestiaStar) {
        let name = universe.starCatalog.starName(star)
        result[name] = CelestiaBrowserItem(name: name, catEntry: star, provider: universe)
    }

    let nearest = CelestiaStarBrowser(kind: .nearest, simulation: core.simulation).stars().reduce(into: [String : CelestiaBrowserItem](), updateAccumulation)
    let brightest = CelestiaStarBrowser(kind: .brightest, simulation: core.simulation).stars().reduce(into: [String : CelestiaBrowserItem](), updateAccumulation)
    let hasPlanets = CelestiaStarBrowser(kind: .starsWithPlants, simulation: core.simulation).stars().reduce(into: [String : CelestiaBrowserItem](), updateAccumulation)

    let nearestName = CelestiaString("Nearest Stars", comment: "")
    let brightestName = CelestiaString("Brightest Stars", comment: "")
    let hasPlanetsName = CelestiaString("Stars With Planets", comment: "")
    let stars = CelestiaBrowserItem(name: CelestiaString("Stars", comment: ""), children: [
        nearestName : CelestiaBrowserItem(name: nearestName, children: nearest),
        brightestName : CelestiaBrowserItem(name: brightestName, children: brightest),
        hasPlanetsName : CelestiaBrowserItem(name: hasPlanetsName, children: hasPlanets),
    ])
    return stars
}()

var dsoBrowserRoot: CelestiaBrowserItem = {
    let core = CelestiaAppCore.shared
    let universe = core.simulation.universe

    let typeMap = [
        "SB" : CelestiaString("Galaxies (Barred Spiral)", comment: ""),
        "S" : CelestiaString("Galaxies (Spiral)", comment: ""),
        "E" : CelestiaString("Galaxies (Elliptical)", comment: ""),
        "Irr" : CelestiaString("Galaxies (Irregular)", comment: ""),
        "Neb" : CelestiaString("Nebulae", comment: ""),
        "Glob" : CelestiaString("Globulars", comment: ""),
        "Open cluster" : CelestiaString("Open Clusters", comment: ""),
        "Unknown" : CelestiaString("Unknown", comment: ""),
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
    return CelestiaBrowserItem(name: CelestiaString("Deep Sky Objects", comment: ""), children: results)
}()

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

func CelestiaString(_ key: String, comment: String) -> String {
    return LocalizedString(key)
}

func CelestiaFilename(_ key: String) -> String {
    return LocalizedFilename(key)
}
