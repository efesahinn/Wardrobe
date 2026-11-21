# Wardrobe

Phase 1 implements manual clothing browsing, category filtering, gallery image
selection, validated add/edit forms, detail views, and confirmed deletion.

- domain/: immutable ClothingItem, category/season enums, pure filtering, and the
  asynchronous WardrobeRepository contract.
- data/: in-memory CRUD and three development samples. All changes reset on app
  restart; this is not durable storage.
- presentation/: grid, add/edit form, details, and local-image fallback.

The app shell injects one repository instance. Forms and details share it, and
the list reloads on return. Future Firebase integration can replace the data
implementation without importing SDK types into domain/UI. Image-quality checks,
AI classification, optional sizing, and durable storage remain deferred.

See [architecture](../../../docs/ARCHITECTURE.md) for data flow and limitations.
