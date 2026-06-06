import Foundation
import Combine

// MARK: - AI Provider
enum AIProvider: String, CaseIterable, Codable {
    case none    = "none"
    case gemini  = "gemini"
    case claude  = "claude"

    var displayName: String {
        switch self {
        case .none:   return "Disabled"
        case .gemini: return "Google Gemini"
        case .claude: return "Anthropic Claude"
        }
    }

    var icon: String {
        switch self {
        case .none:   return "slash.circle"
        case .gemini: return "sparkles"
        case .claude: return "brain.head.profile"
        }
    }
}

// MARK: - AI Request Context
struct AIFitnessContext {
    var currentWeightLbs: Double
    var goalWeightLbs: Double
    var weightLostLbs: Double
    var weekNumber: Int
    var weeklyWorkoutsCompleted: Int
    var weeklyWorkoutsTarget: Int
    var averageDailySteps: Double
    var averageSleepHours: Double
    var averageCaloriesLogged: Double
    var calorieTarget: Double
    var habitsCompletedPercent: Double

    var summaryText: String {
        """
        User stats:
        - Current weight: \(String(format: "%.1f", currentWeightLbs)) lbs, goal: \(String(format: "%.1f", goalWeightLbs)) lbs
        - Weight lost so far: \(String(format: "%.1f", weightLostLbs)) lbs
        - Program week: \(weekNumber)
        - Workouts this week: \(weeklyWorkoutsCompleted)/\(weeklyWorkoutsTarget)
        - Avg daily steps: \(Int(averageDailySteps).formatted())
        - Avg sleep: \(String(format: "%.1f", averageSleepHours)) hrs/night
        - Avg calories logged: \(Int(averageCaloriesLogged))/\(Int(calorieTarget)) kcal target
        - Habit completion: \(Int(habitsCompletedPercent * 100))%
        """
    }
}

// MARK: - AI Service
@MainActor
final class AIService: ObservableObject {
    @Published var isLoading = false
    @Published var lastError: String?
    @Published var lastResponse: String?

    // MARK: - Public entry point
    func getFeedback(
        provider: AIProvider,
        apiKey: String,
        context: AIFitnessContext,
        userMessage: String = ""
    ) async -> String? {
        guard provider != .none, !apiKey.trimmingCharacters(in: .whitespaces).isEmpty else {
            lastError = "No AI provider configured. Add an API key in Settings."
            return nil
        }

        isLoading = true
        lastError = nil
        defer { isLoading = false }

        let systemPrompt = """
        You are a supportive fitness coach helping someone reach their weight loss and training goals. \
        Be concise, practical, and encouraging. Avoid generic advice — ground everything in the user's actual data. \
        Keep responses under 200 words unless asked for a detailed plan.
        """

        let userPrompt: String
        if userMessage.isEmpty {
            userPrompt = """
            \(context.summaryText)

            Give me a brief weekly check-in: highlight what went well, one thing to improve, \
            and a specific action tip for the coming week.
            """
        } else {
            userPrompt = "\(context.summaryText)\n\nUser question: \(userMessage)"
        }

        switch provider {
        case .gemini:
            return await callGemini(apiKey: apiKey, systemPrompt: systemPrompt, userPrompt: userPrompt)
        case .claude:
            return await callClaude(apiKey: apiKey, systemPrompt: systemPrompt, userPrompt: userPrompt)
        case .none:
            return nil
        }
    }

    // MARK: - Gemini
    private func callGemini(apiKey: String, systemPrompt: String, userPrompt: String) async -> String? {
        let urlString = "https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=\(apiKey)"
        guard let url = URL(string: urlString) else {
            lastError = "Invalid Gemini endpoint."
            return nil
        }

        let body: [String: Any] = [
            "system_instruction": ["parts": [["text": systemPrompt]]],
            "contents": [["role": "user", "parts": [["text": userPrompt]]]],
            "generationConfig": ["maxOutputTokens": 512, "temperature": 0.7]
        ]

        return await postRequest(url: url, body: body, responseParser: { data in
            guard
                let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                let candidates = json["candidates"] as? [[String: Any]],
                let first = candidates.first,
                let content = first["content"] as? [String: Any],
                let parts = content["parts"] as? [[String: Any]],
                let text = parts.first?["text"] as? String
            else { return nil }
            return text.trimmingCharacters(in: .whitespacesAndNewlines)
        })
    }

    // MARK: - Claude
    private func callClaude(apiKey: String, systemPrompt: String, userPrompt: String) async -> String? {
        guard let url = URL(string: "https://api.anthropic.com/v1/messages") else {
            lastError = "Invalid Claude endpoint."
            return nil
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")

        let body: [String: Any] = [
            "model": "claude-3-haiku-20240307",
            "max_tokens": 512,
            "system": systemPrompt,
            "messages": [["role": "user", "content": userPrompt]]
        ]

        return await postRequest(url: url, customRequest: request, body: body, responseParser: { data in
            guard
                let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                let content = json["content"] as? [[String: Any]],
                let first = content.first,
                let text = first["text"] as? String
            else { return nil }
            return text.trimmingCharacters(in: .whitespacesAndNewlines)
        })
    }

    // MARK: - Shared POST helper
    private func postRequest(
        url: URL,
        customRequest: URLRequest? = nil,
        body: [String: Any],
        responseParser: @escaping (Data) -> String?
    ) async -> String? {
        var request = customRequest ?? URLRequest(url: url)
        if customRequest == nil {
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }

        guard let bodyData = try? JSONSerialization.data(withJSONObject: body) else {
            lastError = "Failed to encode request."
            return nil
        }
        request.httpBody = bodyData

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse else {
                lastError = "Invalid server response."
                return nil
            }
            guard httpResponse.statusCode == 200 else {
                let msg = String(data: data, encoding: .utf8) ?? "Unknown error"
                lastError = "API error \(httpResponse.statusCode): \(msg.prefix(200))"
                return nil
            }
            guard let text = responseParser(data) else {
                lastError = "Could not parse response."
                return nil
            }
            lastResponse = text
            return text
        } catch {
            lastError = error.localizedDescription
            return nil
        }
    }
}
