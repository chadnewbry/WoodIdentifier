import Foundation
import UIKit

/// Service for identifying wood species from photos using the AI proxy.
class WoodIdentificationService {
    static let shared = WoodIdentificationService()

    private let endpoint = URL(string: "https://realidcheck-proxy.chadnewbry.workers.dev")!

    private init() {}

    func identify(image: UIImage) async throws -> String {
        // TODO: Implement image encoding and API call
        fatalError("Not yet implemented")
    }
}
