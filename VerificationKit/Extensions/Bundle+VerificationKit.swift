import Foundation

internal extension Bundle {
    class var verificationKitStringsBundle: Bundle {
        if let frameworkBundle = Bundle(path: Bundle.main.bundlePath + "/Frameworks/VerificationKit.framework/VerificationKitStrings.bundle") {
            return frameworkBundle
        }
        return Bundle(path: Bundle.main.bundlePath + "/VerificationKitStrings.bundle")!
    }
}
