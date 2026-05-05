-- CamminoMod - scelta iniziale Player / Roleplayer per server VEIN.
-- Nota: un vero widget cliccabile richiede codice/mod lato client. Questo script
-- e' pensato per funzionare server-side con UE4SS Lua.

local CONFIG = {
    PlayerLocation = { X = -177173.844, Y = 54661.179, Z = 13909.817, ZOffset = 0.0 },
    RoleplayLocation = { X = -16819.386, Y = -229951.400, Z = 18770.477, ZOffset = 0.0 },
    RoleplayRespawnLocation = { X = -9306.606, Y = -232095.486, Z = 18855.930, ZOffset = 0.0 },
    SafeSpawnZOffset = 0.0,
    SpawnSafetyHoldSeconds = 4.5,
    PlayerSpawnCrouch = true,
    PlayerCrouchDelaySeconds = 0.25,
    PromptDelaySeconds = 4,
    TeleportDelaySeconds = 2,
    PlayerInitialRefreshSeconds = 3,
    RoleplayInitialRefreshSeconds = 3,
    TeleportSavedChoiceOnReconnect = false,
    SaveFile = "ue4ss/Mods/CamminoMod/choices.txt",
    Debug = true,
}

local chosenPlayers = {}
local pendingPrompts = {}
local waitingForChoice = {}
local teleportedPawnKeys = {}
local tickHookRegistered = false
local hasTimerFallback = false
local unpackArgs = table.unpack or unpack

local function Log(message)
    print("[CamminoMod] " .. tostring(message) .. "\n")
end

local function Debug(message)
    if CONFIG.Debug then
        Log(message)
    end
end

local function IsValidObject(object)
    if not object then return false end
    local ok, valid = pcall(function() return object:IsValid() end)
    return ok and valid == true
end

local function SafeToString(value)
    if value == nil then return "" end
    if type(value) == "string" then return value end
    if type(value) == "number" or type(value) == "boolean" then return tostring(value) end

    local ok, result = pcall(function()
        if value.ToString then return value:ToString() end
        return nil
    end)
    if ok and result and result ~= "" then return tostring(result) end

    ok, result = pcall(function()
        local inner = value:get()
        if inner == nil then return nil end
        if type(inner) == "string" then return inner end
        if inner.ToString then return inner:ToString() end
        return tostring(inner)
    end)
    if ok and result and result ~= "" then return tostring(result) end

    return tostring(value)
end

local function DelayMs(seconds)
    local value = tonumber(SafeToString(seconds)) or 0
    return math.floor((value * 1000) + 0.5)
end

local function LooksLikeUnstableObjectId(text)
    text = tostring(text or "")
    if text == "" or text == "None" then return true end
    if text:match("^0x") then return true end
    if text:match("UScriptStruct:") then return true end
    if text:match("UObject:") then return true end
    if text:match("FUniqueNetId") and not text:match("%d%d%d%d%d%d%d%d") then return true end
    if text:match("^userdata") then return true end
    return false
end

local function Send(controller, message)
    if not IsValidObject(controller) then return end
    -- Client_SendNotification ha firme non certe in VEIN e puo' crashare se chiamata male.
    -- ClientMessage e' tenuto solo come tentativo non essenziale.
    pcall(function() controller:ClientMessage(tostring(message)) end)
end

local function NormalizeId(id)
    id = tostring(id or ""):gsub("^%s+", ""):gsub("%s+$", "")
    return id
end

local function NormalizeChoice(choice)
    choice = tostring(choice or ""):lower():gsub("^%s+", ""):gsub("%s+$", "")
    if choice == "rp" or choice == "roleplay" then
        return "roleplayer"
    end
    if choice == "player" or choice == "roleplayer" then
        return choice
    end
    return ""
end

local function ChoiceLocation(choice, useRespawnLocation)
    choice = NormalizeChoice(choice)
    if choice == "player" then return CONFIG.PlayerLocation end
    if choice == "roleplayer" and useRespawnLocation then return CONFIG.RoleplayRespawnLocation end
    if choice == "roleplayer" then return CONFIG.RoleplayLocation end
    return nil
end

local function GetPlayerId(controller)
    if not IsValidObject(controller) then return "" end

    local ok, playerState = pcall(function() return controller.PlayerState end)
    if ok and IsValidObject(playerState) then
        local candidates = {}

        table.insert(candidates, function() return playerState.ID end)
        table.insert(candidates, function() return playerState.PlayerStateID end)
        table.insert(candidates, function() return playerState.UniqueId end)
        table.insert(candidates, function() return playerState:GetUniqueId() end)
        table.insert(candidates, function() return playerState.CharacterPlayerID end)
        table.insert(candidates, function() return playerState:GetPlayerName() end)
        table.insert(candidates, function() return playerState.PlayerNamePrivate end)
        table.insert(candidates, function() return playerState.PlayerName end)

        for _, getter in ipairs(candidates) do
            local okValue, value = pcall(getter)
            if okValue then
                local text = NormalizeId(SafeToString(value))
                if not LooksLikeUnstableObjectId(text) then
                    return text
                end
            end
        end
    end

    local okAddress, address = pcall(function() return controller:GetAddress() end)
    if okAddress and address then
        return "controller_" .. tostring(address)
    end

    return ""
end

local function GetPlayerName(controller)
    if not IsValidObject(controller) then return "" end

    local ok, playerState = pcall(function() return controller.PlayerState end)
    if ok and IsValidObject(playerState) then
        local candidates = {
            function() return playerState:GetPlayerName() end,
            function() return playerState.PlayerNamePrivate end,
            function() return playerState.PlayerName end,
        }

        for _, getter in ipairs(candidates) do
            local okValue, value = pcall(getter)
            if okValue then
                local text = NormalizeId(SafeToString(value))
                if not LooksLikeUnstableObjectId(text) then
                    return text
                end
            end
        end
    end

    return ""
end

local function GetControllerIds(controller)
    local ids = {}
    local seen = {}

    local function add(id)
        id = NormalizeId(id)
        if id ~= "" and not seen[id] then
            table.insert(ids, id)
            seen[id] = true
        end
    end

    add(GetPlayerId(controller))
    add(GetPlayerName(controller))
    return ids
end

local function GetSavedChoiceForController(controller)
    for _, id in ipairs(GetControllerIds(controller)) do
        local choice = NormalizeChoice(chosenPlayers[id])
        if choice ~= "" then
            return choice, id
        end
    end

    return "", ""
end

local function GetWorldName(controller)
    if not IsValidObject(controller) then return "" end

    local ok, world = pcall(function() return controller:GetWorld() end)
    if ok and IsValidObject(world) then
        local fullName = ""
        pcall(function() fullName = world:GetFullName() end)
        if fullName ~= "" then return tostring(fullName) end
        pcall(function() fullName = world:GetName() end)
        if fullName ~= "" then return tostring(fullName) end
    end

    return ""
end

local function HasPlayablePawn(controller)
    if not IsValidObject(controller) then return false end

    local ok, pawn = pcall(function() return controller.Pawn end)
    if ok and IsValidObject(pawn) then return true end

    ok, pawn = pcall(function() return controller:GetPawn() end)
    return ok and IsValidObject(pawn)
end

local function ShouldHandleSpawn(controller, reason)
    if not IsValidObject(controller) then return false end

    local worldName = GetWorldName(controller)
    if worldName:match("MainMenu") then
        Debug("Spawn ignorato nel menu iniziale (" .. tostring(reason) .. ").")
        return false
    end

    if not HasPlayablePawn(controller) then
        Debug("Spawn ignorato: nessun pawn valido (" .. tostring(reason) .. ", world=" .. worldName .. ").")
        return false
    end

    return true
end

local function FindControllerById(id)
    id = NormalizeId(id)
    if id == "" then return nil end

    for _, data in pairs(waitingForChoice) do
        if data and IsValidObject(data.controller) then
            for _, controllerId in ipairs(GetControllerIds(data.controller)) do
                if controllerId == id then
                    return data.controller
                end
            end
        end
    end

    local ok, controllers = pcall(function() return FindAllOf("PlayerController") end)
    if ok and controllers then
        for _, controller in ipairs(controllers) do
            if IsValidObject(controller) then
                for _, controllerId in ipairs(GetControllerIds(controller)) do
                    if controllerId == id then
                        return controller
                    end
                end
            end
        end
    end

    return nil
end

local function LoadChoices()
    local file = io.open(CONFIG.SaveFile, "r")
    if not file then
        Debug("Nessun file scelte trovato, ne creo uno al primo salvataggio.")
        return
    end

    for line in file:lines() do
        local id = NormalizeId(tostring(line):match("^[^\t]+") or line)
        local choice = NormalizeChoice(tostring(line):match("\t(.+)$") or "")
        if id ~= "" and choice ~= "" then
            chosenPlayers[id] = choice
        end
    end
    file:close()
    Log("Scelte caricate da " .. CONFIG.SaveFile)
end

local function SaveChoice(id, choice)
    id = NormalizeId(id)
    if id == "" then return end

    choice = NormalizeChoice(choice)
    if choice == "" then return end

    chosenPlayers[id] = choice
    waitingForChoice[id] = nil
    pendingPrompts[id] = nil

    local file = io.open(CONFIG.SaveFile, "a")
    if file then
        file:write(id .. "\t" .. tostring(choice) .. "\n")
        file:close()
    else
        Log("ATTENZIONE: impossibile scrivere " .. CONFIG.SaveFile)
    end
end

local function RewriteChoicesFile()
    local file = io.open(CONFIG.SaveFile, "w")
    if not file then
        Log("ATTENZIONE: impossibile riscrivere " .. CONFIG.SaveFile)
        return
    end

    for id, choice in pairs(chosenPlayers) do
        choice = NormalizeChoice(choice)
        if choice ~= "" then
            file:write(id .. "\t" .. choice .. "\n")
        end
    end
    file:close()
end

local function GetPawn(controller)
    if not IsValidObject(controller) then return nil end

    local ok, pawn = pcall(function() return controller.Pawn end)
    if ok and IsValidObject(pawn) then return pawn end

    ok, pawn = pcall(function() return controller:GetPawn() end)
    if ok and IsValidObject(pawn) then return pawn end

    return nil
end

local function GetObjectKey(object)
    if not IsValidObject(object) then return "" end

    local key = ""
    pcall(function() key = object:GetFullName() end)
    if key ~= "" then return tostring(key) end

    pcall(function() key = object:GetName() end)
    if key ~= "" then return tostring(key) end

    pcall(function() key = object:GetAddress() end)
    if key ~= "" then return tostring(key) end

    return ""
end

local function GetPawnKey(controller)
    return GetObjectKey(GetPawn(controller))
end

local function ClearChoiceRuntimeState(controller)
    for _, id in ipairs(GetControllerIds(controller)) do
        waitingForChoice[id] = nil
        pendingPrompts[id] = nil
    end
end

local function SaveChoiceForController(controller, choice)
    local ids = GetControllerIds(controller)
    for _, id in ipairs(ids) do
        SaveChoice(id, choice)
    end

    return ids[1] or ""
end

local function PawnTeleportKey(controller, choice)
    local id = GetPlayerId(controller)
    local pawnKey = GetPawnKey(controller)
    if id == "" or pawnKey == "" then return "" end
    return id .. "|" .. NormalizeChoice(choice) .. "|" .. pawnKey
end

local function HasPawnTeleported(controller, choice)
    local key = PawnTeleportKey(controller, choice)
    return key ~= "" and teleportedPawnKeys[key] == true
end

local function MarkPawnTeleported(controller, choice)
    local key = PawnTeleportKey(controller, choice)
    if key ~= "" then
        teleportedPawnKeys[key] = true
    end
end

local function GetCharacterMovement(pawn)
    if not IsValidObject(pawn) then return nil end

    local movement = nil
    pcall(function() movement = pawn.CharacterMovement end)
    if not IsValidObject(movement) then
        pcall(function() movement = pawn:GetCharacterMovement() end)
    end

    return movement
end

local function ApplySpawnSafetyHold(controller, pawn, choice)
    local seconds = tonumber(SafeToString(CONFIG.SpawnSafetyHoldSeconds)) or 0
    if seconds <= 0 then return "" end

    choice = NormalizeChoice(choice)

    local function applyHeldState(held)
        local targetPawn = pawn
        if not IsValidObject(targetPawn) then
            targetPawn = GetPawn(controller)
        end
        if not IsValidObject(targetPawn) then return false end

        local movement = GetCharacterMovement(targetPawn)
        if IsValidObject(movement) then
            pcall(function() movement:StopMovementImmediately() end)
            pcall(function() movement.Velocity.X = 0.0 end)
            pcall(function() movement.Velocity.Y = 0.0 end)
            pcall(function() movement.Velocity.Z = 0.0 end)

            if held then
                pcall(function() targetPawn:SetCanBeDamaged(false) end)
                pcall(function() targetPawn.bCanBeDamaged = false end)
                pcall(function() movement.GravityScale = 0.0 end)
                pcall(function() movement:DisableMovement() end)
                pcall(function() movement:SetMovementMode(0) end)
                pcall(function() movement.MovementMode = 0 end)
            else
                pcall(function() targetPawn:SetCanBeDamaged(true) end)
                pcall(function() targetPawn.bCanBeDamaged = true end)
                pcall(function() movement.GravityScale = 1.0 end)
                pcall(function() movement:SetMovementMode(1) end)
                pcall(function() movement.MovementMode = 1 end)
                if choice == "player" then
                    pcall(function() movement.bWantsToCrouch = true end)
                end
            end
        end

        pcall(function() targetPawn:SetActorTickEnabled(true) end)
        return true
    end

    local held = applyHeldState(true)
    if type(ExecuteWithDelay) == "function" then
        ExecuteWithDelay(DelayMs(CONFIG.SpawnSafetyHoldSeconds), function()
            applyHeldState(false)
            Debug("Sicura anti-caduta spawn rilasciata per " .. tostring(choice))
        end)
    end

    if held then
        return " con sicura anti-caduta"
    end
    return ""
end

local function ApplyPlayerSpawnCrouch(controller, pawn, choice)
    if not CONFIG.PlayerSpawnCrouch or NormalizeChoice(choice) ~= "player" then
        return ""
    end

    local function runCrouch()
        local targetPawn = pawn
        if not IsValidObject(targetPawn) then
            targetPawn = GetPawn(controller)
        end
        if not IsValidObject(targetPawn) then return false end

        local didCrouch = false

        local ok = pcall(function() targetPawn:Crouch(false) end)
        didCrouch = didCrouch or ok

        if not didCrouch then
            ok = pcall(function() targetPawn:Crouch() end)
            didCrouch = didCrouch or ok
        end

        local movement = GetCharacterMovement(targetPawn)
        if IsValidObject(movement) then
            pcall(function() movement.bWantsToCrouch = true end)
            didCrouch = true
        end

        if didCrouch then
            Debug("Crouch player applicato dopo teleport.")
        else
            Debug("Crouch player non applicato: funzione non disponibile sul pawn.")
        end

        return didCrouch
    end

    runCrouch()
    if type(ExecuteWithDelay) == "function" then
        ExecuteWithDelay(DelayMs(CONFIG.PlayerCrouchDelaySeconds), runCrouch)
    end

    return " con crouch player"
end

local function TeleportToChoice(controller, choice, useRespawnLocation, skipSafetyHold)
    if not IsValidObject(controller) then
        return false, "controller non valido"
    end

    local target = ChoiceLocation(choice, useRespawnLocation)
    if not target then
        return false, "scelta non valida"
    end

    local pawn = GetPawn(controller)
    if not IsValidObject(pawn) then
        return false, "pawn non valido"
    end

    local okLoc, loc = pcall(function() return pawn:K2_GetActorLocation() end)
    if not okLoc or not loc then
        okLoc, loc = pcall(function() return pawn.RootComponent:K2_GetComponentLocation() end)
    end
    if not okLoc or not loc then
        return false, "posizione attuale non leggibile"
    end

    loc.X = target.X
    loc.Y = target.Y
    loc.Z = target.Z + (target.ZOffset or CONFIG.SafeSpawnZOffset or 0.0)

    local hit = {}
    local moved = false

    local okSet, result = pcall(function()
        return pawn:K2_SetActorLocation(loc, false, hit, true)
    end)
    if okSet then
        moved = result ~= false
    end

    if not moved then
        local okRot, rot = pcall(function() return pawn:K2_GetActorRotation() end)
        if not okRot or not rot then
            okRot, rot = pcall(function() return pawn.RootComponent:K2_GetComponentRotation() end)
        end

        if okRot and rot then
            okSet, result = pcall(function()
                return pawn:K2_SetActorLocationAndRotation(loc, rot, false, hit, true)
            end)
            if okSet then
                moved = result ~= false
            end
        end
    end

    if moved then
        MarkPawnTeleported(controller, choice)
        local safetyNote = ""
        if not skipSafetyHold then
            safetyNote = ApplySpawnSafetyHold(controller, pawn, choice)
        end
        local crouchNote = ApplyPlayerSpawnCrouch(controller, pawn, choice)
        return true, "teleport " .. NormalizeChoice(choice) .. " eseguito a " ..
            tostring(loc.X) .. ", " .. tostring(loc.Y) .. ", " .. tostring(loc.Z) .. safetyNote .. crouchNote
    end

    return false, "funzioni teleport fallite"
end

local function ScheduleChoiceRefresh(controller, choice, delaySeconds, useRespawnLocation, reason)
    if type(ExecuteWithDelay) ~= "function" then return end
    choice = NormalizeChoice(choice)
    if choice == "" then return end

    ExecuteWithDelay(DelayMs(delaySeconds), function()
        if not IsValidObject(controller) then return end
        if not ShouldHandleSpawn(controller, reason or (choice .. " refresh")) then return end

        local ok, teleportReason = TeleportToChoice(controller, choice, useRespawnLocation, true)
        local id = GetPlayerId(controller)
        if ok then
            Log((id ~= "" and id or "giocatore") .. " refresh " .. choice .. ": " .. tostring(teleportReason))
        else
            Log("Refresh " .. choice .. " fallito per " .. (id ~= "" and id or "giocatore") .. ": " .. tostring(teleportReason))
        end
    end)
end

local function ScheduleRoleplayInitialRefresh(controller)
    ScheduleChoiceRefresh(controller, "roleplayer", CONFIG.RoleplayInitialRefreshSeconds, false, "roleplayer initial refresh")
end

local function ScheduleRoleplayRespawnRefresh(controller)
    ScheduleChoiceRefresh(controller, "roleplayer", CONFIG.RoleplayInitialRefreshSeconds, true, "roleplayer respawn refresh")
end

local function SchedulePlayerRefresh(controller)
    ScheduleChoiceRefresh(controller, "player", CONFIG.PlayerInitialRefreshSeconds, false, "player refresh")
end

local function TeleportSavedChoiceIfNeeded(controller, choice, reason, force)
    choice = NormalizeChoice(choice)
    if choice == "" then return end
    if not ShouldHandleSpawn(controller, reason or "saved choice teleport") then return end
    if not force and CONFIG.TeleportSavedChoiceOnReconnect ~= true then
        Debug("Scelta salvata " .. choice .. " non teletrasportata: rientro normale o evento spawn non esplicito (" .. tostring(reason) .. ").")
        return
    end
    if HasPawnTeleported(controller, choice) then return end
    MarkPawnTeleported(controller, choice)

    local function runTeleport()
        if not IsValidObject(controller) then return end
        if not ShouldHandleSpawn(controller, "saved choice teleport delayed") then return end

        local useRespawnLocation = choice == "roleplayer"
        local ok, teleportReason = TeleportToChoice(controller, choice, useRespawnLocation)
        local id = GetPlayerId(controller)
        if ok then
            if choice == "player" then
                SchedulePlayerRefresh(controller)
            elseif choice == "roleplayer" then
                ScheduleRoleplayRespawnRefresh(controller)
            end
            Log((id ~= "" and id or "giocatore") .. " aveva gia' scelto " .. choice .. ": " .. teleportReason)
        else
            Log("Teleport automatico fallito per " .. (id ~= "" and id or "giocatore") .. ": " .. tostring(teleportReason))
        end
    end

    if type(ExecuteWithDelay) == "function" then
        ExecuteWithDelay(DelayMs(CONFIG.TeleportDelaySeconds), runTeleport)
    else
        runTeleport()
    end
end

local function ShowChoicePrompt(controller, id)
    local choice = GetSavedChoiceForController(controller)
    if choice ~= "" then return end
    if not IsValidObject(controller) then return end

    waitingForChoice[id] = { controller = controller, shownAt = os.time() }

    Send(controller, " ")
    Send(controller, "==============================")
    Send(controller, "      SCEGLI IL TUO CAMMINO")
    Send(controller, "==============================")
    Send(controller, "PLAYER: continua la tua avventura nello spawn scelto.")
    Send(controller, "ROLEPLAYER: verrai teletrasportato nella zona roleplay.")
    Send(controller, " ")
    Send(controller, "Scrivi in chat: /player oppure /roleplayer")
    Send(controller, "Se sei in locale/client con UE4SS puoi provare anche i tasti 1 e 2.")
    Send(controller, "==============================")

    Log("Prompt mostrato a " .. id)
end

local function ShowPromptIfStillNeeded(controller, id)
    local savedChoice = GetSavedChoiceForController(controller)
    if id == "" or savedChoice ~= "" then return end
    if waitingForChoice[id] then return end
    if ShouldHandleSpawn(controller, "delayed prompt") then
        ShowChoicePrompt(controller, id)
    end
end

local function QueuePrompt(controller, reason)
    if not IsValidObject(controller) then return end
    if not ShouldHandleSpawn(controller, reason) then return end

    local id = GetPlayerId(controller)
    if id == "" then
        Debug("Spawn ignorato: id giocatore non risolto.")
        return
    end

    local savedChoice = GetSavedChoiceForController(controller)
    if savedChoice ~= "" then
        ClearChoiceRuntimeState(controller)
        if CONFIG.TeleportSavedChoiceOnReconnect == true then
            Debug(id .. " ha gia' scelto " .. savedChoice .. ", teletrasporto automatico abilitato.")
            TeleportSavedChoiceIfNeeded(controller, savedChoice, reason, false)
        else
            Debug(id .. " ha gia' scelto " .. savedChoice .. ", rientro lasciato alla posizione salvata da VEIN.")
        end
        return
    end

    if type(ExecuteWithDelay) == "function" then
        ExecuteWithDelay(DelayMs(CONFIG.PromptDelaySeconds), function()
            ShowPromptIfStillNeeded(controller, id)
        end)
    elseif hasTimerFallback then
        pendingPrompts[id] = {
            controller = controller,
            showAt = os.time() + CONFIG.PromptDelaySeconds,
            reason = reason or "spawn",
        }
    else
        ShowPromptIfStillNeeded(controller, id)
    end

    Debug("Prompt programmato per " .. id .. " (" .. tostring(reason) .. ")")
end

local function Choose(controller, choice)
    if not IsValidObject(controller) then return false end

    local id = GetPlayerId(controller)
    if id == "" then return false end
    local savedChoice = GetSavedChoiceForController(controller)
    if savedChoice ~= "" then
        Log(id .. " ha gia' scelto " .. savedChoice .. ", scelta ignorata: " .. tostring(choice))
        TeleportSavedChoiceIfNeeded(controller, savedChoice, "choice already saved / comando esplicito", true)
        return true
    end

    choice = NormalizeChoice(choice)

    if choice == "player" then
        SaveChoiceForController(controller, "player")
        ClearChoiceRuntimeState(controller)
        Send(controller, " ")
        Send(controller, "[Cammino] Hai scelto PLAYER. Teletrasporto in corso...")
        local ok, reason = TeleportToChoice(controller, "player")
        if ok then
            SchedulePlayerRefresh(controller)
            Send(controller, "[Cammino] Teletrasporto completato.")
            Log(id .. " ha scelto PLAYER ed e' stato teletrasportato.")
        else
            Send(controller, "[Cammino] Teletrasporto non riuscito: " .. tostring(reason))
            Log("Teletrasporto player fallito per " .. id .. ": " .. tostring(reason))
        end
        return true
    end

    if choice == "roleplayer" then
        SaveChoiceForController(controller, "roleplayer")
        ClearChoiceRuntimeState(controller)
        Send(controller, " ")
        Send(controller, "[Cammino] Hai scelto ROLEPLAYER. Teletrasporto in corso...")

        local ok, reason = TeleportToChoice(controller, "roleplayer")
        if ok then
            ScheduleRoleplayInitialRefresh(controller)
            Send(controller, "[Cammino] Teletrasporto completato.")
            Log(id .. " ha scelto ROLEPLAYER ed e' stato teletrasportato.")
        else
            Send(controller, "[Cammino] Teletrasporto non riuscito: " .. tostring(reason))
            Log("Teletrasporto fallito per " .. id .. ": " .. tostring(reason))
        end
        return true
    end

    return false
end

local function TickPrompts()
    local now = os.time()
    for id, data in pairs(pendingPrompts) do
        if data and now >= data.showAt then
            pendingPrompts[id] = nil
            local savedChoice = ""
            if IsValidObject(data.controller) then
                savedChoice = GetSavedChoiceForController(data.controller)
            end
            if savedChoice == "" and IsValidObject(data.controller) then
                ShowChoicePrompt(data.controller, id)
            end
        end
    end
end

local function RegisterTickOnce()
    if tickHookRegistered then return end
    tickHookRegistered = true

    local okPlayerTick = pcall(function()
        RegisterHook("/Script/Engine.PlayerController:PlayerTick", function()
            TickPrompts()
        end)
    end)

    local okClientSetHud = pcall(function()
        RegisterHook("/Script/Engine.PlayerController:ClientSetHUD", function()
            TickPrompts()
        end)
    end)

    hasTimerFallback = okPlayerTick or okClientSetHud
    if not hasTimerFallback and type(ExecuteWithDelay) ~= "function" then
        Log("ATTENZIONE: nessun timer disponibile, i prompt verranno mostrati subito allo spawn.")
    end
end

local function TryParseChoiceText(text)
    text = tostring(text or ""):lower():gsub("^%s+", ""):gsub("%s+$", "")
    if text:match("^cammino_player") then
        return "player"
    end
    if text:match("^cammino_roleplay") or text:match("^cammino_roleplayer") then
        return "roleplayer"
    end
    if text == "/player" or text == "!player" or text == "player" or text == "cammino_player" then
        return "player"
    end
    if text == "/roleplayer" or text == "!roleplayer" or text == "/roleplay" or text == "!roleplay" or text == "/rp" or text == "!rp" or text == "roleplayer" or text == "roleplay" or text == "rp" or text == "cammino_roleplay" or text == "cammino_roleplayer" then
        return "roleplayer"
    end
    return nil
end

local function TryHandlePossibleChoice(controller, ...)
    if not IsValidObject(controller) then return false end

    for _, param in pairs({ ... }) do
        local text = SafeToString(param)
        Log("Chat/command candidate from " .. GetPlayerId(controller) .. ": " .. text)

        local choice = TryParseChoiceText(text)
        if choice then
            Choose(controller, choice)
            return true
        end
    end

    return false
end

local function RegisterHooks()
    RegisterHook("/Script/Engine.PlayerController:ClientRestart", function(self)
        local ok, controller = pcall(function() return self:get() end)
        if ok and IsValidObject(controller) then
            QueuePrompt(controller, "ClientRestart")
        end
    end)

    pcall(function()
        RegisterHook("/Script/Vein.VeinPlayerController:Server_SelectCharacter", function(self)
            local ok, controller = pcall(function() return self:get() end)
            if ok and IsValidObject(controller) then
                QueuePrompt(controller, "Server_SelectCharacter")
            end
        end)
    end)

    pcall(function()
        RegisterHook("/Script/Vein.VeinPlayerController:Server_LoadCharacter", function(self)
            local ok, controller = pcall(function() return self:get() end)
            if ok and IsValidObject(controller) then
                QueuePrompt(controller, "Server_LoadCharacter")
            end
        end)
    end)

    pcall(function()
        RegisterHook("/Script/Vein.VeinPlayerController:Server_Say", function(self, message, p2, p3, p4)
            local ok, controller = pcall(function() return self:get() end)
            if not ok or not IsValidObject(controller) then return end

            TryHandlePossibleChoice(controller, message, p2, p3, p4)
        end)
    end)

    pcall(function()
        RegisterHook("/Script/Vein.VeinPlayerController:Server_Exec", function(self, command, p2, p3, p4)
            local ok, controller = pcall(function() return self:get() end)
            if not ok or not IsValidObject(controller) then return end

            TryHandlePossibleChoice(controller, command, p2, p3, p4)
        end)
    end)

    pcall(function()
        RegisterHook("/Script/Engine.PlayerController:InputKey", function(self, key, eventType)
            local ok, controller = pcall(function() return self:get() end)
            if not ok or not IsValidObject(controller) then return end

            local id = GetPlayerId(controller)
            if id == "" or not waitingForChoice[id] then return end

            local keyName = SafeToString(key)
            local eventName = SafeToString(eventType)
            if eventName ~= "" and eventName ~= "0" and eventName ~= "IE_Pressed" then return end

            if keyName == "One" or keyName == "NumPadOne" or keyName == "1" then
                Choose(controller, "player")
            elseif keyName == "Two" or keyName == "NumPadTwo" or keyName == "2" then
                Choose(controller, "roleplayer")
            end
        end)
    end)

    RegisterConsoleCommandHandler("cammino_status", function()
        local pending = 0
        local waiting = 0
        local chosen = 0
        for _ in pairs(pendingPrompts) do pending = pending + 1 end
        for _ in pairs(waitingForChoice) do waiting = waiting + 1 end
        for _ in pairs(chosenPlayers) do chosen = chosen + 1 end
        Log("status: chosen=" .. chosen .. " waiting=" .. waiting .. " pending=" .. pending)
        return true
    end)

    RegisterConsoleCommandHandler("cammino_show", function(_, params)
        local id = params and params[1] or ""
        local controller = FindControllerById(id)
        if controller then
            ShowChoicePrompt(controller, GetPlayerId(controller))
        else
            Log("cammino_show: giocatore non trovato: " .. tostring(id))
        end
        return true
    end)

    RegisterConsoleCommandHandler("cammino_choose", function(_, params)
        local id = params and params[1] or ""
        local choice = params and params[2] or ""
        local controller = FindControllerById(id)
        if controller then
            Choose(controller, choice)
        else
            Log("cammino_choose: giocatore non trovato: " .. tostring(id))
        end
        return true
    end)

    RegisterConsoleCommandHandler("cammino_roleplay", function(_, params)
        local id = params and params[1] or ""
        local controller = FindControllerById(id)
        if controller then
            Choose(controller, "roleplayer")
        else
            Log("cammino_roleplay: giocatore non trovato: " .. tostring(id))
        end
        return true
    end)

    RegisterConsoleCommandHandler("cammino_player", function(_, params)
        local id = params and params[1] or ""
        local controller = FindControllerById(id)
        if controller then
            Choose(controller, "player")
        else
            Log("cammino_player: giocatore non trovato: " .. tostring(id))
        end
        return true
    end)

    RegisterConsoleCommandHandler("cammino_reset", function(_, params)
        local id = NormalizeId(params and params[1] or "")
        if id == "all" then
            chosenPlayers = {}
            waitingForChoice = {}
            pendingPrompts = {}
            teleportedPawnKeys = {}
            RewriteChoicesFile()
            Log("Tutte le scelte CamminoMod sono state resettate.")
            return true
        end

        if id == "" then
            Log("Uso: cammino_reset <id_giocatore|all>")
            return true
        end

        chosenPlayers[id] = nil
        RewriteChoicesFile()
        Log("Scelta resettata per: " .. id)
        return true
    end)

    RegisterTickOnce()
end

LoadChoices()
RegisterHooks()
Log("Caricata. Comandi chat: /player, /roleplayer, /roleplay. Console: cammino_status, cammino_show <id>, cammino_choose <id> <player|roleplayer>, cammino_roleplay <id>, cammino_player <id>, cammino_reset <id|all>.")
