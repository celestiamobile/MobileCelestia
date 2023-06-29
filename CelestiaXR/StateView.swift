//
// StateView.swift
//
// Copyright © 2023 Celestia Development Team. All rights reserved.
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.
//

import CelestiaCore
import CelestiaUI
import CelestiaXRCore
import SwiftUI

struct StateView: View {
    let state: AppState

    @Environment(XRRenderer.self) private var renderer

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .medium
        return formatter
    }()

    private static let numberFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.usesGroupingSeparator = true
        return formatter
    }()

    private func currentTimeText() -> Text {
        return Text(state.time, format: .dateTime.year().month().day().hour().minute().second())
    }

    private func currentTimeText() -> String {
        let time = Self.dateFormatter.string(from: state.time)
        if state.isPaused {
            if state.isLightTravelDelayEnabled {
                return String.localizedStringWithFormat(CelestiaString("%@ LT (Paused)", comment: ""), time)
            } else {
                return String.localizedStringWithFormat(CelestiaString("%@ (Paused)", comment: ""), time)
            }
        } else {
            if state.isLightTravelDelayEnabled {
                return String.localizedStringWithFormat(CelestiaString("%@ LT", comment: ""), time)
            } else {
                return time
            }
        }
    }

    private func getName(_ selection: Selection) -> String {
        return renderer.appCore.simulation.universe.name(for: selection)
    }

    @ViewBuilder
    private func flightModeView() -> some View {
        switch state.coordinateSystem {
        case .ecliptical:
            Text(String.localizedStringWithFormat(CelestiaString("Follow %@", comment: ""), getName(state.referenceObject)))
        case .bodyFixed:
            Text(String.localizedStringWithFormat(CelestiaString("Sync Orbit %@", comment: ""), getName(state.referenceObject)))
        case .phaseLock:
            Text(String.localizedStringWithFormat(CelestiaString("Lock %1$@ → %2$@", comment: ""), getName(state.referenceObject), getName(state.targetObject)))
        case .chase:
            Text(String.localizedStringWithFormat(CelestiaString("Chase %@", comment: ""), getName(state.referenceObject)))
        case .universal:
            Text(CelestiaString("Freeflight", comment: ""))
        default:
            Text(CelestiaString("Unknown", comment: ""))
        }
    }

    var body: some View {
        Grid(alignment: .leadingFirstTextBaseline) {
            GridRow {
                Text(CelestiaString("Time", comment: ""))
                Group {
                    Text(currentTimeText())
                }
                .gridColumnAlignment(.trailing)
            }
            Divider()
            GridRow {
                Text(CelestiaString("Time Scale", comment: ""))
                if state.timeScale == 1.0 {
                    Text(CelestiaString("Real Time", comment: "Reset time speed to 1x"))
                } else if state.timeScale == -1.0 {
                    Text(CelestiaString("-Real Time", comment: ""))
                } else if abs(state.timeScale) < 1e-15 {
                    Text(CelestiaString("Time Stopped", comment: ""))
                } else {
                    Text(
                        String.localizedStringWithFormat(CelestiaString("%@x Real Time", comment: ""), Self.numberFormatter.string(from: state.timeScale))
                    )
                }
            }
            Divider()
            if !state.selectedObject.isEmpty {
                GridRow {
                    Text(CelestiaString("Selected", comment: ""))
                    Text(getName(state.selectedObject))
                }
                Divider()
                if state.showDistanceToSelection {
                    GridRow {
                        Text(CelestiaString("Distance", comment: "Distance to the object (in Go to)"))
                        Text(state.distanceToSelectionSurface.formattedLength())
                    }
                    Divider()

                    if state.showDistanceToSelectionCenter {
                        GridRow {
                            Text(CelestiaString("Distance to Center", comment: ""))
                            Text(state.distanceToSelectionCenter.formattedLength())
                        }
                        Divider()
                    }
                }
            }
            GridRow {
                Text(CelestiaString("Mode", comment: ""))
                flightModeView()
            }
            Divider()
            GridRow {
                Text(CelestiaString("Speed", comment: ""))
                Text(Double(state.speed).formattedSpeed())
            }
        }
    }
}

fileprivate extension Double {
    private static let usesMetricSystem = Locale.current.measurementSystem == .metric

    private static let numberFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.usesGroupingSeparator = true
        return formatter
    }()

    private static let oneMiInKm = 1.609344
    private static let oneFtInKm = 0.0003048

    func formattedLength() -> String {
        let ly = AstroUtils.kilometers(toLightYears: self)
        let number: Double
        let unitTemplate: String
        if abs(ly) >= AstroUtils.parsecs(toLightYears: 1e+6) {
            unitTemplate = CelestiaString("%@ Mpc", comment: "")
            number = AstroUtils.lightYears(toParsecs: ly) / 1e+6
        } else if abs(ly) >= 0.5 * AstroUtils.parsecs(toLightYears: 1e+3) {
            unitTemplate = CelestiaString("%@ kpc", comment: "")
            number = AstroUtils.lightYears(toParsecs: ly) / 1e+3
        } else {
            let au = AstroUtils.kilometers(toAU: self)
            if abs(au) >= 1000.0 {
                unitTemplate = CelestiaString("%@ ly", comment: "")
                number = ly
            } else if self >= 10000000.0 {
                unitTemplate = CelestiaString("%@ au", comment: "")
                number = au
            } else if !Self.usesMetricSystem {
                if self >= Self.oneMiInKm {
                    unitTemplate = CelestiaString("%@ mi", comment: "")
                    number = self / Self.oneMiInKm
                } else {
                    unitTemplate = CelestiaString("%@ ft", comment: "")
                    number = self / Self.oneFtInKm
                }
            } else {
                if self >= 1 {
                    unitTemplate = CelestiaString("%@ km", comment: "")
                    number = self
                } else {
                    unitTemplate = CelestiaString("%@ m", comment: "")
                    number = self * 1000
                }
            }
        }
        return String.localizedStringWithFormat(unitTemplate, Self.numberFormatter.string(from: number))
    }

    func formattedSpeed() -> String {
        let number: Double
        let unitTemplate: String
        let au = AstroUtils.kilometers(toAU: self)
        if abs(au) >= 1000.0 {
            unitTemplate = CelestiaString("%@ ly/s", comment: "")
            number = AstroUtils.kilometers(toLightYears: self)
        } else if self >= 10000000.0 {
            unitTemplate = CelestiaString("%@ au/s", comment: "")
            number = au
        } else if !Self.usesMetricSystem {
            if self >= Self.oneMiInKm {
                unitTemplate = CelestiaString("%@ mi/s", comment: "")
                number = self / Self.oneMiInKm
            } else {
                unitTemplate = CelestiaString("%@ ft/s", comment: "")
                number = self / Self.oneFtInKm
            }
        } else {
            if self >= 1 {
                unitTemplate = CelestiaString("%@ km/s", comment: "")
                number = self
            } else {
                unitTemplate = CelestiaString("%@ m/s", comment: "")
                number = self * 1000
            }
        }
        return String.localizedStringWithFormat(unitTemplate, Self.numberFormatter.string(from: number))
    }
}
