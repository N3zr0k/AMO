# Funktionen

Stand: 0.1.8-latest.1

| Funktion | Beschreibung |
| --- | --- |
| Munitionswarnung | Köcher bald leer (Hochrechnung aus dem Verbrauch im Kampf, ab einstellbarer Zahl gefüllter Köcherplätze), dringende Warnung bei wenigen Schuss, Warnung vor einem Dungeon bei zu wenig Munition; Sprüche je Volk |
| Tooltip | Auf Munition, Köcher und Munitionsbeutel: Vorrat je Art, Schuss pro Minute (Durchschnitt, letzter Kampf), Zeit bis leer |
| Munition anlegen | Optional: stärkste nutzbare Munition automatisch anlegen, bei leerem Stapel die nächst schwächere; nicht im Kampf |
| Nachkaufen | Am Händler Frage, ob der Köcher mit der stärksten nutzbaren Munition aufgefüllt werden soll |
| Abschalten | Option „Aktiv“ schaltet das ganze Addon ab; für andere Klassen als Jäger passiert nichts |
| Debug | Nur über die BugLab-Konsole, automatisch an, sobald BugLab erkannt wird (kein Schalter); ohne BugLab keine Debug-Meldungen. Probe `/amo equip` |

## Datenbank

AMO nutzt keine Glimpse-Datenbank. Einstellungen stehen in der SavedVariable `AMODB` (Profil: `enabled`, `ammo`).

| Namespace / SavedVariable | Lesen | Schreiben |
| --- | --- | --- |
| `AMODB` | AMO | AMO |
