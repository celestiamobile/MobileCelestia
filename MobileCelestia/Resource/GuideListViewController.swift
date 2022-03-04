//
// GuideListViewController.swift
//
// Copyright © 2022 Celestia Development Team. All rights reserved.
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.
//

import CelestiaCore
import UIKit

extension GuideItem: AsyncListItem {
    var name: String {
        return title
    }

    var imageURL: (URL, String)? {
        return nil
    }
}

class GuideListViewController: AsyncListViewController<GuideItem> {
    private let type: String
    private let listTitle: String

    override class var useStylizedCells: Bool {
        return false
    }

    init(type: String, title: String, selection: @escaping (GuideItem) -> Void) {
        self.type = type
        self.listTitle = title
        super.init(selection: selection)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = listTitle
    }

    override func loadItems(pageStart: Int, pageSize: Int, success: @escaping ([GuideItem]) -> Void, failure: @escaping (Error) -> Void) {
        let requestURL = apiPrefix + "/resource/guides"
        _ = RequestHandler.get(url: requestURL, parameters: [
            "lang": AppCore.language,
            "type": type,
            "pageStart": "\(pageStart)",
            "pageSize": "\(pageSize)",
        ], success: { (items: [GuideItem]) in
            success(items)
        }, failure: failure)
    }
}
