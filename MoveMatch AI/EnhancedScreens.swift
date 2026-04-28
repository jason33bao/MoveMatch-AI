import Charts
import SwiftUI

private extension View {
    @ViewBuilder
    func platformInlineNavigationBarTitle() -> some View {
#if os(iOS)
        self.navigationBarTitleDisplayMode(.inline)
#else
        self
#endif
    }
}

private extension ToolbarItemPlacement {
    static var platformTopBarTrailing: ToolbarItemPlacement {
#if os(iOS)
        .topBarTrailing
#else
        .automatic
#endif
    }
}

private func decodeIDSet(from storage: String) -> Set<Int> {
    Set(storage.split(separator: ",").compactMap { Int($0) })
}

private func encodeIDSet(_ ids: Set<Int>) -> String {
    ids.sorted().map(String.init).joined(separator: ",")
}

private enum EnhancedProfileTab: String, CaseIterable {
    case overview = "Overview"
    case activities = "Activities"
    case skills = "Skills"
    case awards = "Awards"
}

private struct DiscoverActivity: Identifiable, Hashable {
    let id: Int
    let sport: String
    let emoji: String
    let title: String
    let organizer: String
    let location: String
    let time: String
    let level: String
    let distance: String
    let rating: Double
    let participants: Int
    let maxParticipants: Int
    let tags: [String]
    let imageURL: String
    let verified: Bool
}

private struct ProfileActivity: Identifiable, Hashable {
    let id: Int
    let title: String
    let type: String
    let sport: String
    let date: String
    let duration: String
    let score: Int?
    let imageURL: String
    let description: String
    let highlights: [String]
    let strengths: [String]
    let improvements: [String]
}

private struct ProfileAchievement: Identifiable, Hashable {
    let id: Int
    let title: String
    let detail: String
    let icon: String
    let earned: Bool
    let progress: Int
}

private struct SkillAxis: Identifiable {
    let id = UUID()
    let label: String
    let value: Double
}

private enum SkillTier: String, CaseIterable, Identifiable {
    case beginner
    case intermediate
    case advanced

    var id: String { rawValue }

    var title: String {
        rawValue.capitalized
    }
}

private struct SportSkillGroup: Identifiable {
    let id: String
    var sport: String
    var emoji: String
    var tier: SkillTier
    var tierLevel: Int
    var score: Double
    var maxScore: Double
    var tint: Color
    var skills: [SkillAxis]

    var usesUSTARating: Bool {
        sport == "Tennis"
    }

    var levelLabel: String {
        if usesUSTARating {
            return String(format: "USTA %.1f", score)
        }
        return "\(tier.title) \(tierLevel).0"
    }
}

private struct SocialPerson: Identifiable, Hashable {
    let id: Int
    let name: String
    let handle: String
    let sport: String
    let accent: Color
}

struct EnhancedDiscoverView: View {
    @State private var searchText = ""
    @State private var selectedSport = "All"
    @AppStorage("enhanced_discover_joined_activity_ids") private var joinedActivityIDsStorage = ""
    @State private var joinedActivityIDs: Set<Int> = []
    @State private var selectedActivity: DiscoverActivity?
    private let discoverColumns = [GridItem(.flexible(), spacing: 14), GridItem(.flexible(), spacing: 14)]

    private let sports = ["All", "Tennis", "Basketball", "Running", "Yoga", "Swimming", "Golf"]

    private let activities: [DiscoverActivity] = [
        .init(id: 1, sport: "Tennis", emoji: "🎾", title: "Singles Practice", organizer: "Sarah K.", location: "City Tennis Club", time: "Tomorrow 9:00 AM", level: "Advanced", distance: "1.2 km", rating: 4.9, participants: 1, maxParticipants: 2, tags: ["Competitive", "Coach nearby"], imageURL: "https://images.unsplash.com/photo-1761286753856-2f39b4413c1c?auto=format&fit=crop&w=900&q=80", verified: true),
        .init(id: 2, sport: "Basketball", emoji: "🏀", title: "3v3 Pickup Game", organizer: "Jordan M.", location: "Riverside Court", time: "Today 4:00 PM", level: "Intermediate", distance: "0.8 km", rating: 4.8, participants: 4, maxParticipants: 6, tags: ["Casual", "Outdoors"], imageURL: "https://images.unsplash.com/photo-1770042572491-0c3f1ca7d6a1?auto=format&fit=crop&w=900&q=80", verified: true),
        .init(id: 3, sport: "Running", emoji: "🏃", title: "Morning 5K Run", organizer: "Park Run Club", location: "Riverside Park", time: "Tomorrow 7:00 AM", level: "All Levels", distance: "0.4 km", rating: 4.7, participants: 8, maxParticipants: 20, tags: ["Beginner friendly", "Group"], imageURL: "https://images.unsplash.com/photo-1758586326115-d4e9052b8f06?auto=format&fit=crop&w=900&q=80", verified: false),
        .init(id: 4, sport: "Yoga", emoji: "🧘", title: "Sunrise Yoga Session", organizer: "ZenFlow Studio", location: "Central Park Lawn", time: "Sat 6:30 AM", level: "Beginner", distance: "2.1 km", rating: 4.9, participants: 12, maxParticipants: 25, tags: ["Wellness", "Outdoor"], imageURL: "https://images.unsplash.com/photo-1758274525887-d95d19269f76?auto=format&fit=crop&w=900&q=80", verified: true),
        .init(id: 5, sport: "Swimming", emoji: "🏊", title: "Masters Swim Practice", organizer: "SwimMasters", location: "Aquatic Center", time: "Wed 6:00 PM", level: "Advanced", distance: "3.0 km", rating: 4.6, participants: 6, maxParticipants: 12, tags: ["Indoor", "Technique"], imageURL: "https://images.unsplash.com/photo-1572594505398-97a384b34ec8?auto=format&fit=crop&w=900&q=80", verified: true),
        .init(id: 6, sport: "Golf", emoji: "⛳", title: "9-Hole Casual Round", organizer: "GolfPro Dave", location: "Green Valley Golf", time: "Sun 10:00 AM", level: "Intermediate", distance: "5.4 km", rating: 4.5, participants: 2, maxParticipants: 4, tags: ["Weekend", "Friendly"], imageURL: "https://images.unsplash.com/photo-1763917379121-91130139aca0?auto=format&fit=crop&w=900&q=80", verified: false)
    ]

    private var filteredActivities: [DiscoverActivity] {
        activities.filter { activity in
            (selectedSport == "All" || activity.sport == selectedSport) &&
            (searchText.isEmpty ||
             activity.title.localizedCaseInsensitiveContains(searchText) ||
             activity.location.localizedCaseInsensitiveContains(searchText) ||
             activity.organizer.localizedCaseInsensitiveContains(searchText))
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                discoverHeader
                searchSection
                sportPicker
                resultsHeader

                LazyVGrid(columns: discoverColumns, spacing: 16) {
                    ForEach(filteredActivities) { activity in
                        DiscoverActivityCard(
                            activity: activity,
                            joined: joinedActivityIDs.contains(activity.id),
                            displayedParticipants: displayedParticipants(for: activity),
                            onTap: { selectedActivity = activity },
                            onJoin: { toggleJoin(activity.id) }
                        )
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 20 + MoveMatchPalette.tabBarScrollBottomPadding)
        }
        .background(MoveMatchPalette.background.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .sheet(item: $selectedActivity) { activity in
            DiscoverActivityDetailSheet(
                activity: activity,
                joined: joinedActivityIDs.contains(activity.id),
                displayedParticipants: displayedParticipants(for: activity),
                onJoin: { toggleJoin(activity.id) }
            )
        }
        .onAppear {
            joinedActivityIDs = decodeIDSet(from: joinedActivityIDsStorage)
        }
    }

    private var discoverHeader: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Discover Activities")
                .font(.title.bold())
                .foregroundStyle(MoveMatchPalette.textOnCard)
            Text("Find sports activities near you")
                .font(.footnote)
                .foregroundStyle(MoveMatchPalette.textOnCardMuted)
        }
    }

    private var searchSection: some View {
        HStack(spacing: 12) {
            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(MoveMatchPalette.textOnCardMuted)
                TextField(
                    "",
                    text: $searchText,
                    prompt: Text("Search activities...")
                        .foregroundStyle(MoveMatchPalette.textOnCardMuted)
                )
                .font(.subheadline)
                .foregroundStyle(MoveMatchPalette.textOnCard)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 11)
            .background(.white)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(Color.black.opacity(0.05), lineWidth: 1)
            )

            Button {
            } label: {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(.white)
                    .frame(width: 48, height: 48)
                    .overlay(
                        Image(systemName: "slider.horizontal.3")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(MoveMatchPalette.textOnCardMuted)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(Color.black.opacity(0.05), lineWidth: 1)
                    )
            }
            .buttonStyle(.plain)
        }
    }

    private var sportPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(sports, id: \.self) { sport in
                    Button {
                        selectedSport = sport
                    } label: {
                        HStack(spacing: 6) {
                            if let icon = sportIcon(for: sport) {
                                Text(icon)
                            }
                            Text(sport == "All" ? "All Sports" : sport)
                        }
                            .font(.footnote.weight(.semibold))
                            .foregroundStyle(selectedSport == sport ? MoveMatchPalette.primaryDark : MoveMatchPalette.textOnCard)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 9)
                            .background(selectedSport == sport ? MoveMatchPalette.primary.opacity(0.12) : .white)
                            .overlay(
                                Capsule()
                                    .stroke(selectedSport == sport ? MoveMatchPalette.primary.opacity(0.28) : Color.gray.opacity(0.10), lineWidth: 1)
                            )
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.vertical, 2)
        }
    }

    private var resultsHeader: some View {
        HStack {
            Text("\(filteredActivities.count) found")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(MoveMatchPalette.textOnCard)
            Spacer()
            Label("Near you", systemImage: "location.fill")
                .font(.caption2.weight(.semibold))
                .foregroundStyle(MoveMatchPalette.primaryDark)
            Image(systemName: "arrow.clockwise")
                .font(.caption2.weight(.semibold))
                .foregroundStyle(MoveMatchPalette.textOnCardMuted)
        }
    }

    private func toggleJoin(_ id: Int) {
        if joinedActivityIDs.contains(id) {
            joinedActivityIDs.remove(id)
        } else {
            joinedActivityIDs.insert(id)
        }
        joinedActivityIDsStorage = encodeIDSet(joinedActivityIDs)
    }

    private func displayedParticipants(for activity: DiscoverActivity) -> Int {
        activity.participants + (joinedActivityIDs.contains(activity.id) ? 1 : 0)
    }

    private func sportIcon(for sport: String) -> String? {
        switch sport {
        case "All":
            return "🏆"
        case "Tennis":
            return "🎾"
        case "Basketball":
            return "🏀"
        case "Running":
            return "🏃"
        case "Yoga":
            return "🧘"
        case "Swimming":
            return "🏊"
        case "Golf":
            return "⛳"
        default:
            return nil
        }
    }
}

struct EnhancedProfileView: View {
    @State private var activeTab: EnhancedProfileTab = .overview
    @State private var profile = EditableProfile(
        name: "Alex Chen",
        handle: "@alexchen",
        location: "Hong Kong",
        bio: "Passionate tennis player and weekend basketball enthusiast. I use MoveMatch AI to track skill growth, find better sessions, and stay accountable.",
        tags: ["🎾 Tennis", "🏀 Basketball", "🏃 Running"]
    )
    @State private var editDraft = EditableProfile(
        name: "Alex Chen",
        handle: "@alexchen",
        location: "Hong Kong",
        bio: "Passionate tennis player and weekend basketball enthusiast. I use MoveMatch AI to track skill growth, find better sessions, and stay accountable.",
        tags: ["🎾 Tennis", "🏀 Basketball", "🏃 Running"]
    )
    @State private var showingEditSheet = false
    @State private var showingFollowersSheet = false
    @State private var showingFollowingSheet = false
    @State private var showingShareSheet = false
    @State private var showingSkillLevelSheet = false
    @State private var showingBodyMetricsSheet = false
    @State private var selectedActivity: ProfileActivity?
    @State private var selectedCoverIndex = 0
    @State private var bodyMetrics = AthleteBodyMetrics.load()
    @State private var bodyMetricsDraft = AthleteBodyMetrics.load()

    private let coverGradients: [LinearGradient] = [
        LinearGradient(colors: [MoveMatchPalette.primary, .teal, .cyan], startPoint: .topLeading, endPoint: .bottomTrailing),
        LinearGradient(colors: [.blue, .indigo, .purple], startPoint: .topLeading, endPoint: .bottomTrailing),
        LinearGradient(colors: [.orange, .pink, .red], startPoint: .topLeading, endPoint: .bottomTrailing)
    ]

    private let progressPoints: [(month: String, score: Int)] = [
        ("Nov", 58), ("Dec", 63), ("Jan", 68), ("Feb", 72), ("Mar", 78)
    ]

    private let activities: [ProfileActivity] = [
        .init(id: 1, title: "Tennis Practice", type: "Training", sport: "Tennis", date: "Mar 30, 2026", duration: "90 min", score: 79, imageURL: "https://images.unsplash.com/photo-1761286753856-2f39b4413c1c?auto=format&fit=crop&w=900&q=80", description: "Focused session on serve rhythm, forehand contact point, and balanced follow-through. Great progress in consistency and shot depth.", highlights: ["Serve speed improved by 12%", "Forehand topspin more stable", "Unforced errors reduced"], strengths: ["Hip rotation stayed compact", "Ball contact was further in front", "Footwork stayed active before impact"], improvements: ["Need a calmer toss on second serves", "Backhand recovery still slow", "Stay lower through follow-through"]),
        .init(id: 2, title: "Serve Analysis", type: "AI Session", sport: "Tennis", date: "Mar 20, 2026", duration: "30 min", score: 74, imageURL: "https://images.unsplash.com/photo-1622163642998-1ea32b0bbc67?auto=format&fit=crop&w=900&q=80", description: "AI review of serve mechanics with emphasis on toss consistency, shoulder turn, and timing through contact.", highlights: ["45 serves analyzed", "Main issue: toss drift", "4-week plan generated"], strengths: ["Good racket acceleration", "Strong body alignment", "Clean follow-through"], improvements: ["Toss variance too wide", "Hip drive limited at trophy position", "Kick-serve elbow drops early"]),
        .init(id: 3, title: "Morning Run 5K", type: "Training", sport: "Running", date: "Mar 18, 2026", duration: "28 min", score: 82, imageURL: "https://images.unsplash.com/photo-1758586326115-d4e9052b8f06?auto=format&fit=crop&w=900&q=80", description: "Steady-state run with negative splits and solid aerobic control. The final kilometer showed noticeably better pacing confidence.", highlights: ["New personal best", "Average pace 5:38/km", "Recovery felt strong"], strengths: ["Controlled start", "Stable cadence", "Strong finish"], improvements: ["Relax shoulders earlier", "Improve hill posture", "Add stride drills weekly"]),
        .init(id: 4, title: "Basketball Pickup", type: "Activity", sport: "Basketball", date: "Mar 28, 2026", duration: "60 min", score: nil, imageURL: "https://images.unsplash.com/photo-1770042572491-0c3f1ca7d6a1?auto=format&fit=crop&w=900&q=80", description: "Competitive pickup run with strong pace, good team play, and several clean late-game possessions.", highlights: ["5 threes made", "7 assists", "Won final game 21-17"], strengths: ["Court vision was sharp", "Spacing improved", "Transition defense recovered quickly"], improvements: ["Need better right-hand finishes", "Box out earlier", "Protect dribble under pressure"])
    ]

    private let achievements: [ProfileAchievement] = [
        .init(id: 1, title: "First Match Won", detail: "Won your first competitive match", icon: "🏆", earned: true, progress: 100),
        .init(id: 2, title: "10 Activities", detail: "Joined 10 community activities", icon: "🎯", earned: true, progress: 100),
        .init(id: 3, title: "Skill Master", detail: "Reached 80+ in any tracked skill", icon: "⚡", earned: true, progress: 100),
        .init(id: 4, title: "30-Day Streak", detail: "Stay active for 30 days straight", icon: "🔥", earned: false, progress: 40),
        .init(id: 5, title: "AI Champion", detail: "Score above 90 in a single session", icon: "🤖", earned: false, progress: 78),
        .init(id: 6, title: "Community Creator", detail: "Host an activity with 100 joins", icon: "🌟", earned: false, progress: 34)
    ]

    @State private var skillGroups: [SportSkillGroup] = [
        .init(id: "tennis", sport: "Tennis", emoji: "🎾", tier: .intermediate, tierLevel: 3, score: 3.0, maxScore: 7.0, tint: .blue, skills: [
            .init(label: "Serve", value: 72),
            .init(label: "Forehand", value: 78),
            .init(label: "Backhand", value: 65),
            .init(label: "Volley", value: 60),
            .init(label: "Movement", value: 74)
        ]),
        .init(id: "basketball", sport: "Basketball", emoji: "🏀", tier: .advanced, tierLevel: 2, score: 2.0, maxScore: 5.0, tint: .orange, skills: [
            .init(label: "Dribbling", value: 55),
            .init(label: "Shooting", value: 48),
            .init(label: "Defense", value: 52),
            .init(label: "Passing", value: 60),
            .init(label: "Athleticism", value: 65)
        ]),
        .init(id: "running", sport: "Running", emoji: "🏃", tier: .beginner, tierLevel: 4, score: 4.0, maxScore: 5.0, tint: .green, skills: [
            .init(label: "Endurance", value: 76),
            .init(label: "Speed", value: 68),
            .init(label: "Form", value: 72),
            .init(label: "Recovery", value: 70),
            .init(label: "Pacing", value: 74)
        ])
    ]

    private let radarSkills: [SkillAxis] = [
        .init(label: "Technique", value: 82),
        .init(label: "Fitness", value: 74),
        .init(label: "Tactics", value: 68),
        .init(label: "Mental", value: 79),
        .init(label: "Social", value: 91),
        .init(label: "Consistency", value: 71)
    ]

    private let followers: [SocialPerson] = [
        .init(id: 1, name: "Jamie Lee", handle: "@jamielee", sport: "Tennis", accent: .blue),
        .init(id: 2, name: "Chris Park", handle: "@chrispark", sport: "Running", accent: .green),
        .init(id: 3, name: "Sam Torres", handle: "@sammyt", sport: "Basketball", accent: .orange),
        .init(id: 4, name: "Dana Kim", handle: "@danakim", sport: "Yoga", accent: .purple)
    ]

    private let following: [SocialPerson] = [
        .init(id: 11, name: "Marcus Chen", handle: "@marcusc", sport: "Tennis", accent: .blue),
        .init(id: 12, name: "Emily Zhang", handle: "@emilyz", sport: "Basketball", accent: .orange),
        .init(id: 13, name: "Alex Rivera", handle: "@arivera", sport: "Running", accent: .green),
        .init(id: 14, name: "Taylor Swift", handle: "@taylorfit", sport: "Yoga", accent: .pink)
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                profileHero
                segmentedTabs
                tabContent
            }
            .padding(.bottom, 24 + MoveMatchPalette.tabBarScrollBottomPadding)
        }
        .background(MoveMatchPalette.background.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .sheet(isPresented: $showingEditSheet) {
            ProfileEditSheet(draft: $editDraft) {
                profile = editDraft
            }
        }
        .sheet(isPresented: $showingFollowersSheet) {
            SocialListSheet(title: "Followers", people: followers)
        }
        .sheet(isPresented: $showingFollowingSheet) {
            SocialListSheet(title: "Following", people: following)
        }
        .sheet(isPresented: $showingShareSheet) {
            ShareSheet(profile: profile)
        }
        .sheet(isPresented: $showingSkillLevelSheet) {
            SkillLevelEditSheet(skillGroups: $skillGroups)
        }
        .sheet(isPresented: $showingBodyMetricsSheet) {
            BodyMetricsSheet(draft: $bodyMetricsDraft) {
                bodyMetrics = bodyMetricsDraft
                bodyMetrics.persist()
            }
        }
        .sheet(item: $selectedActivity) { activity in
            ProfileActivityDetailSheet(activity: activity)
        }
    }

    private var profileHero: some View {
        VStack(spacing: 0) {
            ZStack(alignment: .topTrailing) {
                coverGradients[selectedCoverIndex]
                    .frame(height: 180)
                    .overlay(
                        VStack {
                            Spacer()
                            HStack {
                                Spacer()
                                HStack(spacing: 8) {
                                    ForEach(coverGradients.indices, id: \.self) { index in
                                        Circle()
                                            .fill(index == selectedCoverIndex ? Color.white : Color.white.opacity(0.35))
                                            .frame(width: 8, height: 8)
                                            .onTapGesture {
                                                selectedCoverIndex = index
                                            }
                                    }
                                }
                                .padding(.trailing, 20)
                                .padding(.bottom, 14)
                            }
                        }
                    )

                Button {
                    selectedCoverIndex = (selectedCoverIndex + 1) % coverGradients.count
                } label: {
                    Label("Cover", systemImage: "photo")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(.black.opacity(0.18))
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
                .padding(16)
            }

            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .bottom, spacing: 14) {
                    Circle()
                        .fill(.white)
                        .frame(width: 88, height: 88)
                        .overlay(
                            Circle()
                                .fill(MoveMatchPalette.primary.opacity(0.18))
                                .padding(6)
                                .overlay(
                                    Image(systemName: "person.fill")
                                        .font(.title)
                                        .foregroundStyle(MoveMatchPalette.primary)
                                )
                        )
                        .overlay(alignment: .bottomTrailing) {
                            Circle()
                                .fill(MoveMatchPalette.primary)
                                .frame(width: 28, height: 28)
                                .overlay(Image(systemName: "camera.fill").font(.caption).foregroundStyle(.white))
                        }
                        .offset(y: -28)
                        .padding(.bottom, -28)

                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 8) {
                            Text(profile.name)
                                .font(.title2.bold())
                                .foregroundStyle(MoveMatchPalette.textOnCard)
                            Image(systemName: "checkmark.seal.fill")
                                .foregroundStyle(.blue)
                        }
                        Text("\(profile.handle) · \(primarySkillSummary)")
                            .font(.subheadline)
                            .foregroundStyle(MoveMatchPalette.textOnCardMuted)
                        Label(profile.location, systemImage: "mappin.and.ellipse")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(MoveMatchPalette.textOnCardMuted)
                    }

                    Spacer()
                }

                Text(profile.bio)
                    .font(.subheadline)
                    .foregroundStyle(MoveMatchPalette.textOnCardMuted)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(profile.tags, id: \.self) { tag in
                            Text(tag)
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(MoveMatchPalette.textOnCard)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(Color(red: 0.94, green: 0.95, blue: 0.97))
                                .clipShape(Capsule())
                        }
                    }
                }

                HStack(spacing: 12) {
                    profileStat(title: "Activities", value: "24") {
                        activeTab = .activities
                    }
                    profileStat(title: "Followers", value: "183") {
                        showingFollowersSheet = true
                    }
                    profileStat(title: "Following", value: "97") {
                        showingFollowingSheet = true
                    }
                    profileStat(title: "Streak", value: "12d") {}
                }

                HStack(spacing: 10) {
                    Button {
                        editDraft = profile
                        showingEditSheet = true
                    } label: {
                        Label("Edit", systemImage: "square.and.pencil")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(ProfileActionButtonStyle(background: .white, foreground: MoveMatchPalette.textOnCard))

                    Button {
                        showingShareSheet = true
                    } label: {
                        Label("Share", systemImage: "square.and.arrow.up.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(ProfileActionButtonStyle(background: MoveMatchPalette.primary, foreground: .white))
                }

                Button {
                    bodyMetricsDraft = bodyMetrics
                    showingBodyMetricsSheet = true
                } label: {
                    HStack {
                        Label("Body Metrics", systemImage: "figure.arms.open")
                        Spacer()
                        Text(bodyMetrics.summaryLine)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(MoveMatchPalette.textOnCardMuted)
                            .lineLimit(1)
                    }
                    .foregroundStyle(MoveMatchPalette.textOnCard)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)
                    .background(Color(red: 0.94, green: 0.95, blue: 0.97))
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
                .buttonStyle(.plain)
            }
            .padding(20)
            .background(.white)
        }
    }

    private var segmentedTabs: some View {
        HStack(spacing: 8) {
            ForEach(EnhancedProfileTab.allCases, id: \.self) { tab in
                Button {
                    activeTab = tab
                } label: {
                    Text(tab.rawValue)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(activeTab == tab ? Color.white : MoveMatchPalette.textOnCard)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 11)
                        .background(activeTab == tab ? MoveMatchPalette.primary : .white)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(8)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .padding(.horizontal, 20)
    }

    @ViewBuilder
    private var tabContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            switch activeTab {
            case .overview:
                overviewTab
            case .activities:
                activitiesTab
            case .skills:
                skillsTab
            case .awards:
                awardsTab
            }
        }
        .padding(.horizontal, 20)
    }

    private var overviewTab: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Label("Body Metrics for AI Coach", systemImage: "figure.strengthtraining.traditional")
                        .font(.headline)
                    Spacer()
                    Button("Edit") {
                        bodyMetricsDraft = bodyMetrics
                        showingBodyMetricsSheet = true
                    }
                    .font(.caption.weight(.bold))
                    .foregroundStyle(MoveMatchPalette.primaryDark)
                }
                bodyMetricsSnapshot
            }
            .padding(16)
            .background(.white)
            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))

            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 12) {
                    Label("Skill Progress", systemImage: "chart.line.uptrend.xyaxis")
                        .font(.headline)
                        .foregroundStyle(MoveMatchPalette.textOnCard)

                    Chart(progressPoints, id: \.month) { item in
                        AreaMark(
                            x: .value("Month", item.month),
                            y: .value("Score", item.score)
                        )
                        .foregroundStyle(MoveMatchPalette.primary.opacity(0.18))

                        LineMark(
                            x: .value("Month", item.month),
                            y: .value("Score", item.score)
                        )
                        .foregroundStyle(MoveMatchPalette.primary)
                        .lineStyle(.init(lineWidth: 3))

                        PointMark(
                            x: .value("Month", item.month),
                            y: .value("Score", item.score)
                        )
                        .foregroundStyle(MoveMatchPalette.primaryDark)
                    }
                    .frame(height: 180)
                    .chartYScale(domain: 40 ... 100)
                    .chartXAxis {
                        AxisMarks { value in
                            AxisValueLabel {
                                if let m = value.as(String.self) {
                                    Text(m)
                                        .font(.caption.weight(.semibold))
                                        .foregroundStyle(MoveMatchPalette.textOnCard)
                                }
                            }
                        }
                    }
                    .chartYAxis {
                        AxisMarks(position: .trailing) { value in
                            AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                                .foregroundStyle(Color.black.opacity(0.08))
                            AxisValueLabel {
                                if let n = value.as(Int.self) {
                                    Text("\(n)")
                                        .font(.caption.weight(.semibold))
                                        .foregroundStyle(MoveMatchPalette.textOnCard)
                                }
                            }
                        }
                    }
                }
                .padding(18)
                .background(.white)
                .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            }

            HStack(spacing: 14) {
                metricCard("AI Score", value: "847", tint: .green)
                metricCard("Win Rate", value: "67%", tint: .blue)
                metricCard("Sessions", value: "9/mo", tint: .orange)
            }

            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    HStack(spacing: 8) {
                        Image(systemName: "clock.arrow.circlepath")
                            .font(.headline)
                        Text("Recent Activity")
                            .font(.headline)
                    }
                    .foregroundStyle(MoveMatchPalette.textOnCard)
                    Spacer()
                    Button("View all") {
                        activeTab = .activities
                    }
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(MoveMatchPalette.primaryDark)
                }

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    ForEach(activities.prefix(4)) { activity in
                        Button {
                            selectedActivity = activity
                        } label: {
                            ProfileActivityTile(activity: activity)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private var bodyMetricsSnapshot: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
            metricCell(title: "Height", value: bodyMetrics.heightCm.isEmpty ? "--" : "\(bodyMetrics.heightCm) cm")
            metricCell(title: "Weight", value: bodyMetrics.weightKg.isEmpty ? "--" : "\(bodyMetrics.weightKg) kg")
            metricCell(title: "Chest", value: bodyMetrics.chestCm.isEmpty ? "--" : "\(bodyMetrics.chestCm) cm")
            metricCell(title: "Waist", value: bodyMetrics.waistCm.isEmpty ? "--" : "\(bodyMetrics.waistCm) cm")
            metricCell(title: "Hip", value: bodyMetrics.hipCm.isEmpty ? "--" : "\(bodyMetrics.hipCm) cm")
            metricCell(title: "Arm Span", value: bodyMetrics.armSpanCm.isEmpty ? "--" : "\(bodyMetrics.armSpanCm) cm")
        }
    }

    private func metricCell(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(MoveMatchPalette.textOnCardMuted)
            Text(value)
                .font(.subheadline.weight(.bold))
                .foregroundStyle(MoveMatchPalette.textOnCard)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(Color(red: 0.96, green: 0.97, blue: 0.99))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private var activitiesTab: some View {
        VStack(alignment: .leading, spacing: 14) {
            summaryBanner(
                icon: "figure.run",
                title: "24 Activities Total",
                subtitle: "A complete view of your sessions, matches, AI reviews, and social sports history."
            )

            ForEach(activities) { activity in
                Button {
                    selectedActivity = activity
                } label: {
                    HStack(spacing: 14) {
                        RemoteImageCard(urlString: activity.imageURL)
                            .frame(width: 84, height: 84)

                        VStack(alignment: .leading, spacing: 5) {
                            HStack {
                                Text(activity.title)
                                    .font(.headline)
                                Spacer()
                                Text(activity.type)
                                    .font(.caption.weight(.bold))
                                    .foregroundStyle(typeTint(activity.type))
                            }
                            Text("\(activity.date) · \(activity.duration)")
                                .font(.caption)
                                .foregroundStyle(MoveMatchPalette.textSecondary)

                            Text(activity.description)
                                .font(.footnote)
                                .foregroundStyle(MoveMatchPalette.textSecondary)
                                .lineLimit(2)

                            if let score = activity.score {
                                Text("AI Score \(score)")
                                    .font(.caption.weight(.bold))
                                    .foregroundStyle(MoveMatchPalette.primaryDark)
                            }
                        }
                    }
                    .padding(14)
                    .background(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var skillsTab: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Label("Overall Skill Radar", systemImage: "scope")
                        .font(.headline)
                    Spacer()
                    Button("Edit Levels") {
                        showingSkillLevelSheet = true
                    }
                    .font(.caption.weight(.bold))
                    .foregroundStyle(MoveMatchPalette.primaryDark)
                }
                RadarChartView(skills: radarSkills, tint: MoveMatchPalette.primary)
                    .frame(height: 260)
            }
            .padding(18)
            .background(.white)
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))

            ForEach(skillGroups) { group in
                VStack(alignment: .leading, spacing: 14) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("\(group.emoji) \(group.sport)")
                                .font(.headline)
                            Text(group.levelLabel)
                                .font(.caption.weight(.bold))
                                .foregroundStyle(group.tint)
                        }
                        Spacer()
                        Text(String(format: "%.1f / %.1f", group.score, group.maxScore))
                            .font(.title3.bold())
                            .foregroundStyle(group.tint)
                    }

                    ProgressView(value: group.score, total: group.maxScore)
                        .tint(group.tint)

                    ForEach(group.skills) { skill in
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Text(skill.label)
                                    .font(.subheadline)
                                Spacer()
                                Text("\(Int(skill.value))")
                                    .font(.caption.weight(.bold))
                                    .foregroundStyle(group.tint)
                            }
                            ProgressView(value: skill.value, total: 100)
                                .tint(group.tint.opacity(0.75))
                        }
                    }
                }
                .padding(18)
                .background(.white)
                .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            }

            summaryBanner(
                icon: "lightbulb.fill",
                title: "Next Focus",
                subtitle: "Your tennis volley and basketball shooting mechanics are the two fastest paths to visible score improvement."
            )
        }
    }

    private var awardsTab: some View {
        VStack(alignment: .leading, spacing: 16) {
            summaryBanner(
                icon: "trophy.fill",
                title: "4 of 6 awards unlocked",
                subtitle: "You are halfway to the next milestone set. Keep streaks and skill sessions consistent."
            )

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(achievements) { achievement in
                    VStack(alignment: .leading, spacing: 12) {
                        Text(achievement.earned ? achievement.icon : "🔒")
                            .font(.system(size: 30))
                        Text(achievement.title)
                            .font(.headline)
                        Text(achievement.detail)
                            .font(.footnote)
                            .foregroundStyle(MoveMatchPalette.textSecondary)
                            .lineLimit(3)

                        if achievement.earned {
                            Text("Unlocked")
                                .font(.caption.weight(.bold))
                                .foregroundStyle(.green)
                        } else {
                            ProgressView(value: Double(achievement.progress), total: 100)
                                .tint(.orange)
                            Text("\(achievement.progress)% complete")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.orange)
                        }
                    }
                    .frame(maxWidth: .infinity, minHeight: 180, alignment: .topLeading)
                    .padding(16)
                    .background(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                    .opacity(achievement.earned ? 1 : 0.82)
                }
            }
        }
    }

    private func profileStat(title: String, value: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Text(value)
                    .font(.headline.bold())
                    .foregroundStyle(MoveMatchPalette.primaryDark)
                Text(title)
                    .font(.caption)
                    .foregroundStyle(MoveMatchPalette.textOnCardMuted)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(Color.white.opacity(0.96))
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private func metricCard(_ title: String, value: String, tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption)
                .foregroundStyle(MoveMatchPalette.textOnCardMuted)
            Text(value)
                .font(.title3.bold())
                .foregroundStyle(tint)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
    }

    private func summaryBanner(icon: String, title: String, subtitle: String) -> some View {
        HStack(alignment: .top, spacing: 14) {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(MoveMatchPalette.primary.opacity(0.16))
                .frame(width: 48, height: 48)
                .overlay(Image(systemName: icon).foregroundStyle(MoveMatchPalette.primary))
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(MoveMatchPalette.textOnCard)
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(MoveMatchPalette.textOnCardMuted)
            }
        }
        .padding(16)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
    }

    private func typeTint(_ type: String) -> Color {
        switch type {
        case "AI Session":
            return .purple
        case "Tournament":
            return .orange
        case "Training":
            return .blue
        default:
            return MoveMatchPalette.primaryDark
        }
    }

    private var primarySkillSummary: String {
        skillGroups.prefix(2).map { "\($0.sport) \($0.levelLabel)" }.joined(separator: " · ")
    }
}

private struct EditableProfile {
    var name: String
    var handle: String
    var location: String
    var bio: String
    var tags: [String]
}

private struct AthleteBodyMetrics {
    var heightCm: String = ""
    var weightKg: String = ""
    var chestCm: String = ""
    var waistCm: String = ""
    var hipCm: String = ""
    var armSpanCm: String = ""

    static let heightKey = "movematch.profile.body.height_cm"
    static let weightKey = "movematch.profile.body.weight_kg"
    static let chestKey = "movematch.profile.body.chest_cm"
    static let waistKey = "movematch.profile.body.waist_cm"
    static let hipKey = "movematch.profile.body.hip_cm"
    static let armSpanKey = "movematch.profile.body.arm_span_cm"

    static func load() -> AthleteBodyMetrics {
        let defaults = UserDefaults.standard
        return AthleteBodyMetrics(
            heightCm: defaults.string(forKey: heightKey) ?? "",
            weightKg: defaults.string(forKey: weightKey) ?? "",
            chestCm: defaults.string(forKey: chestKey) ?? "",
            waistCm: defaults.string(forKey: waistKey) ?? "",
            hipCm: defaults.string(forKey: hipKey) ?? "",
            armSpanCm: defaults.string(forKey: armSpanKey) ?? ""
        )
    }

    func persist() {
        let defaults = UserDefaults.standard
        defaults.set(heightCm, forKey: Self.heightKey)
        defaults.set(weightKg, forKey: Self.weightKey)
        defaults.set(chestCm, forKey: Self.chestKey)
        defaults.set(waistCm, forKey: Self.waistKey)
        defaults.set(hipCm, forKey: Self.hipKey)
        defaults.set(armSpanCm, forKey: Self.armSpanKey)
    }

    var summaryLine: String {
        let parts = [
            heightCm.isEmpty ? nil : "H \(heightCm)cm",
            weightKg.isEmpty ? nil : "W \(weightKg)kg",
            armSpanCm.isEmpty ? nil : "Arm \(armSpanCm)cm"
        ].compactMap { $0 }
        return parts.isEmpty ? "Not set" : parts.joined(separator: " · ")
    }
}

private struct DiscoverActivityCard: View {
    let activity: DiscoverActivity
    let joined: Bool
    let displayedParticipants: Int
    let onTap: () -> Void
    let onJoin: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 0) {
                ZStack(alignment: .topLeading) {
                    RemoteImageCard(urlString: activity.imageURL)
                        .frame(height: 118)

                    VStack(alignment: .leading, spacing: 0) {
                        HStack(spacing: 6) {
                            if activity.verified {
                                Text("Verified")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundStyle(.black)
                                    .padding(.horizontal, 7)
                                    .padding(.vertical, 4)
                                    .background(MoveMatchPalette.primary)
                                    .clipShape(Capsule())
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.7)
                                    .layoutPriority(2)
                            }

                            Text(activity.level)
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(.black)
                                .padding(.horizontal, 7)
                                .padding(.vertical, 4)
                                .background(levelBadgeColor)
                                .clipShape(Capsule())
                                .lineLimit(1)
                                .minimumScaleFactor(0.65)
                                .layoutPriority(1)

                            Spacer(minLength: 4)

                            Label(activity.distance, systemImage: "location.circle.fill")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 7)
                                .padding(.vertical, 4)
                                .background(.black.opacity(0.42))
                                .clipShape(Capsule())
                                .lineLimit(1)
                                .minimumScaleFactor(0.7)
                                .layoutPriority(2)
                        }

                        Spacer()
                    }
                    .padding(8)
                }

                VStack(alignment: .leading, spacing: 8) {
                    HStack(alignment: .top, spacing: 6) {
                        Text(activity.title)
                            .font(.subheadline.bold())
                            .foregroundStyle(MoveMatchPalette.textOnCard)
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)

                        Spacer(minLength: 4)

                        Label(String(format: "%.1f", activity.rating), systemImage: "star.fill")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(.orange)
                    }

                    Text("by \(activity.organizer)")
                        .font(.footnote.weight(.medium))
                        .foregroundStyle(MoveMatchPalette.textOnCardMuted)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)

                    VStack(alignment: .leading, spacing: 6) {
                        Label(activity.location, systemImage: "mappin.and.ellipse")
                        Label(activity.time, systemImage: "clock")
                    }
                    .font(.footnote.weight(.regular))
                    .foregroundStyle(MoveMatchPalette.textOnCardMuted)
                    .lineLimit(1)

                    HStack(spacing: 8) {
                        Label("\(displayedParticipants)/\(activity.maxParticipants)", systemImage: "person.2")
                            .font(.caption.weight(.medium))
                            .foregroundStyle(MoveMatchPalette.textOnCardMuted)

                        ProgressView(value: Double(displayedParticipants), total: Double(activity.maxParticipants))
                            .tint(MoveMatchPalette.primary)
                    }

                    Button(action: onJoin) {
                        Text(joined ? "Joined" : "Join")
                            .font(.footnote.weight(.bold))
                            .foregroundStyle(joined ? .white : MoveMatchPalette.primaryDark)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .background(joined ? MoveMatchPalette.primaryDark : MoveMatchPalette.primary.opacity(0.14))
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)

                    HStack(spacing: 8) {
                        ForEach(activity.tags.prefix(2), id: \.self) { tag in
                            Text(tag)
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundStyle(MoveMatchPalette.textOnCardMuted)
                                .padding(.horizontal, 7)
                                .padding(.vertical, 4)
                                .background(Color(red: 0.90, green: 0.91, blue: 0.94))
                                .clipShape(Capsule())
                                .lineLimit(1)
                        }
                    }
                }
                .padding(10)
                .background(.white)
            }
            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .stroke(Color.black.opacity(0.05), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 4)
        }
        .buttonStyle(.plain)
    }

    private var levelBadgeColor: Color {
        if activity.level.contains("Advanced") {
            return Color.orange.opacity(0.95)
        } else if activity.level.contains("Intermediate") {
            return Color.blue.opacity(0.92)
        } else if activity.level.contains("Beginner") {
            return MoveMatchPalette.primary.opacity(0.9)
        } else {
            return Color.purple.opacity(0.9)
        }
    }
}

private struct DiscoverActivityDetailSheet: View {
    let activity: DiscoverActivity
    let joined: Bool
    let displayedParticipants: Int
    let onJoin: () -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    RemoteImageCard(urlString: activity.imageURL)
                        .frame(height: 240)
                        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))

                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text(activity.title)
                                .font(.largeTitle.bold())
                                .foregroundStyle(MoveMatchPalette.textOnCard)
                            Text("by \(activity.organizer)")
                                .font(.headline)
                                .foregroundStyle(MoveMatchPalette.textOnCardMuted)
                        }
                        Spacer()
                        Label(String(format: "%.1f", activity.rating), systemImage: "star.fill")
                            .font(.headline.weight(.bold))
                            .foregroundStyle(.orange)
                    }

                    detailInfoGrid

                    Text("MoveMatch AI recommends this activity because it matches your recent sport history, current skill tier, and preferred session intensity. This is a strong option if you want social practice plus measurable progress.")
                        .font(.body)
                        .foregroundStyle(MoveMatchPalette.textSecondary)

                    WrapTagRow(tags: activity.tags)

                    Button {
                        onJoin()
                    } label: {
                        Text(joined ? "Leave Activity" : "Join Activity")
                            .font(.headline.bold())
                            .foregroundStyle(joined ? .red : .white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(joined ? .red.opacity(0.10) : MoveMatchPalette.primary)
                            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                    }
                    .buttonStyle(.plain)
                }
                .padding(20)
            }
            .background(MoveMatchPalette.background.ignoresSafeArea())
            .navigationTitle("Activity Details")
            .platformInlineNavigationBarTitle()
            .toolbar {
                ToolbarItem(placement: .platformTopBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    private var detailInfoGrid: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                detailBox(title: "Time", value: activity.time, icon: "clock.fill")
                detailBox(title: "Distance", value: activity.distance, icon: "location.fill")
            }
            HStack(spacing: 12) {
                detailBox(title: "Level", value: activity.level, icon: "bolt.fill")
                detailBox(title: "Participants", value: "\(displayedParticipants)/\(activity.maxParticipants)", icon: "person.2.fill")
            }
        }
    }

    private func detailBox(title: String, value: String, icon: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Label(title, systemImage: icon)
                .font(.caption.weight(.bold))
                .foregroundStyle(MoveMatchPalette.textOnCardMuted)
            Text(value)
                .font(.headline)
                .foregroundStyle(MoveMatchPalette.textOnCard)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}

private struct ProfileActivityTile: View {
    let activity: ProfileActivity

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            RemoteImageCard(urlString: activity.imageURL)
                .frame(height: 132)
                .clipped()

            VStack(alignment: .leading, spacing: 6) {
                Text(activity.title)
                    .font(.headline)
                    .foregroundStyle(MoveMatchPalette.textOnCard)
                    .lineLimit(1)
                Text(activity.date)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(MoveMatchPalette.textOnCardMuted)
                if let score = activity.score {
                    Text("AI Score \(score)")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(MoveMatchPalette.primaryDark)
                } else {
                    Text(activity.type)
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.orange)
                }
            }
            .frame(maxWidth: .infinity, minHeight: 88, maxHeight: 88, alignment: .topLeading)
            .padding(12)
        }
        .frame(maxWidth: .infinity, minHeight: 220, maxHeight: 220, alignment: .top)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }
}

private struct ProfileActivityDetailSheet: View {
    let activity: ProfileActivity
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    RemoteImageCard(urlString: activity.imageURL)
                        .frame(height: 240)
                        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))

                    VStack(alignment: .leading, spacing: 8) {
                        Text(activity.title)
                            .font(.largeTitle.bold())
                        Text("\(activity.type) · \(activity.date) · \(activity.duration)")
                            .font(.subheadline)
                            .foregroundStyle(MoveMatchPalette.textSecondary)
                        if let score = activity.score {
                            Text("AI Score \(score)")
                                .font(.headline.weight(.bold))
                                .foregroundStyle(MoveMatchPalette.primaryDark)
                        }
                    }

                    detailSection("Summary", body: activity.description)
                    bulletSection("Highlights", items: activity.highlights, tint: .orange)
                    bulletSection("Strengths", items: activity.strengths, tint: .green)
                    bulletSection("Improvements", items: activity.improvements, tint: .red)
                }
                .padding(20)
            }
            .navigationTitle("Activity")
            .platformInlineNavigationBarTitle()
            .toolbar {
                ToolbarItem(placement: .platformTopBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    private func detailSection(_ title: String, body: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
            Text(body)
                .font(.body)
                .foregroundStyle(MoveMatchPalette.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
    }

    private func bulletSection(_ title: String, items: [String], tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.headline)
            ForEach(items, id: \.self) { item in
                HStack(alignment: .top, spacing: 8) {
                    Circle()
                        .fill(tint)
                        .frame(width: 8, height: 8)
                        .padding(.top, 6)
                    Text(item)
                        .font(.subheadline)
                        .foregroundStyle(MoveMatchPalette.textSecondary)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
    }
}

private struct ProfileEditSheet: View {
    @Binding var draft: EditableProfile
    let onSave: () -> Void
    @Environment(\.dismiss) private var dismiss

    private let allTags = ["🎾 Tennis", "🏀 Basketball", "🏃 Running", "🏊 Swimming", "⛳ Golf", "🧘 Yoga"]

    var body: some View {
        NavigationStack {
            Form {
                Section("Profile") {
                    TextField("Name", text: $draft.name)
                    TextField("Handle", text: $draft.handle)
                    TextField("Location", text: $draft.location)
                    TextField("Bio", text: $draft.bio, axis: .vertical)
                        .lineLimit(4, reservesSpace: true)
                }

                Section("Sport tags") {
                    ForEach(allTags, id: \.self) { tag in
                        Button {
                            if draft.tags.contains(tag) {
                                draft.tags.removeAll { $0 == tag }
                            } else if draft.tags.count < 3 {
                                draft.tags.append(tag)
                            }
                        } label: {
                            HStack {
                                Text(tag)
                                    .foregroundStyle(MoveMatchPalette.textOnCard)
                                Spacer()
                                if draft.tags.contains(tag) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(MoveMatchPalette.primary)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Edit Profile")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        onSave()
                        dismiss()
                    }
                }
            }
        }
    }
}

private struct BodyMetricsSheet: View {
    @Binding var draft: AthleteBodyMetrics
    let onSave: () -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section("Core") {
                    TextField("Height (cm)", text: $draft.heightCm)
                        .keyboardType(.decimalPad)
                    TextField("Weight (kg)", text: $draft.weightKg)
                        .keyboardType(.decimalPad)
                    TextField("Arm span (cm)", text: $draft.armSpanCm)
                        .keyboardType(.decimalPad)
                }

                Section("Measurements") {
                    TextField("Chest (cm)", text: $draft.chestCm)
                        .keyboardType(.decimalPad)
                    TextField("Waist (cm)", text: $draft.waistCm)
                        .keyboardType(.decimalPad)
                    TextField("Hip (cm)", text: $draft.hipCm)
                        .keyboardType(.decimalPad)
                }

                Section {
                    Text("These values are self-reported and will be used by AI Coach to tailor workload and movement suggestions.")
                        .font(.caption)
                        .foregroundStyle(MoveMatchPalette.textSecondary)
                }
            }
            .navigationTitle("Body Metrics")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        onSave()
                        dismiss()
                    }
                }
            }
        }
    }
}

private struct SkillLevelEditSheet: View {
    @Binding var skillGroups: [SportSkillGroup]
    @Environment(\.dismiss) private var dismiss
    private let ustaRatings = Array(stride(from: 1.0, through: 7.0, by: 0.5))

    var body: some View {
        NavigationStack {
            Form {
                Section("Skill Level") {
                    Text("Use USTA 1.0-7.0 for tennis. Other sports still use three tiers and five steps per tier.")
                        .font(.caption)
                        .foregroundStyle(MoveMatchPalette.textSecondary)
                }

                ForEach(skillGroups.indices, id: \.self) { index in
                    Section("\(skillGroups[index].emoji) \(skillGroups[index].sport)") {
                        if skillGroups[index].usesUSTARating {
                            Picker("USTA Rating", selection: $skillGroups[index].score) {
                                ForEach(ustaRatings, id: \.self) { rating in
                                    Text(String(format: "USTA %.1f", rating)).tag(rating)
                                }
                            }
                        } else {
                            Picker("Tier", selection: $skillGroups[index].tier) {
                                ForEach(SkillTier.allCases) { tier in
                                    Text(tier.title).tag(tier)
                                }
                            }

                            Picker("Level", selection: $skillGroups[index].tierLevel) {
                                ForEach(1 ... 5, id: \.self) { level in
                                    Text("\(level).0").tag(level)
                                }
                            }
                        }

                        Text("Current: \(skillGroups[index].levelLabel)")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(skillGroups[index].tint)
                    }
                }
            }
            .navigationTitle("Edit Skill Levels")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { dismiss() }
                }
            }
        }
    }
}

private struct SocialListSheet: View {
    let title: String
    let people: [SocialPerson]
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List(people) { person in
                HStack(spacing: 12) {
                    Circle()
                        .fill(person.accent.opacity(0.18))
                        .frame(width: 46, height: 46)
                        .overlay(Text(String(person.name.prefix(1))).font(.headline).foregroundStyle(person.accent))
                    VStack(alignment: .leading, spacing: 2) {
                        Text(person.name)
                            .font(.headline)
                        Text("\(person.handle) · \(person.sport)")
                            .font(.caption)
                            .foregroundStyle(MoveMatchPalette.textSecondary)
                    }
                    Spacer()
                    Button("Follow") {}
                        .buttonStyle(.borderedProminent)
                        .tint(MoveMatchPalette.primary)
                }
                .listRowSeparator(.hidden)
            }
            .listStyle(.plain)
            .navigationTitle(title)
            .toolbar {
                ToolbarItem(placement: .platformTopBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

private struct ShareSheet: View {
    let profile: EditableProfile
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Share Profile")
                        .font(.title.bold())
                    Text("Invite friends to view your sports identity, skills, and progress.")
                        .foregroundStyle(MoveMatchPalette.textSecondary)
                }

                HStack(spacing: 14) {
                    shareIcon("link", title: "Copy Link")
                    shareIcon("message.fill", title: "Messages")
                    shareIcon("camera.fill", title: "Instagram")
                    shareIcon("bubble.left.and.bubble.right.fill", title: "WeChat")
                }

                ShareLink(item: URL(string: "https://movematch.ai/profile/\(profile.handle.replacingOccurrences(of: "@", with: ""))")!) {
                    Text("Open iOS Share Sheet")
                        .font(.headline.bold())
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(MoveMatchPalette.primary)
                        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                }
                .buttonStyle(.plain)

                Spacer()
            }
            .padding(20)
            .navigationTitle("Share")
            .toolbar {
                ToolbarItem(placement: .platformTopBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    private func shareIcon(_ systemName: String, title: String) -> some View {
        VStack(spacing: 8) {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(MoveMatchPalette.primary.opacity(0.14))
                .frame(width: 64, height: 64)
                .overlay(Image(systemName: systemName).font(.title3).foregroundStyle(MoveMatchPalette.primaryDark))
            Text(title)
                .font(.caption.weight(.semibold))
        }
        .frame(maxWidth: .infinity)
    }
}

private struct WrapTagRow: View {
    let tags: [String]

    var body: some View {
        HStack(spacing: 8) {
            ForEach(tags, id: \.self) { tag in
                Text(tag)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(MoveMatchPalette.textOnCardMuted)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color(red: 0.90, green: 0.91, blue: 0.94))
                    .clipShape(Capsule())
            }
        }
    }
}

private struct ProfileActionButtonStyle: ButtonStyle {
    let background: Color
    let foreground: Color

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.subheadline.weight(.bold))
            .foregroundStyle(foreground)
            .padding(.vertical, 12)
            .padding(.horizontal, 14)
            .background(background.opacity(configuration.isPressed ? 0.85 : 1))
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}

private struct SimpleMetricCard: View {
    let title: String
    let value: String
    let tint: Color
    let icon: String

    var body: some View {
        VStack(spacing: 10) {
            Circle()
                .fill(tint.opacity(0.10))
                .frame(width: 42, height: 42)
                .overlay(
                    Image(systemName: icon)
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(tint)
                )
            Text(value)
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(MoveMatchPalette.textOnCard)
            Text(title)
                .font(.caption.weight(.medium))
                .foregroundStyle(MoveMatchPalette.textOnCardMuted)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .padding(.horizontal, 10)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(Color.black.opacity(0.04), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.06), radius: 10, x: 0, y: 4)
    }
}

private struct SharedSummaryBanner: View {
    let icon: String
    let title: String
    let subtitle: String

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(MoveMatchPalette.primary.opacity(0.16))
                .frame(width: 48, height: 48)
                .overlay(Image(systemName: icon).foregroundStyle(MoveMatchPalette.primary))
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(MoveMatchPalette.textSecondary)
            }
        }
        .padding(16)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
    }
}

private struct RemoteImageCard: View {
    let urlString: String

    var body: some View {
        AsyncImage(url: URL(string: urlString)) { phase in
            switch phase {
            case let .success(image):
                image
                    .resizable()
                    .scaledToFill()
            case .failure:
                placeholder
            case .empty:
                placeholder.overlay(ProgressView())
            @unknown default:
                placeholder
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    private var placeholder: some View {
        RoundedRectangle(cornerRadius: 20, style: .continuous)
            .fill(LinearGradient(colors: [Color.gray.opacity(0.16), Color.gray.opacity(0.08)], startPoint: .topLeading, endPoint: .bottomTrailing))
            .overlay(Image(systemName: "photo").foregroundStyle(MoveMatchPalette.textOnCardMuted))
    }
}

private struct RadarChartView: View {
    let skills: [SkillAxis]
    let tint: Color

    var body: some View {
        GeometryReader { geo in
            let size = min(geo.size.width, geo.size.height)
            let center = CGPoint(x: geo.size.width / 2, y: geo.size.height / 2)
            let radius = size * 0.32

            ZStack {
                ForEach(1 ... 4, id: \.self) { ring in
                    PolygonShape(points: normalizedPoints(radiusScale: CGFloat(ring) / 4))
                        .stroke(Color.gray.opacity(0.18), lineWidth: 1)
                        .frame(width: radius * 2, height: radius * 2)
                        .position(center)
                }

                ForEach(Array(skills.enumerated()), id: \.offset) { index, _ in
                    Path { path in
                        path.move(to: center)
                        path.addLine(to: point(for: index, value: 100, center: center, radius: radius))
                    }
                    .stroke(Color.gray.opacity(0.18), lineWidth: 1)
                }

                PolygonShape(points: skillPoints())
                    .fill(tint.opacity(0.18))
                    .overlay(
                        PolygonShape(points: skillPoints())
                            .stroke(tint, lineWidth: 3)
                    )
                    .frame(width: radius * 2, height: radius * 2)
                    .position(center)

                ForEach(Array(skills.enumerated()), id: \.offset) { index, skill in
                    Circle()
                        .fill(tint)
                        .frame(width: 8, height: 8)
                        .position(point(for: index, value: skill.value, center: center, radius: radius))

                    Text(skill.label)
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(MoveMatchPalette.textSecondary)
                        .position(labelPoint(for: index, center: center, radius: radius + 34))
                }
            }
        }
    }

    private func normalizedPoints(radiusScale: CGFloat) -> [CGPoint] {
        (0 ..< skills.count).map { index in
            let angle = angleForIndex(index)
            return CGPoint(x: 0.5 + cos(angle) * 0.5 * radiusScale, y: 0.5 + sin(angle) * 0.5 * radiusScale)
        }
    }

    private func skillPoints() -> [CGPoint] {
        (0 ..< skills.count).map { index in
            let valueScale = CGFloat(skills[index].value / 100)
            let angle = angleForIndex(index)
            return CGPoint(x: 0.5 + cos(angle) * 0.5 * valueScale, y: 0.5 + sin(angle) * 0.5 * valueScale)
        }
    }

    private func angleForIndex(_ index: Int) -> CGFloat {
        let fraction = CGFloat(index) / CGFloat(max(skills.count, 1))
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

private struct PolygonShape: Shape {
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

private enum CoachMarketplaceTab: String, CaseIterable {
    case coaches = "Coaches"
    case calendar = "Calendar"
}

private struct CoachMarketplaceItem: Identifiable, Hashable {
    let id: Int
    let name: String
    let title: String
    let sports: [String]
    let rating: Double
    let reviews: Int
    let location: String
    let distance: String
    let price: Int
    let experience: String
    let verified: Bool
    let aiVerified: Bool
    let available: Bool
    let students: Int
    let imageURL: String
    let badges: [String]
    let bio: String
    let availability: [String]
    let sessionTypes: [String]
}

private struct CoachBookedSession: Identifiable, Hashable {
    let id = UUID()
    let coach: CoachMarketplaceItem
    let date: String
    let time: String
    let sessionType: String
}

private enum CompeteTab: String, CaseIterable {
    case tournaments = "Tournaments"
    case leaderboard = "Leaderboard"
    case mine = "Mine"

    var icon: String {
        switch self {
        case .tournaments:
            return "trophy.fill"
        case .leaderboard:
            return "chart.bar.fill"
        case .mine:
            return "star.fill"
        }
    }
}

private struct ChallengeItem: Identifiable, Hashable {
    let id: Int
    let title: String
    let creator: String
    let prize: String
    let type: String
    let imageURL: String
    let description: String
    let daysLeft: Int
    let baseParticipants: Int
}

private struct TournamentItem: Identifiable, Hashable {
    let id: Int
    let title: String
    let sport: String
    let emoji: String
    let type: String
    let level: String
    let imageURL: String
    let prize: String
    let baseParticipants: Int
    let maxParticipants: Int
    let location: String
    let date: String
    let registrationEnd: String
    let organizer: String
    let status: String
    let rounds: [String]
    let entryFee: Int
    let description: String
}

private struct LeaderboardAthlete: Identifiable {
    let id = UUID()
    let rank: Int
    let name: String
    let sport: String
    let score: Int
    let wins: Int
    let trend: String
    let isMe: Bool
}

private enum CommunityTab: String, CaseIterable {
    case forYou = "For You"
    case following = "Following"
    case challenges = "Challenges"
    case explore = "Explore Sports"
}

private enum CommunityCategory: String, CaseIterable {
    case all = "All"
    case nearby = "Nearby"
    case training = "Training"
    case science = "Science"
    case nutrition = "Nutrition"
    case lifestyle = "Lifestyle"
}

private struct CommunityPost: Identifiable, Hashable {
    let id: Int
    let userName: String
    let handle: String
    let avatarSeed: String
    let location: String
    let content: String
    let imageURL: String?
    let thumbnailURL: String?
    let tags: [String]
    let likes: Int
    let comments: Int
    let shares: Int
    let time: String
    let category: CommunityCategory
    let aiScore: Int?
}

private struct CommunityStory: Identifiable, Hashable {
    let id: Int
    let name: String
    let avatarSeed: String
    let active: Bool
}

private struct CommunityChallenge: Identifiable, Hashable {
    let id: Int
    let title: String
    let subtitle: String
    let imageURL: String
    let joinedCount: Int
    let prize: String
    let description: String
    let submissions: Int
    let topScore: Int
    let tags: [String]
    let isHot: Bool
    let creatorType: String
}

private struct ExploreSportCard: Identifiable, Hashable {
    let id: Int
    let title: String
    let subtitle: String
    let imageURL: String
    let members: String
}

struct EnhancedCoachesView: View {
    @State private var activeTab: CoachMarketplaceTab = .coaches
    @State private var selectedSport = "all"
    @State private var searchText = ""
    @State private var expandedCoachID: Int?
    @State private var bookedSessions: [CoachBookedSession] = []
    @State private var bookingCoach: CoachMarketplaceItem?
    @State private var selectedCoachProfile: CoachMarketplaceItem?

    private let sports = ["all", "tennis", "yoga", "basketball", "swimming", "fitness"]
    private let bookingDates = ["Tomorrow, Apr 13", "Wed, Apr 14", "Thu, Apr 15", "Sat, Apr 17", "Sun, Apr 18", "Mon, Apr 20"]
    private let bookingTimes = ["9:00 AM", "10:00 AM", "11:00 AM", "2:00 PM", "3:00 PM", "4:00 PM", "5:00 PM"]

    private let coaches: [CoachMarketplaceItem] = [
        .init(id: 1, name: "Marcus Chen", title: "Professional Tennis Coach", sports: ["Tennis"], rating: 4.9, reviews: 234, location: "Downtown Sports Hub", distance: "1.2 km", price: 85, experience: "12 years", verified: true, aiVerified: true, available: true, students: 847, imageURL: "https://images.unsplash.com/photo-1750698545009-679820502908?auto=format&fit=crop&w=500&q=80", badges: ["ATP Certified", "Ex-Pro", "Top Rated"], bio: "Former ATP-ranked player with 12 years of coaching experience. Focused on technique refinement, shot selection, and match confidence for intermediate and advanced athletes.", availability: ["Mon", "Wed", "Fri", "Sat"], sessionTypes: ["1-on-1", "Group", "Online"]),
        .init(id: 2, name: "Sarah Williams", title: "Certified Fitness & Yoga Coach", sports: ["Yoga", "Fitness", "Swimming"], rating: 4.8, reviews: 189, location: "Zen Fitness Studio", distance: "2.4 km", price: 65, experience: "8 years", verified: true, aiVerified: true, available: true, students: 512, imageURL: "https://images.unsplash.com/photo-1589860518300-9eac95f784d9?auto=format&fit=crop&w=500&q=80", badges: ["200hr YTT", "NASM Certified", "Community Coach"], bio: "Holistic wellness coach combining mobility, yoga, and recovery planning. Great for beginners, flexible scheduling, and hybrid online sessions.", availability: ["Tue", "Thu", "Sat", "Sun"], sessionTypes: ["Group", "Online", "Workshop"]),
        .init(id: 3, name: "Derek Johnson", title: "Basketball & Strength Coach", sports: ["Basketball", "Fitness"], rating: 4.7, reviews: 156, location: "Elite Performance Center", distance: "3.1 km", price: 95, experience: "15 years", verified: true, aiVerified: false, available: false, students: 633, imageURL: "https://images.unsplash.com/photo-1590070714379-e894212d7838?auto=format&fit=crop&w=500&q=80", badges: ["NBA D-League", "CSCS", "High Performance"], bio: "Former development league athlete turned performance coach. Specializes in explosiveness, vertical jump work, and basketball-specific strength development.", availability: ["Mon", "Tue", "Thu"], sessionTypes: ["1-on-1", "Team Session"]),
        .init(id: 4, name: "Lisa Tanaka", title: "Community Swimming Coach", sports: ["Swimming"], rating: 4.6, reviews: 98, location: "Riverside Aquatic Center", distance: "1.8 km", price: 55, experience: "6 years", verified: true, aiVerified: true, available: true, students: 289, imageURL: "https://images.unsplash.com/photo-1589860518300-9eac95f784d9?auto=format&fit=crop&w=500&q=80", badges: ["SwimAustralia L2", "Kids Friendly", "AI Verified"], bio: "National-level swimmer focused on stroke mechanics, pacing, and building water confidence for all ages.", availability: ["Mon", "Wed", "Sat", "Sun"], sessionTypes: ["1-on-1", "Group", "Kids"])
    ]

    private var filteredCoaches: [CoachMarketplaceItem] {
        coaches.filter { coach in
            let sportMatch = selectedSport == "all" || coach.sports.contains { $0.lowercased() == selectedSport }
            let searchMatch = searchText.isEmpty ||
                coach.name.localizedCaseInsensitiveContains(searchText) ||
                coach.title.localizedCaseInsensitiveContains(searchText)
            return sportMatch && searchMatch
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                tabSwitcher
                if activeTab == .coaches {
                    coachesTab
                } else {
                    calendarTab
                }
            }
            .padding(20)
            .padding(.bottom, 12 + MoveMatchPalette.tabBarScrollBottomPadding)
        }
        .background(MoveMatchPalette.background.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .sheet(item: $bookingCoach) { coach in
            CoachBookingSheet(
                coach: coach,
                dates: bookingDates,
                times: bookingTimes
            ) { session in
                bookedSessions.append(session)
                activeTab = .calendar
            }
        }
        .sheet(item: $selectedCoachProfile) { coach in
            CoachProfileSheet(coach: coach) {
                bookingCoach = coach
            }
        }
    }

    private var tabSwitcher: some View {
        HStack(spacing: 8) {
            ForEach(CoachMarketplaceTab.allCases, id: \.self) { tab in
                Button {
                    activeTab = tab
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: tab == .coaches ? "person.3.fill" : "calendar")
                        Text(tab.rawValue)
                    }
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(activeTab == tab ? MoveMatchPalette.textOnCard : MoveMatchPalette.textSecondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(activeTab == tab ? .white : Color.gray.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(8)
        .background(Color.gray.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    private var coachesTab: some View {
        VStack(alignment: .leading, spacing: 16) {
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                coachFeature(icon: "sparkles", title: "AI Verification", detail: "All coaches pass skill assessment", tint: .purple)
                coachFeature(icon: "rosette", title: "Certified Pros", detail: "Professional credentials verified", tint: .orange)
                coachFeature(icon: "person.2.fill", title: "Community Coaches", detail: "Trusted local sports mentors", tint: .green)
                coachFeature(icon: "video.fill", title: "Online Sessions", detail: "Book from anywhere", tint: .blue)
            }

            HStack(spacing: 12) {
                HStack(spacing: 10) {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(MoveMatchPalette.textOnCardMuted)
                    TextField(
                        "",
                        text: $searchText,
                        prompt: Text("Search coaches...")
                            .foregroundStyle(MoveMatchPalette.textOnCardMuted)
                    )
                    .foregroundStyle(MoveMatchPalette.textOnCard)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .background(.white)
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))

                Button {
                } label: {
                    Image(systemName: "line.3.horizontal.decrease.circle.fill")
                        .font(.title3)
                        .foregroundStyle(MoveMatchPalette.primaryDark)
                        .frame(width: 48, height: 48)
                        .background(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                }
                .buttonStyle(.plain)
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(sports, id: \.self) { sport in
                        Button {
                            selectedSport = sport
                        } label: {
                            Text(sport == "all" ? "All Sports" : sport.capitalized)
                                .font(.caption.weight(.bold))
                                .foregroundStyle(selectedSport == sport ? .white : MoveMatchPalette.textOnCard)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 10)
                                .background(selectedSport == sport ? MoveMatchPalette.primary : .white)
                                .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            SharedSummaryBanner(
                icon: "sparkles.rectangle.stack.fill",
                title: "Not sure who to pick?",
                subtitle: "Use AI matching to shortlist coaches based on your goals, sport history, and play style."
            )

            ForEach(filteredCoaches) { coach in
                VStack(alignment: .leading, spacing: 12) {
                    Button {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                            expandedCoachID = expandedCoachID == coach.id ? nil : coach.id
                        }
                    } label: {
                        HStack(alignment: .top, spacing: 14) {
                            ZStack(alignment: .bottomTrailing) {
                                RemoteImageCard(urlString: coach.imageURL)
                                    .frame(width: 72, height: 72)
                                if coach.available {
                                    Circle()
                                        .fill(MoveMatchPalette.primary)
                                        .frame(width: 16, height: 16)
                                        .overlay(Circle().stroke(.white, lineWidth: 3))
                                        .offset(x: 2, y: 2)
                                }
                            }

                            VStack(alignment: .leading, spacing: 6) {
                                HStack(spacing: 8) {
                                    Text(coach.name)
                                        .font(.headline)
                                    if coach.verified {
                                        Image(systemName: "checkmark.seal.fill")
                                            .foregroundStyle(.blue)
                                    }
                                    if coach.aiVerified {
                                        Text("AI")
                                            .font(.caption2.weight(.bold))
                                            .foregroundStyle(.purple)
                                            .padding(.horizontal, 6)
                                            .padding(.vertical, 3)
                                            .background(.purple.opacity(0.12))
                                            .clipShape(Capsule())
                                    }
                                }
                                Text(coach.title)
                                    .font(.subheadline)
                                    .foregroundStyle(MoveMatchPalette.textSecondary)

                                HStack(spacing: 10) {
                                    Label(String(format: "%.1f (%d)", coach.rating, coach.reviews), systemImage: "star.fill")
                                        .foregroundStyle(.orange)
                                    Label(coach.distance, systemImage: "mappin.and.ellipse")
                                        .foregroundStyle(MoveMatchPalette.textSecondary)
                                    Label("\(coach.students)", systemImage: "person.2.fill")
                                        .foregroundStyle(MoveMatchPalette.textSecondary)
                                }
                                .font(.caption.weight(.semibold))

                                HStack {
                                    WrapTagRow(tags: Array(coach.badges.prefix(2)))
                                    Spacer()
                                    VStack(alignment: .trailing, spacing: 2) {
                                        Text("$\(coach.price)")
                                            .font(.headline.bold())
                                        Text("/session")
                                            .font(.caption)
                                            .foregroundStyle(MoveMatchPalette.textSecondary)
                                    }
                                }
                            }
                        }
                    }
                    .buttonStyle(.plain)

                    WrapTagRow(tags: coach.sports)

                    if expandedCoachID == coach.id {
                        VStack(alignment: .leading, spacing: 12) {
                            Text(coach.bio)
                                .font(.footnote)
                                .foregroundStyle(MoveMatchPalette.textSecondary)
                            infoSection(title: "Session Types", tags: coach.sessionTypes)
                            availabilityRow(coach.availability)
                            Button {
                                selectedCoachProfile = coach
                            } label: {
                                HStack {
                                    Label("View Full Profile", systemImage: "person.crop.rectangle")
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                }
                                .font(.subheadline.weight(.bold))
                                .foregroundStyle(MoveMatchPalette.textOnCard)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 12)
                                .background(Color.gray.opacity(0.08))
                                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                            }
                            .buttonStyle(.plain)
                        }
                        .transition(.opacity.combined(with: .move(edge: .top)))
                    }

                    HStack {
                        Label("Next available: Tomorrow, 10:00 AM", systemImage: "calendar")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(MoveMatchPalette.textSecondary)
                        Spacer()
                    }

                    HStack(spacing: 10) {
                        Button {
                            bookingCoach = coach
                        } label: {
                            HStack {
                                Image(systemName: bookedSessions.contains(where: { $0.coach.id == coach.id }) ? "checkmark.circle.fill" : "calendar.badge.plus")
                                Text(bookedSessions.contains(where: { $0.coach.id == coach.id }) ? "Booked" : "Book Session")
                            }
                            .font(.subheadline.weight(.bold))
                            .foregroundStyle(bookedSessions.contains(where: { $0.coach.id == coach.id }) ? .black : .white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(bookedSessions.contains(where: { $0.coach.id == coach.id }) ? MoveMatchPalette.primary.opacity(0.18) : MoveMatchPalette.primary)
                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        }
                        .buttonStyle(.plain)

                        Button {
                        } label: {
                            Image(systemName: "video.fill")
                                .foregroundStyle(MoveMatchPalette.textOnCard)
                                .frame(width: 46, height: 46)
                                .background(Color.gray.opacity(0.08))
                                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(16)
                .background(.white)
                .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            }

            SharedSummaryBanner(
                icon: "award.fill",
                title: "Become a Community Coach",
                subtitle: "Share your expertise, get AI verified, and start earning by guiding other athletes."
            )
        }
    }

    private var calendarTab: some View {
        VStack(alignment: .leading, spacing: 16) {
            if bookedSessions.isEmpty {
                VStack(spacing: 12) {
                    Text("📅")
                        .font(.system(size: 42))
                    Text("No sessions booked yet")
                        .font(.title3.bold())
                    Text("Book a coach session to see it here.")
                        .font(.subheadline)
                        .foregroundStyle(MoveMatchPalette.textSecondary)
                    Button("Find a Coach") {
                        activeTab = .coaches
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(MoveMatchPalette.primary)
                }
                .frame(maxWidth: .infinity)
                .padding(32)
                .background(.white)
                .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            } else {
                ForEach(groupedSessions.keys.sorted(), id: \.self) { date in
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Circle()
                                .fill(MoveMatchPalette.primary)
                                .frame(width: 8, height: 8)
                            Text(date)
                                .font(.headline)
                            Spacer()
                        }

                        ForEach(groupedSessions[date] ?? []) { session in
                            VStack(alignment: .leading, spacing: 12) {
                                HStack(alignment: .top, spacing: 12) {
                                    RemoteImageCard(urlString: session.coach.imageURL)
                                        .frame(width: 64, height: 64)
                                    VStack(alignment: .leading, spacing: 4) {
                                        HStack {
                                            Text(session.coach.name)
                                                .font(.headline)
                                            Spacer()
                                            Text("Confirmed")
                                                .font(.caption.weight(.bold))
                                                .foregroundStyle(MoveMatchPalette.primaryDark)
                                        }
                                        Text(session.coach.title)
                                            .font(.subheadline)
                                            .foregroundStyle(MoveMatchPalette.textSecondary)
                                    }
                                }

                                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                                    bookingMeta("Time", value: session.time, icon: "clock.fill")
                                    bookingMeta("Type", value: session.sessionType, icon: "person.2.fill")
                                    bookingMeta("Location", value: session.coach.location, icon: "mappin.and.ellipse")
                                    bookingMeta("Price", value: "$\(session.coach.price)", icon: "creditcard.fill")
                                }

                                HStack {
                                    WrapTagRow(tags: [session.coach.sports.first ?? "Sport"])
                                    Spacer()
                                    Button("Cancel") {
                                        bookedSessions.removeAll { $0.id == session.id }
                                    }
                                    .font(.caption.weight(.bold))
                                    .foregroundStyle(.red)
                                }
                            }
                            .padding(16)
                            .background(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                        }
                    }
                }
            }
        }
    }

    private var groupedSessions: [String: [CoachBookedSession]] {
        Dictionary(grouping: bookedSessions, by: \.date)
    }

    private func coachFeature(icon: String, title: String, detail: String, tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(tint.opacity(0.12))
                .frame(width: 36, height: 36)
                .overlay(Image(systemName: icon).foregroundStyle(tint))
            Text(title)
                .font(.subheadline.bold())
                .foregroundStyle(MoveMatchPalette.textOnCard)
            Text(detail)
                .font(.caption)
                .foregroundStyle(MoveMatchPalette.textOnCardMuted)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private func infoSection(title: String, tags: [String]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption.weight(.bold))
                .foregroundStyle(MoveMatchPalette.textOnCard)
            WrapTagRow(tags: tags)
        }
    }

    private func availabilityRow(_ days: [String]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Available")
                .font(.caption.weight(.bold))
                .foregroundStyle(MoveMatchPalette.textOnCard)
            HStack(spacing: 6) {
                ForEach(["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"], id: \.self) { day in
                    Text(day)
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(days.contains(day) ? MoveMatchPalette.primaryDark : MoveMatchPalette.textOnCardMuted)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(days.contains(day) ? MoveMatchPalette.primary.opacity(0.12) : Color.gray.opacity(0.08))
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                }
            }
        }
    }

    private func bookingMeta(_ title: String, value: String, icon: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundStyle(MoveMatchPalette.textOnCardMuted)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(MoveMatchPalette.textOnCardMuted)
                Text(value)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(MoveMatchPalette.textOnCard)
                    .lineLimit(1)
            }
        }
        .padding(10)
        .background(Color.gray.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

private struct CoachBookingSheet: View {
    let coach: CoachMarketplaceItem
    let dates: [String]
    let times: [String]
    let onConfirm: (CoachBookedSession) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var selectedDate = ""
    @State private var selectedTime = ""
    @State private var selectedSessionType = ""
    @State private var step = 0

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    HStack(spacing: 12) {
                        RemoteImageCard(urlString: coach.imageURL)
                            .frame(width: 64, height: 64)
                        VStack(alignment: .leading, spacing: 4) {
                            Text(coach.name)
                                .font(.headline)
                            Text(coach.title)
                                .font(.subheadline)
                                .foregroundStyle(MoveMatchPalette.textSecondary)
                            Label(String(format: "%.1f · $%d/session", coach.rating, coach.price), systemImage: "star.fill")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.orange)
                        }
                    }

                    if step == 0 {
                        selectionGrid("Select Date", options: dates, selection: $selectedDate, columns: 3)
                        selectionGrid("Select Time", options: times, selection: $selectedTime, columns: 4)
                        selectionGrid("Session Type", options: coach.sessionTypes, selection: $selectedSessionType, columns: 2)
                    } else if step == 1 {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Confirm Your Booking")
                                .font(.title3.bold())
                            bookingConfirmationRow("Date", value: selectedDate, icon: "calendar")
                            bookingConfirmationRow("Time", value: selectedTime, icon: "clock.fill")
                            bookingConfirmationRow("Type", value: selectedSessionType, icon: "person.2.fill")
                            bookingConfirmationRow("Location", value: coach.location, icon: "mappin.and.ellipse")

                            HStack {
                                Text("Total")
                                    .font(.headline)
                                Spacer()
                                Text("$\(coach.price)")
                                    .font(.title3.bold())
                            }
                            .padding(.top, 4)
                        }
                        .padding(16)
                        .background(Color.gray.opacity(0.08))
                        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                    } else {
                        VStack(spacing: 16) {
                            Circle()
                                .fill(MoveMatchPalette.primary.opacity(0.16))
                                .frame(width: 84, height: 84)
                                .overlay(
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.system(size: 38))
                                        .foregroundStyle(MoveMatchPalette.primaryDark)
                                )
                            VStack(spacing: 6) {
                                Text("Booking Confirmed")
                                    .font(.title3.bold())
                                Text("Your session with \(coach.name) is locked in. We added it to your calendar and shared the details below.")
                                    .font(.subheadline)
                                    .multilineTextAlignment(.center)
                                    .foregroundStyle(MoveMatchPalette.textSecondary)
                            }
                            VStack(alignment: .leading, spacing: 10) {
                                bookingConfirmationRow("Date", value: selectedDate, icon: "calendar")
                                bookingConfirmationRow("Time", value: selectedTime, icon: "clock.fill")
                                bookingConfirmationRow("Type", value: selectedSessionType, icon: "person.2.fill")
                                bookingConfirmationRow("Location", value: coach.location, icon: "mappin.and.ellipse")
                            }
                            .padding(16)
                            .background(Color.gray.opacity(0.08))
                            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                    }
                }
                .padding(20)
            }
            .navigationTitle(step == 0 ? "Book a Session" : (step == 1 ? "Review Booking" : "Success"))
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(step == 0 ? "Cancel" : (step == 1 ? "Back" : "Close")) {
                        if step == 0 {
                            dismiss()
                        } else if step == 1 {
                            step = 0
                        } else {
                            dismiss()
                        }
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(step == 0 ? "Review" : (step == 1 ? "Confirm" : "View Calendar")) {
                        if step == 0 {
                            if !selectedDate.isEmpty, !selectedTime.isEmpty, !selectedSessionType.isEmpty {
                                step = 1
                            }
                        } else if step == 1 {
                            onConfirm(.init(coach: coach, date: selectedDate, time: selectedTime, sessionType: selectedSessionType))
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.88)) {
                                step = 2
                            }
                        } else {
                            dismiss()
                        }
                    }
                    .disabled(step == 0 && (selectedDate.isEmpty || selectedTime.isEmpty || selectedSessionType.isEmpty))
                }
            }
            .onAppear {
                selectedSessionType = coach.sessionTypes.first ?? ""
            }
        }
    }

    private func selectionGrid(_ title: String, options: [String], selection: Binding<String>, columns: Int) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.headline)
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: columns), spacing: 8) {
                ForEach(options, id: \.self) { option in
                    Button {
                        selection.wrappedValue = option
                    } label: {
                        Text(option)
                            .font(.caption.weight(.bold))
                            .foregroundStyle(selection.wrappedValue == option ? MoveMatchPalette.primaryDark : MoveMatchPalette.textOnCard)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .padding(.horizontal, 6)
                            .background(selection.wrappedValue == option ? MoveMatchPalette.primary.opacity(0.12) : Color.white)
                            .overlay(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .stroke(selection.wrappedValue == option ? MoveMatchPalette.primary.opacity(0.5) : Color.gray.opacity(0.15), lineWidth: 1)
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func bookingConfirmationRow(_ title: String, value: String, icon: String) -> some View {
        HStack {
            Label(title, systemImage: icon)
                .font(.subheadline.weight(.semibold))
            Spacer()
            Text(value)
                .font(.subheadline)
                .foregroundStyle(MoveMatchPalette.textSecondary)
        }
    }
}

private struct CoachProfileSheet: View {
    let coach: CoachMarketplaceItem
    let onBook: () -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    ZStack(alignment: .bottomLeading) {
                        RemoteImageCard(urlString: coach.imageURL)
                            .frame(height: 260)
                            .overlay(
                                LinearGradient(colors: [.black.opacity(0.55), .clear], startPoint: .bottomLeading, endPoint: .topTrailing)
                            )

                        VStack(alignment: .leading, spacing: 8) {
                            HStack(spacing: 8) {
                                ForEach(coach.badges.prefix(2), id: \.self) { badge in
                                    Text(badge)
                                        .font(.caption.weight(.bold))
                                        .foregroundStyle(.white)
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 6)
                                        .background(.white.opacity(0.14))
                                        .clipShape(Capsule())
                                }
                            }
                            Text(coach.name)
                                .font(.largeTitle.bold())
                                .foregroundStyle(.white)
                            Text(coach.title)
                                .font(.headline)
                                .foregroundStyle(.white.opacity(0.86))
                        }
                        .padding(20)
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))

                    HStack(spacing: 12) {
                        profileStat(title: "Rating", value: String(format: "%.1f", coach.rating), tint: .orange)
                        profileStat(title: "Students", value: "\(coach.students)", tint: .blue)
                        profileStat(title: "Price", value: "$\(coach.price)", tint: MoveMatchPalette.primaryDark)
                    }

                    sectionHeader("About")
                    Text(coach.bio)
                        .font(.body)
                        .foregroundStyle(MoveMatchPalette.textSecondary)

                    sectionHeader("Specialties")
                    WrapTagRow(tags: coach.sports + coach.sessionTypes)

                    sectionHeader("Availability")
                    HStack(spacing: 6) {
                        ForEach(["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"], id: \.self) { day in
                            Text(day)
                                .font(.caption2.weight(.bold))
                                .foregroundStyle(coach.availability.contains(day) ? MoveMatchPalette.primaryDark : MoveMatchPalette.textOnCardMuted)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 9)
                                .background(coach.availability.contains(day) ? MoveMatchPalette.primary.opacity(0.14) : Color.gray.opacity(0.08))
                                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        }
                    }

                    sectionHeader("At a Glance")
                    VStack(spacing: 10) {
                        detailRow(title: "Experience", value: coach.experience, icon: "clock.arrow.circlepath")
                        detailRow(title: "Location", value: coach.location, icon: "mappin.and.ellipse")
                        detailRow(title: "Distance", value: coach.distance, icon: "figure.walk")
                        detailRow(title: "Verification", value: coach.aiVerified ? "AI verified profile" : "Manual verification", icon: "checkmark.shield")
                    }
                }
                .padding(20)
            }
            .navigationTitle("Coach Profile")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Book") {
                        dismiss()
                        onBook()
                    }
                }
            }
        }
    }

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.headline.bold())
    }

    private func profileStat(title: String, value: String, tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption.weight(.bold))
                .foregroundStyle(MoveMatchPalette.textSecondary)
            Text(value)
                .font(.title3.bold())
                .foregroundStyle(tint)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private func detailRow(title: String, value: String, icon: String) -> some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.gray.opacity(0.08))
                .frame(width: 40, height: 40)
                .overlay(Image(systemName: icon).foregroundStyle(MoveMatchPalette.primaryDark))
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(MoveMatchPalette.textSecondary)
                Text(value)
                    .font(.subheadline.weight(.semibold))
            }
            Spacer()
        }
        .padding(14)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}

struct EnhancedCompeteView: View {
    @State private var activeTab: CompeteTab = .tournaments
    @AppStorage("enhanced_compete_joined_challenges") private var joinedChallengesStorage = "2"
    @AppStorage("enhanced_compete_registered_tournaments") private var registeredTournamentsStorage = "1"
    @State private var joinedChallenges: Set<Int> = [2]
    @State private var registeredTournaments: Set<Int> = [1]
    @State private var challengeParticipants: [Int: Int] = [1: 2847, 2: 1203, 3: 856, 4: 1540]
    @State private var tournamentParticipants: [Int: Int] = [1: 32, 2: 214, 3: 9, 4: 18]
    @State private var selectedChallenge: ChallengeItem?
    @State private var selectedTournament: TournamentItem?
    private let compactColumns = [GridItem(.flexible(), spacing: 14), GridItem(.flexible(), spacing: 14)]

    private let challenges: [ChallengeItem] = [
        .init(id: 1, title: "30-Day Sprint Challenge", creator: "Nike Run Club", prize: "$500", type: "Official", imageURL: "https://images.unsplash.com/photo-1758586326115-d4e9052b8f06?auto=format&fit=crop&w=900&q=80", description: "Log daily runs, hit pace targets, and compete on the global leaderboard over 30 days.", daysLeft: 19, baseParticipants: 2847),
        .init(id: 2, title: "Basketball Trick Shot", creator: "HoopKing", prize: "Merch Bundle", type: "Trending", imageURL: "https://images.unsplash.com/photo-1770042572491-0c3f1ca7d6a1?auto=format&fit=crop&w=900&q=80", description: "Submit your best trick shot video and compete through public voting plus judges.", daysLeft: 8, baseParticipants: 1203),
        .init(id: 3, title: "Summer Swim Marathon", creator: "AquaSports Pro", prize: "$200", type: "Trending", imageURL: "https://images.unsplash.com/photo-1560090970-feef7ff6e339?auto=format&fit=crop&w=900&q=80", description: "Track pool and open-water sessions. Longest cumulative distance wins.", daysLeft: 5, baseParticipants: 856),
        .init(id: 4, title: "Yoga Flexibility Master", creator: "MindBody Studio", prize: "$300 + Gear", type: "Official", imageURL: "https://images.unsplash.com/photo-1666043428335-9278302bdd36?auto=format&fit=crop&w=900&q=80", description: "Submit daily pose videos and earn scores from certified judges.", daysLeft: 27, baseParticipants: 1540)
    ]

    private let tournaments: [TournamentItem] = [
        .init(id: 1, title: "City Tennis Open 2026", sport: "Tennis", emoji: "🎾", type: "Singles", level: "Intermediate", imageURL: "https://images.unsplash.com/photo-1761286753856-2f39b4413c1c?auto=format&fit=crop&w=900&q=80", prize: "$2,500", baseParticipants: 32, maxParticipants: 64, location: "City Tennis Complex", date: "Apr 28 - May 3", registrationEnd: "Apr 25", organizer: "City Sports Federation", status: "Registration Open", rounds: ["Quarters", "Semis", "Final"], entryFee: 25, description: "Structured city tournament for intermediate singles players across five days."),
        .init(id: 2, title: "Summer Run Festival 10K", sport: "Running", emoji: "🏃", type: "Individual", level: "All Levels", imageURL: "https://images.unsplash.com/photo-1758586326115-d4e9052b8f06?auto=format&fit=crop&w=900&q=80", prize: "$800 + Medals", baseParticipants: 214, maxParticipants: 600, location: "Riverside Park Boulevard", date: "May 10, 2026", registrationEnd: "May 5", organizer: "Park Run Club", status: "Registration Open", rounds: ["Race"], entryFee: 20, description: "Scenic chip-timed 10K with finisher medals and strong community turnout."),
        .init(id: 3, title: "5v5 Soccer League", sport: "Soccer", emoji: "⚽", type: "Team", level: "Intermediate", imageURL: "https://images.unsplash.com/photo-1549923015-badf41b04831?auto=format&fit=crop&w=900&q=80", prize: "Trophy + Jerseys", baseParticipants: 9, maxParticipants: 12, location: "FC United Sports Complex", date: "May 3 - May 31", registrationEnd: "Apr 30", organizer: "FC United", status: "Almost Full", rounds: ["Group Stage", "Knockouts", "Final"], entryFee: 60, description: "Indoor 5v5 monthly league with team registration and knockout rounds."),
        .init(id: 4, title: "Basketball 3x3 Open", sport: "Basketball", emoji: "🏀", type: "Team (3v3)", level: "All Levels", imageURL: "https://images.unsplash.com/photo-1775362914221-20ab89370042?auto=format&fit=crop&w=900&q=80", prize: "$1,200 + Trophies", baseParticipants: 18, maxParticipants: 32, location: "Downtown Arena Courts", date: "May 17 - 18", registrationEnd: "May 10", organizer: "HoopCity League", status: "Registration Open", rounds: ["Pool Play", "Knockouts", "Final"], entryFee: 40, description: "Fast-paced 3x3 weekend tournament with outdoor courts, DJ, and strong city presence.")
    ]

    private let leaderboard: [LeaderboardAthlete] = [
        .init(rank: 1, name: "Jordan Lee", sport: "Running", score: 9840, wins: 18, trend: "+240", isMe: false),
        .init(rank: 2, name: "Taylor Kim", sport: "Tennis", score: 9510, wins: 15, trend: "+180", isMe: false),
        .init(rank: 3, name: "Marcus Chen", sport: "Basketball", score: 9240, wins: 14, trend: "+120", isMe: false),
        .init(rank: 4, name: "Alex Chen", sport: "Tennis", score: 8890, wins: 12, trend: "+95", isMe: true),
        .init(rank: 5, name: "Emily Zhang", sport: "Swimming", score: 8610, wins: 11, trend: "-30", isMe: false),
        .init(rank: 6, name: "Riley Morgan", sport: "Yoga", score: 8470, wins: 10, trend: "+60", isMe: false)
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                competeHero
                statsRow
                tabBar
                tabContent
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 24 + MoveMatchPalette.tabBarScrollBottomPadding)
        }
        .background(MoveMatchPalette.background.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .sheet(item: $selectedChallenge) { challenge in
            CompeteDetailSheet(
                title: challenge.title,
                subtitle: challenge.creator,
                imageURL: challenge.imageURL,
                description: challenge.description,
                accent: challenge.type == "Official" ? .blue : .orange,
                metadata: [
                    ("Prize", challenge.prize, "gift.fill"),
                    ("Days Left", "\(challenge.daysLeft)", "clock.fill"),
                    ("Participants", "\(challengeParticipants[challenge.id] ?? challenge.baseParticipants)", "person.2.fill")
                ],
                sections: [
                    ("How It Works", challengeFlow(for: challenge)),
                    ("What You Need", challengeChecklist(for: challenge))
                ]
            )
        }
        .sheet(item: $selectedTournament) { tournament in
            CompeteDetailSheet(
                title: tournament.title,
                subtitle: "\(tournament.organizer) · \(tournament.type)",
                imageURL: tournament.imageURL,
                description: tournament.description,
                accent: .orange,
                metadata: [
                    ("Prize", tournament.prize, "gift.fill"),
                    ("Location", tournament.location, "mappin.and.ellipse"),
                    ("Entry Fee", "$\(tournament.entryFee)", "creditcard.fill")
                ],
                sections: [
                    ("Timeline", tournamentTimeline(for: tournament)),
                    ("Format", tournamentFormat(for: tournament))
                ]
            )
        }
        .onAppear {
            joinedChallenges = decodeIDSet(from: joinedChallengesStorage)
            registeredTournaments = decodeIDSet(from: registeredTournamentsStorage)
            syncParticipantCounters()
        }
    }

    private var competeHero: some View {
        ZStack(alignment: .bottomLeading) {
            RemoteImageCard(urlString: "https://images.unsplash.com/photo-1762345127396-ac4a970436c3?auto=format&fit=crop&w=1200&q=80")
                .frame(height: 208)
                .overlay(
                    Rectangle().fill(.black.opacity(0.18))
                )
            VStack(alignment: .leading, spacing: 8) {
                Label("Competition Hub", systemImage: "trophy.fill")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.orange)
                Text("Compete, Win,\nBe Legendary")
                    .font(.system(size: 34, weight: .bold))
                    .foregroundStyle(.white)
                    .minimumScaleFactor(0.85)
                Text("From local leagues to regional championships.")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.white)
                    .shadow(color: .black.opacity(0.35), radius: 0, x: 0, y: 1)
            }
            .padding(18)
        }
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
    }

    private var statsRow: some View {
        HStack(spacing: 10) {
            SimpleMetricCard(title: "Active Events", value: "\(challenges.count + tournaments.count)", tint: .orange, icon: "trophy")
            SimpleMetricCard(title: "Participants", value: "12.4K", tint: .blue, icon: "person.2")
            SimpleMetricCard(title: "Prize Pool", value: "$85K", tint: .green, icon: "rosette")
        }
    }

    private var tabBar: some View {
        HStack(spacing: 8) {
            ForEach(CompeteTab.allCases, id: \.self) { tab in
                Button {
                    activeTab = tab
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: tab.icon)
                            .font(.system(size: 12, weight: .semibold))
                        Text(tab.rawValue)
                            // Slightly smaller than before so the top tab row feels lighter,
                            // especially the selected (yellow) pill.
                            .font(.system(size: 13, weight: activeTab == tab ? .semibold : .medium))
                            .minimumScaleFactor(0.9)
                    }
                        .foregroundStyle(activeTab == tab ? Color.black : MoveMatchPalette.textOnCard)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 9)
                        .background(activeTab == tab ? Color.yellow.opacity(0.95) : .white)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(8)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    @ViewBuilder
    private var tabContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            switch activeTab {
            case .tournaments:
                tournamentsTab
            case .leaderboard:
                leaderboardTab
            case .mine:
                mineTab
            }
        }
        .animation(.spring(response: 0.36, dampingFraction: 0.9), value: activeTab)
    }

    private var tournamentsTab: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                HStack(spacing: 10) {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color.yellow.opacity(0.22))
                        .frame(width: 34, height: 34)
                        .overlay(Image(systemName: "flame.fill").foregroundStyle(.orange))
                    Text("Hot Challenges")
                        .font(.title3.bold())
                        .foregroundStyle(MoveMatchPalette.textOnCard)
                    Text("\(challenges.count) open")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.orange)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Color.yellow.opacity(0.20))
                        .clipShape(Capsule())
                }
                Spacer()
                Text("Trending Now")
                    .font(.headline.weight(.bold))
                    .foregroundStyle(MoveMatchPalette.textSecondary)
            }

            LazyVGrid(columns: compactColumns, spacing: 14) {
                ForEach(challenges) { challenge in
                    let joined = joinedChallenges.contains(challenge.id)
                    let participants = challengeParticipants[challenge.id] ?? challenge.baseParticipants
                    CompeteChallengeGridCard(
                        challenge: challenge,
                        participants: participants,
                        joined: joined,
                        onOpen: { selectedChallenge = challenge },
                        onJoin: {
                            if joined {
                                joinedChallenges.remove(challenge.id)
                                challengeParticipants[challenge.id] = max((challengeParticipants[challenge.id] ?? challenge.baseParticipants) - 1, 0)
                            } else {
                                joinedChallenges.insert(challenge.id)
                                challengeParticipants[challenge.id] = (challengeParticipants[challenge.id] ?? challenge.baseParticipants) + 1
                            }
                            joinedChallengesStorage = encodeIDSet(joinedChallenges)
                        }
                    )
                }
            }

            HStack {
                Label("Tournaments", systemImage: "trophy.fill")
                    .font(.title3.bold())
                    .foregroundStyle(.orange)
                Spacer()
                Text("\(tournaments.count) open")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(MoveMatchPalette.textSecondary)
            }

            LazyVGrid(columns: compactColumns, spacing: 14) {
                ForEach(tournaments) { tournament in
                    let count = tournamentParticipants[tournament.id] ?? tournament.baseParticipants
                    let registered = registeredTournaments.contains(tournament.id)
                    CompeteTournamentGridCard(
                        tournament: tournament,
                        participants: count,
                        registered: registered,
                        onOpen: { selectedTournament = tournament },
                        onRegister: {
                            if registered {
                                registeredTournaments.remove(tournament.id)
                                tournamentParticipants[tournament.id] = max((tournamentParticipants[tournament.id] ?? tournament.baseParticipants) - 1, 0)
                            } else {
                                registeredTournaments.insert(tournament.id)
                                tournamentParticipants[tournament.id] = (tournamentParticipants[tournament.id] ?? tournament.baseParticipants) + 1
                            }
                            registeredTournamentsStorage = encodeIDSet(registeredTournaments)
                        }
                    )
                }
            }
        }
    }

    private var leaderboardTab: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 12) {
                ForEach([leaderboard[1], leaderboard[0], leaderboard[2]], id: \.rank) { athlete in
                    VStack(spacing: 8) {
                        Text(athlete.rank == 1 ? "🥇" : athlete.rank == 2 ? "🥈" : "🥉")
                            .font(.system(size: athlete.rank == 1 ? 30 : 24))
                        Circle()
                            .fill((athlete.isMe ? MoveMatchPalette.primary : Color.blue).opacity(0.18))
                            .frame(width: athlete.rank == 1 ? 64 : 56, height: athlete.rank == 1 ? 64 : 56)
                            .overlay(Text(String(athlete.name.prefix(1))).font(.headline))
                        Text(athlete.name.split(separator: " ").first.map(String.init) ?? athlete.name)
                            .font(.caption.weight(.bold))
                        Text(athlete.score.formatted())
                            .font(.headline.bold())
                            .foregroundStyle(.orange)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, athlete.rank == 1 ? 18 : 14)
                    .background(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                }
            }

            VStack(spacing: 0) {
                ForEach(leaderboard) { athlete in
                    HStack(spacing: 12) {
                        Text("#\(athlete.rank)")
                            .font(.subheadline.bold())
                            .foregroundStyle(athlete.rank <= 3 ? .orange : .secondary)
                            .frame(width: 34)
                        Circle()
                            .fill((athlete.isMe ? MoveMatchPalette.primary : Color.blue).opacity(0.18))
                            .frame(width: 42, height: 42)
                            .overlay(Text(String(athlete.name.prefix(1))).font(.subheadline.weight(.bold)))
                        VStack(alignment: .leading, spacing: 2) {
                            Text(athlete.name + (athlete.isMe ? " (You)" : ""))
                                .font(.headline)
                                .foregroundStyle(athlete.isMe ? MoveMatchPalette.primaryDark : MoveMatchPalette.textOnCard)
                            Text("\(athlete.sport) · \(athlete.wins) wins")
                                .font(.caption)
                                .foregroundStyle(MoveMatchPalette.textSecondary)
                        }
                        Spacer()
                        VStack(alignment: .trailing, spacing: 2) {
                            Text(athlete.score.formatted())
                                .font(.headline.bold())
                            Text(athlete.trend)
                                .font(.caption.weight(.bold))
                                .foregroundStyle(athlete.trend.hasPrefix("-") ? .red : .green)
                        }
                    }
                    .padding(14)
                    .background(athlete.isMe ? MoveMatchPalette.primary.opacity(0.06) : .white)
                    if athlete.rank != leaderboard.last?.rank {
                        Divider().padding(.leading, 56)
                    }
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            .background(.white)
        }
    }

    private var mineTab: some View {
        VStack(alignment: .leading, spacing: 16) {
            let myTournaments = tournaments.filter { registeredTournaments.contains($0.id) }
            let myChallenges = challenges.filter { joinedChallenges.contains($0.id) }

            if myTournaments.isEmpty && myChallenges.isEmpty {
                SharedSummaryBanner(
                    icon: "trophy.fill",
                    title: "Nothing here yet",
                    subtitle: "Join a challenge or register for a tournament to start building your competition history."
                )
            } else {
                if !myTournaments.isEmpty {
                    Text("Registered Tournaments")
                        .font(.headline)
                    ForEach(myTournaments) { tournament in
                        HStack(spacing: 12) {
                            Text(tournament.emoji)
                                .font(.largeTitle)
                            VStack(alignment: .leading, spacing: 4) {
                                Text(tournament.title)
                                    .font(.headline)
                                Text("\(tournament.date) · \(tournament.location)")
                                    .font(.caption)
                                    .foregroundStyle(MoveMatchPalette.textSecondary)
                            }
                            Spacer()
                            Text("Registered")
                                .font(.caption.weight(.bold))
                                .foregroundStyle(MoveMatchPalette.primaryDark)
                        }
                        .padding(16)
                        .background(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                    }
                }

                if !myChallenges.isEmpty {
                    Text("Joined Challenges")
                        .font(.headline)
                    ForEach(myChallenges) { challenge in
                        HStack(spacing: 12) {
                            Image(systemName: "flame.fill")
                                .foregroundStyle(.orange)
                                .font(.title3)
                            VStack(alignment: .leading, spacing: 4) {
                                Text(challenge.title)
                                    .font(.headline)
                                Text("\(challenge.daysLeft)d left · \(challenge.prize)")
                                    .font(.caption)
                                    .foregroundStyle(MoveMatchPalette.textSecondary)
                            }
                            Spacer()
                            Text("Active")
                                .font(.caption.weight(.bold))
                                .foregroundStyle(.orange)
                        }
                        .padding(16)
                        .background(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                    }
                }
            }
        }
    }

    private func challengeFlow(for challenge: ChallengeItem) -> [String] {
        switch challenge.id {
        case 1:
            return [
                "Log your sprint sessions daily and keep your streak alive for the full 30-day cycle.",
                "Pace consistency and total distance both contribute to leaderboard movement.",
                "Final rankings unlock sponsor rewards and featured community placement."
            ]
        case 2:
            return [
                "Upload one qualifying trick-shot clip before the weekly review window closes.",
                "Community votes determine the shortlist before judges score execution and creativity.",
                "Top creators move into the final highlight round for bonus exposure."
            ]
        default:
            return [
                "Join the event, complete the required activity, and submit your proof before the deadline.",
                "Scores are refreshed throughout the challenge so you can track momentum.",
                "Top finishers receive the listed prize plus community recognition."
            ]
        }
    }

    private func challengeChecklist(for challenge: ChallengeItem) -> [String] {
        [
            "Valid MoveMatch profile with activity history",
            "One public submission or synced workout before the final deadline",
            "Follow creator rules from \(challenge.creator) to stay eligible"
        ]
    }

    private func tournamentTimeline(for tournament: TournamentItem) -> [String] {
        [
            "Registration closes on \(tournament.registrationEnd).",
            "Event window: \(tournament.date).",
            "Organizer \(tournament.organizer) publishes draws and check-in info in-app."
        ]
    }

    private func tournamentFormat(for tournament: TournamentItem) -> [String] {
        [
            "\(tournament.type) format for \(tournament.level) athletes.",
            "Current rounds: \(tournament.rounds.joined(separator: " -> ")).",
            "Entry fee is $\(tournament.entryFee) and venue is \(tournament.location)."
        ]
    }

    private func syncParticipantCounters() {
        for challenge in challenges {
            challengeParticipants[challenge.id] = challenge.baseParticipants + (joinedChallenges.contains(challenge.id) ? 1 : 0)
        }
        for tournament in tournaments {
            tournamentParticipants[tournament.id] = tournament.baseParticipants + (registeredTournaments.contains(tournament.id) ? 1 : 0)
        }
    }
}

private struct CompeteChallengeGridCard: View {
    let challenge: ChallengeItem
    let participants: Int
    let joined: Bool
    let onOpen: () -> Void
    let onJoin: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Button(action: onOpen) {
                VStack(alignment: .leading, spacing: 0) {
                    ZStack(alignment: .topLeading) {
                        RemoteImageCard(urlString: challenge.imageURL)
                            .frame(height: 118)

                        VStack(alignment: .leading, spacing: 0) {
                            HStack {
                                Text(challenge.type)
                                    .font(.system(size: 10, weight: .semibold))
                                    .foregroundStyle(.white)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(.orange)
                                    .clipShape(Capsule())

                                Spacer()

                                Text(challenge.prize)
                                    .font(.system(size: 10, weight: .semibold))
                                    .foregroundStyle(.white)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(.orange)
                                    .clipShape(Capsule())
                            }

                            Spacer()

                            Text("\(challenge.daysLeft)d left")
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.red.opacity(0.92))
                                .clipShape(Capsule())
                        }
                        .padding(8)
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))

                    VStack(alignment: .leading, spacing: 4) {
                        Text(challenge.title)
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(MoveMatchPalette.textOnCard)
                            .lineLimit(2)
                            .minimumScaleFactor(0.9)

                        Text("by \(challenge.creator)")
                            .font(.system(size: 10.5, weight: .regular))
                            .foregroundStyle(MoveMatchPalette.textOnCardMuted)
                            .lineLimit(1)

                        Label("\(participants.formatted())", systemImage: "person.2")
                            .font(.system(size: 10.5, weight: .medium))
                            .foregroundStyle(MoveMatchPalette.textOnCardMuted)
                    }
                    .padding(.horizontal, 4)
                }
            }
            .buttonStyle(.plain)

            Button(action: onJoin) {
                Text(joined ? "Joined" : "Join Now")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(joined ? .white : .black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(joined ? MoveMatchPalette.primaryDark : Color.yellow.opacity(0.96))
                    .clipShape(Capsule())
            }
            .buttonStyle(.plain)
        }
        .padding(10)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(Color.black.opacity(0.04), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 4)
    }
}

private struct CompeteTournamentGridCard: View {
    let tournament: TournamentItem
    let participants: Int
    let registered: Bool
    let onOpen: () -> Void
    let onRegister: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Button(action: onOpen) {
                VStack(alignment: .leading, spacing: 10) {
                    ZStack(alignment: .topLeading) {
                        RemoteImageCard(urlString: tournament.imageURL)
                            .frame(height: 112)
                            .frame(maxWidth: .infinity)

                        HStack(alignment: .top) {
                            Text(tournament.emoji)
                                .font(.title3)
                                .padding(8)
                                .background(.white.opacity(0.92))
                                .clipShape(Circle())

                            Spacer()

                            Text(tournament.prize)
                                .font(.caption2.weight(.bold))
                                .foregroundStyle(.white)
                                .lineLimit(1)
                                .minimumScaleFactor(0.72)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(.orange)
                                .clipShape(Capsule())
                        }
                        .padding(10)
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))

                    VStack(alignment: .leading, spacing: 6) {
                        Text(tournament.title)
                            .font(.subheadline.bold())
                            .foregroundStyle(MoveMatchPalette.textOnCard)
                            .lineLimit(2)

                        Text("\(tournament.type) · \(tournament.level)")
                            .font(.caption)
                            .foregroundStyle(MoveMatchPalette.textOnCardMuted)
                            .lineLimit(1)

                        Label(tournament.date, systemImage: "calendar")
                            .font(.caption)
                            .foregroundStyle(MoveMatchPalette.textOnCardMuted)
                            .lineLimit(1)

                        Label("\(participants)/\(tournament.maxParticipants)", systemImage: "person.2")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(MoveMatchPalette.textOnCardMuted)

                        ProgressView(value: Double(participants), total: Double(tournament.maxParticipants))
                            .tint(.orange)
                    }
                    .padding(.horizontal, 4)
                }
            }
            .buttonStyle(.plain)

            Button(action: onRegister) {
                Text(registered ? "Registered" : "Register")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(registered ? .white : .black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(registered ? .red.opacity(0.88) : Color.yellow.opacity(0.96))
                    .clipShape(Capsule())
            }
            .buttonStyle(.plain)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(Color.black.opacity(0.04), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 4)
    }
}

private struct CompeteDetailSheet: View {
    let title: String
    let subtitle: String
    let imageURL: String
    let description: String
    let accent: Color
    let metadata: [(String, String, String)]
    let sections: [(String, [String])]

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    ZStack(alignment: .bottomLeading) {
                        RemoteImageCard(urlString: imageURL)
                            .frame(height: 240)
                            .overlay(
                                LinearGradient(colors: [.black.opacity(0.55), .clear], startPoint: .bottomLeading, endPoint: .topTrailing)
                            )
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Overview")
                                .font(.caption.weight(.bold))
                                .foregroundStyle(accent)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(.white.opacity(0.16))
                                .clipShape(Capsule())
                            Text(title)
                                .font(.largeTitle.bold())
                                .foregroundStyle(.white)
                            Text(subtitle)
                                .font(.headline)
                                .foregroundStyle(.white.opacity(0.86))
                        }
                        .padding(20)
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))

                    Text(description)
                        .font(.body)
                        .foregroundStyle(MoveMatchPalette.textOnCard)
                        .padding(14)
                        .background(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))

                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                        ForEach(metadata, id: \.0) { item in
                            VStack(alignment: .leading, spacing: 8) {
                                Image(systemName: item.2)
                                    .foregroundStyle(accent)
                                Text(item.0)
                                    .font(.caption.weight(.bold))
                                    .foregroundStyle(MoveMatchPalette.textOnCardMuted)
                                Text(item.1)
                                    .font(.subheadline.weight(.bold))
                                    .foregroundStyle(MoveMatchPalette.textOnCard)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(14)
                            .background(Color.gray.opacity(0.08))
                            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                        }
                    }

                    ForEach(sections, id: \.0) { section in
                        VStack(alignment: .leading, spacing: 12) {
                            Text(section.0)
                                .font(.headline.bold())
                                .foregroundStyle(MoveMatchPalette.textOnCard)
                            VStack(spacing: 10) {
                                ForEach(Array(section.1.enumerated()), id: \.offset) { index, row in
                                    HStack(alignment: .top, spacing: 12) {
                                        Circle()
                                            .fill(accent.opacity(0.18))
                                            .frame(width: 28, height: 28)
                                            .overlay(
                                                Text("\(index + 1)")
                                                    .font(.caption.weight(.bold))
                                                    .foregroundStyle(accent)
                                            )
                                        Text(row)
                                            .font(.subheadline)
                                            .foregroundStyle(MoveMatchPalette.textSecondary)
                                        Spacer(minLength: 0)
                                    }
                                }
                            }
                            .padding(16)
                            .background(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                        }
                    }
                }
                .padding(20)
            }
            .background(MoveMatchPalette.background.ignoresSafeArea())
            .navigationTitle("Intro")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarBackground(Color.white, for: .navigationBar)
            .toolbarColorScheme(.light, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(MoveMatchPalette.primaryDark)
                }
            }
        }
    }
}

struct EnhancedCommunityView: View {
    @State private var activeTab: CommunityTab = .forYou
    @State private var activeCategory: CommunityCategory = .all
    @State private var likedPosts: Set<Int> = []
    @State private var joinedChallenges: Set<Int> = [2]
    @State private var selectedStorySeed: String?
    @State private var showingCreateSheet = false
    @State private var showingCreateMenu = false
    @State private var showingInventSheet = false
    @State private var selectedCommunityChallenge: CommunityChallenge?
    @State private var userPosts: [CommunityPost] = []

    private let categories = CommunityCategory.allCases
    private let stories: [CommunityStory] = [
        .init(id: 1, name: "Emma", avatarSeed: "Emma", active: true),
        .init(id: 2, name: "David", avatarSeed: "David", active: true),
        .init(id: 3, name: "Sophie", avatarSeed: "Sophie", active: true),
        .init(id: 4, name: "Alex", avatarSeed: "Alex", active: false),
        .init(id: 5, name: "Maya", avatarSeed: "Maya", active: false)
    ]

    private let forYouPosts: [CommunityPost] = [
        .init(id: 1, userName: "Jordan Li", handle: "@jordanli", avatarSeed: "Jordan", location: "Hong Kong", content: "Discovered an amazing hiking trail with 360 degree views. The climb was tough but the sunset made it worth every step.", imageURL: "https://images.unsplash.com/photo-1748199866497-98739ad95701?auto=format&fit=crop&w=1080&q=80", thumbnailURL: nil, tags: ["#Hiking", "#Outdoor"], likes: 243, comments: 38, shares: 15, time: "2h ago", category: .training, aiScore: nil),
        .init(id: 2, userName: "Emma Rodriguez", handle: "@emmafit", avatarSeed: "Emma", location: "Barcelona", content: "Meal prep Sunday. Nutrition is 70 percent of the game. What is your favorite pre-workout meal?", imageURL: "https://images.unsplash.com/photo-1606859191214-25806e8e2423?auto=format&fit=crop&w=1080&q=80", thumbnailURL: nil, tags: ["#Nutrition", "#MealPrep"], likes: 156, comments: 34, shares: 19, time: "7h ago", category: .nutrition, aiScore: nil),
        .init(id: 3, userName: "Dr. Ryan Mitchell", handle: "@drryanfit", avatarSeed: "Ryan", location: "Boston", content: "Injury prevention starts with dynamic warm-up routines. Current physiotherapy data shows a clear reduction in avoidable strains.", imageURL: "https://images.unsplash.com/photo-1713711437257-0232e837f40c?auto=format&fit=crop&w=1080&q=80", thumbnailURL: nil, tags: ["#Science", "#InjuryPrevention"], likes: 267, comments: 48, shares: 34, time: "5h ago", category: .science, aiScore: 94),
        .init(id: 4, userName: "Maya Patel", handle: "@mayalocal", avatarSeed: "Maya", location: "Your City", content: "Local running group meets every Saturday at 7am. We have beginners to advanced runners. Join us at the park entrance.", imageURL: "https://images.unsplash.com/photo-1773394018583-5ec5abcbb9a7?auto=format&fit=crop&w=1080&q=80", thumbnailURL: nil, tags: ["#Nearby", "#Running"], likes: 198, comments: 31, shares: 18, time: "6h ago", category: .nearby, aiScore: nil),
        .init(id: 5, userName: "Isabella Martinez", handle: "@bellawellness", avatarSeed: "Bella", location: "Miami", content: "Sleep is the ultimate recovery tool. Tracking sleep quality changed my performance more than any supplement.", imageURL: "https://images.unsplash.com/photo-1683448372037-8a406e1a5a5e?auto=format&fit=crop&w=1080&q=80", thumbnailURL: nil, tags: ["#Lifestyle", "#Recovery"], likes: 212, comments: 37, shares: 24, time: "7h ago", category: .lifestyle, aiScore: nil)
    ]

    private let followingPosts: [CommunityPost] = [
        .init(id: 101, userName: "Emma", handle: "@emmafit", avatarSeed: "Emma", location: "Barcelona", content: "Post-workout stretching is non-negotiable. I have noticed a huge difference in recovery time since making this a daily habit.", imageURL: nil, thumbnailURL: "https://images.unsplash.com/photo-1571726656333-2640ca759d22?auto=format&fit=crop&w=400&q=80", tags: ["#Recovery", "#Stretching"], likes: 278, comments: 45, shares: 0, time: "1h ago", category: .training, aiScore: nil),
        .init(id: 102, userName: "David", handle: "@davidclimbs", avatarSeed: "David", location: "Singapore", content: "Weightlifting PR today: 225 lbs deadlift. Progressive overload really works when you stay patient.", imageURL: nil, thumbnailURL: "https://images.unsplash.com/photo-1770493895453-4f758c40d11d?auto=format&fit=crop&w=400&q=80", tags: ["#Weightlifting", "#Strength"], likes: 294, comments: 51, shares: 0, time: "5h ago", category: .training, aiScore: nil),
        .init(id: 103, userName: "Sophie", handle: "@sophiemoves", avatarSeed: "Sophie", location: "Toronto", content: "Dance fitness class was amazing today. Burned 600 calories while having the time of my life.", imageURL: nil, thumbnailURL: "https://images.unsplash.com/photo-1524594152303-9fd13543fe6e?auto=format&fit=crop&w=400&q=80", tags: ["#Dance", "#Cardio"], likes: 189, comments: 34, shares: 0, time: "3h ago", category: .training, aiScore: nil),
        .init(id: 104, userName: "Alex", handle: "@alexfitness", avatarSeed: "Alex", location: "Los Angeles", content: "Boot camp training session complete. High intensity drills, team motivation, and that post-workout endorphin rush.", imageURL: nil, thumbnailURL: "https://images.unsplash.com/photo-1758875570256-6510adffb1de?auto=format&fit=crop&w=400&q=80", tags: ["#Bootcamp", "#Intensity"], likes: 198, comments: 36, shares: 0, time: "4h ago", category: .training, aiScore: nil)
    ]

    private let communityChallenges: [CommunityChallenge] = [
        .init(id: 1, title: "7-Day Hydration Reset", subtitle: "Lifestyle challenge · daily check-ins", imageURL: "https://images.unsplash.com/photo-1752681304950-cc5bc78064f5?auto=format&fit=crop&w=900&q=80", joinedCount: 438, prize: "Wellness kit", description: "Build a simple consistency streak with daily hydration check-ins, short reflections, and friendly leaderboard updates.", submissions: 312, topScore: 98, tags: ["#Lifestyle", "#Recovery"], isHot: false, creatorType: "Official"),
        .init(id: 2, title: "10K Weekend Club", subtitle: "Running challenge · community leaderboard", imageURL: "https://images.unsplash.com/photo-1758586326115-d4e9052b8f06?auto=format&fit=crop&w=900&q=80", joinedCount: 891, prize: "Badge + merch", description: "Complete a weekend 10K, upload your proof, and compare splits with runners in your city and around the world.", submissions: 524, topScore: 96, tags: ["#Running", "#Weekend"], isHot: true, creatorType: "Community"),
        .init(id: 3, title: "Mobility March", subtitle: "Recovery challenge · video streaks", imageURL: "https://images.unsplash.com/photo-1649738247362-4e43a2665a77?auto=format&fit=crop&w=900&q=80", joinedCount: 522, prize: "Coach spotlight", description: "Share one short mobility flow each day and keep your streak alive to unlock recovery badges and feature spots.", submissions: 268, topScore: 92, tags: ["#Mobility", "#Recovery"], isHot: true, creatorType: "Official")
    ]

    private let exploreSports: [ExploreSportCard] = [
        .init(id: 1, title: "Tennis Circle", subtitle: "Serve tips, drills, match clips", imageURL: "https://images.unsplash.com/photo-1761286753856-2f39b4413c1c?auto=format&fit=crop&w=900&q=80", members: "18.2K members"),
        .init(id: 2, title: "Running Crew", subtitle: "Routes, pacing, race prep", imageURL: "https://images.unsplash.com/photo-1758586326115-d4e9052b8f06?auto=format&fit=crop&w=900&q=80", members: "22.7K members"),
        .init(id: 3, title: "Basketball Lab", subtitle: "Handles, shooting, pickup spots", imageURL: "https://images.unsplash.com/photo-1770042572491-0c3f1ca7d6a1?auto=format&fit=crop&w=900&q=80", members: "14.9K members"),
        .init(id: 4, title: "Cycling Club", subtitle: "Gear, climbs, and city rides", imageURL: "https://images.unsplash.com/photo-1720749407269-b92e86cffb68?auto=format&fit=crop&w=900&q=80", members: "9.4K members")
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                communityHero
                if showingCreateMenu {
                    communityCreateMenu
                }
                primaryTabs
                if activeTab == .forYou {
                    categoryTabs
                }
                tabBody
            }
            .padding(.bottom, 24 + MoveMatchPalette.tabBarScrollBottomPadding)
        }
        .background(MoveMatchPalette.background.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .sheet(isPresented: $showingCreateSheet) {
            CommunityCreatePostSheet { post in
                userPosts.insert(post, at: 0)
                activeTab = .forYou
            }
        }
        .sheet(isPresented: $showingInventSheet) {
            CommunityInventSportSheet()
        }
        .sheet(item: $selectedCommunityChallenge) { challenge in
            CommunityChallengeDetailSheet(
                challenge: challenge,
                joined: joinedChallenges.contains(challenge.id),
                onToggleJoin: {
                    if joinedChallenges.contains(challenge.id) {
                        joinedChallenges.remove(challenge.id)
                    } else {
                        joinedChallenges.insert(challenge.id)
                    }
                }
            )
        }
    }

    private var communityHero: some View {
        ZStack(alignment: .topLeading) {
            RemoteImageCard(urlString: "https://images.unsplash.com/photo-1767809673585-78513a929f99?auto=format&fit=crop&w=1200&q=80")
                .frame(height: 150)
                .clipped()
                .overlay(
                    LinearGradient(
                        colors: [Color.black.opacity(0.5), Color.black.opacity(0.2), .clear],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )

            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 6) {
                    Label("Sports Community", systemImage: "person.3.sequence.fill")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.white)
                    Text("Community")
                        .font(.title.bold())
                        .foregroundStyle(.white)
                    Text("Connect, share, and grow through sports.")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.white.opacity(0.95))
                        .shadow(color: .black.opacity(0.4), radius: 0, x: 0, y: 1)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.86)) {
                        showingCreateMenu.toggle()
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: showingCreateMenu ? "xmark" : "plus")
                        Text(showingCreateMenu ? "Close" : "Create")
                    }
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 9)
                    .background(MoveMatchPalette.primary)
                    .clipShape(Capsule())
                    .shadow(color: .black.opacity(0.28), radius: 6, y: 2)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(showingCreateMenu ? "Close create menu" : "Create post")
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 10)
        }
    }

    private var communityCreateMenu: some View {
        VStack(alignment: .leading, spacing: 8) {
            Button {
                showingCreateMenu = false
                showingCreateSheet = true
            } label: {
                createMenuRow(icon: "square.and.pencil", title: "Post Update", subtitle: "Share a moment with the community")
            }
            .buttonStyle(.plain)

            Button {
                showingCreateMenu = false
                showingInventSheet = true
            } label: {
                createMenuRow(icon: "sparkles", title: "Invent Sport", subtitle: "Create a new community challenge")
            }
            .buttonStyle(.plain)
        }
        .padding(10)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .shadow(color: .black.opacity(0.08), radius: 16, y: 8)
        .transition(.opacity.combined(with: .move(edge: .top)))
        .padding(.horizontal, 20)
    }

    private var primaryTabs: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(CommunityTab.allCases, id: \.self) { tab in
                    Button {
                        withAnimation(.spring(response: 0.34, dampingFraction: 0.9)) {
                            activeTab = tab
                        }
                    } label: {
                        Text(tab.rawValue)
                            .font(.caption.weight(.bold))
                            .lineLimit(1)
                            .minimumScaleFactor(0.9)
                            .foregroundStyle(activeTab == tab ? Color.white : MoveMatchPalette.textOnCard)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 10)
                            .background(activeTab == tab ? MoveMatchPalette.primary : .white)
                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.vertical, 1)
        }
        .padding(8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .padding(.horizontal, 20)
    }

    private var categoryTabs: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(categories, id: \.self) { category in
                    Button {
                        activeCategory = category
                    } label: {
                        Text(category.rawValue)
                            .font(.caption.weight(.bold))
                            .foregroundStyle(
                                activeCategory == category
                                    ? Color.white
                                    : MoveMatchPalette.textOnCard
                            )
                            .padding(.horizontal, 14)
                            .padding(.vertical, 10)
                            .background(
                                activeCategory == category ? MoveMatchPalette.primary : Color.white,
                                in: Capsule()
                            )
                            .overlay(
                                Capsule()
                                    .stroke(
                                        activeCategory == category
                                            ? Color.clear
                                            : MoveMatchPalette.textOnCard.opacity(0.32),
                                        lineWidth: 1.5
                                    )
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 20)
        }
    }

    @ViewBuilder
    private var tabBody: some View {
        VStack(alignment: .leading, spacing: 16) {
            switch activeTab {
            case .forYou:
                ForEach(filteredForYouFeed) { post in
                    CommunityFeedCard(post: post, liked: likedPosts.contains(post.id), onLike: { toggleLike(post.id) })
                }
            case .following:
                followingBody
            case .challenges:
                challengesBody
            case .explore:
                exploreBody
            }
        }
        .padding(.horizontal, 20)
        .animation(.spring(response: 0.34, dampingFraction: 0.9), value: activeTab)
    }

    private var filteredForYouFeed: [CommunityPost] {
        let all = userPosts + forYouPosts
        if activeCategory == .all { return all }
        return all.filter { $0.category == activeCategory }
    }

    private var followingBody: some View {
        VStack(alignment: .leading, spacing: 16) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 14) {
                    ForEach(stories) { story in
                        Button {
                            selectedStorySeed = selectedStorySeed == story.avatarSeed ? nil : story.avatarSeed
                        } label: {
                            VStack(spacing: 8) {
                                Circle()
                                    .fill((selectedStorySeed == story.avatarSeed ? MoveMatchPalette.primary : Color.gray).opacity(story.active ? 0.18 : 0.12))
                                    .frame(width: 62, height: 62)
                                    .overlay(Text(String(story.name.prefix(1))).font(.headline.weight(.bold)))
                                    .overlay(
                                        Circle()
                                            .stroke(selectedStorySeed == story.avatarSeed ? MoveMatchPalette.primary : (story.active ? MoveMatchPalette.primary.opacity(0.5) : .clear), lineWidth: 3)
                                    )
                                Text(story.name)
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(selectedStorySeed == story.avatarSeed ? MoveMatchPalette.primaryDark : MoveMatchPalette.textOnCard)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            ForEach(filteredFollowingPosts) { post in
                CommunityCompactPostCard(post: post, liked: likedPosts.contains(post.id), onLike: { toggleLike(post.id) })
            }
        }
    }

    private var filteredFollowingPosts: [CommunityPost] {
        guard let selectedStorySeed else { return followingPosts }
        return followingPosts.filter { $0.avatarSeed == selectedStorySeed }
    }

    private var challengesBody: some View {
        VStack(alignment: .leading, spacing: 16) {
            ForEach(communityChallenges) { challenge in
                let joined = joinedChallenges.contains(challenge.id)
                VStack(alignment: .leading, spacing: 12) {
                    ZStack(alignment: .topLeading) {
                        RemoteImageCard(urlString: challenge.imageURL)
                            .frame(height: 178)
                        HStack {
                            HStack(spacing: 6) {
                                if challenge.isHot {
                                    Label("Hot", systemImage: "flame.fill")
                                        .font(.caption2.weight(.bold))
                                        .foregroundStyle(.orange)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 6)
                                        .background(.white.opacity(0.9))
                                        .clipShape(Capsule())
                                }
                                Text(challenge.creatorType)
                                    .font(.caption2.weight(.bold))
                                    .foregroundStyle(.white)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 6)
                                    .background((challenge.creatorType == "Official" ? Color.blue : Color.orange).opacity(0.9))
                                    .clipShape(Capsule())
                            }
                            Spacer()
                            if joined {
                                Text("Joined")
                                    .font(.caption.weight(.bold))
                                    .foregroundStyle(.white)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .background(MoveMatchPalette.primary.opacity(0.95))
                                    .clipShape(Capsule())
                            }
                        }
                        .padding(12)
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))

                    VStack(alignment: .leading, spacing: 6) {
                        Text(challenge.title)
                            .font(.headline)
                            .foregroundStyle(MoveMatchPalette.textOnCard)
                        Text(challenge.subtitle)
                            .font(.caption)
                            .foregroundStyle(MoveMatchPalette.textOnCardMuted)
                        Text(challenge.description)
                            .font(.subheadline)
                            .foregroundStyle(MoveMatchPalette.textOnCardMuted)
                    }

                    HStack {
                        Label("\(challenge.joinedCount + (joined ? 1 : 0)) joined", systemImage: "person.2.fill")
                        Label("\(challenge.submissions) submissions", systemImage: "video.fill")
                        Spacer()
                        Label("Top \(challenge.topScore)", systemImage: "trophy.fill")
                            .foregroundStyle(.orange)
                    }
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(MoveMatchPalette.textSecondary)

                    WrapTagRow(tags: challenge.tags)

                    HStack(spacing: 10) {
                        Button("Intro") {
                            selectedCommunityChallenge = challenge
                        }
                        .buttonStyle(.bordered)

                        Button(joined ? "Joined" : "Join Challenge") {
                            if joined {
                                joinedChallenges.remove(challenge.id)
                            } else {
                                joinedChallenges.insert(challenge.id)
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(joined ? MoveMatchPalette.primary : .orange)
                    }
                }
                .padding(16)
                .background(.white)
                .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            }
        }
    }

    private var exploreBody: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 14) {
            ForEach(exploreSports) { sport in
                VStack(alignment: .leading, spacing: 10) {
                    RemoteImageCard(urlString: sport.imageURL)
                        .frame(height: 130)
                    Text(sport.title)
                        .font(.headline)
                    Text(sport.subtitle)
                        .font(.footnote)
                        .foregroundStyle(MoveMatchPalette.textSecondary)
                    Text(sport.members)
                        .font(.caption.weight(.bold))
                        .foregroundStyle(MoveMatchPalette.primaryDark)
                }
                .padding(12)
                .background(.white)
                .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
            }
        }
    }

    private func toggleLike(_ id: Int) {
        if likedPosts.contains(id) {
            likedPosts.remove(id)
        } else {
            likedPosts.insert(id)
        }
    }

    private func createMenuRow(icon: String, title: String, subtitle: String) -> some View {
        HStack(spacing: 10) {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.gray.opacity(0.08))
                .frame(width: 40, height: 40)
                .overlay(Image(systemName: icon).foregroundStyle(MoveMatchPalette.primaryDark))
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(MoveMatchPalette.textOnCard)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(MoveMatchPalette.textOnCardMuted)
            }
            Spacer()
        }
        .padding(10)
        .background(Color.gray.opacity(0.04))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

private struct CommunityFeedCard: View {
    let post: CommunityPost
    let liked: Bool
    let onLike: () -> Void

    private var trimmedContent: String {
        post.content.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // 1) Author (same structure for every post; never overlaid on media)
            HStack(alignment: .top, spacing: 12) {
                avatar(seed: post.avatarSeed)
                VStack(alignment: .leading, spacing: 3) {
                    Text(post.userName)
                        .font(.headline)
                        .foregroundStyle(MoveMatchPalette.textOnCard)
                    Text("\(post.handle) · \(post.location) · \(post.time)")
                        .font(.caption)
                        .foregroundStyle(MoveMatchPalette.textOnCardMuted)
                }
                Spacer(minLength: 0)
                if let aiScore = post.aiScore {
                    Text("AI Score \(aiScore)")
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(.green)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(.green.opacity(0.12))
                        .clipShape(Capsule())
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)

            if !trimmedContent.isEmpty {
                Text(post.content)
                    .font(.subheadline)
                    .foregroundStyle(MoveMatchPalette.textOnCard)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
            }

            // 2) Image only (tags & actions are below, never on top of the photo)
            if let imageURL = post.imageURL {
                RemoteImageCard(urlString: imageURL)
                    .frame(maxWidth: .infinity)
                    .frame(height: 250)
                    .clipped()
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
            }

            HStack(alignment: .center, spacing: 8) {
                ForEach(post.tags, id: \.self) { tag in
                    Text(tag)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(MoveMatchPalette.textOnCardMuted)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Color(red: 0.90, green: 0.91, blue: 0.94))
                        .clipShape(Capsule())
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 2)

            HStack(spacing: 8) {
                socialButton(
                    systemImage: "heart.fill",
                    text: "\(post.likes + (liked ? 1 : 0))",
                    tint: liked ? .red : MoveMatchPalette.textOnCard,
                    filled: liked,
                    action: onLike
                )
                socialButton(systemImage: "message.fill", text: "\(post.comments)", tint: .blue, filled: true, action: {})
                socialButton(systemImage: "square.and.arrow.up.fill", text: "\(post.shares)", tint: MoveMatchPalette.primaryDark, filled: true, action: {})
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 16)
            .padding(.top, 4)
            .padding(.bottom, 14)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
    }

    private func avatar(seed: String) -> some View {
        Circle()
            .fill(MoveMatchPalette.primary.opacity(0.18))
            .frame(width: 48, height: 48)
            .overlay(
                Text(String(seed.prefix(1)))
                    .font(.headline.weight(.bold))
                    .foregroundStyle(MoveMatchPalette.textOnCard)
            )
    }

    private func socialButton(systemImage: String, text: String, tint: Color, filled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: systemImage)
                Text(text)
            }
            .font(.caption.weight(.bold))
            .foregroundStyle(tint)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(tint.opacity(filled ? 0.12 : 0.08))
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

private struct CommunityCompactPostCard: View {
    let post: CommunityPost
    let liked: Bool
    let onLike: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                Circle()
                    .fill(MoveMatchPalette.primary.opacity(0.18))
                    .frame(width: 48, height: 48)
                    .overlay(Text(String(post.avatarSeed.prefix(1))).font(.headline.weight(.bold)))
                VStack(alignment: .leading, spacing: 4) {
                    Text(post.userName)
                        .font(.headline)
                    Text("\(post.handle) · \(post.location) · \(post.time)")
                        .font(.caption)
                        .foregroundStyle(MoveMatchPalette.textSecondary)
                    Text(post.content)
                        .font(.subheadline)
                }
                if let thumbnailURL = post.thumbnailURL {
                    RemoteImageCard(urlString: thumbnailURL)
                        .frame(width: 76, height: 76)
                }
            }

            WrapTagRow(tags: post.tags)

            HStack(spacing: 8) {
                Button(action: onLike) {
                    Label("\(post.likes + (liked ? 1 : 0))", systemImage: "heart.fill")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(liked ? .red : .gray)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background((liked ? Color.red : Color.gray).opacity(0.08))
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)

                TextField("Add a comment...", text: .constant(""))
                    .font(.caption)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .background(Color.gray.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
        }
        .padding(16)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
    }
}

private struct CommunityCreatePostSheet: View {
    let onCreate: (CommunityPost) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var content = ""
    @State private var selectedCategory: CommunityCategory = .training

    var body: some View {
        NavigationStack {
            Form {
                Section("Post") {
                    TextField("Share your update...", text: $content, axis: .vertical)
                        .lineLimit(5, reservesSpace: true)
                }
                Section("Category") {
                    Picker("Category", selection: $selectedCategory) {
                        ForEach([CommunityCategory.nearby, .training, .science, .nutrition, .lifestyle], id: \.self) { category in
                            Text(category.rawValue).tag(category)
                        }
                    }
                }
            }
            .navigationTitle("Create Post")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Post") {
                        let post = CommunityPost(
                            id: Int.random(in: 1000 ... 9999),
                            userName: "Alex Chen",
                            handle: "@alexchen",
                            avatarSeed: "Alex",
                            location: "Hong Kong",
                            content: content,
                            imageURL: nil,
                            thumbnailURL: nil,
                            tags: ["#MoveMatch", "#\(selectedCategory.rawValue.replacingOccurrences(of: " ", with: ""))"],
                            likes: 0,
                            comments: 0,
                            shares: 0,
                            time: "now",
                            category: selectedCategory,
                            aiScore: nil
                        )
                        onCreate(post)
                        dismiss()
                    }
                    .disabled(content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
}

private struct CommunityChallengeDetailSheet: View {
    let challenge: CommunityChallenge
    let joined: Bool
    let onToggleJoin: () -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    ZStack(alignment: .bottomLeading) {
                        RemoteImageCard(urlString: challenge.imageURL)
                            .frame(height: 240)
                            .overlay(
                                LinearGradient(colors: [.black.opacity(0.55), .clear], startPoint: .bottomLeading, endPoint: .topTrailing)
                            )
                        VStack(alignment: .leading, spacing: 8) {
                            HStack(spacing: 8) {
                                if challenge.isHot {
                                    Text("Hot")
                                        .font(.caption.weight(.bold))
                                        .foregroundStyle(.orange)
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 6)
                                        .background(.white.opacity(0.9))
                                        .clipShape(Capsule())
                                }
                                Text(challenge.creatorType)
                                    .font(.caption.weight(.bold))
                                    .foregroundStyle(.white)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .background((challenge.creatorType == "Official" ? Color.blue : Color.orange).opacity(0.9))
                                    .clipShape(Capsule())
                            }
                            Text(challenge.title)
                                .font(.largeTitle.bold())
                                .foregroundStyle(.white)
                            Text(challenge.subtitle)
                                .font(.headline)
                                .foregroundStyle(.white.opacity(0.88))
                        }
                        .padding(20)
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))

                    Text(challenge.description)
                        .font(.body)
                        .foregroundStyle(MoveMatchPalette.textSecondary)

                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                        detailStat(title: "Joined", value: "\(challenge.joinedCount + (joined ? 1 : 0))", icon: "person.2.fill", tint: .blue)
                        detailStat(title: "Submissions", value: "\(challenge.submissions)", icon: "video.fill", tint: .purple)
                        detailStat(title: "Top Score", value: "\(challenge.topScore)", icon: "trophy.fill", tint: .orange)
                    }

                    VStack(alignment: .leading, spacing: 12) {
                        Text("Tags")
                            .font(.headline.bold())
                        WrapTagRow(tags: challenge.tags)
                    }

                    VStack(alignment: .leading, spacing: 12) {
                        Text("How It Works")
                            .font(.headline.bold())
                        bulletRow("Join the challenge and keep your streak active during the event window.")
                        bulletRow("Upload progress clips or activity proof to remain eligible.")
                        bulletRow("Top entries receive \(challenge.prize) and a featured spot in Community.")
                    }
                }
                .padding(20)
            }
            .navigationTitle("Challenge Intro")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarBackground(Color.white, for: .navigationBar)
            .toolbarColorScheme(.light, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                        .foregroundStyle(MoveMatchPalette.textOnCard)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(joined ? "Joined" : "Join") {
                        onToggleJoin()
                        dismiss()
                    }
                    .foregroundStyle(MoveMatchPalette.primaryDark)
                }
            }
        }
    }

    private func detailStat(title: String, value: String, icon: String, tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: icon)
                .foregroundStyle(tint)
            Text(title)
                .font(.caption.weight(.bold))
                .foregroundStyle(MoveMatchPalette.textSecondary)
            Text(value)
                .font(.headline.bold())
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(Color.gray.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private func bulletRow(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Circle()
                .fill(Color.orange.opacity(0.24))
                .frame(width: 8, height: 8)
                .padding(.top, 6)
            Text(text)
                .font(.subheadline)
                .foregroundStyle(MoveMatchPalette.textSecondary)
            Spacer()
        }
        .padding(14)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}

private struct CommunityInventSportSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var sportName = ""
    @State private var description = ""
    @State private var difficulty = 3.0

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    HStack(spacing: 12) {
                        Circle()
                            .fill(Color.purple.opacity(0.14))
                            .frame(width: 52, height: 52)
                            .overlay(Image(systemName: "sparkles").foregroundStyle(.purple))
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Create New Sport")
                                .font(.title3.bold())
                            Text("Pitch a new idea, add simple rules, and publish it to the community.")
                                .font(.subheadline)
                                .foregroundStyle(MoveMatchPalette.textSecondary)
                        }
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Sport Name")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(MoveMatchPalette.textSecondary)
                        TextField("e.g. Reverse Basketball", text: $sportName)
                            .padding(14)
                            .background(Color.gray.opacity(0.08))
                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Rules & Description")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(MoveMatchPalette.textSecondary)
                        TextField("Describe how it works and what makes it unique...", text: $description, axis: .vertical)
                            .lineLimit(5, reservesSpace: true)
                            .padding(14)
                            .background(Color.gray.opacity(0.08))
                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Difficulty")
                                .font(.caption.weight(.bold))
                                .foregroundStyle(MoveMatchPalette.textSecondary)
                            Spacer()
                            Text(difficultyLabel)
                                .font(.caption.weight(.bold))
                                .foregroundStyle(MoveMatchPalette.primaryDark)
                        }
                        Slider(value: $difficulty, in: 1 ... 5, step: 1)
                            .tint(MoveMatchPalette.primaryDark)
                    }

                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .strokeBorder(style: StrokeStyle(lineWidth: 1.5, dash: [6]))
                        .foregroundStyle(Color.purple.opacity(0.35))
                        .frame(height: 150)
                        .overlay(
                            VStack(spacing: 8) {
                                Image(systemName: "video.badge.plus")
                                    .font(.title2)
                                    .foregroundStyle(.purple)
                                Text("Demo Video (Optional)")
                                    .font(.subheadline.weight(.bold))
                                Text("Add a short clip later to explain the rules.")
                                    .font(.caption)
                                    .foregroundStyle(MoveMatchPalette.textSecondary)
                            }
                        )
                }
                .padding(20)
            }
            .navigationTitle("Invent Sport")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Publish") { dismiss() }
                        .disabled(sportName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || description.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }

    private var difficultyLabel: String {
        switch Int(difficulty) {
        case 1: return "Beginner"
        case 2: return "Easy"
        case 3: return "Intermediate"
        case 4: return "Advanced"
        default: return "Expert"
        }
    }
}
