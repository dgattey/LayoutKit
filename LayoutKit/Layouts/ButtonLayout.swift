// Copyright 2016 LinkedIn Corp.
// Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except in compliance with the License.
// You may obtain a copy of the License at http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing,
// software distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.

import UIKit

/**
 Layout for a UIButton.

 Since UIKit does not provide threadsafe methods to determine the size of a button given its content
 ButtonLayout's implementation is not future proof for any design changes that may happen to UIButton in the future.
 If the style of UIButton changes in the future, then ButtonLayout will need to be updated accordingly.

 If future-proofing is a concern for your application, then you should not use ButtonLayout and instead implement your own
 custom layout that uses you own custom button view (e.g. by subclassing UIControl).
 */
open class ButtonLayout<Button: UIButton>: BaseLayout<Button>, ConfigurableLayout {

    private let type: ButtonLayoutType
    private let title: Text
    private let font: UIFont?

    public init(type: ButtonLayoutType,
                title: Text,
                font: UIFont? = nil,
                alignment: Alignment = defaultAlignment,
                flexibility: Flexibility = defaultFlexibility,
                viewReuseId: String? = nil,
                config: ((Button) -> Void)? = nil) {

        self.type = type
        self.title = title
        self.font = font
        super.init(alignment: alignment, flexibility: flexibility, viewReuseId: viewReuseId, config: config)
    }

    open func measurement(within maxSize: CGSize) -> LayoutMeasurement {
        let titleSize = sizeOfTitle(within: maxSize)

        // This is observed padding behavior of UIButton.
        let width: CGFloat
        let height: CGFloat
        switch type {
        case .custom:
            if #available(tvOS 10.0, *) {
                width = ceil(max(titleSize.width, minWidth))
                height = calculateHeightWithPadding(titleSize.height)
            } else {
                // Prior to tvOS 10.0, custom buttons had the same behavior as system buttons.
                fallthrough
            }
        case .system:
            width = ceil(max(titleSize.width + systemPadding.width, minWidth))
            height = calculateHeightWithPadding(titleSize.height)
        case .contactAdd, .infoLight, .infoDark, .detailDisclosure:
            width = iconWidth + ceil(titleSize.width)
            height = iconHeight + iconPadding.height
        }

        let size = CGSize(width: width, height: height).decreasedToSize(maxSize)
        return LayoutMeasurement(layout: self, size: size, maxSize: maxSize, sublayouts: [])
    }

    // Takes into account attributed vs unattributed string, as well as the padding needed
    // for this button. Should only be called on .custom buttons.
    private func calculateHeightWithPadding(_ height: CGFloat) -> CGFloat {
        switch title {
        case .attributed(let attributedString):
            if attributedString.length == 0 {
                fallthrough
            }
            return RoundUtils.roundUpToFractionalPoint(height + systemPadding.height)
        case .unattributed(_):
            return ceil(height + systemPadding.height)
        }
    }

    /// Unlike UILabel, UIButton has nonzero height when the title is empty.
    private func sizeOfTitle(within maxSize: CGSize) -> CGSize {
        switch title {
        case .attributed(let text):
            if text.string == "" {
                let attributedText = NSMutableAttributedString(attributedString: text)
                attributedText.mutableString.setString(" ")
                return CGSize(width: 0, height: sizeOf(text: .attributed(attributedText), maxSize: maxSize).height)
            } else {
                return sizeOf(text: title, maxSize: maxSize)
            }
        case .unattributed(let text):
            if text == "" {
                return CGSize(width: 0, height: sizeOf(text: .unattributed(" "), maxSize: maxSize).height)
            } else {
                return sizeOf(text: title, maxSize: maxSize)
            }
        }
    }

    private func sizeOf(text: Text, maxSize: CGSize) -> CGSize {
        return LabelLayout(text: text, font: fontForMeasurement, numberOfLines: 0).measurement(within: maxSize).size
    }

    /**
     The font that should be used to measure the button's title.
     This is based on observed behavior of UIButton.
     */
    private var fontForMeasurement: UIFont {
        switch type {
        case .custom:
            return font ?? defaultFontForCustomButton
        case .system:
            return font ?? defaultFontForSystemButton
        case .contactAdd, .infoLight, .infoDark, .detailDisclosure:
            // Setting a custom font has no effect in this case.
            return defaultFontForSystemButton
        }
    }

    private var defaultFontForCustomButton: UIFont {
        #if os(tvOS)
            return UIFont.systemFont(ofSize: 38, weight: UIFontWeightMedium)
        #else
            return UIFont.systemFont(ofSize: 18)
        #endif
    }

    private var defaultFontForSystemButton: UIFont {
        #if os(tvOS)
            return UIFont.systemFont(ofSize: 38, weight: UIFontWeightMedium)
        #else
            return UIFont.systemFont(ofSize: 15)
        #endif
    }

    private let minWidth: CGFloat = 30

    private var systemPadding: CGSize {
        #if os(tvOS)
            return CGSize(width: 80, height: 40)
        #else
            return CGSize(width: 0, height: 12)
        #endif
    }

    private var iconWidth: CGFloat {
        #if os(tvOS)
            return 117
        #else
            return 22
        #endif
    }

    private var iconHeight: CGFloat {
        #if os(tvOS)
            return 46
        #else
            return 22
        #endif
    }

    private var iconPadding: CGSize {
        #if os(tvOS)
            let height = isTitleEmpty ? 31 : 40
            return CGSize(width: 0, height: height)
        #else
            return .zero
        #endif
    }

    private var isTitleEmpty: Bool {
        switch title {
        case .unattributed(let text):
            return text == ""
        case .attributed(let text):
            return text.string == ""
        }
    }

    open func arrangement(within rect: CGRect, measurement: LayoutMeasurement) -> LayoutArrangement {
        let frame = alignment.position(size: measurement.size, in: rect)
        return LayoutArrangement(layout: self, frame: frame, sublayouts: [])
    }

    open override func makeView() -> View {
        return Button(type: type.buttonType)
    }

    open override func configure(view: Button) {
        config?(view)
        if let font = font {
            view.titleLabel?.font = font
        }
        switch title {
        case .unattributed(let text):
            view.setTitle(text, for: .normal)
        case .attributed(let text):
            view.setAttributedTitle(text, for: .normal)
        }
    }
}

/**
 Maps to UIButtonType.
 This prevents LayoutKit from breaking if a new UIButtonType is added.
 */
public enum ButtonLayoutType {
    case custom
    case system
    case detailDisclosure
    case infoLight
    case infoDark
    case contactAdd

    public var buttonType: UIButtonType {
        switch (self) {
        case .custom:
            return .custom
        case .system:
            return .system
        case .detailDisclosure:
            return .detailDisclosure
        case .infoLight:
            return .infoLight
        case .infoDark:
            return .infoDark
        case .contactAdd:
            return .contactAdd
        }
    }
}

private let defaultAlignment = Alignment.topLeading
private let defaultFlexibility = Flexibility.flexible
