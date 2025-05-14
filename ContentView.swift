import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            NavigationView { HomeView() }
                .tabItem {
                    Label("Home", systemImage: "house")
                }
            NavigationView { DietPlanView() }
                .tabItem {
                    Label("Diet Plan", systemImage: "leaf")
                }
            NavigationView { WorkoutPlanView() }
                .tabItem {
                    Label("Workout", systemImage: "figure.walk")
                }
            NavigationView { ProgressViewScreen() }
                .tabItem {
                    Label("Progress", systemImage: "chart.bar")
                }
            NavigationView { SettingsView() }
                .tabItem {
                    Label("Settings", systemImage: "gearshape")
                }
        }
        .accentColor(.orange)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
