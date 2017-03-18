import Foundation
import PhoneNumberKit

/// This class represents a phone number.
public struct PhoneNumber {

    /// The country code for the phone number.
    public var countryCode: String

    /// The remaining portion of the phone number after the country code.
    public var phoneNumber: String

    /// Initializes a PhoneNumber instance.
    ///
    /// - parameter countryCode: The country code for the phone number.
    /// - parameter phoneNumber: The remaining portion of the phone number after
    ///   the country code.
    public init(countryCode: String, phoneNumber: String) {
        self.countryCode = countryCode
        self.phoneNumber = PhoneNumber.parseNationalNumber(phoneNumber)
    }

    /// Compares the receiver to another phone number.
    ///
    /// - parameter phoneNumber: the phone number to compare to.
    ///
    /// - returns: comparation result.
    public func isEqualToPhoneNumber(_ phoneNumber: PhoneNumber) -> Bool {
        if phoneNumber.countryCode == self.countryCode && phoneNumber.phoneNumber == self.phoneNumber {
            return true
        }
        return false
    }

    /// Phone number in E164 format. All characters that are not digits will be
    /// stripped from the phone number and a `+` character will precede the
    /// country code value.
    public var stringRepresentation: String {
        let phoneNumberKit = PhoneNumberKit()
        let regionCode = Verification.shared.regionCode

        do {
            let phoneNumber = try phoneNumberKit.parse(self.phoneNumber, withRegion: regionCode)
            let formattedString: String = phoneNumberKit.format(phoneNumber, toType: .e164)
            return formattedString
        }
        catch let error as NSError {
            print(error.localizedDescription)
            return "+" + countryCode + phoneNumber
        }
    }

    /// Phone number in national format.
    public func nationalFormat() -> String {
        let phoneNumberKit = PhoneNumberKit()
        let regionCode = Verification.shared.regionCode

        do {
            let phoneNumber = try phoneNumberKit.parse(self.phoneNumber, withRegion: regionCode)
            let formattedString: String = phoneNumberKit.format(phoneNumber, toType: .national)
            return formattedString
        }
        catch let error as NSError {
            print(error.localizedDescription)
            return phoneNumber
        }
    }

    fileprivate static func parseNationalNumber(_ numberString: String) -> String {
        let digitsSet = CharacterSet(charactersIn: "0123456789")
        let string = numberString.components(separatedBy: digitsSet.inverted).joined(separator: "")
        guard let int = UInt(string) else { return "" }
        return "\(int)"
    }
}
