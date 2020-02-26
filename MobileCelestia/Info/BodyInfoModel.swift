//
//  BodyInfoModel.swift
//  MobileCelestia
//
//  Created by Li Linfeng on 2020/2/24.
//  Copyright © 2020 李林峰. All rights reserved.
//

import Foundation

import CelestiaCore

struct BodyInfo {
    let name: String
    let overview: String

    fileprivate let selection: CelestiaSelection
}

extension CelestiaAppCore {
    var selection: BodyInfo {
        get { return BodyInfo(selection: simulation.selection) }
        set { simulation.selection = newValue.selection }
    }
}

extension BodyInfo {
    init(selection: CelestiaSelection) {
        self.init(name: CelestiaAppCore.shared.simulation.universe.name(for: selection),
                  overview: overviewForSelection(selection), selection: selection)
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
        return CelestiaString("No overview available.", comment: "")
    }
}

private func overviewForBody(_ body: CelestiaBody) -> String {
    let core = CelestiaAppCore.shared
    var str = ""

    if body.isEllipsoid {
        str += String(format: CelestiaString("Equatorial radius: %@", comment: ""), body.radius.radiusString)
    } else {
        str += String(format: CelestiaString("Size: %@", comment: ""), body.radius.radiusString)
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

            unit = CelestiaString("hours", comment: "")
        } else {
            unit = CelestiaString("days", comment: "")
        }
        str += "\n"
        str += String(format: CelestiaString("Sidereal rotation period: %.2f %@", comment: ""), rotPeriod, unit)
        if dayLength != 0 {
            str += "\n"
            str += String(format: CelestiaString("Length of day: %.2f %@", comment: ""), dayLength, unit)
        }
    }

    if body.hasRings {
        str += "\n"
        str += CelestiaString("Has rings", comment: "")
    }
    if body.hasAtmosphere {
        str += "\n"
        str += CelestiaString("Has atmosphere", comment: "")
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
    str += String(format: CelestiaString("RA: %dh %dm %.2fs", comment: ""), hms.hours, abs(hms.minutes), abs(hms.seconds))

    str += "\n"

    str += "\n"
    let dms = DMS(decimal: sph.dy)
    str += String(format: CelestiaString("Dec: %d° %d′ %.2f″", comment: ""), dms.degrees, abs(dms.minutes), abs(dms.seconds))

    return str
}

private func overviewForDSO(_ dso: CelestiaDSO) -> String {
    var str = ""

    let celPos = dso.position
    let eqPos = Astro.ecliptic(toEquatorial: Astro.cel(toJ2000Ecliptic: celPos))
    var sph = Astro.rect(toSpherical: eqPos)

    let hms = DMS(decimal: sph.dx)
    str += String(format: CelestiaString("RA: %dh %dm %.2fs", comment: ""), hms.hours, abs(hms.minutes), abs(hms.seconds))

    str += "\n"
    var dms = DMS(decimal: sph.dy)
    str += String(format: CelestiaString("Dec: %d° %d′ %.2f″", comment: ""), dms.degrees, abs(dms.minutes), abs(dms.seconds))

    let galPos = Astro.equatorial(toGalactic: eqPos)
    sph = Astro.rect(toSpherical: galPos)

    str += "\n"
    dms = DMS(decimal: sph.dx)
    str += String(format: CelestiaString("L: %d° %d′ %.2f″", comment: ""), dms.degrees, abs(dms.minutes), abs(dms.seconds))

    str += "\n"
    dms = DMS(decimal: sph.dy)
    str += String(format: CelestiaString("B: %d° %d′ %.2f″", comment: ""), dms.degrees, abs(dms.minutes), abs(dms.seconds))

    return str
}

private extension Float {
    var radiusString: String {
        if self < 1 {
            return String(format: CelestiaString("%d \(CelestiaString("m", comment: ""))", comment: ""), Int(self * 1000))
        }
        return String(format: CelestiaString("%d \(CelestiaString("km", comment: ""))", comment: ""), Int(self))
    }
}
