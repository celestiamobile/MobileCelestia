//
// CelestiaScriptHandler.swift
//
// Copyright © 2022 Celestia Development Team. All rights reserved.
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.
//

import WebKit

struct MessagePayload: Decodable {
    let operation: String
    let content: String
    let minScriptVersion: Int
}

struct RunScriptContext: Decodable {
    let scriptContent: String
    let scriptType: String
    let scriptName: String?
    let scriptLocation: String?
}

struct ElementFrame: Decodable {
    let left: CGFloat
    let top: CGFloat
    let width: CGFloat
    let height: CGFloat
}

struct ShareURLContext: Decodable {
    let title: String
    let url: URL
    let frame: ElementFrame
}

struct SendACKContext: Decodable {
    let id: String
}

struct OpenAddonNextContext: Decodable {
    let id: String
}

struct RunDemoContext: Decodable {
}

struct OpenSubscriptionPageContext: Decodable {
}

protocol BaseJavascriptHandler {
    var operation: String { get }
    func executeWithContent(content: String, delegate: CelestiaScriptHandlerDelegate)
}

class JavascriptHandler<T: Decodable & Sendable>: BaseJavascriptHandler, @unchecked Sendable {
    var operation: String { fatalError() }

    @MainActor
    func execute(context: T, delegate: CelestiaScriptHandlerDelegate) {
        fatalError()
    }

    func executeWithContent(content: String, delegate: CelestiaScriptHandlerDelegate) {
        guard let data = content.data(using: .utf8) else { return }
        do {
            let context = try JSONDecoder().decode(T.self, from: data)
            Task.detached { @MainActor in
                self.execute(context: context, delegate: delegate)
            }
        } catch {}
    }
}

class RunScriptHandler: JavascriptHandler<RunScriptContext> {
    override var operation: String { return "runScript" }

    override func execute(context: RunScriptContext, delegate: CelestiaScriptHandlerDelegate) {
        delegate.runScript(type: context.scriptType, content: context.scriptContent, name: context.scriptName, location: context.scriptLocation)
    }
}

class ShareURLHandler: JavascriptHandler<ShareURLContext> {
    override var operation: String { return "shareURL" }

    override func execute(context: ShareURLContext, delegate: CelestiaScriptHandlerDelegate) {
        delegate.shareURL(title: context.title, url: context.url, rect: CGRect(x: context.frame.left, y: context.frame.top, width: context.frame.width, height: context.frame.height))
    }
}

class SendACKHandler: JavascriptHandler<SendACKContext> {
    override var operation: String { return "sendACK" }

    override func execute(context: SendACKContext, delegate: CelestiaScriptHandlerDelegate) {
        delegate.receivedACK(id: context.id)
    }
}

class OpenAddonNextHandler: JavascriptHandler<OpenAddonNextContext> {
    override var operation: String { return "openAddonNext" }

    override func execute(context: OpenAddonNextContext, delegate: CelestiaScriptHandlerDelegate) {
        delegate.openAddonNext(id: context.id)
    }
}

class RunDemoHandler: JavascriptHandler<RunDemoContext> {
    override var operation: String { return "runDemo" }

    override func execute(context: RunDemoContext, delegate: CelestiaScriptHandlerDelegate) {
        delegate.runDemo()
    }
}


class OpenSubscriptionPageHandler: JavascriptHandler<OpenSubscriptionPageContext> {
    override var operation: String { return "openSubscriptionPage" }

    override func execute(context: OpenSubscriptionPageContext, delegate: CelestiaScriptHandlerDelegate) {
        delegate.openSubscriptionPage()
    }
}

@MainActor
protocol CelestiaScriptHandlerDelegate: AnyObject, Sendable {
    func runScript(type: String, content: String, name: String?, location: String?)
    func shareURL(title: String, url: URL, rect: CGRect)
    func receivedACK(id: String)
    func openAddonNext(id: String)
    func runDemo()
    func openSubscriptionPage()
}

class CelestiaScriptHandler: NSObject, WKScriptMessageHandler {
    weak var delegate: CelestiaScriptHandlerDelegate?

    private static let supportedScriptVersion = 4

    private static let handlers: [BaseJavascriptHandler] = [
        RunScriptHandler(),
        ShareURLHandler(),
        SendACKHandler(),
        OpenAddonNextHandler(),
        RunDemoHandler(),
        OpenSubscriptionPageHandler(),
    ]

    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        guard let strongDelegate = delegate else { return }
        guard let string = message.body as? String, let data = string.data(using: .utf8) else { return }
        do {
            let payload = try JSONDecoder().decode(MessagePayload.self, from: data)
            if payload.minScriptVersion > Self.supportedScriptVersion { return }
            for handler in Self.handlers {
                if handler.operation == payload.operation {
                    handler.executeWithContent(content: payload.content, delegate: strongDelegate)
                    break
                }
            }
        } catch {}
    }
}
