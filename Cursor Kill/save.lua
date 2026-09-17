-- ============================================================
-- save.lua – упрощённая система сохранений (с отладкой)
-- ============================================================
local save = {}

local SAVE_VERSION = 1
local HIGHSCORE_SEED = 0x5EED

-- Функция для отладки (выводит в консоль)
local function debugPrint(msg)
    print("[SAVE] " .. msg)
end

-- Шифрование
local function bxor(a, b)
    local result = 0
    local bitval = 1
    while a > 0 or b > 0 do
        if a % 2 ~= b % 2 then
            result = result + bitval
        end
        bitval = bitval * 2
        a = math.floor(a / 2)
        b = math.floor(b / 2)
    end
    return result
end

local function encryptString(str, seed)
    local bytes = {}
    local key = seed or 0x7A3F
    for i = 1, #str do
        local byte = string.byte(str, i)
        local keyByte = key % 256
        bytes[i] = string.char(bxor(byte, keyByte))
        key = (key * 31 + i) % 65536
    end
    return table.concat(bytes)
end

local function decryptString(data, seed)
    return encryptString(data, seed)
end

-- Получение пути к файлу сохранения
local function getSaveFilePath()
    local base = system.pathForFile("", system.DocumentsDirectory)
    debugPrint("DocumentsDirectory: " .. tostring(base))
    
    if not base or base == "" then
        base = system.pathForFile("", system.TemporaryDirectory)
        debugPrint("TemporaryDirectory: " .. tostring(base))
    end
    
    if not base or base == "" then
        base = "."
        debugPrint("Using current directory: " .. base)
    end
    
    if base:sub(-1) == "/" or base:sub(-1) == "\\" then
        base = base:sub(1, -2)
    end
    
    local fileName = "PlayerData.dat"
    local fullPath = base .. "/" .. fileName
    
    debugPrint("Full save path: " .. fullPath)
    
    return fullPath
end

-- Альтернативный путь
local function getAlternativeSavePath()
    local temp = system.pathForFile("", system.TemporaryDirectory)
    debugPrint("Alternative path (temp): " .. tostring(temp))
    
    if temp and temp ~= "" then
        if temp:sub(-1) == "/" or temp:sub(-1) == "\\" then
            temp = temp:sub(1, -2)
        end
        return temp .. "/PlayerData.dat"
    end
    return nil
end

-- Парсинг строки с пройденными уровнями
local function parseCompleted(str)
    local result = {}
    if str and str ~= "" then
        for key in string.gmatch(str, "[^,]+") do
            result[key] = true
        end
    end
    return result
end

local function parseReplayed(str)
    local result = {}
    if str and str ~= "" then
        for key in string.gmatch(str, "[^,]+") do
            result[key] = true
        end
    end
    return result
end

local function serializeCompleted(completed)
    local keys = {}
    for key in pairs(completed) do
        keys[#keys + 1] = key
    end
    table.sort(keys)
    return table.concat(keys, ",")
end

local function serializeReplayed(replayed)
    local keys = {}
    for key in pairs(replayed) do
        keys[#keys + 1] = key
    end
    table.sort(keys)
    return table.concat(keys, ",")
end

-- ЗАГРУЗКА ДАННЫХ
function save.loadPlayerData()
    debugPrint("=== LOADING PLAYER DATA ===")
    
    local filePath = getSaveFilePath()
    debugPrint("Trying to load from: " .. filePath)
    
    local file = io.open(filePath, "r")
    if not file then
        debugPrint("File not found at primary path")
        local altPath = getAlternativeSavePath()
        if altPath then
            debugPrint("Trying alternative path: " .. altPath)
            file = io.open(altPath, "r")
            if file then
                debugPrint("File found at alternative path!")
                filePath = altPath
            else
                debugPrint("File not found at alternative path either")
            end
        end
    else
        debugPrint("File found at primary path!")
    end
    
    if not file then
        debugPrint("No save file found, returning default data")
        return { 
            brains = 0, 
            completed = {}, 
            replayed = {},
            medkits = 0, 
            energy = 0, 
            grenades = 0,
            firstRun = 0 
        }
    end
    
    local encrypted = file:read("*a")
    file:close()
    debugPrint("Read " .. string.len(encrypted) .. " bytes from file")
    
    if not encrypted or #encrypted == 0 then
        debugPrint("File is empty, returning default data")
        return { brains = 0, completed = {}, replayed = {}, medkits = 0, energy = 0, grenades = 0, firstRun = 0 }
    end
    
    local decrypted = decryptString(encrypted, HIGHSCORE_SEED)
    debugPrint("Decrypted data: " .. (decrypted or "nil"))
    
    if not decrypted or decrypted == "" then
        debugPrint("Decryption failed, returning default data")
        return { brains = 0, completed = {}, replayed = {}, medkits = 0, energy = 0, grenades = 0, firstRun = 0 }
    end
    
    local brains = tonumber(decrypted:match("brains=(%d+)")) or 0
    local completedStr = decrypted:match("completed=([^;]*)") or ""
    local replayedStr = decrypted:match("replayed=([^;]*)") or ""
    local firstRun = tonumber(decrypted:match("firstRun=(%d+)")) or 0
    local medkits = tonumber(decrypted:match("medkits=(%d+)")) or 0
    local energy = tonumber(decrypted:match("energy=(%d+)")) or 0
    local grenades = tonumber(decrypted:match("grenades=(%d+)")) or 0
    
    local completed = parseCompleted(completedStr)
    local replayed = parseReplayed(replayedStr)
    
    debugPrint("Loaded data: brains=" .. brains .. ", medkits=" .. medkits .. 
               ", energy=" .. energy .. ", grenades=" .. grenades)
    
    -- Выводим ключи для проверки
    local compKeys = {}
    for k in pairs(completed) do
        table.insert(compKeys, k)
    end
    debugPrint("Completed keys: " .. table.concat(compKeys, ", "))
    
    return {
        brains = brains,
        completed = completed,
        replayed = replayed,
        medkits = medkits,
        energy = energy,
        grenades = grenades,
        firstRun = firstRun
    }
end

-- СОХРАНЕНИЕ ДАННЫХ
function save.savePlayerData(brains)
    debugPrint("=== SAVING PLAYER DATA ===")
    debugPrint("Brains to save: " .. tostring(brains))
    
    local filePath = getSaveFilePath()
    debugPrint("Saving to: " .. filePath)
    
    local testFile = io.open(filePath, "w")
    if not testFile then
        debugPrint("Cannot write to primary path, trying alternative")
        local altPath = getAlternativeSavePath()
        if altPath then
            debugPrint("Trying alternative path: " .. altPath)
            testFile = io.open(altPath, "w")
            if testFile then
                debugPrint("Using alternative path!")
                filePath = altPath
            else
                debugPrint("Cannot write to alternative path either!")
                return false
            end
        else
            debugPrint("No alternative path available!")
            return false
        end
    end
    testFile:close()
    
    local completed = _G.completedLevels or {}
    local replayed = _G.replayedLevels or {}
    local medkits = _G.medkits or 0
    local energy = _G.energyDrinks or 0
    local grenades = _G.grenades or 0
    local firstRun = _G.firstRun or 0
    local brainPieces = brains or _G.brainPieces or 0
    
    debugPrint("Global vars: medkits=" .. medkits .. ", energy=" .. energy .. 
               ", grenades=" .. grenades .. ", brainPieces=" .. brainPieces)
    debugPrint("Completed levels: " .. serializeCompleted(completed))
    debugPrint("Replayed levels: " .. serializeReplayed(replayed))
    
    local dataStr = "version=" .. SAVE_VERSION ..
                    ";brains=" .. tostring(brainPieces) ..
                    ";completed=" .. serializeCompleted(completed) ..
                    ";firstRun=" .. tostring(firstRun) ..
                    ";replayed=" .. serializeReplayed(replayed) ..
                    ";medkits=" .. tostring(medkits) ..
                    ";energy=" .. tostring(energy) ..
                    ";grenades=" .. tostring(grenades)
    
    debugPrint("Data string: " .. dataStr)
    
    local encrypted = encryptString(dataStr, HIGHSCORE_SEED)
    debugPrint("Encrypted data length: " .. string.len(encrypted))
    
    local file = io.open(filePath, "w")
    if file then
        file:write(encrypted)
        file:close()
        debugPrint("Save successful!")
        return true
    end
    
    debugPrint("Save failed!")
    return false
end

-- ОБНОВЛЕНИЕ КОНКРЕТНЫХ ПОЛЕЙ
function save.updatePlayerData(fields)
    debugPrint("=== UPDATING PLAYER DATA ===")
    local data = save.loadPlayerData()
    for key, value in pairs(fields) do
        data[key] = value
        debugPrint("Updated " .. key .. " = " .. tostring(value))
    end
    save.savePlayerData(data.brains or 0)
end

-- ОТМЕТКА УРОВНЯ КАК ПРОЙДЕННОГО
function save.markLevelCompleted(key)
    debugPrint("=== MARKING LEVEL COMPLETED: " .. key)
    local data = save.loadPlayerData()
    data.completed[key] = true
    save.savePlayerData(data.brains or 0)
end

-- ПРОВЕРКА, ПРОЙДЕН ЛИ УРОВЕНЬ
function save.isLevelCompleted(key)
    local data = save.loadPlayerData()
    return data.completed[key] == true
end

return save