# Dateien

Alle Dateien im Spielordner `AMO/`.

| Datei | Aufgabe | Datenbank | Weitere Abhängigkeiten |
| --- | --- | --- | --- |
| `AMO.toc` | Addon-Beschreibung (Interface 16001, SavedVariables `AMODB`) | – | optional BugLab |
| `AMO.xml` | Lädt Libs, Locales, Core, Module, Optionen | – | – |
| `Media/Logo.tga` | Logo mit Schriftzug (128x128): Optionen, Addon-Kompartment (Tooltip) | – | – |
| `Media/Logo_256.tga` | Dasselbe Logo in 256x256: Übersichtsseite der Optionen | – | – |
| `Media/Icon.tga` | Logo (128x128): Addon-Liste, Optionen, Addon-Kompartment (Tooltip), Kopfzeile im Item-Tooltip | – | – |
| `LICENSE` | MIT-Lizenz | – | – |
| `Libs/Libs.xml` | Lädt die eingebetteten Bibliotheken | – | – |
| `Libs/*` | Ace3-Teilmenge: LibStub, CallbackHandler, AceAddon, AceEvent, AceDB, AceLocale, AceGUI, AceConfig | – | – |
| `Locales/Locales.xml` | Lädt die Sprachen | – | – |
| `Locales/enUS.lua`, `Locales/deDE.lua` | Texte der Oberfläche | – | – |
| `Core/Core.xml` | Lädt die Kerndateien vor den Modulen | – | – |
| `Core/AMO.lua` | Addon-Objekt, Datenbank `AMODB`, Ereignisse, Meldungen, Anmeldung der Proben | `AMODB` lesen/schreiben | AceDB |
| `Core/AMODebug.lua` | Debug-Meldungen über BugLab, Anmeldung beim Login | – | BugLab (optional) |
| `Core/AMONotify.lua` | Große Meldung und Hinweis mit Ton, Mindestabstand | – | Blizzard: `RaidNotice_AddMessage`, `PlaySound` |
| `Core/AMOTooltip.lua` | Zeilen in Item-Tooltips | – | Blizzard: `TooltipDataProcessor` |
| `Core/AMOCompartment.lua` | Eintrag im Addon-Kompartment (Minikarte) mit Logo im Tooltip, Klick öffnet die Optionen | – | Blizzard: `AddonCompartmentFrame` |
| `Core/Options.xml` | Lädt Optionen und Befehle nach den Modulen | – | – |
| `Core/AMOOptions.lua` | Optionsseite: Übersicht (Logo, Version, Autor) und Unterseite Allgemein mit Abschnitten; Blizzard-Bausteine, kein AceConfig | `AMODB` lesen/schreiben | Blizzard: `Settings`, `CreateFrame` |
| `Core/AMOCommands.lua` | Slash-Befehl `/amo`, Prüfungen | – | – |
| `Modules/Modules.xml` | Lädt die Module | – | – |
| `Modules/Ammo/Ammo.xml` | Lädt die Munitionsfunktion | – | – |
| `Modules/Ammo/Ammo.lua` | Munitionswarnungen: Köcher bald leer, wenige Schuss, zu wenig vor einem Dungeon | `AMODB` lesen | Blizzard: `GetInventoryItemCount`, `IsInInstance`, Taschen |
| `Modules/Ammo/AmmoRestock.lua` | Am Händler Auffüllen anbieten | – | Blizzard: `GetMerchantItemInfo`, `BuyMerchantItem` |
| `Modules/Ammo/AmmoEquip.lua` | Beste nutzbare Munition anlegen; Probe `/amo equip` | `AMODB` lesen | Blizzard: `PickupContainerItem`, `PickupInventoryItem` |
| `Modules/Ammo/AmmoStats.lua` | Misst den Verbrauch (Schuss pro Minute) | – | – |
| `Modules/Ammo/AmmoTooltip.lua` | Tooltip auf Munition, Köcher, Beutel | `AMODB` lesen | Blizzard: Taschen |
| `Modules/Ammo/AmmoOptions.lua` | Optionen der Munition als Daten für die Optionsseite | `AMODB` lesen/schreiben | – |
| `Modules/Ammo/AmmoTexts.lua` | Meldungstexte je Sprache und Volk | – | – |
