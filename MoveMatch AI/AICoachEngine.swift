import Combine
import Foundation

enum AICoachMetricSeverity: String, Decodable {
    case warning
    case info
    case success
}

struct AICoachBiomechanicalMetric {
    let label: String
    let value: String
    let tip: String
    let type: AICoachMetricSeverity
}

struct AICoachRadarMetric {
    let subject: String
    let score: Int
}

struct AICoachProSimilarity {
    let playerName: String
    let percentage: Int
    let description: String
}

struct AICoachPrescription {
    let focusArea: String
    let drillName: String
    let drillDescription: String
    let targetValue: Int
}

/// Normalized 0...1 full-court coordinates for heatmap; `player` 1 = green, 2 = red in UI.
struct CoachShotPlacement: Hashable {
    let x: Double
    let y: Double
    let player: Int
}

/// Raw response returned by the Node.js vision-analysis backend.
struct VideoAnalysisResponse: Decodable {
    let score: Int
    let level: String
    let ntrpEquivalent: String
    let summary: String
    let strengths: [String]
    let issues: [String]
    let suggestions: [String]
    let training_plan: [String]
    let shotPlacements: [CoachShotPlacement]
    let depthControlLine: String

    fileprivate struct ShotPlacementDTO: Decodable {
        let x: Double
        let y: Double
        let player: Int
    }

    private enum CodingKeys: String, CodingKey {
        case score
        case level
        case ntrpEquivalent
        case summary
        case strengths
        case issues
        case suggestions
        case training_plan
        case shotPlacements
        case shot_placements
        case depthControlLine
        case depth_control_line
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        score = try container.decodeIfPresent(Int.self, forKey: .score) ?? 0
        level = try container.decodeIfPresent(String.self, forKey: .level) ?? ""
        ntrpEquivalent = try container.decodeIfPresent(String.self, forKey: .ntrpEquivalent) ?? ""
        summary = try container.decodeIfPresent(String.self, forKey: .summary) ?? ""
        strengths = Self.decodeFlexibleStringArray(from: container, key: .strengths)
        issues = Self.decodeFlexibleStringArray(from: container, key: .issues)
        suggestions = Self.decodeFlexibleStringArray(from: container, key: .suggestions)
        training_plan = Self.decodeFlexibleStringArray(from: container, key: .training_plan)
        let rawPlacements: [ShotPlacementDTO]
        if let raw = try? container.decode([ShotPlacementDTO].self, forKey: .shotPlacements) {
            rawPlacements = raw
        } else if let raw = try? container.decode([ShotPlacementDTO].self, forKey: .shot_placements) {
            rawPlacements = raw
        } else {
            rawPlacements = []
        }
        shotPlacements = rawPlacements.map { dto in
            CoachShotPlacement(
                x: min(1, max(0, dto.x)),
                y: min(1, max(0, dto.y)),
                player: dto.player == 2 ? 2 : 1
            )
        }
        if let d = try? container.decodeIfPresent(String.self, forKey: .depthControlLine) {
            depthControlLine = d
        } else {
            depthControlLine = (try? container.decodeIfPresent(String.self, forKey: .depth_control_line)) ?? ""
        }
    }

    private static func decodeFlexibleStringArray(
        from container: KeyedDecodingContainer<CodingKeys>,
        key: CodingKeys
    ) -> [String] {
        if let values = try? container.decode([String].self, forKey: key) {
            return values
        }

        if let objects = try? container.decode([FlexibleTextObject].self, forKey: key) {
            return objects.compactMap(\.displayText)
        }

        return []
    }
}

private struct FlexibleTextObject: Decodable {
    let text: String?
    let summary: String?
    let description: String?
    let suggestion: String?
    let issue: String?
    let goal: String?
    let drill: String?
    let focus: String?
    let title: String?
    let phase: String?

    var displayText: String? {
        let preferred = [text, summary, description, suggestion, issue, goal, drill, focus, title]
            .compactMap { $0?.trimmingCharacters(in: .whitespacesAndNewlines) }
            .first(where: { !$0.isEmpty })

        if let preferred {
            return preferred
        }

        let composite = [phase, goal, drill]
            .compactMap { $0?.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .joined(separator: ": ")

        return composite.isEmpty ? nil : composite
    }
}

struct AICoachAnalysis {
    let score: Int
    let level: String
    /// NTRP-style label from the backend (e.g. "NTRP 3.5"). Empty for non-tennis or unavailable.
    let ntrpEquivalent: String
    let summary: String
    let scoreLabel: String
    let issues: [String]
    let suggestions: [String]
    let trainingPlan: [String]
    let biomechanics: [AICoachBiomechanicalMetric]
    let radarData: [AICoachRadarMetric]
    let proSimilarity: AICoachProSimilarity
    let prescription: AICoachPrescription
    let strengths: [String]
    let improvements: [String]
    let actionItems: [String]
    let drills: [String]
    let shotPlacements: [CoachShotPlacement]
    let depthControlLine: String
}

struct CoachAthleteBodyProfile {
    let heightCm: String
    let weightKg: String
    let chestCm: String
    let waistCm: String
    let hipCm: String
    let armSpanCm: String

    var hasAnyData: Bool {
        [heightCm, weightKg, chestCm, waistCm, hipCm, armSpanCm]
            .contains { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
    }
}

enum AICoachPhase {
    case idle
    case working
    case completed
    case failed
}

@MainActor
final class AICoachViewModel: ObservableObject {
    static let supportedSports = ["Tennis", "Basketball", "Running", "Swimming", "Golf", "Soccer"]
    static let backendModelName = "glm-4.6v"
    static let localAnalyzeEndpoint = "http://127.0.0.1:3001/api/analyze"
    /// Production HTTPS endpoint from `Info-ATS.plist` key `AICoachCloudEndpoint`.
    /// On physical devices this URL is applied automatically so users never need to configure it.
    static var cloudAnalyzeEndpoint: String? {
        guard let raw = Bundle.main.object(forInfoDictionaryKey: "AICoachCloudEndpoint") as? String else {
            return nil
        }
        let cleaned = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        return cleaned.isEmpty ? nil : cleaned
    }

    @Published var selectedSport = "Tennis"
    @Published var selectedVideoName: String?
    @Published var phase: AICoachPhase = .idle
    @Published var progress: Double = 0
    @Published var statusMessage = ""
    @Published var latestAnalysis: AICoachAnalysis?
    @Published var failureReason: String?
    @Published var backendConfigured = false

    @Published var endpoint: String
    @Published var modelIdentifier: String

    private var selectedVideoData: Data?
    private let service = InternalAICoachService()

    init() {
        if UserDefaults.standard.string(forKey: StorageKeys.modelIdentifier) == nil {
            UserDefaults.standard.set(Self.backendModelName, forKey: StorageKeys.modelIdentifier)
        }
        modelIdentifier = UserDefaults.standard.string(forKey: StorageKeys.modelIdentifier) ?? Self.backendModelName

        let raw = UserDefaults.standard.string(forKey: StorageKeys.endpoint)?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

        #if !targetEnvironment(simulator)
        // Physical devices: always use the bundled public HTTPS URL from Info.plist when present,
        // so AI Coach works on cellular or any Wi‑Fi without manual configuration.
        if let cloud = Self.cloudAnalyzeEndpoint {
            endpoint = cloud
            UserDefaults.standard.set(cloud, forKey: StorageKeys.endpoint)
        } else if !raw.isEmpty {
            endpoint = raw
        } else {
            endpoint = ""
        }
        #else
        // Simulator: prefer a saved value (e.g. localhost for local backend), else cloud from plist, else local default.
        if !raw.isEmpty {
            endpoint = raw
        } else if let cloud = Self.cloudAnalyzeEndpoint {
            endpoint = cloud
            UserDefaults.standard.set(cloud, forKey: StorageKeys.endpoint)
        } else {
            endpoint = Self.localAnalyzeEndpoint
        }
        #endif

        backendConfigured = !endpoint
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .isEmpty
    }

    var isWorking: Bool {
        phase == .working
    }

    var canStartAnalysis: Bool {
        backendConfigured && selectedVideoData != nil && !endpoint.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !isWorking
    }

    var endpointDisplay: String {
        let trimmed = endpoint.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? "Not configured" : trimmed
    }

    func saveConfiguration(endpoint: String) throws {
        let cleanedEndpoint = endpoint.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !cleanedEndpoint.isEmpty, let parsedURL = URL(string: cleanedEndpoint) else {
            throw AICoachConfigurationError.invalidEndpoint
        }

        #if !targetEnvironment(simulator)
        guard parsedURL.scheme?.lowercased() == "https" else {
            throw AICoachConfigurationError.httpsRequiredOnDevice
        }

        if Self.isLikelyLocalEndpoint(cleanedEndpoint) {
            throw AICoachConfigurationError.publicEndpointRequiredOnDevice
        }
        #endif

        UserDefaults.standard.set(cleanedEndpoint, forKey: StorageKeys.endpoint)
        UserDefaults.standard.set(Self.backendModelName, forKey: StorageKeys.modelIdentifier)

        self.endpoint = cleanedEndpoint
        self.modelIdentifier = Self.backendModelName
        backendConfigured = true
    }

    func setVideo(data: Data, fileName: String) {
        selectedVideoData = data
        selectedVideoName = fileName
        latestAnalysis = nil
        failureReason = nil
        phase = .idle
        progress = 0
        statusMessage = "Video ready for upload."
    }

    func clearVideo() {
        selectedVideoData = nil
        selectedVideoName = nil
        latestAnalysis = nil
        failureReason = nil
        phase = .idle
        progress = 0
        statusMessage = ""
    }

    func registerImportFailure(message: String) {
        phase = .failed
        failureReason = "Video import failed: \(message)"
        statusMessage = ""
    }

    func analyzeSelectedVideo() async {
        guard let videoData = selectedVideoData, let videoName = selectedVideoName else {
            phase = .failed
            failureReason = "Please select a sports video first."
            return
        }

        guard let url = URL(string: endpoint), !endpoint.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            phase = .failed
            failureReason = "No backend URL found. Open AI Settings first."
            return
        }

        phase = .working
        failureReason = nil
        latestAnalysis = nil

        do {
            try await advance(to: 0.20, message: "Uploading video to AI analysis service...")
            try await advance(to: 0.50, message: "Preparing video frames for motion review...")
            try await advance(to: 0.78, message: "Generating structured tennis coaching feedback...")

            let analysis = try await service.analyzeVideo(
                data: videoData,
                fileName: videoName,
                sport: selectedSport,
                endpoint: url,
                modelIdentifier: modelIdentifier,
                bodyProfile: Self.loadBodyProfile()
            )

            progress = 1
            statusMessage = "Analysis completed."
            latestAnalysis = analysis
            phase = .completed
        } catch {
            phase = .failed
            failureReason = Self.diagnoseAnalysisFailure(error, endpoint: endpoint)
            statusMessage = ""
        }
    }

    private static func diagnoseAnalysisFailure(_ error: Error, endpoint: String) -> String {
        #if !targetEnvironment(simulator)
        let host = endpoint.lowercased()
        if host.contains("127.0.0.1") || host.contains("localhost") {
            return "This URL points at the phone itself, not your backend. Open AI Settings and set a public HTTPS endpoint (recommended), for example https://<your-render-service>/api/analyze. For local testing only, use your Mac LAN IP while both devices are on the same Wi-Fi."
        }
        #endif
        if let urlError = error as? URLError {
            switch urlError.code {
            case .cannotConnectToHost, .cannotFindHost, .timedOut, .networkConnectionLost, .notConnectedToInternet, .secureConnectionFailed:
                return "Could not reach the server. For cross-Wi-Fi usage, configure a public HTTPS backend URL (for example Render) in AI Settings: https://<your-render-service>/api/analyze. If you're using a local Mac backend, phone and Mac must be on the same Wi-Fi and 127.0.0.1 cannot be used on a real iPhone."
            default:
                break
            }
        }
        return error.localizedDescription
    }

    private func advance(to value: Double, message: String) async throws {
        statusMessage = message
        progress = value
        try await Task.sleep(for: .milliseconds(450))
    }

    private static func isLikelyLocalEndpoint(_ endpoint: String) -> Bool {
        let host = endpoint.lowercased()
        if host.contains("127.0.0.1") || host.contains("localhost") {
            return true
        }
        return host.contains("://192.168.") || host.contains("://10.") || host.contains("://172.")
    }

    private static func loadBodyProfile() -> CoachAthleteBodyProfile {
        let defaults = UserDefaults.standard
        return CoachAthleteBodyProfile(
            heightCm: defaults.string(forKey: StorageKeys.bodyHeightCm) ?? "",
            weightKg: defaults.string(forKey: StorageKeys.bodyWeightKg) ?? "",
            chestCm: defaults.string(forKey: StorageKeys.bodyChestCm) ?? "",
            waistCm: defaults.string(forKey: StorageKeys.bodyWaistCm) ?? "",
            hipCm: defaults.string(forKey: StorageKeys.bodyHipCm) ?? "",
            armSpanCm: defaults.string(forKey: StorageKeys.bodyArmSpanCm) ?? ""
        )
    }
}

private enum StorageKeys {
    static let endpoint = "movematch.ai-endpoint"
    static let modelIdentifier = "movematch.ai-model"
    static let bodyHeightCm = "movematch.profile.body.height_cm"
    static let bodyWeightKg = "movematch.profile.body.weight_kg"
    static let bodyChestCm = "movematch.profile.body.chest_cm"
    static let bodyWaistCm = "movematch.profile.body.waist_cm"
    static let bodyHipCm = "movematch.profile.body.hip_cm"
    static let bodyArmSpanCm = "movematch.profile.body.arm_span_cm"
}

private enum AICoachConfigurationError: LocalizedError {
    case invalidEndpoint
    case httpsRequiredOnDevice
    case publicEndpointRequiredOnDevice

    var errorDescription: String? {
        switch self {
        case .invalidEndpoint:
            return "Please provide a valid backend URL."
        case .httpsRequiredOnDevice:
            return "On a physical iPhone, use an HTTPS endpoint (for example: https://<your-service>.onrender.com/api/analyze)."
        case .publicEndpointRequiredOnDevice:
            return "On a physical iPhone, use a public HTTPS endpoint. Localhost / LAN IP works only when phone and Mac are on the same Wi-Fi."
        }
    }
}

private struct InternalAICoachService {
    func analyzeVideo(
        data: Data,
        fileName: String,
        sport: String,
        endpoint: URL,
        modelIdentifier: String,
        bodyProfile: CoachAthleteBodyProfile
    ) async throws -> AICoachAnalysis {
        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.timeoutInterval = 180

        let boundary = "Boundary-\(UUID().uuidString)"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        request.httpBody = buildMultipartBody(
            boundary: boundary,
            sport: sport,
            modelIdentifier: modelIdentifier,
            bodyProfile: bodyProfile,
            data: data,
            fileName: fileName
        )

        let (responseData, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }

        guard (200 ..< 300).contains(httpResponse.statusCode) else {
            let body = String(decoding: responseData, as: UTF8.self)
            throw InternalAICoachServiceError.serverError(code: httpResponse.statusCode, body: body)
        }

        if let payload = try? JSONDecoder().decode(VideoAnalysisResponse.self, from: responseData) {
            let normalizedLevel: String
            if sport == "Tennis" {
                let trimmed = payload.level.trimmingCharacters(in: .whitespacesAndNewlines)
                // Node backend returns fixed-band labels; prefer that over a local score→tier map.
                normalizedLevel = trimmed.isEmpty ? tennisTierLabel(for: payload.score) : trimmed
            } else {
                normalizedLevel = payload.level.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? skillLabel(for: payload.score) : payload.level
            }
            let ntrpLine: String
            if sport == "Tennis" {
                let raw = payload.ntrpEquivalent.trimmingCharacters(in: .whitespacesAndNewlines)
                if raw.isEmpty || raw.uppercased() == "N/A" {
                    ntrpLine = tennisNtrpEquivalentFromScore(payload.score)
                } else {
                    ntrpLine = raw
                }
            } else {
                ntrpLine = ""
            }
            let issues = payload.issues.isEmpty ? ["Needs earlier preparation before contact."] : payload.issues
            let strengths = payload.strengths.isEmpty ? ["Shows a stable athletic base during the visible sequence."] : payload.strengths
            let suggestions = payload.suggestions.isEmpty ? ["Use side-view recordings to refine timing and spacing feedback."] : payload.suggestions
            let trainingPlan = payload.training_plan.isEmpty ? ["Repeat 20 shadow swings focused on early unit turn."] : payload.training_plan

            let derivedBiomechanics = deriveBiomechanics(issues: issues, suggestions: suggestions)
            let derivedRadar = deriveRadar(score: payload.score, sport: sport)
            let derivedProSimilarity = deriveProSimilarity(score: payload.score, sport: sport, level: normalizedLevel)
            let derivedPrescription = derivePrescription(trainingPlan: trainingPlan, suggestions: suggestions)

            let heatmap: [CoachShotPlacement]
            let depthLine: String
            if sport == "Tennis" {
                heatmap = payload.shotPlacements
                depthLine = payload.depthControlLine.trimmingCharacters(in: .whitespacesAndNewlines)
            } else {
                heatmap = []
                depthLine = ""
            }

            return AICoachAnalysis(
                score: payload.score,
                level: normalizedLevel,
                ntrpEquivalent: ntrpLine,
                summary: payload.summary,
                scoreLabel: normalizedLevel,
                issues: issues,
                suggestions: suggestions,
                trainingPlan: trainingPlan,
                biomechanics: derivedBiomechanics,
                radarData: derivedRadar,
                proSimilarity: derivedProSimilarity,
                prescription: derivedPrescription,
                strengths: strengths,
                improvements: issues,
                actionItems: suggestions,
                drills: trainingPlan,
                shotPlacements: heatmap,
                depthControlLine: depthLine
            )
        }

        let rawText = String(decoding: responseData, as: UTF8.self)
        return AICoachAnalysis(
            score: 75,
            level: sport == "Tennis" ? tennisTierLabel(for: 75) : "Developing Amateur",
            ntrpEquivalent: sport == "Tennis" ? tennisNtrpEquivalentFromScore(75) : "",
            summary: rawText.isEmpty ? "The API call succeeded, but the response format was not recognized." : rawText,
            scoreLabel: sport == "Tennis" ? tennisTierLabel(for: 75) : "Developing Amateur",
            issues: ["The backend response could not be parsed into the expected analysis format."],
            suggestions: ["Check the Node.js backend response shape and try the upload again."],
            trainingPlan: ["Verify that /api/analyze returns valid JSON before re-running the analysis."],
            biomechanics: deriveBiomechanics(
                issues: ["The backend response could not be parsed into the expected analysis format."],
                suggestions: ["Check the Node.js backend response shape and try the upload again."]
            ),
            radarData: deriveRadar(score: 75, sport: sport),
            proSimilarity: deriveProSimilarity(score: 75, sport: sport, level: sport == "Tennis" ? tennisTierLabel(for: 75) : "Developing Amateur"),
            prescription: derivePrescription(
                trainingPlan: ["Verify that /api/analyze returns valid JSON before re-running the analysis."],
                suggestions: ["Check the Node.js backend response shape and try the upload again."]
            ),
            strengths: ["Upload and authentication both succeeded."],
            improvements: ["Return JSON with score, level, summary, strengths, issues, suggestions, and training_plan."],
            actionItems: ["Check the Node.js backend response shape and try the upload again."],
            drills: ["Verify that /api/analyze returns valid JSON before re-running the analysis."],
            shotPlacements: [],
            depthControlLine: ""
        )
    }

    private func skillLabel(for score: Int) -> String {
        switch score {
        case 90...100: return "Advanced Competitive Player"
        case 80...89: return "Developing Amateur"
        case 65...79: return "Emerging Recreational Player"
        default: return "Early Stage Learner"
        }
    }

    /// NTRP text bands; must match `ntrpEquivalent` in `TENNIS_SCORE_BANDS` (backend `server.js`).
    private func tennisNtrpEquivalentFromScore(_ score: Int) -> String {
        let s = max(0, min(100, score))
        switch s {
        case 0 ... 20: return "NTRP 1.0–1.5"
        case 21 ... 35: return "NTRP 2.0"
        case 36 ... 50: return "NTRP 2.5"
        case 51 ... 65: return "NTRP 3.0"
        case 66 ... 75: return "NTRP 3.5"
        case 76 ... 84: return "NTRP 4.0"
        case 85 ... 91: return "NTRP 4.5–5.0"
        case 92 ... 96: return "NTRP 5.5–6.0"
        case 97 ... 100: return "NTRP 6.5–7.0"
        default: return "NTRP 1.0–1.5"
        }
    }

    /// Fallback tier labels; must match backend `TENNIS_SCORE_BANDS` in `backend-node/server.js`.
    private func tennisTierLabel(for score: Int) -> String {
        let s = max(0, min(100, score))
        switch s {
        case 0 ... 20: return "Complete Beginner"
        case 21 ... 35: return "Beginner"
        case 36 ... 50: return "Developing Amateur"
        case 51 ... 65: return "Intermediate Recreational"
        case 66 ... 75: return "Strong Club Player"
        case 76 ... 84: return "Advanced Club Player"
        case 85 ... 91: return "Competitive Advanced"
        case 92 ... 96: return "Elite"
        case 97 ... 100: return "Professional"
        default: return "Complete Beginner"
        }
    }

    /// Converts the backend's issues + suggestions into the existing card format
    /// so we can reuse the current SwiftUI result screens with minimal changes.
    private func deriveBiomechanics(issues: [String], suggestions: [String]) -> [AICoachBiomechanicalMetric] {
        let issueMetrics = issues.prefix(2).map {
            AICoachBiomechanicalMetric(
                label: "Issue",
                value: "Needs Attention",
                tip: $0,
                type: .warning
            )
        }
        let suggestionMetrics = suggestions.prefix(2).map {
            AICoachBiomechanicalMetric(
                label: "Suggestion",
                value: "Next Step",
                tip: $0,
                type: .info
            )
        }
        let merged = Array(issueMetrics + suggestionMetrics)
        if merged.isEmpty {
            return [
                AICoachBiomechanicalMetric(
                    label: "Review",
                    value: "Pending",
                    tip: "Upload another clip so the AI can generate actionable video feedback.",
                    type: .info
                )
            ]
        }
        return merged
    }

    /// The current UI already has a radar card, so we derive a lightweight
    /// five-axis distribution from the returned score rather than introducing
    /// a new chart system.
    private func deriveRadar(score: Int, sport: String) -> [AICoachRadarMetric] {
        let capped = max(40, min(score, 98))
        return [
            AICoachRadarMetric(subject: "Power", score: capped),
            AICoachRadarMetric(subject: "Consistency", score: max(35, capped - 4)),
            AICoachRadarMetric(subject: sport == "Tennis" ? "Timing" : "Technique", score: max(30, capped - 7)),
            AICoachRadarMetric(subject: "Recovery", score: max(32, capped - 3)),
            AICoachRadarMetric(subject: "Footwork", score: max(28, capped - 6)),
        ]
    }

    private func deriveProSimilarity(score: Int, sport: String, level: String) -> AICoachProSimilarity {
        let playerName: String
        switch sport {
        case "Tennis":
            playerName = score >= 80 ? "Jannik Sinner" : "Taylor Fritz"
        case "Basketball":
            playerName = "Klay Thompson"
        case "Golf":
            playerName = "Rory McIlroy"
        default:
            playerName = "Elite Athlete Reference"
        }

        return AICoachProSimilarity(
            playerName: playerName,
            percentage: max(45, min(score - 8, 92)),
            description: "This similarity estimate is a style reference derived from the returned level (\(level)) and overall movement score."
        )
    }

    private func derivePrescription(trainingPlan: [String], suggestions: [String]) -> AICoachPrescription {
        let planItem = trainingPlan.first ?? "Repeat 20 shadow reps focused on cleaner preparation and recovery."
        let suggestion = suggestions.first ?? "Film another side-view clip after the next session."
        return AICoachPrescription(
            focusArea: suggestion,
            drillName: "Next Training Block",
            drillDescription: planItem,
            targetValue: 20
        )
    }

    private func buildMultipartBody(
        boundary: String,
        sport: String,
        modelIdentifier: String,
        bodyProfile: CoachAthleteBodyProfile,
        data: Data,
        fileName: String
    ) -> Data {
        var body = Data()

        appendField("sport", value: sport, to: &body, boundary: boundary)
        appendField("model", value: modelIdentifier, to: &body, boundary: boundary)
        appendOptionalField("height_cm", value: bodyProfile.heightCm, to: &body, boundary: boundary)
        appendOptionalField("weight_kg", value: bodyProfile.weightKg, to: &body, boundary: boundary)
        appendOptionalField("chest_cm", value: bodyProfile.chestCm, to: &body, boundary: boundary)
        appendOptionalField("waist_cm", value: bodyProfile.waistCm, to: &body, boundary: boundary)
        appendOptionalField("hip_cm", value: bodyProfile.hipCm, to: &body, boundary: boundary)
        appendOptionalField("arm_span_cm", value: bodyProfile.armSpanCm, to: &body, boundary: boundary)

        body.append("--\(boundary)\r\n".data(using: .utf8) ?? Data())
        let mimeType = fileName.lowercased().hasSuffix(".mp4") ? "video/mp4" : "video/quicktime"
        body.append("Content-Disposition: form-data; name=\"video\"; filename=\"\(fileName)\"\r\n".data(using: .utf8) ?? Data())
        body.append("Content-Type: \(mimeType)\r\n\r\n".data(using: .utf8) ?? Data())
        body.append(data)
        body.append("\r\n".data(using: .utf8) ?? Data())
        body.append("--\(boundary)--\r\n".data(using: .utf8) ?? Data())

        return body
    }

    private func appendField(_ name: String, value: String, to body: inout Data, boundary: String) {
        body.append("--\(boundary)\r\n".data(using: .utf8) ?? Data())
        body.append("Content-Disposition: form-data; name=\"\(name)\"\r\n\r\n".data(using: .utf8) ?? Data())
        body.append("\(value)\r\n".data(using: .utf8) ?? Data())
    }

    private func appendOptionalField(_ name: String, value: String, to body: inout Data, boundary: String) {
        let cleaned = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleaned.isEmpty else { return }
        appendField(name, value: cleaned, to: &body, boundary: boundary)
    }
}

private enum InternalAICoachServiceError: LocalizedError {
    case serverError(code: Int, body: String)

    var errorDescription: String? {
        switch self {
        case let .serverError(code, body):
            if body.isEmpty {
                return "The internal AI endpoint returned HTTP \(code)."
            }
            let cleaned = cleanedMessage(from: body)
            if cleaned.isEmpty {
                return "The internal AI endpoint returned HTTP \(code)."
            }
            return cleaned
        }
    }

    private func cleanedMessage(from body: String) -> String {
        if let data = body.data(using: .utf8),
           let payload = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
        {
            if let message = payload["message"] as? String {
                return simplify(message)
            }
            if let detail = payload["detail"] as? String {
                return simplify(detail)
            }
        }

        return simplify(body)
    }

    private func simplify(_ message: String) -> String {
        let normalized = message.lowercased()

        if normalized.contains("openai api key") || normalized.contains("incorrect api key") || normalized.contains("invalid_api_key") {
            return "The configured API key is invalid. Update AI_API_KEY in backend-node/.env, restart the Node backend, and try again."
        }

        if normalized.contains("permission") && normalized.contains("api") {
            return "The provider rejected the request. Check that your backend API key can access the selected model."
        }

        return message
    }
}
