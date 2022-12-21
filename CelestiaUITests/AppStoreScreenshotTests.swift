//
// AppStoreScreenshot.swift
//
// Copyright © 2021 Celestia Development Team. All rights reserved.
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.
//

import XCTest

struct TestItem {
    let celURL: String
    let addonID: String?
    let showInfo: Bool
}

@MainActor
class AppStoreScreenshotTests: XCTestCase {
    private let app = XCUIApplication()

    let itemsToTest = [
        TestItem(celURL: "cel://Follow/Sol:Earth/2023-07-02T13:52:59.06554Z?x=gHqIoxcYrv7//////////w&y=JAcLdlkIUQ&z=ySumWO0O/v///////////w&ow=-0.73719114&ox=-0.26776052&oy=-0.6141897&oz=0.087318935&select=Sol:Earth&fov=15.534162&ts=1&ltd=0&p=1&rf=71227287&nrf=255&lm=2048&tsrc=0&ver=3", addonID: nil, showInfo: true),
        TestItem(celURL: "cel://Follow/Sol/2023-06-10T04:01:09.36594Z?x=AADgxNkenTx7Ag&y=AAAAeu5N7SvJAw&z=AABAbpqtfATN+v///////w&ow=-0.1762914&ox=0.039147615&oy=0.9339327&oz=0.30847773&fov=15.497456&ts=1&ltd=0&p=0&rf=71227315&nrf=255&lm=6147&tsrc=0&ver=3", addonID: nil, showInfo: false),
        TestItem(celURL: "cel://SyncOrbit/Sol:Earth/2024-07-30T06:00:31.79943Z?x=5H8ym9O86f///////////w&y=Jx39zwAGIw&z=6bKOqSApDw&ow=0.88020444&ox=-0.3483816&oy=0.18829681&oz=-0.26156196&select=TYC%204123-1214-1&fov=51.175&ts=1&ltd=0&p=1&rf=71235487&nrf=255&lm=15&tsrc=0&ver=3", addonID: nil, showInfo: false),
        TestItem(celURL: "cel://Follow/Westerhout%2051/2023-06-10T03:31:39.13768Z?x=AAAAAABxRUqY3KUS&y=AAAAAAA1xr8Nhgv2/////w&z=AAAAAAC8ueP73lXs/////w&ow=-0.4382953&ox=0.5837729&oy=0.678968&oz=0.07815942&fov=15.497456&ts=1&ltd=0&p=0&rf=71227287&nrf=255&lm=2048&tsrc=0&ver=3", addonID: nil, showInfo: false),
        TestItem(celURL: "cel://Follow/Sol:Jupiter:Callisto/2023-07-02T11:03:12.01362Z?x=YJG63ya8Sf///////////w&y=k1RN8wszCw&z=ZY4WNWkjGQ&ow=0.7285262&ox=-0.043709736&oy=0.682417&oz=0.0405734&fov=5.30302&ts=10&ltd=0&p=1&rf=71227287&nrf=255&lm=2048&tsrc=0&ver=3", addonID: nil, showInfo: false),
        TestItem(celURL: "cel://Follow/Cygnus%20X-1/2023-07-02T13:52:59.06554Z?x=ACwEriWpVvv//////////w&y=cKpIoLiUl////////////w&z=AOyX+4hMTQg&ow=0.10665737&ox=-0.3053027&oy=-0.0070079123&oz=0.94623744&select=HD%20226868%20A&fov=15.534161&ts=10&ltd=0&p=1&rf=71227287&nrf=255&lm=2048&tsrc=0&ver=3", addonID: "87D5FBAB-5722-70A9-6D4C-F4FD22EA87BC", showInfo: false),
    ]

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.

        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testTakeScreenshots() throws {
#if targetEnvironment(macCatalyst)
        let xcode = XCUIApplication(bundleIdentifier: "com.apple.dt.Xcode")
        if xcode.buttons["_XCUI:MinimizeWindow"].isHittable {
            xcode.buttons["_XCUI:MinimizeWindow"].tap()
        }
#endif

        for (index, item) in itemsToTest.enumerated() {
            try takeURLScreenshots(from: item, name: "URL\(index).png")
        }
    }

    func takeScreenshotsNow(name: String) throws {
        #if targetEnvironment(macCatalyst)
        let deviceName = "Mac"
        let directory = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] + "/Celestia/\(deviceName)"
        #else
        let deviceName = ProcessInfo.processInfo.environment["SIMULATOR_DEVICE_NAME"]!
        let directory = ProcessInfo.processInfo.environment["SIMULATOR_HOST_HOME"]! + "/Documents/Celestia/\(deviceName)"
        #endif
        try FileManager.default.createDirectory(atPath: directory, withIntermediateDirectories: true, attributes: nil)
        let path = "\(directory)/\(name)"
        #if targetEnvironment(macCatalyst)
        let process = Process()
        process.setValue("/usr/sbin/screencapture", forKey: "launchPath")
        process.arguments = [path]
        process.perform(NSSelectorFromString("launch"))
        process.waitUntilExit()
        #else
        try XCUIScreen.main.screenshot().pngRepresentation.write(to: URL(fileURLWithPath: path))
        #endif
        print("Saving screenshot to \(path)")
    }

    func takeURLScreenshots(from item: TestItem, name: String) throws {
        app.launch()

        #if targetEnvironment(macCatalyst)
        app.activate()
        app.buttons["_XCUI:FullScreenWindow"].tap()
        #endif

        #if targetEnvironment(macCatalyst)
        let safari = XCUIApplication(bundleIdentifier: "com.apple.Safari")
        #else
        let safari = XCUIApplication(bundleIdentifier: "com.apple.mobilesafari")
        #endif
        safari.launch()
        safari.activate()

        #if !targetEnvironment(macCatalyst)
        safari.buttons["Address"].tap()
        #endif

        safari.typeText(item.celURL)
        safari.typeText("\n")

        #if targetEnvironment(macCatalyst)
        safari.toggles["Allow"].tap()
        #else
        safari.buttons["Open"].tap()
        #endif

        safari.terminate()

        sleep(20)

        #if targetEnvironment(macCatalyst)
        app.sheets.buttons["OK"].tap()
        #else
        app.buttons["OK"].tap()
        #endif

        sleep(5)

        #if targetEnvironment(macCatalyst)
        if item.showInfo {
            safari.launch()
            safari.activate()
            
            safari.typeText("celestia://getinfo")
            safari.typeText("\n")
            
            safari.toggles["Allow"].tap()
            
            safari.terminate()
            
            sleep(5)
        }
        #else
        if item.showInfo {
            app.buttons["Get Info"].tap()
        } else {
            app.buttons["Hide"].tap()
        }
        #endif

        if let addonID = item.addonID {
            safari.launch()
            safari.activate()

#if !targetEnvironment(macCatalyst)
            safari.buttons["Address"].tap()
#endif

            safari.typeText("celaddon://item?item=\(addonID)")
            safari.typeText("\n")

#if targetEnvironment(macCatalyst)
            safari.toggles["Allow"].tap()
#else
            safari.buttons["Open"].tap()
#endif

            safari.terminate()

            sleep(5)
        }

        sleep(5)

        try takeScreenshotsNow(name: name)

        sleep(2)

        app.terminate()
    }
}
