// Copyright 2016 LinkedIn Corp.
// Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except in compliance with the License.
// You may obtain a copy of the License at http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing,
// software distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.

import XCTest
import LayoutKit

class ButtonLayoutTests: XCTestCase {

    func testButtonLayouts() {
        let types: [ButtonLayoutType] = [
            .custom,
            .system,
            .detailDisclosure,
            .infoDark,
            .infoLight,
            .contactAdd,
        ]

        for textTestCase in Text.testCases {
            for type in types {
                verifyButtonLayout(textTestCase: textTestCase, type: type)
            }
        }
    }

    private func verifyButtonLayout(textTestCase: Text.TestCase, type: ButtonLayoutType) {
        let button = UIButton(type: type.buttonType)
        if let font = textTestCase.font {
            button.titleLabel?.font = font
        }
        switch textTestCase.text {
        case .unattributed(let text):
            button.setTitle(text, for: .normal)
        case .attributed(let text):
            button.setAttributedTitle(text, for: .normal)
        }

        let layout = textTestCase.font.map({ (font: UIFont) -> Layout in
            return ButtonLayout(type: type, title: textTestCase.text, font: font)
        }) ?? ButtonLayout(type: type, title: textTestCase.text)

        XCTAssertEqual(layout.arrangement().frame.size, button.intrinsicContentSize, "fontName:\(textTestCase.font?.fontName) title:'\(textTestCase.text)' fontSize:\(textTestCase.font?.pointSize) type:\(type)")
    }
}
