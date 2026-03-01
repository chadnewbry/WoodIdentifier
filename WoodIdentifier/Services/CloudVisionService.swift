import Foundation

/// Calls the GPT-4o vision API via the Cloudflare proxy for wood identification.
final class CloudVisionService {
    private let endpoint = URL(string: "https://realidcheck-proxy.chadnewbry.workers.dev")!

    private let systemPrompt = """
    You are an expert wood species identification botanist and woodworker. \
    Analyze the provided photo(s) of wood and return your top 3 species matches as a JSON array.

    For each match include exactly these fields:
    - speciesId: kebab-case identifier (e.g. "quercus-alba")
    - commonName: common English name
    - scientificName: Latin binomial
    - confidence: number 0.0–1.0 representing your confidence
    - hardness: Janka hardness in lbf as an integer, or null if unknown
    - grainPattern: concise description (e.g. "straight", "interlocked", "wavy with ray fleck")
    - typicalUses: comma-separated common uses (e.g. "furniture, flooring, cabinetry")
    - similarSpecies: JSON array of common names of visually similar species
    - properties: JSON object with any additional key-value details such as color, density, \
    workability, durability, or other notable characteristics

    Consider grain pattern, color, texture, pore structure, end grain, and bark if visible.
    Respond ONLY with a JSON object containing a "matches" key whose value is an array of exactly 3 objects. No markdown, no code fences, no explanation.
    Example format: {"matches": [...]}
    """

    func identify(imagesData: [Data]) async throws -> [WoodMatch] {
        var content: [[String: Any]] = [
            ["type": "text", "text": "Identify the wood species in these photos. Respond with the JSON array as instructed."]
        ]

        for data in imagesData {
            let base64 = data.base64EncodedString()
            content.append([
                "type": "image_url",
                "image_url": ["url": "data:image/jpeg;base64,\(base64)"]
            ])
        }

        let body: [String: Any] = [
            "model": "gpt-4o",
            "messages": [
                ["role": "system", "content": systemPrompt],
                ["role": "user", "content": content]
            ],
            "max_tokens": 1500,
            "temperature": 0.2,
            "response_format": ["type": "json_object"]
        ]

        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 60
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)

        if let http = response as? HTTPURLResponse, http.statusCode == 429 {
            throw WoodIdentificationError.apiRateLimited
        }
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw WoodIdentificationError.networkFailure(
                NSError(domain: "CloudVision", code: (response as? HTTPURLResponse)?.statusCode ?? 0)
            )
        }

        return try parseResponse(data)
    }

    // MARK: - Private

    private func parseResponse(_ data: Data) throws -> [WoodMatch] {
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let choices = json["choices"] as? [[String: Any]],
              let first = choices.first,
              let message = first["message"] as? [String: Any],
              let content = message["content"] as? String else {
            throw WoodIdentificationError.malformedResponse
        }

        // Strip markdown code fences defensively
        let cleaned = content
            .replacingOccurrences(of: "```json", with: "")
            .replacingOccurrences(of: "```", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        // Support both a bare array and a wrapped object like {"results": [...]}
        let array: [[String: Any]]
        if let jsonData = cleaned.data(using: .utf8),
           let direct = try? JSONSerialization.jsonObject(with: jsonData) as? [[String: Any]] {
            array = direct
        } else if let jsonData = cleaned.data(using: .utf8),
                  let wrapped = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any] {
            // Try common wrapper keys, then fall back to first array value found
            if let inner = (wrapped["results"] ?? wrapped["matches"] ?? wrapped["species"]) as? [[String: Any]] {
                array = inner
            } else if let inner = wrapped.values.first(where: { $0 is [[String: Any]] }) as? [[String: Any]] {
                array = inner
            } else {
                print("[WoodID] Unexpected response structure: \(wrapped.keys)")
                throw WoodIdentificationError.malformedResponse
            }
        } else {
            print("[WoodID] Could not parse response: \(cleaned.prefix(200))")
            throw WoodIdentificationError.malformedResponse
        }

        let matches = array.prefix(3).compactMap { dict -> WoodMatch? in
            guard let speciesId = dict["speciesId"] as? String,
                  let commonName = dict["commonName"] as? String,
                  let scientificName = dict["scientificName"] as? String,
                  let confidence = dict["confidence"] as? Double else {
                return nil
            }

            let hardness = dict["hardness"] as? Int
            let grainPattern = dict["grainPattern"] as? String ?? ""
            let typicalUses = dict["typicalUses"] as? String ?? ""
            let similar = dict["similarSpecies"] as? [String] ?? []

            var props: [String: String] = [:]
            if let p = dict["properties"] as? [String: Any] {
                for (k, v) in p { props[k] = "\(v)" }
            }

            return WoodMatch(
                speciesId: speciesId,
                commonName: commonName,
                scientificName: scientificName,
                confidence: min(max(confidence, 0), 1),
                hardness: hardness,
                grainPattern: grainPattern,
                typicalUses: typicalUses,
                properties: props,
                similarSpecies: similar
            )
        }

        guard !matches.isEmpty else { throw WoodIdentificationError.malformedResponse }
        return matches
    }
}
