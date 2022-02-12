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
}

struct RunScriptContext: Decodable {
    let scriptContent: String
    let scriptType: String
}

struct ShareURLContext: Decodable {
    let title: String
    let url: URL
}

protocol BaseJavascriptHandler {
    var operation: String { get }
    func executeWithContent(content: String, delegate: CelestiaScriptHandlerDelegate)
}

class JavascriptHandler<T: Decodable>: BaseJavascriptHandler {
    var operation: String { fatalError() }

    func execute(context: T, delegate: CelestiaScriptHandlerDelegate) {
        fatalError()
    }

    func executeWithContent(content: String, delegate: CelestiaScriptHandlerDelegate) {
        guard let data = content.data(using: .utf8) else { return }
        do {
            let context = try JSONDecoder().decode(T.self, from: data)
            execute(context: context, delegate: delegate)
        } catch {}
    }
}

class RunScriptHandler: JavascriptHandler<RunScriptContext> {
    override var operation: String { return "runScript" }

    override func execute(context: RunScriptContext, delegate: CelestiaScriptHandlerDelegate) {
        delegate.runScript(type: context.scriptType, content: context.scriptContent)
    }
}

class ShareURLHandler: JavascriptHandler<ShareURLContext> {
    override var operation: String { return "shareURL" }

    override func execute(context: ShareURLContext, delegate: CelestiaScriptHandlerDelegate) {
        delegate.shareURL(title: context.title, url: context.url)
    }
}

protocol CelestiaScriptHandlerDelegate: AnyObject {
    func runScript(type: String, content: String)
    func shareURL(title: String, url: URL)
}

class CelestiaScriptHandler: NSObject, WKScriptMessageHandler {
    weak var delegate: CelestiaScriptHandlerDelegate?

    private static let handlers: [BaseJavascriptHandler] = [
        RunScriptHandler(),
        ShareURLHandler(),
    ]

    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        guard let strongDelegate = delegate else { return }
        guard let string = message.body as? String, let data = string.data(using: .utf8) else { return }
        do {
            let payload = try JSONDecoder().decode(MessagePayload.self, from: data)
            for handler in Self.handlers {
                if handler.operation == payload.operation {
                    handler.executeWithContent(content: payload.content, delegate: strongDelegate)
                    break
                }
            }
        } catch {}
    }
}
