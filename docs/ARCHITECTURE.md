# Application architecture

Wardrobe+ uses a feature-first structure. This foundation implements only the
application shell, navigation, and the first functional in-memory Digital
Wardrobe module. Other product capabilities in the proposal remain planned.

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
    wardrobe/
      domain/               # ClothingItem, category/season, repository contract
      data/                 # Seeded in-memory repository
      presentation/
        screens/            # Wardrobe grid, add/edit form, clothing details
        widgets/            # Local image with missing/unreadable fallback
        gallery_image_picker.dart
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
  secondary-route placeholders and functional wardrobe screens live here.
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

Home, Outfits, Profile, Favorites, and Wear History remain placeholders.
Authentication, recommendations, Smart Swap, favorites storage, wear logging,
profile editing, and external integrations remain unimplemented.

## Digital Wardrobe - Phase 1

### Data flow and lifetime

AppShell is the composition point. Its State creates one
InMemoryWardrobeRepository.seeded() instance and injects it into WardrobeScreen.
The IndexedStack keeps this screen and its selected filter/scroll state alive
when switching tabs. The repository is never recreated by build().

WardrobeScreen reads an immutable snapshot using the asynchronous
WardrobeRepository contract, filters it using the pure Dart filterClothingItems
function, and renders a responsive SliverGrid. All is represented by a null
category and is not stored as a clothing category. Loading, retry, empty wardrobe,
and no-filter-matches states are separate. Category and season use explicit enums;
the current small taxonomy is a Phase 1 choice, not an AI classification scheme.

The add form calls create(). Cards open a feature-local MaterialPageRoute to the
detail screen, which opens the same form with prefilled values for editing.
Successful updates return the saved item to refresh details. Returning from any
form/detail route reloads the grid from the same repository; deletion requires
confirmation. Forms disable duplicate submissions and show failure feedback.
No generic use-case wrappers, service locator, or state-management package is used.

ClothingItem is immutable pure Dart data: ID, name, category, color, season, and
optional image reference. Repository-generated IDs remain stable on update.
The in-memory repository validates/trims names and colors, rejects missing
mutation targets, and returns read-only snapshots. Names are limited to 80
characters and colors to 40 to keep manual entry practical.

Three clearly labeled development samples are loaded at app startup. All CRUD
changes are session-only: restarting/recreating the app shell restores the seed
data. This module does not save metadata or images to disk, Firebase, or a server.

### Gallery and presentation

image_picker is the only new direct dependency; its platform packages are
transitive dependencies in pubspec.lock. Gallery selection requests no full photo
metadata and uses a bounded image size where supported. The iOS photo-library
usage description is added to Info.plist. No camera or microphone permission
and no Android broad-storage permission are added.

The image path stays local and is optional. Canceling the picker preserves the
current image; edit can replace/remove it. Missing or unreadable images render
a clothing icon. Sample items deliberately use these placeholders. No image
quality checks, AI metadata, upload, durable file copying, or cloud storage is
implemented. Native gallery permission/device behavior still requires an Android
and iOS device smoke test. If Android kills the process while the gallery is
open, this Phase 1 session and unsaved form are discarded; lost-picker-result
recovery and durable storage are deferred together.

Grid column count adapts to width and text scale. Headings, cards, form fields,
detail content, and the confirmation dialog support scrolling and larger text.
The existing Material 3 theme and shared EmptyState are reused. Secondary
wardrobe routes cover the tab bar and Back restores the wardrobe tab.

### Replacing the store later

Implement WardrobeRepository in the data layer using Firebase (after separately
approving that integration), map remote records to ClothingItem, and change the
AppShell composition point to inject that implementation. Keep network/SDK types
out of domain and presentation. The async methods already provide a boundary
for network latency and errors; production work must additionally design auth
ownership, security rules, image uploads/reference resolution, and durable
storage. A remote implementation should not seed real user accounts.
Live remote synchronization can be added when needed; Phase 1 refreshes at route
boundaries and does not introduce a streaming layer.

### Tests

Repository tests cover CRUD, stable unique IDs, validation, immutable snapshots,
independent seeded sessions, and category filtering. Wardrobe widget tests cover
browsing, no matches, add/edit/delete, confirmation cancellation, validation,
gallery selection/cancellation/errors, image fallback, and small-screen large-text
flows. Gallery callbacks are injected in widget tests, so they do not open native
OS dialogs. The existing navigation tests are preserved.

### Responsive clothing pages

Details and the shared add/edit form use the feature-local ClothingPageLayout.
A LayoutBuilder measures the SafeArea viewport after Scaffold has resized for
the keyboard. A SingleChildScrollView contains a width-limited column with a
minimum height equal to the available viewport minus padding. Space between the
content and action groups places buttons near the bottom when everything fits;
when content is taller, it scrolls naturally. No forced always-scrollable physics,
unbounded Expanded, or fixed screen height is used. Image previews use aspect
ratios with maximum heights, rather than reserving the same height at every width.

Forms keep all fields mounted so off-screen validation remains active.
Scaffold handles keyboard insets once, scroll padding keeps focused text fields
reachable, and dragging dismisses the keyboard. The existing Material 3 theme,
gallery actions, metadata, validation, and CRUD route flow are preserved.

Responsive tests cover Details/Add/Edit at normal, small, landscape, and up to
3x text scale, safe-area padding, bottom-aligned actions without excess scroll
extent, and successful Add/Edit saves with simulated keyboard insets.
