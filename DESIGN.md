# Shogunate – Game Design

Roblox-Kampfspiel (Luau) im Samurai-Setting. Inspiriert von Schul-Kampfspielen mit Reroll-System, aber mit eigenem Thema: Samurai statt Schüler, Clans, Reroll von Kampfstil und Katana.

## Eckdaten
- **Plattform:** Roblox, alle Spieler nutzen **R6**-Avatare (in Studio: Game Settings → Avatar → R6, Auswahl sperren).
- **Genre:** PvP-Nahkampf mit Clans und Reroll.
- **Sprache der Doku:** Deutsch.
- **Map:** baut der Entwickler selbst (Dojo, Tempel, Burg o. Ä.). Tools wie ForgeGUI können Modelle, Bilder, Sounds und Texturen liefern.
- **Animationen:** Der Entwickler kann nicht gut animieren, deshalb gibt es Code-Animationen als Platzhalter. Echte Animationen kommen später.

## Map
- **Art:** Samurai-Dorf im Edo-Stil, Abendstimmung. Ein Dorf, kein kleiner Ort.
- **Größe:** groß (etwa 60 % einer JJS-Map). Genaue Studs-Maße stehen noch aus.
- **Gehege:** hohe dunkle Holzmauer mit Ziegeldach rundherum, Steinlaternen (aus dem ersten Konzeptbild, sollen genau so bleiben).
- **Schrein** im Dorf.
- **Arena als eigenes Gebäude** (PvP-Regel noch klären, siehe Annahmen).
- **Hügel** mit japanischen Steintreppen, oben das **Hauptgebäude der Seirin** in Schwarz, nur für sie.
- **Die 3 anderen Clan-Gebäude** im Dorf verteilt: Hao (gelb), Rengoku (rot), Genji (grün).
- Konzeptbilder werden mit ForgeGUI erzeugt; Modelle kommen ebenfalls von ForgeGUI.

## Kernschleife
1. Beitritt → einen von 4 Clans wählen (Pflicht, am Anfang, nur einmal).
2. Kämpfen (4er-M1-Kombo, Block, Dash).
3. Kills geben +60 HP.
4. Kampfstil und Katana per Reroll (Robux) verbessern.

## Clans
| Clan    | Kleidung/Aura | HP  | Blocks | Besonderheit |
|---------|---------------|-----|--------|--------------|
| Hao     | Gelb          | 90  | 2 (-1) | 1.1x Schaden, 1.6x Angriffsgeschwindigkeit |
| Rengoku | Rot           | 100 | 3      | 1.3x Schaden; unter 30 HP insgesamt 1.5x |
| Seirin  | Schwarz       | 100 | 3      | Dash-Cooldown 1.75x schneller |
| Genji   | Grün          | 120 | 4 (+1) | 0.8x Laufgeschwindigkeit |

- Shirt und Hose sehen einfarbig in der Clanfarbe aus.
- Die Kleidungsfarbe ist zugleich die Aurafarbe. Jeder Clan hat eine Clan-Aura-Barriere.

## Kampfregeln
- 100 HP Basis (je Clan abweichend, siehe Tabelle).
- **Block:** Standard 3 Blocks (clanabhängig). Jeder Block fängt einen Schlag ab. Alle 2,5 s regeneriert 1 Block. Beim Blocken erscheint ein Schild-GUI.
- Blocken mit 0 Blocks und getroffen werden → 0,8 s Stun.
- **Im Kampf:** 30 % langsamer, damit man nicht wegrennen kann.
- **Dash:** weicht M1s aus, 0,4 s i-Frames, Cooldown 4 s (Seirin 4 / 1,75 ≈ 2,29 s).
- **Kill:** +60 HP (maximal Max-HP).
- **M1-Kombo:** 4 Schläge, jeder Kampfstil hat eigene Schlaganimationen.
- **Steuerung:** Linksklick = Schlag, F = Block (halten), Q = Dash.

## Reroll
- **Bezahlung:** Robux (Developer Products). IDs in `Shared/StyleConfig.lua` eintragen. In Studio ohne ID gratis zum Testen.
- **Seltenheiten:** Rare 65 %, Epic 28 %, Legendary 5 %, Shogun 2 %.
- **Kampfstile:** Rare Kiken, Epic Tsuken, Legendary Shiken, Shogun King. Kleine Schadensboni: 1.0x / 1.05x / 1.10x / 1.15x.
- **Katanas (nur Optik, keine Werte):** Rare Tetsu, Kage; Epic Tsuki, Hayate; Legendary Murasame, Kusanagi; Shogun Tenka Goken.
- Das neue Ergebnis ersetzt das alte sofort.
- Eigene Katana-Modelle: `ServerStorage.Katanas.<Name>` (Model mit PrimaryPart oder Part). Sonst Platzhalter.

## Annahmen (bitte bestätigen oder ändern)
- Rengoku unter 30 HP: 1.5x ersetzt die 1.3x (nicht 1.3 × 1.5).
- Block ist richtungsunabhängig.
- Treffer auf einen Spieler mit 0 Blocks beim Blocken: voller Schaden + Stun.
- "Im Kampf" = 6 s nach dem letzten Schlag, den man austeilt oder einsteckt.
- Startausrüstung: Kiken und Tetsu.
- Spieler ohne Clan sind unverwundbar (Lobby).
- Alle Werte stehen in `Shared/CombatConfig.lua`, `Shared/ClanConfig.lua` und `Shared/StyleConfig.lua`.

## Code-Aufbau
- `Shared/` Konfigurationen (Kampf, Clans, Stile/Katanas, Animationen).
- `ServerScriptService/Modules/Combat.lua` Kampflogik (Treffer, Block, Dash, Stun, Kampfzustand, Kill-Heilung).
- `ServerScriptService/Modules/ProceduralAnim.lua` Code-Animationen für R6 (Winkel sind Schätzwerte, in Studio nachjustieren).
- `ServerScriptService/ClanService.server.lua` Clanwahl, Kleidung, Aura.
- `ServerScriptService/RerollService.server.lua` Reroll und Katana-Ausrüstung.
- `StarterPlayerScripts/CombatController.client.lua` Eingaben, Clanwahl-Menü, Block-Anzeige, Reroll-Menü.
- `ServerStorage/Builders/` Bau-Skripte für Map-Objekte aus Parts (z. B. `SakuraTree`). Aufruf über die Command Bar in Studio.
- Echte Animationen: AnimationIds in `Shared/AnimationConfig.lua` eintragen, sie ersetzen die Code-Animationen automatisch.

## Roadmap
- [x] Clanwahl, Aura, Kleidung
- [x] M1-Kombo (4 Treffer), Block, Dash, Stun, Kampfzustand, Kill-Heilung
- [x] Kampfstile, Katanas, Reroll (Robux, Server-Roll, neues ersetzt altes)
- [x] Code-Animationen als Platzhalter (R6)
- [ ] Alles in Studio testen und Animationswinkel nachjustieren
- [ ] Developer Products für den Reroll anlegen
- [ ] Echte Animationen
- [ ] Map
- [ ] Speichern (DataStore: Clan, Stil, Katana)
- [ ] Katana-Modelle, Effekte, Sounds
- [ ] Balancing

## Entwicklung
Rojo: `rojo serve` und in Roblox Studio über das Rojo-Plugin verbinden.
