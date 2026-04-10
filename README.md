# ConGrowing Flutter App

A complete Flutter rewrite of the ConGrowing social growth platform, converted from HTML/CSS/JavaScript.

## Project Structure

```
congrowing_flutter/
├── lib/
│   ├── main.dart                    # App entry point & routes
│   ├── utils/
│   │   ├── app_colors.dart          # Brand color constants
│   │   └── app_theme.dart           # Light & dark ThemeData
│   ├── widgets/
│   │   └── bottom_nav_bar.dart      # Shared bottom navigation bar
│   └── screens/
│       ├── login_screen.dart        # Login with form validation
│       ├── home_screen.dart         # Home feed: stories, connect, leaderboard, CRI
│       ├── messages_screen.dart     # Messages list
│       ├── chat_screen.dart         # Individual chat with typing dots
│       ├── call_screen.dart         # Connect / Call people
│       ├── notifications_screen.dart# Like / follow / comment notifications
│       ├── create_post_screen.dart  # Create new post
│       ├── my_profile_screen.dart   # User profile with post grid
│       ├── edit_profile_screen.dart # Edit profile form
│       ├── settings_screen.dart     # App settings with logout
│       ├── search_screen.dart       # Search users with live filter
│       ├── leaderboard_screen.dart  # Full leaderboard screen
│       ├── cri_analytics_screen.dart# CRI score with progress bars & bar chart
│       └── play_screen.dart         # TikTok-style vertical video feed
└── pubspec.yaml
```

## Screens Converted

| HTML Page | Flutter Screen |
|-----------|----------------|
| Login.html | LoginScreen |
| Home.html | HomeScreen |
| Messages.html | MessagesScreen |
| Chat.html | ChatScreen |
| Call.html | CallScreen |
| Notifications.html | NotificationsScreen |
| CreatePost.html | CreatePostScreen |
| MyProfile.html | MyProfileScreen |
| EditProfile.html | EditProfileScreen |
| Settings.html | SettingsScreen |
| Search.html | SearchScreen |
| Leaderboard.html | LeaderboardScreen |
| CRIanalytics.html | CriAnalyticsScreen |
| Play.html | PlayScreen |

## Getting Started

### Prerequisites
Install Flutter SDK: https://flutter.dev/docs/get-started/install

### Run the app
```bash
cd congrowing_flutter
flutter pub get
flutter run
```

### Demo Login
- **Username:** `Username`
- **Password:** `Password`

## Features
- 🎨 **Dark/Light theme** toggle preserved
- 🔐 **Auth guard** — Login required to access all screens
- 📱 **Bottom navigation** — Home, Call, Messages, Play, Profile
- 💬 **Chat** — Animated typing indicator, send messages
- 📊 **CRI Analytics** — Progress bars + bar chart history
- 🏆 **Leaderboard** — Podium + ranked full list
- 🎬 **Play** — Vertical scrolling video feed (TikTok-style)
- 🔔 **Notifications** — Like/follow/comment + system alerts
