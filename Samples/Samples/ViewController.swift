import AWSCore
import VerificationKit
import UIKit

class ViewController: UIViewController {

    let verify = Verification.shared

    override func viewDidLoad() {
        super.viewDidLoad()

        verify.appName = "Samples"
        verify.lookupFunction = LOOKUP_FUNCTION
        verify.phonecallFunction = CALLOUT_FUNCTION
        verify.fromEmailAddress = FROM_EMAIL

        if let file = Bundle.main.path(forResource: "EmailTemplate", ofType: "html") {
            do {
                verify.htmlEmailContent = try NSString(contentsOfFile: file, encoding: String.Encoding.utf8.rawValue) as String
            } catch _ { }
        }

        if let txtFile = Bundle.main.path(forResource: "EmailTemplate", ofType: "txt") {
            do {
                verify.textEmailContent = try NSString(contentsOfFile: txtFile, encoding: String.Encoding.utf8.rawValue) as String
            } catch _ { }
        }

        var theme = Theme()
        theme.buttonBackgroundColor = UIColor.purple
        verify.theme = theme
    }

    @IBAction func verify(_ sender: AnyObject) {
        verify.verifyPhone { (error, phoneNumber) in
            print(error ?? "")
            print(phoneNumber ?? "")
        }
    }

    @IBAction func verifyEmail(_ sender: AnyObject) {
        verify.verifyEmail { (error, emailAddress) in
            print(error ?? "")
            print(emailAddress ?? "")
        }
    }
}
