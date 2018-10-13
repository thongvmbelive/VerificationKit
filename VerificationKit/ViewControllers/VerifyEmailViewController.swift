import UIKit

class VerifyEmailViewController: UIViewController, UITextFieldDelegate {

    @IBOutlet weak var enterCodePromtLabel: UILabel!
    @IBOutlet weak var enterCodePromptSubtitleLabel: UILabel!
    @IBOutlet weak var verificationCodeField: UITextField!
    @IBOutlet weak var resendCodeButton: UIButton!

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "Confirm your email".localized
        enterCodePromtLabel.text = "Enter your code".localized

        if let email = Verification.shared.toEmailAddress {
            enterCodePromptSubtitleLabel.text = String(format: "We sent a code to \n%@.".localized, email)
        }
        verificationCodeField.placeholder = "Verification code".localized
        resendCodeButton.setTitle("Resend Email".localized, for: UIControlState())

        resendCodeButton.layer.cornerRadius = 5

        let verfication = Verification.shared
        resendCodeButton.backgroundColor = verfication.theme?.buttonBackgroundColor
        resendCodeButton.titleLabel?.textColor = verfication.theme?.buttonTextColor

        verificationCodeField.addTarget(self, action: #selector(textFieldDidChange(_:)), for: UIControlEvents.editingChanged)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        verificationCodeField.becomeFirstResponder()
    }

    @IBAction func resendCodeButtonDidTap(_ sender: AnyObject) {
        updateResendCodeButtonStatus(whileSending: true)

        Verification.shared.sendEmail { (error) in
            self.updateResendCodeButtonStatus(whileSending: false)
            if let error = error { debugPrint("[VerificationKit]", error) }
        }
    }

    func textFieldDidChange(_ textField: UITextField) {
        if textField.text?.count != 4 { return }

        let verification = Verification.shared
        if textField.text == verification.code {
            dismiss(animated: true) {
                verification.emailVerificationCompletion?(nil, verification.toEmailAddress)
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
                self.resendCodeButton.setTitle("Sending email...".localized, for: UIControlState())
            } else {
                self.resendCodeButton.backgroundColor = Verification.shared.theme?.buttonBackgroundColor
                self.resendCodeButton.setTitle("Resend Email".localized, for: UIControlState())
            }
        })
    }
}
