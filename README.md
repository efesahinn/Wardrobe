# Wardrobe+

Wardrobe+ is a mobile wardrobe assistant proposed for the **SE380 Mobile Application Development course**. The mobile client will be developed with **Flutter and Dart**.

Users photograph and add their real clothing items to a digital wardrobe, preferably against a plain white background. The application checks basic image quality, suggests clothing metadata with AI, and asks the user to confirm or correct the result. It then recommends several daily outfits made only from the user's own wardrobe, considering weather, occasion or destination, wearing history, and—at a later stage—optional calendar context.

A key interaction is **Smart Quick Swap**: the user can tap an item in a suggested outfit and immediately see compatible alternatives while the remaining outfit items stay fixed. Selecting **“I Wore This”** records the latest edited version of the outfit.

## Confirmed MVP scope

- User authentication
- Clothing photo capture/upload and image-quality feedback
- AI-suggested category, subcategory, color, season, and style
- User confirmation and correction of AI metadata
- Digital wardrobe browsing and item management
- Optional, category-appropriate size entered manually by the user
- Weather and occasion/destination input
- Multiple daily AI outfit recommendations
- Smart Quick Swap for a selected outfit item
- “I Wore This” logging of the final edited outfit
- Favorite outfits organized under categories such as Casual, Business, Formal, and Sport

Advanced analytics and optional calendar integration are planned for a later phase.

## Documentation

See the full [Project Proposal](docs/PROJECT_PROPOSAL.md) for requirements, user flow, architecture candidates, feasibility, milestones, risks, deliverables, and evaluation criteria. A formatted [PDF version](docs/Wardrobe_Plus_Project_Proposal.pdf) is also available for submission and download.

## Technology status

- **Confirmed:** Flutter and Dart mobile client
- **Proposed / subject to evaluation:** Firebase Authentication, Cloud Firestore, Cloud Storage, an external or hosted AI service, and a weather API

> Project status: proposal and planning. Features described here have not yet been presented as implemented.
