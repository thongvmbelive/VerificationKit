import AWSCore
import AWSLambda
import AWSSES
import AWSSNS
import PhoneNumberKit

/// A custom verification type which will be executed before sending SMS.
public typealias PhoneValidationBlock = (_ phoneNumber: PhoneNumber, _ completion: ((NSError?, Bool?) -> Void)?) -> Void

/// Called when the phone verification completes.
public typealias PhoneVerificationCompletion = (NSError?, PhoneNumber?) -> Void

/// A custom verification type which will be executed before sending email.
public typealias EmailValidationBlock = (_ emailAddress: String, _ completion: ((NSError?, Bool?) -> Void)?) -> Void

/// Called when the email verification completes.
public typealias EmailVerificationCompletion = (_ error: NSError?, _ email: String?) -> Void

/// Phone number types.
public enum PhoneNumberType: String {
    case landline = "landline"
    case mobile = "mobile"
    case voip = "voip"
}

/// The type of header text to use within the UI.
public enum HeaderTextType : UInt {
    case login
    case verify
}

/// Primary interface of VerificationKit.
public class Verification {

    /// The singleton instance of VerificationKit.
    public static let shared = Verification()

    /// The app name which will appear in the SMS message
    public var appName: String = ""

    /// An array of acceppted number types. Possible item values are .landline,
    /// .mobile and .voip.
    /// You need to setup an AWS Lambda function to look up number types.
    public var acceptedNumberTypes: [PhoneNumberType] = [.landline, .mobile, .voip]

    /// Blacklisting a set of countries allows a user to use all VerificationKit's
    /// supported countries except those defined in blacklist. The value is an
    /// array of 2-letter country codes as defined by ISO 3166-1 Alpha 2.
    public var blacklistedCountryCodes: [String] = []

    /// The type of header text to use within the UI.
    public var headerTextType: HeaderTextType = .verify

    /// The AWS Lambda function to look up phone number type.
    public var lookupFunction: String?

    /// The AWS Lambda function to place phone call.
    public var phonecallFunction: String?

    /// Phone number region code.
    public var regionCode: String {
        get {
            let code = _regionCode
            if blacklistedCountryCodes.contains(code) {
                return regionCodes[0]
            }
            return code
        }
        set(newRegionCode) {
            _regionCode = newRegionCode
        }
    }

    /// The input phone number.
    public var phoneNumber: PhoneNumber?

    /// A a custom ID that contains up to 11 alphanumeric characters, including 
    /// at least one letter and no spaces. The sender ID is displayed as the
    /// message sender on the receiving device. For example, you can use your
    /// business brand to make the message source easier to recognize. Support
    /// for sender IDs varies by country.
    /// See http://docs.aws.amazon.com/sns/latest/dg/sms_supported-countries.html
    public var senderId = "Verify"

    /// A theme for the VerificationKit UI
    public var theme: Theme?

    /// A custom verification which will be executed before sending SMS.
    public var phoneValidationBlock: PhoneValidationBlock?

    /// Sender email address. Must be a AWS SES verified email address.
    public var fromEmailAddress: String?

    /// Receiver email address.
    public var toEmailAddress: String?

    /// The content of the email, in HTML format. Use this for email clients
    /// that can process HTML. You can include clickable links, formatted text,
    /// and much more in an HTML message.
    public var htmlEmailContent: String?

    /// The content of the message, in text format. Use this for text-based
    /// email clients, or clients on high-latency networks (such as mobile
    /// devices).
    public var textEmailContent: String?

    /// A custom verification which will be executed before sending email.
    public var emailValidationBlock: EmailValidationBlock?

    // MARK: ------------------------------PRIVATE------------------------------

    internal var code: String = ""
    internal var completion: PhoneVerificationCompletion?
    internal var emailVerificationCompletion: EmailVerificationCompletion?

    internal var regionCodes: [String] {
        return PhoneNumberKit()
            .availableCountries()
            .filter { !(Verification.shared.blacklistedCountryCodes.contains($0)) }
    }

    fileprivate var _regionCode = PhoneNumberKit.defaultRegionCode()

    init() {}
}

// MARK: ------------------------------PUBLIC------------------------------
public extension Verification {

    /// Presents a view controller to verify user's phone number.
    ///
    /// - parameter completion: Called when the verification completes.
    func verifyPhone(completion: PhoneVerificationCompletion?) {
        self.completion = completion

        let storyboard = UIStoryboard(name: "VerificationKit", bundle: Bundle(identifier: "com.verificationkit.VerificationKit"))
        let verifyController = storyboard.instantiateViewController(withIdentifier: "AddPhoneViewController") as! AddPhoneViewController
        let nav = UINavigationController(rootViewController: verifyController)
        UIViewController.topViewController()?.present(nav, animated: true, completion: nil)
    }

    /// Presents a view controller to verify user's email address.
    ///
    /// - parameter completion: Called when the verification completes.
    func verifyEmail(completion: EmailVerificationCompletion?) {
        self.emailVerificationCompletion = completion

        let storyboard = UIStoryboard(name: "VerificationKit", bundle: Bundle(identifier: "com.verificationkit.VerificationKit"))
        let verifyController = storyboard.instantiateViewController(withIdentifier: "AddEmailViewController") as! AddEmailViewController
        let nav = UINavigationController(rootViewController: verifyController)
        UIViewController.topViewController()?.present(nav, animated: true, completion: nil)
    }
}

// MARK: -----------------------------INTERNAL-----------------------------
internal extension Verification {
    func sendSMS(_ completion: ((_ error: NSError?) -> Void)?) {
        let verification = Verification.shared
        let message = "\(verification.code) is your \(verification.appName) verification code.".localized
        let phoneNumber = verification.phoneNumber?.stringRepresentation

        debugPrint("[VerificationKit] Phone number:", phoneNumber ?? "", separator: " ", terminator: "\n")
        debugPrint("[VerificationKit] Text message:", message, separator: " ", terminator: "\n")

        let senderIdAttrs = AWSSNSMessageAttributeValue()
        senderIdAttrs?.dataType = "String"
        senderIdAttrs?.stringValue = senderId
        let smsTypeAttrs = AWSSNSMessageAttributeValue()
        smsTypeAttrs?.dataType = "String"
        smsTypeAttrs?.stringValue = "Transactional"

        let request = AWSSNSPublishInput()
        request?.message = message
        request?.phoneNumber = phoneNumber
        request?.messageAttributes = [
            "AWS.SNS.SMS.SenderID": senderIdAttrs!,
            "AWS.SNS.SMS.SMSType": smsTypeAttrs!
        ]
        let sns = AWSSNS.default()
        sns.publish(request!) { response, error in
            completion?(error as NSError?)
        }
    }

    func lookup(_ completion: ((_ error: NSError?, _ numberType: PhoneNumberType?) -> Void)?) {
        guard let lookupFunction = lookupFunction else {
            fatalError("[VerificationKit] You must specify a lookupFunction")
        }

        guard let phoneNumber = Verification.shared.phoneNumber?.stringRepresentation else {
            let error = NSError(domain: "com.verificationkit.error", code: -70002, userInfo: [NSLocalizedDescriptionKey: "Please enter a valid phone number.".localized])
            completion?(error, nil)
            return
        }
        let invoker = AWSLambdaInvoker.default()
        let parameters = [
            "phoneNumber": phoneNumber
        ]
        invoker.invokeFunction(lookupFunction, jsonObject: parameters) { (response, error) in
            if let numberType = response as? String {
                completion?(error as NSError?, PhoneNumberType(rawValue: numberType))
                return
            }
            completion?(error as NSError?, nil)
        }
    }

    func call(_ completion: ((_ error: NSError?) -> Void)?) {
        guard let phonecallFunction = phonecallFunction else {
            fatalError("[VerificationKit] You must specify a phoneCallFunction")
        }

        let verification = Verification.shared
        guard let phoneNumber = verification.phoneNumber?.stringRepresentation else {
            let error = NSError(domain: "com.verificationkit.error", code: -70002, userInfo: [NSLocalizedDescriptionKey: "Please enter a valid phone number.".localized])
            completion?(error as NSError?)
            return
        }
        let digits = verification.code.map { String($0) }
        let code = digits.joined(separator: ", ")
        let twiML = String(format: "<Response><Say language=\"en-US\" voice=\"alice\" loop=\"2\">Your verification code for %2$@ is, %1$@.</Say></Response>".localized, code, verification.appName)

        let invoker = AWSLambdaInvoker.default()
        let parameters = [
            "to": phoneNumber,
            "twiML": twiML
        ]
        invoker.invokeFunction(phonecallFunction, jsonObject: parameters) { (response, error) in
            completion?(error as NSError?)
        }
    }

    func sendEmail(_ completion: ((_ error: NSError?) -> Void)?) {
        let verification = Verification.shared
        guard let email = verification.toEmailAddress else {
            let error = NSError(domain: "com.verificationkit.error", code: -70000, userInfo: [NSLocalizedDescriptionKey: "Enter your email address".localized])
            completion?(error)
            return
        }

        let destination = AWSSESDestination()
        destination?.toAddresses = [email]

        let subject = AWSSESContent()
        subject?.charset = "UTF-8"
        subject?.data = "Please verify your email"

        let body = AWSSESBody()

        if let htmlEmailContent = htmlEmailContent {
            let htmlContent = AWSSESContent()
            htmlContent?.charset = "UTF-8"
            htmlContent?.data = htmlEmailContent.replacingOccurrences(of: "%@", with: code)
            body?.html = htmlContent
        }

        if let textEmailContent = textEmailContent {
            let textContent = AWSSESContent()
            textContent?.charset = "UTF-8"
            textContent?.data = String(format: textEmailContent, code)
            body?.text = textContent
        }

        let message = AWSSESMessage()
        message?.subject = subject
        message?.body = body

        let request = AWSSESSendEmailRequest()
        request?.source = verification.fromEmailAddress
        request?.destination = destination
        request?.message = message

        let ses = AWSSES.default()
        ses.sendEmail(request!) { (response, error) in
            completion?(error as NSError?)
        }
    }
}
