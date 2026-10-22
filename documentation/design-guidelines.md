# A·M·O Design-Guidelines

Farbsystem V1.0, dunkle Oberfläche. Das Farbschema als Bild: `assets/a-m-o_color_system.png`, die Farbdefinitionen als JSON: `colors.json`. Im Code stehen die Farben in `AMO.colors` (`AMO/AMO/Core/AMO.lua`).

## Hauptfarben

| Farbe | HEX | Verwendung |
| --- | --- | --- |
| Gold | `#E1A93A` | Aktive Elemente, Buttons, Icons |
| Hunter Olive | `#1E2C0E` | Markenfarbe, dunkle Flächen |
| Ivory | `#FEFAEB` | Texte und helle Symbole |
| Black | `#000000` | Hintergrund und Header |

## Oberflächenfarben

| Farbe | HEX | Verwendung |
| --- | --- | --- |
| Background | `#0B1008` | Hintergrund |
| Surface | `#192513` | Flächen, Karten |
| Border | `#4B623D` | Rahmen, Trennlinien |
| Muted | `#AAB6A0` | Gedämpfte Texte (Beschriftungen, Version, Autor) |
| Gold Hover | `#F0C46D` | Gold beim Darüberfahren |

## Statusfarben für das Munitionsmanagement

| Zustand | HEX | Verwendung |
| --- | --- | --- |
| Warnung | `#E1A93A` | Köcher wird bald leer |
| Dringend | `#FFAA4A` | Nur noch wenige Schüsse |
| Kritisch | `#F16B68` | Munition leer |
| Erfolg | `#81C995` | Munition aufgefüllt |
| Information | `#6BB9F0` | Vorrat, Schussrate, Restzeit |

## Grundsätze

* Die Oberflächen überwiegend in dunklem Oliv gestalten.
* Gold ist die Markenfarbe und hebt aktive Schalter und wichtige Funktionen hervor.
* Ivory sorgt für gut lesbare Texte.
* Orange (Dringend) und Rot (Kritisch) ausschließlich für tatsächliche Warnungen einsetzen.
* Statusfarben sparsam verwenden: Munitionswarnungen sollen sofort erkennbar sein.
* Dieses Farbschema ist die Grundlage für die gesamte Addon-Oberfläche.

## Schriftzug

„A·M·O“: Buchstaben in Ivory, Punkte in Gold. Im Spiel als `AMO.wordmark`.
