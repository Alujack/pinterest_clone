//
//  pinterest_cloneApp.swift
//  pinterest_clone
//
//  Main application entry point
//

import SwiftUI
import AppKit

@main
struct PinterestCloneApp: App {
    // Initialize app on startup
    init() {
        print("🚀 Pinterest Clone Starting...")
        
        // Setup dependency injection
        Container.registerAppModules()
        
        // Setup plugins
        Task {
            await PluginManager.shared.registerBuiltInPlugins()
        }
        
        // Seed sample data (development only)
        #if DEBUG
        Task {
            try? await DatabaseManager.shared.seedSampleData()
            
            // Runtime examples commented out temporarily - uncomment to see demos
            // RuntimeExamples.demonstrateReflection()
            // await RuntimeExamples.demonstratePerformance()
            // RuntimeExamples.demonstrateFeatureFlags()
        }
        #endif
        
        print("✅ Pinterest Clone Initialized")
    }
    
    var body: some Scene {
        WindowGroup {
            MainView()
                .frame(minWidth: 1000, minHeight: 700)
        }
        .windowStyle(HiddenTitleBarWindowStyle())
        .commands {
            appCommands
        }
    }
    
    // MARK: - App Commands
    
    @CommandsBuilder
    var appCommands: some Commands {
        CommandGroup(replacing: .help) {
            Button("Learning Guide") {
                openLearningGuide()
            }
            
            Button("Plugin Manager") {
                openPluginManager()
            }
            
            #if DEBUG
            Divider()
            
            Button("Database Statistics") {
                showDatabaseStats()
            }
            
            Button("Performance Report") {
                PerformanceMonitor.shared.printStatistics()
            }
            
            Button("Clear Database") {
                clearDatabase()
            }
            #endif
        }
    }
    
    // MARK: - Helper Functions
    
    private func openLearningGuide() {
        let url = URL(fileURLWithPath: #file)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent("LEARNING_GUIDE.md")
        
        NSWorkspace.shared.open(url)
    }
    
    private func openPluginManager() {
        // Would open plugin management UI
        print("Opening plugin manager...")
    }
    
    #if DEBUG
    private func showDatabaseStats() {
        Task {
            if let stats = try? await DatabaseManager.shared.getStats() {
                print("""
                    
                    📊 Database Statistics:
                    =====================
                    Users: \(stats.userCount)
                    Boards: \(stats.boardCount)
                    Pins: \(stats.pinCount)
                    Comments: \(stats.commentCount)
                    Size: \(ByteCountFormatter.string(fromByteCount: stats.databaseSizeBytes, countStyle: .file))
                    =====================
                    
                    """)
            }
        }
    }
    
    private func clearDatabase() {
        Task {
            try? await DatabaseManager.shared.clearAllData()
            try? await DatabaseManager.shared.seedSampleData()
            print("✅ Database cleared and re-seeded")
        }
    }
    #endif
}

// MARK: - Main View

struct MainView: View {
    @State private var selectedTab = "Home"
    
    var body: some View {
        HStack(spacing: 0) {
            // Sidebar (from original design)
            ModernSidebar(selectedTab: $selectedTab)
            
            Divider()
            
            // Main content
            mainContent
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .background(Color(NSColor.windowBackgroundColor))
    }
    
    @ViewBuilder
    private var mainContent: some View {
        switch selectedTab {
        case "Home":
            PinGridView()
        case "Recent":
            RecentPinsView()
        case "Followings":
            FollowingsView()
        case "Messages":
            MessagesView()
        case "Notifications":
            NotificationsView()
        default:
            PinGridView()
        }
    }
}

// MARK: - Modern Sidebar

struct ModernSidebar: View {
    @Binding var selectedTab: String
    @Namespace var animation
    
    var body: some View {
        VStack(spacing: 22) {
            // Logo
            HStack {
                Image(systemName: "heart.circle.fill")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 45, height: 45)
                    .foregroundColor(.red)
                
                Text("Pinterest")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Spacer()
            }
            .padding(.top, 35)
            .padding(.leading, 10)
            
            // Navigation
            Group {
                SidebarButton(
                    image: "house.fill",
                    title: "Home",
                    selected: $selectedTab,
                    animation: animation
                )
                
                SidebarButton(
                    image: "clock.fill",
                    title: "Recent",
                    selected: $selectedTab,
                    animation: animation
                )
                
                SidebarButton(
                    image: "person.2.fill",
                    title: "Followings",
                    selected: $selectedTab,
                    animation: animation
                )
                
                HStack {
                    Text("Insights")
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)
                        .font(.caption)
                    Spacer()
                }
                .padding(.horizontal)
                .padding(.top, 10)
                
                SidebarButton(
                    image: "message.fill",
                    title: "Messages",
                    selected: $selectedTab,
                    animation: animation
                )
                
                SidebarButton(
                    image: "bell.fill",
                    title: "Notifications",
                    selected: $selectedTab,
                    animation: animation
                )
            }
            
            Spacer()
            
            // User profile
            userProfile
        }
        .frame(width: 260)
        .background(Color(NSColor.controlBackgroundColor).opacity(0.3))
    }
    
    private var userProfile: some View {
        HStack(spacing: 10) {
            Image(systemName: "person.circle.fill")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 35, height: 35)
                .foregroundColor(.blue)
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Learning User")
                    .font(.caption)
                    .fontWeight(.semibold)
                
                Text("Exploring Pinterest Clone")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .foregroundColor(.secondary)
                .font(.caption)
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 5)
        .padding(.horizontal)
        .padding(.bottom, 20)
    }
}

// MARK: - Sidebar Button

struct SidebarButton: View {
    let image: String
    let title: String
    @Binding var selected: String
    var animation: Namespace.ID
    
    var body: some View {
        Button(action: {
            withAnimation(.spring()) {
                selected = title
            }
        }) {
            HStack(spacing: 12) {
                Image(systemName: image)
                    .font(.title3)
                    .foregroundColor(selected == title ? .primary : .secondary)
                    .frame(width: 25)
                
                Text(title)
                    .font(.body)
                    .fontWeight(selected == title ? .semibold : .regular)
                    .foregroundColor(selected == title ? .primary : .secondary)
                
                Spacer()
                
                if selected == title {
                    Capsule()
                        .fill(Color.accentColor)
                        .frame(width: 3, height: 25)
                        .matchedGeometryEffect(id: "Tab", in: animation)
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            .background(
                selected == title ?
                Color.accentColor.opacity(0.1) : Color.clear
            )
            .cornerRadius(10)
        }
        .buttonStyle(PlainButtonStyle())
        .padding(.horizontal, 8)
    }
}

// MARK: - Placeholder Views

struct RecentPinsView: View {
    var body: some View {
        VStack {
            Text("Recent Pins")
                .font(.title)
            Text("Coming soon...")
                .foregroundColor(.secondary)
        }
    }
}

struct FollowingsView: View {
    var body: some View {
        VStack {
            Text("Following")
                .font(.title)
            Text("Coming soon...")
                .foregroundColor(.secondary)
        }
    }
}

struct MessagesView: View {
    var body: some View {
        VStack {
            Text("Messages")
                .font(.title)
            Text("Coming soon...")
                .foregroundColor(.secondary)
        }
    }
}

struct NotificationsView: View {
    var body: some View {
        VStack {
            Text("Notifications")
                .font(.title)
            Text("Coming soon...")
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Preview

#Preview {
    MainView()
}
