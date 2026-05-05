-- CamminoMod - Scegli il tuo cammino

local ROLEPLAY_X = -9689.599
local ROLEPLAY_Y = -234727.413
local ROLEPLAY_Z = 18725.025

local SAVE_FILE = "CamminoMod_giocatori.txt"
local chosenPlayers = {}
local spawnTimers = {}
local waitingForChoice = {}
local hookHandles = {}

local function LoadChosenPlayers()
    local file = io.open(SAVE_FILE, "r")
    if file then
        for line in file:lines() do
            local id = line:match("^%s*(.-)%s*$")
            if id and id ~= "" then
                chosenPlayers[id] = true
            end
        end
        file:close()
    end
    print("[CamminoMod] Giocatori registrati caricati")
end

local function SaveChosenPlayer(id)
    chosenPlayers[id] = true
    waitingForChoice[id] = nil
    spawnTimers[id] = nil
    local file = io.open(SAVE_FILE, "a")
    if file then
        file:write(id .. "\n")
        file:close()
    end
    print("[CamminoMod] Salvato: " .. id)
end

local function GetPlayerId(controller)
    local ok, state = pcall(function() return controller.PlayerState end)
    if ok and state and state:IsValid() then
        local ok2, name = pcall(function()
            return state.PlayerNamePrivate:ToString()
        end)
        if ok2 and name and name ~= "" and not name:match("^0x") then
            return name
        end
        return tostring(state:GetAddress())
    end
    return tostring(controller:GetAddress())
end

local function Teleport(controller)
    local ok, pawn = pcall(function() return controller.Pawn end)
    if ok and pawn and pawn:IsValid() then
        local loc = pawn:K2_GetActorLocation()
        loc.X = ROLEPLAY_X
        loc.Y = ROLEPLAY_Y
        loc.Z = ROLEPLAY_Z
        pawn:K2_SetActorLocation(loc, false, {}, false)
        print("[CamminoMod] Teletrasportato!")
    else
        print("[CamminoMod] Errore: pawn non valido per teletrasporto")
    end
end

local function ReleaseKeyHooks(id)
    if hookHandles[id] then
        for _, handle in ipairs(hookHandles[id]) do
            local ok = pcall(function() UnregisterHook(handle) end)
            if not ok then
                pcall(function() RemoveHook(handle) end)
            end
        end
        hookHandles[id] = nil
        print("[CamminoMod] Hook tasti rilasciati per: " .. id)
    end
end

local function ShowPanel(controller, id)
    waitingForChoice[id] = controller

    controller:ClientMessage(" ")
    controller:ClientMessage("╔══════════════════════════════════════════════════╗")
    controller:ClientMessage("            ★  SCEGLI IL TUO CAMMINO  ★            ")
    controller:ClientMessage("╠══════════════════════════════════════════════════╣")
    controller:ClientMessage(" ")
    controller:ClientMessage("  [ 1 ]  ── PLAYER ──")
    controller:ClientMessage(" ")
    controller:ClientMessage("  Vuoi vivere l'esperienza del server in modalita")
    controller:ClientMessage("  Player, dedicandoti al PVE & PVP, all'esplorazione,")
    controller:ClientMessage("  al crafting, alla costruzione e alla sopravvivenza")
    controller:ClientMessage("  libera? Allora premi il tasto 1 per continuare la")
    controller:ClientMessage("  strada attuale del Player, libera, selvaggia e")
    controller:ClientMessage("  piena di sfide.")
    controller:ClientMessage(" ")
    controller:ClientMessage("╠══════════════════════════════════════════════════╣")
    controller:ClientMessage(" ")
    controller:ClientMessage("  [ 2 ]  ── ROLEPLAYER ──")
    controller:ClientMessage(" ")
    controller:ClientMessage("  Vuoi invece immergerti nel mondo del server in")
    controller:ClientMessage("  modalita Roleplay, dove ogni gesto, parola e scelta")
    controller:ClientMessage("  danno vita a una storia profonda, emozionante e")
    controller:ClientMessage("  viva? Allora premi il tasto 2 per scegliere la")
    controller:ClientMessage("  strada del Roleplayer, intensa, realistica e ricca")
    controller:ClientMessage("  di emozioni.")
    controller:ClientMessage(" ")
    controller:ClientMessage("╚══════════════════════════════════════════════════╝")
    print("[CamminoMod] Pannello mostrato a: " .. id)

    -- Hook tasto 1
    local h1 = RegisterHook("/Script/Engine.PlayerController:InputKey", function(self, key, event, amount, bGamepad)
        local keyName = key:ToString()
        if keyName ~= "One" and keyName ~= "NumPadOne" then return end
        if event ~= 0 then return end

        local ctrl = self:get()
        if not ctrl or not ctrl:IsValid() then return end
        local cid = GetPlayerId(ctrl)
        if cid ~= id then return end
        if not waitingForChoice[cid] then return end

        ReleaseKeyHooks(cid)
        SaveChosenPlayer(cid)
        ctrl:ClientMessage(" ")
        ctrl:ClientMessage("  Hai scelto la strada del PLAYER.")
        ctrl:ClientMessage("  Libera, selvaggia e piena di sfide. Buona avventura!")
        ctrl:ClientMessage(" ")
        print("[CamminoMod] Scelta PLAYER: " .. cid)
    end)

    -- Hook tasto 2
    local h2 = RegisterHook("/Script/Engine.PlayerController:InputKey", function(self, key, event, amount, bGamepad)
        local keyName = key:ToString()
        if keyName ~= "Two" and keyName ~= "NumPadTwo" then return end
        if event ~= 0 then return end

        local ctrl = self:get()
        if not ctrl or not ctrl:IsValid() then return end
        local cid = GetPlayerId(ctrl)
        if cid ~= id then return end
        if not waitingForChoice[cid] then return end

        ReleaseKeyHooks(cid)
        SaveChosenPlayer(cid)
        ctrl:ClientMessage(" ")
        ctrl:ClientMessage("  Hai scelto la strada del ROLEPLAYER.")
        ctrl:ClientMessage("  Intensa, realistica e ricca di emozioni.")
        ctrl:ClientMessage("  Teletrasporto in corso...")
        ctrl:ClientMessage(" ")
        Teleport(ctrl)
        print("[CamminoMod] Scelta ROLEPLAY: " .. cid)
    end)

    hookHandles[id] = { h1, h2 }
end

RegisterHook("/Script/Engine.PlayerController:ClientRestart", function(self)
    local ok, controller = pcall(function() return self:get() end)
    if not ok or not controller or not controller:IsValid() then return end

    local id = GetPlayerId(controller)
    print("[CamminoMod] Spawn rilevato: " .. id)

    if chosenPlayers[id] then
        print("[CamminoMod] " .. id .. " ha gia scelto, skip")
        return
    end

    spawnTimers[id] = { controller = controller, time = os.time() }
    print("[CamminoMod] Timer avviato per: " .. id)
end)

RegisterHook("/Script/Engine.PlayerController:ClientSetHUD", function(self)
    local now = os.time()
    for id, data in pairs(spawnTimers) do
        if (now - data.time) >= 4 then
            spawnTimers[id] = nil
            local ok, valid = pcall(function() return data.controller:IsValid() end)
            if ok and valid and not chosenPlayers[id] and not waitingForChoice[id] then
                ShowPanel(data.controller, id)
            end
        end
    end
end)

LoadChosenPlayers()
print("[CamminoMod] Caricata! Pannello tasti 1/2 attivo")
