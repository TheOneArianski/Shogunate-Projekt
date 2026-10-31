# Shogunate – Game Design

Roblox-Kampfspiel (Luau, R6-Avatar): Samurai statt Schüler, Clans, Reroll von Kampfstil und Katana.

## Kernschleife
1. Beitritt → einen von 4 Clans wählen (Pflicht, am Anfang).
2. Kämpfen (4er-M1-Kombo, Block, Dash).
3. Kills geben +60 HP.
4. Kampfstil und Katana per Reroll verbessern (noch nicht umgesetzt).

## Clans
| Clan    | Farbe  | HP  | Blocks | Besonderheit |
|---------|--------|-----|--------|--------------|
| Hao     | Gelb   | 90  | 2 (-1) | 1.1x Schaden, 1.6x Angriffsgeschwindigkeit |
| Rengoku | Rot    | 100 | 3      | 1.3x Schaden; unter 30 HP insgesamt 1.5x |
| Seirin  | Schwarz| 100 | 3      | Dash-Cooldown 1.75x schneller |
| Genji   | Grün   | 120 | 4 (+1) | 0.8x Laufgeschwindigkeit |

Kleidungsfarbe = Aurafarbe. Shirt und Hose sind einfarbig. Jeder Clan hat eine Clan-Aura-Barriere.

## Kampfregeln
- 100 HP Basis.
- Block: 3 Blocks (clanabhängig), jeder Block fängt einen Schlag ab. Alle 2.5 s regeneriert 1 Block.
- Blocken mit 0 Blocks und getroffen werden → 0.8 s Stun.
- Schild-GUI beim Blocken.
- Im Kampf: 30 % langsamer (kein Weglaufen).
- Dash: weicht M1 aus, 0.4 s i-Frames, Cooldown 4 s (Seirin 4 / 1.75 ≈ 2.29 s).
- Kill → +60 HP (max. Max-HP).
- Jeder Kampfstil hat eigene Schlaganimationen.

## Annahmen (bitte bestätigen oder ändern)
- Rengoku unter 30 HP: 1.5x ersetzt die 1.3x (nicht 1.3 × 1.5).
- Block ist richtungsunabhängig.
- Treffer auf einen Spieler mit 0 Blocks beim Blocken: voller Schaden + Stun.
- "Im Kampf" = 6 s nach dem letzten Schlag, den man austeilt oder einsteckt.
- Alle Werte stehen in `Shared/CombatConfig.lua` und `Shared/ClanConfig.lua`.

## Roadmap
- [x] Clanwahl, Aura, Kleidung
- [x] M1-Kombo (4 Treffer), Block, Dash, Stun, Kampfzustand, Kill-Heilung
- [x] Code-Animationen als Platzhalter für R6 und R15 (`Modules/ProceduralAnim.lua`, Winkel müssen in Studio nachjustiert werden)
- [ ] Echte Animationen (AnimationIds in `Shared/AnimationConfig.lua` eintragen, ersetzen die Code-Animationen automatisch)
- [x] Kampfstile + Katana + Reroll (Robux, Server-Roll, neues ersetzt altes)
- [ ] Map
- [ ] Speichern (DataStore)
- [ ] Effekte, Sounds, Balancing

## Entwicklung
Rojo: `rojo serve` und in Roblox Studio verbinden.

## Reroll
- Bezahlung: Robux (Developer Products). IDs in `Shared/StyleConfig.lua` eintragen. In Studio ohne ID gratis zum Testen.
- Seltenheiten: Rare 65 %, Epic 28 %, Legendary 5 %, Shogun 2 %.
- Kampfstile: Rare Kiken, Epic Tsuken, Legendary Shiken, Shogun King. Schadensbonus 1.0 / 1.05 / 1.10 / 1.15.
- Katanas (nur Optik): Rare Tetsu, Kage; Epic Tsuki, Hayate; Legendary Murasame, Kusanagi; Shogun Tenka Goken.
- Das neue Ergebnis ersetzt das alte sofort. Start: Kiken und Tetsu (Annahme).
- Eigene Katana-Modelle: `ServerStorage.Katanas.<Name>` (Model mit PrimaryPart oder Part). Sonst Platzhalter.
