# Changelog

## [Unreleased]

## [0.1.8]

### Changed
- Tooltip: "Leer in (Durchschnitt)" is now "Leer in (Ø)" ("Empty in (Ø)")

## [0.1.7]

### Changed
- Ammo and quiver tooltip: the counts show their status by the slider settings (critical when empty, urgent up to "Warn at or below", warning up to the quiver-slot setting, otherwise OK); in "Total" the current value shows the status and the maximum is ivory; the averages (rounds per minute, time until empty) use the information color, the labels are ivory, each ammo type shows its item icon before the name, and the average row is labeled with the symbol Ø instead of the word

## [0.1.6]

### Changed
- Options overview page shows the logo at 256 px (`Media/Logo_256.tga`)

## [0.1.5]

### Added
- Design guidelines and color definitions under `documentation` (`design-guidelines.md`, `colors.json`)
- After a vendor refill a chat line "Ammo refilled: ..." in the success color (chat only, no screen message, no sound)

### Changed
- `Media/Logo.tga` is the light logo (light wordmark), readable on the dark options page and tooltip
- Tooltip values (supply, rounds per minute, time until empty) use the information color
- The refill popup is now named `AMO_RESTOCK_AMMO` instead of the leftover Glimpse name

## [0.1.4]

### Changed
- Options overview page and addon compartment tooltip use the full logo with wordmark (`Media/Logo.tga`)
- Addon compartment tooltip: the logo hangs large to the left of the tooltip, like ATT, instead of a small icon in the title line

## [0.1.3]

### Changed
- Options page rebuilt like Binds: an overview page with logo, version and author, and a "General" page with sections (heading on the left, divider line) in the A·M·O colors; sliders and checkboxes are plain Blizzard widgets, no AceConfig
- Debug switch and `/amo debug` removed: debug messages go to BugLab and are on automatically as soon as BugLab is detected
- Brand and interface colors from the A·M·O color system V1.0 in `AMO.colors`; warnings use its status colors: warning (gold), urgent (orange), critical (red)
- Logo, header banner, icon and color system added under `documentation/assets`

## [0.1.2]

### Added
- Wordmark A·M·O (ivory letters, gold dots) in the addon list, the options title and the tooltips
- Ammo and quiver tooltips: header with the larger logo and a divider line up to the right edge, like Binds

### Fixed
- Addon compartment tooltip raised "Wrong object type for function" on hover

## [0.1.1]

### Added
- Logo in the addon list, the options page, the addon compartment (top right of the minimap, logo in its tooltip); the compartment entry opens the options

## [0.1.0]

### Added
- First version: the hunter ammo helper from Glimpse: Classes as a standalone addon (no Glimpse needed)
