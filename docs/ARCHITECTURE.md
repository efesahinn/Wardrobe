# Application architecture

Wardrobe+ uses a feature-first structure. This foundation implements only the
application shell and navigation placeholders; product capabilities in the
proposal remain planned.

## Current structure

```text
lib/
  main.dart                 # Entry point: runApp only
  app.dart                  # MaterialApp configuration
  core/
    constants/              # Application-wide constants
    routing/                # Route paths, route table, and app shell
    theme/                  # Central Material 3 theme
    widgets/                # Reusable presentation widgets
    services/               # Shared integrations when selected
  features/
    authentication/
    home/presentation/screens/home_screen.dart
    wardrobe/presentation/screens/wardrobe_screen.dart
    outfit_recommendations/presentation/screens/outfits_screen.dart
    smart_swap/
    favorites/presentation/screens/favorites_screen.dart
    wear_history/presentation/screens/wear_history_screen.dart
    profile/presentation/screens/profile_screen.dart
```

Each feature has a README describing its ownership. Reserved folders are kept
in Git through these useful notes rather than empty Dart classes or .gitkeep files.

## Layers added when needed

- **presentation/**: screens, feature widgets, and local UI state. Tab and
  secondary-route placeholders are the current implementations.
- **domain/**: pure Dart entities, business rules, and repository contracts when
  persistence or external behavior needs a boundary.
- **data/**: concrete repositories, serialization models, and local/remote data
  sources that implement the feature's domain contracts.

Create domain and data directories with their first real implementation.
Do not create empty layers, generic base repositories, or one-line use cases
that merely forward calls. Small features can start with presentation alone.

Presentation may depend on domain and core UI utilities. Data may depend on
domain and integration code. Domain must not import Flutter, data, or external
SDKs. app.dart (or a future composition point) will assemble implementations as
needed; widgets should not call backend SDKs directly.

## Ownership and shared code

Feature-specific models and widgets stay with their feature. Move code into core
only when it is application-wide or needed across features. core must not depend
on features except for routing, which composes feature screens in the shell and route table.
Avoid feature-to-feature presentation imports; share domain concepts through
explicit contracts when an actual workflow requires them.

Wardrobe owns garment management and metadata review. Recommendations own outfit
generation context. Smart Swap must preserve every non-selected item. Wear
history must preserve the final edited composition as a historical snapshot.
Favorites owns categorized saved outfits; profile owns account preferences.
Authentication owns sign-in and session behavior.

## Current choices

- Built-in MaterialApp routes with a four-tab shell and two secondary routes;
  no routing dependency.
- One centralized light Material 3 theme, using the platform text scale.
- No state-management package, backend, AI, weather, or persistence integration.
- No service locator, dependency-injection framework, or speculative domain models.
- Existing project configuration and proposal documentation are preserved.

Run from the project root:

```sh
flutter analyze
flutter test
```

Widget tests verify startup, tab switching, mounted state and scroll retention,
secondary-route Back behavior, layout at small/landscape/wide sizes and large
text scales, and navigation labels and touch targets. Add domain and data tests
as those layers appear.

## Navigation foundation

The root route (/) builds AppShell, which owns one Scaffold, the active tab's
AppBar title, SafeArea, and a Material 3 NavigationBar. The four destinations are
Home, Wardrobe, Outfits, and Profile. Each tab supplies content from its own
feature's presentation/screens folder. Home now has its own feature folder;
the original welcome content is preserved there.

AppShell uses a local selected index with setState and an IndexedStack. All four
tab subtrees stay mounted, retaining widget state and scroll offsets across tab
switches. This is session-only UI state: restarting the app returns to Home.
No persistence or additional state-management package is introduced.

Favorites is an action on Outfits; Wear History is an action on Profile. They
push /favorites and /wear-history onto the root Navigator. These full-page
placeholders have their own AppBars and standard Back controls. Returning reveals
the existing shell with its selected tab and scroll position intact. Bottom
navigation is covered on secondary pages; independent per-tab route stacks are
not needed for this foundation.

route_paths.dart contains only path constants, so feature screens can navigate
without importing the route table or other features. app_routes.dart composes
the shell and secondary screens. main.dart, app.dart, and the centralized theme
remain unchanged.

EmptyState now accepts optional actions, marks its heading semantically, and
keeps content in a scroll view with a capped reading width. Actions wrap when
space is tight. Screens honor platform text scaling and safe areas. The standard
NavigationBar provides always-visible labels, tooltips, selected semantics, and
Material touch targets; its SDK behavior controls navigation label scaling.
No text-scale override is applied by this app. Content can scroll in small or
landscape viewports, including at 2x and 3x text scales.

All destinations remain clearly identified placeholders. Authentication,
garment editing, recommendations, Smart Swap, favorites storage, wear logging,
profile editing, and external integrations remain unimplemented.
