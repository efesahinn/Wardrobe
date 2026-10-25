# Application architecture

Wardrobe+ uses a feature-first structure. This foundation implements only the
application shell and a wardrobe home placeholder; product capabilities in the
proposal remain planned.

## Current structure

```text
lib/
  main.dart                 # Entry point: runApp only
  app.dart                  # MaterialApp configuration
  core/
    constants/              # Application-wide constants
    routing/                # Flutter SDK route table
    theme/                  # Central Material 3 theme
    widgets/                # Reusable presentation widgets
    services/               # Shared integrations when selected
  features/
    authentication/
    wardrobe/
      presentation/screens/home_screen.dart
    outfit_recommendations/
    smart_swap/
    favorites/
    wear_history/
    profile/
```

Each feature has a README describing its ownership. Reserved folders are kept
in Git through these useful notes rather than empty Dart classes or .gitkeep files.

## Layers added when needed

- **presentation/**: screens, feature widgets, and local UI state. The wardrobe
  home screen is the first implementation.
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
on features except for routing, which maps application paths to feature screens.
Avoid feature-to-feature presentation imports; share domain concepts through
explicit contracts when an actual workflow requires them.

Wardrobe owns garment management and metadata review. Recommendations own outfit
generation context. Smart Swap must preserve every non-selected item. Wear
history must preserve the final edited composition as a historical snapshot.
Favorites owns categorized saved outfits; profile owns account preferences.
Authentication owns sign-in and session behavior.

## Current choices

- Built-in MaterialApp routes with one home route; no routing dependency.
- One centralized light Material 3 theme, using the platform text scale.
- No state-management package, backend, AI, weather, or persistence integration.
- No service locator, dependency-injection framework, or speculative domain models.
- Existing project configuration and proposal documentation are preserved.

Run from the project root:

```sh
flutter analyze
flutter test
```

Widget tests verify startup through routing and the placeholder layout with a
small viewport and large text. Add domain and data tests as those layers appear.
