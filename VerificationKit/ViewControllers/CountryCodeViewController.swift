import PhoneNumberKit
import UIKit

class CountryCodeViewController: UITableViewController {

    let regionCodes = Verification.shared.regionCodes

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "Select Your Country".localized
    }

    // MARK: - Table view data source

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return regionCodes.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "CountryCodeCell", for: indexPath)

        let regionCode = regionCodes[(indexPath as NSIndexPath).row]

        if let countryName = regionCode.countryName() {
            cell.textLabel?.text = "\(regionCode.emojiFlag()) \(countryName)"
        }

        if let callingCode = PhoneNumberKit().countryCode(for: regionCode) {
            cell.detailTextLabel?.text = "+\(callingCode)"
        }

        return cell
    }

    // MARK - Table view delegate

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        Verification.shared.regionCode = regionCodes[(indexPath as NSIndexPath).row]
        let _ = navigationController?.popViewController(animated: true)
    }
}
