import UIKit

/// A type that represents a specific font.
public enum Font {
    /// Uses a custom font with the provided associated value as font name.
    case custom(String)
    /// Uses the default system font.
    case systemDefault
}

extension Font {
    /// A type that determines the weight of a font.
    public enum Weight {
        /// The light font weight.
        case light
        /// The regular font weight.
        case regular
        /// The bold font weight.
        case bold

        var fontWeight: UIFont.Weight {
            switch self {
            case .light:
                return .light
            case .regular:
                return .regular
            case .bold:
                return .bold
            }
        }
    }
}

extension Font {
    
    enum Size: UInt {
        
        /// 80
        case yotta = 80
        
        /// 45
        case peta = 45
        
        /// 35
        case tera = 35
        
        /// 25
        case giga = 25
        
        /// 21
        case mega = 21
        
        /// 17
        case hecto = 17
        
        /// 15
        case deci = 15
        
        /// 13
        case micro = 13
        
        /// 11
        case nano = 11
        
        /// 10
        /// - Note: This size should only be used for the tab bar label.
        case tabBarLabel = 10
        
        /// 9
        case pico = 9
        
        fileprivate var textStyle: UIFont.TextStyle {
            switch self {
            case .yotta:
                return UIFont.TextStyle.largeTitle
            case .peta:
                return UIFont.TextStyle.largeTitle
            case .tera:
                return UIFont.TextStyle.title1
            case .giga:
                return UIFont.TextStyle.title2
            case .mega:
                return UIFont.TextStyle.title3
            case .hecto:
                return UIFont.TextStyle.headline
            case .deci:
                return UIFont.TextStyle.body
            case .micro:
                return UIFont.TextStyle.callout
            case .pico:
                return UIFont.TextStyle.footnote
            case .tabBarLabel:
                return UIFont.TextStyle.caption1
            case .nano:
                return UIFont.TextStyle.caption2
            }
        }
        
        var pointSize: CGFloat {
            return CGFloat(rawValue)
        }
        
        var lineHeight: CGFloat {
            switch self {
            case .peta:
                return 48
            case .tera:
                return 40
            case .giga:
                return 28
            case .mega:
                return 28
            case .hecto:
                return 24
            case .deci:
                return 20
            case .micro:
                return 20
            case .nano:
                return 16
            case .pico:
                return 12
            default:
                return self.pointSize
            }
        }
    }
    
    static func light(_ size: Size, adjustsFontForContentSizeCategory: Bool = true) -> UIFont {
        if adjustsFontForContentSizeCategory {
            return scaledFont(weight: .light, size: size)
        } else {
            return font(weight: .light, size: size)
        }
    }
    
    static func regular(_ size: Size, adjustsFontForContentSizeCategory: Bool = true) -> UIFont {
        if adjustsFontForContentSizeCategory {
            return scaledFont(weight: .regular, size: size)
        } else {
            return font(weight: .regular, size: size)
        }
    }
    
    static func semibold(_ size: Size, adjustsFontForContentSizeCategory: Bool = true) -> UIFont {
        if adjustsFontForContentSizeCategory {
            return scaledFont(weight: .semibold, size: size)
        } else {
            return font(weight: .semibold, size: size)
        }
    }
    
    static func bold(_ size: Size, adjustsFontForContentSizeCategory: Bool = true) -> UIFont {
        if adjustsFontForContentSizeCategory {
            return scaledFont(weight: .bold, size: size)
        } else {
            return font(weight: .bold, size: size)
        }
    }
    
    static func lineSpacing(weight: Weight, size: Size) -> CGFloat {
        let maxLineHeight = size.lineHeight * 1.5
        let scaledLineHeight = UIFontMetrics(forTextStyle: size.textStyle).scaledValue(for: size.lineHeight)
        return min(maxLineHeight, scaledLineHeight) - scaledFont(weight: weight, size: size).lineHeight
    }
    
    private static func font(weight: Weight, size: Size) -> UIFont {
        switch Appearance.fontProvider.font(for: weight) {
        case .custom(let fontName):
            return UIFont(name: fontName, size: size.pointSize)!
        case .systemDefault:
            return UIFont.systemFont(ofSize: size.pointSize, weight: weight.fontWeight)
        }
    }
    
    private static func scaledFont(weight: Weight, size: Size) -> UIFont {
        let lotaGrotesque = font(weight: weight, size: size)
        if size == .tabBarLabel { return lotaGrotesque }
        return UIFontMetrics(forTextStyle: size.textStyle).scaledFont(for: lotaGrotesque, maximumPointSize: size.pointSize * 1.5)
    }
}
