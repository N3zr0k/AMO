local AMO = LibStub("AceAddon-3.0"):GetAddon("AMO")

-- Meldungstexte der Munition; AMO:Say wählt zufällig einen, %d ist die Anzahl (bei ammoSoon die Minuten).
-- Neue Texte einfach in die Liste der Sprache eintragen.
local TEXTS = {
    enUS = {
        ammoEmpty = {
            "Your quiver is empty. Time to throw your best insults at the enemy.",
            "No ammo left. Your bow is now a very expensive stick.",
            "Out of ammo! Even a murloc would laugh at that.",
            "The quiver is empty. Say 'bang' really loud and hope for the best.",
        },
        ammoSoon = {
            "In about %d min your quiver is empty if you keep shooting like this.",
            "Keep that up and you are out of ammo in about %d min. Your pet is already packing.",
            "The quiver runs dry in about %d min at this pace. The vendor misses you.",
        },
        ammoSoonNoRate = {
            "Your quiver is running empty, only %d rounds left. Plan a shopping trip.",
            "The quiver is getting light: %d rounds. Even a hunter cannot shoot air.",
        },
        ammoLow = {
            "WARNING: only %d rounds left! Make every shot count, hunter!",
            "Only %d left in the quiver. Your trusty pet looks worried.",
            "Only %d shots left. The ammo vendor is calling your name!",
        },
        ammoDungeon = {
            "HALT! Only %d rounds in the quiver, and you want to go in there?",
            "Only %d rounds. The boss will be thrilled about that fair fight.",
            "Only %d shots left. Go shopping first, the dungeon will wait.",
        },
    },
    deDE = {
        ammoEmpty = {
            "Dein Köcher ist leer. Zeit, den Gegner mit Beleidigungen zu bewerfen.",
            "Keine Munition mehr. Dein Bogen ist jetzt ein sehr teurer Stock.",
            "Munition alle! Selbst ein Murloc würde darüber lachen.",
            "Der Köcher ist leer. Ruf ganz laut 'Peng' und hoffe aufs Beste.",
        },
        ammoSoon = {
            "Wenn du so weiterschießt, ist dein Köcher in etwa %d Min leer.",
            "So weiter und die Munition ist in etwa %d Min alle. Dein Tier packt schon die Koffer.",
            "In etwa %d Min ist der Köcher leer, so wie du ballerst. Der Händler vermisst dich.",
        },
        ammoSoonNoRate = {
            "Dein Köcher wird leer, nur noch %d Schuss. Plane einen Einkauf ein.",
            "Der Köcher wird leicht: %d Schuss. Auch ein Jäger kann nicht in die Luft schießen.",
        },
        ammoLow = {
            "ACHTUNG: nur noch %d Schuss! Jeder Schuss muss sitzen, Waidmann!",
            "Nur noch %d im Köcher. Dein treues Tier schaut schon besorgt.",
            "Nur noch %d Schuss. Der Munitionshändler ruft nach dir!",
        },
        ammoDungeon = {
            "HALT! Nur %d Schuss im Köcher und du willst da rein?",
            "Nur %d Schuss. Der Boss freut sich schon auf den fairen Kampf.",
            "Nur noch %d Schuss. Geh erst einkaufen, der Dungeon läuft nicht weg.",
        },
    },
}


-- Texte je Volk (UnitRace, zweiter Rückgabewert); ohne Eintrag gelten die allgemeinen Listen. Dringende Meldungen
-- (ammoLow, ammoDungeon) sind ernst formuliert, die anderen dürfen witzig sein.
local RACES = {
    enUS = {
        Dwarf = {
            ammoEmpty = { "By my beard, the quiver is empty! Not even a barrel of ale will fix that.", "No ammo left. A dwarf without bolts is just a short, angry bartender." },
            ammoSoon = { "At this pace the quiver is dry in about %d min, laddie. Ironforge is far away.", "About %d min of ammo left. Better than an empty mug, but not by much." },
            ammoSoonNoRate = { "Only %d rounds left, laddie. Time to visit the smith.", "The quiver is getting light: %d rounds. Even a dwarf cannot shoot beer foam." },
            ammoLow = { "WARNING: only %d rounds left! By Khaz Modan, restock now!", "ATTENTION: %d rounds. Do not enter the next fight unprepared." },
            ammoDungeon = { "STOP! Only %d rounds. Stone and steel do not make up for missing ammo.", "Only %d rounds in the quiver. Resupply before you go in." },
        },
        NightElf = {
            ammoEmpty = { "Elune, hear us: the quiver is empty. Not even the moon can fill it.", "No arrows left. The forest has fine branches, though." },
            ammoSoon = { "In about %d min the quiver runs dry, if you shoot like this. Even a wisp could count that.", "About %d min of arrows left. Ashenvale does not grow fletching." },
            ammoSoonNoRate = { "The quiver is almost bare: %d arrows. Elune does not sell ammo.", "Only %d arrows. Your moonlit patience is wearing thin." },
            ammoLow = { "WARNING: only %d arrows left! Elune guide your aim, but restock first.", "ATTENTION: %d arrows. The next fight needs more." },
            ammoDungeon = { "STOP! Only %d arrows. Not even the wilds go into the dark unprepared.", "Only %d arrows in the quiver. Restock before you enter." },
        },
        Orc = {
            ammoEmpty = { "Lok'tar ogar, but the quiver is empty! Time to throw rocks.", "No ammo left. Strong orcs punch their enemies instead." },
            ammoSoon = { "In about %d min the quiver is empty. For the Horde, buy more!", "About %d min of ammo left. Thrall would not approve of waste." },
            ammoSoonNoRate = { "Only %d rounds left. Blood and thunder need ammunition too.", "The quiver is nearly empty: %d rounds. Go and shop in Orgrimmar." },
            ammoLow = { "WARNING: only %d rounds! Restock now, warrior!", "ATTENTION: %d rounds. A fight without ammo is a quick one." },
            ammoDungeon = { "HALT! Only %d rounds. Even the Horde does not storm a dungeon with empty hands.", "Only %d rounds in the quiver. Resupply first." },
        },
        Tauren = {
            ammoEmpty = { "The Earth Mother weeps: your quiver is empty. Mu'sha would shake her head.", "No ammo left. A tauren can still trample the foe." },
            ammoSoon = { "In about %d min the quiver is empty. The great spirits advise a trip to Thunder Bluff.", "About %d min of ammo left. Plan like the patient hunter you are." },
            ammoSoonNoRate = { "The quiver grows light: %d rounds. The spirits whisper of a vendor.", "Only %d rounds. Even Mulgore's grass cannot be shot." },
            ammoLow = { "WARNING: only %d rounds left! The spirits urge you to restock.", "ATTENTION: %d rounds. Prepare before the next hunt." },
            ammoDungeon = { "STOP! Only %d rounds. Walk the path with a full quiver.", "Only %d rounds in the quiver. Fill it before you enter." },
        },
        Troll = {
            ammoEmpty = { "Dat quiver be empty, mon! Even da loa cannot shoot wit nothin'.", "No ammo left, ya. Time to throw some voodoo curses." },
            ammoSoon = { "In 'bout %d min da quiver be empty, ya mon. Sen'jin be callin' fo' a vendor.", "'Bout %d min o' ammo left. Dat be tight, mon." },
            ammoSoonNoRate = { "Only %d rounds left, mon. Da quiver get light.", "Da quiver be near empty: %d. Time fo' shoppin', ya." },
            ammoLow = { "WARNING: only %d rounds left, mon! Restock now.", "ATTENTION: %d rounds. Da next fight need more." },
            ammoDungeon = { "STOP, mon! Only %d rounds. Don' go in dere unprepared.", "Only %d rounds in da quiver. Resupply first." },
        },
    },
    deDE = {
        Dwarf = {
            ammoEmpty = { "Bei meinem Bart, der Köcher ist leer! Da hilft nicht mal ein Fass Bier.", "Keine Munition mehr. Ein Zwerg ohne Bolzen ist nur ein kleiner, wütender Wirt." },
            ammoSoon = { "In etwa %d Min ist der Köcher trocken, mein Junge. Eisenschmiede ist weit.", "Etwa %d Min Munition übrig. Besser als ein leerer Humpen, aber nicht viel." },
            ammoSoonNoRate = { "Nur noch %d Schuss, mein Junge. Zeit für einen Besuch beim Schmied.", "Der Köcher wird leicht: %d Schuss. Auch ein Zwerg kann keinen Bierschaum schießen." },
            ammoLow = { "ACHTUNG: nur noch %d Schuss! Bei Khaz Modan, kauf jetzt nach!", "WARNUNG: %d Schuss. Geh nicht unvorbereitet in den nächsten Kampf." },
            ammoDungeon = { "HALT! Nur %d Schuss. Stein und Stahl ersetzen keine Munition.", "Nur %d Schuss im Köcher. Kauf nach, bevor du hineingehst." },
        },
        NightElf = {
            ammoEmpty = { "Elune, hör uns: Der Köcher ist leer. Nicht einmal der Mond füllt ihn.", "Keine Pfeile mehr. Der Wald hat immerhin feine Äste." },
            ammoSoon = { "In etwa %d Min ist der Köcher leer, wenn du so schießt. Selbst ein Irrwisch kann das zählen.", "Etwa %d Min Pfeile übrig. Eschental züchtet keine Federn." },
            ammoSoonNoRate = { "Der Köcher ist fast leer: %d Pfeile. Elune verkauft keine Munition.", "Nur noch %d Pfeile. Deine mondhelle Geduld wird dünn." },
            ammoLow = { "ACHTUNG: nur noch %d Pfeile! Elune führe deinen Schuss, aber kauf erst nach.", "WARNUNG: %d Pfeile. Der nächste Kampf braucht mehr." },
            ammoDungeon = { "HALT! Nur %d Pfeile. Nicht einmal die Wildnis geht unvorbereitet ins Dunkel.", "Nur %d Pfeile im Köcher. Kauf nach, bevor du eintrittst." },
        },
        Orc = {
            ammoEmpty = { "Lok'tar ogar, aber der Köcher ist leer! Zeit, Steine zu werfen.", "Keine Munition mehr. Starke Orcs hauen ihre Feinde einfach." },
            ammoSoon = { "In etwa %d Min ist der Köcher leer. Für die Horde, kauf mehr!", "Etwa %d Min Munition übrig. Thrall würde Verschwendung nicht mögen." },
            ammoSoonNoRate = { "Nur noch %d Schuss. Auch Blut und Donner brauchen Munition.", "Der Köcher ist fast leer: %d Schuss. Geh einkaufen in Orgrimmar." },
            ammoLow = { "ACHTUNG: nur noch %d Schuss! Kauf jetzt nach, Krieger!", "WARNUNG: %d Schuss. Ein Kampf ohne Munition ist schnell vorbei." },
            ammoDungeon = { "HALT! Nur %d Schuss. Selbst die Horde stürmt keinen Dungeon mit leeren Händen.", "Nur %d Schuss im Köcher. Erst nachkaufen." },
        },
        Tauren = {
            ammoEmpty = { "Die Erdmutter weint: Dein Köcher ist leer. Mu'sha würde den Kopf schütteln.", "Keine Munition mehr. Ein Tauren kann den Feind immer noch niedertrampeln." },
            ammoSoon = { "In etwa %d Min ist der Köcher leer. Die Großen Geister raten zu einem Ausflug nach Donnerfels.", "Etwa %d Min Munition übrig. Plane wie der geduldige Jäger, der du bist." },
            ammoSoonNoRate = { "Der Köcher wird leichter: %d Schuss. Die Geister flüstern von einem Händler.", "Nur noch %d Schuss. Selbst das Gras von Mulgore kann man nicht schießen." },
            ammoLow = { "ACHTUNG: nur noch %d Schuss! Die Geister mahnen dich, nachzukaufen.", "WARNUNG: %d Schuss. Bereite dich vor der nächsten Jagd vor." },
            ammoDungeon = { "HALT! Nur %d Schuss. Geh den Pfad mit vollem Köcher.", "Nur %d Schuss im Köcher. Füll ihn, bevor du eintrittst." },
        },
        Troll = {
            ammoEmpty = { "Dat Köcher is leer, Mon! Nicht ma' die Loa können mit nix schießen.", "Keine Munition mehr, ya. Zeit für ein paar Voodoo-Flüche." },
            ammoSoon = { "In 'ner %d Min is dat Köcher leer, ya Mon. Sen'jin ruft nach 'nem Händler.", "Etwa %d Min Munition übrig. Dat wird eng, Mon." },
            ammoSoonNoRate = { "Nur noch %d Schuss, Mon. Dat Köcher wird leicht.", "Dat Köcher is fast leer: %d. Zeit zum Einkaufen, ya." },
            ammoLow = { "ACHTUNG: nur noch %d Schuss, Mon! Kauf jetzt nach.", "WARNUNG: %d Schuss. Der nächste Kampf braucht mehr." },
            ammoDungeon = { "HALT, Mon! Nur %d Schuss. Geh nich' unvorbereitet da rein.", "Nur %d Schuss im Köcher. Erst nachkaufen." },
        },
    },
}

AMO:AddTexts(TEXTS, RACES)
