CamminoMod per VEIN / UE4SS

Struttura nuova:
- CamminoMod = parte SERVER. Salva le scelte e teletrasporta.
- CamminoClientUI = parte CLIENT. Disegna il pannello a schermo e gestisce i click.

Installazione server:
- La mod deve stare in: Vein/Binaries/Win64/ue4ss/Mods/CamminoMod/Scripts/main.lua
- La riga "CamminoMod : 1" deve stare in: Vein/Binaries/Win64/ue4ss/Mods/mods.txt

Installazione client:
- Ogni giocatore che deve vedere il pannello cliccabile deve avere:
  Vein/Binaries/Win64/ue4ss/Mods/CamminoClientUI/Scripts/main.lua
- Nel mods.txt del client deve esserci:
  CamminoClientUI : 1

Uso:
- Dopo lo spawn del personaggio, CamminoClientUI disegna il pannello "Scegli il tuo cammino".
- Player: scrivere in chat /player
- Roleplayer: scrivere in chat /roleplayer, /roleplay oppure /rp
- Se il pannello client funziona, non serve scrivere nulla: basta cliccare PLAYER o ROLEPLAYER.

Comandi console server:
- cammino_status
- cammino_show <id_giocatore>
- cammino_choose <id_giocatore> <player|roleplayer>
- cammino_roleplay <id_giocatore>
- cammino_player <id_giocatore>
- cammino_reset <id_giocatore|all>

Coordinate Roleplayer:
- Modifica CONFIG.RoleplayLocation in Scripts/main.lua.

Limite tecnico:
- Il server da solo non puo' disegnare UI cliccabile sui client.
- Il pannello cliccabile richiede CamminoClientUI installata sul client.
- Questa UI e' disegnata sull'HUD via Lua. Per un menu UMG nativo al 100% serve una mod Blueprint/pak client.
