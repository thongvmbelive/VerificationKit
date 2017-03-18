# VerificationKit

**VerficationKit** is a phone number and email address verification framework
for iOS in Swift.

## Why VerificationKit?

<table>
  <tr>
    <th colspan="2">Features</th>
  </tr>
  <tr>
    <td>:sunglasses:</td>
    <td>SMS sender is your app name</td>
  </tr>
  <tr>
    <td>:muscle:</td>
    <td>SMS messages in your own brand</td>
  </tr>
  <tr>
    <td>:jp:</td>
    <td>Localized in 50 languages</td>
  </tr>
  <tr>
    <td>:telephone_receiver:</td>
    <td>SMS and phone call verification</td>
  </tr>
  <tr>
    <td>:rocket:</td>
    <td>Fast integration, no server needed</td>
  </tr>
  <tr>
    <td>:octocat:</td>
    <td>Open source under the MIT license</td>
  </tr>
</table>

## Screenshots

<img src="https://github.com/thii/VerificationKit/blob/master/.github/AddPhone.png?raw=true" height=480> <img src="https://github.com/thii/VerificationKit/blob/master/.github/VerifyPhone.png?raw=true" height=480>

## Getting Started

### Prerequisites

VerificationKit uses Amazon Simple Notification Service (SNS) to send SMS and
Amazon Simple Email Service (SES) to send email. You need an Amazon Web Services
account in order to get started.

### Usage

1. Integrate VerificationKit into your project using Carthage:

    ```
    github "thii/VerificationKit"
    ```

1. Add AWSCore, AWSLambda, AWSSES, AWSSNS frameworks into your project. You can
follow the instructions from the
[aws-sdk-ios](https://github.com/aws/aws-sdk-ios) page. I recommend using adding
them manually if you don't use all AWS frameworks.

1. In your AWS account, go to Amazon Cognito service, click **Manage Federated
Identities** > **Create new identity pool** to create a new identity pool. Note
your identity pool ID.

1. Select **Enable access to unauthenticated identities**.

1. The above step will create an IAM role. Go to your account's IAM service and
attach `ses:SendEmail` policy to send emails and `sns:Publish` policy to send
SMS.

1. Attach policies to invoke any AWS Lambda functions that you want to use in
your app (e.g. function to place phone calls, function to look up phone
number type).

1. To use phone number verification, in your AppDelegate's `application(_
application: UIApplication, didFinishLaunchingWithOptions launchOptions:
[UIApplicationLaunchOptionsKey: Any]?) -> Bool`, add the following to configure
the AWS services:

    ```swift
    let credentialsProvider = AWSCognitoCredentialsProvider(regionType: AWSRegionType.usWest2, identityPoolId: "IDENTITY_POOL_ID")
    let configuration = AWSServiceConfiguration(region: AWSRegionType.usWest2, credentialsProvider: credentialsProvider)
    AWSServiceManager.default().defaultServiceConfiguration = configuration

    let verify = Verification.shared
    verify.appName = "Samples"
    verify.phonecallFunction = "PhoneCall" // AWS Lambda function to place phone calls (optional)
    ```

    Where `IDENTITY_POOL_ID` is the identity pool ID you noted in the first step.
    Change the `regionType` value to the region in which you have created your
    identity pool.

    To start verifying phone number, in your view controller, call:

    ```swift
    let verify = Verification.shared
    verify.verifyPhone { (error, phoneNumber) in
        print(error ?? "")
        print(phoneNumber ?? "")
    }
    ```

1. To use email address verification, in your AppDelegate's `application(_
application: UIApplication, didFinishLaunchingWithOptions launchOptions:
[UIApplicationLaunchOptionsKey: Any]?) -> Bool`, add the following to configure
the AWS services:

    ```swift
    let credentialsProvider = AWSCognitoCredentialsProvider(regionType: AWSRegionType.usWest2, identityPoolId: "IDENTITY_POOL_ID")
    let configuration = AWSServiceConfiguration(region: AWSRegionType.usWest2, credentialsProvider: credentialsProvider)
    AWSServiceManager.default().defaultServiceConfiguration = configuration

    let verify = Verification.shared
    verify.appName = "Samples"
    verify.fromEmailAddress = "email@example.com"
    verify.htmlEmailContent = "Your email verification code is: %@"
    verify.textEmailContent = "<p>Your email verification code is: %@</p>"
    ```

    `email@example.com` is the sender email address that you have added and
    verified in your Amazon SES account. You need to verify it in order to start
    sending email on its behalf.

    To start verifying user's email address, in your view controller, call:

    ```swift
    let verify = Verification.shared
    verify.verifyEmail { (error, email) in
        print(error ?? "")
        print(email ?? "")
    }
    ```

1. (Optional) You may change the default theme of the verification view
controller.

    ```swift
    var theme = Theme()
    theme.buttonBackgroundColor = UIColor.purple
    theme.buttonTextColor = UIColor.white
    let verify = Verification.shared
    verify.theme = theme
    ```

See more at [Documentation](https://thii.github.io/VerificationKit).

## Samples App

To run the Samples app, first you need to copy the example constants file and
change its default settings. You only need to set the `IDENTITY_POOL_ID` and
`REGION_TYPE` if you just want to test the phone number verification feature.

    cp Samples/Samples/Constants.swift.example Samples/Samples/Constants.swift

```swift
let IDENTITY_POOL_ID = "Your identity pool ID goes here" // E.g. "us-west-2:xxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
let REGION_TYPE = AWSRegionType.usWest2 // The region in which you have created your identity pool
```

## License
MIT
