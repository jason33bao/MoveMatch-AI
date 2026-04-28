import PhotosUI
import SwiftUI
import UniformTypeIdentifiers

private enum AppTab: Hashable {
    case discover
    case coaches
    case compete
    case community
    case profile

    var title: String {
        switch self {
        case .discover:
            return "Discover"
        case .coaches:
            return "Coaches"
        case .compete:
            return "Compete"
        case .community:
            return "Community"
        case .profile:
            return "Profile"
        }
    }

    var systemImage: String {
        switch self {
        case .discover:
            return "magnifyingglass"
        case .coaches:
            return "person.3.fill"
        case .compete:
            return "trophy.fill"
        case .community:
            return "message.fill"
        case .profile:
            return "person.crop.circle"
        }
    }
}

enum MoveMatchPalette {
    static let primary = Color(red: 0 / 255, green: 210 / 255, blue: 106 / 255)
    static let primaryDark = Color(red: 0 / 255, green: 168 / 255, blue: 85 / 255)
    static let background = Color(red: 246 / 255, green: 248 / 255, blue: 251 / 255)
    static let card = Color.white
    /// App-wide secondary text on light backgrounds (darker than system `Color.secondary` for legibility).
    static let textSecondary = Color(red: 58 / 255, green: 66 / 255, blue: 82 / 255)
    /// Main titles and primary body on white / light cards.
    static let textOnCard = Color(red: 28 / 255, green: 34 / 255, blue: 44 / 255)
    /// Sublabels, captions, and placeholders.
    static let textOnCardMuted = Color(red: 72 / 255, green: 80 / 255, blue: 96 / 255)
    /// Inactive items on the custom tab bar: darker than `textOnCard` so long labels (Community / Profile) read clearly on `ultraThinMaterial`.
    static let tabBarLabelInactive = Color(red: 10 / 255, green: 14 / 255, blue: 20 / 255)
    /// Extra scroll length so the last content clears the custom tab bar and home indicator.
    static let tabBarScrollBottomPadding: CGFloat = 64
}

struct ContentView: View {
    @State private var selectedTab: AppTab = .discover
    @StateObject private var coachViewModel = AICoachViewModel()

    var body: some View {
        currentTabView
            .safeAreaInset(edge: .bottom) {
                MoveMatchTabBar(selectedTab: $selectedTab)
            }
        .tint(MoveMatchPalette.primary)
    }

    @ViewBuilder
    private var currentTabView: some View {
        switch selectedTab {
        case .discover:
            NavigationStack {
                EnhancedDiscoverView()
            }
        case .coaches:
            NavigationStack {
                CoachHubView(viewModel: coachViewModel, selectedTab: $selectedTab)
            }
        case .compete:
            NavigationStack {
                EnhancedCompeteView()
            }
        case .community:
            NavigationStack {
                EnhancedCommunityView()
            }
        case .profile:
            NavigationStack {
                EnhancedProfileView()
            }
        }
    }
}

private struct MoveMatchTabBar: View {
    @Binding var selectedTab: AppTab

    private let tabs: [AppTab] = [.discover, .coaches, .compete, .community, .profile]

    var body: some View {
        VStack(spacing: 0) {
            Divider()
                .opacity(0.08)

            HStack(spacing: 4) {
                ForEach(tabs, id: \.self) { tab in
                    Button {
                        selectedTab = tab
                    } label: {
                        VStack(spacing: 6) {
                            Image(systemName: tab.systemImage)
                                .font(.system(size: 18, weight: .semibold))
                            Text(tab.title)
                                .font(.system(size: 11, weight: .semibold))
                                .lineLimit(1)
                                .minimumScaleFactor(0.82)
                        }
                        .foregroundStyle(selectedTab == tab ? MoveMatchPalette.primary : MoveMatchPalette.tabBarLabelInactive)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 7)
                        .background(
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .fill(selectedTab == tab ? MoveMatchPalette.primary.opacity(0.14) : Color.clear)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 12)
            .padding(.top, 1)
            .padding(.bottom, 1)
            .background(.ultraThinMaterial)
        }
    }
}

private struct DiscoverView: View {
    private let activities = [
        ("3v3 Pickup Game", "Intermediate", "Today 4:00 PM"),
        ("Singles Practice", "Advanced", "Tomorrow 9:00 AM"),
        ("Sunrise Yoga", "Beginner", "Sat 7:00 AM")
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                searchHeader("Discover Activities", subtitle: "Search, filter, and join sports near you.")

                ForEach(activities, id: \.0) { activity in
                    feedCard(
                        title: activity.0,
                        subtitle: activity.2,
                        detail: activity.1,
                        icon: "magnifyingglass.circle.fill",
                        color: .blue
                    )
                }
            }
            .padding(20)
        }
        .background(MoveMatchPalette.background.ignoresSafeArea())
        .navigationTitle("Discover")
    }
}

private struct CoachesView: View {
    private let coaches = [
        ("Marcus Chen", "Professional Tennis Coach", "$85 / session"),
        ("Sarah Williams", "Yoga & Fitness Coach", "$65 / session"),
        ("Lisa Tanaka", "Swimming Coach", "$55 / session")
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                searchHeader("Coaching Marketplace", subtitle: "Browse AI-verified and certified sports coaches.")

                ForEach(coaches, id: \.0) { coach in
                    feedCard(
                        title: coach.0,
                        subtitle: coach.1,
                        detail: coach.2,
                        icon: "person.crop.rectangle.stack.fill",
                        color: .indigo
                    )
                }
            }
            .padding(20)
        }
        .background(MoveMatchPalette.background.ignoresSafeArea())
        .navigationTitle("Coaches")
    }
}

private struct CompeteView: View {
    private let events = [
        ("City Tennis Open 2026", "Registration open", "Prize pool $2,500"),
        ("30-Day Sprint Challenge", "8 days left", "Leaderboard live"),
        ("Basketball 3x3 Open", "Team event", "Winner trophies")
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                searchHeader("Compete", subtitle: "Tournaments, challenges, and leaderboards in one place.")

                ForEach(events, id: \.0) { event in
                    feedCard(
                        title: event.0,
                        subtitle: event.1,
                        detail: event.2,
                        icon: "trophy.circle.fill",
                        color: .orange
                    )
                }
            }
            .padding(20)
        }
        .background(MoveMatchPalette.background.ignoresSafeArea())
        .navigationTitle("Compete")
    }
}

private struct CommunityView: View {
    private let posts = [
        ("Training/Skills", "Great forehand session today. My contact point is finally more stable."),
        ("Diet & Nutrition", "Meal prep Sunday is the real performance hack."),
        ("Lifestyle", "Sleep quality improved my recovery more than any supplement.")
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                searchHeader("Community", subtitle: "Content sharing, social motivation, and challenge discovery.")

                ForEach(posts, id: \.0) { post in
                    feedCard(
                        title: post.0,
                        subtitle: post.1,
                        detail: "For You feed",
                        icon: "bubble.left.and.exclamationmark.bubble.right.fill",
                        color: .pink
                    )
                }
            }
            .padding(20)
        }
        .background(MoveMatchPalette.background.ignoresSafeArea())
        .navigationTitle("Community")
    }
}

private struct ProfileView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                searchHeader("Profile", subtitle: "Identity, activity history, skill radar, and awards.")

                HStack(spacing: 14) {
                    Circle()
                        .fill(MoveMatchPalette.primary.opacity(0.18))
                        .frame(width: 72, height: 72)
                        .overlay(Image(systemName: "person.fill").font(.title2).foregroundStyle(MoveMatchPalette.primary))

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Alex Chen")
                            .font(.title2.bold())
                        Text("Tennis, Basketball, Running")
                            .foregroundStyle(MoveMatchPalette.textSecondary)
                        Text("AI score 847")
                            .font(.footnote.weight(.semibold))
                            .foregroundStyle(MoveMatchPalette.primaryDark)
                    }
                }
                .padding(18)
                .background(MoveMatchPalette.card)
                .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))

                feedCard(title: "Skill Progress", subtitle: "Technique, endurance, and consistency trending up.", detail: "Weekly insights", icon: "chart.xyaxis.line", color: .green)
                feedCard(title: "Recent Activities", subtitle: "Tennis practice, AI serve analysis, 5K run.", detail: "12 this month", icon: "clock.arrow.circlepath", color: .blue)
                feedCard(title: "Awards", subtitle: "4 of 8 achievements unlocked.", detail: "50% complete", icon: "medal.star.fill", color: .yellow)
            }
            .padding(20)
        }
        .background(MoveMatchPalette.background.ignoresSafeArea())
        .navigationTitle("Profile")
    }
}

private struct AICoachView: View {
    @ObservedObject var viewModel: AICoachViewModel
    @Binding var selectedTab: AppTab

    @State private var pickedVideo: PhotosPickerItem?
    @State private var showSmartwatchPrompt = false
    @State private var showImportSourcePicker = false
    @State private var showPhotoLibraryPicker = false
    @State private var showFileImporter = false
    @State private var isImportingVideo = false
    @State private var equipmentName = ""
    @State private var bodyProfileHintDismissed = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                coachHero

                if viewModel.phase == .failed, let failureReason = viewModel.failureReason {
                    statusBanner(
                        title: "Analysis failed",
                        detail: failureReason,
                        tint: .red,
                        icon: "exclamationmark.triangle.fill"
                    )
                }

                primaryCoachCard
                resultSection
                progressCard
                recentSessionsCard
                tipsCard
                upgradeCard
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)
            .padding(.bottom, 20 + MoveMatchPalette.tabBarScrollBottomPadding)
        }
        .background(MoveMatchPalette.background.ignoresSafeArea())
        .sheet(isPresented: $showSmartwatchPrompt) {
            SmartwatchPromptSheet()
        }
        .photosPicker(isPresented: $showPhotoLibraryPicker, selection: $pickedVideo, matching: .videos)
        .fileImporter(
            isPresented: $showFileImporter,
            allowedContentTypes: [.movie, .video],
            allowsMultipleSelection: false
        ) { result in
            handleFileImport(result)
        }
        .confirmationDialog(
            "Choose Import Source",
            isPresented: $showImportSourcePicker,
            titleVisibility: .visible
        ) {
            Button("Photo Library") {
                showPhotoLibraryPicker = true
            }
            Button("Files") {
                showFileImporter = true
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Select where to import your training video from.")
        }
        .task(id: pickedVideo) {
            await loadPickedVideo()
        }
        .navigationTitle("AI Coach")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                Button {
                    showSmartwatchPrompt = true
                } label: {
                    Image(systemName: "applewatch")
                }
                .accessibilityLabel("Health watch")
            }
        }
    }

    private var coachHero: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 12) {
                Circle()
                    .fill(.white.opacity(0.16))
                    .frame(width: 36, height: 36)
                    .overlay(Image(systemName: "brain.head.profile").foregroundStyle(.white))

                Text("AI-POWERED ANALYSIS")
                    .font(.footnote.weight(.bold))
                    .foregroundStyle(.white.opacity(0.92))
                    .tracking(1.2)
            }

            HStack(spacing: 10) {
                AICoachHeroMetric(title: "Analyses Done", value: "3")
                AICoachHeroMetric(title: "Avg Score", value: "\(max(viewModel.latestAnalysis?.score ?? 78, 78))")
                AICoachHeroMetric(title: "Improvement", value: "+20pts")
            }

            HStack(spacing: 6) {
                Button {
                    showSmartwatchPrompt = true
                } label: {
                    heroPill(title: "Health Data", tint: .white)
                }
                .buttonStyle(.plain)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(coachGradient)
        .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
    }

    @ViewBuilder
    private var primaryCoachCard: some View {
        switch viewModel.phase {
        case .working:
            analysisLoadingCard
        default:
            setupCard
        }
    }

    private var setupCard: some View {
        VStack(alignment: .leading, spacing: 18) {
            numberHeader(index: 1, title: "Context & Equipment")

            Text("SELECT SPORT")
                .font(.caption.weight(.bold))
                .foregroundStyle(MoveMatchPalette.textOnCard)
                .tracking(1)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(AICoachViewModel.supportedSports, id: \.self) { sport in
                        Button {
                            withAnimation(.spring(response: 0.28, dampingFraction: 0.88)) {
                                viewModel.selectedSport = sport
                            }
                        } label: {
                            Text(sport)
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(viewModel.selectedSport == sport ? MoveMatchPalette.primaryDark : MoveMatchPalette.textOnCard)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 11)
                                .background(viewModel.selectedSport == sport ? MoveMatchPalette.primary.opacity(0.12) : .white)
                                .overlay(
                                    Capsule()
                                        .stroke(viewModel.selectedSport == sport ? MoveMatchPalette.primary.opacity(0.4) : Color.gray.opacity(0.15), lineWidth: 1)
                                )
                                .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            Text("REGISTER YOUR GEAR (optional)")
                .font(.caption.weight(.bold))
                .foregroundStyle(MoveMatchPalette.textOnCard)
                .tracking(1)

            HStack(spacing: 10) {
                HStack(spacing: 10) {
                    Image(systemName: "shippingbox")
                        .foregroundStyle(MoveMatchPalette.textOnCardMuted)
                    TextField(
                        "",
                        text: $equipmentName,
                        prompt: Text(gearPlaceholder)
                            .foregroundStyle(MoveMatchPalette.textOnCardMuted)
                    )
                    .foregroundStyle(MoveMatchPalette.textOnCard)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 13)
                .background(Color(red: 0.94, green: 0.95, blue: 0.97))
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(Color.black.opacity(0.06), lineWidth: 1)
                )

                Button("Add") {
                    if equipmentName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        equipmentName = gearPlaceholder
                    }
                }
                .font(.headline.weight(.bold))
                .foregroundStyle(.white)
                .frame(width: 78, height: 54)
                .background(
                    LinearGradient(colors: [Color(red: 168 / 255, green: 236 / 255, blue: 225 / 255), MoveMatchPalette.primary], startPoint: .topLeading, endPoint: .bottomTrailing)
                )
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            }

            Divider().opacity(0.5)

            numberHeader(index: 2, title: "Upload Training Video")

            if shouldShowBodyProfileHint {
                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: "figure.strengthtraining.traditional")
                        .foregroundStyle(MoveMatchPalette.primaryDark)
                        .padding(.top, 2)
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Complete body metrics for personalized coaching")
                            .font(.subheadline.weight(.bold))
                            .foregroundStyle(MoveMatchPalette.textOnCard)
                        Text("Add height, weight, and measurements in Profile to help AI Coach tailor drills and workload suggestions.")
                            .font(.caption)
                            .foregroundStyle(MoveMatchPalette.textOnCardMuted)

                        Button("Go to Profile") {
                            selectedTab = .profile
                        }
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 7)
                        .background(MoveMatchPalette.primaryDark)
                        .clipShape(Capsule())
                        .buttonStyle(.plain)
                    }
                    Spacer()
                    Button {
                        bodyProfileHintDismissed = true
                    } label: {
                        Image(systemName: "xmark")
                            .font(.caption.bold())
                            .foregroundStyle(MoveMatchPalette.textOnCardMuted)
                    }
                    .buttonStyle(.plain)
                }
                .padding(12)
                .background(Color(red: 236 / 255, green: 251 / 255, blue: 247 / 255))
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }

            HStack(spacing: 12) {
                UploadOptionTile(
                    icon: "camera",
                    title: "In-App Camera",
                    subtitle: "AR-guided capture",
                    isSelected: false,
                    isDisabled: true
                )

                Button {
                    showImportSourcePicker = true
                } label: {
                    UploadOptionTile(
                        icon: "square.and.arrow.up",
                        title: isImportingVideo ? "Importing..." : "Local Album",
                        subtitle: "Photo Library",
                        isSelected: viewModel.selectedVideoName != nil,
                        isDisabled: false
                    )
                }
                .buttonStyle(.plain)
                .disabled(isImportingVideo)
            }

            if let fileName = viewModel.selectedVideoName {
                HStack(spacing: 12) {
                    Circle()
                        .fill(MoveMatchPalette.primary.opacity(0.14))
                        .frame(width: 40, height: 40)
                        .overlay(Image(systemName: "video.fill").foregroundStyle(MoveMatchPalette.primaryDark))

                    VStack(alignment: .leading, spacing: 3) {
                        Text(fileName)
                            .font(.subheadline.weight(.bold))
                            .foregroundStyle(MoveMatchPalette.textOnCard)
                        Text("\(viewModel.selectedSport) session ready for upload")
                            .font(.caption)
                            .foregroundStyle(MoveMatchPalette.textOnCardMuted)
                    }
                    Spacer()
                    Button("Clear") {
                        viewModel.clearVideo()
                        pickedVideo = nil
                    }
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.red)
                }
                .padding(14)
                .background(Color.gray.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            }

            if !viewModel.backendConfigured {
                #if targetEnvironment(simulator)
                statusBanner(
                    title: "Connect your backend first",
                    detail: "No AI endpoint configured. Add `AICoachCloudEndpoint` in Info-ATS.plist or set a local simulator endpoint.",
                    tint: .orange,
                    icon: "link.circle.fill"
                )
                #else
                statusBanner(
                    title: "Connect your backend first",
                    detail: "No public AI endpoint is bundled with this build. Add `AICoachCloudEndpoint` in Info-ATS.plist to your HTTPS /api/analyze URL and rebuild.",
                    tint: .orange,
                    icon: "link.circle.fill"
                )
                #endif
            }

            VStack(spacing: 10) {
                Button {
                    Task {
                        await viewModel.analyzeSelectedVideo()
                    }
                } label: {
                    HStack {
                        Image(systemName: "sparkles.rectangle.stack.fill")
                        Text("Analyze Training Video")
                        Spacer()
                        Image(systemName: "arrow.right")
                    }
                    .font(.headline.weight(.bold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 18)
                    .padding(.vertical, 15)
                    .background(viewModel.canStartAnalysis ? coachGradient : LinearGradient(colors: [Color.gray, Color.gray], startPoint: .leading, endPoint: .trailing))
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                }
                .buttonStyle(.plain)
                .disabled(!viewModel.canStartAnalysis)
            }
        }
        .padding(18)
        .background(MoveMatchPalette.card)
        .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
        .shadow(color: .black.opacity(0.04), radius: 10, y: 6)
    }

    private var analysisLoadingCard: some View {
        VStack(spacing: 18) {
            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.12), lineWidth: 10)
                    .frame(width: 98, height: 98)
                Circle()
                    .trim(from: 0, to: max(viewModel.progress, 0.08))
                    .stroke(
                        LinearGradient(colors: [MoveMatchPalette.primary, .cyan], startPoint: .topLeading, endPoint: .bottomTrailing),
                        style: StrokeStyle(lineWidth: 10, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .frame(width: 98, height: 98)
                    .animation(.easeInOut(duration: 0.45), value: viewModel.progress)
                Image(systemName: "cpu")
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundStyle(MoveMatchPalette.primaryDark)
            }
            .padding(.top, 8)

            VStack(spacing: 6) {
                Text("AI Analysing Technique...")
                    .font(.system(size: 28, weight: .bold))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(MoveMatchPalette.textOnCard)
                Text(viewModel.statusMessage.isEmpty ? "Computing swing velocity vectors..." : viewModel.statusMessage)
                    .font(.headline.weight(.semibold))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(MoveMatchPalette.primaryDark)
            }

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                ForEach(Array(analysisSteps.enumerated()), id: \.offset) { entry in
                    AnalysisStepBadge(
                        title: entry.element,
                        state: analysisState(for: entry.offset)
                    )
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(22)
        .background(MoveMatchPalette.card)
        .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
        .shadow(color: .black.opacity(0.04), radius: 10, y: 6)
    }

    @ViewBuilder
    private var resultSection: some View {
        switch viewModel.phase {
        case .idle:
            EmptyView()

        case .working:
            EmptyView()

        case .completed:
            if let analysis = viewModel.latestAnalysis {
                VStack(alignment: .leading, spacing: 14) {
                    statusBanner(
                        title: aiCoachResultHeadline(analysis),
                        detail: analysis.summary.isEmpty ? "Compared to last week, your timing and consistency both improved after this session." : analysis.summary,
                        tint: MoveMatchPalette.primaryDark,
                        icon: "chart.line.uptrend.xyaxis"
                    )

                    executiveSummaryCard(analysis)
                    feedbackCollectionsCard(analysis)
                    biomechanicalCard(analysis)
                    if viewModel.selectedSport == "Tennis" {
                        shotPlacementCard(analysis)
                    }
                    skillRadarCard(analysis)
                    comparativeBenchmarkingCard(analysis)
                    nextSessionCard(analysis)
                    actionItemsCard(analysis)
                    nearbyCoachesCard

                    Button {
                        viewModel.clearVideo()
                        pickedVideo = nil
                    } label: {
                        HStack {
                            Image(systemName: "arrow.counterclockwise")
                            Text("Analyze Another Video")
                        }
                        .font(.headline.weight(.bold))
                        .foregroundStyle(MoveMatchPalette.textOnCard)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(.white)
                        .overlay(
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .stroke(Color.gray.opacity(0.14), lineWidth: 1)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                    }
                    .buttonStyle(.plain)
                }
            }

        case .failed:
            EmptyView()
        }
    }

    private func loadPickedVideo() async {
        guard let pickedVideo else { return }

        isImportingVideo = true
        defer { isImportingVideo = false }

        do {
            if let data = try await pickedVideo.loadTransferable(type: Data.self) {
                let fileName = "\(viewModel.selectedSport.lowercased())-session.mov"
                viewModel.setVideo(data: data, fileName: fileName)
            }
        } catch {
            viewModel.registerImportFailure(message: error.localizedDescription)
        }
    }

    private func handleFileImport(_ result: Result<[URL], Error>) {
        switch result {
        case let .success(urls):
            guard let url = urls.first else { return }
            Task {
                await importVideoFile(from: url)
            }
        case let .failure(error):
            viewModel.registerImportFailure(message: error.localizedDescription)
        }
    }

    private func importVideoFile(from url: URL) async {
        isImportingVideo = true
        defer { isImportingVideo = false }

        let hasScopedAccess = url.startAccessingSecurityScopedResource()
        defer {
            if hasScopedAccess {
                url.stopAccessingSecurityScopedResource()
            }
        }

        do {
            let data = try Data(contentsOf: url)
            viewModel.setVideo(data: data, fileName: url.lastPathComponent)
            pickedVideo = nil
        } catch {
            viewModel.registerImportFailure(message: error.localizedDescription)
        }
    }

    private func numberHeader(index: Int, title: String) -> some View {
        HStack(spacing: 10) {
            Circle()
                .fill(MoveMatchPalette.primary.opacity(0.14))
                .frame(width: 24, height: 24)
                .overlay(Text("\(index)").font(.caption.weight(.bold)).foregroundStyle(MoveMatchPalette.primaryDark))
            Text(title)
                .font(.title3.weight(.bold))
                .foregroundStyle(MoveMatchPalette.textOnCard)
        }
    }

    private func heroPill(title: String, tint: Color) -> some View {
        Text(title)
            .font(.caption.weight(.semibold))
            .foregroundStyle(tint)
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(.white.opacity(0.14))
            .clipShape(Capsule())
    }

    private func aiCoachResultHeadline(_ analysis: AICoachAnalysis) -> String {
        if !analysis.ntrpEquivalent.isEmpty {
            return "\(analysis.level) · \(analysis.ntrpEquivalent) · Score \(analysis.score)"
        }
        return "\(analysis.level) · Score \(analysis.score)"
    }

    private func statusBanner(title: String, detail: String, tint: Color, icon: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Circle()
                .fill(tint.opacity(0.14))
                .frame(width: 42, height: 42)
                .overlay(Image(systemName: icon).foregroundStyle(tint))

            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(MoveMatchPalette.textOnCard)
                Text(detail)
                    .font(.subheadline)
                    .foregroundStyle(MoveMatchPalette.textOnCardMuted)
            }
        }
        .padding(16)
        .background(tint.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private func executiveSummaryCard(_ analysis: AICoachAnalysis) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Label("Executive Summary", systemImage: "waveform.path.ecg")
                    .font(.headline.weight(.bold))
                Spacer()
                if !analysis.ntrpEquivalent.isEmpty {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("NTRP / USTA")
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(MoveMatchPalette.textSecondary)
                        Text(analysis.ntrpEquivalent)
                            .font(.caption.weight(.bold))
                            .foregroundStyle(MoveMatchPalette.primaryDark)
                    }
                } else {
                    Text(analysis.scoreLabel)
                        .font(.caption.weight(.bold))
                        .foregroundStyle(MoveMatchPalette.primaryDark)
                }
            }

            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .stroke(Color.orange.opacity(0.18), lineWidth: 8)
                        .frame(width: 70, height: 70)
                    Circle()
                        .trim(from: 0, to: CGFloat(analysis.score) / 100)
                        .stroke(Color.orange, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                        .frame(width: 70, height: 70)
                    VStack(spacing: 2) {
                        Text("\(analysis.score)")
                            .font(.title2.weight(.bold))
                            .foregroundStyle(.orange)
                        Text("Score")
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(MoveMatchPalette.textSecondary)
                        if !analysis.ntrpEquivalent.isEmpty {
                            Text(analysis.ntrpEquivalent)
                                .font(.system(size: 9, weight: .semibold))
                                .foregroundStyle(MoveMatchPalette.textSecondary)
                                .lineLimit(1)
                                .minimumScaleFactor(0.7)
                        }
                    }
                }

                VStack(alignment: .leading, spacing: 10) {
                    metricStrip(
                        title: "TOP STRENGTH",
                        value: analysis.strengths.first ?? "Balanced mechanics",
                        detail: "Most reliable pattern identified from this upload."
                    )
                    metricStrip(
                        title: "KEY IMPROVEMENT",
                        value: analysis.improvements.first ?? "Earlier preparation",
                        detail: "Highest-priority adjustment for your next session."
                    )
                }
            }

            if let fileName = viewModel.selectedVideoName {
                Label(fileName, systemImage: "doc.text")
                    .font(.caption)
                    .foregroundStyle(MoveMatchPalette.textSecondary)
            }
        }
        .padding(18)
        .background(MoveMatchPalette.card)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
    }

    private func feedbackCollectionsCard(_ analysis: AICoachAnalysis) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Structured AI Feedback", systemImage: "text.badge.checkmark")
                .font(.headline.weight(.bold))

            feedbackListBlock(title: "Strengths", items: analysis.strengths, tint: MoveMatchPalette.primaryDark)
            feedbackListBlock(title: "Issues", items: analysis.issues, tint: .orange)
            feedbackListBlock(title: "Suggestions", items: analysis.suggestions, tint: .blue)
            feedbackListBlock(title: "Training Plan", items: analysis.trainingPlan, tint: .purple)
        }
        .padding(18)
        .background(MoveMatchPalette.card)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
    }

    private func biomechanicalCard(_ analysis: AICoachAnalysis) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Issues & Suggestions", systemImage: "figure.tennis")
                    .font(.headline.weight(.bold))
                Spacer()
                Text("AI Review")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(MoveMatchPalette.primaryDark)
            }

            ZStack(alignment: .bottomLeading) {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(
                        LinearGradient(colors: [Color(red: 20 / 255, green: 40 / 255, blue: 70 / 255), Color.black], startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
                    .frame(height: 170)
                VStack(alignment: .leading, spacing: 8) {
                    Text(analysis.issues.first ?? "Technique Overview")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(.black.opacity(0.4))
                        .clipShape(Capsule())

                    HStack {
                        Spacer()
                        Circle()
                            .fill(.white.opacity(0.16))
                            .frame(width: 54, height: 54)
                            .overlay(Image(systemName: "play.fill").foregroundStyle(.white))
                        Spacer()
                    }
                }
                .padding(14)
            }

            ForEach(Array(analysis.biomechanics.prefix(4).enumerated()), id: \.offset) { entry in
                biomechanicalInsightRow(index: entry.offset, metric: entry.element)
            }
        }
        .padding(18)
        .background(MoveMatchPalette.card)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
    }

    private func skillRadarCard(_ analysis: AICoachAnalysis) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Skill Development Radar", systemImage: "scope")
                .font(.headline.weight(.bold))

            AICoachRadarView(metrics: analysis.radarData, tint: MoveMatchPalette.primaryDark)
                .frame(height: 240)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                ForEach(analysis.radarData, id: \.subject) { metric in
                    VStack(spacing: 6) {
                        Text(metric.subject)
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(MoveMatchPalette.textSecondary)
                            .multilineTextAlignment(.center)
                            .lineLimit(2)
                        Text("\(metric.score)")
                            .font(.headline.weight(.bold))
                            .foregroundStyle(MoveMatchPalette.primaryDark)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(Color.gray.opacity(0.06))
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
            }
        }
        .padding(18)
        .background(MoveMatchPalette.card)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
    }

    private func shotPlacementCard(_ analysis: AICoachAnalysis) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Shot Placement Heatmap", systemImage: "sparkles")
                .font(.headline.weight(.bold))

            TennisHeatmapCard(
                placements: analysis.shotPlacements,
                depthControlLine: analysis.depthControlLine
            )
        }
        .padding(18)
        .background(MoveMatchPalette.card)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
    }

    private func comparativeBenchmarkingCard(_ analysis: AICoachAnalysis) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text("Comparative Benchmarking")
                            .font(.caption.weight(.bold))
                        Spacer()
                        Text("Premium")
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(.purple)
                    }

                    Text("Pro Player Similarity")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(MoveMatchPalette.primaryDark)
                    HStack {
                        Text("Your motion signature vs \(analysis.proSimilarity.playerName)")
                            .font(.caption)
                            .foregroundStyle(MoveMatchPalette.textSecondary)
                            .lineLimit(3)
                        Spacer()
                        Text("\(analysis.proSimilarity.percentage)%")
                            .font(.headline.weight(.bold))
                    }
                    Text(analysis.proSimilarity.description)
                        .font(.caption)
                        .foregroundStyle(MoveMatchPalette.textSecondary)
                        .lineLimit(3)
                }
                .padding(14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.purple.opacity(0.05))
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))

                VStack(alignment: .leading, spacing: 10) {
                    Text("Skill Level Estimate")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(MoveMatchPalette.primaryDark)
                    Text(analysis.level)
                        .font(.title.weight(.bold))
                        .foregroundStyle(MoveMatchPalette.primaryDark)
                    Text("Estimated from your current motion quality, timing, and repeatability in this session.")
                        .font(.caption)
                        .foregroundStyle(MoveMatchPalette.textSecondary)
                }
                .padding(14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(MoveMatchPalette.primary.opacity(0.06))
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            }
        }
    }

    private func nextSessionCard(_ analysis: AICoachAnalysis) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Training Plan", systemImage: "calendar")
                .font(.headline.weight(.bold))

            VStack(alignment: .leading, spacing: 10) {
                Text("NEXT BLOCK")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.white.opacity(0.8))
                Text(analysis.prescription.focusArea)
                    .font(.title3.weight(.bold))
                    .foregroundStyle(.white)
                Text(analysis.prescription.drillName)
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(.white.opacity(0.92))
                Text(analysis.prescription.drillDescription)
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.84))

                HStack(spacing: 16) {
                    sessionMiniStat(value: "\(analysis.prescription.targetValue)", title: "Your Target")
                    sessionMiniStat(value: "\(analysis.score)", title: "Current Score")
                }

                Button {
                } label: {
                    HStack {
                        Text("Schedule Practice Session")
                        Spacer()
                        Image(systemName: "arrow.right")
                    }
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(MoveMatchPalette.primaryDark)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)
                    .background(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
                .buttonStyle(.plain)
            }
            .padding(16)
            .background(coachGradient)
            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        }
        .padding(18)
        .background(MoveMatchPalette.card)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
    }

    private func actionItemsCard(_ analysis: AICoachAnalysis) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Suggestions", systemImage: "checklist")
                .font(.headline.weight(.bold))

            ForEach(Array(analysis.actionItems.prefix(4).enumerated()), id: \.offset) { entry in
                HStack(alignment: .top, spacing: 12) {
                    Circle()
                        .fill(MoveMatchPalette.primary.opacity(0.14))
                        .frame(width: 28, height: 28)
                        .overlay(
                            Text("\(entry.offset + 1)")
                                .font(.caption.weight(.bold))
                                .foregroundStyle(MoveMatchPalette.primaryDark)
                        )
                    Text(entry.element)
                        .font(.subheadline)
                        .foregroundStyle(MoveMatchPalette.textSecondary)
                    Spacer(minLength: 0)
                }
                .padding(12)
                .background(Color.gray.opacity(0.06))
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
        }
        .padding(18)
        .background(MoveMatchPalette.card)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
    }

    private var nearbyCoachesCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Nearby Coaches", systemImage: "figure.run")
                    .font(.headline.weight(.bold))
                Spacer()
                Text("View All")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(MoveMatchPalette.primaryDark)
            }

            ForEach(nearbyCoachRows, id: \.name) { coach in
                HStack(spacing: 12) {
                    Circle()
                        .fill(coach.color.opacity(0.14))
                        .frame(width: 36, height: 36)
                        .overlay(Text(coach.initials).font(.caption.weight(.bold)).foregroundStyle(coach.color))
                    VStack(alignment: .leading, spacing: 2) {
                        Text(coach.name)
                            .font(.subheadline.weight(.bold))
                        Text(coach.specialty)
                            .font(.caption)
                            .foregroundStyle(MoveMatchPalette.textSecondary)
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("⭐ \(coach.rating)")
                            .font(.caption.weight(.bold))
                        Text(coach.price)
                            .font(.caption)
                            .foregroundStyle(coach.available ? MoveMatchPalette.primaryDark : .secondary)
                    }
                }
            }
        }
        .padding(18)
        .background(MoveMatchPalette.card)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
    }

    private var progressCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Label("Progress", systemImage: "chart.line.uptrend.xyaxis")
                    .font(.headline.weight(.bold))
                Spacer()
                Text("+20 pts")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(MoveMatchPalette.primaryDark)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(MoveMatchPalette.primary.opacity(0.08))
                    .clipShape(Capsule())
            }

            ForEach(progressRows, id: \.week) { row in
                HStack(spacing: 12) {
                    Text(row.week)
                        .font(.subheadline)
                        .foregroundStyle(MoveMatchPalette.textOnCardMuted)
                        .frame(width: 44, alignment: .leading)

                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            Capsule()
                                .fill(Color.gray.opacity(0.12))
                            Capsule()
                                .fill(row.color)
                                .frame(width: geometry.size.width * row.fill)
                        }
                    }
                    .frame(height: 8)

                    Text("\(row.score)")
                        .font(.headline.weight(.bold))
                        .foregroundStyle(row.color)
                        .frame(width: 36, alignment: .trailing)
                }
            }
        }
        .padding(18)
        .background(MoveMatchPalette.card)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
    }

    private var recentSessionsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Recent Sessions", systemImage: "chart.bar.xaxis")
                .font(.headline.weight(.bold))

            ForEach(recentSessions, id: \.title) { session in
                HStack(spacing: 12) {
                    Circle()
                        .fill(Color.white)
                        .frame(width: 42, height: 42)
                        .shadow(color: .black.opacity(0.06), radius: 6, y: 3)
                        .overlay(Text(session.emoji))
                    VStack(alignment: .leading, spacing: 2) {
                        Text(session.title)
                            .font(.subheadline.weight(.bold))
                        Text(session.time)
                            .font(.caption)
                            .foregroundStyle(MoveMatchPalette.textSecondary)
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("\(session.score)")
                            .font(.headline.weight(.bold))
                            .foregroundStyle(session.color)
                        Text(session.delta)
                            .font(.caption.weight(.bold))
                            .foregroundStyle(MoveMatchPalette.primaryDark)
                    }
                }
                .padding(.vertical, 6)
            }
        }
        .padding(18)
        .background(MoveMatchPalette.card)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
    }

    private var tipsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Pro Tips", systemImage: "star.fill")
                .font(.headline.weight(.bold))
                .foregroundStyle(.white)

            ForEach(proTips, id: \.self) { tip in
                HStack(alignment: .top, spacing: 10) {
                    Circle()
                        .fill(Color(red: 232 / 255, green: 255 / 255, blue: 191 / 255))
                        .frame(width: 6, height: 6)
                        .padding(.top, 7)
                    Text(tip)
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.88))
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .background(coachGradient)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        // Inset 与 `upgradeCard` 内白底区域一致，使蓝底宽度与其中「Upgrade Now」渐变按钮对齐
        .padding(.horizontal, 18)
    }

    private var upgradeCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Upgrade to Pro", systemImage: "flame.fill")
                .font(.headline.weight(.bold))
                .foregroundStyle(.orange)

            Text("Get unlimited analyses, frame-by-frame breakdown, biometric correlation and live coach review.")
                .font(.subheadline)
                .foregroundStyle(MoveMatchPalette.textSecondary)

            Button {
            } label: {
                HStack {
                    Spacer()
                    Text("Upgrade Now")
                    Image(systemName: "arrow.up.right")
                    Spacer()
                }
                .font(.headline.weight(.bold))
                .foregroundStyle(.white)
                .padding(.vertical, 14)
                .background(coachGradient)
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            }
            .buttonStyle(.plain)
        }
        .padding(18)
        .background(MoveMatchPalette.card)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
    }

    private func metricStrip(title: String, value: String, detail: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption.weight(.bold))
                .foregroundStyle(MoveMatchPalette.textSecondary)
            Text(value)
                .font(.title3.weight(.bold))
                .lineLimit(2)
                .minimumScaleFactor(0.7)
            Text(detail)
                .font(.caption)
                .foregroundStyle(MoveMatchPalette.textSecondary)
        }
    }

    private func feedbackListBlock(title: String, items: [String], tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(tint)
                Spacer()
            }

            ForEach(Array(items.prefix(4).enumerated()), id: \.offset) { entry in
                HStack(alignment: .top, spacing: 10) {
                    Circle()
                        .fill(tint.opacity(0.14))
                        .frame(width: 8, height: 8)
                        .padding(.top, 6)
                    Text(entry.element)
                        .font(.subheadline)
                        .foregroundStyle(MoveMatchPalette.textSecondary)
                    Spacer(minLength: 0)
                }
            }
        }
        .padding(14)
        .background(tint.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private func biomechanicalInsightRow(index: Int, metric: AICoachBiomechanicalMetric) -> some View {
        let tint = tint(for: metric.type)
        return HStack(alignment: .top, spacing: 10) {
            Circle()
                .fill(tint.opacity(0.14))
                .frame(width: 28, height: 28)
                .overlay(Image(systemName: iconName(for: metric.type, index: index)).font(.caption.weight(.bold)).foregroundStyle(tint))
            VStack(alignment: .leading, spacing: 3) {
                HStack {
                    Text(metric.label)
                        .font(.subheadline.weight(.bold))
                    Spacer(minLength: 8)
                    Text(metric.value)
                        .font(.caption.weight(.bold))
                        .foregroundStyle(tint)
                }
                Text(metric.tip)
                    .font(.subheadline)
                    .foregroundStyle(MoveMatchPalette.textSecondary)
            }
            Spacer(minLength: 0)
        }
        .padding(12)
        .background(tint.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private func sessionMiniStat(value: String, title: String) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(value)
                .font(.title2.weight(.bold))
                .foregroundStyle(.white)
            Text(title)
                .font(.caption)
                .foregroundStyle(.white.opacity(0.82))
        }
    }

    private func skillLevelEstimate(for score: Int) -> String {
        switch score {
        case 98...100: return "USTA 7.0"
        case 95...97: return "USTA 6.5"
        case 92...94: return "USTA 6.0"
        case 89...91: return "USTA 5.5"
        case 84...88: return "USTA 5.0"
        case 78...83: return "USTA 4.5"
        case 70...77: return "USTA 4.0"
        case 62...69: return "USTA 3.5"
        case 52...61: return "USTA 3.0"
        case 42...51: return "USTA 2.5"
        case 30...41: return "USTA 2.0"
        case 15...29: return "USTA 1.5"
        default: return "USTA 1.0"
        }
    }

    private func tint(for severity: AICoachMetricSeverity) -> Color {
        switch severity {
        case .warning:
            return .orange
        case .info:
            return .blue
        case .success:
            return MoveMatchPalette.primaryDark
        }
    }

    private func iconName(for severity: AICoachMetricSeverity, index: Int) -> String {
        switch severity {
        case .warning:
            return "exclamationmark"
        case .info:
            return index == 0 ? "scope" : "info"
        case .success:
            return "checkmark"
        }
    }

    private func analysisState(for index: Int) -> AnalysisStepBadge.State {
        let completedCount = max(1, min(Int((viewModel.progress * 6).rounded(.up)), 6))
        if index < completedCount - 1 { return .done }
        if index == completedCount - 1 { return .active }
        return .pending
    }

    private var gearPlaceholder: String {
        switch viewModel.selectedSport {
        case "Tennis": return "e.g. Wilson Blade V9"
        case "Golf": return "e.g. TaylorMade Stealth"
        case "Basketball": return "e.g. Wilson Evolution"
        case "Swimming": return "e.g. Arena Powerskin"
        default: return "e.g. Training gear"
        }
    }

    private var analysisSteps: [String] {
        [
            "Extracting skeletal nodes",
            "Reconstructing ball trajectory",
            "Computing swing velocity vectors",
            "Correlating biometric data",
            "Identifying root technique issues",
            "Building longitudinal performance report"
        ]
    }

    private var coachGradient: LinearGradient {
        LinearGradient(colors: [.teal, .cyan, .blue], startPoint: .topLeading, endPoint: .bottomTrailing)
    }

    private var recentSessions: [(title: String, time: String, score: Int, delta: String, emoji: String, color: Color)] {
        [
            ("Tennis · Forehand", "2 days ago", 78, "+5", "🎾", .orange),
            ("Basketball · Free Throw", "1 week ago", 85, "+12", "🏀", MoveMatchPalette.primaryDark),
            ("Swimming · Freestyle", "2 weeks ago", 71, "+3", "🏊", .orange)
        ]
    }

    private var nearbyCoachRows: [(name: String, specialty: String, rating: String, price: String, initials: String, color: Color, available: Bool)] {
        [
            ("Sarah M.", "Forehand & Serve", "4.9", "Free", "SM", .blue, true),
            ("James T.", "Match Strategy", "4.7", "Free", "JT", .teal, true),
            ("Liu W.", "Footwork & Movement", "4.8", "Busy", "LW", .cyan, false)
        ]
    }

    private var progressRows: [(week: String, score: Int, fill: Double, color: Color)] {
        [
            ("Wk 1", 58, 0.68, .red),
            ("Wk 2", 63, 0.72, .red),
            ("Wk 3", 70, 0.79, .orange),
            ("Wk 4", max(viewModel.latestAnalysis?.score ?? 78, 78), 0.86, .orange)
        ]
    }

    private var proTips: [String] {
        [
            "Film from the side for best swing analysis",
            "Good lighting improves joint detection",
            "Upload 3–5 reps for consistent feedback",
            "Wear fitted clothing for body tracking",
            "Authorize heart rate data for deeper insights"
        ]
    }

    private var shouldShowBodyProfileHint: Bool {
        !bodyProfileHintDismissed && !hasAnyBodyMetrics
    }

    private var hasAnyBodyMetrics: Bool {
        let defaults = UserDefaults.standard
        let keys = [
            "movematch.profile.body.height_cm",
            "movematch.profile.body.weight_kg",
            "movematch.profile.body.chest_cm",
            "movematch.profile.body.waist_cm",
            "movematch.profile.body.hip_cm",
            "movematch.profile.body.arm_span_cm"
        ]
        return keys.contains {
            !(defaults.string(forKey: $0) ?? "").trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
    }
}

private struct CoachHubView: View {
    @ObservedObject var viewModel: AICoachViewModel
    @Binding var selectedTab: AppTab

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Choose your coaching mode")
                        .font(.largeTitle.bold())
                        .foregroundStyle(MoveMatchPalette.textOnCard)
                    Text("Pick AI-powered analysis or browse traditional coaches and book sessions.")
                        .font(.subheadline)
                        .foregroundStyle(MoveMatchPalette.textOnCardMuted)
                }

                NavigationLink {
                    AICoachView(viewModel: viewModel, selectedTab: $selectedTab)
                } label: {
                    coachModeCard(
                        icon: "brain.head.profile",
                        title: "AI Coach",
                        subtitle: "Upload your own video and get motion analysis, benchmarks, and drill suggestions.",
                        gradient: LinearGradient(colors: [.teal, .cyan, .blue], startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
                }
                .buttonStyle(.plain)

                NavigationLink {
                    EnhancedCoachesView()
                } label: {
                    coachModeCard(
                        icon: "person.3.fill",
                        title: "Traditional Manual Coach",
                        subtitle: "Browse verified coaches, compare expertise, and book 1-on-1 or group sessions.",
                        gradient: LinearGradient(colors: [.orange, .pink], startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
                }
                .buttonStyle(.plain)
            }
            .padding(20)
            .padding(.bottom, MoveMatchPalette.tabBarScrollBottomPadding)
        }
        .background(MoveMatchPalette.background.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
    }

    private func coachModeCard(icon: String, title: String, subtitle: String, gradient: LinearGradient) -> some View {
        ZStack(alignment: .bottomLeading) {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(gradient)
                .frame(height: 220)

            VStack(alignment: .leading, spacing: 12) {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(.white.opacity(0.16))
                    .frame(width: 54, height: 54)
                    .overlay(Image(systemName: icon).font(.title3).foregroundStyle(.white))

                Text(title)
                    .font(.title2.bold())
                    .foregroundStyle(.white)

                Text(subtitle)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.leading)
                    .shadow(color: .black.opacity(0.35), radius: 0, x: 0, y: 1)

                HStack {
                    Text("Open")
                        .font(.subheadline.weight(.bold))
                    Spacer()
                    Image(systemName: "arrow.right")
                }
                .foregroundStyle(.white)
                .padding(.top, 4)
            }
            .padding(20)
        }
    }
}

private struct AICoachHeroMetric: View {
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.white.opacity(0.82))
            Text(value)
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(.white)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(.white.opacity(0.10))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(.white.opacity(0.12), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}

private struct UploadOptionTile: View {
    let icon: String
    let title: String
    let subtitle: String
    let isSelected: Bool
    let isDisabled: Bool

    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(isDisabled ? Color.gray : (isSelected ? MoveMatchPalette.primaryDark : MoveMatchPalette.textOnCardMuted))
            Text(title)
                .font(.headline.weight(.bold))
                .foregroundStyle(isDisabled ? Color.gray : MoveMatchPalette.textOnCard)
                .multilineTextAlignment(.center)
            Text(subtitle)
                .font(.caption)
                .foregroundStyle(isDisabled ? Color.gray.opacity(0.85) : MoveMatchPalette.textOnCardMuted)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 140)
        .background(.white)
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(isSelected ? MoveMatchPalette.primary.opacity(0.5) : Color.gray.opacity(0.14), lineWidth: isSelected ? 1.5 : 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .opacity(isDisabled ? 0.72 : 1)
    }
}

private struct AnalysisStepBadge: View {
    enum State {
        case done
        case active
        case pending
    }

    let title: String
    let state: State

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: iconName)
                .font(.caption.weight(.bold))
            Text(title)
                .font(.caption.weight(.semibold))
                .lineLimit(2)
                .multilineTextAlignment(.leading)
        }
        .foregroundStyle(foreground)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 12)
        .padding(.vertical, 12)
        .background(background)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var iconName: String {
        switch state {
        case .done: return "checkmark.circle.fill"
        case .active: return "sparkle"
        case .pending: return "circle"
        }
    }

    private var foreground: Color {
        switch state {
        case .done, .active: return MoveMatchPalette.primaryDark
        case .pending: return .secondary
        }
    }

    private var background: Color {
        switch state {
        case .done: return MoveMatchPalette.primary.opacity(0.10)
        case .active: return Color(red: 237 / 255, green: 251 / 255, blue: 247 / 255)
        case .pending: return Color.gray.opacity(0.08)
        }
    }
}

private struct TennisHeatmapCard: View {
    let placements: [CoachShotPlacement]
    let depthControlLine: String

    private var points: [(CGFloat, CGFloat, Color)] {
        placements.map { p in
            let c: Color = p.player == 2 ? .red : Color(red: 0.2, green: 0.72, blue: 0.45)
            return (CGFloat(p.x), CGFloat(p.y), c)
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [Color(red: 191 / 255, green: 236 / 255, blue: 212 / 255), Color(red: 160 / 255, green: 220 / 255, blue: 193 / 255)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                GeometryReader { geometry in
                    let width = geometry.size.width * 0.60
                    let height = geometry.size.height * 0.78
                    let originX = (geometry.size.width - width) / 2
                    let originY = (geometry.size.height - height) / 2
                    let netY = originY + height / 2

                    ZStack(alignment: .topLeading) {
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(Color(red: 93 / 255, green: 160 / 255, blue: 122 / 255))
                            .frame(width: width, height: height)
                            .position(x: geometry.size.width / 2, y: geometry.size.height / 2)

                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .stroke(.white.opacity(0.92), lineWidth: 2.4)
                            .frame(width: width, height: height)
                            .position(x: geometry.size.width / 2, y: geometry.size.height / 2)

                        Path { path in
                            path.move(to: CGPoint(x: originX + width / 2, y: originY))
                            path.addLine(to: CGPoint(x: originX + width / 2, y: originY + height))

                            path.move(to: CGPoint(x: originX + width * 0.12, y: originY))
                            path.addLine(to: CGPoint(x: originX + width * 0.12, y: originY + height))

                            path.move(to: CGPoint(x: originX + width * 0.88, y: originY))
                            path.addLine(to: CGPoint(x: originX + width * 0.88, y: originY + height))

                            path.move(to: CGPoint(x: originX, y: originY + height * 0.26))
                            path.addLine(to: CGPoint(x: originX + width, y: originY + height * 0.26))

                            path.move(to: CGPoint(x: originX, y: originY + height * 0.74))
                            path.addLine(to: CGPoint(x: originX + width, y: originY + height * 0.74))

                            path.move(to: CGPoint(x: originX + width / 2, y: originY + height * 0.26))
                            path.addLine(to: CGPoint(x: originX + width / 2, y: originY + height * 0.74))
                        }
                        .stroke(.white.opacity(0.82), lineWidth: 1.2)

                        Rectangle()
                            .fill(Color.white.opacity(0.95))
                            .frame(width: width + 18, height: 3)
                            .position(x: geometry.size.width / 2, y: netY - 10)

                        Rectangle()
                            .fill(Color(red: 28 / 255, green: 45 / 255, blue: 37 / 255).opacity(0.90))
                            .frame(width: width + 8, height: 18)
                            .position(x: geometry.size.width / 2, y: netY + 1)

                        Path { path in
                            let left = originX - 4
                            let right = originX + width + 4
                            let top = netY - 8
                            let bottom = netY + 10
                            let spacing: CGFloat = 8

                            var x = left
                            while x <= right {
                                path.move(to: CGPoint(x: x, y: top))
                                path.addLine(to: CGPoint(x: x, y: bottom))
                                x += spacing
                            }

                            var y = top
                            while y <= bottom {
                                path.move(to: CGPoint(x: left, y: y))
                                path.addLine(to: CGPoint(x: right, y: y))
                                y += 4
                            }
                        }
                        .stroke(.white.opacity(0.22), lineWidth: 0.5)

                        Capsule()
                            .fill(.white)
                            .frame(width: 4, height: 26)
                            .position(x: originX - 6, y: netY - 1)

                        Capsule()
                            .fill(.white)
                            .frame(width: 4, height: 26)
                            .position(x: originX + width + 6, y: netY - 1)

                        ForEach(Array(points.enumerated()), id: \.offset) { entry in
                            let point = entry.element
                            Circle()
                                .fill(point.2)
                                .frame(width: 14, height: 14)
                                .overlay(
                                    Circle()
                                        .stroke(.white.opacity(0.38), lineWidth: 1)
                                )
                                .shadow(color: .black.opacity(0.10), radius: 3, y: 1)
                                .position(
                                    x: originX + width * point.0,
                                    y: originY + height * point.1
                                )
                        }
                    }
                }
                .padding(20)
            }
            .frame(height: 250)
            .overlay(alignment: .bottom) {
                if placements.isEmpty {
                    Text("No shot placements to draw — the model did not detect the ball or court in the video.")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(.black.opacity(0.35))
                        .clipShape(Capsule())
                        .padding(.bottom, 12)
                }
            }

            HStack(spacing: 16) {
                heatmapLegend(
                    color: Color(red: 0.2, green: 0.72, blue: 0.45),
                    title: "Player 1",
                    subtitle: "Return placement"
                )
                heatmapLegend(color: .red, title: "Player 2", subtitle: "Return placement")
            }

            VStack(alignment: .leading, spacing: 6) {
                Label("Depth & placement note", systemImage: "sparkles")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.purple)
                Text(
                    depthControlLine.isEmpty
                        ? "Placements are estimated from visible frames only and are for training reference (not line tracking)."
                        : depthControlLine
                )
                    .font(.caption)
                    .foregroundStyle(MoveMatchPalette.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(12)
            .background(Color.purple.opacity(0.06))
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
    }

    private func heatmapLegend(color: Color, title: String, subtitle: String) -> some View {
        HStack(spacing: 6) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(.caption2.weight(.bold))
                Text(subtitle)
                    .font(.caption2)
                    .foregroundStyle(MoveMatchPalette.textOnCardMuted)
            }
        }
    }
}

private struct AICoachRadarView: View {
    let metrics: [AICoachRadarMetric]
    let tint: Color

    var body: some View {
        GeometryReader { geo in
            let size = min(geo.size.width, geo.size.height)
            let center = CGPoint(x: geo.size.width / 2, y: geo.size.height / 2)
            let radius = size * 0.32

            ZStack {
                ForEach(1 ... 4, id: \.self) { ring in
                    AICoachPolygonShape(points: normalizedPoints(radiusScale: CGFloat(ring) / 4))
                        .stroke(Color.gray.opacity(0.18), lineWidth: 1)
                        .frame(width: radius * 2, height: radius * 2)
                        .position(center)
                }

                ForEach(Array(metrics.enumerated()), id: \.offset) { index, _ in
                    Path { path in
                        path.move(to: center)
                        path.addLine(to: point(for: index, value: 100, center: center, radius: radius))
                    }
                    .stroke(Color.gray.opacity(0.18), lineWidth: 1)
                }

                AICoachPolygonShape(points: metricPoints())
                    .fill(tint.opacity(0.18))
                    .overlay(
                        AICoachPolygonShape(points: metricPoints())
                            .stroke(tint, lineWidth: 3)
                    )
                    .frame(width: radius * 2, height: radius * 2)
                    .position(center)

                ForEach(Array(metrics.enumerated()), id: \.offset) { index, metric in
                    Circle()
                        .fill(tint)
                        .frame(width: 8, height: 8)
                        .position(point(for: index, value: Double(metric.score), center: center, radius: radius))

                    Text(metric.subject)
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(MoveMatchPalette.textSecondary)
                        .multilineTextAlignment(.center)
                        .position(labelPoint(for: index, center: center, radius: radius + 36))
                }
            }
        }
    }

    private func normalizedPoints(radiusScale: CGFloat) -> [CGPoint] {
        (0 ..< metrics.count).map { index in
            let angle = angleForIndex(index)
            return CGPoint(x: 0.5 + cos(angle) * 0.5 * radiusScale, y: 0.5 + sin(angle) * 0.5 * radiusScale)
        }
    }

    private func metricPoints() -> [CGPoint] {
        (0 ..< metrics.count).map { index in
            let valueScale = CGFloat(Double(metrics[index].score) / 100)
            let angle = angleForIndex(index)
            return CGPoint(x: 0.5 + cos(angle) * 0.5 * valueScale, y: 0.5 + sin(angle) * 0.5 * valueScale)
        }
    }

    private func angleForIndex(_ index: Int) -> CGFloat {
        let fraction = CGFloat(index) / CGFloat(max(metrics.count, 1))
        return (.pi * 2 * fraction) - (.pi / 2)
    }

    private func point(for index: Int, value: Double, center: CGPoint, radius: CGFloat) -> CGPoint {
        let angle = angleForIndex(index)
        let scaled = CGFloat(value / 100) * radius
        return CGPoint(x: center.x + cos(angle) * scaled, y: center.y + sin(angle) * scaled)
    }

    private func labelPoint(for index: Int, center: CGPoint, radius: CGFloat) -> CGPoint {
        let angle = angleForIndex(index)
        return CGPoint(x: center.x + cos(angle) * radius, y: center.y + sin(angle) * radius)
    }
}

private struct AICoachPolygonShape: Shape {
    let points: [CGPoint]

    func path(in rect: CGRect) -> Path {
        guard let first = points.first else { return Path() }
        var path = Path()
        path.move(to: CGPoint(x: rect.minX + rect.width * first.x, y: rect.minY + rect.height * first.y))
        for point in points.dropFirst() {
            path.addLine(to: CGPoint(x: rect.minX + rect.width * point.x, y: rect.minY + rect.height * point.y))
        }
        path.closeSubpath()
        return path
    }
}

private struct SmartwatchPromptSheet: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 18) {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(
                        LinearGradient(colors: [.teal, .cyan], startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
                    .frame(width: 68, height: 68)
                    .overlay(
                        Image(systemName: "applewatch")
                            .font(.system(size: 28, weight: .semibold))
                            .foregroundStyle(.white)
                    )

                Text("Connect Your Smartwatch")
                    .font(.system(size: 34, weight: .bold))

                Text("To unlock deeper AI coaching, authorize your health & sports data.")
                    .font(.title3)
                    .foregroundStyle(MoveMatchPalette.textSecondary)

                VStack(alignment: .leading, spacing: 10) {
                    Label("Why this matters: By authorizing heart rate data, the AI can analyze the relationship between your physical exertion and shot quality during long rallies — giving you elite-level insights.", systemImage: "heart.text.square")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(MoveMatchPalette.primaryDark)
                }
                .padding(16)
                .background(Color(red: 236 / 255, green: 251 / 255, blue: 247 / 255))
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))

                Label("Data is processed locally and never sold to third parties.", systemImage: "shield")
                    .font(.subheadline)
                    .foregroundStyle(MoveMatchPalette.textSecondary)

                Spacer()

                Button {
                    dismiss()
                } label: {
                    Text("Authorize Health Data")
                        .font(.headline.weight(.bold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            LinearGradient(colors: [.teal, .cyan], startPoint: .leading, endPoint: .trailing)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                }
                .buttonStyle(.plain)

                Button {
                    dismiss()
                } label: {
                    Text("Skip for Now")
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(.primary.opacity(0.7))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.white)
                        .overlay(
                            RoundedRectangle(cornerRadius: 20, style: .continuous)
                                .stroke(Color.gray.opacity(0.16), lineWidth: 1)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                }
                .buttonStyle(.plain)
            }
            .padding(24)
            .navigationTitle("")
        }
    }
}

private struct CoachConfigurationSheet: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: AICoachViewModel

    @State private var endpoint = ""
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            Form {
                Section("Backend") {
                    TextField("Analyze endpoint", text: $endpoint)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                    LabeledContent("AI model", value: AICoachViewModel.backendModelName)
                    if let cloudEndpoint = AICoachViewModel.cloudAnalyzeEndpoint {
                        Button("Use Public Cloud Endpoint") {
                            endpoint = cloudEndpoint
                        }
                        .font(.subheadline.weight(.semibold))
                    }
                    #if targetEnvironment(simulator)
                    Button("Use Local Simulator Endpoint") {
                        endpoint = AICoachViewModel.localAnalyzeEndpoint
                    }
                    .font(.subheadline.weight(.semibold))
                    #endif
                }

                Section("Expected flow") {
                    Text("1. Deploy backend-node to a public host (recommended: Render) and set AI_API_KEY in server environment variables.")
                    Text("2. Ship Info-ATS.plist with `AICoachCloudEndpoint` pointing to POST /api/analyze (for example: https://<your-service>.onrender.com/api/analyze).")
                    #if targetEnvironment(simulator)
                    Text("3. Simulator can use http://127.0.0.1:3001/... for local debugging, or the bundled cloud URL when nothing is saved.")
                    #else
                    Text("3. On physical iPhone the bundled HTTPS URL is used automatically on cellular or any Wi‑Fi; users do not need to configure it.")
                    #endif
                    Text("4. Upload a sports video in AI Coach, then run Analyze Training Video.")
                }

                if let errorMessage {
                    Section {
                        Text(errorMessage)
                            .foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle("AI Settings")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        do {
                            try viewModel.saveConfiguration(endpoint: endpoint)
                            dismiss()
                        } catch {
                            errorMessage = error.localizedDescription
                        }
                    }
                }
            }
            .onAppear {
                #if targetEnvironment(simulator)
                endpoint = viewModel.endpoint.isEmpty ? AICoachViewModel.localAnalyzeEndpoint : viewModel.endpoint
                #else
                endpoint = viewModel.endpoint
                #endif
            }
        }
    }
}

private struct SectionTitle: View {
    let title: String

    init(_ title: String) {
        self.title = title
    }

    var body: some View {
        Text(title)
            .font(.title3.bold())
    }
}

private struct StatCard: View {
    let title: String
    let value: String
    let icon: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: icon)
                .foregroundStyle(MoveMatchPalette.primary)
            Text(value)
                .font(.title2.bold())
            Text(title)
                .font(.footnote)
                .foregroundStyle(MoveMatchPalette.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(MoveMatchPalette.card)
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
    }
}

private struct RequirementRow: View {
    let title: String
    let detail: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(MoveMatchPalette.primary)
                .padding(.top, 2)
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                Text(detail)
                    .font(.caption)
                    .foregroundStyle(MoveMatchPalette.textSecondary)
            }
        }
    }
}

private func searchHeader(_ title: String, subtitle: String) -> some View {
    VStack(alignment: .leading, spacing: 8) {
        Text(title)
            .font(.largeTitle.bold())
        Text(subtitle)
            .font(.subheadline)
            .foregroundStyle(MoveMatchPalette.textSecondary)
    }
    .frame(maxWidth: .infinity, alignment: .leading)
}

private func feedCard(title: String, subtitle: String, detail: String, icon: String, color: Color) -> some View {
    HStack(spacing: 14) {
        RoundedRectangle(cornerRadius: 18, style: .continuous)
            .fill(color.opacity(0.15))
            .frame(width: 54, height: 54)
            .overlay(Image(systemName: icon).foregroundStyle(color))

        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.headline)
            Text(subtitle)
                .font(.subheadline)
                .foregroundStyle(MoveMatchPalette.textSecondary)
            Text(detail)
                .font(.caption.weight(.semibold))
                .foregroundStyle(color)
        }

        Spacer()
    }
    .padding(16)
    .background(MoveMatchPalette.card)
    .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
    ContentView()
    }
}
