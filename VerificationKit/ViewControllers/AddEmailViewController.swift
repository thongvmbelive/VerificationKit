import UIKit

class AddEmailViewController: UIViewController, UITextFieldDelegate {

    @IBOutlet weak var promptLabel: UILabel!
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var nextButton: UIButton!

    override func viewDidLoad() {
        super.viewDidLoad()

        if Verification.shared.headerTextType == .verify {
            title = "Confirm your email".localized
        } else {
            title = "Log In".localized
        }

        promptLabel.text = "Enter your email address".localized
        emailTextField.placeholder = "user@example.com"
        nextButton.setTitle("Next".localized, for: UIControl.State())

        navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(cancel))
        nextButton.layer.cornerRadius = 5

        nextButton.backgroundColor = Verification.shared.theme?.buttonBackgroundColor
        nextButton.titleLabel?.textColor = Verification.shared.theme?.buttonTextColor

        emailTextField.keyboardType = .emailAddress
        emailTextField.delegate = self
        emailTextField.becomeFirstResponder()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        emailTextField.resignFirstResponder()
    }

    @objc func cancel() {
        dismiss(animated: true, completion: nil)
    }

    @IBAction func nextButtonDidTap(_ sender: AnyObject) {
        guard let email = emailTextField.text , email.isValidEmailAddress else {
            UIAlertController.showError(message: "This email is incorrect. Please try again.".localized)
            return
        }

        let verification = Verification.shared
        verification.code = String.randomCode(length: 4)
        verification.toEmailAddress = email
        setViewStatus(isSending: true)

        if let validationBlock = verification.emailValidationBlock {
            validationBlock(email, { (error, emailAddress) in
                if let error = error {
                    self.setViewStatus(isSending: false)
                    UIAlertController.show(error)
                    return
                }
                verification.sendEmail { error in
                    if let error = error {
                        self.setViewStatus(isSending: false)
                        UIAlertController.show(error)
                        return
                    }
                    self.setViewStatus(isSending: false)
                    DispatchQueue.main.async(execute: {
                        self.performSegue(withIdentifier: "VerifyEmailSegue", sender: self)
                    })
                }
            })
        } else {
            verification.sendEmail { error in
                self.setViewStatus(isSending: false)
                if let error = error {
                    UIAlertController.show(error)
                    return
                }
                DispatchQueue.main.async(execute: {
                    self.performSegue(withIdentifier: "VerifyEmailSegue", sender: self)
                })
            }
        }
    }

    override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        if identifier == "VerifyEmailSegue" { return false }
        return true
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        nextButtonDidTap(self)
        return true
    }

    func setViewStatus(isSending: Bool) {
        DispatchQueue.main.async(execute: {
            self.emailTextField.isUserInteractionEnabled = !isSending
            self.nextButton.isUserInteractionEnabled = !isSending
            self.nextButton.backgroundColor = isSending ? UIColor.lightGray : Verification.shared.theme?.buttonBackgroundColor

            if isSending {
                self.nextButton.setTitle("Sending email...".localized, for: UIControl.State())
            } else {
                self.nextButton.setTitle("Next".localized, for: UIControl.State())
            }
        })
    }
}
