import Foundation
import PhoneNumberKit

internal extension String {
    func countryName() -> String? {
        let locale = Locale.current
        return (locale as NSLocale).displayName(forKey: NSLocale.Key.countryCode, value: self)
    }

    // Generate a random code
    static func randomCode(length: Int) -> String {
        var s = ""
        for _ in 0..<length {
            s.append("\(arc4random_uniform(10))")
        }
        return s
    }

    /// Emoji flags from ISO 3166-1 country codes
    ///
    /// See more: https://bendodson.com/weblog/2016/04/26/emoji-flags-from-iso-3166-country-codes-in-swift/
    func emojiFlag() -> String {
        var string = ""
        var country = self.uppercased()
        for uS in country.unicodeScalars {
            string.append(String(describing: UnicodeScalar(127397 + uS.value)!))
        }
        return string
    }

    /// Email Address Validation
    ///
    /// See more: http://bjmiller.me/post/143143277507/simple-email-address-validation-for-ios
    var isValidEmailAddress: Bool {
        let types: NSTextCheckingResult.CheckingType = [.link]
        let linkDetector = try? NSDataDetector(types: types.rawValue)
        let range = NSRange(location: 0, length: self.characters.count)
        let result = linkDetector?.firstMatch(in: self, options: .reportCompletion, range: range)
        let scheme = result?.url?.scheme ?? ""
        return scheme == "mailto" && result?.range.length == self.characters.count
    }

    var localized: String {
        return NSLocalizedString(self, bundle: Bundle.verificationKitStringsBundle, comment: "")
    }
}
