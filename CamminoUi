local UEHelpers = require("UEHelpers")

-- CamminoClientUI - client-side UMG panel for CamminoMod.
-- Requires Vein/Content/Paks/LogicMods/CamminoChoice.pak.

local CONFIG = {
    DelaySeconds = 3.4,
    PlayerLocation = { X = -177173.844, Y = 54661.179, Z = 13909.817, ZOffset = 0.0 },
    RoleplayLocation = { X = -16819.386, Y = -229951.400, Z = 18770.477, ZOffset = 0.0 },
    RoleplayRespawnLocation = { X = -9306.606, Y = -232095.486, Z = 18855.930, ZOffset = 0.0 },
    SafeSpawnZOffset = 0.0,
    SpawnSafetyHoldSeconds = 4.5,
    PlayerSpawnCrouch = true,
    PlayerCrouchDelaySeconds = 0.25,
    TeleportDelaySeconds = 2,
    PlayerInitialRefreshSeconds = 3,
    RoleplayInitialRefreshSeconds = 3,
    DisableSavedChoiceTeleportOnReconnect = true,
    CharacterCreationTeleportWindowSeconds = 300,
    RoleplayIntroDelaySeconds = 2.2,
    RoleplayIntroImagePath = {
        "C:/Program Files (x86)/Steam/steamapps/common/Vein/Vein/Binaries/Win64/ue4ss/Mods/CamminoClientUI/Assets/spawn_roleplayer.png",
        "C:/Users/peppi/Downloads/spawn roleplayer.png",
    },
    RoleplayRespawnIntroDelaySeconds = 2.2,
    RoleplayRespawnIntroImagePath = {
        "C:/Program Files (x86)/Steam/steamapps/common/Vein/Vein/Binaries/Win64/ue4ss/Mods/CamminoClientUI/Assets/spawn_roleplayer_respawn.png",
        "C:/Users/peppi/Downloads/spawn roleplay dopo morte.png",
    },
    PlayerIntroDelaySeconds = 2.2,
    PlayerIntroImagePath = {
        "C:/Program Files (x86)/Steam/steamapps/common/Vein/Vein/Binaries/Win64/ue4ss/Mods/CamminoClientUI/Assets/spawn_player.png",
        "C:/Users/peppi/Downloads/inizio e morte player.png",
    },
    SkipVanillaStartLocation = true,
    VanillaStartLocationScanSeconds = 14,
    VanillaStartLocationScanIntervalSeconds = 0.35,
    StartLocationGuidelinesEnabled = false,
    StartLocationGuidelinesTitle = "Linee Guida",
    StartLocationGuidelines = {
        {
            Title = "Registra la tua esperienza",
            Body = "Ti consigliamo di tenere attiva una registrazione dello schermo mentre giochi. Se dovesse succedere qualcosa di contestato, un abuso, un bug, una situazione poco chiara, avere una prova video permette allo staff di intervenire nel modo corretto.",
        },
        {
            Title = "Rispetta la scelta",
            Body = "Se scegli di vivere il server in modalita' Roleplay, mi raccomando, resta coerente con il tuo personaggio. Ogni parola, gesto e decisione puo' creare conseguenze e rendere la storia piu' credibile per tutti.",
        },
        {
            Title = "Segnala senza discutere",
            Body = "Se qualcosa non va, evita litigi in chat o a voce. Piuttosto raccogli prove, segnala allo staff e lascia che la situazione venga valutata con calma.",
        },
        {
            Title = "Conferma e continua",
            Body = "Clicca qui per confermare di aver letto i suggerimenti e abilitare il tasto Termina. Dopo lo spawn potrai scegliere il tuo cammino tra Player e Roleplayer.",
        },
    },
    CharacterCreationWatchdogEnabled = false,
    CharacterCreationWatchdogIntervalSeconds = 1.5,
    RegisterCharacterCreationBlueprintHooks = false,
    WidgetClassPath = "/Game/Mods/CamminoChoice/WBP_CamminoChoice.WBP_CamminoChoice_C",
    WidgetAssetPath = "/Game/Mods/CamminoChoice/WBP_CamminoChoice.WBP_CamminoChoice",
    WidgetPackageName = "/Game/Mods/CamminoChoice/WBP_CamminoChoice",
    WidgetAssetName = "WBP_CamminoChoice_C",
    SaveFile = "ue4ss/Mods/CamminoClientUI/choices.txt",
    SharedSaveFile = "ue4ss/Mods/CamminoMod/choices.txt",
    Debug = false,
}

local state = {
    visible = false,
    shownOnce = false,
    shownPawnKeys = {},
    teleportedPawnKeys = {},
    currentPawnKey = "",
    controller = nil,
    widget = nil,
    choiceBackdropWidget = nil,
    choiceBackdropSerial = 0,
    roleplayIntroVisible = false,
    roleplayIntroWidget = nil,
    roleplayIntroController = nil,
    roleplayIntroButton = nil,
    roleplayIntroSerial = 0,
    vanillaStartLocationScanSerial = 0,
    vanillaStartLocationLastScanAt = 0,
    vanillaStartLocationHidden = {},
    startLocationGuidelinesWidget = nil,
    startLocationGuidelinesSerial = 0,
    startLocationGuidelinesScanSerial = 0,
    startLocationGuidelinesScanLastStart = 0,
    startLocationGuidelinesLastApplyAt = 0,
    preSpawnChoice = false,
    vanillaFinishInProgress = false,
    vanillaFinishFailureCount = 0,
    pendingInitialChoice = "",
    pendingInitialChoiceAt = 0,
    pendingSavedChoiceRespawn = "",
    pendingSavedChoiceRespawnAt = 0,
    awaitingStartLocationAfterUniqueness = false,
    awaitingStartLocationAt = 0,
    characterCreationScanSerial = 0,
    characterCreationScanLastStart = 0,
    characterCreationWatchdogStarted = false,
    characterCreationPanelRetrySerial = 0,
    characterCreationPanelWasBlocked = false,
    playerId = "",
}

local savedChoices = {}
local choicesLoaded = false

local function Log(message)
    print("[CamminoClientUI] " .. tostring(message) .. "\n")
end

local function Debug(message)
    if CONFIG.Debug then Log(message) end
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

local function SafeNumber(value, fallback)
    if type(value) == "number" then return value end
    local parsed = tonumber(SafeToString(value))
    if parsed then return parsed end
    return fallback or 0
end

local function DelayMs(seconds)
    return math.floor((SafeNumber(seconds, 0) * 1000) + 0.5)
end

local function NormalizeId(id)
    return tostring(id or ""):gsub("^%s+", ""):gsub("%s+$", "")
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

local function LoadChoiceFile(path)
    local file = io.open(path, "r")
    if not file then return end

    for line in file:lines() do
        local id = NormalizeId(tostring(line):match("^[^\t]+") or line)
        local choice = NormalizeChoice(tostring(line):match("\t(.+)$") or "")
        if id ~= "" and choice ~= "" then
            savedChoices[id] = choice
        end
    end

    file:close()
end

local function LoadChoices()
    if choicesLoaded then return end
    choicesLoaded = true
    LoadChoiceFile(CONFIG.SharedSaveFile)
    LoadChoiceFile(CONFIG.SaveFile)
end

local function SaveChoice(id, choice)
    id = NormalizeId(id)
    choice = NormalizeChoice(choice)
    if id == "" or choice == "" then return end

    savedChoices[id] = choice

    local file = io.open(CONFIG.SaveFile, "a")
    if file then
        file:write(id .. "\t" .. choice .. "\n")
        file:close()
    else
        Log("ATTENZIONE: impossibile scrivere " .. CONFIG.SaveFile)
    end
end

local function RewriteClientChoicesFile()
    local file = io.open(CONFIG.SaveFile, "w")
    if not file then
        Log("ATTENZIONE: impossibile riscrivere " .. CONFIG.SaveFile)
        return
    end

    for id, choice in pairs(savedChoices) do
        choice = NormalizeChoice(choice)
        if choice ~= "" then
            file:write(id .. "\t" .. choice .. "\n")
        end
    end

    file:close()
end

local function ReadOutNumber(value)
    if type(value) == "number" then return value end
    if type(value) == "table" then
        return tonumber(value[1] or value.X or value.Value or value.value or 0) or 0
    end

    local ok, inner = pcall(function() return value:get() end)
    if ok then return SafeNumber(inner, 0) end

    return SafeNumber(value, 0)
end

local function ReadVector2D(value)
    if not value then return nil, nil end

    if type(value) == "table" then
        local x = value.X or value.x or value[1]
        local y = value.Y or value.y or value[2]
        if x ~= nil and y ~= nil then return SafeNumber(x, 0), SafeNumber(y, 0) end
    end

    local ok, x = pcall(function() return value.X end)
    local okY, y = pcall(function() return value.Y end)
    if ok and okY and x ~= nil and y ~= nil then
        return SafeNumber(x, 0), SafeNumber(y, 0)
    end

    ok, x = pcall(function() return value:get() end)
    if ok and x and x ~= value then
        local vx, vy = ReadVector2D(x)
        if vx ~= nil and vy ~= nil then return vx, vy end
    end

    local text = SafeToString(value)
    local parsedX, parsedY = text:match("X=([%-%.%d]+).*Y=([%-%.%d]+)")
    if parsedX and parsedY then return tonumber(parsedX), tonumber(parsedY) end

    return nil, nil
end

local function IsLocalController(controller)
    if not IsValidObject(controller) then return false end

    local ok, result = pcall(function() return controller:IsLocalPlayerController() end)
    if ok then return result == true end

    ok, result = pcall(function() return controller.Player ~= nil end)
    return ok and result == true
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
    if ok and IsValidObject(pawn) then
        return true
    end

    ok, pawn = pcall(function() return controller:GetPawn() end)
    return ok and IsValidObject(pawn)
end

local IsCharacterCreationUiBlockingIntro = function()
    return false
end

local function ShouldShowPanel(controller, reason)
    if not IsLocalController(controller) then return false end

    local worldName = GetWorldName(controller)
    if worldName:match("MainMenu") then
        Debug("Pannello ignorato nel menu iniziale. Motivo: " .. tostring(reason))
        return false
    end

    local ok, blockedByCreation = pcall(IsCharacterCreationUiBlockingIntro)
    if ok and blockedByCreation == true then
        Debug("Pannello ignorato: creazione personaggio ancora aperta. Motivo: " .. tostring(reason))
        return false
    end

    if not HasPlayablePawn(controller) then
        Debug("Pannello ignorato: nessun personaggio/pawn valido. Motivo: " .. tostring(reason) .. " world=" .. worldName)
        return false
    end

    return true
end

local function FindLocalController()
    local ok, controllers = pcall(function() return FindAllOf("PlayerController") end)
    if not ok or not controllers then return nil end

    for _, controller in ipairs(controllers) do
        if IsLocalController(controller) then
            return controller
        end
    end

    return nil
end

local function GetPlayerId(controller)
    if not IsValidObject(controller) then return "" end

    local ok, playerState = pcall(function() return controller.PlayerState end)
    if ok and IsValidObject(playerState) then
        local candidates = {
            function() return playerState.ID end,
            function() return playerState.PlayerStateID end,
            function() return playerState.UniqueId end,
            function() return playerState:GetUniqueId() end,
            function() return playerState.CharacterPlayerID end,
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
    LoadChoices()
    for _, id in ipairs(GetControllerIds(controller)) do
        local choice = NormalizeChoice(savedChoices[id])
        if choice ~= "" then
            return choice, id
        end
    end

    return "", ""
end

local function SaveChoiceForController(controller, choice)
    for _, id in ipairs(GetControllerIds(controller)) do
        SaveChoice(id, choice)
    end
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

local function HasShownForCurrentPawn(controller)
    local pawnKey = GetPawnKey(controller)
    if pawnKey ~= "" then
        return state.shownPawnKeys[pawnKey] == true
    end

    return state.shownOnce
end

local function MarkShownForCurrentPawn(controller)
    local pawnKey = GetPawnKey(controller)
    state.currentPawnKey = pawnKey
    if pawnKey ~= "" then
        state.shownPawnKeys[pawnKey] = true
    end
end

local function NoticePawnChange(controller, reason)
    local pawnKey = GetPawnKey(controller)
    if pawnKey == "" then return end

    if state.currentPawnKey ~= "" and state.currentPawnKey ~= pawnKey then
        Debug("Nuovo personaggio/pawn rilevato, riabilito il pannello. Motivo: " .. tostring(reason))
        state.shownOnce = false
    end

    state.currentPawnKey = pawnKey
end

local function GetWidgetBlueprintLibrary()
    return StaticFindObject("/Script/UMG.Default__WidgetBlueprintLibrary")
end

local function GetWidgetLayoutLibrary()
    return StaticFindObject("/Script/UMG.Default__WidgetLayoutLibrary")
end

local function SetMouse(controller, enabled, widget)
    if not IsValidObject(controller) then return end

    local lib = GetWidgetBlueprintLibrary()

    if enabled then
        if IsValidObject(lib) then
            local ok, err = pcall(function()
                lib:SetInputMode_GameAndUIEx(controller, widget, 0, false, true)
            end)
            if ok then
                Debug("InputMode GameAndUI applicata.")
            else
                Debug("InputMode GameAndUI fallita: " .. SafeToString(err))
            end
            if not ok then
                local fallbackOk, fallbackErr = pcall(function() lib:SetInputMode_UIOnlyEx(controller, widget, 0, true) end)
                if fallbackOk then
                    Debug("InputMode UIOnly applicata come fallback.")
                else
                    Debug("InputMode UIOnly fallita: " .. SafeToString(fallbackErr))
                end
            end
        end

        pcall(function() controller:SetShowMouseCursor(true) end)
        pcall(function() controller.bShowMouseCursor = true end)
        pcall(function() controller.bEnableClickEvents = true end)
        pcall(function() controller.bEnableMouseOverEvents = true end)
        pcall(function() controller:SetIgnoreLookInput(true) end)
        pcall(function() controller:SetIgnoreMoveInput(true) end)
        if IsValidObject(widget) then
            pcall(function() widget:SetFocus() end)
            pcall(function() widget:SetKeyboardFocus() end)
            pcall(function() widget:SetUserFocus(controller) end)
        end
    else
        if IsValidObject(lib) then
            pcall(function() lib:SetInputMode_GameOnly(controller, true) end)
            pcall(function() lib:SetFocusToGameViewport() end)
        end

        pcall(function() controller:SetIgnoreLookInput(false) end)
        pcall(function() controller:SetIgnoreMoveInput(false) end)
        pcall(function() controller:SetShowMouseCursor(false) end)
        pcall(function() controller.bShowMouseCursor = false end)
        pcall(function() controller.bEnableClickEvents = false end)
        pcall(function() controller.bEnableMouseOverEvents = false end)
    end

    pcall(function() controller.bShowMouseCursor = enabled end)
    pcall(function() controller.bEnableClickEvents = enabled end)
    pcall(function() controller.bEnableMouseOverEvents = enabled end)
end

local function GetMousePosition(controller)
    if not IsValidObject(controller) then return nil, nil end

    local fallbackX = nil
    local fallbackY = nil

    local ok, x, y = pcall(function() return controller:GetMousePosition() end)
    if ok and type(x) == "number" and type(y) == "number" then
        if x ~= 0 or y ~= 0 then return x, y end
        fallbackX = x
        fallbackY = y
    end

    local outX = {}
    local outY = {}
    ok = pcall(function() return controller:GetMousePosition(outX, outY) end)
    if ok then
        x = ReadOutNumber(outX)
        y = ReadOutNumber(outY)
        if x ~= 0 or y ~= 0 then return x, y end
        fallbackX = fallbackX or x
        fallbackY = fallbackY or y
    end

    local layoutLib = GetWidgetLayoutLibrary()
    if IsValidObject(layoutLib) then
        ok, x = pcall(function() return layoutLib:GetMousePositionOnViewport(controller) end)
        if ok then
            x, y = ReadVector2D(x)
            if x ~= nil and y ~= nil then
                if x ~= 0 or y ~= 0 then return x, y end
                fallbackX = fallbackX or x
                fallbackY = fallbackY or y
            end
        end

        outX = {}
        outY = {}
        ok = pcall(function() return layoutLib:GetMousePositionScaledByDPI(controller, outX, outY) end)
        if ok then
            x = ReadOutNumber(outX)
            y = ReadOutNumber(outY)
            if x ~= 0 or y ~= 0 then return x, y end
            fallbackX = fallbackX or x
            fallbackY = fallbackY or y
        end
    end

    return fallbackX, fallbackY
end

local function GetViewportSize(controller)
    if not IsValidObject(controller) then return 1920, 1080 end

    local ok, x, y = pcall(function() return controller:GetViewportSize() end)
    if ok and type(x) == "number" and type(y) == "number" then
        return x, y
    end

    local outX = {}
    local outY = {}
    ok = pcall(function() return controller:GetViewportSize(outX, outY) end)
    if ok then
        local sx = ReadOutNumber(outX)
        local sy = ReadOutNumber(outY)
        if sx > 0 and sy > 0 then return sx, sy end
    end

    local layoutLib = GetWidgetLayoutLibrary()
    if IsValidObject(layoutLib) then
        ok, x = pcall(function() return layoutLib:GetViewportSize(controller) end)
        if ok then
            x, y = ReadVector2D(x)
            if x and y and x > 0 and y > 0 then return x, y end
        end
    end

    return 1920, 1080
end

local function RunOnGameThread(callback)
    if type(ExecuteInGameThread) == "function" then
        ExecuteInGameThread(callback)
    else
        callback()
    end
end

local function LoadWidgetClass()
    local function AsWidgetClass(object)
        if not IsValidObject(object) then return nil end

        local ok, generated = pcall(function() return object.GeneratedClass end)
        if ok and IsValidObject(generated) then return generated end

        local fullName = ""
        pcall(function() fullName = object:GetFullName() end)
        if tostring(fullName):match("Class") or tostring(fullName):match("_C") then
            return object
        end

        return nil
    end

    local paths = {
        CONFIG.WidgetClassPath,
        CONFIG.WidgetAssetPath,
        "WidgetBlueprintGeneratedClass " .. CONFIG.WidgetClassPath,
        "WidgetBlueprint " .. CONFIG.WidgetAssetPath,
    }

    for _, path in ipairs(paths) do
        local loaded = nil

        if type(LoadAsset) == "function" then
            pcall(function() loaded = LoadAsset(path) end)
            loaded = AsWidgetClass(loaded)
            if IsValidObject(loaded) then return loaded end
        end

        pcall(function() loaded = StaticFindObject(path) end)
        loaded = AsWidgetClass(loaded)
        if IsValidObject(loaded) then return loaded end
    end

    local assetRegistryHelpers = StaticFindObject("/Script/AssetRegistry.Default__AssetRegistryHelpers")
    if IsValidObject(assetRegistryHelpers) then
        local ok, result = pcall(function()
            return assetRegistryHelpers:GetAsset({
                PackageName = UEHelpers.FindOrAddFName(CONFIG.WidgetPackageName),
                AssetName = UEHelpers.FindOrAddFName(CONFIG.WidgetAssetName),
            })
        end)
        result = AsWidgetClass(result)
        if ok and IsValidObject(result) then return result end
    end

    return nil
end

local function CreateWidgetInstance(controller)
    local widgetClass = LoadWidgetClass()
    if not IsValidObject(widgetClass) then
        Log("Widget class non trovata: " .. CONFIG.WidgetClassPath .. ". Controlla che CamminoChoice.pak sia montato.")
        return nil
    end

    local lib = StaticFindObject("/Script/UMG.Default__WidgetBlueprintLibrary")
    local widget = nil

    if IsValidObject(lib) then
        local attempts = {
            function() return lib:Create(controller, widgetClass, controller) end,
            function() return lib:Create(controller:GetWorld(), widgetClass, controller) end,
            function() return lib:Create(controller, widgetClass) end,
        }

        for _, attempt in ipairs(attempts) do
            local ok, result = pcall(attempt)
            if ok and IsValidObject(result) then
                widget = result
                break
            end
        end
    end

    if not IsValidObject(widget) then
        local ok, result = pcall(function() return StaticConstructObject(widgetClass, controller) end)
        if ok and IsValidObject(result) then
            widget = result
        end
    end

    if not IsValidObject(widget) then
        Log("Creazione widget fallita.")
        return nil
    end

    local added = false
    local addAttempts = {
        function() widget:AddToViewport(10000) end,
        function() widget:AddToViewport() end,
        function() widget:AddToPlayerScreen(10000) end,
        function() widget:AddToPlayerScreen() end,
    }

    for _, attempt in ipairs(addAttempts) do
        local ok = pcall(attempt)
        if ok then
            added = true
            break
        end
    end

    if not added then
        Log("Widget creato, ma AddToViewport/AddToPlayerScreen e' fallito.")
        return nil
    end

    return widget
end

local function MakeText(text)
    local ok, result = pcall(function()
        local textLib = UEHelpers.GetKismetTextLibrary()
        if IsValidObject(textLib) then
            return textLib:Conv_StringToText(tostring(text or ""))
        end
        return nil
    end)
    if ok and result ~= nil then return result end
    return tostring(text or "")
end

local function FindObjectByPaths(paths)
    for _, path in ipairs(paths) do
        local object = nil

        pcall(function() object = StaticFindObject(path) end)
        if IsValidObject(object) then return object end

        if type(LoadAsset) == "function" then
            pcall(function() object = LoadAsset(path) end)
            if IsValidObject(object) then return object end
        end
    end

    return nil
end

local function FindClassObject(scriptPath)
    return FindObjectByPaths({
        "Class " .. scriptPath,
        scriptPath,
    })
end

local function ConstructNamedObject(class, outer, name)
    if not IsValidObject(class) then return nil end

    local object = nil
    if name and name ~= "" then
        pcall(function() object = StaticConstructObject(class, outer, UEHelpers.FindOrAddFName(name)) end)
        if IsValidObject(object) then return object end
    end

    pcall(function() object = StaticConstructObject(class, outer) end)
    if IsValidObject(object) then return object end

    return nil
end

local function ConstructTreeWidget(tree, class, name)
    if not IsValidObject(tree) or not IsValidObject(class) then return nil end

    local widget = nil
    if name and name ~= "" then
        pcall(function() widget = tree:ConstructWidget(class, UEHelpers.FindOrAddFName(name)) end)
        if IsValidObject(widget) then return widget end
    end

    pcall(function() widget = tree:ConstructWidget(class) end)
    if IsValidObject(widget) then return widget end

    return ConstructNamedObject(class, tree, name)
end

local function AddCanvasChild(canvas, child)
    if not IsValidObject(canvas) or not IsValidObject(child) then return nil end

    local ok, slot = pcall(function() return canvas:AddChildToCanvas(child) end)
    if ok and IsValidObject(slot) then return slot end

    pcall(function() canvas:AddChild(child) end)
    return nil
end

local function SetCanvasSlot(slot, minX, minY, maxX, maxY, left, top, right, bottom, alignX, alignY)
    if not IsValidObject(slot) then return end

    pcall(function()
        slot:SetAnchors({
            Minimum = { X = minX, Y = minY },
            Maximum = { X = maxX, Y = maxY },
        })
    end)
    pcall(function()
        slot:SetOffsets({
            Left = left,
            Top = top,
            Right = right,
            Bottom = bottom,
        })
    end)
    pcall(function() slot:SetAlignment({ X = alignX or 0.0, Y = alignY or 0.0 }) end)

    pcall(function()
        slot.LayoutData.Anchors.Minimum.X = minX
        slot.LayoutData.Anchors.Minimum.Y = minY
        slot.LayoutData.Anchors.Maximum.X = maxX
        slot.LayoutData.Anchors.Maximum.Y = maxY
        slot.LayoutData.Offsets.Left = left
        slot.LayoutData.Offsets.Top = top
        slot.LayoutData.Offsets.Right = right
        slot.LayoutData.Offsets.Bottom = bottom
        slot.LayoutData.Alignment.X = alignX or 0.0
        slot.LayoutData.Alignment.Y = alignY or 0.0
    end)
end

local function HideChoiceBackdrop()
    if IsValidObject(state.choiceBackdropWidget) then
        pcall(function() state.choiceBackdropWidget:RemoveFromParent() end)
        pcall(function() state.choiceBackdropWidget:RemoveFromViewport() end)
    end
    state.choiceBackdropWidget = nil
end

local function ShowChoiceBackdrop(controller)
    if not IsValidObject(controller) then return nil end

    HideChoiceBackdrop()

    state.choiceBackdropSerial = SafeNumber(state.choiceBackdropSerial, 0) + 1
    local uniqueSuffix = tostring(os.time()) .. "_" .. tostring(state.choiceBackdropSerial)

    local userWidgetClass = FindClassObject("/Script/UMG.UserWidget")
    local treeClass = FindClassObject("/Script/UMG.WidgetTree")
    local canvasClass = FindClassObject("/Script/UMG.CanvasPanel")
    local imageClass = FindClassObject("/Script/UMG.Image")
    if not IsValidObject(userWidgetClass) or not IsValidObject(treeClass)
        or not IsValidObject(canvasClass) or not IsValidObject(imageClass) then
        Log("Fondale nero scelta: classi UMG base non trovate.")
        return nil
    end

    local widget = nil
    local lib = GetWidgetBlueprintLibrary()
    if IsValidObject(lib) then
        local attempts = {
            function() return lib:Create(controller, userWidgetClass, controller) end,
            function() return lib:Create(controller:GetWorld(), userWidgetClass, controller) end,
        }
        for _, attempt in ipairs(attempts) do
            local ok, result = pcall(attempt)
            if ok and IsValidObject(result) then
                widget = result
                break
            end
        end
    end

    if not IsValidObject(widget) then
        widget = ConstructNamedObject(userWidgetClass, controller, "CamminoChoiceBlackBackdrop_" .. uniqueSuffix)
    end
    if not IsValidObject(widget) then
        Log("Fondale nero scelta: creazione UserWidget fallita.")
        return nil
    end

    local tree = nil
    pcall(function() tree = widget.WidgetTree end)
    if not IsValidObject(tree) then
        tree = ConstructNamedObject(treeClass, widget, "CamminoChoiceBlackBackdropTree_" .. uniqueSuffix)
        pcall(function() widget.WidgetTree = tree end)
    end
    if not IsValidObject(tree) then
        Log("Fondale nero scelta: creazione WidgetTree fallita.")
        return nil
    end

    local canvas = ConstructTreeWidget(tree, canvasClass, "CamminoChoiceBlackBackdropRoot")
    if not IsValidObject(canvas) then
        Log("Fondale nero scelta: creazione CanvasPanel fallita.")
        return nil
    end
    pcall(function() tree.RootWidget = canvas end)

    local background = ConstructTreeWidget(tree, imageClass, "CamminoChoiceBlackBackdropImage")
    if not IsValidObject(background) then
        Log("Fondale nero scelta: creazione Image fallita.")
        return nil
    end

    pcall(function() background:SetColorAndOpacity({ R = 0.0, G = 0.0, B = 0.0, A = 1.0 }) end)
    local backgroundSlot = AddCanvasChild(canvas, background)
    SetCanvasSlot(backgroundSlot, 0.0, 0.0, 1.0, 1.0, 0, 0, 0, 0, 0.0, 0.0)

    pcall(function() widget:Initialize() end)

    local added = false
    local addAttempts = {
        function() widget:AddToViewport(9990) end,
        function() widget:AddToPlayerScreen(9990) end,
        function() widget:AddToViewport() end,
        function() widget:AddToPlayerScreen() end,
    }
    for _, attempt in ipairs(addAttempts) do
        local ok = pcall(attempt)
        if ok then
            added = true
            break
        end
    end

    if not added then
        Log("Fondale nero scelta: widget creato ma non aggiunto allo schermo.")
        return nil
    end

    state.choiceBackdropWidget = widget
    return widget
end

local function LoadIntroTexture(controller, imagePath, label)
    label = tostring(label or "display")
    local paths = {}
    if type(imagePath) == "table" then
        paths = imagePath
    else
        paths = { tostring(imagePath or "") }
    end

    local renderingLib = FindObjectByPaths({
        "/Script/Engine.Default__KismetRenderingLibrary",
        "KismetRenderingLibrary /Script/Engine.Default__KismetRenderingLibrary",
    })
    if not IsValidObject(renderingLib) then
        Log("Intro " .. label .. ": KismetRenderingLibrary non trovata.")
        return nil
    end

    local tried = {}
    for _, path in ipairs(paths) do
        path = tostring(path or "")
        if path ~= "" then
            table.insert(tried, path)

            local texture = nil
            pcall(function() texture = renderingLib:ImportFileAsTexture2D(controller, path) end)
            if IsValidObject(texture) then return texture end

            pcall(function() texture = renderingLib:ImportFileAsTexture2D(controller:GetWorld(), path) end)
            if IsValidObject(texture) then return texture end

            pcall(function() texture = renderingLib:ImportFileAsTexture2D(UEHelpers.GetWorldContextObject(), path) end)
            if IsValidObject(texture) then return texture end
        end
    end

    Log("Intro " .. label .. ": immagine non caricata da " .. table.concat(tried, " | "))
    return nil
end

local function LoadRoleplayIntroTexture(controller)
    return LoadIntroTexture(controller, CONFIG.RoleplayIntroImagePath, "roleplayer")
end

local function AddIntroFallbackText(tree, canvas, imageW, imageH, fallbackText)
    local textClass = FindClassObject("/Script/UMG.TextBlock")
    local textBlock = ConstructTreeWidget(tree, textClass, "RoleplayIntroFallbackText")
    if not IsValidObject(textBlock) then return end

    pcall(function()
        textBlock:SetText(MakeText(fallbackText or "Display iniziale."))
    end)
    pcall(function() textBlock:SetAutoWrapText(true) end)
    pcall(function() textBlock:SetJustification(1) end)
    pcall(function() textBlock.Font.Size = 34 end)

    local slot = AddCanvasChild(canvas, textBlock)
    SetCanvasSlot(slot, 0.5, 0.5, 0.5, 0.5, 0, -60, imageW, imageH * 0.55, 0.5, 0.5)
end

local function AddRoleplayIntroButton(tree, canvas, buttonCenterY, buttonW, buttonH, buttonText)
    local buttonClass = FindClassObject("/Script/UMG.Button")
    local textClass = FindClassObject("/Script/UMG.TextBlock")
    local button = ConstructTreeWidget(tree, buttonClass, "RoleplayIntroDecisionButton")
    if not IsValidObject(button) then return false end

    local textBlock = ConstructTreeWidget(tree, textClass, "RoleplayIntroDecisionText")
    if IsValidObject(textBlock) then
        pcall(function() textBlock:SetText(MakeText(buttonText or "Ho deciso")) end)
        pcall(function() textBlock:SetJustification(1) end)
        pcall(function() textBlock.Font.Size = 28 end)
        pcall(function() button:AddChild(textBlock) end)
        pcall(function() button:SetContent(textBlock) end)
    end

    local slot = AddCanvasChild(canvas, button)
    SetCanvasSlot(slot, 0.5, 0.5, 0.5, 0.5, 0, buttonCenterY, buttonW, buttonH, 0.5, 0.5)
    return true
end

local function CreateRoleplayIntroWidget(controller, options)
    if not IsValidObject(controller) then return nil end
    options = options or {}

    local sx, sy = GetViewportSize(controller)
    state.roleplayIntroSerial = state.roleplayIntroSerial + 1
    local uniqueSuffix = tostring(os.time()) .. "_" .. tostring(state.roleplayIntroSerial) .. "_" .. tostring(math.floor(sx)) .. "x" .. tostring(math.floor(sy))
    local label = tostring(options.label or "roleplayer")
    local imagePath = options.imagePath or CONFIG.RoleplayIntroImagePath
    local imagePathText = type(imagePath) == "table" and table.concat(imagePath, " | ") or tostring(imagePath or "")
    local buttonText = tostring(options.buttonText or "Ho deciso")
    local fallbackText = tostring(options.fallbackText or "Dopo giorni di cammino nel bosco, intravedi un avamposto tra i pini.\n\nLO RAGGIUNGI, O RIPRENDI LA TUA STRADA?")
    local imageRatio = 849 / 566
    local imageW = math.min(sx * 0.82, 1180)
    local imageH = imageW / imageRatio
    if imageH > sy * 0.70 then
        imageH = sy * 0.70
        imageW = imageH * imageRatio
    end

    local imageCenterY = -48
    local buttonW = math.min(320, sx * 0.34)
    local buttonH = 58
    local buttonCenterY = imageCenterY + (imageH / 2) + 54

    state.roleplayIntroButton = {
        x1 = (sx / 2) - (buttonW / 2),
        x2 = (sx / 2) + (buttonW / 2),
        y1 = (sy / 2) + buttonCenterY - (buttonH / 2),
        y2 = (sy / 2) + buttonCenterY + (buttonH / 2),
    }

    local userWidgetClass = FindClassObject("/Script/UMG.UserWidget")
    local treeClass = FindClassObject("/Script/UMG.WidgetTree")
    local canvasClass = FindClassObject("/Script/UMG.CanvasPanel")
    if not IsValidObject(userWidgetClass) or not IsValidObject(treeClass) or not IsValidObject(canvasClass) then
        Log("Intro " .. label .. ": classi UMG base non trovate.")
        return nil
    end

    local widget = nil
    local lib = GetWidgetBlueprintLibrary()
    if IsValidObject(lib) then
        local attempts = {
            function() return lib:Create(controller, userWidgetClass, controller) end,
            function() return lib:Create(controller:GetWorld(), userWidgetClass, controller) end,
        }
        for _, attempt in ipairs(attempts) do
            local ok, result = pcall(attempt)
            if ok and IsValidObject(result) then
                widget = result
                break
            end
        end
    end

    if not IsValidObject(widget) then
        widget = ConstructNamedObject(userWidgetClass, controller, "RoleplayIntroWidget_" .. uniqueSuffix)
    end
    if not IsValidObject(widget) then
        Log("Intro " .. label .. ": creazione UserWidget fallita.")
        return nil
    end

    local tree = nil
    pcall(function() tree = widget.WidgetTree end)
    if not IsValidObject(tree) then
        tree = ConstructNamedObject(treeClass, widget, "RoleplayIntroWidgetTree_" .. uniqueSuffix)
        pcall(function() widget.WidgetTree = tree end)
    end
    if not IsValidObject(tree) then
        Log("Intro " .. label .. ": creazione WidgetTree fallita.")
        return nil
    end

    local canvas = ConstructTreeWidget(tree, canvasClass, "RoleplayIntroRoot")
    if not IsValidObject(canvas) then
        Log("Intro " .. label .. ": creazione CanvasPanel fallita.")
        return nil
    end
    pcall(function() tree.RootWidget = canvas end)

    local imageClass = FindClassObject("/Script/UMG.Image")
    local background = ConstructTreeWidget(tree, imageClass, "RoleplayIntroBackdrop")
    if IsValidObject(background) then
        pcall(function() background:SetColorAndOpacity({ R = 0.0, G = 0.0, B = 0.0, A = 0.82 }) end)
        local backgroundSlot = AddCanvasChild(canvas, background)
        SetCanvasSlot(backgroundSlot, 0.0, 0.0, 1.0, 1.0, 0, 0, 0, 0, 0.0, 0.0)
    end

    local texture = LoadIntroTexture(controller, imagePath, label)
    local image = ConstructTreeWidget(tree, imageClass, "RoleplayIntroImage")
    if IsValidObject(image) and IsValidObject(texture) then
        pcall(function() image:SetBrushFromTexture(texture, true) end)
        local imageSlot = AddCanvasChild(canvas, image)
        SetCanvasSlot(imageSlot, 0.5, 0.5, 0.5, 0.5, 0, imageCenterY, imageW, imageH, 0.5, 0.5)
    else
        Log("Intro " .. label .. ": display non mostrato perche' manca l'immagine. Percorso: " .. imagePathText)
        return nil
    end

    AddRoleplayIntroButton(tree, canvas, buttonCenterY, buttonW, buttonH, buttonText)
    pcall(function() widget:Initialize() end)

    local added = false
    local addAttempts = {
        function() widget:AddToViewport(1200) end,
        function() widget:AddToViewport() end,
        function() widget:AddToPlayerScreen(1200) end,
        function() widget:AddToPlayerScreen() end,
    }
    for _, attempt in ipairs(addAttempts) do
        local ok = pcall(attempt)
        if ok then
            added = true
            break
        end
    end

    if not added then
        Log("Intro " .. label .. ": widget creato ma non aggiunto allo schermo.")
        return nil
    end

    pcall(function() widget:SetPositionInViewport({ X = 0, Y = 0 }, false) end)
    pcall(function() widget:SetDesiredSizeInViewport({ X = sx, Y = sy }) end)
    pcall(function() widget:SetAlignmentInViewport({ X = 0, Y = 0 }) end)

    return widget
end

IsCharacterCreationUiBlockingIntro = function()
    return false
end

local function HideRoleplayIntro()
    local controller = state.roleplayIntroController

    if IsValidObject(state.roleplayIntroWidget) then
        pcall(function() state.roleplayIntroWidget:RemoveFromParent() end)
        pcall(function() state.roleplayIntroWidget:RemoveFromViewport() end)
    end

    state.roleplayIntroVisible = false
    state.roleplayIntroWidget = nil
    state.roleplayIntroController = nil
    state.roleplayIntroButton = nil
    SetMouse(controller, false, nil)
end

local function ShowRoleplayIntro(controller)
    if state.roleplayIntroVisible then return end
    if not ShouldShowPanel(controller, "roleplayer intro") then return end
    if IsCharacterCreationUiBlockingIntro() then
        Log("Intro roleplayer rimandata: creazione personaggio ancora aperta.")
        if type(ExecuteWithDelay) == "function" then
            ExecuteWithDelay(DelayMs(2), function()
                RunOnGameThread(function()
                    ShowRoleplayIntro(controller)
                end)
            end)
        end
        return
    end

    local widget = CreateRoleplayIntroWidget(controller, {
        label = "roleplayer",
        imagePath = CONFIG.RoleplayIntroImagePath,
        buttonText = "Ho deciso",
        fallbackText = "Dopo giorni di cammino nel bosco, intravedi un avamposto tra i pini.\n\nLO RAGGIUNGI, O RIPRENDI LA TUA STRADA?",
    })
    if not IsValidObject(widget) then
        Log("Intro roleplayer non mostrata: widget non valido.")
        return
    end

    state.roleplayIntroVisible = true
    state.roleplayIntroWidget = widget
    state.roleplayIntroController = controller
    SetMouse(controller, true, widget)
    Log("Intro roleplayer mostrata.")
end

local function ShowPlayerIntro(controller)
    if state.roleplayIntroVisible then return end
    if not ShouldShowPanel(controller, "player intro") then return end
    if IsCharacterCreationUiBlockingIntro() then
        Log("Intro player rimandata: creazione personaggio ancora aperta.")
        if type(ExecuteWithDelay) == "function" then
            ExecuteWithDelay(DelayMs(2), function()
                RunOnGameThread(function()
                    ShowPlayerIntro(controller)
                end)
            end)
        end
        return
    end

    local widget = CreateRoleplayIntroWidget(controller, {
        label = "player",
        imagePath = CONFIG.PlayerIntroImagePath,
        buttonText = "Chiudi",
        fallbackText = "Ti svegli di scatto, il respiro affannato e il cuore che batte forte.\n\nSEI IN VITA. PER ORA.",
    })
    if not IsValidObject(widget) then
        Log("Intro player non mostrata: widget non valido.")
        return
    end

    state.roleplayIntroVisible = true
    state.roleplayIntroWidget = widget
    state.roleplayIntroController = controller
    SetMouse(controller, true, widget)
    Log("Intro player mostrata.")
end

local function ShowRoleplayRespawnIntro(controller)
    if state.roleplayIntroVisible then return end
    if not ShouldShowPanel(controller, "roleplayer respawn intro") then return end
    if IsCharacterCreationUiBlockingIntro() then
        Log("Intro roleplayer respawn rimandata: creazione personaggio ancora aperta.")
        if type(ExecuteWithDelay) == "function" then
            ExecuteWithDelay(DelayMs(2), function()
                RunOnGameThread(function()
                    ShowRoleplayRespawnIntro(controller)
                end)
            end)
        end
        return
    end

    local widget = CreateRoleplayIntroWidget(controller, {
        label = "roleplayer respawn",
        imagePath = CONFIG.RoleplayRespawnIntroImagePath,
        buttonText = "Riprenditi",
        fallbackText = "Ti risvegli di scatto, il respiro affannato e il cuore che batte forte.\n\nNON RICORDI MOLTO. FORSE E' MEGLIO COSI.",
    })
    if not IsValidObject(widget) then
        Log("Intro roleplayer respawn non mostrata: widget non valido.")
        return
    end

    state.roleplayIntroVisible = true
    state.roleplayIntroWidget = widget
    state.roleplayIntroController = controller
    SetMouse(controller, true, widget)
    Log("Intro roleplayer respawn mostrata.")
end

local function QueueStoryIntro(controller, delaySeconds, showCallback)
    if type(ExecuteWithDelay) == "function" then
        ExecuteWithDelay(DelayMs(delaySeconds), function()
            RunOnGameThread(function()
                showCallback(controller)
            end)
        end)
    else
        RunOnGameThread(function()
            showCallback(controller)
        end)
    end
end

local function QueueRoleplayIntro(controller)
    QueueStoryIntro(controller, CONFIG.RoleplayIntroDelaySeconds, ShowRoleplayIntro)
end

local function QueuePlayerIntro(controller)
    QueueStoryIntro(controller, CONFIG.PlayerIntroDelaySeconds, ShowPlayerIntro)
end

local function QueueRoleplayRespawnIntro(controller)
    QueueStoryIntro(controller, CONFIG.RoleplayRespawnIntroDelaySeconds, ShowRoleplayRespawnIntro)
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
    if SafeNumber(CONFIG.SpawnSafetyHoldSeconds, 0) <= 0 then return "" end

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
            RunOnGameThread(function()
                applyHeldState(false)
                Debug("Sicura anti-caduta spawn rilasciata per " .. tostring(choice))
            end)
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
        ExecuteWithDelay(DelayMs(CONFIG.PlayerCrouchDelaySeconds), function()
            RunOnGameThread(runCrouch)
        end)
    end

    return " con crouch player"
end

local function TeleportLocalToChoice(controller, choice, useRespawnLocation, skipSafetyHold)
    local pawn = GetPawn(controller)
    if not IsValidObject(pawn) then
        return false, "pawn non valido"
    end

    local target = ChoiceLocation(choice, useRespawnLocation)
    if not target then
        return false, "scelta non valida"
    end

    local ok, loc = pcall(function() return pawn:K2_GetActorLocation() end)
    if not ok or not loc then
        ok, loc = pcall(function() return pawn.RootComponent:K2_GetComponentLocation() end)
    end
    if not ok or not loc then
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
        local safetyNote = ""
        if not skipSafetyHold then
            safetyNote = ApplySpawnSafetyHold(controller, pawn, choice)
        end
        local crouchNote = ApplyPlayerSpawnCrouch(controller, pawn, choice)
        return true, "teleport locale " .. NormalizeChoice(choice) .. " eseguito a " ..
            tostring(loc.X) .. ", " .. tostring(loc.Y) .. ", " .. tostring(loc.Z) .. safetyNote .. crouchNote
    end

    return false, "funzioni teleport fallite"
end

local function MarkSavedTeleportForCurrentPawn(controller, choice)
    local pawnKey = GetPawnKey(controller)
    local playerId = GetPlayerId(controller)
    local teleportKey = playerId .. "|" .. NormalizeChoice(choice) .. "|" .. pawnKey
    if teleportKey ~= "||" then
        state.teleportedPawnKeys[teleportKey] = true
    end
end

local function ScheduleChoiceRefresh(controller, choice, delaySeconds, useRespawnLocation, reason)
    if type(ExecuteWithDelay) ~= "function" then return end
    choice = NormalizeChoice(choice)
    if choice == "" then return end

    ExecuteWithDelay(DelayMs(delaySeconds), function()
        RunOnGameThread(function()
            if not IsValidObject(controller) then return end
            if not ShouldShowPanel(controller, reason or (choice .. " refresh")) then return end

            local ok, teleportReason = TeleportLocalToChoice(controller, choice, useRespawnLocation, true)
            if ok then
                Log("Refresh " .. choice .. ": " .. tostring(teleportReason))
            else
                Log("Refresh " .. choice .. " fallito: " .. tostring(teleportReason))
            end
        end)
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

local function SetPendingInitialChoice(controller, choice)
    choice = NormalizeChoice(choice)
    if choice == "" then return end

    state.pendingInitialChoice = choice
    state.pendingInitialChoiceAt = os.clock()
    SaveChoiceForController(controller, choice)
    Log("Scelta iniziale salvata prima dello spawn: " .. choice)
end

local function IsPendingInitialChoice(controller, choice)
    choice = NormalizeChoice(choice)
    if choice == "" or state.pendingInitialChoice ~= choice then return false end

    local startedAt = SafeNumber(state.pendingInitialChoiceAt, 0)
    if startedAt > 0 and (os.clock() - startedAt) > 300 then
        state.pendingInitialChoice = ""
        state.pendingInitialChoiceAt = 0
        return false
    end

    return true
end

local function ClearPendingInitialChoice(choice)
    choice = NormalizeChoice(choice)
    if choice == "" or state.pendingInitialChoice == choice then
        state.pendingInitialChoice = ""
        state.pendingInitialChoiceAt = 0
    end
end

local function SetPendingSavedChoiceRespawn(choice, reason)
    choice = NormalizeChoice(choice)
    if choice == "" then return end

    state.pendingSavedChoiceRespawn = choice
    state.pendingSavedChoiceRespawnAt = os.clock()
    Debug("Teleport da creazione personaggio segnato per scelta salvata: " .. choice .. " (" .. tostring(reason) .. ")")
end

local function IsPendingSavedChoiceRespawn(choice)
    choice = NormalizeChoice(choice)
    if choice == "" or state.pendingSavedChoiceRespawn ~= choice then return false end

    local startedAt = SafeNumber(state.pendingSavedChoiceRespawnAt, 0)
    local windowSeconds = SafeNumber(CONFIG.CharacterCreationTeleportWindowSeconds, 300)
    if startedAt > 0 and windowSeconds > 0 and (os.clock() - startedAt) > windowSeconds then
        state.pendingSavedChoiceRespawn = ""
        state.pendingSavedChoiceRespawnAt = 0
        return false
    end

    return true
end

local function ClearPendingSavedChoiceRespawn(choice)
    choice = NormalizeChoice(choice)
    if choice == "" or state.pendingSavedChoiceRespawn == choice then
        state.pendingSavedChoiceRespawn = ""
        state.pendingSavedChoiceRespawnAt = 0
    end
end

local function SendChoiceCommandOnly(controller, choice, reason)
    if not IsValidObject(controller) then return false end

    choice = NormalizeChoice(choice)
    if choice == "" then return false end

    local id = state.playerId ~= "" and state.playerId or GetPlayerId(controller)
    local command = choice == "roleplayer" and "/roleplay" or "/player"
    local directCommand = choice == "roleplayer" and ("cammino_roleplay " .. id) or ("cammino_player " .. id)

    local attempts = {
        { label = "Kismet ExecuteConsoleCommand direct", fn = function()
            UEHelpers.GetKismetSystemLibrary():ExecuteConsoleCommand(controller, directCommand, controller)
        end },
        { label = "Server_Exec direct", fn = function() controller:Server_Exec(directCommand) end },
        { label = "ConsoleCommand direct", fn = function() controller:ConsoleCommand(directCommand, true) end },
        { label = "Kismet ExecuteConsoleCommand chat", fn = function()
            UEHelpers.GetKismetSystemLibrary():ExecuteConsoleCommand(controller, command, controller)
        end },
        { label = "Server_Exec chat", fn = function() controller:Server_Exec(command) end },
        { label = "ConsoleCommand chat", fn = function() controller:ConsoleCommand(command, true) end },
    }

    for _, attempt in ipairs(attempts) do
        local ok, err = pcall(attempt.fn)
        if ok then
            Log("Comando scelta inviato al server: " .. choice .. " (" .. attempt.label .. ", " .. tostring(reason) .. ")")
            return true
        else
            Debug("Invio comando server fallito con " .. attempt.label .. ": " .. SafeToString(err))
        end
    end

    Log("ATTENZIONE: non sono riuscito a inviare al server la scelta salvata: " .. choice)
    return false
end

local function SendChoiceToServer(controller, choice, deferTeleportUntilSpawn)
    if not IsValidObject(controller) then return end

    choice = NormalizeChoice(choice)
    if choice == "" then return end

    local id = state.playerId ~= "" and state.playerId or GetPlayerId(controller)
    local command = choice == "roleplayer" and "/roleplay" or "/player"
    local directCommand = choice == "roleplayer" and ("cammino_roleplay " .. id) or ("cammino_player " .. id)
    local localHandled = false
    local commandText = nil

    pcall(function()
        local textLib = UEHelpers.GetKismetTextLibrary()
        if IsValidObject(textLib) then
            commandText = textLib:Conv_StringToText(command)
        end
    end)

    if deferTeleportUntilSpawn then
        SetPendingInitialChoice(controller, choice)
        localHandled = true
        Log("Teleport " .. choice .. " rimandato: il personaggio non e' ancora stato creato.")
    elseif choice == "roleplayer" then
        SaveChoiceForController(controller, "roleplayer")
        local ok, reason = TeleportLocalToChoice(controller, "roleplayer")
        ScheduleRoleplayInitialRefresh(controller)
        QueueRoleplayIntro(controller)
        if ok then
            localHandled = true
            MarkSavedTeleportForCurrentPawn(controller, "roleplayer")
            Log("Roleplayer: " .. tostring(reason))
        else
            Log("Roleplayer: teleport locale non riuscito: " .. tostring(reason))
        end
    elseif choice == "player" then
        SaveChoiceForController(controller, "player")
        local ok, reason = TeleportLocalToChoice(controller, "player")
        SchedulePlayerRefresh(controller)
        QueuePlayerIntro(controller)
        if ok then
            localHandled = true
            MarkSavedTeleportForCurrentPawn(controller, "player")
            Log("Player: " .. tostring(reason))
        else
            Log("Player: teleport locale non riuscito: " .. tostring(reason))
        end
    end

    local attempts = {
        { label = "Kismet ExecuteConsoleCommand direct", fn = function()
            UEHelpers.GetKismetSystemLibrary():ExecuteConsoleCommand(controller, directCommand, controller)
        end },
        { label = "Kismet ExecuteConsoleCommand chat", fn = function()
            UEHelpers.GetKismetSystemLibrary():ExecuteConsoleCommand(controller, command, controller)
        end },
        { label = "Server_Exec direct", fn = function() controller:Server_Exec(directCommand) end },
        { label = "Server_Exec chat", fn = function() controller:Server_Exec(command) end },
        { label = "Server_Say string", fn = function() controller:Server_Say(command) end },
        { label = "Server_Say text", fn = function()
            if not commandText then error("FText non disponibile") end
            controller:Server_Say(commandText)
        end },
        { label = "ConsoleCommand direct", fn = function() controller:ConsoleCommand(directCommand, true) end },
        { label = "ConsoleCommand chat", fn = function() controller:ConsoleCommand(command, true) end },
    }

    for _, attempt in ipairs(attempts) do
        local ok, err = pcall(attempt.fn)
        if ok then
            Log("Scelta inviata: " .. choice .. " (" .. attempt.label .. ")")
            return
        else
            Debug("Invio scelta fallito con " .. attempt.label .. ": " .. SafeToString(err))
        end
    end

    if localHandled then
        Log("Scelta gestita localmente; invio server non disponibile in questo contesto: " .. choice)
    else
        Log("Non sono riuscito a inviare la scelta: " .. choice)
    end
end

local function GetAllUserWidgets()
    local ok, widgets = pcall(function() return FindAllOf("UserWidget") end)
    if ok and widgets then return widgets end

    ok, widgets = pcall(function() return FindAllOf("Widget") end)
    if ok and widgets then return widgets end

    return {}
end

local function FindWidgetByNamePart(namePart, rejectPart)
    local wanted = tostring(namePart or ""):lower()
    local rejected = tostring(rejectPart or ""):lower()
    if wanted == "" then return nil end

    local fallback = nil
    for _, widget in ipairs(GetAllUserWidgets()) do
        if IsValidObject(widget) then
            local key = GetObjectKey(widget)
            local lower = key:lower()
            if lower:match(wanted) and not lower:match("default__") and (rejected == "" or not lower:match(rejected)) then
                local inViewport = false
                pcall(function() inViewport = widget:IsInViewport() == true end)
                if inViewport then return widget end
                fallback = fallback or widget
            end
        end
    end

    return fallback
end

local function FindWidgetsByNamePart(namePart)
    local wanted = tostring(namePart or ""):lower()
    local results = {}
    if wanted == "" then return results end

    for _, widget in ipairs(GetAllUserWidgets()) do
        if IsValidObject(widget) then
            local key = GetObjectKey(widget)
            local lower = key:lower()
            if lower:match(wanted) and not lower:match("default__") then
                table.insert(results, widget)
            end
        end
    end

    return results
end

local function IsWidgetVisible(widget)
    if not IsValidObject(widget) then return false end

    local ok, visible = pcall(function() return widget:IsVisible() end)
    if ok then return visible == true end

    local visibility = nil
    ok = pcall(function() visibility = widget:GetVisibility() end)
    if ok then
        local text = SafeToString(visibility):lower()
        if text:match("hidden") or text:match("collapsed") then return false end
        local numeric = tonumber(text)
        if numeric == 1 or numeric == 2 then return false end
        return true
    end

    return true
end

local function IsWidgetInViewport(widget)
    if not IsValidObject(widget) then return false end

    local ok, inViewport = pcall(function() return widget:IsInViewport() end)
    return ok and inViewport == true
end

local function GetOuterObject(object)
    if not IsValidObject(object) then return nil end

    local ok, outer = pcall(function() return object:GetOuter() end)
    if ok and IsValidObject(outer) then return outer end

    ok, outer = pcall(function() return object.Outer end)
    if ok and IsValidObject(outer) then return outer end

    return nil
end

local function LooksLikeCharacterCreationRoot(object)
    if not IsValidObject(object) then return false end

    local key = GetObjectKey(object):lower()
    if not key:match("wbp_charactercreation_c") then return false end
    if key:match("default__") or key:match("generatedclass") or key:match("class ") then return false end
    if key:match("location_c") or key:match("flex_c") or key:match("occupation_c") then return false end
    if key:match("stat_c") or key:match("uniqueness_c") or key:match("selection") then return false end

    return true
end

local function FindCharacterCreationRootFromOuterChain(child)
    local object = child
    for _ = 1, 12 do
        object = GetOuterObject(object)
        if not IsValidObject(object) then return nil end
        if LooksLikeCharacterCreationRoot(object) then
            return object
        end
    end

    return nil
end

local function FindCharacterCreationRoot()
    for _, locationWidget in ipairs(FindWidgetsByNamePart("wbp_charactercreation_location_c")) do
        if IsWidgetVisible(locationWidget) then
            local root = FindCharacterCreationRootFromOuterChain(locationWidget)
            if IsValidObject(root) then
                return root
            end
        end
    end

    local best = nil
    local bestScore = -1

    for _, widget in ipairs(GetAllUserWidgets()) do
        if LooksLikeCharacterCreationRoot(widget) then
            local score = 0
            if IsWidgetInViewport(widget) then score = score + 100 end
            if IsWidgetVisible(widget) then score = score + 25 end

            local switcher = nil
            pcall(function() switcher = widget.Switcher end)
            if IsValidObject(switcher) then score = score + 50 end

            local completeButton = nil
            pcall(function() completeButton = widget.CompleteButton end)
            if IsValidObject(completeButton) then score = score + 50 end

            if score > bestScore then
                best = widget
                bestScore = score
            end
        end
    end

    if IsValidObject(best) then
        return best
    end

    return nil
end

local function FindCharacterCreationLocations()
    return FindWidgetsByNamePart("wbp_charactercreation_location_c")
end

local function HasVisibleCharacterCreationLocation()
    for _, locationWidget in ipairs(FindCharacterCreationLocations()) do
        if IsWidgetVisible(locationWidget) then
            return true
        end
    end

    return false
end

IsCharacterCreationUiBlockingIntro = function()
    local root = FindCharacterCreationRoot()
    if IsValidObject(root) and IsWidgetVisible(root) then
        return true
    end

    return HasVisibleCharacterCreationLocation()
end

local function IsCharacterCreationLocationPageActive(root)
    if not IsValidObject(root) then return false end

    local switcher = nil
    pcall(function() switcher = root.Switcher end)
    if IsValidObject(switcher) then
        local activeWidget = nil
        pcall(function() activeWidget = switcher:GetActiveWidget() end)
        if IsValidObject(activeWidget) then
            local key = GetObjectKey(activeWidget):lower()
            if key:match("location") then return true end
        end

        local activeIndex = nil
        pcall(function() activeIndex = switcher:GetActiveWidgetIndex() end)
        activeIndex = tonumber(SafeToString(activeIndex))
        if activeIndex and activeIndex >= 5 then return true end
    end

    return HasVisibleCharacterCreationLocation()
end

local function GetAllTextBlocks()
    local ok, blocks = pcall(function() return FindAllOf("TextBlock") end)
    if ok and blocks then return blocks end

    ok, blocks = pcall(function() return FindAllOf("RichTextBlock") end)
    if ok and blocks then return blocks end

    return {}
end

local function GetTextBlockString(textBlock)
    if not IsValidObject(textBlock) then return "" end

    local ok, value = pcall(function() return textBlock:GetText() end)
    if ok then
        local text = SafeToString(value)
        if text ~= "" then return text end
    end

    ok, value = pcall(function() return textBlock.Text end)
    if ok then
        local text = SafeToString(value)
        if text ~= "" then return text end
    end

    return ""
end

local function SetTextBlockString(textBlock, text)
    if not IsValidObject(textBlock) then return false end

    local value = MakeText(text or "")
    local ok = pcall(function() textBlock:SetText(value) end)
    if ok then return true end

    ok = pcall(function() textBlock.Text = value end)
    return ok == true
end

local function NormalizeUiText(text)
    return tostring(text or "")
        :gsub("\r", " ")
        :gsub("\n", " ")
        :gsub("%s+", " ")
        :gsub("^%s+", "")
        :gsub("%s+$", "")
        :lower()
end

local function GuidelineReplacementForText(text)
    local lower = NormalizeUiText(text)
    local items = CONFIG.StartLocationGuidelines or {}

    if lower == "luogo di partenza" then
        return CONFIG.StartLocationGuidelinesTitle or "Linee Guida"
    end
    if lower:find("seleziona dove vuoi", 1, true) then
        return "Leggi queste linee guida prima di entrare nel server."
    end

    if lower:find("dannemora", 1, true) then return items[1] and items[1].Title end
    if lower:find("prende il nome da", 1, true) then return items[1] and items[1].Body end

    if lower:find("lyon mountain", 1, true) then return items[2] and items[2].Title end
    if lower:find("un piccolo borgo situato", 1, true) then return items[2] and items[2].Body end

    if lower:find("redford", 1, true) then return items[3] and items[3].Title end
    if lower:find("un piccolo borgo rurale", 1, true) then return items[3] and items[3].Body end

    if lower:find("saranac", 1, true) then return items[4] and items[4].Title end
    if lower:find("spesso scambiata", 1, true) then return items[4] and items[4].Body end

    return nil
end

local function ApplyStartLocationGuidelinesText()
    if not CONFIG.StartLocationGuidelinesEnabled then return 0 end

    local changed = 0
    for _, textBlock in ipairs(GetAllTextBlocks()) do
        if IsValidObject(textBlock) then
            local key = GetObjectKey(textBlock):lower()
            if not key:match("default__") and not key:match("generatedclass") and not key:match("class ") then
                local current = GetTextBlockString(textBlock)
                local replacement = GuidelineReplacementForText(current)
                if replacement and replacement ~= "" and current ~= replacement then
                    if SetTextBlockString(textBlock, replacement) then
                        changed = changed + 1
                    end
                end
            end
        end
    end

    return changed
end

local function SetGuidelinesHitTestInvisible(widget)
    if not IsValidObject(widget) then return end
    pcall(function() widget:SetVisibility(3) end)
    pcall(function() widget.Visibility = 3 end)
end

local function AddGuidelinesText(tree, canvas, name, text, x, y, w, h, fontSize, justification)
    local textClass = FindClassObject("/Script/UMG.TextBlock")
    local textBlock = ConstructTreeWidget(tree, textClass, name)
    if not IsValidObject(textBlock) then return nil end

    pcall(function() textBlock:SetText(MakeText(text or "")) end)
    pcall(function() textBlock:SetAutoWrapText(true) end)
    pcall(function() textBlock:SetWrapTextAt(w) end)
    pcall(function() textBlock:SetJustification(justification or 0) end)
    pcall(function() textBlock.Font.Size = fontSize end)
    SetGuidelinesHitTestInvisible(textBlock)

    local slot = AddCanvasChild(canvas, textBlock)
    SetCanvasSlot(slot, 0.0, 0.0, 0.0, 0.0, x, y, w, h, 0.0, 0.0)
    return textBlock
end

local function AddGuidelinesBox(tree, canvas, index, item, x, y, w, h)
    local imageClass = FindClassObject("/Script/UMG.Image")
    local background = ConstructTreeWidget(tree, imageClass, "CamminoGuidelinesBox_" .. tostring(index))
    if IsValidObject(background) then
        pcall(function() background:SetColorAndOpacity({ R = 0.0, G = 0.0, B = 0.0, A = 0.86 }) end)
        SetGuidelinesHitTestInvisible(background)
        local slot = AddCanvasChild(canvas, background)
        SetCanvasSlot(slot, 0.0, 0.0, 0.0, 0.0, x, y, w, h, 0.0, 0.0)
    end

    AddGuidelinesText(tree, canvas, "CamminoGuidelinesTitle_" .. tostring(index), tostring(item.Title or ""), x + 12, y + 8, w - 24, 23, 16, 0)
    AddGuidelinesText(tree, canvas, "CamminoGuidelinesBody_" .. tostring(index), tostring(item.Body or ""), x + 12, y + 34, w - 24, h - 38, 11, 0)
end

local function HideStartLocationGuidelines()
    if IsValidObject(state.startLocationGuidelinesWidget) then
        pcall(function() state.startLocationGuidelinesWidget:RemoveFromParent() end)
        pcall(function() state.startLocationGuidelinesWidget:RemoveFromViewport() end)
    end
    state.startLocationGuidelinesWidget = nil
end

local function CreateStartLocationGuidelinesWidget(controller)
    if not IsValidObject(controller) then return nil end

    local sx, sy = GetViewportSize(controller)
    state.startLocationGuidelinesSerial = SafeNumber(state.startLocationGuidelinesSerial, 0) + 1
    local uniqueSuffix = tostring(os.time()) .. "_" .. tostring(state.startLocationGuidelinesSerial)

    local userWidgetClass = FindClassObject("/Script/UMG.UserWidget")
    local treeClass = FindClassObject("/Script/UMG.WidgetTree")
    local canvasClass = FindClassObject("/Script/UMG.CanvasPanel")
    if not IsValidObject(userWidgetClass) or not IsValidObject(treeClass) or not IsValidObject(canvasClass) then
        Log("Linee Guida: classi UMG base non trovate.")
        return nil
    end

    local widget = nil
    local lib = GetWidgetBlueprintLibrary()
    if IsValidObject(lib) then
        local attempts = {
            function() return lib:Create(controller, userWidgetClass, controller) end,
            function() return lib:Create(controller:GetWorld(), userWidgetClass, controller) end,
        }
        for _, attempt in ipairs(attempts) do
            local ok, result = pcall(attempt)
            if ok and IsValidObject(result) then
                widget = result
                break
            end
        end
    end

    if not IsValidObject(widget) then
        widget = ConstructNamedObject(userWidgetClass, controller, "CamminoStartLocationGuidelines_" .. uniqueSuffix)
    end
    if not IsValidObject(widget) then
        Log("Linee Guida: creazione UserWidget fallita.")
        return nil
    end

    local tree = nil
    pcall(function() tree = widget.WidgetTree end)
    if not IsValidObject(tree) then
        tree = ConstructNamedObject(treeClass, widget, "CamminoStartLocationGuidelinesTree_" .. uniqueSuffix)
        pcall(function() widget.WidgetTree = tree end)
    end
    if not IsValidObject(tree) then
        Log("Linee Guida: creazione WidgetTree fallita.")
        return nil
    end

    local canvas = ConstructTreeWidget(tree, canvasClass, "CamminoStartLocationGuidelinesRoot")
    if not IsValidObject(canvas) then
        Log("Linee Guida: creazione CanvasPanel fallita.")
        return nil
    end
    pcall(function() tree.RootWidget = canvas end)
    SetGuidelinesHitTestInvisible(canvas)

    local panelW = math.min(600, sx * 0.92)
    if sx > 1000 then panelW = math.min(600, sx * 0.34) end
    local marginX = math.max(28, panelW * 0.083)
    local contentW = panelW - (marginX * 2)
    local topY = 48
    local rowY = 150
    local rowH = math.max(96, math.min(107, (sy - 280) / 4))
    local gap = 12
    local itemCount = #(CONFIG.StartLocationGuidelines or {})
    local panelH = math.min(sy - 135, rowY + (itemCount * (rowH + gap)) - gap + 20)

    local imageClass = FindClassObject("/Script/UMG.Image")
    local panelBg = ConstructTreeWidget(tree, imageClass, "CamminoStartLocationGuidelinesBackground")
    if IsValidObject(panelBg) then
        pcall(function() panelBg:SetColorAndOpacity({ R = 0.0, G = 0.0, B = 0.0, A = 0.88 }) end)
        SetGuidelinesHitTestInvisible(panelBg)
        local slot = AddCanvasChild(canvas, panelBg)
        SetCanvasSlot(slot, 0.0, 0.0, 0.0, 0.0, 0, 0, panelW, panelH, 0.0, 0.0)
    end

    AddGuidelinesText(tree, canvas, "CamminoGuidelinesHeader", CONFIG.StartLocationGuidelinesTitle or "Linee Guida", marginX, topY, contentW, 44, 32, 0)

    for i, item in ipairs(CONFIG.StartLocationGuidelines or {}) do
        AddGuidelinesBox(tree, canvas, i, item, marginX, rowY + ((i - 1) * (rowH + gap)), contentW, rowH)
    end

    pcall(function() widget:Initialize() end)
    SetGuidelinesHitTestInvisible(widget)

    local added = false
    for _, attempt in ipairs({
        function() widget:AddToViewport(9998) end,
        function() widget:AddToViewport() end,
        function() widget:AddToPlayerScreen(9998) end,
        function() widget:AddToPlayerScreen() end,
    }) do
        local ok = pcall(attempt)
        if ok then
            added = true
            break
        end
    end

    if not added then
        Log("Linee Guida: widget creato ma non aggiunto allo schermo.")
        return nil
    end

    return widget
end

local function ShowStartLocationGuidelines(controller)
    if not CONFIG.StartLocationGuidelinesEnabled then return end
    if not IsLocalController(controller) then return end

    local changed = ApplyStartLocationGuidelinesText()
    if changed > 0 then
        Debug("Linee Guida applicate ai TextBlock vanilla: " .. tostring(changed))
    end
end

local function TickStartLocationGuidelines(controller)
    if not CONFIG.StartLocationGuidelinesEnabled then return end
    if not IsLocalController(controller) then return end

    local root = FindCharacterCreationRoot()
    if IsValidObject(root) and IsCharacterCreationLocationPageActive(root) then
        HideStartLocationGuidelines()
        local now = os.clock()
        if now - SafeNumber(state.startLocationGuidelinesLastApplyAt, 0) < 0.25 then return end
        state.startLocationGuidelinesLastApplyAt = now

        local changed = ApplyStartLocationGuidelinesText()
        if changed > 0 then
            Debug("Linee Guida applicate ai TextBlock vanilla: " .. tostring(changed))
        end
    else
        HideStartLocationGuidelines()
    end
end

local function SelectVanillaSpawnRegion(root)
    if not IsValidObject(root) then return false, "root non valido" end

    for _, locationWidget in ipairs(FindCharacterCreationLocations()) do
        if IsValidObject(locationWidget) then
            local notes = {}

            pcall(function()
                locationWidget.bIsSelected = true
                table.insert(notes, "bIsSelected")
            end)

            pcall(function()
                locationWidget:OnClicked()
                table.insert(notes, "OnClicked")
            end)

            local data = nil
            pcall(function() data = locationWidget.SpawnRegionWidgetData end)
            if data ~= nil then
                local okSet = pcall(function()
                    root.SpawnRegion = data
                end)
                if okSet then
                    table.insert(notes, "SpawnRegion")
                    return true, table.concat(notes, "+")
                end
            end

            if #notes > 0 then
                return true, table.concat(notes, "+")
            end
        end
    end

    return false, "nessun WBP_CharacterCreation_Location_C attivo"
end

local function TryBroadcastButton(button, depth)
    depth = SafeNumber(depth, 0)
    if depth > 2 then return false end
    if not IsValidObject(button) then return false end

    local attempts = {
        function() button:OnClicked() end,
        function() button.OnClicked:Broadcast() end,
        function() button:OnButtonClicked() end,
        function() button.OnButtonClicked:Broadcast() end,
        function() button.OnPressed:Broadcast() end,
        function() button:Press() end,
        function() button:Click() end,
    }

    for _, attempt in ipairs(attempts) do
        local ok = pcall(attempt)
        if ok then return true end
    end

    for _, childName in ipairs({ "Button", "SelectButton", "SpawnButton", "Button_0", "InternalButton" }) do
        local child = nil
        pcall(function() child = button[childName] end)
        if IsValidObject(child) and child ~= button and TryBroadcastButton(child, depth + 1) then
            return true
        end
    end

    return false
end

local function FinalizeVanillaCharacterCreation(reason)
    if state.vanillaFinishInProgress then return false end
    state.vanillaFinishInProgress = true

    local root = FindCharacterCreationRoot()
    if not IsValidObject(root) then
        state.vanillaFinishInProgress = false
        Log("Skip luogo di partenza: WBP_CharacterCreation non trovato.")
        return false
    end
    Debug("Skip luogo di partenza: root=" .. GetObjectKey(root))

    local locationPageActive = IsCharacterCreationLocationPageActive(root)
    local selected, selectReason = SelectVanillaSpawnRegion(root)
    Debug("Skip luogo di partenza: selezione location vanilla = " .. tostring(selected) .. " (" .. tostring(selectReason) .. ")")

    if not selected and not locationPageActive then
        state.vanillaFinishInProgress = false
        Debug("Skip luogo di partenza: aspetto che la pagina Location sia pronta.")
        return false
    end

    local canFinish = nil
    pcall(function() canFinish = root:CanClickFinish() end)
    if canFinish ~= nil then
        Debug("Skip luogo di partenza: CanClickFinish=" .. tostring(canFinish))
    end

    if canFinish == false then
        state.vanillaFinishInProgress = false
        Debug("Skip luogo di partenza: Termina non ancora disponibile, ritento allo scan successivo.")
        return false
    end

    local attempts = {
        { label = "CompleteButton", fn = function()
            local button = root.CompleteButton
            Debug("Skip luogo di partenza: CompleteButton=" .. GetObjectKey(button))
            if not TryBroadcastButton(button) then error("CompleteButton non cliccabile") end
        end },
        { label = "Finish", fn = function() root:Finish() end },
    }

    for _, attempt in ipairs(attempts) do
        local ok, err = pcall(attempt.fn)
        if ok then
            Log("Skip luogo di partenza: chiamato " .. attempt.label .. ". Motivo: " .. tostring(reason))
            state.vanillaFinishFailureCount = 0
            if type(ExecuteWithDelay) == "function" then
                ExecuteWithDelay(DelayMs(1.2), function()
                    state.vanillaFinishInProgress = false
                end)
            else
                state.vanillaFinishInProgress = false
            end
            return true
        end
        Debug("Skip luogo di partenza: " .. attempt.label .. " fallito: " .. SafeToString(err))
    end

    state.vanillaFinishInProgress = false
    state.vanillaFinishFailureCount = SafeNumber(state.vanillaFinishFailureCount, 0) + 1
    Log("Skip luogo di partenza fallito: non riesco a chiamare Finish/CompleteButton.")
    return false
end

local function ShowCreationChoicePanel(controller, reason)
    if state.visible or state.roleplayIntroVisible then return end
    if not IsLocalController(controller) then return end

    state.controller = controller
    state.playerId = GetPlayerId(controller)
    ShowChoiceBackdrop(controller)
    state.widget = CreateWidgetInstance(controller)

    if not IsValidObject(state.widget) then
        HideChoiceBackdrop()
        Log("Pannello creazione non mostrato: widget non valido.")
        return
    end

    state.visible = true
    state.preSpawnChoice = true
    SetMouse(controller, true, state.widget)
    Log("Pannello Cammino mostrato sopra Luogo di partenza. Motivo: " .. tostring(reason))
end

local function TickVanillaStartLocationSkip(controller)
    if not CONFIG.SkipVanillaStartLocation then return end
    if state.visible or state.roleplayIntroVisible or state.vanillaFinishInProgress then return end
    if not IsLocalController(controller) then return end

    TickStartLocationGuidelines(controller)

    local now = os.clock()
    if now - SafeNumber(state.vanillaStartLocationLastScanAt, 0) < SafeNumber(CONFIG.VanillaStartLocationScanIntervalSeconds, 0.35) then
        return
    end
    state.vanillaStartLocationLastScanAt = now

    local root = FindCharacterCreationRoot()
    if not IsValidObject(root) then return end

    local fromUniquenessNext = state.awaitingStartLocationAfterUniqueness == true
        and (os.clock() - SafeNumber(state.awaitingStartLocationAt, 0)) < 12
    if not IsCharacterCreationLocationPageActive(root) and not fromUniquenessNext then return end

    local savedChoice = GetSavedChoiceForController(controller)
    if savedChoice ~= "" then
        if SafeNumber(state.vanillaFinishFailureCount, 0) >= 4 then
            return
        end
        if FinalizeVanillaCharacterCreation("scelta gia' salvata: " .. savedChoice) then
            SetPendingSavedChoiceRespawn(savedChoice, "Luogo di partenza completato con scelta salvata")
        end
        return
    end

    state.awaitingStartLocationAfterUniqueness = false
    state.awaitingStartLocationAt = 0
end

local function FinishSavedChoiceFromUniqueness(controller, reason)
    if not CONFIG.SkipVanillaStartLocation then return end
    if not IsLocalController(controller) then return end
    if state.visible or state.roleplayIntroVisible or state.vanillaFinishInProgress then return end

    local savedChoice = GetSavedChoiceForController(controller)
    if savedChoice == "" then return end
    if state.pendingInitialChoice ~= "" then return end

    local function finish()
        if not IsValidObject(controller) then return end
        local stillSaved = GetSavedChoiceForController(controller)
        if stillSaved == "" then return end
        if FinalizeVanillaCharacterCreation(reason or ("Avanti Unicita con scelta salvata: " .. stillSaved)) then
            SetPendingSavedChoiceRespawn(stillSaved, reason or "Avanti Unicita con scelta salvata")
        end
    end

    if type(ExecuteWithDelay) == "function" then
        ExecuteWithDelay(DelayMs(0.2), function()
            RunOnGameThread(finish)
        end)
    else
        finish()
    end
end

local function StartCharacterCreationUiScan(reason, durationSeconds)
    if not CONFIG.SkipVanillaStartLocation then return end

    local now = os.clock()
    if now - SafeNumber(state.characterCreationScanLastStart, 0) < 0.5 then return end
    state.characterCreationScanLastStart = now

    local duration = SafeNumber(durationSeconds, 18)
    if duration <= 0 then duration = 18 end

    state.vanillaFinishFailureCount = 0
    state.characterCreationScanSerial = state.characterCreationScanSerial + 1
    local serial = state.characterCreationScanSerial
    local stopAt = os.clock() + duration

    local function scanStep()
        if serial ~= state.characterCreationScanSerial then return end

        RunOnGameThread(function()
            local controller = FindLocalController()
            if IsValidObject(controller) then
                TickStartLocationGuidelines(controller)
                TickVanillaStartLocationSkip(controller)
            end
        end)

        if os.clock() < stopAt and type(ExecuteWithDelay) == "function" then
            ExecuteWithDelay(DelayMs(0.25), scanStep)
        end
    end

    Debug("Scan UI creazione personaggio avviato: " .. tostring(reason))
    scanStep()
end

local function StartLocationGuidelinesScan(reason, durationSeconds)
    if not CONFIG.StartLocationGuidelinesEnabled then return end

    local controller = FindLocalController()
    if IsValidObject(controller) then
        local worldName = GetWorldName(controller):lower()
        if not worldName:match("mainmenu") and not worldName:match("character") then return end
    end

    local now = os.clock()
    if now - SafeNumber(state.startLocationGuidelinesScanLastStart, 0) < 0.35 then return end
    state.startLocationGuidelinesScanLastStart = now

    local duration = SafeNumber(durationSeconds, 8)
    if duration <= 0 then duration = 8 end

    state.startLocationGuidelinesScanSerial = SafeNumber(state.startLocationGuidelinesScanSerial, 0) + 1
    local serial = state.startLocationGuidelinesScanSerial
    local stopAt = os.clock() + duration

    local function scanStep()
        if serial ~= state.startLocationGuidelinesScanSerial then return end

        RunOnGameThread(function()
            local controller = FindLocalController()
            if IsValidObject(controller) then
                TickStartLocationGuidelines(controller)
            else
                HideStartLocationGuidelines()
            end
        end)

        if os.clock() < stopAt and type(ExecuteWithDelay) == "function" then
            ExecuteWithDelay(DelayMs(0.25), scanStep)
        end
    end

    Debug("Scan Linee Guida avviato: " .. tostring(reason))
    scanStep()
end

local function StartCharacterCreationWatchdog()
    if not CONFIG.CharacterCreationWatchdogEnabled then return end
    if state.characterCreationWatchdogStarted then return end
    state.characterCreationWatchdogStarted = true

    local function step()
        if not CONFIG.CharacterCreationWatchdogEnabled then return end

        local ok, err = pcall(function()
            RunOnGameThread(function()
                local controller = FindLocalController()
                if IsValidObject(controller) then
                    TickVanillaStartLocationSkip(controller)
                end
            end)
        end)
        if not ok then
            Debug("Watchdog creazione personaggio: errore scan - " .. SafeToString(err))
        end

        if type(ExecuteWithDelay) == "function" then
            ExecuteWithDelay(DelayMs(CONFIG.CharacterCreationWatchdogIntervalSeconds), step)
        end
    end

    Debug("Watchdog creazione personaggio avviato.")
    if type(ExecuteWithDelay) == "function" then
        ExecuteWithDelay(DelayMs(1), step)
    else
        step()
    end
end

local function StartCharacterCreationScanAfterUiClick()
    if state.visible or state.roleplayIntroVisible then return end

    local controller = FindLocalController()
    if not IsValidObject(controller) then return end
    if GetSavedChoiceForController(controller) == "" then return end

    local worldName = GetWorldName(controller):lower()
    if not worldName:match("mainmenu") and not worldName:match("character") then return end

    state.awaitingStartLocationAfterUniqueness = true
    state.awaitingStartLocationAt = os.clock()

    if type(ExecuteWithDelay) == "function" then
        ExecuteWithDelay(DelayMs(0.35), function()
            StartCharacterCreationUiScan("click UI creazione personaggio", 6)
        end)
    else
        StartCharacterCreationUiScan("click UI creazione personaggio", 6)
    end
end

local function HidePanel(choice)
    local controller = state.controller
    local wasPreSpawnChoice = state.preSpawnChoice == true

    if IsValidObject(state.widget) then
        pcall(function() state.widget:RemoveFromParent() end)
        pcall(function() state.widget:RemoveFromViewport() end)
    end

    state.visible = false
    state.widget = nil
    state.preSpawnChoice = false
    HideChoiceBackdrop()
    SetMouse(controller, false, nil)

    if choice and IsValidObject(controller) then
        SendChoiceToServer(controller, choice, wasPreSpawnChoice)
        if wasPreSpawnChoice then
            FinalizeVanillaCharacterCreation("scelta Cammino: " .. tostring(choice))
        end
    end
end

local function TeleportSavedChoiceIfNeeded(controller, choice, reason)
    choice = NormalizeChoice(choice)
    if choice == "" then return end
    if not ShouldShowPanel(controller, reason or "saved choice teleport") then return end

    local pendingInitial = IsPendingInitialChoice(controller, choice)
    local pendingRespawn = IsPendingSavedChoiceRespawn(choice)
    if CONFIG.DisableSavedChoiceTeleportOnReconnect and not pendingInitial and not pendingRespawn then
        Debug("Scelta salvata " .. choice .. " non teletrasportata: probabile rientro normale nel server (" .. tostring(reason) .. ").")
        return
    end

    local pawnKey = GetPawnKey(controller)
    local playerId = GetPlayerId(controller)
    local teleportKey = playerId .. "|" .. choice .. "|" .. pawnKey
    if teleportKey ~= "||" and state.teleportedPawnKeys[teleportKey] then return end
    if teleportKey ~= "||" then
        state.teleportedPawnKeys[teleportKey] = true
    end

    local function runTeleport()
        if not IsValidObject(controller) then return end
        if not ShouldShowPanel(controller, "saved choice teleport delayed") then return end

        pendingInitial = IsPendingInitialChoice(controller, choice)
        pendingRespawn = IsPendingSavedChoiceRespawn(choice)
        if CONFIG.DisableSavedChoiceTeleportOnReconnect and not pendingInitial and not pendingRespawn then
            Debug("Teleport scelta salvata annullato dopo delay: non arriva da creazione personaggio.")
            return
        end

        if pendingInitial then
            SaveChoiceForController(controller, choice)
        end

        local useRespawnLocation = choice == "roleplayer" and not pendingInitial
        local ok, teleportReason = TeleportLocalToChoice(controller, choice, useRespawnLocation)
        if ok then
            if pendingRespawn then
                SendChoiceCommandOnly(controller, choice, "respawn con scelta salvata")
            end

            Log("Scelta salvata " .. choice .. ": " .. teleportReason)
            if choice == "player" then
                SchedulePlayerRefresh(controller)
                QueuePlayerIntro(controller)
            elseif choice == "roleplayer" then
                if pendingInitial then
                    ScheduleRoleplayInitialRefresh(controller)
                    QueueRoleplayIntro(controller)
                else
                    ScheduleRoleplayRespawnRefresh(controller)
                    QueueRoleplayRespawnIntro(controller)
                end
            end

            if pendingInitial then
                ClearPendingInitialChoice(choice)
            end
            if pendingRespawn then
                ClearPendingSavedChoiceRespawn(choice)
            end
        else
            Log("Teleport scelta salvata fallito: " .. tostring(teleportReason))
        end
    end

    if type(ExecuteWithDelay) == "function" then
        ExecuteWithDelay(DelayMs(CONFIG.TeleportDelaySeconds), function()
            RunOnGameThread(runTeleport)
        end)
    else
        runTeleport()
    end
end

local function ShowPanel(controller, reason)
    local okBlocked, blockedByCreation = pcall(IsCharacterCreationUiBlockingIntro)
    if okBlocked and blockedByCreation == true then
        TickStartLocationGuidelines(controller)
        state.characterCreationPanelWasBlocked = true
        Debug("Pannello Cammino rimandato: creazione personaggio ancora aperta. Motivo: " .. tostring(reason))
        if type(ExecuteWithDelay) == "function" then
            state.characterCreationPanelRetrySerial = SafeNumber(state.characterCreationPanelRetrySerial, 0) + 1
            local retrySerial = state.characterCreationPanelRetrySerial
            ExecuteWithDelay(DelayMs(1), function()
                RunOnGameThread(function()
                    if retrySerial ~= state.characterCreationPanelRetrySerial then return end
                    if IsValidObject(controller) then
                        ShowPanel(controller, reason)
                    end
                end)
            end)
        end
        return
    end

    if state.characterCreationPanelWasBlocked == true and type(ExecuteWithDelay) == "function" then
        state.characterCreationPanelWasBlocked = false
        state.characterCreationPanelRetrySerial = SafeNumber(state.characterCreationPanelRetrySerial, 0) + 1
        local retrySerial = state.characterCreationPanelRetrySerial
        ExecuteWithDelay(DelayMs(CONFIG.DelaySeconds), function()
            RunOnGameThread(function()
                if retrySerial ~= state.characterCreationPanelRetrySerial then return end
                if IsValidObject(controller) then
                    ShowPanel(controller, reason)
                end
            end)
        end)
        return
    end

    local savedChoice = GetSavedChoiceForController(controller)
    if savedChoice == "" and state.pendingInitialChoice ~= "" then
        savedChoice = NormalizeChoice(state.pendingInitialChoice)
        if savedChoice ~= "" then
            SaveChoiceForController(controller, savedChoice)
        end
    end

    if savedChoice ~= "" then
        TeleportSavedChoiceIfNeeded(controller, savedChoice, reason)
        return
    end

    if HasShownForCurrentPawn(controller) then return end
    if not ShouldShowPanel(controller, reason) then return end

    state.controller = controller
    state.playerId = GetPlayerId(controller)
    ShowChoiceBackdrop(controller)
    state.widget = CreateWidgetInstance(controller)

    if not IsValidObject(state.widget) then
        HideChoiceBackdrop()
        Log("Pannello non mostrato: widget non valido.")
        return
    end

    state.visible = true
    state.shownOnce = true
    MarkShownForCurrentPawn(controller)
    SetMouse(controller, true, state.widget)
    Log("Pannello UMG mostrato" .. (state.playerId ~= "" and (" (" .. state.playerId .. ")") or "") .. ". Motivo: " .. tostring(reason))
end

local function QueuePanel(controller, reason)
    if not IsLocalController(controller) then return end
    NoticePawnChange(controller, reason)
    if HasShownForCurrentPawn(controller) then return end

    if type(ExecuteWithDelay) == "function" then
        ExecuteWithDelay(DelayMs(CONFIG.DelaySeconds), function()
            RunOnGameThread(function()
                ShowPanel(controller, reason)
            end)
        end)
    else
        RunOnGameThread(function()
            ShowPanel(controller, reason)
        end)
    end
end

local function ResetAndQueuePanel(controller, reason)
    if not IsLocalController(controller) then return end

    if state.visible then
        HidePanel(nil)
    end

    state.shownOnce = false
    state.shownPawnKeys = {}
    state.currentPawnKey = ""
    QueuePanel(controller, reason)
end

local function ClickRoleplayIntro()
    if not state.roleplayIntroVisible then return end

    local controller = state.roleplayIntroController
    if not IsValidObject(controller) then
        controller = FindLocalController()
        state.roleplayIntroController = controller
    end
    if not IsValidObject(controller) then return end

    local mouseX, mouseY = GetMousePosition(controller)
    if not mouseX or not mouseY then
        Log("Click intro roleplayer letto, ma posizione mouse non disponibile.")
        return
    end

    local bounds = state.roleplayIntroButton
    if not bounds then
        local sx, sy = GetViewportSize(controller)
        bounds = {
            x1 = (sx / 2) - 180,
            x2 = (sx / 2) + 180,
            y1 = sy - 150,
            y2 = sy - 70,
        }
    end

    if mouseX >= bounds.x1 and mouseX <= bounds.x2 and mouseY >= bounds.y1 and mouseY <= bounds.y2 then
        HideRoleplayIntro()
    end
end

local function ClickChoice()
    if state.roleplayIntroVisible then
        ClickRoleplayIntro()
        return
    end

    if not state.visible then return end

    local controller = state.controller
    if not IsValidObject(controller) then
        controller = FindLocalController()
        state.controller = controller
    end
    if not IsValidObject(controller) then return end

    local mouseX, mouseY = GetMousePosition(controller)
    if not mouseX or not mouseY then
        Log("Click letto, ma posizione mouse non disponibile.")
        return
    end

    local sx, sy = GetViewportSize(controller)
    local centerX = sx / 2
    local centerY = sy / 2
    local y1 = centerY + 92
    local y2 = centerY + 215
    local leftX1 = centerX - 620
    local leftX2 = centerX - 240
    local rightX1 = centerX + 230
    local rightX2 = centerX + 640

    Debug("Click " .. tostring(mouseX) .. "," .. tostring(mouseY) .. " viewport " .. tostring(sx) .. "x" .. tostring(sy))

    if mouseY >= y1 and mouseY <= y2 and mouseX >= leftX1 and mouseX <= leftX2 then
        HidePanel("player")
    elseif mouseY >= y1 and mouseY <= y2 and mouseX >= rightX1 and mouseX <= rightX2 then
        HidePanel("roleplayer")
    end
end

RegisterHook("/Script/Engine.PlayerController:ClientRestart", function(self)
    local ok, controller = pcall(function() return self:get() end)
    if ok then
        RunOnGameThread(function()
            if IsLocalController(controller) then
                QueuePanel(controller, "ClientRestart")
            end
        end)
    end
end)

pcall(function()
    RegisterHook("/Script/Engine.PlayerController:PlayerTick", function(self)
        if type(ExecuteWithDelay) == "function" then return end
        if state.awaitingStartLocationAfterUniqueness ~= true then return end
        if os.clock() - SafeNumber(state.awaitingStartLocationAt, 0) > 8 then
            state.awaitingStartLocationAfterUniqueness = false
            return
        end

        local ok, controller = pcall(function() return self:get() end)
        if ok and IsLocalController(controller) then
            RunOnGameThread(function()
                TickVanillaStartLocationSkip(controller)
            end)
        end
    end)
end)

local function HandleUniquenessNextClicked(reason)
    local controller = FindLocalController()
    if IsValidObject(controller) then
        local savedChoice = GetSavedChoiceForController(controller)
        if savedChoice ~= "" then
            state.awaitingStartLocationAfterUniqueness = true
            state.awaitingStartLocationAt = os.clock()
            StartCharacterCreationUiScan(reason or "Avanti Unicita con scelta salvata", 8)
            FinishSavedChoiceFromUniqueness(controller, reason or "Avanti Unicita con scelta gia' salvata")
        else
            state.awaitingStartLocationAfterUniqueness = false
            state.awaitingStartLocationAt = 0
            Debug("Avanti Unicita senza scelta salvata: lascio proseguire Luogo di partenza vanilla.")
        end
    else
        Debug("Avanti Unicita senza controller: nessuno scan avviato.")
    end
end

local function RegisterCharacterCreationHook(path, label, handler)
    local ok, err = pcall(function()
        RegisterHook(path, function(self)
            RunOnGameThread(function()
                handler(self)
            end)
        end)
    end)

    if ok then
        Debug("Hook creazione registrato: " .. tostring(label))
    else
        Debug("Hook creazione NON registrato: " .. tostring(label) .. " - " .. SafeToString(err))
    end
end

if CONFIG.RegisterCharacterCreationBlueprintHooks then
RegisterCharacterCreationHook(
    "/Game/Vein/UI/UMG/CharacterCreation/WBP_CharacterCreation.WBP_CharacterCreation_C:Construct",
    "CharacterCreation Construct",
    function()
        StartCharacterCreationUiScan("Construct WBP_CharacterCreation", 60)
    end
)

RegisterCharacterCreationHook(
    "/Game/Vein/UI/UMG/CharacterCreation/WBP_CharacterCreation.WBP_CharacterCreation_C:BndEvt__WBP_CharacterCreation_Next5_K2Node_ComponentBoundEvent_33_OnButtonClicked__DelegateSignature",
    "Avanti Unicita Next5",
    function()
        HandleUniquenessNextClicked("Avanti Unicita Next5")
    end
)

-- Il testo sul bottone puo' essere tradotto ("Avanti"), ma i nomi interni restano Next.
-- Agganciamo anche gli altri Next: se VEIN cambia indice pagina, lo scanner trova comunque
-- la schermata Luogo di partenza e la salta.
for _, hook in ipairs({
    {
        path = "/Game/Vein/UI/UMG/CharacterCreation/WBP_CharacterCreation.WBP_CharacterCreation_C:BndEvt__WBP_CharacterCreation_Next1_K2Node_ComponentBoundEvent_0_OnButtonClicked__DelegateSignature",
        label = "Avanti Next1",
    },
    {
        path = "/Game/Vein/UI/UMG/CharacterCreation/WBP_CharacterCreation.WBP_CharacterCreation_C:BndEvt__WBP_CharacterCreation_Next2_K2Node_ComponentBoundEvent_3_OnButtonClicked__DelegateSignature",
        label = "Avanti Next2",
    },
    {
        path = "/Game/Vein/UI/UMG/CharacterCreation/WBP_CharacterCreation.WBP_CharacterCreation_C:BndEvt__WBP_CharacterCreation_Next3_K2Node_ComponentBoundEvent_5_OnButtonClicked__DelegateSignature",
        label = "Avanti Next3",
    },
    {
        path = "/Game/Vein/UI/UMG/CharacterCreation/WBP_CharacterCreation.WBP_CharacterCreation_C:BndEvt__WBP_CharacterCreation_Next4_K2Node_ComponentBoundEvent_18_OnButtonClicked__DelegateSignature",
        label = "Avanti Next4",
    },
}) do
    local hookPath = hook.path
    local hookLabel = hook.label
    RegisterCharacterCreationHook(hookPath, hookLabel, function()
        StartCharacterCreationUiScan(hookLabel, 18)
    end)
end

RegisterCharacterCreationHook(
    "/Game/Vein/UI/UMG/CharacterCreation/WBP_CharacterCreation.WBP_CharacterCreation_C:BndEvt__WBP_CharacterCreation_CompleteButton_K2Node_ComponentBoundEvent_1_OnButtonClicked__DelegateSignature",
    "Termina vanilla",
    function()
        StartCharacterCreationUiScan("Termina vanilla", 8)
    end
)

-- Fallback: se il nome del pulsante cambia tra build, questo scan breve dopo ogni click del widget
-- intercetta comunque la pagina Luogo di partenza e la chiude se la scelta e' gia' salvata.
RegisterCharacterCreationHook(
    "/Game/Vein/UI/UMG/CharacterCreation/WBP_CharacterCreation.WBP_CharacterCreation_C:ExecuteUbergraph_WBP_CharacterCreation",
    "CharacterCreation ExecuteUbergraph fallback",
    function()
        StartCharacterCreationUiScan("ExecuteUbergraph WBP_CharacterCreation", 3)
    end
)
end

pcall(function()
    RegisterHook("/Script/Vein.VeinPlayerController:Server_SelectCharacter", function(self)
        local ok, controller = pcall(function() return self:get() end)
        if ok then
            RunOnGameThread(function()
                if IsLocalController(controller) then
                    ResetAndQueuePanel(controller, "Server_SelectCharacter")
                end
            end)
        end
    end)
end)

pcall(function()
    RegisterHook("/Script/Vein.VeinPlayerController:Server_LoadCharacter", function(self)
        local ok, controller = pcall(function() return self:get() end)
        if ok then
            RunOnGameThread(function()
                if IsLocalController(controller) then
                    ResetAndQueuePanel(controller, "Server_LoadCharacter")
                end
            end)
        end
    end)
end)

RegisterLoadMapPostHook(function()
    RunOnGameThread(function()
        HideStartLocationGuidelines()
        HideRoleplayIntro()
        HidePanel(nil)
        state.shownOnce = false
        state.shownPawnKeys = {}
        state.teleportedPawnKeys = {}
        state.currentPawnKey = ""
        state.preSpawnChoice = false
        state.vanillaFinishInProgress = false
        state.vanillaFinishFailureCount = 0
        state.vanillaStartLocationHidden = {}
        state.vanillaStartLocationLastScanAt = 0
        state.awaitingStartLocationAfterUniqueness = false
        state.awaitingStartLocationAt = 0
        state.characterCreationScanSerial = state.characterCreationScanSerial + 1
        state.characterCreationScanLastStart = 0
        state.startLocationGuidelinesScanSerial = SafeNumber(state.startLocationGuidelinesScanSerial, 0) + 1
        state.startLocationGuidelinesScanLastStart = 0
    end)
end)

pcall(function()
    RegisterKeyBind(Key.LEFT_MOUSE_BUTTON, function()
        ExecuteInGameThread(function()
            ClickChoice()
            StartLocationGuidelinesScan("click UI creazione personaggio", 8)
            StartCharacterCreationScanAfterUiClick()
        end)
    end)
end)

RegisterConsoleCommandHandler("cammino_ui", function()
    RunOnGameThread(function()
        local controller = FindLocalController()
        if IsValidObject(controller) then
            HidePanel(nil)
            state.shownOnce = false
            local pawnKey = GetPawnKey(controller)
            if pawnKey ~= "" then
                state.shownPawnKeys[pawnKey] = nil
            end
            ShowPanel(controller, "console")
        else
            Log("Nessun PlayerController locale trovato.")
        end
    end)
    return true
end)

RegisterConsoleCommandHandler("cammino_ui_close", function()
    RunOnGameThread(function()
        HideStartLocationGuidelines()
        HideRoleplayIntro()
        HidePanel(nil)
    end)
    return true
end)

RegisterConsoleCommandHandler("cammino_guidelines", function()
    RunOnGameThread(function()
        StartLocationGuidelinesScan("console", 10)
    end)
    return true
end)

RegisterConsoleCommandHandler("cammino_intro", function()
    RunOnGameThread(function()
        local controller = FindLocalController()
        if IsValidObject(controller) then
            HideRoleplayIntro()
            ShowRoleplayIntro(controller)
        else
            Log("Nessun PlayerController locale trovato per intro roleplayer.")
        end
    end)
    return true
end)

RegisterConsoleCommandHandler("cammino_intro_player", function()
    RunOnGameThread(function()
        local controller = FindLocalController()
        if IsValidObject(controller) then
            HideRoleplayIntro()
            ShowPlayerIntro(controller)
        else
            Log("Nessun PlayerController locale trovato per intro player.")
        end
    end)
    return true
end)

RegisterConsoleCommandHandler("cammino_intro_roleplay_respawn", function()
    RunOnGameThread(function()
        local controller = FindLocalController()
        if IsValidObject(controller) then
            HideRoleplayIntro()
            ShowRoleplayRespawnIntro(controller)
        else
            Log("Nessun PlayerController locale trovato per intro roleplayer respawn.")
        end
    end)
    return true
end)

RegisterConsoleCommandHandler("cammino_ui_reset", function()
    RunOnGameThread(function()
        HideRoleplayIntro()
        savedChoices = {}
        choicesLoaded = true
        RewriteClientChoicesFile()
        state.shownOnce = false
        state.shownPawnKeys = {}
        state.teleportedPawnKeys = {}
        state.pendingInitialChoice = ""
        state.pendingInitialChoiceAt = 0
        state.vanillaFinishFailureCount = 0
        state.awaitingStartLocationAfterUniqueness = false
        state.awaitingStartLocationAt = 0
        state.characterCreationScanSerial = state.characterCreationScanSerial + 1
        state.characterCreationScanLastStart = 0
        Log("Scelte client resettate. Per resettare anche il server usa: cammino_reset all")
    end)
    return true
end)

RegisterConsoleCommandHandler("cammino_skip_location_scan", function()
    RunOnGameThread(function()
        local controller = FindLocalController()
        if IsValidObject(controller) then
            state.vanillaStartLocationLastScanAt = 0
            TickVanillaStartLocationSkip(controller)
            Log("Scan manuale Luogo di partenza eseguito.")
        else
            Log("Nessun PlayerController locale trovato per scan Luogo di partenza.")
        end
    end)
    return true
end)

RegisterConsoleCommandHandler("cammino_finish_vanilla", function()
    RunOnGameThread(function()
        FinalizeVanillaCharacterCreation("console")
    end)
    return true
end)

RegisterConsoleCommandHandler("cammino_debug_widgets", function()
    RunOnGameThread(function()
        local ok, widgets = pcall(function() return FindAllOf("UserWidget") end)
        if not ok or not widgets then
            ok, widgets = pcall(function() return FindAllOf("Widget") end)
            if not ok or not widgets then
                Log("Debug widget fallito: FindAllOf(UserWidget/Widget) non disponibile.")
                return
            end
        end

        local count = 0
        Log("Widget UMG attivi filtrati:")
        for _, widget in ipairs(widgets) do
            if IsValidObject(widget) then
                local fullName = ""
                pcall(function() fullName = widget:GetFullName() end)
                if fullName == "" then
                    pcall(function() fullName = widget:GetName() end)
                end

                local lowerName = tostring(fullName):lower()
                if lowerName:match("spawn") or lowerName:match("start") or lowerName:match("location")
                    or lowerName:match("character") or lowerName:match("cammino") or lowerName:match("finish")
                    or lowerName:match("complete") or lowerName:match("unique") or lowerName:match("occupation") then
                    count = count + 1
                    Log("Widget: " .. tostring(fullName))
                end
            end
        end
        Log("Fine debug widget. Trovati: " .. tostring(count))
    end)
    return true
end)

StartCharacterCreationWatchdog()

Log("Caricata. Usa cammino_ui per testare scelta, cammino_intro per testare intro roleplayer, cammino_intro_player per testare intro player, cammino_intro_roleplay_respawn per testare respawn roleplayer. Reset client: cammino_ui_reset, debug widget: cammino_debug_widgets, skip location: cammino_skip_location_scan")
