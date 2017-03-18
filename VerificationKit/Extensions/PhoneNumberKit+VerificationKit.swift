import PhoneNumberKit

fileprivate func < <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
    switch (lhs, rhs) {
    case let (l?, r?):
        return l < r
    case (nil, _?):
        return true
    default:
        return false
    }
}

internal extension PhoneNumberKit {
    func availableCountries() -> [String] {
        return PhoneNumberKit()
            .allCountries()
            .filter { $0 != "001" }
            .sorted { $0.countryName() < $1.countryName() }
    }
}
