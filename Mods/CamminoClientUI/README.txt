CamminoClientUI per VEIN / UE4SS

Questa e' la parte CLIENT della mod "Scegli il tuo cammino".

Installazione client:
- Copiare questa cartella in:
  Vein/Binaries/Win64/ue4ss/Mods/CamminoClientUI
- Aggiungere in:
  Vein/Binaries/Win64/ue4ss/Mods/mods.txt
  la riga:
  CamminoClientUI : 1

Installazione server:
- Il server deve avere CamminoMod attiva.
- CamminoMod riceve /player o /roleplay e teletrasporta.

Uso:
- Dopo lo spawn il client disegna un pannello a schermo.
- Il giocatore clicca PLAYER o ROLEPLAYER.
- PLAYER chiude il pannello e invia /player al server.
- ROLEPLAYER chiude il pannello e invia /roleplay al server.

Test manuale:
- Apri la console UE4SS/client e scrivi:
  cammino_ui
- Per chiuderlo:
  cammino_ui_close

Nota:
- Questa UI e' disegnata sull'HUD via Lua, non e' un Widget Blueprint .pak.
- Per un menu UMG nativo al 100% serve creare un Blueprint/pak client.
