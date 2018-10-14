import UIKit

class VerificationPhoneViewController: UIViewController, UITextFieldDelegate {

    @IBOutlet weak var enterCodePromtLabel: UILabel!
    @IBOutlet weak var enterCodePromptSubtitleLabel: UILabel!
    @IBOutlet weak var verificationCodeField: UITextField!
    @IBOutlet weak var resendCodeButton: UIButton!
    @IBOutlet weak var callMeButton: UIButton!

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "Verify phone".localized
        enterCodePromtLabel.text = "Enter your code".localized

        if let phoneNumberNationalFormatString = Verification.shared.phoneNumber?.nationalFormat() {
            enterCodePromptSubtitleLabel.text = "We sent a code to \n\(phoneNumberNationalFormatString).".localized
        }
        verificationCodeField.placeholder = "Verification code".localized
        resendCodeButton.setTitle("Resend code".localized, for: UIControl.State())
        callMeButton.setTitle("Call me".localized, for: UIControl.State())

        resendCodeButton.layer.cornerRadius = 5
        callMeButton.layer.cornerRadius = 5

        let verfication = Verification.shared
        resendCodeButton.backgroundColor = verfication.theme?.buttonBackgroundColor
        resendCodeButton.titleLabel?.textColor = verfication.theme?.buttonTextColor
        callMeButton.backgroundColor = verfication.theme?.buttonBackgroundColor
        callMeButton.titleLabel?.textColor = verfication.theme?.buttonTextColor
        callMeButton.isHidden = verfication.phonecallFunction == ""

        verificationCodeField.addTarget(self, action: #selector(textFieldDidChange(_:)), for: UIControl.Event.editingChanged)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        verificationCodeField.becomeFirstResponder()
    }

    @IBAction func resendCodeButtonDidTap(_ sender: AnyObject) {
        updateResendCodeButtonStatus(whileSending: true)

        Verification.shared.sendSMS() { (error) in
            self.updateResendCodeButtonStatus(whileSending: false)
            if let error = error { debugPrint("[VerificationKit]", error) }
        }
    }

    @IBAction func callmeButtonDidTap(_ sender: AnyObject) {
        updateCallMeButtonStatus(whileCalling: true)
        Verification.shared.call() { (error) in
            self.updateCallMeButtonStatus(whileCalling: false)
            if let error = error { debugPrint("[VerificationKit]", error) }
        }
    }

    @objc func textFieldDidChange(_ textField: UITextField) {
        if textField.text?.count != 4 { return }

        let verification = Verification.shared
        if textField.text == verification.code {
            dismiss(animated: true) {
                verification.completion?(nil, verification.phoneNumber)
            }
        }
    }

    // @see http://stackoverflow.com/a/1773257/2780476
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        let currentCharacterCount = textField.text?.count ?? 0
        if (range.length + range.location > currentCharacterCount){
            return false
        }
        let newLength = currentCharacterCount + string.count - range.length
        return newLength <= 4
    }

    func updateResendCodeButtonStatus(whileSending sending: Bool) {
        DispatchQueue.main.async(execute: {
            self.resendCodeButton.isUserInteractionEnabled = !sending

            if sending {
                self.resendCodeButton.backgroundColor = UIColor.lightGray
                self.resendCodeButton.setTitle("Sending...".localized, for: UIControl.State())
            } else {
                self.resendCodeButton.backgroundColor = Verification.shared.theme?.buttonBackgroundColor
                self.resendCodeButton.setTitle("Resend code".localized, for: UIControl.State())
            }
        })
    }

    func updateCallMeButtonStatus(whileCalling calling: Bool) {
        DispatchQueue.main.async(execute: {
            self.callMeButton.isUserInteractionEnabled = !calling

            if calling {
                self.callMeButton.backgroundColor = UIColor.lightGray
                self.callMeButton.setTitle("Calling...".localized, for: UIControl.State())
            } else {
                self.callMeButton.backgroundColor = Verification.shared.theme?.buttonBackgroundColor
                self.callMeButton.setTitle("Call me".localized, for: UIControl.State())
            }
        })
    }
}
