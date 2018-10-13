import PhoneNumberKit
import UIKit

class AddPhoneViewController: UIViewController {

    @IBOutlet weak var addPhonePromtLabel: UILabel!
    @IBOutlet weak var callingCodeButton: UIButton!
    @IBOutlet weak var phoneNumberField: PhoneNumberTextField!
    @IBOutlet weak var nextButton: UIButton!

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        let countryCode = Verification.shared.regionCode
        phoneNumberField.defaultRegion = countryCode
        if let countryName = countryCode.countryName(), let callingCode = PhoneNumberKit().countryCode(for: countryCode) {
            if UIApplication.shared.userInterfaceLayoutDirection == .leftToRight {
                let title = "\(countryCode.emojiFlag()) \(countryName) (+\(callingCode))"
                callingCodeButton.setTitle(title, for: UIControl.State())
                callingCodeButton.contentHorizontalAlignment = .left
            } else {
                let title = "\(countryName) (\(callingCode)+)"
                callingCodeButton.setTitle(title, for: UIControl.State())
                callingCodeButton.contentHorizontalAlignment = .right
            }
        }

        phoneNumberField.becomeFirstResponder()
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        if Verification.shared.headerTextType == .verify {
            title = "Add phone".localized
        } else {
            title = "Log In".localized
        }

        addPhonePromtLabel.text = "Enter your phone number".localized
        phoneNumberField.placeholder = "Phone number".localized
        nextButton.setTitle("Next".localized, for: UIControl.State())

        navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(cancel))
        phoneNumberField.withPrefix = false
        nextButton.layer.cornerRadius = 5

        nextButton.backgroundColor = Verification.shared.theme?.buttonBackgroundColor
        nextButton.titleLabel?.textColor = Verification.shared.theme?.buttonTextColor
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        phoneNumberField.resignFirstResponder()
    }

    @objc func cancel() {
        dismiss(animated: true, completion: nil)
    }

    @IBAction func nextButtonDidTap(_ sender: AnyObject) {
        let verification = Verification.shared

        guard let countryCode = PhoneNumberKit().countryCode(for: verification.regionCode), let nationalNumber = phoneNumberField.text else { return }
        let phoneNumber = PhoneNumber(countryCode: "\(countryCode)", phoneNumber: nationalNumber)
        verification.phoneNumber = phoneNumber
        verification.code = String.randomCode(length: 4)

        if !phoneNumberField.isValidNumber {
            UIAlertController.showError(message: "Please enter a valid phone number.".localized)
            return
        }

        let validationCompletion: (_ error: NSError?, _ valid: Bool?) -> Void = { error, isValid in
            if let error = error {
                self.setViewStatus(isSending: false)
                debugPrint("[VerificationKit]", error)
                UIAlertController.show(error)
                return
            }
            if isValid == false {
                self.setViewStatus(isSending: false)
                UIAlertController.showError(message: "Please enter a valid phone number.".localized)
                return
            }
            if verification.acceptedNumberTypes == [.landline, .mobile, .voip] {
                verification.sendSMS() { (error) in
                    self.setViewStatus(isSending: false)
                    if let error = error {
                        UIAlertController.show(error)
                    }
                    DispatchQueue.main.async(execute: {
                        self.performSegue(withIdentifier: "VerifySegue", sender: self)
                    })
                }
                return
            }
            verification.lookup() { (error, numberType) in
                if let error = error {
                    self.setViewStatus(isSending: false)
                    debugPrint("[VerificationKit]", error)
                    UIAlertController.show(error)
                } else if let numberType = numberType {
                    if verification.acceptedNumberTypes.contains(numberType) {
                        verification.sendSMS() { (error) in
                            if let error = error {
                                self.setViewStatus(isSending: false)
                                UIAlertController.show(error)
                                return
                            }
                            self.setViewStatus(isSending: false)
                            DispatchQueue.main.async(execute: {
                                self.performSegue(withIdentifier: "VerifySegue", sender: self)
                            })
                        }
                    } else {
                        self.setViewStatus(isSending: false)
                        UIAlertController.showError(message: "Please enter a valid phone number.".localized)
                    }
                }
            }
        }

        setViewStatus(isSending: true)
        if let validationBlock = verification.phoneValidationBlock {
            validationBlock(phoneNumber, validationCompletion)
        } else {
            validationCompletion(nil, true)
        }
    }

    override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        if identifier == "VerifySegue" { return false }
        return true
    }

    func setViewStatus(isSending: Bool) {
        DispatchQueue.main.async(execute: {
            self.callingCodeButton.isUserInteractionEnabled = !isSending
            self.phoneNumberField.isUserInteractionEnabled = !isSending
            self.nextButton.isUserInteractionEnabled = !isSending
            self.nextButton.backgroundColor = isSending ? UIColor.lightGray : Verification.shared.theme?.buttonBackgroundColor

            if isSending {
                self.nextButton.setTitle("Sending verification code".localized, for: UIControl.State())
            } else {
                self.nextButton.setTitle("Next".localized, for: UIControl.State())
            }
        })
    }
}
