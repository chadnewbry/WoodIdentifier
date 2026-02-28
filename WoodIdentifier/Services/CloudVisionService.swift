import Foundation

/// Calls the GPT-4o vision API via the Cloudflare proxy for wood identification.
final class CloudVisionService {
    private let endpoint = URL(string: "https://realidcheck-proxy.chadnewbry.workers.dev")!

    private let systemPrompt = """
    You are a wood species identification expert. Analyze the provided photo(s) of wood \
    and return your top 3 species matches. For each match provide:
    - speciesId: a kebab-case identifier (e.g. "quercus-alba")
    - commonName: the common English name
    - scientificName: the Latin binomial
    - confidence: a number 0.0–1.0 representing your confidence
    - properties: an object with keys like "hardness", "grainPattern", "color", "density", "workability", "durability"
    - similarSpecies: array of common names of species that look similar

    Consider grain pattern, color, texture, end grain, and bark if visible.
    Respond ONLY with a JSON array of 3 objects. No markdown, no explanation.
    """

    func identify(imagesData: [Data]) async throws -> [WoodMatch] {
        // Build content array with text + images
        var content: [[String: Any]] = [
            ["type": "text", "text": "Identify the wood species in these photos. Return JSON array of top 3 matches."]
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
            "temperature": 0.3
        ]

        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 30
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

    private func parseResponse(_ data: Data) throws -> [WoodMatch] {
        // Extract the assistant message content from OpenAI response
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let choices = json["choices"] as? [[String: Any]],
              let first = choices.first,
              let message = first["message"] as? [String: Any],
              let content = message["content"] as? String else {
            throw WoodIdentificationError.malformedResponse
        }

        // Clean potential markdown code fences
        let cleaned = content
            .replacingOccurrences(of: "```json", with: "")
            .replacingOccurrences(of: "```", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard let jsonData = cleaned.data(using: .utf8),
              let array = try JSONSerialization.jsonObject(with: jsonData) as? [[String: Any]] else {
            throw WoodIdentificationError.malformedResponse
        }

        return array.compactMap { dict -> WoodMatch? in
            guard let speciesId = dict["speciesId"] as? String,
                  let commonName = dict["commonName"] as? String,
                  let scientificName = dict["scientificName"] as? String,
                  let confidence = dict["confidence"] as? Double else {
                return nil
            }

            // Parse properties dict
            var props: [String: String] = [:]
            if let p = dict["properties"] as? [String: Any] {
                for (k, v) in p { props[k] = "\(v)" }
            }

            let similar = dict["similarSpecies"] as? [String] ?? []

            return WoodMatch(
                speciesId: speciesId,
                commonName: commonName,
                scientificName: scientificName,
                confidence: confidence,
                properties: props,
                similarSpecies: similar
            )
        }
    }
}
