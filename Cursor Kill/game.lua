composer = require("composer")  -- убрали local
scene = composer.newScene()     -- убрали local
physics = require("physics")    -- убрали local
physics.setPositionIterations(64)
physics.setVelocityIterations(48)
physics.setGravity(0, 0)
local save = require("save")
mainGroup, ui, player, enemies, walls, spawnerPoints = nil, nil, nil, {}, {}, {}
energyBar, healthBar, ammoText, weaponNameText, killsText, fpsText = nil, nil, nil, nil, nil, nil
medkitIcon, medkitText, energyIcon, energyText, aimLine, rapidIndicator = nil, nil, nil, nil, nil, nil
isShooting, lastBulletTime, energy, hp, ammo, isReloading, isDead = false, 0, 0, 0, nil, false, false
move = { up=false, down=false, left=false, right=false }
isRunning, isCrouching, isDashing, targetAngle, rotateSpeed = false, false, false, 0, 8
mouseX, mouseY, lastLineX, lastLineY, aimStartTime, isAiming = display.contentCenterX, display.contentCenterY, nil, nil, 0, false
killsCount, lastHitTime, frameCounter, activeTimers = 0, 0, 0, {}
zombiesSpawned, allZombiesSpawned, levelWon, levelMaxZombies = 0, false, false, 0
-- УБИРАЕМ ДУБЛИРУЮЩИЕСЯ ОБЪЯВЛЕНИЯ! Оставляем только один раз:
completedLevels = {}      -- ГЛОБАЛЬНАЯ (без local)
replayedLevels = {}       -- ГЛОБАЛЬНАЯ (без local)
medkits = 0               -- ГЛОБАЛЬНАЯ (без local)
energyDrinks = 0          -- ГЛОБАЛЬНАЯ (без local)
grenades = 0              -- ГЛОБАЛЬНАЯ (без local)
brainPieces = 0           -- ГЛОБАЛЬНАЯ (без local)
currentRewards = {}
lowHpOverlay = nil  -- добавить в раздел глобальных переменных (вверху game.lua)
damageFlashTimer = nil  -- таймер для управления миганием
damageFlashOverlay = nil  -- оверлей
checkLevelComplete = nil
playerSpawnFromMap = nil
gameStarted = false
tileSize = 100
warning = nil
fireRateMultiplier = 1.0
enlightenmentActive = false
enlightenmentEndTime = 0
enlightenmentTimer = nil
fireRateTimer = nil
fogGroup = nil        -- группа для тумана войны
fogTiles = {}         -- таблица { [row] = { [col] = rect } }
damageTextGroup = nil
medkits = 0
energyDrinks = 0
grenades = 0
brainPieces = 0
completedLevels = {}
replayedLevels = {}
lastExtraUseTime = 0
exploredUpdateTimer = nil
fogUpdateTimer = nil   -- таймер обновления целевых альф
fogDirty = false       -- флаг, что нужно пересчитать альфы
lastUltimateUseTime = 0
energyBoostActive, originalMaxEnergy, rapidEndTime = false, nil, nil
lastRegenTime = nil
grenadeIcon, grenadeText = nil, nil
grenades = 0
reloadSpeedMultiplier = 1.0
playerInvis = nil
minimapGroup, minimapPlayerIcon, minimapZombieIcons, minimapLootIcons = nil, nil, {}, {}
minimapSize = 150
mapWidth, mapHeight = nil, nil
ultimateCooldownBarBack, ultimateCooldownBar = nil, nil
isPaused = false
pauseGroup = nil
pauseMenuItems = {}
chestProgressTransition = nil
chestMovementTimer = nil
traderMenuGroup = nil
explored = {}   -- explored[row][col] = true/false
traderMenuActive = false
traderMenuBrainText = nil
closeTraderMenu = nil
local shotCounter = 0
doors = {}
donorChunks = {}
chests = {}
minimapChestIcons = {}
doorHint = nil
elevator = nil
elevatorHint = nil
elevatorActive = false
elevatorSequenceDone = false
elevatorCutsceneActive = false
-- chest looting variables
activeChest = nil
chestProgressBar = nil
chestProgressFill = nil
chestProgressTimer = nil
chestLootingActive = false
chestLootingStartX = nil
chestLootingStartY = nil
chestHint = nil
currentAimAngle = 0
-- burst-состояние теперь в vars.burst (нужно для уменьшения upvalues)
brainPieces = 0
brainPiecesText = nil
poisonTimer = nil
BRAIN_SAVE_KEY = 0x7A3F  -- оставим local? Нет, используем как глобальную? Но она не используется в startLevel, можно оставить local, но для простоты уберём local
-- вертикальная шкала перезарядки экстра-навыка
extraCooldownBarBack = nil
extraCooldownBar = nil
playerSpawnFromMap = nil
ultimateActive = false
ultimateEndTime = 0
ultimateCooldownEndTime = 0
lootingProgressText = nil
corpses = {}
gasCanisters = {}          -- таблица для хранения газовых баллонов
gasCanisterIcons = {}      -- иконки на миникарте
corpseHint = nil
doorTypes = {base = {hp = 30}}
viewRadius = 3   -- радиус видимости в клетках
-- Добавить после doorTypes
gasCanisterTypes = {
    base = { hp = 75, explosionRadius = 300, maxDamage = 75, minDamage = 25, 
             doorBreakRadius = 450, playerDamageMax = 45, playerDamageMin = 15,
             burnDamage = 10, burnDuration = 5000, burnTick = 1000 }
}
FORCE_ZOMBIE_TYPE = false
lastFrameTime = 0
fpsAccum = 0
fpsFrames = 0
displayFPS = 60


-- Группируем часть состояния, чтобы уменьшить число upvalues
vars = {
    burst = {
        active = false,
        timer = nil,
        remaining = 0,
        weapon = nil,
    }
}

local function cancelBurst()
    if vars.burst.timer then
        timer.cancel(vars.burst.timer)
        vars.burst.timer = nil
    end
    vars.burst.active = false
    vars.burst.remaining = 0
    vars.burst.weapon = nil
end





zombieTypes = {
    zombie      = { maxHp = 175, attackRate = 900,   speed = 90,  dmg = 10, weight = 35, xSize = 35, ySize = 35 },
    runner      = { maxHp = 100, attackRate = 650,   speed = 160, dmg = 8,  weight = 33, xSize = 28, ySize = 28 },
    fatty       = { maxHp = 350, attackRate = 1200,  speed = 50,  dmg = 22, weight = 7,  xSize = 45, ySize = 45 },
    heavy       = { maxHp = 800, attackRate = 1500,  speed = 40,  dmg = 35, weight = 3,  xSize = 55, ySize = 55 },
    berserker   = { maxHp = 275, attackRate = 400,   speed = 140, dmg = 20, weight = 4,  xSize = 38, ySize = 38 },
    healer      = { maxHp = 200, attackRate = 1500,  speed = 100, dmg = 5,  weight = 6,  xSize = 35, ySize = 35 },
    ghost       = { maxHp = 135, attackRate = 950,   speed = 80,  dmg = 9,  weight = 5,  xSize = 32, ySize = 32,  color = {0.7, 0.85, 1} },
    donor       = { maxHp = 150, attackRate = 999999,speed = 110, dmg = 0,  weight = 5,  xSize = 35, ySize = 35, throwDamage = 35, throwSelfDamage = 50, throwCooldown = 3000, throwRange = 350, color = {0.9, 0.2, 0.2}, description = "Кружит вокруг, отрывает куски плоти с самонаведением" },
    exploder    = { maxHp = 120, attackRate = 1500,  speed = 85,  dmg = 15, weight = 3,  xSize = 30, ySize = 30 },
    archer      = { maxHp = 140, attackRate = 900,   speed = 110, dmg = 8,  rangedDmg = 17, rangedRate = 1750, rangedRange = 500, projectileSpeed = 600, weight = 8, xSize = 32, ySize = 32, color = {0.8, 0.5, 0.2} },
    teleporter  = { maxHp = 180, attackRate = 1000,  speed = 65,  dmg = 3,  weight = 1,  xSize = 32, ySize = 32, teleportCooldown = 12000, doubleAttackDelay = 3000 },
    crikey      = { maxHp = 180, attackRate = 10000, speed = 110, dmg = 15, weight = 6,  xSize = 32, ySize = 32, screamCooldown = 10000, screamRadius = 400 },
    summoner    = { maxHp = 200, attackRate = 1200, speed = 70, dmg = 8, weight = 4, xSize = 35, ySize = 35, summonCooldown = 30000, summonRadius = 200 },
    acid_zombie = { maxHp = 175, attackRate = 1200, speed = 90, dmg = 10, weight = 5, xSize = 35, ySize = 35, pukeRate = 10000, pukeRange = 400, pukeAngle = 60, pukeDmg = 20, color = {0.4, 1, 0} },
}

weapons = {
    ["Glock-17"] = {
        name = "Glock-17", clip = 17, currentClip = 17,
        reloadT = 1050, rate = 275, bSpeed = 650,
        dmg = 12, spread = 2, bullets = 90,
        barrelLen = 15, critChance = 15, critMult = 2.0,
        aimMult = 1.3, range = 800, pellets = 1,
        burstCount = 1, aimTime = 400
    },
    ["AK-47"] = {
        name = "AK-47", clip = 30, currentClip = 30,
        reloadT = 2100, rate = 120, bSpeed = 800,
        dmg = 19, spread = 5, bullets = 210,
        barrelLen = 22, critChance = 10, critMult = 1.8,
        aimMult = 1.5, range = 1600, pellets = 1,
        burstCount = 3, aimRepeat = 2, aimRepeatDelay = 100,
        aimSplash = 1, aimTime = 500, burstModeEnabled = false,
        burstDelay = 75, burstCooldown = 350, burstSpread = 2,
        aimBurstCount = 1
    },
    ["Benelli M4"] = {
        name = "Benelli M4", clip = 7, currentClip = 7,
        reloadT = 2450, rate = 600, bSpeed = 500,
        dmg = 36, spread = 4, bullets = 28,
        barrelLen = 16, critChance = 5, critMult = 1.25,
        aimMult = 1.3, range = 175, minDmgMult = 0.3,
        pellets = 3, shotAngle = 17, burstCount = 2,
        burstDelay = 150, isShotgun = true, splash = 2,
        splashMult = 1.5, aimTime = 500
    },
    ["Spas-12"] = {
        name = "Spas-12", clip = 8, currentClip = 8,
        reloadT = 2800, rate = 900, bSpeed = 700,
        dmg = 28, spread = 1.5, bullets = 24,
        barrelLen = 24, critChance = 12, critMult = 1.6,
        aimMult = 1.6, range = 750, minDmgMult = 0.5,
        pellets = 2, shotAngle = 6, burstCount = 1,
        burstDelay = 0, isShotgun = true, splash = 2,
        splashMult = 1.6, aimTime = 500
    },
    ["Grenade"] = {
        damage = 95, explosionRadius = 300, throwSpeed = 500,
        fuseTime = 400, minDamage = 25
    },
    ["Barrett M82"] = {
        name = "Barrett M82", clip = 2, currentClip = 2,
        reloadT = 2500, rate = 120, bSpeed = 750,
        dmg = 61, spread = 1, bullets = 16,
        barrelLen = 35, critChance = 10, splash = 2,
        critMult = 1.3, aimMult = 1.5, range = 3200,
        pellets = 1, burstCount = 1, aimSplash = 4,
        aimTime = 650
    },
    ["Plazmite"] = {
        name = "Plazmite", clip = 6, currentClip = 6,
        reloadT = 1250, rate = 75, bSpeed = 1000,
        dmg = 13, spread = 0, bullets = 64,
        barrelLen = 22, critChance = 15, splash = 3,
        critMult = 1.3, aimMult = 1.5, range = 3200,
        pellets = 1, burstCount = 3, aimSplash = 4,
        aimTime = 650, isBurst = true, burstDelay = 135,
        burstCooldown = math.floor(1500 / 4)
    }
}

playerExtras = {
    ["shockWave"] = {damage = 25, radius = 450, colldown = 7500, push = 25, stunDuration = 0.5, type = "wave"},
    ["enlightenment"] = {type = "enlightenment", duration = 6000, colldown = 15000}
}

playerUltimates = {
    ["invisible"] = {func = "playerInvis", time = 7500, colldown = 10000},
    ["phase"]     = {func = "playerPhase", time = 3500, colldown = 15000}
}

lootTypes = {
    medkit = { color = {0, 1, 0}, chance = 13, min = 10, max = 30, label = "MEDKIT" },
    energy = { color = {1, 1, 0}, chance = 6, min = 1, max = 1, label = "ENERGY" },
    ammo_glock = { color = {1, 0.8, 0}, chance = 9, min = 10, max = 20, weapon = "Glock-17", label = "GLOCK" },
    ammo_ak47 = { color = {1, 0.5, 0}, chance = 9, min = 15, max = 30, weapon = "AK-47", label = "AK47" },
    ammo_benelli = { color = {0.8, 0.8, 0.8}, chance = 8, min = 4, max = 8, weapon = "Benelli M4", label = "SHELLS" },
    grenade = { color = {1, 0.5, 0}, chance = 6, min = 1, max = 1, label = "GRENADE" },
    ammo_plazmite = { color = {0.2, 0.6, 1}, chance = 5, min = 4, max = 8, weapon = "Plazmite", label = "PLAZMITE" },
    ammo_barrett = { color = {0.5, 0.5, 0.5}, chance = 4, min = 1, max = 3, weapon = "Barrett M82", label = "M82" }
}
chestLootTypes = {
    { chance = 18, label = "MEDKIT", type = "medkit", min = 1, max = 1 },
    { chance = 13, label = "ENERGY DRINK", type = "energy", min = 1, max = 1 },
    { chance = 11, label = "GLOCK AMMO", type = "ammo", weapon = "Glock-17", min = 15, max = 35 },
    { chance = 11, label = "AK47 AMMO", type = "ammo", weapon = "AK-47", min = 20, max = 50 },
    { chance = 10, label = "SHELLS", type = "ammo", weapon = "Benelli M4", min = 6, max = 15 },
    { chance = 10, label = "SPAS AMMO", type = "ammo", weapon = "Spas-12", min = 5, max = 12 },
    { chance = 7, label = "PLAZMITE AMMO", type = "ammo", weapon = "Plazmite", min = 5, max = 10 },
    { chance = 6, label = "M82 AMMO", type = "ammo", weapon = "Barrett M82", min = 2, max = 6 },
    { chance = 5, label = "HEALTH PACK", type = "health", min = 35, max = 65 },
    { chance = 5, label = "GRENADE", type = "grenade", min = 1, max = 2 },
    { chance = 4, label = "ENERGY BOOST", type = "energy_boost", min = 20, max = 50 }
}

stats = {
    speedNormal = 115, speedRun = 170, speedCrouch = 70,
    dashSpeed = 100000, dashTime = 855, dashCost = 25,
    maxEnergy = 150, regenBase = 12, regenCrMult = 1.25, runCost = 18,
    maxHp = 125,
    currentWeapon = weapons["Glock-17"],
    currentExtra = playerExtras["shockWave"],
    currentUltimate = playerUltimates["invisible"]
}

npcTypes = {
    trader = { name = _G.getText("trader"), hp = 100, color = {0.2, 0.2, 0.6}, interactionDistance = 100 }
}

npcs = {}



-- Вспомогательные функции обновления UI (вызываются после покупки)
function updateMedkitUI()
    if medkitText then
        medkitText.text = "x" .. medkits
        if medkits > 0 then medkitIcon.alpha = 1; medkitText.alpha = 1
        else medkitIcon.alpha = 0; medkitText.alpha = 0 end
    end
end

function updateEnergyUI()
    if energyText then
        energyText.text = "x" .. energyDrinks
        if energyDrinks > 0 then energyIcon.alpha = 1; energyText.alpha = 1
        else energyIcon.alpha = 0; energyText.alpha = 0 end
    end
end

function updateGrenadeUI()
    if grenadeText then
        grenadeText.text = "x" .. grenades
        if grenades > 0 then grenadeIcon.alpha = 1; grenadeText.alpha = 1
        else grenadeIcon.alpha = 0; grenadeText.alpha = 0 end
    end
end

function updateAmmoUI()
    local weapon = stats.currentWeapon
    if ammoText then
        ammoText.text = weapon.currentClip .. " | " .. weapon.bullets
    end
end

function updateHealthBar()
    if healthBar then
        healthBar.width = math.max(1, (hp / stats.maxHp) * 120)
    end
end

function updateEnergyBar()
    if energyBar then
        energyBar.width = math.max(1, (energy / stats.maxEnergy) * 120)
    end
end

-- Обновление отображения мозгов в панели статистики и в меню
function updateBrainDisplay()
    if statsBrainValue then
        statsBrainValue.text = tostring(brainPieces)
    end
    if traderMenuGroup and traderMenuBrainText and traderMenuBrainText.text then
    traderMenuBrainText.text = "МОЗГИ: " .. brainPieces
end
end

--[[ ========== МАГАЗИН ТОРГОВЦА ========== ]]
shopItems = {
    -- Лечение и баффы
    { name = "Medkit",        type = "medkit",      cost = 1,  action = function() medkits = medkits + 1; updateMedkitUI() end },
    { name = "Energy Drink",  type = "energy",      cost = 1,  action = function() energyDrinks = energyDrinks + 1; updateEnergyUI() end },
    { name = "Grenade",       type = "grenade",     cost = 2,  action = function() grenades = grenades + 1; updateGrenadeUI() end },
    { name = "Health Pack",   type = "health",      cost = 2,  action = function() hp = math.min(stats.maxHp, hp + 50); updateHealthBar() end },
    { name = "Energy Boost",  type = "energy_boost",cost = 1,  action = function() energy = math.min(stats.maxEnergy, energy + 30); updateEnergyBar() end },
    -- Патроны
    { name = "Glock Ammo x15",type = "ammo_glock",  cost = 1,  action = function() weapons["Glock-17"].bullets = weapons["Glock-17"].bullets + 15; updateAmmoUI() end },
    { name = "AK Ammo x20",   type = "ammo_ak47",   cost = 2,  action = function() weapons["AK-47"].bullets = weapons["AK-47"].bullets + 20; updateAmmoUI() end },
    { name = "Benelli Shells x6", type = "ammo_benelli", cost = 2, action = function() weapons["Benelli M4"].bullets = weapons["Benelli M4"].bullets + 6; updateAmmoUI() end },
    { name = "Spas Shells x5", type = "ammo_spas",  cost = 2,  action = function() weapons["Spas-12"].bullets = weapons["Spas-12"].bullets + 5; updateAmmoUI() end },
    { name = "Plazmite Ammo x5", type = "ammo_plazmite", cost = 3, action = function() weapons["Plazmite"].bullets = weapons["Plazmite"].bullets + 5; updateAmmoUI() end },
    { name = "Barrett Ammo x3", type = "ammo_barrett", cost = 4, action = function() weapons["Barrett M82"].bullets = weapons["Barrett M82"].bullets + 3; updateAmmoUI() end },
}


currentLevelKey = "main_door"
currentLevelConfig = nil
map = {}

levelData = {
    basement = {
    difficulty = "hard",
    maxZombies = 55,
    spawnCol = 3,
    spawnRow = 16,
    bgColor = {0.10, 0.13, 0.22},
    allowedZombies = {"zombie", "runner", "fatty", "archer", "healer", "exploder", "berserker", "acid_zombie", "crikey", "ghost"},
    spawnDelay = {1, 5},
    map = {
        {1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1},
        {1,4,0,0,0,0,1,0,0,0,0,0,1,4,0,0,0,0,1,0,0,0,0,0,1,2,0,0,4,1},
        {1,0,0,0,0,0,1,0,2,0,0,0,1,0,0,10,0,0,1,0,0,2,0,0,0,10,0,0,0,1},
        {1,1,1,3,1,1,1,1,1,1,3,1,1,1,1,1,3,1,1,1,1,1,3,1,1,1,1,3,1,1},
        {1,0,0,0,0,0,1,4,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,4,1,0,0,0,0,1},
        {1,1,1,1,0,0,1,0,0,0,0,0,1,0,0,0,0,0,1,0,0,0,0,0,1,0,0,2,0,1},
        {1,0,0,1,1,3,1,1,1,3,1,1,1,0,0,0,0,0,1,1,1,1,1,3,1,1,1,1,1,1},
        {1,8,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,1,0,0,10,0,0,0,0,0,0,4,1},
        {1,0,0,0,0,0,0,0,0,0,0,0,1,0,2,0,0,0,1,0,0,0,0,0,0,0,0,0,0,1},
        {1,1,1,1,1,1,1,1,3,1,1,1,1,1,1,1,1,1,1,1,1,1,3,1,1,1,1,3,1,1},
        {1,0,0,0,1,0,0,0,0,0,0,0,1,0,0,0,0,0,1,0,0,0,0,0,1,0,10,0,0,1},
        {1,0,4,0,1,0,0,0,0,0,0,0,0,0,0,4,0,0,0,0,0,0,0,0,1,0,4,0,0,1},
        {1,0,0,0,1,0,0,2,0,0,0,0,1,0,0,0,0,0,1,0,0,0,0,2,1,0,0,0,0,1},
        {1,1,3,1,1,1,1,1,1,1,1,1,1,1,1,3,1,1,1,1,1,1,1,1,1,1,1,3,1,1},
        {1,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,10,0,0,0,1,0,0,0,0,0,0,1},
        {1,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,10,0,0,0,1},
        {1,1,1,1,3,1,1,0,0,1,1,1,1,1,1,1,1,1,1,1,0,0,1,1,3,1,1,3,1,1},
        {1,4,0,0,0,0,1,0,0,1,4,0,0,0,0,0,0,0,4,1,0,0,1,0,0,0,0,0,4,1},
        {1,0,0,2,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,2,0,0,0,1},
        {1,0,0,0,0,0,1,0,0,1,0,0,0,0,0,0,0,0,0,1,0,0,1,0,0,0,0,10,0,1},
        {1,1,1,1,1,1,1,1,1,1,1,1,1,1,3,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1},
        {1,1,1,1,1,1,1,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,1,1,1,1,1,1,1},
        {1,4,0,0,0,0,1,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,1,0,0,0,0,4,1},
        {1,0,2,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,2,0,0,1},
        {1,0,0,0,0,0,1,1,0,0,0,0,10,0,0,0,0,0,0,0,0,0,1,1,0,0,0,0,0,1},
        {1,1,1,3,1,1,1,1,0,0,1,1,1,1,1,1,1,1,1,0,0,0,1,1,1,1,3,1,1,1},
        {1,0,0,0,0,0,1,1,0,0,1,0,0,0,0,0,0,4,1,0,0,0,1,1,0,0,0,0,0,1},
        {1,4,0,0,0,0,1,1,0,0,1,0,10,0,9,0,0,0,1,0,0,0,1,1,0,0,0,4,0,1},
        {1,0,0,0,0,0,1,1,0,0,0,0,0,0,0,0,0,0,1,0,0,0,1,1,0,0,0,0,0,1},
        {1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1}
    }
},
    main_door = {
    difficulty = "easy",
    maxZombies = 15,
    spawnCol = 2,
    spawnRow = 16,
    bgColor = {0.25, 0.35, 0.25},
    allowedZombies = {"zombie", "runner", "fatty", "healer"},
    spawnDelay = {1, 5},
    map = {
        {1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1},
        {1,4,0,0,0,0,0,0,0,0,0,0,0,1,4,0,0,0,0,4,1,2,0,0,0,0,0,0,4,1},
        {1,0,0,0,1,0,0,0,0,0,0,0,0,1,0,0,0,2,0,0,1,0,0,0,0,0,0,0,0,1},
        {1,0,0,0,1,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1},
        {1,0,0,0,1,0,0,0,0,0,0,0,2,1,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,1},
        {1,1,1,1,1,3,1,1,1,1,1,1,1,1,0,0,0,0,0,0,1,1,1,1,1,1,3,1,1,1},
        {1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1},
        {1,8,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1},
        {1,2,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,2,1},
        {1,1,1,1,1,3,1,1,1,1,1,1,1,1,0,0,0,0,0,0,1,3,1,1,1,1,1,1,1,1},
        {1,0,0,0,1,0,0,1,4,0,0,0,0,1,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,1},
        {1,0,0,0,1,0,0,1,0,0,0,0,0,1,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,1},
        {1,0,0,0,1,0,0,1,0,0,0,0,0,1,0,10,0,0,0,0,1,0,0,0,0,1,1,1,1,1},
        {1,2,0,0,1,0,0,1,0,0,0,0,0,1,0,0,0,0,0,0,1,0,0,0,0,1,0,0,4,1},
        {1,0,0,0,1,0,0,1,0,0,0,0,0,1,0,0,10,0,0,0,1,0,0,0,0,1,0,0,0,1},
        {1,0,0,0,1,1,3,1,1,1,3,1,1,1,1,1,3,5,1,1,1,2,0,0,4,1,0,0,0,1},
        {1,0,0,0,0,0,0,1,4,0,0,0,0,0,0,0,0,0,0,0,1,1,1,1,1,1,1,3,1,1},
        {1,0,4,0,0,0,4,1,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,1},
        {1,3,1,1,1,1,1,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1},
        {1,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,10,1,0,0,0,0,0,0,0,0,1},
        {1,0,0,0,0,0,4,1,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,4,1},
        {1,1,1,1,1,1,1,1,1,1,3,1,1,1,1,1,1,1,1,3,1,1,1,1,1,1,1,1,1,1},
        {6,6,6,6,6,6,6,1,4,0,0,0,0,0,0,0,0,0,0,0,0,0,1,6,6,6,6,6,6,6},
        {6,6,6,6,6,6,6,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,6,6,6,6,6,6,6},
        {6,6,6,6,6,6,6,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,6,6,6,6,6,6,6},
        {6,6,6,6,6,6,6,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,6,6,6,6,6,6,6},
        {6,6,6,6,6,6,6,1,1,1,1,1,0,0,0,0,0,0,1,1,1,1,1,6,6,6,6,6,6,6},
        {6,6,6,6,6,6,6,1,4,0,0,1,0,0,0,0,0,0,1,0,0,0,1,6,6,6,6,6,6,6},
        {6,6,6,6,6,6,6,1,0,0,0,0,0,0,0,0,0,0,0,0,0,9,1,6,6,6,6,6,6,6},
        {6,6,6,6,6,6,6,1,1,1,1,1,1,1,7,5,1,1,1,1,1,1,1,6,6,6,6,6,6,6}
    }
},
    two_floor = {
    difficulty = "medium",
    maxZombies = 35,
    spawnCol = 4,
    spawnRow = 14,
    bgColor = {0.15, 0.17, 0.25},
    allowedZombies = {"zombie", "runner", "fatty", "archer", "healer", "exploder"},
    spawnDelay = {1, 5},
    map = {
        {1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1},
        {1,4,0,0,0,0,0,0,0,1,0,0,0,1,4,0,0,2,0,4,1,2,0,0,0,0,0,0,4,1},
        {1,0,0,0,0,0,0,0,0,1,0,0,0,1,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,1},
        {1,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1},
        {1,0,0,0,0,0,0,0,0,1,0,0,2,1,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,1},
        {1,1,1,1,1,1,3,1,1,1,1,1,1,1,0,0,0,0,0,0,1,1,1,1,1,1,3,1,1,1},
        {1,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,10,0,0,0,0,0,0,0,0,0,1},
        {1,8,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1},
        {1,0,0,0,9,4,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,2,1},
        {1,1,1,1,1,1,3,1,1,1,1,1,1,1,0,0,0,0,0,0,0,0,0,0,0,1,1,3,1,1},
        {1,0,0,0,1,0,0,1,4,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,10,1,0,0,0,1},
        {1,0,0,0,1,0,0,1,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,1},
        {1,0,0,0,1,0,0,1,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,1,1,1,1,1},
        {1,2,0,0,1,0,0,1,0,0,0,0,0,1,0,0,10,0,0,0,0,0,0,0,0,1,0,0,4,1},
        {1,0,0,0,1,0,0,1,0,0,0,0,0,1,2,0,0,0,0,0,0,0,0,0,2,1,0,0,0,1},
        {1,0,0,0,1,1,3,1,1,1,3,1,1,1,1,0,0,0,0,0,1,1,1,1,1,1,1,3,1,1},
        {1,0,0,0,0,0,0,1,4,0,0,0,0,0,1,0,0,0,0,0,1,0,0,0,0,0,0,0,0,1},
        {1,0,4,0,0,0,4,1,0,0,0,0,0,0,1,1,1,1,3,1,1,0,0,0,0,0,0,0,0,1},
        {1,3,1,1,1,1,1,1,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,1},
        {1,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,10,0,0,0,0,0,0,0,0,0,1},
        {1,0,0,0,0,0,4,1,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,4,1},
        {1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1}
    }
},

    three_floor = {
    difficulty = "medium",
    maxZombies = 45,
    spawnCol = 4,
    spawnRow = 14,
    bgColor = {0.15, 0.17, 0.25},
    allowedZombies = {"zombie", "runner", "fatty", "archer", "healer", "exploder", "acid_zombie", "berserker"},
    spawnDelay = {1, 5},
    map = {
        {1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1},
        {1,4,0,0,0,1,2,0,0,0,0,0,0,1,4,0,0,2,0,4,1,2,0,0,0,0,0,0,4,1},
        {1,0,0,0,0,1,0,0,0,0,0,0,0,1,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,1},
        {1,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1},
        {1,0,0,0,0,1,0,0,0,0,0,0,2,1,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,1},
        {1,1,1,1,3,1,3,1,1,1,1,1,1,1,1,1,1,3,1,1,1,1,1,1,1,1,3,1,1,1},
        {1,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,10,0,0,0,0,0,0,0,0,0,0,1},
        {1,8,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1},
        {1,0,0,0,9,4,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,2,1},
        {1,1,1,1,1,1,3,1,1,1,1,1,3,1,0,0,0,0,0,0,1,1,1,1,1,1,1,3,1,1},
        {1,0,0,0,1,0,0,0,4,0,0,0,0,1,0,0,0,0,0,10,1,0,0,0,0,0,0,0,0,1},
        {1,0,0,0,1,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,1,0,0,0,0,1,0,0,0,1},
        {1,1,1,1,3,1,1,1,1,1,1,3,1,1,0,0,0,0,10,0,0,0,0,0,0,1,1,1,1,1},
        {1,0,0,2,0,0,0,1,0,0,0,0,0,1,0,0,0,0,0,0,1,0,0,0,0,1,0,0,4,1},
        {1,0,0,0,0,0,0,1,0,0,0,0,0,1,2,0,0,0,0,0,1,0,0,0,2,1,0,0,0,1},
        {1,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,10,1,1,1,1,1,1,1,3,1,1},
        {1,0,0,0,0,0,0,1,4,0,0,0,0,1,4,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1},
        {1,0,4,0,0,0,4,1,1,1,1,1,1,1,1,1,1,1,3,1,1,0,0,0,0,0,0,0,0,1},
        {1,3,1,1,1,1,1,1,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,1},
        {1,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,1},
        {1,0,0,0,0,0,4,1,2,0,0,0,0,0,0,0,0,0,0,0,1,2,0,0,0,0,0,0,4,1},
        {1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1}
    }
},
four_floor = {
    difficulty = "medium",
    maxZombies = 60,
    spawnCol = 4,
    spawnRow = 14,
    bgColor = {0.15, 0.17, 0.25},
    allowedZombies = {"zombie", "runner", "fatty", "archer", "healer", "exploder", "berserker", "teleporter", "summoner"},
    spawnDelay = {1, 3},
    map = {
        {1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1},
        {1,4,0,0,0,0,0,1,0,0,0,0,0,0,1,0,0,2,0,4,1,2,0,0,0,1,0,0,4,1},
        {1,0,0,0,0,0,0,1,0,0,0,0,0,0,1,0,0,0,0,0,1,0,0,0,0,1,0,0,0,1},
        {1,0,0,0,0,0,0,1,0,0,0,0,0,0,1,0,0,0,0,0,1,0,0,0,0,0,0,0,0,1},
        {1,0,0,0,0,0,0,1,0,0,0,0,0,0,1,0,0,0,0,0,1,0,0,0,0,1,0,0,0,1},
        {1,1,1,1,1,1,3,1,1,1,1,3,1,1,1,1,1,3,1,1,1,1,1,1,1,1,3,1,1,1},
        {1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,9,1,0,0,0,0,0,0,0,0,1},
        {1,8,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1},
        {1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,2,1},
        {1,1,1,1,1,1,3,1,1,1,1,3,1,1,1,3,1,1,1,1,1,1,1,3,1,1,1,3,1,1},
        {1,0,0,0,0,0,0,1,4,0,0,0,1,0,0,0,1,4,0,0,0,0,0,0,1,2,0,0,0,1},
        {1,0,0,0,0,0,0,1,0,0,0,0,1,0,0,0,1,0,0,0,0,0,0,0,1,0,0,0,0,1},
        {1,0,0,0,0,0,0,1,0,0,2,0,1,0,0,0,1,0,0,0,0,0,0,0,1,0,0,0,0,1},
        {1,0,0,0,0,0,0,1,4,0,0,0,1,0,0,0,1,2,0,0,0,4,0,0,1,0,0,0,4,1},
        {1,1,3,1,3,1,1,1,1,1,1,1,1,0,0,0,1,1,1,1,1,1,1,1,1,1,1,1,1,1},
        {1,4,0,1,0,0,4,1,0,0,0,0,1,0,0,0,1,0,0,0,1,4,0,0,0,0,0,0,0,1},
        {1,0,0,1,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1},
        {1,0,0,1,0,0,4,1,4,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,0,0,0,0,0,1},
        {1,0,0,1,0,0,0,1,1,1,3,1,1,1,1,1,1,1,3,1,1,0,0,0,0,0,0,0,0,1},
        {1,0,0,1,0,0,0,1,0,0,0,0,0,1,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,1},
        {1,4,0,1,0,0,4,1,2,0,0,0,0,1,0,0,0,0,0,2,1,2,0,0,0,0,0,0,4,1},
        {1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1}
    }
},

    admin_test = {
        difficulty = "easy",
        maxZombies = 5,
        spawnCol = 2,
        spawnRow = 16,
        bgColor = {0.3, 0.3, 0.3},
        spawnDelay = {500, 1000},
        map = {
            {0,1,2,3,4,5,6,7,8,9,10},
            {0,1,2,3,4,5,6,7,8,9,10},
            {0,1,2,3,4,5,6,7,8,9,10},
            {0,1,2,3,4,5,6,7,8,9,10},
            {0,1,2,3,4,5,6,7,8,9,10},
            {0,1,2,3,4,5,6,7,8,9,10},
            {0,1,2,3,4,5,6,7,8,9,10},
            {0,1,2,3,4,5,6,7,8,9,10},
            {0,1,2,3,4,5,6,7,8,9,10},
            {0,1,2,3,4,5,6,7,8,9,10}
    }
    }
}

function cloneMap(template)
    local copy = {}
    for row = 1, #template do
        copy[row] = {}
        for col = 1, #template[row] do
            copy[row][col] = template[row][col]
        end
    end
    return copy
end

function getLevelConfig(key)
    return levelData[key] or levelData.main_door
end

-- ========== ШИФРОВАНИЕ ==========


local function showResetWarningAndExit()
    local overlay = display.newRect(scene.view, display.contentCenterX, display.contentCenterY,
        display.actualContentWidth, display.actualContentHeight)
    overlay:setFillColor(0, 0, 0, 0.85)
    local txt = display.newText({
        parent = overlay,
        text = "СБРОС СОХРАНЕНИЙ",
        x = display.contentCenterX,
        y = display.contentCenterY - 20,
        font = native.systemFontBold,
        fontSize = 40
    })
    txt:setFillColor(1, 0.2, 0.2)
    local sub = display.newText({
        parent = overlay,
        text = "Старое сохранение удалено",
        x = display.contentCenterX,
        y = display.contentCenterY + 40,
        font = native.systemFont,
        fontSize = 20
    })
    sub:setFillColor(1, 1, 1)
    timer.performWithDelay(3000, function()
        os.exit()
    end)
end


local function updateFogAlpha()
    if not fogGroup then return end
    if not player then return end
    local maxDist = viewRadius * tileSize
    local maxAlpha = 0.7

    for row = 1, #map do
        for col = 1, #map[row] do
            local rect = fogTiles[row] and fogTiles[row][col]
            if rect then
                if explored[row] and explored[row][col] then
                    rect.targetAlpha = 0
                else
                    local cx = (col - 0.5) * tileSize
                    local cy = (row - 0.5) * tileSize
                    local dist = math.sqrt((player.x - cx)^2 + (player.y - cy)^2)
                    local t = math.min(1, dist / maxDist)
                    rect.targetAlpha = maxAlpha * t * t
                end
            end
        end
    end
    fogDirty = false
end
local function hasLineOfSight(x1, y1, x2, y2)
    local dx = x2 - x1
    local dy = y2 - y1
    local dist = math.sqrt(dx*dx + dy*dy)
    if dist == 0 then return true end

    local step = 25
    local steps = math.floor(dist / step)
    for s = 1, steps do
        local cx = x1 + dx * (s / steps)
        local cy = y1 + dy * (s / steps)
        local col = math.floor(cx / tileSize) + 1
        local row = math.floor(cy / tileSize) + 1
        if map[row] and (map[row][col] == 1 or map[row][col] == 3 or map[row][col] == 5 or map[row][col] == 7) then
    return false
end
    end
    return true
end
local function updateVisibility()
    if not player or not map then return end
    if not tileSize then return end
    -- Зомби
    for _, z in ipairs(enemies) do
        if z and z.x then
            local col = math.floor(z.x / tileSize) + 1
            local row = math.floor(z.y / tileSize) + 1
            local visible = false
            if explored[row] and explored[row][col] then
                visible = true
            else
                if hasLineOfSight(player.x, player.y, z.x, z.y) then
                    visible = true
                end
            end
            if z.rect then z.rect.alpha = visible and 1 or 0 end
            if z.hpBg then z.hpBg.alpha = visible and 1 or 0 end
            if z.hpFill then z.hpFill.alpha = visible and 1 or 0 end
            if z.hpText then z.hpText.alpha = visible and 1 or 0 end
            if z.nameText then z.nameText.alpha = visible and 1 or 0 end
        end
    end

    -- Сундуки
    for _, chest in ipairs(chests) do
        if chest.group and not chest.isOpened then
            local col = math.floor(chest.x / tileSize) + 1
            local row = math.floor(chest.y / tileSize) + 1
            local visible = false
            if explored[row] and explored[row][col] then
                visible = true
            else
                if hasLineOfSight(player.x, player.y, chest.x, chest.y) then
                    visible = true
                end
            end
            chest.group.alpha = visible and 1 or 0
        end
    end

    -- Лут (предметы)
    for _, icon in ipairs(minimapLootIcons) do
        if icon.lootRef then
            local col = math.floor(icon.lootRef.x / tileSize) + 1
            local row = math.floor(icon.lootRef.y / tileSize) + 1
            local visible = false
            if explored[row] and explored[row][col] then
                visible = true
            else
                if hasLineOfSight(player.x, player.y, icon.lootRef.x, icon.lootRef.y) then
                    visible = true
                end
            end
            icon.lootRef.alpha = visible and 1 or 0
            if icon.lootRef.tempText then
                icon.lootRef.tempText.alpha = visible and 1 or 0
            end
        end
    end

    -- Трупы
    for _, corpse in ipairs(corpses) do
        if corpse and corpse.x and not corpse.isLooted then
            local col = math.floor(corpse.x / tileSize) + 1
            local row = math.floor(corpse.y / tileSize) + 1
            local visible = false
            if explored[row] and explored[row][col] then
                visible = true
            else
                if hasLineOfSight(player.x, player.y, corpse.x, corpse.y) then
                    visible = true
                end
            end
            if corpse.rect then corpse.rect.alpha = visible and 0.8 or 0 end
            -- также можно скрыть самого corpse, но он группа, у него нет alpha, только у rect.
        end
    end

    -- Лифт (если есть)
    if elevator and elevator.group then
        local col = math.floor(elevator.x / tileSize) + 1
        local row = math.floor(elevator.y / tileSize) + 1
        local visible = false
        if explored[row] and explored[row][col] then
            visible = true
        else
            if hasLineOfSight(player.x, player.y, elevator.x, elevator.y) then
                visible = true
            end
        end
        elevator.group.alpha = visible and 1 or 0
    end
        -- Газовые баллоны
    for _, canister in ipairs(gasCanisters) do
        if canister and canister.x and not canister.exploded then
            local col = math.floor(canister.x / tileSize) + 1
            local row = math.floor(canister.y / tileSize) + 1
            local visible = false
            if explored[row] and explored[row][col] then
                visible = true
            else
                if hasLineOfSight(player.x, player.y, canister.x, canister.y) then
                    visible = true
                end
            end
            canister.alpha = visible and 1 or 0
            if canister.hpBg then canister.hpBg.alpha = visible and (canister.isDamaged and 1 or 0) or 0 end
            if canister.hpFill then canister.hpFill.alpha = visible and (canister.isDamaged and 1 or 0) or 0 end
            if canister.hpText then canister.hpText.alpha = visible and (canister.isDamaged and 1 or 0) or 0 end
        end
    end
    -- NPC (трейдер)
    for _, npc in ipairs(npcs) do
        if npc and npc.x then
            local col = math.floor(npc.x / tileSize) + 1
            local row = math.floor(npc.y / tileSize) + 1
            local visible = false
            if explored[row] and explored[row][col] then
                visible = true
            else
                if hasLineOfSight(player.x, player.y, npc.x, npc.y) then
                    visible = true
                end
            end
            if npc.body then npc.body.alpha = visible and 1 or 0 end
            if npc.nameText then npc.nameText.alpha = visible and 1 or 0 end
            if npc.hpBg then npc.hpBg.alpha = visible and 1 or 0 end
            if npc.hpFill then npc.hpFill.alpha = visible and 1 or 0 end
            if npc.hpText then npc.hpText.alpha = visible and 1 or 0 end
        end
    end
end
local function updateExplored()
    if not player or not map then return end

    -- ЕСЛИ АКТИВНО ПРОСВЕЩЕНИЕ — НЕ ОБНОВЛЯЕМ
    if enlightenmentActive then
        return
    end

    -- Сбрасываем все клетки
    for row = 1, #map do
        for col = 1, #map[row] do
            explored[row][col] = false
        end
    end

    local playerCol = math.floor((player.x + tileSize/2) / tileSize)
    local playerRow = math.floor((player.y + tileSize/2) / tileSize)
    playerCol = math.max(1, math.min(#map[1], playerCol))
    playerRow = math.max(1, math.min(#map, playerRow))

    for r = math.max(1, playerRow - viewRadius), math.min(#map, playerRow + viewRadius) do
        for c = math.max(1, playerCol - viewRadius), math.min(#map[1], playerCol + viewRadius) do
            if (r - playerRow)^2 + (c - playerCol)^2 <= viewRadius^2 then
                local cellX = (c - 1) * tileSize + tileSize/2
                local cellY = (r - 1) * tileSize + tileSize/2
                if hasLineOfSight(player.x, player.y, cellX, cellY) then
                    explored[r][c] = true
                end
            end
        end
    end
    fogDirty = true
end
local function toggleDoor(door)
    updateExplored()
    if door.isOpen then
        -- Закрываем
        door.group.alpha = 1.0
        door.hitBox.isSensor = false
        door.hitBox.type = "door_phys"
        door.isOpen = false
        map[door.row][door.col] = door.tileType
    else
        -- Открываем
        door.group.alpha = 0.2
        door.hitBox.isSensor = true
        door.hitBox.type = "door_phys_open"
        door.isOpen = true
        map[door.row][door.col] = 0
    end

    -- Синхронизация парной двери без рекурсии
    if door.pairedDoor then
        local paired = door.pairedDoor
        if paired.isOpen ~= door.isOpen then
            if door.isOpen then
                paired.group.alpha = 0.2
                paired.hitBox.isSensor = true
                paired.hitBox.type = "door_phys_open"
                paired.isOpen = true
                map[paired.row][paired.col] = 0
            else
                paired.group.alpha = 1.0
                paired.hitBox.isSensor = false
                paired.hitBox.type = "door_phys"
                paired.isOpen = false
                map[paired.row][paired.col] = paired.tileType
            end
        end
    end
end

local function cancelZombieTimers(z)
    if not z then return end
    if z.doubleAttackTimer then
        timer.cancel(z.doubleAttackTimer)
        z.doubleAttackTimer = nil
    end
    if z.stunnedTimer then
        timer.cancel(z.stunnedTimer)
        z.stunnedTimer = nil
    end
    -- Если есть другие таймеры, добавь их сюда (например, задержки атаки)
end

local function cancelAllTimers()
        if enlightenmentTimer then
        timer.cancel(enlightenmentTimer)
        enlightenmentTimer = nil
    end
    enlightenmentActive = false
    for _, t in ipairs(activeTimers) do
        if t then timer.cancel(t) end
    end
    activeTimers = {}
    if stats.currentWeapon and stats.currentWeapon.reloadTimer then
        timer.cancel(stats.currentWeapon.reloadTimer)
        stats.currentWeapon.reloadTimer = nil
        stats.currentWeapon.isReloading = false
        stats.currentWeapon.reloadStartTime = nil
    end
    if fireRateTimer then
        timer.cancel(fireRateTimer)
        fireRateTimer = nil
    end
    fireRateMultiplier = 1.0
    reloadSpeedMultiplier = 1.0
    rapidEndTime = nil
    if rapidIndicator then rapidIndicator.alpha = 0 end
    cancelBurst()

    -- Отменяем таймеры всех живых зомби
    for _, z in ipairs(enemies) do
        cancelZombieTimers(z)
    end
end

local function safeRemove(obj)
    if obj and obj.removeSelf then
        -- Удаляем из списка донорских снарядов
        if obj.type == "donor_chunk" then
            for i = #donorChunks, 1, -1 do
                if donorChunks[i] == obj then
                    table.remove(donorChunks, i)
                    break
                end
            end
        end
        if obj.removeTimer then
            timer.cancel(obj.removeTimer)
            obj.removeTimer = nil
        end
        pcall(function() obj:removeSelf() end)
    end
end

local function showWarning(txt, time)
    if warning then safeRemove(warning) end
    warning = display.newText({
        parent = ui,
        text = txt,
        x = display.contentCenterX,
        y = display.contentCenterY - 150,
        font = native.systemFontBold,
        fontSize = 22
    })
    warning:setFillColor(1, 0, 0)
    transition.to(warning, {
        alpha = 0,
        time = time or 2000,
        onComplete = function() safeRemove(warning) end
    })
end
-- Отмена текущего обыска (трупа или сундука)
local function cancelChestLooting(showMsg)
    if chestLootingActive then
        -- Отменяем переход анимации
        if chestProgressTransition then
            transition.cancel(chestProgressTransition)
            chestProgressTransition = nil
        end
        -- Отменяем таймер проверки движения
        if chestMovementTimer then
            timer.cancel(chestMovementTimer)
            chestMovementTimer = nil
        end
        -- Удаляем объекты UI
        safeRemove(chestProgressBar)
        safeRemove(chestProgressFill)
        safeRemove(lootingProgressText)
        chestProgressBar = nil
        chestProgressFill = nil
        lootingProgressText = nil
        chestLootingActive = false
        activeChest = nil
        chestLootingStartX = nil
        chestLootingStartY = nil
        if showMsg then
            showWarning("Обыск прерван", 1000)
        end
    end
end

local function bloodParticles(x, y, isCrit, mainGroup)
    local count = isCrit and 15 or 8
    if isCrit == "player" then count = 5 end
    for i = 1, count do
        local size = math.random(2, isCrit and 6 or 4)
        if isCrit == "player" then size = math.random(2,3) end
        local particle = display.newCircle(mainGroup, x, y, size)
        local r = 0.5 + math.random() * 0.5
        particle:setFillColor(r, 0, 0)
        local angle = math.random() * math.pi * 2
        local dist = math.random(30, isCrit and 80 or 50)
        local dx = math.cos(angle) * dist
        local dy = math.sin(angle) * dist
        transition.to(particle, {
            x = x + dx, y = y + dy, alpha = 0, rotation = math.random(360),
            time = math.random(400, 600),
            onComplete = function() safeRemove(particle) end
        })
    end
end

local function bloodPoolParticles(x, y, isCrit, mainGroup)
    local count = isCrit and 30 or 15
    for i = 1, count do
        local offsetX = x + math.random(-25, 25)
        local offsetY = y + math.random(-25, 25)
        local size = math.random(3, isCrit and 8 or 5)
        local drop = display.newCircle(mainGroup, offsetX, offsetY, size)
        local r = 0.5 + math.random() * 0.3
        local g = math.random(0, 10)/100
        local b = math.random(0, 5)/100
        drop:setFillColor(r, g, b, 0.8)
        drop.startR = r
        drop.startG = g
        drop.startB = b
        drop.startAlpha = 0.8
        transition.to(drop, {
            alpha = 0.2, time = 3000, delay = math.random(0, 500),
            onUpdate = function()
                local progress = 1 - (drop.alpha / drop.startAlpha)
                drop:setFillColor(
                    drop.startR - progress * 0.3,
                    drop.startG + progress * 0.5,
                    drop.startB + progress * 0.3,
                    drop.alpha
                )
            end,
            onComplete = function() safeRemove(drop) end
        })
        transition.to(drop, {
            y = offsetY + math.random(5, 15),
            x = offsetX + math.random(-5, 5),
            time = 500, delay = math.random(0, 200)
        })
    end
end

local function showDamageText(zombie, dmgVal, isCrit, mainGroup, isKill, isOneShot)
    local textStr = tostring(math.floor(dmgVal))
    if isKill then
        textStr = isOneShot and (math.floor(dmgVal) .. "!") or tostring(math.floor(dmgVal))
    end
    local txt = display.newText(damageTextGroup, textStr, zombie.x, zombie.y - 40, native.systemFontBold, isCrit and 24 or 18)
    if isKill then
        if isOneShot then
            txt:setFillColor(0.5, 0, 0)
        else
            txt:setFillColor(1, 0, 0)
        end
    else
        txt:setFillColor(isCrit and 1 or 1, isCrit and 0.8 or 1, isCrit and 0 or 1)
    end
    transition.to(txt, {y = zombie.y - 80, alpha = 0, time = 600, onComplete = function() safeRemove(txt) end})
end

local function explosionParticles(x, y, mainGroup)
    for i = 1, 10 do
        local particle = display.newCircle(mainGroup, x, y, math.random(3,6))
        particle:setFillColor(1, math.random(0.3,0.8), 0)
        local angle = math.random() * math.pi * 2
        local speed = math.random(2,5)
        local dx = math.cos(angle) * 100 * speed
        local dy = math.sin(angle) * 100 * speed
        transition.to(particle, {
            x = x + dx, y = y + dy, alpha = 0,
            time = 800,
            onComplete = function() safeRemove(particle) end
        })
    end
end

local function spawnLoot(x, y)
    local r = math.random(1,100)
    local cumulative = 0
    for key, data in pairs(lootTypes) do
        cumulative = cumulative + data.chance
        if r <= cumulative then
            local item = display.newRect(mainGroup, x, y, 20, 20)
            item:setFillColor(unpack(data.color))
            item.type = "loot"
            physics.addBody(item, "static", { isSensor = true, radius = 30 })

            local val1 = math.random(data.min, data.max)
            local val2 = math.random(data.min, data.max)
            local finalVal = math.min(val1, val2)

            item.lootData = {
                value = finalVal,
                weapon = data.weapon,
                label = data.label,
                color = data.color
            }

            local txt = display.newText(mainGroup, data.label:sub(1,1), x, y, native.systemFontBold, 12)
            txt:setFillColor(0,0,0)
            item.tempText = txt

            local lx = (x / mapWidth) * minimapSize
            local ly = (y / mapHeight) * minimapSize
            local icon = display.newCircle(minimapGroup, 10 + lx, 10 + ly, 2)
            icon:setFillColor(0, 0, 1)
            icon.lootRef = item
            item.minimapIcon = icon
            table.insert(minimapLootIcons, icon)

            transition.from(item, { time = 300, xScale = 0.1, yScale = 0.1 })
            return true
        end
    end
    return false
end

local function die()
    if isDead then return end
    if traderMenuActive then
        closeTraderMenu()
    end
    isDead = true
    isShooting = false
    cancelAllTimers()
    if chestLootingActive then
        cancelChestLooting(false)
    end

    -- ===== Добавляем чёрный экран, чтобы скрыть артефакты =====
    local blackOverlay = display.newRect(scene.view, display.contentCenterX, display.contentCenterY,
        display.actualContentWidth * 2, display.actualContentHeight * 2)
    blackOverlay:setFillColor(0, 0, 0)
    blackOverlay.alpha = 0
    transition.to(blackOverlay, { time = 500, alpha = 1 })
    -- =========================================================

    transition.to(mainGroup, { time = 1500, alpha = 0 })
    transition.to(ui, { time = 1500, alpha = 0, onComplete = function()
        local dtxt = display.newText({
            parent = scene.view,
            text = "ВЫ УМЕРЛИ",
            x = display.contentCenterX,
            y = display.contentCenterY,
            font = native.systemFontBold,
            fontSize = 50
        })
        dtxt:setFillColor(1,0,0)
        dtxt.alpha = 0
        transition.to(dtxt, { time = 1000, alpha = 1, onComplete = function()
            timer.performWithDelay(2000, function()
                composer.removeScene("game")
                composer.gotoScene("levels", { effect = "slideLeft", time = 500 })
            end)
        end})
    end})
end

-- Ссылки на элементы статистики (будут установлены в startLevel)
local statsBrainValue

local function killZombie(z, isOneShot)
    killsCount = killsCount + 1
    if statsKillsValue then
        statsKillsValue.text = tostring(killsCount) .. "/" .. tostring(levelMaxZombies)
    end

    local pieces = 0
    local r = math.random(1, 100)
    if r <= 15 then pieces = 1
    elseif r <= 25 then pieces = 2
    elseif r <= 31 then pieces = 3
    end
    z.brainLoot = pieces

    bloodPoolParticles(z.x, z.y, "enemy", mainGroup)

    -- БАГ 6: взрыв exploder'а может убить игрока – после урона проверяем смерть и выходим
    if z.zombieType == "exploder" then
                -- Проверка газовых баллонов в радиусе взрыва
        for _, canister in ipairs(gasCanisters) do
            if canister and not canister.exploded then
                local d = math.sqrt((canister.x - z.x)^2 + (canister.y - z.y)^2)
                if d < 100 then  -- если баллон в радиусе взрыва
                    damageGasCanister(canister, 30)
                end
            end
        end
        explosionParticles(z.x, z.y, mainGroup)
        local distToPlayer = math.sqrt((player.x - z.x)^2 + (player.y - z.y)^2)
        -- Тряска камеры (mainGroup)
local origX, origY = mainGroup.x, mainGroup.y
for i=1, 5 do
    timer.performWithDelay(i*30, function()
        mainGroup.x = origX + math.random(-4, 4)
        mainGroup.y = origY + math.random(-4, 4)
    end)
end
timer.performWithDelay(200, function()
    mainGroup.x, mainGroup.y = origX, origY
end)
        if distToPlayer < 100 then
            hp = hp - 30
            showDamageFlash()
            bloodParticles(player.x, player.y, "player", mainGroup)
            showWarning("ВЗРЫВ!", 1000)
            updateHealthBar()
            if hp <= 0 then
                die()
                return   -- НЕ продолжаем обрабатывать этого зомби, так как игрок мёртв
            end
        end
        -- Урон по другим зомби от взрыва
        for _, other in ipairs(enemies) do
            if other ~= z then
                local d = math.sqrt((other.x - z.x)^2 + (other.y - z.y)^2)
                if d < 50 then
                    local dmg = 15
                    if other.hp - dmg <= 0 then
                        killZombie(other, false)
                    else
                        other.hp = other.hp - dmg
                        local ratio = other.hp / other.maxHp
                        if other.hpFill then
                            other.hpFill.width = 50 * ratio
                            other.hpFill.x = other.x - 25 + (other.hpFill.width/2)
                        end
                        if other.hpText then
                            other.hpText.text = math.floor(other.hp) .. "/" .. other.maxHp
                            other.hpText.x = other.x
                        end
                        showDamageText(other, dmg, true, mainGroup, false, false)
                    end
                end
            end
        end
    end

    if z.zombieType == "teleporter" and z.doubleAttackTimer then
        timer.cancel(z.doubleAttackTimer)
        z.doubleAttackTimer = nil
    end

    safeRemove(z.hpBg)
    safeRemove(z.hpFill)
    safeRemove(z.hpText)
    safeRemove(z.nameText)

    for i = #minimapZombieIcons, 1, -1 do
        if minimapZombieIcons[i].zombieRef == z then
            safeRemove(minimapZombieIcons[i])
            table.remove(minimapZombieIcons, i)
            break
        end
    end

    for i = #enemies, 1, -1 do
        if enemies[i] == z then
            table.remove(enemies, i)
            break
        end
    end

    z.type = "corpse"
    z.isLooted = false
    
    z.isSensor = true
    z.bodyType = "static"
    z:setLinearVelocity(0, 0)
    
    transition.to(z.rect, { time = 300, alpha = 0.8 })
    z.rect:setFillColor(0.6, 0.3, 0.3)
    
    table.insert(corpses, z)

    if checkLevelComplete then
        checkLevelComplete()
    end
end

local function findNearestCorpse(maxDist)
    maxDist = maxDist or 200  -- по умолчанию 200 пикселей
    if not player then return nil end
    local nearest = nil
    local minDist = maxDist
    for _, c in ipairs(corpses) do
        if c and c.x and not c.isLooted then
            local dx = player.x - c.x
            local dy = player.y - c.y
            local dist = math.sqrt(dx*dx + dy*dy)
            if dist < minDist then
                minDist = dist
                nearest = c
                if dist < 30 then break end  -- если совсем рядом, дальше не ищем
            end
        end
    end
    return nearest
end

local function startCorpseLooting(corpse)
    if not corpse or corpse.isLooted or chestLootingActive then return end
    local dx = player.x - corpse.x
    local dy = player.y - corpse.y
    if dx*dx + dy*dy > 100*100 then
        showWarning("Подойдите ближе к трупу", 1000)
        return
    end

    -- Сначала отменяем любой текущий обыск
    cancelChestLooting(false)

    chestLootingActive = true
    activeChest = nil
    chestLootingStartX = player.x
    chestLootingStartY = player.y

    local duration = math.random(4, 11) / 10

    local barWidth = 300
    local barHeight = 30
    chestProgressBar = display.newRoundedRect(ui, display.contentCenterX - barWidth/2, display.contentCenterY - 50, barWidth, barHeight, 10)
    chestProgressBar:setFillColor(0.2, 0.2, 0.2, 0.8)
    chestProgressBar.strokeWidth = 2
    chestProgressBar:setStrokeColor(1, 1, 1)
    chestProgressBar.anchorX = 0

    chestProgressFill = display.newRoundedRect(ui, display.contentCenterX - barWidth/2, display.contentCenterY - 50, 0, barHeight, 10)
    chestProgressFill:setFillColor(1, 1, 1)
    chestProgressFill.anchorX = 0

    lootingProgressText = display.newText({
        parent = ui,
        text = "Обыск трупа...",
        x = display.contentCenterX,
        y = display.contentCenterY - 90,
        font = native.systemFontBold,
        fontSize = 18
    })
    lootingProgressText:setFillColor(1, 1, 1)

    local function checkMovement()
        if not chestLootingActive then return true end
        local dx = player.x - chestLootingStartX
        local dy = player.y - chestLootingStartY
        local distMoved = math.sqrt(dx*dx + dy*dy)
        if distMoved > 5 then
            cancelChestLooting(true)
            return false
        end
        return true
    end

    -- Запускаем таймер проверки движения (глобальный)
    if chestMovementTimer then timer.cancel(chestMovementTimer) end
    chestMovementTimer = timer.performWithDelay(100, function()
        if not chestLootingActive then
            if chestMovementTimer then timer.cancel(chestMovementTimer); chestMovementTimer = nil end
            return
        end
        if not checkMovement() then
            if chestMovementTimer then timer.cancel(chestMovementTimer); chestMovementTimer = nil end
            return
        end
    end, 0)

    -- Запускаем анимацию прогресса, сохраняем переход в глобальную переменную
    chestProgressTransition = transition.to(chestProgressFill, {
        width = barWidth,
        time = duration * 1000,
        onComplete = function()
            if not chestLootingActive then return end
            if not checkMovement() then return end

            if chestMovementTimer then timer.cancel(chestMovementTimer); chestMovementTimer = nil end

            chestProgressFill:setFillColor(0, 1, 0)
            timer.performWithDelay(300, function()
                if not corpse or corpse.isLooted or not chestLootingActive then
                    cancelChestLooting(false)
                    return
                end

                local lootSpawned = spawnLoot(corpse.x, corpse.y)

                if not lootSpawned then
                    local noLootText = display.newText(damageTextGroup, "Ничего ценного", corpse.x, corpse.y - 60, native.systemFontBold, 20)
                    noLootText:setFillColor(0.8, 0.8, 0.8)
                    transition.to(noLootText, { time = 1500, y = noLootText.y - 40, alpha = 0, onComplete = function() safeRemove(noLootText) end })
                end

                if corpse.brainLoot and corpse.brainLoot > 0 then
                    brainPieces = brainPieces + corpse.brainLoot
                    updateBrainDisplay()
                    save.savePlayerData(brainPieces)
                    if statsBrainValue then
                        statsBrainValue.text = tostring(brainPieces)
                    end

                    local brainMsg = display.newText({
                        parent = damageTextGroup,
                        text = "+" .. corpse.brainLoot .. " 🧠 МОЗГ!",
                        x = corpse.x,
                        y = corpse.y - 100,
                        font = native.systemFontBold,
                        fontSize = 24
                    })
                    brainMsg:setFillColor(1, 0.8, 0.6)
                    transition.to(brainMsg, {
                        y = corpse.y - 150,
                        alpha = 0,
                        time = 1500,
                        onComplete = function() safeRemove(brainMsg) end
                    })
                    transition.from(brainMsg, { time = 300, xScale = 0.5, yScale = 0.5 })
                end

                corpse.isLooted = true

                transition.to(corpse.rect, { time = 800, alpha = 0 })
                transition.to(corpse, { time = 800, alpha = 0, onComplete = function()
                    for i = #corpses, 1, -1 do
                        if corpses[i] == corpse then
                            table.remove(corpses, i)
                            break
                        end
                    end
                    safeRemove(corpse)
                end})

                cancelChestLooting(false)
            end)
        end
    })
end
-- Функция для красной вспышки при уроне
local function showDamageFlash()
    -- Отменяем предыдущий таймер
    if damageFlashTimer then
        timer.cancel(damageFlashTimer)
        damageFlashTimer = nil
    end
    
    -- Удаляем старый оверлей
    if damageFlashOverlay then
        damageFlashOverlay:removeSelf()
        damageFlashOverlay = nil
    end
    
    -- Создаём новый
    damageFlashOverlay = display.newRect(ui, display.contentCenterX, display.contentCenterY,
        display.actualContentWidth * 1.5, display.actualContentHeight * 1.5)
    damageFlashOverlay:setFillColor(1, 0, 0, 0)
    damageFlashOverlay:toFront()
    
    -- Появляется и исчезает
    transition.to(damageFlashOverlay, {
        alpha = 0.15,
        time = 50,
        onComplete = function()
            transition.to(damageFlashOverlay, {
                alpha = 0,
                time = 300,
                onComplete = function()
                    if damageFlashOverlay then
                        damageFlashOverlay:removeSelf()
                        damageFlashOverlay = nil
                    end
                end
            })
        end
    })
end
local function breakDoor(doorHitBox)
    if not doorHitBox or not doorHitBox.doorGroup then return end
    display.remove(doorHitBox.shadow)
    for i, d in ipairs(doors) do
        if d.hitBox == doorHitBox then
            table.remove(doors, i)
            break
        end
    end
    map[doorHitBox.row][doorHitBox.col] = 0
    if doorHitBox.doorGroup and doorHitBox.doorGroup.removeSelf then
        doorHitBox.doorGroup:removeSelf()
    end
    if doorHitBox.removeSelf then
        doorHitBox:removeSelf()
    end
end
    -- Создание газового баллона
local function createGasCanister(x, y, row, col)
    local group = display.newGroup()
    mainGroup:insert(group)
    group.x, group.y = x, y
    group.y_sort = y
    group.type = "gas_canister"
    
    -- Основной корпус (продолговатый красный)
    local body = display.newRoundedRect(group, 0, 0, 30, 50, 6)
    body:setFillColor(0.9, 0.1, 0.1)  -- красный
    body.strokeWidth = 2
    body:setStrokeColor(0.6, 0, 0)
    group.body = body
    
    -- Верхняя часть (горловина)
    local neck = display.newRect(group, 0, -30, 12, 12)
    neck:setFillColor(0.3, 0.3, 0.3)
    group.neck = neck
    
    -- Полоска-индикатор (желтая)
    local stripe = display.newRect(group, 0, 0, 20, 4)
    stripe:setFillColor(1, 0.8, 0)
    group.stripe = stripe
    
    -- Полоска здоровья (изначально скрыта)
    local hpBg = display.newRoundedRect(mainGroup, x, y - 45, 40, 6, 2)
    hpBg:setFillColor(0, 0, 0, 0.5)
    hpBg.alpha = 0
    group.hpBg = hpBg
    
    local hpFill = display.newRoundedRect(mainGroup, x - 20, y - 45, 40, 6, 2)
    hpFill:setFillColor(0, 1, 0, 0.8)
    hpFill.anchorX = 0
    hpFill.alpha = 0
    group.hpFill = hpFill
    
    local hpText = display.newText(mainGroup, "75/75", x, y - 45, native.systemFontBold, 9)
    hpText:setFillColor(1, 1, 1)
    hpText.alpha = 0
    group.hpText = hpText
    
    -- Физика
    physics.addBody(group, "static", { radius = 25, isSensor = false })
    group.isFixedRotation = true
    
    -- Данные баллона
    group.maxHp = gasCanisterTypes.base.hp
    group.hp = gasCanisterTypes.base.hp
    group.isDamaged = false  -- флаг, был ли нанесён урон
    group.row = row
    group.col = col
    group.exploded = false
    group.burnTimer = nil
    
    -- Иконка на миникарте
    local wx = (x / mapWidth) * minimapSize
    local wy = (y / mapHeight) * minimapSize
    local icon = display.newCircle(minimapGroup, 10 + wx, 10 + wy, 3)
    icon:setFillColor(1, 0.2, 0.1)
    icon.canisterRef = group
    table.insert(gasCanisterIcons, icon)
    
    table.insert(gasCanisters, group)
    return group
end

-- Обновление полоски здоровья баллона
local function updateCanisterHealth(canister)
    if not canister or not canister.hpBg then return end
    
    local ratio = math.max(0, canister.hp / canister.maxHp)
    
    -- Если урон был нанесён, показываем полоску
    if canister.isDamaged then
        canister.hpBg.alpha = 1
        canister.hpFill.alpha = 1
        canister.hpText.alpha = 1
        
        canister.hpFill.width = 40 * ratio
        canister.hpFill:setFillColor(ratio > 0.5 and 0 or 1, ratio > 0.5 and 1 or 0.5, 0)
        
        -- Позиционируем элементы (они привязаны к mainGroup, а не к группе баллона)
        canister.hpBg.x, canister.hpBg.y = canister.x, canister.y - 45
        canister.hpFill.x, canister.hpFill.y = canister.x - 20, canister.y - 45
        canister.hpText.x, canister.hpText.y = canister.x, canister.y - 45
        canister.hpText.text = math.floor(canister.hp) .. "/" .. canister.maxHp
    end
end

-- Взрыв газового баллона
local function explodeGasCanister(canister)
    if not canister or canister.exploded then return end
    canister.exploded = true
    
    local x, y = canister.x, canister.y
    local config = gasCanisterTypes.base
    
    -- Эффект взрыва как от гранаты
    local blast = display.newCircle(mainGroup, x, y, 5)
    blast:setFillColor(1, 0.4, 0, 0.9)
    transition.to(blast, {
        scaleX = 3, scaleY = 3, alpha = 0, time = 250,
        onComplete = function() safeRemove(blast) end
    })
    
    -- Огненные частицы
    for i = 1, 40 do
        local particle = display.newCircle(mainGroup, x, y, math.random(2, 6))
        particle:setFillColor(1, math.random(0.3, 0.8), math.random(0, 0.3))
        local angle = math.random() * math.pi * 2
        local speed = math.random(3, 8)
        local dx = math.cos(angle) * 100 * speed
        local dy = math.sin(angle) * 100 * speed
        transition.to(particle, {
            x = x + dx, y = y + dy, alpha = 0,
            time = 800 + math.random(200),
            onComplete = function() safeRemove(particle) end
        })
    end
    
    -- Тряска камеры
    local origX, origY = mainGroup.x, mainGroup.y
    for i = 1, 6 do
        timer.performWithDelay(i * 25, function()
            mainGroup.x = origX + math.random(-6, 6)
            mainGroup.y = origY + math.random(-6, 6)
        end)
    end
    timer.performWithDelay(200, function()
        mainGroup.x, mainGroup.y = origX, origY
    end)
    
    -- Урон зомби в радиусе 300
    local radius = config.explosionRadius
    for i = #enemies, 1, -1 do
        local z = enemies[i]
        if z and z.x then
            local dx = z.x - x
            local dy = z.y - y
            local dist = math.sqrt(dx*dx + dy*dy)
            if dist <= radius then
                local t = dist / radius
                local damage = math.floor(config.maxDamage * (1 - t) + config.minDamage * t)
                
                if z.hp - damage <= 0 then
                    killZombie(z)
                else
                    z.hp = z.hp - damage
                    local ratio = z.hp / z.maxHp
                    if z.hpFill then
                        z.hpFill.width = 50 * ratio
                    end
                    if z.hpText then
                        z.hpText.text = math.floor(z.hp) .. "/" .. z.maxHp
                    end
                    showDamageText(z, damage, false, mainGroup)
                end
                
                -- Поджигание зомби
                if z.hp > 0 then
                    z.isBurning = true
                    z.burnEndTime = system.getTimer() + config.burnDuration
                    if z.rect then
                        z.rect:setFillColor(1, 0.4, 0)
                    end
                end
            end
        end
    end
    
    -- Урон игроку в радиусе 150
    if player and not isDead then
        local dx = player.x - x
        local dy = player.y - y
        local dist = math.sqrt(dx*dx + dy*dy)
        local playerRadius = 150
        if dist <= playerRadius then
            local t = dist / playerRadius
            local damage = math.floor(config.playerDamageMax * (1 - t) + config.playerDamageMin * t)
            if damage > 0 then
                hp = hp - damage
                showDamageFlash()
                bloodParticles(player.x, player.y, "player", mainGroup)
                showWarning("ВЗРЫВ БАЛЛОНА!", 1000)
                updateHealthBar()
                if hp <= 0 then die() end
            end
        end
    end
    
    -- Ломаем двери в радиусе 450
    for i = #doors, 1, -1 do
        local door = doors[i]
        if door and door.hitBox and door.hitBox.hp and door.x and door.y then
            local dx = door.x - x
            local dy = door.y - y
            local dist = math.sqrt(dx*dx + dy*dy)
            if dist <= config.doorBreakRadius then
                breakDoor(door.hitBox)
            end
        end
    end
    
    -- Удаляем баллон
    safeRemove(canister.hpBg)
    safeRemove(canister.hpFill)
    safeRemove(canister.hpText)
    
    for i, icon in ipairs(gasCanisterIcons) do
        if icon.canisterRef == canister then
            safeRemove(icon)
            table.remove(gasCanisterIcons, i)
            break
        end
    end
    
    -- Убираем из списка
    for i, c in ipairs(gasCanisters) do
        if c == canister then
            table.remove(gasCanisters, i)
            break
        end
    end
    
    safeRemove(canister)
end

-- Нанесение урона газовому баллону
local function damageGasCanister(canister, damage)
    if not canister or canister.exploded then return end
    
    canister.isDamaged = true
    canister.hp = canister.hp - damage
    
    updateCanisterHealth(canister)
    
    if canister.hp <= 0 then
        explodeGasCanister(canister)
    else
        -- Визуальный эффект при попадании
        spawnHitSparks(canister.x, canister.y, 0)
    end
end

-- Обработка горения зомби (добавить в onEnterFrame)
local function updateBurningZombies()
    local now = system.getTimer()
    for _, z in ipairs(enemies) do
        if z.isBurning then
            if now >= z.burnEndTime then
                z.isBurning = false
                if z.rect and z.baseColor then
                    z.rect:setFillColor(unpack(z.baseColor))
                end
            elseif now % 1000 < 50 then  -- примерно раз в секунду
                z.hp = z.hp - 10
                local ratio = z.hp / z.maxHp
                if z.hpFill then
                    z.hpFill.width = 50 * ratio
                end
                if z.hpText then
                    z.hpText.text = math.floor(z.hp) .. "/" .. z.maxHp
                end
                showDamageText(z, 10, false, mainGroup)
                if z.hp <= 0 then
                    killZombie(z)
                end
            end
        end
    end
end
local function damageDoor(doorHitBox, bullet)
    local damage = bullet / 4
    if doorHitBox and doorHitBox.hp then
        doorHitBox.hp = doorHitBox.hp - damage
        if doorHitBox.hp <= 0 then
            showDamageText(doorHitBox, damage, false, mainGroup, true)
            breakDoor(doorHitBox)
        else
            showDamageText(doorHitBox, damage, false, mainGroup, false)
        end
    end
end

local function grenadeExplosion(x, y, maxDamage, radius, minDamage)
    local blast = display.newCircle(mainGroup, x, y, 5)
    blast:setFillColor(1, 0.6, 0, 0.9)
    transition.to(blast, {
        scaleX = 2.5, scaleY = 2.5, alpha = 0, time = 200,
        onComplete = function() safeRemove(blast) end
    })
    -- Тряска камеры (mainGroup)
local origX, origY = mainGroup.x, mainGroup.y
for i=1, 5 do
    timer.performWithDelay(i*30, function()
        mainGroup.x = origX + math.random(-4, 4)
        mainGroup.y = origY + math.random(-4, 4)
    end)
end
timer.performWithDelay(200, function()
    mainGroup.x, mainGroup.y = origX, origY
end)
    for i = 1, 30 do
        local particle = display.newCircle(mainGroup, x, y, math.random(2,5))
        particle:setFillColor(1, math.random(0.3,0.8), 0)
        local angle = math.random() * math.pi * 2
        local speed = math.random(2,6)
        local dx = math.cos(angle) * 100 * speed
        local dy = math.sin(angle) * 100 * speed
        transition.to(particle, {
            x = x + dx, y = y + dy, alpha = 0,
            time = 800,
            onComplete = function() safeRemove(particle) end
        })
    end

    -- Урон зомби
    for i = #enemies, 1, -1 do
        local z = enemies[i]
        if z and z.x then
            local dx = z.x - x
            local dy = z.y - y
            local dist = math.sqrt(dx*dx + dy*dy)
            if dist <= radius then
                local t = dist / radius
                local actualDamage = maxDamage * (1 - t) + minDamage * t
                actualDamage = math.floor(actualDamage)

                if z.hp - actualDamage <= 0 then
                    killZombie(z)
                else
                    z.hp = z.hp - actualDamage
                    local ratio = z.hp / z.maxHp
                    if z.hpFill then
                        z.hpFill.width = 50 * ratio
                        -- убрано z.hpFill.x
                    end
                    if z.hpText then
                        z.hpText.text = math.floor(z.hp) .. "/" .. z.maxHp
                    end
                    showDamageText(z, actualDamage, true, mainGroup)
                end
            end
        end
    end

    -- Урон NPC
    for i = #npcs, 1, -1 do
        local npc = npcs[i]
        if npc and npc.x then
            local dx = npc.x - x
            local dy = npc.y - y
            local dist = math.sqrt(dx*dx + dy*dy)
            if dist <= radius then
                local t = dist / radius
                local actualDamage = (maxDamage * (1 - t) + minDamage * t) / 3
                actualDamage = math.floor(actualDamage)
                if actualDamage > 0 then
                    npc.hp = npc.hp - actualDamage
                    local ratio = math.max(0, npc.hp / npc.maxHp)
                    if npc.hpFill then
                        npc.hpFill.width = 50 * ratio
                        -- убрано npc.hpFill.x
                    end
                    if npc.hpText then
                        npc.hpText.text = math.floor(npc.hp) .. "/" .. npc.maxHp
                    end
                    bloodParticles(npc.x, npc.y, "enemy", mainGroup)
                    if npc.hp <= 0 then
                        safeRemove(npc.nameText)
                        safeRemove(npc.hpBg)
                        safeRemove(npc.hpFill)
                        safeRemove(npc.hpText)
                        safeRemove(npc)
                        table.remove(npcs, i)
                        bloodPoolParticles(npc.x, npc.y, "enemy", mainGroup)
                    end
                end
            end
        end
    end

    -- Урон дверям
    for i = #doors, 1, -1 do
        local door = doors[i]
        if door and door.hitBox and door.hitBox.hp and door.x and door.y then
            local dx = door.x - x
            local dy = door.y - y
            local dist = math.sqrt(dx*dx + dy*dy)
            if dist <= radius then
                local t = dist / radius
                local actualDamage = (maxDamage * (1 - t) + minDamage * t)*2
                actualDamage = math.floor(actualDamage)
                damageDoor(door.hitBox, actualDamage)
            end
        end
    end    -- Урон газовым баллонам
    for _, canister in ipairs(gasCanisters) do
        if canister and canister.x and not canister.exploded then
            local dx = canister.x - x
            local dy = canister.y - y
            local dist = math.sqrt(dx*dx + dy*dy)
            if dist <= radius then
                local t = dist / radius
                local damage = math.floor((maxDamage * (1 - t) + minDamage * t) * 0.8)
                damageGasCanister(canister, math.max(10, damage))
            end
        end
    end

    -- Урон игроку
    if player and not isDead then
        local dx = player.x - x
        local dy = player.y - y
        local dist = math.sqrt(dx*dx + dy*dy)
        local playerRadius = radius * 0.75
        if dist <= playerRadius then
            local t = dist / playerRadius
            local actualDamage = (maxDamage / 2) * (1 - t) + (minDamage / 2) * t
            actualDamage = math.floor(actualDamage)
            if actualDamage > 0 then
                hp = hp - actualDamage
                showDamageFlash()
                bloodParticles(player.x, player.y, "player", mainGroup)
                updateHealthBar()
                if hp <= 0 then die() end
            end
        end
    end
end

local function healParticles(x, y, mainGroup)
    for i = 1, 5 do
        local p = display.newCircle(mainGroup, x + math.random(-15,15), y + math.random(-15,15), math.random(2,4))
        p:setFillColor(0,1,0)
        transition.to(p, {alpha = 0, time = 500, onComplete = function() safeRemove(p) end})
    end
end

local function getPath(startX, startY, endX, endY)
    local startCol = math.max(1, math.min(#map[1], math.floor(startX / tileSize) + 1))
    local startRow = math.max(1, math.min(#map, math.floor(startY / tileSize) + 1))
    local endCol = math.max(1, math.min(#map[1], math.floor(endX / tileSize) + 1))
    local endRow = math.max(1, math.min(#map, math.floor(endY / tileSize) + 1))

    if map[endRow][endCol] == 1 then
        return {{x = endX, y = endY}}
    end

    local openList = {{row = startRow, col = startCol, g = 0, h = 0, f = 0}}
    local closedList = {}
    local cameFrom = {}
    local neighbors = {
        {r=0, c=1}, {r=0, c=-1}, {r=1, c=0}, {r=-1, c=0},
        {r=1, c=1}, {r=1, c=-1}, {r=-1, c=1}, {r=-1, c=-1}
    }
    local iterations = 0

    while #openList > 0 do
        iterations = iterations + 1
        if iterations > 256 then break end

        table.sort(openList, function(a, b) return a.f < b.f end)
        local current = table.remove(openList, 1)

        if current.row == endRow and current.col == endCol then
            local path = {}
            local temp = current
            while temp do
                table.insert(path, 1, {x = (temp.col-1)*tileSize + tileSize/2, y = (temp.row-1)*tileSize + tileSize/2})
                temp = cameFrom[temp.row .. "_" .. temp.col]
            end
            if #path > 1 then table.remove(path, 1) end
            return path
        end

        closedList[current.row .. "_" .. current.col] = true

        for i = 1, #neighbors do
            local r, c = current.row + neighbors[i].r, current.col + neighbors[i].c
            if map[r] and map[r][c] and map[r][c] ~= 1 and not closedList[r .. "_" .. c] then
                local cost = (neighbors[i].r ~= 0 and neighbors[i].c ~= 0) and 1.4 or 1
                local g = current.g + cost
                local h = math.sqrt((r - endRow)^2 + (c - endCol)^2)
                local node = {row = r, col = c, g = g, h = h, f = g + h}
                cameFrom[r .. "_" .. c] = current
                table.insert(openList, node)
            end
        end
    end
    return {{x = endX, y = endY}}
end

local function canSeePlayer(z, playerX, playerY)
    if player.isInvisible then return false end
    local dx = playerX - z.x
    local dy = playerY - z.y
    local dist = math.sqrt(dx*dx + dy*dy)
    if dist > z.viewDistance then return false end

    local zombieAngle = math.rad(z.rect.rotation - 90)
    local toPlayerAngle = math.atan2(dy, dx)
    local angleDiff = math.abs(toPlayerAngle - zombieAngle)
    angleDiff = math.min(angleDiff, 2*math.pi - angleDiff)
    if math.deg(angleDiff) > z.viewAngle/2 then return false end

    -- Более частая проверка тайлов (каждые 25 пикселей)
    local step = 25
    local steps = math.floor(dist / step)
    for s = 1, steps do
        local cx = z.x + dx * (s / steps)
        local cy = z.y + dy * (s / steps)
        local col = math.floor(cx / tileSize) + 1
        local row = math.floor(cy / tileSize) + 1
        if map[row] and map[row][col] == 1 then
            return false
        end
    end
    return true
end
-- Проверяет, есть ли прямая видимость между двумя точками (без учёта стен)


local function setReloadMultiplier(newMult)
    if newMult == reloadSpeedMultiplier then return end
    local weapon = stats.currentWeapon
    if weapon and weapon.isReloading and weapon.reloadStartTime then
        local elapsed = system.getTimer() - weapon.reloadStartTime
        local totalTime = weapon.reloadT * reloadSpeedMultiplier
        local remaining = totalTime - elapsed
        if remaining > 0 then
            local newTotal = weapon.reloadT * newMult
            local newRemaining = math.max(0, newTotal * (remaining / totalTime))
            weapon.reloadStartTime = system.getTimer() - (newTotal - newRemaining)
            if weapon.reloadTimer then
                timer.cancel(weapon.reloadTimer)
                weapon.reloadTimer = nil
            end
            weapon.reloadTimer = timer.performWithDelay(newRemaining, function()
                if not isDead and weapon and weapon.isReloading then
                    local need = weapon.clip - weapon.currentClip
                    local available = math.min(weapon.bullets, need)
                    weapon.bullets = weapon.bullets - available
                    weapon.currentClip = weapon.currentClip + available
                    weapon.isReloading = false
                    weapon.reloadTimer = nil
                    weapon.reloadStartTime = nil
                    if stats.currentWeapon == weapon then
                        ammoText.text = weapon.currentClip .. " | " .. weapon.bullets
                    end
                end
            end)
            table.insert(activeTimers, weapon.reloadTimer)
        else
            weapon.reloadStartTime = nil
            weapon.isReloading = false
            if weapon.reloadTimer then timer.cancel(weapon.reloadTimer); weapon.reloadTimer = nil end
        end
    end
    reloadSpeedMultiplier = newMult
end

local function applyExtraWave(extra, playerX, playerY)
    local now = system.getTimer()
    local stunMs = extra.stunDuration * 1000

    for i = #enemies, 1, -1 do
        local z = enemies[i]
        if z and z.x then
            local dx = z.x - playerX
            local dy = z.y - playerY
            local dist = math.sqrt(dx*dx + dy*dy)

            if dist <= extra.radius then
                local isDeadNow = false

                if extra.damage > 0 then
                    z.hp = z.hp - extra.damage
                    local ratio = math.max(0, z.hp / z.maxHp)
                    if z.hpFill then
                        z.hpFill.width = 50 * ratio
                        -- убрано z.hpFill.x
                    end
                    if z.hpText then
                        z.hpText.text = math.floor(z.hp) .. "/" .. z.maxHp
                    end
                    showDamageText(z, extra.damage, true, mainGroup)
                    bloodParticles(z.x, z.y, "enemy", mainGroup)

                    if z.hp <= 0 then
                        killZombie(z)
                        isDeadNow = true
                    end
                end

                if not isDeadNow then
                    if extra.push > 0 and dist > 0 then
                        local vx = (dx / dist) * extra.push
                        local vy = (dy / dist) * extra.push
                        z:setLinearVelocity(vx, vy)
                    else
                        z:setLinearVelocity(0, 0)
                    end

                    if extra.stunDuration > 0 then
                        z.stunned = true
                        z.stunnedEndTime = now + stunMs
                        z.path = nil
                        z.isAttacking = false
                        if z.doubleAttackTimer then
                            timer.cancel(z.doubleAttackTimer)
                            z.doubleAttackTimer = nil
                        end
                        if z.rect then
                            z.rect:setFillColor(0.8, 0.8, 1)
                            timer.performWithDelay(stunMs, function()
                                if z and z.rect and not z.stunned then
                                    if z.zombieType == "healer" then
                                        z.rect:setFillColor(0.2, 0.9, 0.6)
                                    elseif z.zombieType == "exploder" then
                                        z.rect:setFillColor(0.9, 0.3, 0.2)
                                    elseif z.zombieType == "teleporter" then
                                        z.rect:setFillColor(0.7, 0.2, 0.9)
                                    elseif z.zombieType == "crikey" then
                                        z.rect:setFillColor(0.8, 0.6, 0.9)
                                    else
                                        z.rect:setFillColor(0.2, 0.8, 0.2)
                                    end
                                end
                            end)
                        end
                    end
                end
            end
        end
    end

    local waveCircle = display.newCircle(mainGroup, playerX, playerY, 5)
    waveCircle:setFillColor(0.3, 0.5, 1, 0.7)
    transition.to(waveCircle, {
        scaleX = (extra.radius * 2) / 10,
        scaleY = (extra.radius * 2) / 10,
        alpha = 0,
        time = 300,
        onComplete = function() safeRemove(waveCircle) end
    })
end

-- Активация Просвещения — временное раскрытие всей карты
local function activateEnlightenment()
    if enlightenmentActive then return end
    
    enlightenmentActive = true
    enlightenmentEndTime = system.getTimer() + 6000  -- 6 секунд
    
    -- Сохраняем текущее состояние explored, чтобы восстановить после
    local savedExplored = {}
    for row = 1, #map do
        savedExplored[row] = {}
        for col = 1, #map[row] do
            savedExplored[row][col] = explored[row][col]
        end
    end
    
    -- Открываем всю карту
    for row = 1, #map do
        for col = 1, #map[row] do
            if map[row][col] ~= 1 then
                explored[row][col] = true
            end
        end
    end
    
        -- Принудительно скрываем туман
    if fogGroup then
        fogGroup.alpha = 0
        fogGroup.isVisible = false
    end
    
    updateVisibility()
    

    

    
    -- Текст уведомления
    local notice = display.newText({
        parent = ui,
        text = "🧠 ПРОСВЕЩЕНИЕ!",
        x = display.contentCenterX,
        y = display.contentCenterY - 100,
        font = native.systemFontBold,
        fontSize = 32
    })
    notice:setFillColor(0.5, 0.8, 1)
    notice.alpha = 0
    transition.to(notice, { time = 300, alpha = 1 })
    transition.to(notice, { time = 500, delay = 5500, alpha = 0, onComplete = function() safeRemove(notice) end })
    
    -- Таймер возврата к нормальному туману
    if enlightenmentTimer then timer.cancel(enlightenmentTimer) end
    enlightenmentTimer = timer.performWithDelay(6000, function()
        enlightenmentActive = false
        enlightenmentTimer = nil
        
        -- Восстанавливаем сохранённое состояние explored
        for row = 1, #map do
            for col = 1, #map[row] do
                if savedExplored[row] and savedExplored[row][col] ~= nil then
                    explored[row][col] = savedExplored[row][col]
                end
            end
        end
        
                -- Восстанавливаем туман
        if fogGroup then
            fogGroup.alpha = 1
            fogGroup.isVisible = true
        end
        fogDirty = true
        updateFogAlpha()
        updateVisibility()
        

        
        -- Текст окончания
        local endNotice = display.newText({
            parent = ui,
            text = "Просвещение закончилось",
            x = display.contentCenterX,
            y = display.contentCenterY - 100,
            font = native.systemFontBold,
            fontSize = 20
        })
        endNotice:setFillColor(0.5, 0.8, 1)
        endNotice.alpha = 0
        transition.to(endNotice, { time = 300, alpha = 1 })
        transition.to(endNotice, { time = 500, delay = 1500, alpha = 0, onComplete = function() safeRemove(endNotice) end })
    end)
end

local function extraUse()
    if isDead or isPaused then return end
    local extra = stats.currentExtra
    if not extra then return end

    local now = system.getTimer()
    if now - lastExtraUseTime < extra.colldown then
        local remaining = math.ceil((extra.colldown - (now - lastExtraUseTime)) / 1000)
        showWarning("Экстра-навык перезаряжается: " .. remaining .. "с", 1500)
        return
    end

    if extra.type == "wave" then
        applyExtraWave(extra, player.x, player.y)
        lastExtraUseTime = now
    elseif extra.type == "enlightenment" then
        activateEnlightenment()
        lastExtraUseTime = now
    else
        print("Неизвестный тип экстра-навыка")
    end
end

local function reload()
    cancelBurst()

    local weapon = stats.currentWeapon
    if not weapon or weapon.isReloading or weapon.currentClip == weapon.clip or weapon.bullets <= 0 or isDead then
        return
    end
    weapon.isReloading = true
    weapon.reloadStartTime = system.getTimer()
    ammoText.text = "RELOADING..."

    if weapon.reloadTimer then timer.cancel(weapon.reloadTimer) end
    weapon.reloadTimer = timer.performWithDelay(weapon.reloadT * reloadSpeedMultiplier, function()
        if not isDead and weapon and weapon.isReloading then
            local need = weapon.clip - weapon.currentClip
            local available = math.min(weapon.bullets, need)
            weapon.bullets = weapon.bullets - available
            weapon.currentClip = weapon.currentClip + available
            weapon.isReloading = false
            weapon.reloadTimer = nil
            weapon.reloadStartTime = nil
            if stats.currentWeapon == weapon then
                ammoText.text = weapon.currentClip .. " | " .. weapon.bullets
            end
        end
    end)
    table.insert(activeTimers, weapon.reloadTimer)
end

local function playerInvis(time)
    player.isInvisible = true
    player.alpha = 0.5
    timer.performWithDelay(time, function()
        player.isInvisible = false
        player.alpha = 1
    end)
end

local function playerPhase(time)
    player.isPhasing = true
    player.alpha = 0.4
    player.type = "player_phasing"
    player.isSensor = true

    -- Запускаем тряску
    if player.body then
        player.body.origX = player.body.x  -- исходные координаты (0)
        player.body.origY = player.body.y  -- исходные (-15)
        player.shakeTimer = timer.performWithDelay(25, function()
            if player and player.body and player.isPhasing then
                player.body.x = player.body.origX + math.random(-2, 2)
                player.body.y = player.body.origY + math.random(-2, 2)
            end
        end, 0)  -- бесконечный цикл
    end

    timer.performWithDelay(time, function()
        if player then
            player.isPhasing = false
            player.alpha = 1
            player.type = "player"
            player.isSensor = false

            -- Останавливаем тряску и возвращаем спрайт на место
            if player.shakeTimer then
                timer.cancel(player.shakeTimer)
                player.shakeTimer = nil
            end
            if player.body then
                player.body.x = player.body.origX or 0
                player.body.y = player.body.origY or -15
            end
        end
    end)
end

local function ultimateUse()
    if isDead or isPaused then return end
    local ultimate = stats.currentUltimate
    if not ultimate then return end

    local now = system.getTimer()
    if now < ultimateCooldownEndTime then
        local remaining = math.ceil((ultimateCooldownEndTime - now) / 1000)
        showWarning("Ульта перезаряжается: " .. remaining .. "с", 1500)
        return
    end

    if ultimate.func == "playerInvis" then
        playerInvis(ultimate.time)
    elseif ultimate.func == "playerPhase" then
        playerPhase(ultimate.time)
    end
    ultimateActive = true
    ultimateEndTime = now + ultimate.time
    ultimateCooldownEndTime = ultimateEndTime + ultimate.colldown
end

local function removeBullet(bullet)
    if not bullet then return end
    -- отменяем transition плавного изменения урона (чтобы не менять удалённый объект)
    if bullet._dmgTransition then
        transition.cancel(bullet._dmgTransition)
        bullet._dmgTransition = nil
    end
    safeRemove(bullet)
end

local function createBullet(weapon, startX, startY, angle, isAimedShot, isBurst)
    local b
    if weapon.name == "Plazmite" then
        b = display.newRect(mainGroup, startX, startY, 8, 3)
        b:setFillColor(0.15, 0.45, 0.75)
        b.rotation = angle * 180 / math.pi
    else
        b = display.newCircle(mainGroup, startX, startY, 3)
        b:setFillColor(isAimedShot and 1 or 1, isAimedShot and 1 or 1, isAimedShot and 0.2 or 0.5)
    end
    b.angle = angle
    local isCrit = math.random(100) <= (weapon.critChance or 0)
    b.dmg = isCrit and (weapon.dmg * (weapon.critMult or 2)) or weapon.dmg
    if isAimedShot then
        b.dmg = b.dmg * (weapon.aimMult or 1)
    end
    b.isCrit = isCrit

    -- Сохраняем точку спавна для проверки препятствий
    b.startX = startX
    b.startY = startY

    physics.addBody(b, "dynamic", { isSensor = true, radius = 6 })
    b.type = "bullet"
    if isAimedShot then sp = weapon.aimSplash else sp = weapon.splash or 0 end
    b.splash = sp
    b.splashMult = weapon.splashMult
    b.aimMult = weapon.aimMult
    local spread = (isRunning and not isAimedShot) and (weapon.spread * 1.75) or weapon.spread
    local finalAngle = angle + math.rad(math.random(-spread, spread))

    if weapon.isShotgun or (weapon.pellets and weapon.pellets > 1) then
        local finalDmg = b.dmg * (weapon.minDmgMult or 0.2)
        local lifeTime = (weapon.range / weapon.bSpeed) * 1000
        -- БАГ 2: сохраняем transition для возможности отмены
        b._dmgTransition = transition.to(b, {
            time = lifeTime,
            dmg = finalDmg,
            alpha = 0.5,
            onComplete = function() removeBullet(b) end
        })
    else
        local lifeTime = (weapon.range / weapon.bSpeed) * 1000
        timer.performWithDelay(lifeTime, function() removeBullet(b) end)
    end

    b:setLinearVelocity(math.cos(finalAngle) * weapon.bSpeed, math.sin(finalAngle) * weapon.bSpeed)
    return b
end

local function damageZombie(z, bullet)
    if not z or not bullet then return end
    if not z.x or not z.hp or z.hp <= 0 then return end

    if not bullet.hitTargets then
        bullet.hitTargets = {}
    end
    if bullet.hitTargets[z] then
        return
    end
    bullet.hitTargets[z] = true

    if not z.lastShotId or bullet.shotId ~= z.lastShotId then
        z.lastShotId = bullet.shotId
        z.hitCountThisShot = 0
    end
    z.hitCountThisShot = (z.hitCountThisShot or 0) + 1
    local isFirstHitThisShot = (z.hitCountThisShot == 1)

    -- Призрак: каждая третья пуля пролетает насквозь
    if z.zombieType == "ghost" and isFirstHitThisShot then
        z.ghostHitCounter = (z.ghostHitCounter or 0) + 1
        if (z.ghostHitCounter % 3) == 0 then
            if z.rect then
                z.rect.alpha = 0.25
                timer.performWithDelay(90, function()
                    if z and z.rect then z.rect.alpha = 0.55 end
                end)
            end
            return
        end
    end

    local headshot = false
    if bullet.y < z.y - (z.ySize and (z.ySize * 0.15) or 5) then
        headshot = true
    end

    local finalDmg = math.floor(bullet.dmg or 0)
    if headshot then
        finalDmg = finalDmg * (bullet.aimMult or 1.3) * 1.35
        bullet.isCrit = true
        bullet.isHeadshot = true
    end

    z.hp = z.hp - finalDmg

    z.seesPlayer = true
    z.path = nil
    z.nextUpdate = 0

    local ratio = math.max(0, z.hp / z.maxHp)
    if z.hpFill then
        z.hpFill.width = 50 * ratio
        -- больше не меняем x/y
    end
    if z.hpText then
        z.hpText.text = math.floor(z.hp).."/"..z.maxHp
    end

    if z.rect then
        z.rect:setFillColor(1,0,0)
        timer.performWithDelay(100, function()
            if z and z.rect and z.hp > 0 and z.baseColor then
                z.rect:setFillColor(unpack(z.baseColor))
            end
        end)
    end

    if z.hp <= 0 then
        local isOneShot = (z.hitCountThisShot == 1)
        showDamageText(z, finalDmg, bullet.isCrit or headshot, mainGroup, true, isOneShot)
        killZombie(z, isOneShot)
    else
        showDamageText(z, finalDmg, bullet.isCrit or headshot, mainGroup, false, false)
    end

    bloodParticles(z.x, z.y, "enemy", mainGroup)

    if bullet.splash and bullet.splash > 0 then
        if bullet._dmgTransition then
            transition.cancel(bullet._dmgTransition)
            bullet._dmgTransition = nil
        end
        bullet.splash = bullet.splash - 1
        bullet.xScale = bullet.xScale/1.5
        bullet.yScale = bullet.yScale/1.5
        bullet.dmg = bullet.dmg / (bullet.splashMult or 1.5)
    else
        removeBullet(bullet)
    end
end

local function checkBulletImmediateHit(bullet)
    if not bullet or not bullet.x then return false end

    -- БАГ 7: проверяем, не перекрыта ли прямая видимость стеной
    local startX = bullet.startX or player.x   -- fallback на позицию игрока, если по какой-то причине нет startX
    local startY = bullet.startY or player.y

    for i = 1, #enemies do
        local z = enemies[i]
        if z and z.x and z.hp > 0 and z.type == "zombie" then
            local dx = bullet.x - z.x
            local dy = bullet.y - z.y
            local dist = math.sqrt(dx*dx + dy*dy)
            local hitRadius = (z.xSize / 1.5) + 6
            if dist <= hitRadius then
                -- проверка видимости через тайлы
                local steps = math.ceil(dist / tileSize) + 1
                local blocked = false
                for s = 1, steps do
                    local t = s / steps
                    local cx = startX + (bullet.x - startX) * t
                    local cy = startY + (bullet.y - startY) * t
                    local col = math.floor(cx / tileSize) + 1
                    local row = math.floor(cy / tileSize) + 1
                    if map[row] and (map[row][col] == 1 or map[row][col] == 3 or map[row][col] == 5 or map[row][col] == 7) then
                        blocked = true
                        break
                    end
                end
                if not blocked then
                    damageZombie(z, bullet)
                    return true
                end
            end
        end
    end
    return false
end
-- Визуальная отдача ствола (плавная и мягкая)
function playRecoil()
    if not barrel then return end
    -- Отменяем все активные переходы на стволе
    transition.cancel(barrel)

    -- Запоминаем исходный масштаб (на случай, если он не 1.0)
    local origScale = barrel.xScale or 1.0

    -- Этап 1: Быстрое сжатие (80 мс) до 0.88 от исходного размера
    transition.to(barrel, {
        time = 80,
        xScale = 0.88,
        easing = easing.outQuad,
        onComplete = function()
            -- Этап 2: Плавный возврат с "пружинкой" (outBack)
            transition.to(barrel, {
                time = 150,
                xScale = 1.0,
                easing = easing.outBack
            })
        end
    })
end
-- Искры в конце дула при выстреле
function spawnMuzzleFlash(x, y, angle)
    if not mainGroup then return end
    local count = 8 + math.random(0, 4)   -- 6–10 искр
    for i = 1, count do
        local size = math.random(0.8, 1.7)
        local spark = display.newCircle(mainGroup, x, y, size)
        -- Случайный цвет от белого до жёлто-оранжевого
        local r = 1
        local g = 0.6 + math.random() * 0.4
        local b = 0.1 + math.random() * 0.3
        spark:setFillColor(r, g, b)
        spark.alpha = 0.9

        -- Разброс по углу ±30 градусов от направления выстрела
        local spread = math.rad(30)
        local ang = angle + (math.random() - 0.5) * 2 * spread
        local speed = math.random(50, 150)
        local vx = math.cos(ang) * speed
        local vy = math.sin(ang) * speed

        -- Движение и затухание
        transition.to(spark, {
            x = spark.x + vx * 0.3,
            y = spark.y + vy * 0.3,
            alpha = 0,
            time = 200 + math.random(0, 100),
            onComplete = function() safeRemove(spark) end
        })
        spark.rotation = math.random(360)
    end
end
-- Искры при попадании в стену/дверь
function spawnHitSparks(x, y, angle)
    if not mainGroup then return end
    local count = 8 + math.random(0, 6)   -- 8–14 искр
    for i = 1, count do
        local size = math.random(1, 3)
        local spark = display.newCircle(mainGroup, x, y, size)
        -- Бело-жёлтый цвет
        local r = 1
        local g = 0.7 + math.random() * 0.3
        local b = 0.2 + math.random() * 0.4
        spark:setFillColor(r, g, b)
        spark.alpha = 0.9

        -- Разброс в обратную сторону от стены (угол + 180° ± 60°)
        local spread = math.rad(60)
        local dirAngle = angle + math.pi + (math.random() - 0.5) * 2 * spread
        local speed = math.random(40, 120)
        local vx = math.cos(dirAngle) * speed
        local vy = math.sin(dirAngle) * speed

        transition.to(spark, {
            x = spark.x + vx * 0.3,
            y = spark.y + vy * 0.3,
            alpha = 0,
            time = 150 + math.random(100),
            rotation = math.random(360),
            onComplete = function() safeRemove(spark) end
        })
    end
end
-- Вылетающая гильза
function spawnShell(x, y, angle)
    if not mainGroup then return end
    local shell = display.newRect(mainGroup, x, y, 5, 2)
    shell:setFillColor(0.8, 0.7, 0.2)  -- латунный цвет
    shell.alpha = 75
    shell.rotation = math.random(-30, 30) + math.deg(angle) * 0.5

    local speed = math.random(75, 150)
    local dirAngle = angle + math.rad(math.random(-30, 30))
    local vx = math.cos(dirAngle) * speed
    local vy = math.sin(dirAngle) * speed + 80

    -- Анимация полёта и падения
    transition.to(shell, {
        x = shell.x + vx * 0.3,
        y = shell.y + vy * 0.3 + 40,
        rotation = shell.rotation + math.random(200, 400),
        time = 400 + math.random(200),
        onComplete = function()
            -- Задержка перед исчезновением
            transition.to(shell, {
                alpha = 0,
                time = 1250 + math.random(1000),
                onComplete = function() safeRemove(shell) end
            })
        end
    })
end
local function createArcherArrow(startX, startY, targetX, targetY, damage)
    local arrow = display.newRect(mainGroup, startX, startY, 12, 4)
    arrow:setFillColor(0.6, 0.3, 0.1)  -- коричневая стрела
    arrow.type = "arrow"
    arrow.dmg = damage

    -- Вычисляем направление
    local dx = targetX - startX
    local dy = targetY - startY
    local dist = math.sqrt(dx*dx + dy*dy)
    if dist > 0 then
        dx, dy = dx/dist, dy/dist
    end
    arrow.rotation = math.deg(math.atan2(dy, dx))

    physics.addBody(arrow, "dynamic", { isSensor = true, radius = 6 })
    arrow:setLinearVelocity(dx * 300, dy * 300)  -- скорость 300

    -- Удаляем стрелу через 3 секунды
    arrow.removeTimer = timer.performWithDelay(3000, function()
    safeRemove(arrow)
end)

    return arrow
end

local function spawnBul(isBurst)
    local weapon = stats.currentWeapon or "AK-47"
    if not weapon or weapon.isReloading or isDead then return end
    if weapon.currentClip <= 0 then
        reload()
        return
    end

    weapon.currentClip = weapon.currentClip - 1
    ammoText.text = weapon.currentClip .. " | " .. weapon.bullets

    local angleRad = currentAimAngle
    local bLen = weapon.barrelLen or 20
    local startX = player.x + math.cos(angleRad) * bLen
    local startY = (player.y - 20) + math.sin(angleRad) * bLen

    shotCounter = shotCounter + 1
    local currentShotId = shotCounter

    local pellets = weapon.pellets or 1
    for i = 1, pellets do
        local offset = 0
        if pellets > 1 then
            offset = (i - (pellets + 1) / 2) * (weapon.shotAngle or 0)
        end
        local bullet = createBullet(weapon, startX, startY, angleRad + math.rad(offset), false, isBurst)
        bullet.shotId = currentShotId
        spawnMuzzleFlash(startX, startY, angleRad + math.rad(offset))
        playRecoil()
        checkBulletImmediateHit(bullet)   -- проверили и нанесли урон/удалили при необходимости

        if i == 1 then                    -- отдача всегда
            local recoil = 5
            player.x = player.x - math.cos(angleRad) * recoil
            player.y = player.y - math.sin(angleRad) * recoil
        end
        spawnShell(startX, startY, angleRad)
    end
end


local function burstTick()
    local weapon = vars.burst.weapon
    if not weapon then
        cancelBurst()
        return
    end

    if isDead or isPaused or weapon.isReloading then
        cancelBurst()
        return
    end

    if weapon.currentClip <= 0 then
        cancelBurst()
        reload()
        return
    end

    -- Plazmite: стреляет очередями всегда; AK-47: только в burstModeEnabled
    if weapon.name == "Plazmite" then
        if weapon.burstModeEnabled then spawnBul(true) else spawnBul() end
    else
        spawnBul(true)
    end

    vars.burst.remaining = vars.burst.remaining - 1
    if vars.burst.remaining > 0 then
        vars.burst.timer = timer.performWithDelay(weapon.burstDelay, burstTick)
    else
        vars.burst.timer = timer.performWithDelay(weapon.burstCooldown, function()
            vars.burst.timer = nil
            vars.burst.active = false
        end)
    end
end

local function startBurst(weapon)
    if not weapon then return end
    if vars.burst.active then return end
    vars.burst.active = true
    vars.burst.weapon = weapon
    vars.burst.remaining = weapon.burstCount or 0
    if vars.burst.remaining <= 0 then
        cancelBurst()
        return
    end
    burstTick()
end

local function throwGrenade()
    if grenades <= 0 then return end
    grenades = grenades - 1
    if grenadeText then grenadeText.text = "x" .. grenades end
    save.savePlayerData(brainPieces)
    if grenades == 0 and grenadeIcon then
        grenadeIcon.alpha = 0
        grenadeText.alpha = 0
    end

    local grenadeData = weapons["Grenade"]
    if not grenadeData then return end

    local angleRad = currentAimAngle
    local startX = player.x + math.cos(angleRad) * 20
    local startY = (player.y - 20) + math.sin(angleRad) * 20

    local grenade = display.newCircle(mainGroup, startX, startY, 8)
    grenade:setFillColor(1, 0.5, 0)
    physics.addBody(grenade, "dynamic", { radius = 8, isSensor = true })
    grenade.type = "grenade"
    grenade.exploded = false               -- флаг, чтобы избежать двойного взрыва

    local speed = grenadeData.throwSpeed
    local vx = math.cos(angleRad) * speed
    local vy = math.sin(angleRad) * speed
    grenade:setLinearVelocity(vx, vy)

    local explosionTimer = timer.performWithDelay(grenadeData.fuseTime, function()
        if grenade and not grenade.exploded and grenade.x then
            grenade.exploded = true
            grenadeExplosion(grenade.x, grenade.y, grenadeData.damage, grenadeData.explosionRadius, grenadeData.minDamage)
            safeRemove(grenade)
        end
    end)
    table.insert(activeTimers, explosionTimer)

    -- Сохраняем таймер в сам объект, чтобы можно было отменить при ударе о стену
    grenade.explosionTimer = explosionTimer
end

local function aimShoot()
    local weapon = stats.currentWeapon
    if not weapon or weapon.isReloading or isDead then return end
    if weapon.currentClip <= 0 then
        reload()
        return
    end

    local repeats = weapon.aimRepeat or 1
    local actualShots = math.min(weapon.currentClip, repeats)   -- сколько реально можем выстрелить

    weapon.currentClip = weapon.currentClip - actualShots
    ammoText.text = weapon.currentClip .. " | " .. weapon.bullets

    local rDelay = weapon.aimRepeatDelay or 150
    shotCounter = shotCounter + 1
    local currentShotId = shotCounter

    local aimAngle = currentAimAngle

    for rCount = 0, actualShots - 1 do
        local t = timer.performWithDelay(rCount * rDelay, function()
            if isDead or not player or stats.currentWeapon ~= weapon then return end

            local bursts = weapon.aimBurstCount or 1
            local bDelay = weapon.burstDelay or 0
            for bCount = 0, bursts - 1 do
                local t2 = timer.performWithDelay(bCount * bDelay, function()
                    if isDead or not player or stats.currentWeapon ~= weapon then return end

                    local angleRad = aimAngle
                    local bLen = weapon.barrelLen or 20
                    local startX = player.x + math.cos(angleRad) * bLen
                    local startY = (player.y - 20) + math.sin(angleRad) * bLen

                    local pellets = weapon.pellets or 1
                    for i = 1, pellets do
                        local offset = 0
                        if pellets > 1 then
                            offset = (i - (pellets + 1) / 2) * (weapon.shotAngle or 0) / 1.5
                        end
                        local bullet = createBullet(weapon, startX, startY, angleRad + math.rad(offset), true)
                        bullet.shotId = currentShotId
                        spawnMuzzleFlash(startX, startY, angleRad + math.rad(offset))
                        playRecoil()
                        checkBulletImmediateHit(bullet)
                        if i == 1 then
                            local recoil = 10
                            player.x = player.x - math.cos(angleRad) * recoil
                            player.y = player.y - math.sin(angleRad) * recoil
                        end
                    end
                    spawnShell(startX, startY, angleRad)
                end)
                table.insert(activeTimers, t2)
            end
        end)
        table.insert(activeTimers, t)
    end
end

local function createAimLine()
    if aimLine then safeRemove(aimLine); aimLine = nil end
    if not isAiming or not player then return end

    -- Используем сохранённый угол прицеливания
    local angleRad = currentAimAngle
    local bLen = stats.currentWeapon.barrelLen or 20

    -- Точка старта — конец ствола в мировых координатах
    local startX = player.x + math.cos(angleRad) * bLen
    local startY = (player.y - 20) + math.sin(angleRad) * bLen

    -- Направление к мыши (в координатах mainGroup)
    local mx, my = mainGroup:contentToLocal(mouseX, mouseY)
    local dirX = mx - startX
    local dirY = my - startY
    local len = math.sqrt(dirX*dirX + dirY*dirY)

    if len > 1 then
        dirX, dirY = dirX/len, dirY/len
        -- Рисуем линию длиной 2000 пикселей
        aimLine = display.newLine(mainGroup, startX, startY, startX + dirX * 2000, startY + dirY * 2000)
        aimLine.strokeWidth = 2
        aimLine:toFront()

        local aimTime = stats.currentWeapon.aimTime or 500
        if system.getTimer() - (aimStartTime or 0) >= aimTime then
            aimLine:setStrokeColor(0, 1, 0, 0.8)
        else
            aimLine:setStrokeColor(1, 0, 0, 0.5)
        end
    end
end

local function teleportFlash(x, y)
    local flash = display.newCircle(mainGroup, x, y, 35)
    flash:setFillColor(1, 1, 0, 0.7)
    transition.to(flash, { alpha = 0, scaleX = 1.8, scaleY = 1.8, time = 200, onComplete = function() safeRemove(flash) end })
end

local function isValidTeleportPoint(x, y)
    local col = math.floor(x / tileSize) + 1
    local row = math.floor(y / tileSize) + 1
    if row < 1 or row > #map or col < 1 or col > #map[1] then return false end
    return map[row][col] ~= 1
end

local function createDonorChunk(startX, startY, targetX, targetY, damage)
    local chunk = display.newCircle(mainGroup, startX, startY, 10)
    chunk:setFillColor(0.8, 0.2, 0.2)   -- кроваво-красный
    chunk.type = "donor_chunk"
    chunk.dmg = damage
    chunk.speed = 600                   -- в 2 раза быстрее стрелы лучника
    chunk.turnRate = math.rad(3)        -- максимальный поворот за кадр (≈3°)
    chunk.target = player               -- ссылка на игрока (будет обновляться в EnterFrame)

    -- Начальное направление прямо на игрока
    local dx = targetX - startX
    local dy = targetY - startY
    local dist = math.sqrt(dx*dx + dy*dy)
    if dist > 0 then
        dx, dy = dx/dist, dy/dist
    end
    chunk.rotation = math.deg(math.atan2(dy, dx))

    physics.addBody(chunk, "dynamic", { isSensor = true, radius = 10 })
    chunk.isSleepingAllowed = false
    chunk.linearDamping = 0
    chunk:setLinearVelocity(dx * chunk.speed, dy * chunk.speed)

    -- Добавляем в список для обновления траектории
    table.insert(donorChunks, chunk)

    -- Удаление через 4 секунды
    chunk.removeTimer = timer.performWithDelay(4000, function()
        safeRemove(chunk)
    end)
    return chunk
end

local function applyPoisonEffect()
    if isDead or not player then return end
    
    -- Если уже есть таймер, отменяем старый, чтобы обновить длительность
    if poisonTimer then timer.cancel(poisonTimer) end
    
    showWarning("ОТРАВЛЕНИЕ!", 3500)
    
    -- Снимает 2 хп каждую секунду, 5 раз
    poisonTimer = timer.performWithDelay(1000, function(e)
        if not isDead and hp > 0 then
            hp = hp - 2
            showDamageFlash()
            bloodParticles(player.x, player.y, "player", mainGroup)
            updateHealthBar()
            if hp <= 0 then die() end
        end
    end, 5)
    table.insert(activeTimers, poisonTimer)
end

local function spawnZombie(typeData, typeName, spawnX, spawnY)
    if isPaused or isDead then return end
    local z = display.newGroup()

    if spawnX and spawnY then
        z.x, z.y = spawnX, spawnY
    else
        local side = math.random(1,4)
        if side == 1 then z.x, z.y = -50, math.random(20, display.actualContentHeight-20)
        elseif side == 2 then z.x, z.y = display.actualContentWidth+50, math.random(20, display.actualContentHeight-20)
        elseif side == 3 then z.x, z.y = math.random(20, display.actualContentWidth-20), -50
        else z.x, z.y = math.random(20, display.actualContentWidth-20), display.actualContentHeight+50 end
    end

    mainGroup:insert(z)

    local r, g, b = 0.2, 0.8, 0.2
    if typeName == "healer" then
        r, g, b = 0.2, 0.9, 0.6
    elseif typeName == "ghost" then
        r, g, b = unpack(typeData.color or {0.7, 0.85, 1})
    elseif typeName == "donor" then
        r, g, b = unpack(typeData.color)
    elseif typeName == "exploder" then
        r, g, b = 0.9, 0.3, 0.2
    elseif typeName == "teleporter" then
        r, g, b = 0.7, 0.2, 0.9
    elseif typeName == "crikey" then
        r, g, b = 0.8, 0.6, 0.9
    elseif typeName == "archer" then
        r, g, b = 0.8, 0.5, 0.2
    elseif typeName == "acid_zombie" then
        r, g, b = unpack(typeData.color)
        z.lastPuke = 0
    elseif typeName == "summoner" then
        r, g, b = 0.9, 0.5, 1
        z.hasSummonedFirst = false
        z.lastSummonTime = 0
        z.summonCooldown = typeData.summonCooldown or 30000
        z.summonRadius = typeData.summonRadius or 200
    end

    z.rect = display.newRect(z, 0, -20, typeData.xSize, typeData.ySize)
    z.rect:setFillColor(r, g, b)
    z.baseColor = {r, g, b}
    if typeName == "ghost" then
        z.rect.alpha = 0.55
    end

    -- Фон полоски (центрирован)
    z.hpBg = display.newRoundedRect(z, 0, -60, 50, 10, 3)
    z.hpBg:setFillColor(0,0,0,0.5)
    z.hpBg.anchorX, z.hpBg.anchorY = 0.5, 0.5

    -- Полоска здоровья: левый край зафиксирован, ширина уменьшается вправо
    z.hpFill = display.newRoundedRect(z, -25, -60, 50, 10, 3)
    z.hpFill:setFillColor(1,0,0,0.8)
    z.hpFill.anchorX, z.hpFill.anchorY = 0, 0.5   -- левый край, центр по Y

    z.hpText = display.newText(z, math.floor(typeData.maxHp).."/"..typeData.maxHp, 0, -60, native.systemFontBold, 10)
    z.hpText:setFillColor(1,1,1)
    z.hpText.anchorX, z.hpText.anchorY = 0.5, 0.5

    z.nameText = display.newText(z, typeName, 0, -80, native.systemFontBold, 12)
    z.nameText:setFillColor(1,1,1)
    z.nameText.anchorX, z.nameText.anchorY = 0.5, 0.5

    local hitRadius = typeData.xSize/1.5
    if typeName == "ghost" then
        physics.addBody(z, "dynamic", { bounce = 0, radius = hitRadius, isSensor = true })
    else
        physics.addBody(z, "dynamic", { bounce = 0, radius = hitRadius })
    end
    z.isFixedRotation = true

    z.hp = typeData.maxHp
    z.maxHp = typeData.maxHp
    z.type = "zombie"
    z.zombieType = typeName
    z.speed = typeData.speed
    z.attackRate = typeData.attackRate
    z.lastAttack = 0
    z.isAttacking = false
    z.path = nil
    z.nextUpdate = 0
    z.dmg = typeData.dmg
    z.xSize = typeData.xSize
    z.lastHeal = 0
    z.moveAngle = nil
    z.linearDamping = 2
    z.angularDamping = 5
    z.stunned = false
    z.stunnedEndTime = 0
    z.lastShotId = nil
    z.hitCountThisShot = 0
    z.originX = z.x
    z.originY = z.y
    z.wanderRadius = 1000
    z.wanderTargetX = nil
    z.wanderTargetY = nil
    z.wanderUpdateTime = 0
    z.wanderPauseUntil = 0
    z.wanderSpeedFactor = 0.5
    z.seesPlayer = false
    z.viewAngle = 320
    z.viewDistance = 750

    if typeName == "archer" then
        z.rangedDmg = typeData.rangedDmg
        z.rangedRate = typeData.rangedRate
        z.rangedRange = typeData.rangedRange
        z.lastRangedAttack = 0
    end
    if typeName == "donor" then
        z.scaleFactor = 1.0
        z.lastThrow = 0
        z.throwRange = typeData.throwRange
        z.throwDamage = typeData.throwDamage
        z.throwSelfDamage = typeData.throwSelfDamage
        z.throwCooldown = typeData.throwCooldown
    end

    if typeName == "teleporter" then
        z.lastTeleport = 0
        z.doubleAttackTimer = nil
        z.attackCount = 0
        z.teleportCooldown = typeData.teleportCooldown
        z.doubleAttackDelay = typeData.doubleAttackDelay

    elseif typeName == "crikey" then
        z.lastScream = 0
        z.screamCooldown = typeData.screamCooldown
        z.screamRadius = typeData.screamRadius or 400
        z.targetX, z.targetY = nil, nil
        z.lastTargetUpdate = 0
    end

    table.insert(enemies, z)

    local ix = (z.x / mapWidth) * minimapSize
    local iy = (z.y / mapHeight) * minimapSize
    local icon = display.newCircle(minimapGroup, 10 + ix, 10 + iy, 3)
    icon:setFillColor(1,0,0)
    icon.zombieRef = z
    table.insert(minimapZombieIcons, icon)
end

local function collectLoot(item)
    local d = item.lootData
    if not d then return end

    local msg = ""
    if d.weapon then
        weapons[d.weapon].bullets = weapons[d.weapon].bullets + d.value
        msg = "+" .. d.value .. " " .. d.label
        if stats.currentWeapon == weapons[d.weapon] then
            ammoText.text = stats.currentWeapon.currentClip .. " | " .. stats.currentWeapon.bullets
        end
    elseif d.label == "ENERGY" then
        energyDrinks = energyDrinks + 1
        msg = "+1 ENERGY"
        energyIcon.alpha = 1
        energyText.alpha = 1
        energyText.text = "x" .. energyDrinks
    elseif d.label == "GRENADE" then
        grenades = grenades + (d.value or 1)
        msg = "+" .. (d.value or 1) .. " GRENADE"
        if grenadeIcon then grenadeIcon.alpha = 1 end
        if grenadeText then 
            grenadeText.alpha = 1
            grenadeText.text = "x" .. grenades
        end
    else
        medkits = medkits + 1
        msg = "+1 " .. d.label
        medkitIcon.alpha = 1
        medkitText.alpha = 1
        medkitText.text = "x" .. medkits
    end

    local t = display.newText(damageTextGroup, msg, player.x, player.y - 60, native.systemFontBold, 20)
    t:setFillColor(unpack(d.color))
    transition.to(t, { time = 800, y = t.y - 40, alpha = 0, onComplete = function() safeRemove(t) end })

    if item.minimapIcon then
        for i, ic in ipairs(minimapLootIcons) do
            if ic == item.minimapIcon then
                safeRemove(ic)
                table.remove(minimapLootIcons, i)
                break
            end
        end
    end
    if item.tempText then safeRemove(item.tempText) end
    safeRemove(item)
end




local function completeLevel()
    if levelWon or isDead then return end
    if traderMenuActive and closeTraderMenu then
        closeTraderMenu()
    end
    levelWon = true
    isShooting = false
    cancelAllTimers()
    if chestLootingActive then
        cancelChestLooting(false)
    end

    -- 1. ЗАГРУЖАЕМ ТЕКУЩИЕ ДАННЫЕ
    local data = save.loadPlayerData()
    completedLevels = data.completed or {}
    replayedLevels = data.replayed or {}
    brainPieces = data.brains or 0
    
    -- 2. ОТМЕЧАЕМ УРОВЕНЬ КАК ПРОЙДЕННЫЙ (в локальной копии)
    completedLevels[currentLevelKey] = true
    
    -- 3. ПРОВЕРЯЕМ РЕПЛЕЙ (если уже пройден и не реплей)
    if not replayedLevels[currentLevelKey] then
        replayedLevels[currentLevelKey] = true
    end
    
    -- 4. НАГРАДЫ
    for _, reward in ipairs(currentRewards) do
        if reward.type == "brains" then
            brainPieces = brainPieces + reward.amount
        elseif reward.type == "medkit" then
            medkits = medkits + reward.amount
        elseif reward.type == "energy" then
            energyDrinks = energyDrinks + reward.amount
        elseif reward.type == "grenade" then
            grenades = grenades + reward.amount
        elseif reward.type == "ammo" and reward.weapon then
            if weapons[reward.weapon] then
                weapons[reward.weapon].bullets = weapons[reward.weapon].bullets + reward.amount
            end
        end
    end

    -- 5. ОБНОВЛЯЕМ ГЛОБАЛЬНЫЕ ПЕРЕМЕННЫЕ ДЛЯ save.lua
    _G.completedLevels = completedLevels
    _G.replayedLevels = replayedLevels
    _G.medkits = medkits
    _G.energyDrinks = energyDrinks
    _G.grenades = grenades
    _G.brainPieces = brainPieces
    
    -- 6. СОХРАНЯЕМ
    save.savePlayerData(brainPieces)
    
    -- 7. ОБНОВЛЯЕМ UI
    updateMedkitUI()
    updateEnergyUI()
    updateGrenadeUI()
    updateAmmoUI()
    updateBrainDisplay()

    -- 8. Затемнение и переход
    local blackOverlay = display.newRect(scene.view, display.contentCenterX, display.contentCenterY,
        display.actualContentWidth * 2, display.actualContentHeight * 2)
    blackOverlay:setFillColor(0, 0, 0)
    blackOverlay.alpha = 0
    transition.to(blackOverlay, { time = 500, alpha = 1 })

    transition.to(mainGroup, { time = 1500, alpha = 0 })
    transition.to(ui, { time = 1500, alpha = 0, onComplete = function()
        local winText = display.newText({
            parent = scene.view,
            text = _G.getText("levelComplete"),
            x = display.contentCenterX,
            y = display.contentCenterY,
            font = native.systemFontBold,
            fontSize = 44
        })
        winText:setFillColor(0.3, 1, 0.4)
        winText.alpha = 0
        transition.to(winText, { time = 1000, alpha = 1, onComplete = function()
            timer.performWithDelay(2000, function()
                composer.removeScene("game")
                composer.gotoScene("levels", { effect = "slideLeft", time = 500 })
            end)
        end})
    end})
end

local function setElevatorGreen()
    if not elevator then return end
    elevator.indicator:setFillColor(0.2, 1, 0.25)
    elevator.frame:setStrokeColor(0.25, 1, 0.35)
    elevator.doorL:setFillColor(0.15, 0.65, 0.2)
    elevator.doorR:setFillColor(0.15, 0.65, 0.2)
    elevator.glow.alpha = 0.75

    local function pulseGlow()
        if not elevator or not elevator.glow or not elevator.glow.parent then return end
        transition.to(elevator.glow, {
            alpha = 0.35,
            time = 700,
            onComplete = function()
                if not elevator or not elevator.glow or not elevator.glow.parent then return end
                transition.to(elevator.glow, { alpha = 0.85, time = 700, onComplete = pulseGlow })
            end
        })
    end
    pulseGlow()
end

local function playElevatorUnlockSequence()
    if elevatorSequenceDone or not elevator then return end

    -- Сброс ввода, чтобы не залипали клавиши после катсцены
    move.up, move.down, move.left, move.right = false, false, false, false
    isRunning, isCrouching, isDashing = false, false, false
    isShooting, isAiming = false, false
    cancelBurst()
    if player then
        player:setLinearVelocity(0, 0)
    end

    elevatorSequenceDone = true
    elevatorCutsceneActive = true

    local notice = display.newText({
        parent = ui,
        text = _G.getText("elevatorOpened"),
        x = display.contentCenterX,
        y = display.contentCenterY - 200,
        font = native.systemFontBold,
        fontSize = 30
    })
    notice:setFillColor(0.35, 1, 0.45)
    notice.alpha = 0
    transition.to(notice, { time = 400, alpha = 1 })

    local playerCamX = display.contentCenterX - player.x
    local playerCamY = display.contentCenterY - player.y
    local elevCamX = display.contentCenterX - elevator.x
    local elevCamY = display.contentCenterY - elevator.y
        -- Сделать видимой область вокруг лифта
    if elevator and elevator.x and elevator.y then
        local col = math.floor(elevator.x / tileSize) + 1
        local row = math.floor(elevator.y / tileSize) + 1
        for r = math.max(1, row - 2), math.min(#map, row + 2) do
            for c = math.max(1, col - 2), math.min(#map[1], col + 2) do
                if map[r] and map[r][c] and map[r][c] ~= 1 then
                    explored[r][c] = true
                end
            end
        end
        fogDirty = true
        updateVisibility()   -- обновить видимость немедленно
    end
    transition.cancel(mainGroup)
    transition.to(mainGroup, {
        time = 1200,
        x = elevCamX,
        y = elevCamY,
        transition = easing.inOutQuad,
        onComplete = function()
            setElevatorGreen()
            timer.performWithDelay(1200, function()
                transition.to(mainGroup, {
                    time = 1200,
                    x = playerCamX,
                    y = playerCamY,
                    transition = easing.inOutQuad,
                    onComplete = function()
                        elevatorActive = true
                        elevatorCutsceneActive = false
                        transition.to(notice, {
                            time = 500,
                            alpha = 0,
                            onComplete = function() safeRemove(notice) end
                        })
                    end
                })
            end)
        end
    })
end

checkLevelComplete = function()
    if levelWon or isDead or not levelMaxZombies then return end
    if levelWon or isDead then return end
    if allZombiesSpawned and #enemies == 0 then
        if true then
            if not elevatorSequenceDone then
                playElevatorUnlockSequence()
            end
        else
            completeLevel()
        end
    end
end




local function giveLootFromChest(itemData, index)
    if itemData.type == "medkit" then
        medkits = medkits + itemData.value
        medkitText.text = "x" .. medkits
        medkitIcon.alpha = 1
        medkitText.alpha = 1
    elseif itemData.type == "energy" then
        energyDrinks = energyDrinks + itemData.value
        energyText.text = "x" .. energyDrinks
        energyIcon.alpha = 1
        energyText.alpha = 1
    elseif itemData.type == "ammo" then
        local weapon = weapons[itemData.weapon]
        if weapon then
            weapon.bullets = weapon.bullets + itemData.value
            if stats.currentWeapon == weapon then
                ammoText.text = weapon.currentClip .. " | " .. weapon.bullets
            end
        end
    elseif itemData.type == "health" then
        hp = math.min(stats.maxHp, hp + itemData.value)
        if healthBar then healthBar.width = math.max(1, (hp/stats.maxHp)*120) end
    elseif itemData.type == "energy_boost" then
        energy = math.min(stats.maxEnergy, energy + itemData.value)
        if energyBar then energyBar.width = math.max(1, (energy/stats.maxEnergy)*120) end
    end

    local msg = "+" .. (itemData.value or 1) .. " " .. itemData.label
    local t = display.newText(damageTextGroup, msg, player.x, player.y - 60 - index * 25, native.systemFontBold, 20)
    t:setFillColor(0.8, 0.8, 0.2)
    t.alpha = 0.8
    transition.to(t, { time = 1700, y = t.y - 40, alpha = 0, onComplete = function() safeRemove(t) end })
end

local function startChestLooting(chest)
    if chest.isOpened or chestLootingActive then return end

    -- Отменяем текущий обыск, если есть
    cancelChestLooting(false)

    chestLootingActive = true
    activeChest = chest
    chestLootingStartX = player.x
    chestLootingStartY = player.y

    local duration = math.random(10, 20) / 10

    local barWidth = 300
    local barHeight = 30
    chestProgressBar = display.newRoundedRect(ui, display.contentCenterX - barWidth/2, display.contentCenterY - 50, barWidth, barHeight, 10)
    chestProgressBar:setFillColor(0.2, 0.2, 0.2, 0.8)
    chestProgressBar.strokeWidth = 2
    chestProgressBar:setStrokeColor(1, 1, 1)
    chestProgressBar.anchorX = 0

    chestProgressFill = display.newRoundedRect(ui, display.contentCenterX - barWidth/2, display.contentCenterY - 50, 0, barHeight, 10)
    chestProgressFill:setFillColor(1, 1, 1)
    chestProgressFill.anchorX = 0

    lootingProgressText = display.newText({
        parent = ui,
        text = "Обыск сундука...",
        x = display.contentCenterX,
        y = display.contentCenterY - 90,
        font = native.systemFontBold,
        fontSize = 18
    })
    lootingProgressText:setFillColor(1, 1, 1)

    local function checkMovement()
        if not chestLootingActive then return true end
        local dx = player.x - chestLootingStartX
        local dy = player.y - chestLootingStartY
        local distMoved = math.sqrt(dx*dx + dy*dy)
        if distMoved > 5 then
            cancelChestLooting(true)
            return false
        end
        return true
    end

    if chestMovementTimer then timer.cancel(chestMovementTimer) end
    chestMovementTimer = timer.performWithDelay(100, function()
        if not chestLootingActive then
            if chestMovementTimer then timer.cancel(chestMovementTimer); chestMovementTimer = nil end
            return
        end
        if not checkMovement() then
            if chestMovementTimer then timer.cancel(chestMovementTimer); chestMovementTimer = nil end
            return
        end
    end, 0)

    chestProgressTransition = transition.to(chestProgressFill, {
        width = barWidth,
        time = duration * 1000,
        onComplete = function()
            if not chestLootingActive then return end
            if not checkMovement() then return end

            if chestMovementTimer then timer.cancel(chestMovementTimer); chestMovementTimer = nil end

            chestProgressFill:setFillColor(0, 1, 0)
            timer.performWithDelay(300, function()
                if not activeChest or activeChest.isOpened or not chestLootingActive then
                    cancelChestLooting(false)
                    return
                end

                local items = {}
                for i = 1, 3 do
                    local r = math.random(1, 100)
                    local cumulative = 0
                    for _, loot in ipairs(chestLootTypes) do
                        cumulative = cumulative + loot.chance
                        if r <= cumulative then
                            local value = math.random(loot.min, loot.max)
                            table.insert(items, {
                                type = loot.type,
                                label = loot.label,
                                weapon = loot.weapon,
                                value = value
                            })
                            break
                        end
                    end
                end

                for idx, item in ipairs(items) do
                    giveLootFromChest(item, idx - 1)
                end

                activeChest.isOpened = true

                transition.to(activeChest.group, {
                    time = 300,
                    alpha = 0.6,
                    xScale = activeChest.group.xScale * 0.85,
                    yScale = activeChest.group.yScale * 0.85
                })
                if activeChest.group.body then activeChest.group.body:setFillColor(0.3, 0.2, 0.1) end
                if activeChest.group.lid then activeChest.group.lid:setFillColor(0.4, 0.3, 0.2) end
                if activeChest.group.lock then activeChest.group.lock:setFillColor(0.5, 0.5, 0.5) end

                for i, icon in ipairs(minimapChestIcons) do
                    if icon.chestRef == activeChest.group then
                        safeRemove(icon)
                        table.remove(minimapChestIcons, i)
                        break
                    end
                end

                if activeChest.hitBox then
                    activeChest.hitBox.type = "opened_chest"
                end

                cancelChestLooting(false)
            end)
        end
    })
end

local function openChest(chest)
    startChestLooting(chest)
end

local function createNPC(npcType, x, y)
    local npc = display.newGroup()
    mainGroup:insert(npc)
    npc.x, npc.y = x, y

    local data = npcTypes[npcType]
    npc.body = display.newRect(npc, 0, -20, 40, 40)
    npc.body:setFillColor(unpack(data.color))
    npc.type = "npc"
    npc.npcType = npcType
    npc.hp = data.hp
    npc.maxHp = data.hp
    npc.name = data.name

    -- Имя над NPC
    npc.nameText = display.newText(mainGroup, data.name, x, y - 60, native.systemFontBold, 14)
    npc.nameText:setFillColor(1, 1, 1)

    -- Полоска здоровья
    npc.hpBg = display.newRoundedRect(mainGroup, x, y - 55, 50, 8, 3)
    npc.hpBg:setFillColor(0,0,0,0.5)
    npc.hpFill = display.newRoundedRect(mainGroup, x - 25, y - 80, 50, 8, 3)
    npc.hpFill:setFillColor(0,1,0,0.8)
    npc.hpFill.anchorX = 0
    npc.hpText = display.newText(mainGroup, npc.hp .. "/" .. npc.maxHp, x, y - 80, native.systemFontBold, 10)
    npc.hpText:setFillColor(1,1,1)

    physics.addBody(npc, "static", { radius = 40 })
    npc.isFixedRotation = true

    table.insert(npcs, npc)
    return npc
end

local function createElevator(x, y, row, col)
    local floor = display.newImageRect(mainGroup, "assets/floor/floor.png", tileSize, tileSize)
    floor.x = x
    floor.y = y
    floor:toBack()

    local group = display.newGroup()
    mainGroup:insert(group)
    group.x, group.y = x, y

    local frame = display.newRect(group, 0, -10, tileSize * 0.72, tileSize * 0.88)
    frame:setFillColor(0.22, 0.22, 0.28)
    frame.strokeWidth = 3
    frame:setStrokeColor(0.45, 0.45, 0.5)

    local doorL = display.newRect(group, -16, -10, 24, 72)
    doorL:setFillColor(0.34, 0.34, 0.38)
    local doorR = display.newRect(group, 16, -10, 24, 72)
    doorR:setFillColor(0.34, 0.34, 0.38)

    local glow = display.newRect(group, 0, -10, tileSize * 0.78, tileSize * 0.92)
    glow:setFillColor(0.2, 0.9, 0.25)
    glow.alpha = 0
    glow.blendMode = "add"

    local indicator = display.newRect(group, 0, -58, 22, 8)
    indicator:setFillColor(0.55, 0.12, 0.12)

    group.y_sort = y
    group.type = "elevator"

    elevator = {
        group = group,
        frame = frame,
        doorL = doorL,
        doorR = doorR,
        glow = glow,
        indicator = indicator,
        x = x,
        y = y,
        row = row,
        col = col
    }
end

local function createFog()
    if fogGroup then
        display.remove(fogGroup)
        fogGroup = nil
    end
    fogTiles = {}
    fogGroup = display.newGroup()
    mainGroup:insert(fogGroup)
    fogGroup:toFront()

    for row = 1, #map do
        fogTiles[row] = {}
        for col = 1, #map[row] do
            if map[row][col] ~= 1 then
                local x = (col - 1) * tileSize + tileSize/2
                local y = (row - 1) * tileSize + tileSize/2
                local rect = display.newRect(fogGroup, x, y, tileSize, tileSize)
                rect:setFillColor(0, 0, 0, 0.7)
                rect.alpha = 0.7
                rect.currentAlpha = 0.7
                rect.targetAlpha = 0.7
                fogTiles[row][col] = rect
            else
                fogTiles[row][col] = nil
            end
        end
    end
end
local function createMap()
    spawnerPoints = {}
    mapWidth = #map[1] * tileSize
    mapHeight = #map * tileSize
    for row = 1, #map do
        for col = 1, #map[row] do
            local x = (col-1)*tileSize + tileSize/2
            local y = (row-1)*tileSize + tileSize/2

            if map[row][col] == 1 then
                local shadow = display.newRect(mainGroup, x, y+15, tileSize, tileSize)
                shadow:setFillColor(0,0,0,0.2)
                shadow:toBack()
                local wallGroup = display.newGroup()
                mainGroup:insert(wallGroup)
                wallGroup.x, wallGroup.y = x, y
                local facade = display.newImageRect(wallGroup, "assets/wall/facade.png", tileSize, 50)
                facade.fill.filterMag = "nearest" -- Для увеличения
                facade.fill.filterMin = "nearest"
                facade.x, facade.y = 0, 30
                facade:setFillColor(0.8, 0.8, 0.8)
                local wallVisual = display.newRect(wallGroup, 0, -35, tileSize, tileSize)
                wallGroup.y_sort = y
                wallGroup.type = "wall"
                wallVisual:setFillColor(0.17, 0.17, 0.19)
                table.insert(walls, wallGroup)

                local hitBox = display.newRect(mainGroup, x, y - 15, tileSize, 140)
                physics.addBody(hitBox, "static", { bounce = 0, friction = 1 })
                hitBox.alpha = 0
                hitBox.type = "wall_phys"

                local wx = (x / mapWidth) * minimapSize
                local wy = (y / mapHeight) * minimapSize
                local wallIcon = display.newRect(minimapGroup, 10 + wx, 10 + wy,
                    math.max(2, minimapSize / #map[1]),
                    math.max(2, minimapSize / #map))
                wallIcon:setFillColor(0.5,0.5,0.5)
                            elseif map[row][col] == 10 then  -- газовый баллон (используйте 10 или любой свободный номер)
                local floor = display.newImageRect(mainGroup, "assets/floor/floor.png", tileSize, tileSize)
                floor.x = x
                floor.y = y
                floor:toBack()
                createGasCanister(x, y, row, col)
            elseif map[row][col] == 3 or map[row][col] == 7 or map[row][col] == 5 then
                if map[row][col] == 7 and currentLevelKey == "main_door" then
                    playerSpawnFromMap = {x = x, y = y-125}
                end
                local shadow = display.newRect(mainGroup, x, y+57.5, tileSize, 15)
                shadow:setFillColor(0,0,0,0.2)
                shadow:toBack()
                local floor = display.newImageRect(mainGroup, "assets/floor/floor.png", tileSize, tileSize)
                floor.x = x
                floor.y = y
                floor:toBack()
                local doorGroup = display.newGroup()
                mainGroup:insert(doorGroup)
                doorGroup.x, doorGroup.y = x, y-5

                local doorUpVisual = display.newRect(doorGroup, 0, 10, tileSize, 20)
                doorUpVisual:setFillColor(0.22,0.20,0.28)
                doorUpVisual.strokeWidth = 2
                doorUpVisual:setStrokeColor(0.35,0.25,0.15)
                doorUpVisual:toFront()

                local doorTop = display.newRect(doorGroup, 0, 40, tileSize, 40)
                doorTop:setFillColor(0.22,0.20,0.28)

                local frame = display.newRect(doorGroup, 0, 40, tileSize, 40)
                frame:setFillColor(0,0,0,0)
                frame.strokeWidth = 2
                frame:setStrokeColor(0.38,0.28,0.18)

                local panel = display.newRect(doorGroup, 0, 41, tileSize*0.55, 50*0.7)
                panel:setFillColor(0.16,0.14,0.20)
                panel.strokeWidth = 2
                panel:setStrokeColor(0.35,0.25,0.15)
                local handleX = (map[row][col] == 5) and -tileSize*0.22 or tileSize*0.22
                local handle = display.newRect(doorGroup, handleX, 40, 4, 10)
                handle:setFillColor(0.75,0.55,0.15)

                doorGroup.y_sort = y
                doorGroup.type = "door"

                local hitBox = display.newRect(mainGroup, x, y+tileSize/2, tileSize, tileSize/1.5)
                physics.addBody(hitBox, "static", { bounce = 0, friction = 1 })
                hitBox.alpha = 0
                hitBox.shadow = shadow
                hitBox.type = "door_phys"
                hitBox.hp = doorTypes.base.hp
                hitBox.doorGroup = doorGroup
                hitBox.row = row
                hitBox.col = col
                hitBox.tileType = map[row][col]   -- запоминаем исходный тайл (3 или 5)

                table.insert(doors, {
                    row = row,
                    col = col,
                    group = doorGroup,
                    hitBox = hitBox,
                    isOpen = false,
                    x = x,
                    y = y+25,
                    tileType = map[row][col]      -- сохраняем в структуру двери
                })

                local wx = (x / mapWidth) * minimapSize
                local wy = (y / mapHeight) * minimapSize
                local doorIcon = display.newRect(minimapGroup, 10 + wx, 10 + wy,
                    math.max(2, minimapSize / #map[1]),
                    math.max(2, minimapSize / #map))
                doorIcon:setFillColor(0.75,0.55,0.15)

            elseif map[row][col] == 4 then
                local floor = display.newImageRect(mainGroup, "assets/floor/floor.png", tileSize, tileSize)
                floor.x = x
                floor.y = y
                floor:toBack()

                local chestGroup = display.newGroup()
                mainGroup:insert(chestGroup)
                chestGroup.x, chestGroup.y = x, y

                local chestWidth = tileSize * 0.6
                local chestHeight = tileSize * 0.5
                local chestBody = display.newRect(chestGroup, 0, 0, chestWidth, chestHeight)
                chestBody:setFillColor(0.6, 0.4, 0.2)
                chestGroup.body = chestBody
                chestGroup.y_sort = y
                chestGroup.type = "chest"

                local hitBox = display.newRect(mainGroup, x, y, chestWidth, chestHeight)
                physics.addBody(hitBox, "static", { bounce = 0, friction = 1 })
                hitBox.alpha = 0
                hitBox.type = "chest_hit"
                hitBox.chestRef = chestGroup

                table.insert(chests, {
                    group = chestGroup,
                    hitBox = hitBox,
                    isOpened = false,
                    x = x,
                    y = y
                })

                local wx = (x / mapWidth) * minimapSize
                local wy = (y / mapHeight) * minimapSize
                local chestIcon = display.newRect(minimapGroup, 10 + wx, 10 + wy, 4, 4)
                chestIcon:setFillColor(1, 0.8, 0)
                chestIcon.chestRef = chestGroup
                table.insert(minimapChestIcons, chestIcon)

            elseif map[row][col] == 2 then
                local floor = display.newImageRect(mainGroup, "assets/floor/floor.png", tileSize, tileSize)
                floor:setFillColor(1, 0.8, 0.8)
                floor.x = x
                floor.y = y
                floor:toBack()
                local hatch = display.newRect(mainGroup, x, y, tileSize*0.7, tileSize*0.7)
                hatch:setFillColor(0.2,0.2,0.2)
                hatch.strokeWidth = 3
                hatch:setStrokeColor(0.4,0.2,0.2)
                hatch:toBack()
                table.insert(spawnerPoints, {x = x, y = y})
            elseif map[row][col] == 8 then
                createElevator(x, y, row, col)
                if map[row][col] == 8 and currentLevelKey ~= "main_door" then
                    playerSpawnFromMap = {x = x, y = y+100}
                end
            elseif map[row][col] == 9 then
                local floor = display.newImageRect(mainGroup, "assets/floor/floor.png", tileSize, tileSize)
                floor.x = x
                floor.y = y
                floor:toBack()
                createNPC("trader", x, y)
            elseif map[row][col] == 6 then
            else
                local floor = display.newImageRect(mainGroup, "assets/floor/floor.png", tileSize, tileSize)
                floor.x = x
                floor.y = y
                floor:toBack()
            end
            if currentLevelKey == "admin_test" then
                local tileText = display.newText(mainGroup, tostring(map[row][col]), x, y, native.systemFontBold, 17)
                tileText:setFillColor(1, 0.8, 0.8)
            end
        end
    end
    -- Связываем парные двери (стоящие рядом по горизонтали или вертикали)
for i = 1, #doors do
    local d = doors[i]
    if not d.pairedDoor then
        local neighbors = {
            {r = d.row, c = d.col + 1},   -- справа
            {r = d.row + 1, c = d.col}    -- снизу
        }
        for _, nb in ipairs(neighbors) do
            if map[nb.r] and map[nb.r][nb.c] and (map[nb.r][nb.c] == 3 or map[nb.r][nb.c] == 5) then
                for j = 1, #doors do
                    if doors[j].row == nb.r and doors[j].col == nb.c and not doors[j].pairedDoor then
                        d.pairedDoor = doors[j]
                        doors[j].pairedDoor = d
                        break
                    end
                end
            end
        end
    end
end
end



local function updateLayers()
    local items = {}
    if player and player.x then
        player.y_sort = player.y
        table.insert(items, player)
    end
    for _, n in ipairs(npcs) do
        if n and n.x then
            n.y_sort = n.y
            table.insert(items, n)
        end
    end
    for _, e in ipairs(enemies) do
        if e and e.x then
            e.y_sort = e.y
            table.insert(items, e)
        end
    end
    for _, w in ipairs(walls) do
        if w and w.x then
            w.y_sort = w.y
            table.insert(items, w)
        end
    end
    for _, d in ipairs(doors) do
        if d.group and d.group.x then
            d.group.y_sort = d.group.y
            table.insert(items, d.group)
        end
    end
    for _, c in ipairs(chests) do
        if c.group and c.group.x then
            c.group.y_sort = c.group.y
            table.insert(items, c.group)
        end
    end
    table.sort(items, function(a,b) return a.y_sort < b.y_sort end)
    for _, obj in ipairs(items) do obj:toFront() end
    if ui then ui:toFront() end
end

local function resumeGame()
    if not isPaused then return end
    isPaused = false
    if pauseGroup then
        if pauseGroup._mouseListener then
            Runtime:removeEventListener("mouse", pauseGroup._mouseListener)
        end
        safeRemove(pauseGroup)
        pauseGroup = nil
    end
    pauseMenuItems = {}
end

local function pauseGame()
    if isPaused or isDead then return end
    isPaused = true
    -- Остановка игрока
if player then
    player:setLinearVelocity(0, 0)
end
-- Сброс всех состояний движения/стрельбы
move.up, move.down, move.left, move.right = false, false, false, false
isRunning, isCrouching, isDashing = false, false, false
isShooting, isAiming = false, false
cancelBurst()
    for _, z in ipairs(enemies) do
        if z and z.x then
            z:setLinearVelocity(0, 0)
            z.isAttacking = false
        end
    end
    if chestLootingActive then
        cancelChestLooting(false)
    end
    cancelBurst()

    if pauseGroup then return end
    pauseGroup = display.newGroup()
    scene.view:insert(pauseGroup)

    local bg = display.newRect(pauseGroup, display.contentCenterX, display.contentCenterY, display.actualContentWidth, display.actualContentHeight)
    bg:setFillColor(0,0,0,0.7)

    local startY = display.contentCenterY - 40
    local buttons = {
        { text = "ПРОДОЛЖИТЬ", action = function() resumeGame() end },
        { text = "ВЫЙТИ", action = function()
            transition.to(scene.view, { time = 500, alpha = 0, onComplete = function()
                composer.removeScene("game")
                composer.gotoScene("levels", { effect = "fade", time = 500 })
            end})
        end }
    }

    for i, btn in ipairs(buttons) do
        local y = startY + (i-1) * 70
        local txt = display.newText({
            parent = pauseGroup,
            text = btn.text,
            x = display.contentCenterX, y = y,
            font = native.systemFontBold, fontSize = 34
        })
        txt:setFillColor(0.9, 0.9, 0.9)

        local underline = display.newLine(pauseGroup, display.contentCenterX - txt.width/2, y + 20, display.contentCenterX + txt.width/2, y + 20)
        underline:setStrokeColor(1, 0.5, 0.5)
        underline.strokeWidth = 2
        underline.alpha = 0

        local item = { text = txt, underline = underline, action = btn.action, isHovered = false }
        table.insert(pauseMenuItems, item)

        txt:addEventListener("touch", function(e)
            if e.phase == "ended" then
                item.action()
            end
            return true
        end)
    end

    local function onMouseMove(e)
        for _, item in ipairs(pauseMenuItems) do
            local txt = item.text
            if txt and txt.contentBounds then
                local b = txt.contentBounds
                local isHover = (e.x >= b.xMin and e.x <= b.xMax and e.y >= b.yMin and e.y <= b.yMax)

                if isHover and not item.isHovered then
                    item.isHovered = true
                    transition.to(txt, { time = 150, xScale = 1.1, yScale = 1.1 })
                    if item.underline then transition.to(item.underline, { time = 150, alpha = 1 }) end
                elseif not isHover and item.isHovered then
                    item.isHovered = false
                    transition.to(txt, { time = 150, xScale = 1, yScale = 1 })
                    if item.underline then transition.to(item.underline, { time = 150, alpha = 0 }) end
                end
            end
        end
    end

    Runtime:addEventListener("mouse", onMouseMove)
    pauseGroup._mouseListener = onMouseMove
end

local modeText = nil

local function startLevel()

    local view = scene.view
    local level = currentLevelConfig or getLevelConfig(currentLevelKey)
    -- в startLevel, после получения level
   local data = save.loadPlayerData()
    completedLevels = data.completed or {}
    replayedLevels = data.replayed or {}
    brainPieces = data.brains or 0
    medkits = data.medkits or 0
    energyDrinks = data.energy or 0
    grenades = data.grenades or 0
    local firstRun = data.firstRun or 0
    _G.firstRun = firstRun
    map = cloneMap(level.map)
    physics.start()
    physics.setGravity(0, 0)

    -- Инициализация тумана войны
explored = {}
for row = 1, #map do
    explored[row] = {}
    for col = 1, #map[row] do
        explored[row][col] = false
    end
end
    isDead = false
    levelWon = false
    zombiesSpawned = 0
    allZombiesSpawned = false
     local isCompleted = completedLevels[currentLevelKey]
    local isReplayed = replayedLevels[currentLevelKey]

    if isCompleted and not isReplayed then
        levelMaxZombies = level.maxZombies
    elseif isCompleted and isReplayed then
        levelMaxZombies = 4
        allZombiesSpawned = true
    else
        levelMaxZombies = level.maxZombies
    end
    hp = stats.maxHp
    energy = stats.maxEnergy
    killsCount = 0
    
        if firstRun == 0 then
        medkits = medkits + 2
        energyDrinks = energyDrinks + 1
        grenades = grenades + 3
        firstRun = 1  -- помечаем, что стартовые бусты уже выданы
        _G.firstRun = 1  -- обновляем глобальную переменную
        save.savePlayerData(brainPieces)
    end
    isReloading = false
    isShooting = false
    isRunning = false
    isCrouching = false
    isDashing = false
    isAiming = false
    lastBulletTime = 0
    aimStartTime = 0
    frameCounter = 0
    frameCounter = 0
    lastFrameTime = system.getTimer()
    fpsAccum = 0
    fpsFrames = 0
    displayFPS = 60
    fireRateMultiplier = 1.0
    reloadSpeedMultiplier = 1.0
    if fireRateTimer then timer.cancel(fireRateTimer); fireRateTimer = nil end
    energyBoostActive = false
    originalMaxEnergy = stats.maxEnergy
    rapidEndTime = nil
    enemies = {}
    walls = {}
    doors = {}
    chests = {}
    minimapChestIcons = {}
    activeTimers = {}
    isPaused = false
    if pauseGroup then resumeGame() end
    if doorHint then safeRemove(doorHint); doorHint = nil end
    if elevatorHint then safeRemove(elevatorHint); elevatorHint = nil end
    elevator = nil
    elevatorActive = false
    elevatorSequenceDone = false
    elevatorCutsceneActive = false
    lastRegenTime = nil
    mainGroup = display.newGroup()
    view:insert(mainGroup)
    mainGroup.alpha = 0
    lightGroup = display.newGroup()
    mainGroup:insert(lightGroup)
    lightGroup:toFront()
    statsBrainValue = brainValue
    statsKillsValue = killsValue
    updateBrainDisplay()
    damageTextGroup = display.newGroup()
    mainGroup:insert(damageTextGroup)
    damageTextGroup:toFront()
    ui = display.newGroup()
    view:insert(ui)
    ui.alpha = 0
    minimapGroup = display.newGroup()
    ui:insert(minimapGroup)
    minimapGroup.x = display.safeScreenOriginX
    minimapGroup.y = display.safeScreenOriginY
    local minimapBg = display.newRect(minimapGroup, 0, 0, minimapSize, minimapSize)
    minimapBg:setFillColor(0,0,0,0.7)
    minimapBg.x, minimapBg.y = 10, 10
    minimapBg.anchorX, minimapBg.anchorY = 0, 0
    local minimapBorder = display.newRect(minimapGroup, 10, 10, minimapSize, minimapSize)
    minimapBorder:setFillColor(0,0,0,0)
    minimapBorder.strokeWidth = 2
    minimapBorder:setStrokeColor(1,1,1)
    minimapBorder:setStrokeColor(1, 0.5, 0.5)
    minimapBorder.anchorX, minimapBorder.anchorY = 0, 0

    minimapPlayerIcon = display.newCircle(minimapGroup, 0, 0, 4)
    minimapPlayerIcon:setFillColor(0,1,0)
    minimapZombieIcons = {}
    minimapLootIcons = {}
    createMap()
    createFog()
    updateExplored()
    -- Принудительно обновляем целевые альфы и применяем их без плавности
updateFogAlpha()
for row = 1, #map do
    for col = 1, #map[row] do
        local rect = fogTiles[row] and fogTiles[row][col]
        if rect then
            rect.alpha = rect.targetAlpha or 0.7
            rect.currentAlpha = rect.alpha
        end
    end
end
updateVisibility()
    player = display.newGroup()
    local spawnX = playerSpawnFromMap.x
    local spawnY = playerSpawnFromMap.y
    player.x, player.y = spawnX, spawnY
    mainGroup:insert(player)

    local sheetOptions = {
        width = 32,
        height = 32,
        numFrames = 6,
        sheetContentWidth = 32 * 6,
        sheetContentHeight = 32
    }
    local sheet = graphics.newImageSheet("assets/player/player_idle.png", sheetOptions)

    player.body = display.newSprite(player, sheet, {
        { name = "idle", start = 1, count = 6, time = 600, loopCount = 0 }
    })
    player.body.x = 0
    player.body.y = -15
    player.body.anchorX = 0.5
    player.body.anchorY = 0.5

    player.body:setSequence("idle")
    player.body:play()
    player.body.xScale = 1.5
    player.body.yScale = 1.5
    barrel = display.newRect(player, 15, -25, stats.currentWeapon.barrelLen or 20, 6)
    barrel:setFillColor(0.3,0.3,0.3)
    barrel.anchorX = 0
    player.type = "player"
    physics.addBody(player, "dynamic", { radius = 15 })
    player.isFixedRotation = true
    mainGroup.x = display.contentCenterX - player.x
    mainGroup.y = display.contentCenterY - player.y
    local bottomY = display.safeActualContentHeight - 30
    -- Таймер для пересчёта целевых альф (по флагу fogDirty)


-- Таймер для обновления видимых клеток (explored)
if exploredUpdateTimer then timer.cancel(exploredUpdateTimer) end
exploredUpdateTimer = timer.performWithDelay(150, function()
    updateExplored()
end, 0)-- После createFog() и updateExplored()
if fogUpdateTimer then timer.cancel(fogUpdateTimer) end
fogUpdateTimer = timer.performWithDelay(100, function()
    if enlightenmentActive then
        -- Если Просвещение активно, просто скрываем группу тумана
        if fogGroup then
            fogGroup.alpha = 0
            fogGroup.isVisible = false
        end
    else
        -- Восстанавливаем туман
        if fogGroup then
            fogGroup.alpha = 1
            fogGroup.isVisible = true
        end
        if fogDirty then
            updateFogAlpha()
        end
    end
end, 0)
-- После createMap() и createFog() и создания игрока
for _, door in ipairs(doors) do
    if door.group then
        door.group:toFront()
    end
end
    healthBarBack = display.newRoundedRect(ui, display.contentCenterX - 130, bottomY - 20, 120, 15, 6)
    healthBarBack:setFillColor(0.2,0.2,0.2,0.6)
    healthBarBack.anchorX = 0
    healthBarBack.strokeWidth = 2
    healthBarBack:setStrokeColor(1, 0.6, 0.6)

    healthBar = display.newRoundedRect(ui, display.contentCenterX - 130, bottomY - 20, 120, 15, 6)
    healthBar:setFillColor(1,0.2,0.2)
    healthBar.anchorX = 0

    energyBarBack = display.newRoundedRect(ui, display.contentCenterX + 10, bottomY - 20, 120, 15, 6)
    energyBarBack:setFillColor(0.2,0.2,0.2,0.6)
    energyBarBack.anchorX = 0
    energyBarBack.strokeWidth = 2
    energyBarBack:setStrokeColor(0.5, 0.85, 1)

    energyBar = display.newRoundedRect(ui, display.contentCenterX + 10, bottomY - 20, 120, 15, 6)
    energyBar:setFillColor(0,0.7,1)
    energyBar.anchorX = 0

    local extraX = energyBarBack.x + healthBarBack.width + 15
    local extraY = healthBarBack.y
    extraCooldownBarBack = display.newRoundedRect(ui, extraX, extraY, 10, 15, 3)
    extraCooldownBarBack:setFillColor(0.3,0.2,0.1,0.6)
    extraCooldownBarBack.strokeWidth = 2
    extraCooldownBarBack:setStrokeColor(1, 0.9, 0.5)

    extraCooldownBar = display.newRoundedRect(ui, extraX, extraY, 10, 15, 3)
    extraCooldownBar:setFillColor(1,0.8,0)
    extraCooldownBar.height = 15
        -- Индикатор типа экстра-навыка
    local extraNameText = display.newText({
        parent = ui,
        text = "ВОЛНА",
        x = extraCooldownBarBack.x + extraCooldownBarBack.width/2,
        y = extraCooldownBarBack.y - 18,
        font = native.systemFontBold,
        fontSize = 10
    })
    extraNameText:setFillColor(1, 0.9, 0.5)
    extraNameText.anchorX = 0.5
    
    -- Функция обновления имени экстра-навыка
    local function updateExtraName()
        if stats.currentExtra == playerExtras["shockWave"] then
            extraNameText.text = "ВОЛНА"
            extraNameText:setFillColor(1,0.8,0)
        elseif stats.currentExtra == playerExtras["enlightenment"] then
            extraNameText.text = "ПРОСВ"
            extraNameText:setFillColor(1,0.8,0)
        end
    end
    updateExtraName()
    
    -- Сохраняем ссылку для обновления при переключении
    _G.updateExtraName = updateExtraName
    local ultimateX = extraX + extraCooldownBarBack.width + 5
    ultimateCooldownBarBack = display.newRoundedRect(ui, ultimateX, extraY, 10, 15, 3)
    ultimateCooldownBarBack:setFillColor(0.4, 0, 0.6, 0.6)
    ultimateCooldownBarBack.strokeWidth = 2
    ultimateCooldownBarBack:setStrokeColor(0.9, 0.5, 1)

    ultimateCooldownBar = display.newRoundedRect(ui, ultimateX, extraY, 10, 15, 3)
    ultimateCooldownBar:setFillColor(0.8, 0, 1)
    ultimateCooldownBar.height = 15

    medkitIcon = display.newRect(ui, healthBarBack.x - 55, healthBarBack.y, 20, 20)
    medkitIcon:setFillColor(0,1,0)
    medkitIcon.alpha = 0
    -- Найдите в startLevel() блок создания UI элементов для экстра-навыка
-- После создания extraCooldownBarBack и extraCooldownBar, добавьте:

        -- ===== ИНДИКАТОР ВЫБРАННОЙ УЛЬТЫ (под шкалами) =====
    local ultimateNameY = extraCooldownBarBack.y + extraCooldownBarBack.height
    local ultimateNameText = display.newText({
        parent = ui,
        text = "НЕВИД.",
        x = extraCooldownBarBack.x + extraCooldownBarBack.width/2 + 3,
        y = ultimateNameY,
        font = native.systemFontBold,
        fontSize = 10
    })
    ultimateNameText:setFillColor(1, 1, 0)  -- Жёлтый цвет
    ultimateNameText.anchorX = 0.5
    
        -- Функция обновления имени ульты
    local function updateUltimateName()
        if stats.currentUltimate == playerUltimates["invisible"] then
            ultimateNameText.text = "НЕВИД"
            ultimateNameText:setFillColor(1, 1, 0)
        elseif stats.currentUltimate == playerUltimates["phase"] then
            ultimateNameText.text = "ФАЗА"
            ultimateNameText:setFillColor(1, 1, 0)
        end
    end
    updateUltimateName()
    -- Сохраняем ссылку для обновления при переключении
    _G.updateUltimateName = updateUltimateName
    medkitText = display.newText({
        parent = ui,
        text = "x0",
        x = medkitIcon.x + 10,
        y = medkitIcon.y + 10,
        font = native.systemFontBold,
        fontSize = 15
    })
    medkitText.alpha = 0
    medkitText:setFillColor(0.5,1,0)

    if medkits > 0 then
        medkitIcon.alpha = 1
        medkitText.alpha = 1
        medkitText.text = "x" .. medkits
    end

    energyIcon = display.newRect(ui, medkitIcon.x - 55, medkitIcon.y, 20, 20)
    energyIcon:setFillColor(1,1,0)
    energyIcon.alpha = 0

    energyText = display.newText({
        parent = ui,
        text = "x0",
        x = energyIcon.x + 10,
        y = energyIcon.y + 10,
        font = native.systemFontBold,
        fontSize = 15
    })
    energyText:setFillColor(1,1,0)
    energyText.alpha = 0

    if energyDrinks > 0 then
        energyIcon.alpha = 1
        energyText.alpha = 1
        energyText.text = "x" .. energyDrinks
    end

    grenadeIcon = display.newRect(ui, energyIcon.x - 55, energyIcon.y, 20, 20)
    grenadeIcon:setFillColor(1, 0.5, 0)
    grenadeIcon.alpha = 0

    grenadeText = display.newText({
        parent = ui,
        text = "x0",
        x = grenadeIcon.x + 10,
        y = grenadeIcon.y + 10,
        font = native.systemFontBold,
        fontSize = 15
    })
    grenadeText:setFillColor(1, 0.5, 0)
    grenadeText.alpha = 0

    if grenades > 0 then
        grenadeIcon.alpha = 1
        grenadeText.alpha = 1
        grenadeText.text = "x" .. grenades
    end

    ammoText = display.newText({
        parent = ui,
        text = stats.currentWeapon.currentClip .. " | " .. stats.currentWeapon.bullets,
        x = display.contentCenterX,
        y = bottomY - 50,
        font = native.systemFontBold,
        fontSize = 20
    })

    weaponNameText = display.newText({
        parent = ui,
        text = "Glock-17",
        x = display.contentCenterX,
        y = ammoText.y - 20,
        font = native.systemFontBold,
        fontSize = 20
    })

    fpsText = display.newText({
        parent = ui,
        text = "FPS: 60",
        x = display.actualContentWidth + display.screenOriginX - 70,
        y = display.screenOriginY + 20,
        font = native.systemFontBold,
        fontSize = 18
    })
    fpsText:setFillColor(0,1,0)
    fpsText.anchorX = 0

    rapidIndicator = display.newText({
        parent = ui,
        text = "",
        x = display.contentCenterX,
        y = energyBar.y - 120,
        font = native.systemFontBold,
        fontSize = 16
    })
    rapidIndicator:setFillColor(1, 0.5, 0)
    rapidIndicator.alpha = 0

    local statsPanel = display.newRoundedRect(ui,
        display.safeScreenOriginX + 10,
        minimapGroup.y + minimapSize + 20,
        120, 40, 10)
    statsPanel:setFillColor(0.05, 0.05, 0.1, 0.6)
    statsPanel.strokeWidth = 2
    statsPanel:setStrokeColor(1, 0.5, 0.5)
    statsPanel.anchorX = 0
    statsPanel.anchorY = 0

    local lineHeight = 18
    local startY = statsPanel.y - 5.5

    local brainIcon = display.newText({
        parent = ui,
        text = "🧠",
        x = statsPanel.x + 20,
        y = startY + lineHeight,
        font = native.systemFont,
        fontSize = 18
    })
    local brainValue = display.newText({
        parent = ui,
        text = tostring(brainPieces),
        x = statsPanel.x + statsPanel.width - 20,
        y = startY + lineHeight,
        font = native.systemFontBold,
        fontSize = 16
    })
    brainValue:setFillColor(1, 0.8, 0.6)
    brainValue.anchorX = 1

    local killsIcon = display.newText({
        parent = ui,
        text = "💀",
        x = statsPanel.x + 20,
        y = startY + lineHeight * 2,
        font = native.systemFont,
        fontSize = 18
    })
    local killsValue = display.newText({
        parent = ui,
        text = "0/" .. tostring(levelMaxZombies),
        x = statsPanel.x + statsPanel.width - 20,
        y = startY + lineHeight * 2,
        font = native.systemFontBold,
        fontSize = 16
    })
    killsValue:setFillColor(1, 1, 1)
    killsValue.anchorX = 1

    statsBrainValue = brainValue
    statsKillsValue = killsValue

    modeText = display.newText({
        parent = ui,
        text = "AUTO",
        x = weaponNameText.x,
        y = weaponNameText.y - 25,
        font = native.systemFontBold,
        fontSize = 16
    })
    modeText:setFillColor(1, 1, 0.5)
    ui:toFront()
    -- ============================================================
    -- ИЗМЕНЕНИЕ: запускаем спавн зомби ДО того, как мир станет видимым
    -- ============================================================
    local function spawnTick()
        if isDead or levelWon then return end
        if isPaused then
            local t = timer.performWithDelay(100, spawnTick)
            table.insert(activeTimers, t)
            return
        end
        if zombiesSpawned < levelMaxZombies and #spawnerPoints > 0 then
            local p = spawnerPoints[math.random(#spawnerPoints)]
            local rName
if FORCE_ZOMBIE_TYPE and zombieTypes[FORCE_ZOMBIE_TYPE] then
    rName = FORCE_ZOMBIE_TYPE
else
    -- Получаем разрешённые типы из конфига уровня
    local allowed = currentLevelConfig.allowedZombies
    local pool = {}
    if allowed and #allowed > 0 then
        -- Если список задан, используем только его
        for _, name in ipairs(allowed) do
            local data = zombieTypes[name]
            if data then
                for i = 1, data.weight do
                    table.insert(pool, name)
                end
            end
        end
    else
        -- Иначе все типы
        for name, data in pairs(zombieTypes) do
            for i = 1, data.weight do
                table.insert(pool, name)
            end
        end
    end
    if #pool > 0 then
        rName = pool[math.random(#pool)]
    else
        rName = "zombie"  -- fallback
    end
end
            spawnZombie(zombieTypes[rName], rName, p.x, p.y)
            zombiesSpawned = zombiesSpawned + 1
        end
        if zombiesSpawned >= levelMaxZombies then
            allZombiesSpawned = true
        end
        if allZombiesSpawned and #enemies == 0 then
            checkLevelComplete()
            return
        end
        if zombiesSpawned < levelMaxZombies then
            local delayRange = (currentLevelConfig and currentLevelConfig.spawnDelay) or {3500, 7000}
            local t = timer.performWithDelay(math.random(delayRange[1], delayRange[2]), spawnTick)
            table.insert(activeTimers, t)
        end
    end
        -- Отложенный показ игры (будет вызван из scene:show после загрузки)
    -- Принудительно обновляем туман перед показом
    updateFogAlpha()
    for row = 1, #map do
        for col = 1, #map[row] do
            local rect = fogTiles[row] and fogTiles[row][col]
            if rect then
                rect.alpha = rect.targetAlpha or 0.7
                rect.currentAlpha = rect.alpha
            end
        end
    end

    updateVisibility()
        _G.showGame = function()
    -- Принудительно обновляем угол ствола до начала анимации
    if player and player.body and barrel then
        local mx, my = mainGroup:contentToLocal(mouseX, mouseY)
        local angleRad = math.atan2(my - (player.y - 20), mx - player.x)
        currentAimAngle = angleRad
        barrel.rotation = math.deg(angleRad)
        -- Также обновляем масштаб спрайта (по умолчанию)
        local baseScale = 1.5
        local crouchFactor = 1.0
        local mirror = (mx < player.x) and -1 or 1
        player.body.xScale = baseScale * mirror
        player.body.yScale = baseScale * crouchFactor
        player.body.alpha = 1.0
        -- Позиция ствола относительно игрока
        barrel.x = math.cos(angleRad) * 25
        barrel.y = -20 + math.sin(angleRad) * 15
    end

    transition.to(mainGroup, { time = 700, alpha = 1 })
    transition.to(ui, { time = 1500, alpha = 0.5, onComplete = function()
        gameStarted = true
        spawnTick()
    end})
end
    end

local function updateFireModeDisplay()
    local weapon = stats.currentWeapon
    if weapon.name == "AK-47" then
        if weapon.burstModeEnabled then
            modeText.text = "BURST 3"
            modeText:setFillColor(0, 1, 0.5)
        else
            modeText.text = "AUTO"
            modeText:setFillColor(1, 1, 0.5)
        end
        modeText.alpha = 1
    else
        modeText.alpha = 0
    end
end

closeTraderMenu = function()
    if traderMenuGroup then
        safeRemove(traderMenuGroup)
        traderMenuGroup = nil
        traderMenuActive = false
        isPaused = false
    end
end

local function createTraderMenu(trader)
    if traderMenuActive or isDead then return end
    traderMenuActive = true
    isPaused = true  -- ставим игру на паузу

    traderMenuGroup = display.newGroup()
    scene.view:insert(traderMenuGroup)

    -- Затемнённый фон
    local bg = display.newRect(traderMenuGroup, display.contentCenterX, display.contentCenterY,
        display.actualContentWidth, display.actualContentHeight)
    bg:setFillColor(0, 0, 0, 0.7)

    -- Основная панель (как в статистике)
    local panelWidth = 320
    local panelHeight = 450
    local panelX = display.contentCenterX
    local panelY = display.contentCenterY
    local panel = display.newRoundedRect(traderMenuGroup, panelX, panelY, panelWidth, panelHeight, 15)
    panel:setFillColor(0.05, 0.05, 0.1, 0.85)
    panel.strokeWidth = 3
    panel:setStrokeColor(1, 0.8, 0.2)

    -- Заголовок
    local title = display.newText({
        parent = traderMenuGroup,
        text = "ТРЕЙДЕР",
        x = panelX,
        y = panelY - panelHeight/2 + 30,
        font = native.systemFontBold,
        fontSize = 26
    })
    title:setFillColor(1, 0.8, 0.2)

    -- Отображение мозгов
    traderMenuBrainText = display.newText({
        parent = traderMenuGroup,
        text = "МОЗГИ: " .. brainPieces,
        x = panelX,
        y = panelY - panelHeight/2 + 65,
        font = native.systemFontBold,
        fontSize = 20
    })
    traderMenuBrainText:setFillColor(1, 0.8, 0.6)

    -- Разделитель
    local line = display.newLine(traderMenuGroup, panelX - panelWidth/2 + 20, panelY - panelHeight/2 + 80,
        panelX + panelWidth/2 - 20, panelY - panelHeight/2 + 80)
    line:setStrokeColor(0.5, 0.5, 0.5, 0.5)
    line.strokeWidth = 1

    -- Создаём список предметов
    local startY = panelY - panelHeight/2 + 110
    local itemHeight = 30
    local buttonWidth = 80
    local buttonHeight = 24

    for i, item in ipairs(shopItems) do
        local yPos = startY + (i-1) * itemHeight

        -- Название предмета
        local nameText = display.newText({
            parent = traderMenuGroup,
            text = item.name,
            x = panelX - 120,
            y = yPos,
            font = native.systemFont,
            fontSize = 16,
            width = 180
        })
        nameText:setFillColor(1, 1, 1)
        nameText.anchorX = 0

        -- Цена
        local costText = display.newText({
            parent = traderMenuGroup,
            text = item.cost .. "🧠",
            x = panelX + 150,
            y = yPos,
            font = native.systemFontBold,
            fontSize = 16
        })
        costText:setFillColor(1, 0.9, 0.3)
        costText.anchorX = 1

        -- Кнопка "КУПИТЬ"
        local btn = display.newRoundedRect(traderMenuGroup, panelX + 70, yPos, buttonWidth, buttonHeight, 6)
        btn:setFillColor(0.3, 0.3, 0.4)
        btn.strokeWidth = 1
        btn:setStrokeColor(1, 0.8, 0.2)

        local btnText = display.newText({
            parent = traderMenuGroup,
            text = "КУПИТЬ",
            x = btn.x,
            y = btn.y,
            font = native.systemFontBold,
            fontSize = 14
        })
        btnText:setFillColor(1, 1, 1)

        -- Сохраняем ссылки в таблицу кнопки для обработки наведения и клика
        btn.item = item
        btn.cost = item.cost
        btn.btnText = btnText
        btn.costText = costText
        btn.nameText = nameText

        function btn:touch(e)
            if e.phase == "began" then
                self:setFillColor(0.5, 0.5, 0.6)
                return true
            elseif e.phase == "ended" then
                self:setFillColor(0.3, 0.3, 0.4)
                local success, err = pcall(function()
                    if brainPieces >= self.cost then
                        brainPieces = brainPieces - self.cost
                        statsBrainValue.text = tostring(brainPieces)
                        self.item.action()
                        updateBrainDisplay()
                        save.savePlayerData(brainPieces)
                        local data = save.loadPlayerData()
            medkits = data.medkits or 0
            energyDrinks = data.energy or 0
            grenades = data.grenades or 0
            updateMedkitUI()
            updateEnergyUI()
            updateGrenadeUI()
                        -- Анимация успешной покупки
                        transition.to(self.btnText, { time = 150, xScale = 1.2, yScale = 1.2,
                            onComplete = function() transition.to(self.btnText, { time = 150, xScale = 1, yScale = 1 }) end })
                    else
                        showWarning("Недостаточно мозгов!", 1500)
                        -- Мигание красным
                        transition.to(self.btnText, { time = 100, xScale = 1.2, yScale = 1.2 })
                        transition.to(self.btnText, { time = 100, delay = 100, xScale = 1, yScale = 1 })
                    end
                end)
                if not success then print("Ошибка покупки: " .. tostring(err)) end
                return true
            elseif e.phase == "moved" then
                local b = self.contentBounds
                if e.x >= b.xMin and e.x <= b.xMax and e.y >= b.yMin and e.y <= b.yMax then
                    self:setFillColor(0.5, 0.5, 0.6)
                else
                    self:setFillColor(0.3, 0.3, 0.4)
                end
            end
        end

        btn:addEventListener("touch", btn)

        -- Эффект наведения мыши
        function btn:mouse(e)
            if e.type == "enter" then
                self:setFillColor(0.5, 0.5, 0.6)
            elseif e.type == "exit" then
                self:setFillColor(0.3, 0.3, 0.4)
            end
            return true
        end
        btn:addEventListener("mouse", btn)
    end

    -- Кнопка закрытия (крестик)
    local closeBtn = display.newText({
        parent = traderMenuGroup,
        text = "✕",
        x = panelX + panelWidth/2 - 20,
        y = panelY - panelHeight/2 + 20,
        font = native.systemFontBold,
        fontSize = 24
    })
    closeBtn:setFillColor(1, 0.3, 0.3)

    function closeBtn:touch(e)
        if e.phase == "ended" then
            closeTraderMenu()
        end
        return true
    end
    closeBtn:addEventListener("touch", closeBtn)

    -- Закрытие по Escape
    local function onKeyClose(e)
        if e.keyName == "escape" and e.phase == "down" then
            closeTraderMenu()
            Runtime:removeEventListener("key", onKeyClose)
        end
    end
    Runtime:addEventListener("key", onKeyClose)
    traderMenuGroup.closeListener = onKeyClose
end

local function switchWeapon(name)
    cancelBurst()

    if not weapons[name] then return end
    if stats.currentWeapon and stats.currentWeapon.isReloading then
        if stats.currentWeapon.reloadTimer then
            timer.cancel(stats.currentWeapon.reloadTimer)
            stats.currentWeapon.reloadTimer = nil
        end
        stats.currentWeapon.isReloading = false
        stats.currentWeapon.reloadStartTime = nil
    end
    stats.currentWeapon = weapons[name]
    weaponNameText.text = name
    ammoText.text = stats.currentWeapon.currentClip .. " | " .. stats.currentWeapon.bullets
    if barrel then barrel.width = stats.currentWeapon.barrelLen or 16 end
    updateFireModeDisplay()
end





local function damageNPC(npc, bullet)
    local dmg = bullet.dmg or 0
    npc.hp = npc.hp - dmg

    local ratio = math.max(0, npc.hp / npc.maxHp)
    if npc.hpFill then
        npc.hpFill.width = 50 * ratio
        npc.hpFill.x = npc.x - 25 + (npc.hpFill.width / 2)
    end
    if npc.hpText then
        npc.hpText.text = math.floor(npc.hp) .. "/" .. npc.maxHp
    end

    bloodParticles(npc.x, npc.y, "enemy", mainGroup)

    if npc.hp <= 0 then
        safeRemove(npc.nameText)
        safeRemove(npc.hpBg)
        safeRemove(npc.hpFill)
        safeRemove(npc.hpText)
        safeRemove(npc)
        for i, n in ipairs(npcs) do
            if n == npc then table.remove(npcs, i) break end
        end
        bloodPoolParticles(npc.x, npc.y, "enemy", mainGroup)
    end
end
local function onCollision(e)
    if isPaused then return end
    if e.phase ~= "began" then return end
    local a, b = e.object1, e.object2
    if not (a and b and a.x and b.x) then return end
        if (a.type == "player_phasing" and b.type == "wall_phys") or
       (b.type == "player_phasing" and a.type == "wall_phys") then
        return true  -- игнорируем столкновение со стеной
    end

        if (a.type == "grenade" and (b.type == "wall_phys" or b.type == "door_phys")) or
       (b.type == "grenade" and (a.type == "wall_phys" or a.type == "door_phys")) then
        local grenade = (a.type == "grenade") and a or b
        if grenade and grenade.x and not grenade.exploded then
            grenade.exploded = true
            if grenade.explosionTimer then
                timer.cancel(grenade.explosionTimer)
                grenade.explosionTimer = nil
            end
            grenadeExplosion(grenade.x, grenade.y,
                weapons["Grenade"].damage,
                weapons["Grenade"].explosionRadius,
                weapons["Grenade"].minDamage)
            safeRemove(grenade)
        end
        return
    end

    -- Игнорируем столкновения пуль с сундуками
    if (a.type == "bullet" and (b.type == "chest_hit" or b.type == "opened_chest")) or
       (b.type == "bullet" and (a.type == "chest_hit" or a.type == "opened_chest")) then
        return true
    end

    if (a.type == "bullet" and b.type == "npc") or (a.type == "npc" and b.type == "bullet") then
        local bullet = (a.type == "bullet") and a or b
        local npc = (a.type == "npc") and a or b
        if bullet and npc and npc.hp then
            damageNPC(npc, bullet)
            safeRemove(bullet)
        end
        return
    end

    if (a.type == "player" and b.type == "loot") or (b.type == "player" and a.type == "loot") then
        local item = (a.type == "loot") and a or b
        if item and item.lootData then
            collectLoot(item)
        end
        return
    end
        -- Пули попадают в газовый баллон
    if (a.type == "bullet" and b.type == "gas_canister") or 
       (b.type == "bullet" and a.type == "gas_canister") then
        local bullet = (a.type == "bullet") and a or b
        local canister = (a.type == "gas_canister") and a or b
        if bullet and canister then
            damageGasCanister(canister, bullet.dmg or 10)
            safeRemove(bullet)
        end
        return
    end
    
    -- Взрыв гранаты повреждает баллон (проверяем по расстоянию)
    -- Это обрабатывается в grenadeExplosion, но добавим проверку и здесь
    if (a.type == "donor_chunk" and b.type == "player") or (b.type == "donor_chunk" and a.type == "player") then
        local chunk = (a.type == "donor_chunk") and a or b
        if chunk and chunk.dmg then
            if chunk.removeTimer then timer.cancel(chunk.removeTimer) end
            hp = hp - chunk.dmg
            showDamageFlash()
            bloodParticles(player.x, player.y, "player", mainGroup)
            showDamageText(player, chunk.dmg, false, mainGroup, false, false)
            safeRemove(chunk)
            if hp <= 0 then die() end
        end
        return
    end

    if (a.type == "donor_chunk" and (b.type == "wall_phys" or b.type == "door_phys")) or
       (b.type == "donor_chunk" and (a.type == "wall_phys" or a.type == "door_phys")) then
        local chunk = (a.type == "donor_chunk") and a or b
        if chunk then
            if chunk.removeTimer then timer.cancel(chunk.removeTimer) end
            safeRemove(chunk)
        end
        return
    end

    if (a.type == "bullet" and b.type == "door_phys") or (a.type == "door_phys" and b.type == "bullet") then
        local bullet = (a.type == "bullet") and a or b
        local door = (a.type == "door_phys") and a or b
        if bullet and door then
            damageDoor(door, bullet.dmg)
            safeRemove(bullet)
        end
        return
    end

    if (a.type == "bullet" and b.type == "wall_phys") or (a.type == "wall_phys" and b.type == "bullet") then
        local bullet = (a.type == "bullet") and a or b
        if bullet then
            spawnHitSparks(bullet.x, bullet.y, bullet.angle) 
            safeRemove(bullet) 
        end
        return
    end

    if (a.type == "arrow" and b.type == "player") or (b.type == "arrow" and a.type == "player") then
        local arrow = (a.type == "arrow") and a or b
        if arrow and arrow.dmg then
            if arrow.removeTimer then timer.cancel(arrow.removeTimer) end
            hp = hp - arrow.dmg
            showDamageFlash()
            bloodParticles(player.x, player.y, "player", mainGroup)
            showDamageText(player, arrow.dmg, false, mainGroup, false, false)
            safeRemove(arrow)
            if hp <= 0 then die() end
        end
        return
    end

    if (a.type == "arrow" and b.type == "wall_phys") or (a.type == "wall_phys" and b.type == "arrow") then
        local arrow = (a.type == "arrow") and a or b
        if arrow then
            if arrow.removeTimer then timer.cancel(arrow.removeTimer) end
            safeRemove(arrow)
        end
        return
    end

    if (a.type == "arrow" and b.type == "door_phys") or (a.type == "door_phys" and b.type == "arrow") then
        local arrow = (a.type == "arrow") and a or b
        local door = (a.type == "door_phys") and a or b
        if arrow and door then
            damageDoor(door, arrow.dmg)
            spawnHitSparks(bullet.x, bullet.y, bullet.angle)
            safeRemove(arrow)
        end
        return
    end

    local bullet, zombie
    if a.type == "bullet" and b.type == "zombie" then
        bullet, zombie = a, b
    elseif a.type == "zombie" and b.type == "bullet" then
        bullet, zombie = b, a
    end
    if bullet and zombie and zombie.hp and zombie.hp > 0 then
        damageZombie(zombie, bullet)
    end
end

local function onKey(e)
    local down = (e.phase == "down")

    -- Закрытие меню трейдера должно работать даже когда игра на паузе
    if down and e.keyName == "e" and traderMenuActive then
        closeTraderMenu()
        return true
    end

    if e.keyName == "escape" and down then
        if isDead then return true end
        if traderMenuActive then
            closeTraderMenu()
            return true
        end
        if isPaused then
            resumeGame()
        else
            pauseGame()
        end
        return true
    end

    if isPaused then return true end
    if isDead or levelWon or not gameStarted or elevatorCutsceneActive then return true end

    if down and e.keyName == "e" then

    if elevator and elevatorActive then
        local dx = player.x - elevator.x
        local dy = player.y - elevator.y
        if math.sqrt(dx * dx + dy * dy) < 100 then
            completeLevel()
            return true
        end
    end

    -- Проверка NPC (трейдер)
    local nearestTrader = nil
    local minTraderDist = 120
    for _, npc in ipairs(npcs) do
        if npc.npcType == "trader" then
            local dx = player.x - npc.x
            local dy = player.y - npc.y
            local dist = math.sqrt(dx*dx + dy*dy)
            if dist < minTraderDist then
                minTraderDist = dist
                nearestTrader = npc
            end
        end
    end
    if nearestTrader then
        createTraderMenu(nearestTrader)
        return
    end

    -- Обыск трупов
    local nearestCorpse = findNearestCorpse()
    if nearestCorpse then
        local dist = math.sqrt((player.x - nearestCorpse.x)^2 + (player.y - nearestCorpse.y)^2)
        if dist < 100 then
            startCorpseLooting(nearestCorpse)
            return
        end
    end

    -- Обыск сундуков
    local nearestChest = nil
    local minChestDist = 100
    for _, chest in ipairs(chests) do
        if not chest.isOpened and not chestLootingActive then
            local dx = player.x - chest.x
            local dy = player.y - chest.y
            local dist = math.sqrt(dx*dx + dy*dy)
            if dist < minChestDist then
                minChestDist = dist
                nearestChest = chest
            end
        end
    end
    if nearestChest and minChestDist < 100 then
        openChest(nearestChest)
        return
    end

    -- Двери
    local nearestDoor = nil
    local minDist = 100
    for _, door in ipairs(doors) do
        local dx = player.x - door.x
        local dy = player.y - door.y
        local dist = math.sqrt(dx*dx + dy*dy)
        if dist < minDist then
            minDist = dist
            nearestDoor = door
        end
    end
    if nearestDoor then
        toggleDoor(nearestDoor)
        return
    end
end

    if e.keyName == "up" or e.keyName == "w" then
        move.up = down
    elseif e.keyName == "v" and down then
        if medkits > 0 and hp < stats.maxHp then
            medkits = medkits - 1
            hp = math.min(stats.maxHp, hp + 30)
            transition.to(healthBar, { time = 200, alpha = 0.5, onComplete = function() healthBar.alpha = 1 end })
            medkitText.text = "x" .. medkits
            save.savePlayerData(brainPieces)
            if medkits <= 0 then
                medkitIcon.alpha = 0
                medkitText.alpha = 0
            end
        end
        elseif e.keyName == "z" and down then
    -- Переключение экстра-способностей
    local current = stats.currentExtra
    if current == playerExtras["shockWave"] then
        stats.currentExtra = playerExtras["enlightenment"]
        showWarning("Экстра: Просвещение", 1000)
    else
        stats.currentExtra = playerExtras["shockWave"]
        showWarning("Экстра: Волна", 1000)
    end
    if _G.updateExtraName then _G.updateExtraName() end
    -- Найдите в onKey() обработку клавиши "tab"
elseif e.keyName == "tab" and down then
    if stats.currentUltimate == playerUltimates["invisible"] then
        stats.currentUltimate = playerUltimates["phase"]
        showWarning("Ультимейт: Фазирование", 1000)
    else
        stats.currentUltimate = playerUltimates["invisible"]
        showWarning("Ультимейт: Невидимость", 1000)
    end
    -- Обновляем отображение ульты
    if _G.updateUltimateName then _G.updateUltimateName() end
    elseif e.keyName == "g" and down then
        throwGrenade()
    elseif e.keyName == "c" and down then
        if energyDrinks > 0 then
            if energyBoostActive then
                showWarning("Энергетик уже активен!", 1500)
            else
                energyDrinks = energyDrinks - 1
                originalMaxEnergy = stats.maxEnergy
                stats.maxEnergy = stats.maxEnergy * 1.5
                energy = math.min(stats.maxEnergy, energy + stats.maxEnergy * 0.5)
                energyBoostActive = true

                energyText.text = "x" .. energyDrinks
                save.savePlayerData(brainPieces)
                if energyDrinks <= 0 then
                    energyIcon.alpha = 0
                    energyText.alpha = 0
                end

                transition.to(energyBar, { time = 200, alpha = 0.5, onComplete = function() energyBar.alpha = 1 end })

                local boostTimer = timer.performWithDelay(10000, function()
                    if not isDead then
                        stats.maxEnergy = originalMaxEnergy
                        if energy > stats.maxEnergy then
                            energy = stats.maxEnergy
                        end
                        energyBoostActive = false
                        transition.to(energyBar, { time = 200, alpha = 0.5, onComplete = function() energyBar.alpha = 1 end })
                    end
                end)
                table.insert(activeTimers, boostTimer)

                if fireRateTimer then timer.cancel(fireRateTimer) end
                fireRateMultiplier = 1 / 1.7
                rapidEndTime = system.getTimer() + 5000
                rapidIndicator.alpha = 1
                fireRateTimer = timer.performWithDelay(5000, function()
                    fireRateMultiplier = 1.0
                    fireRateTimer = nil
                    rapidEndTime = nil
                    rapidIndicator.alpha = 0
                end)
                table.insert(activeTimers, fireRateTimer)

                setReloadMultiplier(0.5)
                local reloadMultTimer = timer.performWithDelay(5000, function()
                    setReloadMultiplier(1.0)
                end)
                table.insert(activeTimers, reloadMultTimer)
            end
        end
    elseif e.keyName == "down" or e.keyName == "s" then
        move.down = down
    elseif e.keyName == "left" or e.keyName == "a" then
        move.left = down
    elseif e.keyName == "right" or e.keyName == "d" then
        move.right = down
    elseif e.keyName == "rightShift" or e.keyName == "leftShift" then
        isRunning = down
    elseif e.keyName == "rightControl" or e.keyName == "leftControl" then
        isCrouching = down
    elseif e.keyName == "r" and down then
        reload()
    elseif e.keyName == "q" and down then
        local weapon = stats.currentWeapon
        if weapon.name == "AK-47" then
            weapon.burstModeEnabled = not weapon.burstModeEnabled
            updateFireModeDisplay()
            cancelBurst()
        end
    elseif e.keyName == "f" and down then
        extraUse()
    elseif e.keyName == "x" and down then
        ultimateUse()
    elseif e.keyName == "enter" then
        isShooting = down
    elseif (e.keyName == "space" or e.keyName == "numPad0") and down and not isDashing and energy >= stats.dashCost then
        local dx, dy = 0, 0
        if move.up then dy = -1 elseif move.down then dy = 1 end
        if move.left then dx = -1 elseif move.right then dx = 1 end
        if dx ~= 0 or dy ~= 0 then
            isDashing = true
            energy = energy - stats.dashCost
            local len = math.sqrt(dx*dx + dy*dy)
            local dashSpeed = stats.dashSpeed
            player:setLinearVelocity((dx/len)*dashSpeed, (dy/len)*dashSpeed)
            timer.performWithDelay(stats.dashTime, function()
                if not isDead and player then
                    player:setLinearVelocity(0,0)
                    isDashing = false
                end
            end)
        end
    end

    if down then
        if e.keyName == "1" then switchWeapon("Glock-17")
        elseif e.keyName == "2" then switchWeapon("AK-47")
        elseif e.keyName == "3" then switchWeapon("Benelli M4")
        elseif e.keyName == "4" then switchWeapon("Spas-12")
        elseif e.keyName == "5" then switchWeapon("Barrett M82")
        elseif e.keyName == "6" then switchWeapon("Plazmite")
        end
    end
end

local function onMouse(e)
    if isPaused then return end
    if isDead or levelWon or elevatorCutsceneActive or not gameStarted or not player then return end
    mouseX, mouseY = e.x, e.y

    if e.isPrimaryButtonDown then
        if e.type == "down" then
            isShooting = true
            isAiming = false
            if aimLine then safeRemove(aimLine) end
        elseif e.type == "up" then
            isShooting = false
        end
    end

    if e.isSecondaryButtonDown then
        if e.type == "down" then
            isAiming = true
            aimStartTime = system.getTimer()
        end
    else
        if e.type == "up" and isAiming then
            local holdTime = system.getTimer() - (aimStartTime or 0)
            isAiming = false
            if aimLine then safeRemove(aimLine) end
            if holdTime >= (stats.currentWeapon.aimTime or 500) then
                aimShoot()
            else
                showWarning("Держите прицел дольше", 2000)
            end
        end
    end

    if e.type == "up" and not e.isPrimaryButtonDown then
        isShooting = false
    end

    if isAiming then
        createAimLine()
    end
end

local function onEnterFrame()
    if not gameStarted or isPaused or isDead or levelWon or not player then return end
    if elevatorCutsceneActive then return end
    if not isRunning and energy < stats.maxEnergy and not isCrouching then
        energy = energy + 0.2
    elseif not isRunning and energy < stats.maxEnergy and isCrouching then
        energy = energy + 0.35
    end
    -- Эффект бега (камера чуть отдаляется и слегка трясётся)
-- Эффект бега (камера чуть отдаляется и слегка трясётся)
if isRunning and (move.up or move.down or move.left or move.right) then
    -- Отдаление (масштаб 0.98 вместо 1.0)
    local targetScale = 0.98
    mainGroup.xScale = mainGroup.xScale + (targetScale - mainGroup.xScale) * 0.05
    mainGroup.yScale = mainGroup.yScale + (targetScale - mainGroup.yScale) * 0.05
    
    -- Лёгкая тряска (медленные колебания)
    local time = system.getTimer() / 1000
    local shakeX = math.sin(time * 8) * 0.3
    local shakeY = math.cos(time * 7) * 0.3
    mainGroup.x = mainGroup.x + shakeX * 0.1
    mainGroup.y = mainGroup.y + shakeY * 0.1
    
-- Эффект при приседании (камера приближается)
elseif isCrouching then
    -- Приближение (масштаб 1.04)
    local targetScale = 1.04
    mainGroup.xScale = mainGroup.xScale + (targetScale - mainGroup.xScale) * 0.05
    mainGroup.yScale = mainGroup.yScale + (targetScale - mainGroup.yScale) * 0.05
    
    -- Очень лёгкое покачивание при приседании
    local time = system.getTimer() / 1000
    local breath = math.sin(time * 1.5) * 0.1
    mainGroup.x = mainGroup.x + breath * 0.05
    mainGroup.y = mainGroup.y + breath * 0.05
    
else
    -- Плавный возврат к нормальному масштабу
    mainGroup.xScale = mainGroup.xScale + (1.0 - mainGroup.xScale) * 0.05
    mainGroup.yScale = mainGroup.yScale + (1.0 - mainGroup.yScale) * 0.05
end
    local now = system.getTimer()
if lastFrameTime == 0 then
    lastFrameTime = now
end
local dt = (now - lastFrameTime) / 1000  -- реальный dt в секундах
lastFrameTime = now
if dt > 0 then
    fpsAccum = fpsAccum + dt
    fpsFrames = fpsFrames + 1
end
frameCounter = frameCounter + 1

-- Обновляем отображаемый FPS каждые ~0.5 секунды
if fpsAccum >= 0.5 then
    displayFPS = math.floor(fpsFrames / fpsAccum + 0.5)
    fpsAccum = 0
    fpsFrames = 0
end
        -- Обновление горящих зомби
    updateBurningZombies()
-- Обновляем текст каждый кадр (значение displayFPS)
fpsText.text = "FPS: " .. displayFPS
fpsText:setFillColor(displayFPS < 30 and 1 or 0, displayFPS < 40 and 0 or 1, 0)

    if rapidEndTime and now < rapidEndTime then
        local remaining = math.ceil((rapidEndTime - now) / 1000)
        rapidIndicator.text = "RAPID: " .. remaining .. "s"
        rapidIndicator.alpha = 1
    elseif rapidEndTime then
        rapidEndTime = nil
        rapidIndicator.alpha = 0
    end

    if extraCooldownBar and stats.currentExtra then
        local extra = stats.currentExtra
        local elapsed = now - lastExtraUseTime
        local percent = math.min(1, elapsed / extra.colldown)
        extraCooldownBar.height = 15 * percent
        if percent >= 1 then
            extraCooldownBar.alpha = 0.8
            extraCooldownBarBack.alpha = 0.8
        else
            extraCooldownBar.alpha = 1
            extraCooldownBarBack.alpha = 1
        end
    end
        -- Обновление иконок газовых баллонов на миникарте
    for _, icon in ipairs(gasCanisterIcons) do
        if icon and icon.canisterRef and icon.canisterRef.x then
            local gx = (icon.canisterRef.x / mapWidth) * minimapSize
            local gy = (icon.canisterRef.y / mapHeight) * minimapSize
            icon.x = 10 + gx
            icon.y = 10 + gy
            local gRow = math.floor(icon.canisterRef.y / tileSize) + 1
            local gCol = math.floor(icon.canisterRef.x / tileSize) + 1
            icon.isVisible = (explored[gRow] and explored[gRow][gCol]) and true or false
        end
    end
    for _, npc in ipairs(npcs) do
        if npc and npc.x then
            if npc.hpBg then
                npc.hpBg.x, npc.hpBg.y = npc.x, npc.y - 80
                npc.hpFill.x, npc.hpFill.y = npc.x - 25, npc.y - 80
                npc.hpText.x, npc.hpText.y = npc.x, npc.y - 80
                npc.nameText.x, npc.nameText.y = npc.x, npc.y - 60
            end
        end
    end

    if ultimateCooldownBar and stats.currentUltimate then
        local ultimate = stats.currentUltimate
        local now = system.getTimer()
        local percent = 1

        if now < ultimateEndTime then
            percent = (ultimateEndTime - now) / ultimate.time
        elseif now < ultimateCooldownEndTime then
            local cooldownElapsed = now - ultimateEndTime
            percent = cooldownElapsed / ultimate.colldown
        else
            percent = 1
        end

        percent = math.max(0, math.min(1, percent))
        ultimateCooldownBar.height = 15 * percent

        if percent >= 1 then
            ultimateCooldownBar.alpha = 0.8
            ultimateCooldownBarBack.alpha = 0.8
        else
            ultimateCooldownBar.alpha = 1
            ultimateCooldownBarBack.alpha = 1
        end
    end

    if not isDead and hp < stats.maxHp then
        local now = system.getTimer()
        if not lastRegenTime then lastRegenTime = now end
        if now - lastRegenTime >= 7000 then
            local energyPercent = energy / stats.maxEnergy
            if energyPercent > 0.65 then
                local healValue = 2 + (energyPercent - 0.65) * (2 / 0.35)
                healValue = math.min(4, math.max(2, healValue))
                hp = math.min(stats.maxHp, hp + healValue)

                local healText = display.newText(damageTextGroup, "+" .. math.floor(healValue), player.x, player.y - 40, native.systemFontBold, 18)
                healText:setFillColor(0, 1, 0)
                transition.to(healText, { y = player.y - 80, alpha = 0, time = 800, onComplete = function() safeRemove(healText) end })

                lastRegenTime = now
            end
        end
    end

    local speed = stats.speedNormal
    local moving = move.up or move.down or move.left or move.right

    if isCrouching then
        speed = stats.speedCrouch
    elseif isRunning and moving and energy > 0 and not isAiming then
        speed = stats.speedRun
        energy = math.max(0, energy - stats.runCost * dt)
    elseif isAiming then
        speed = stats.speedCrouch
    end

    local vx, vy = 0, 0
    if move.up then vy = -1 end
    if move.down then vy = 1 end
    if move.left then vx = -1 end
    if move.right then vx = 1 end

    if vx ~= 0 or vy ~= 0 then
        local len = math.sqrt(vx*vx + vy*vy)
        vx = vx/len * speed
        vy = vy/len * speed
    end

    player:setLinearVelocity(vx, vy)

    -- Обновление тумана войны (радиус 3 клетки)
updateVisibility()
    if player and player.body then
        local mx, my = mainGroup:contentToLocal(mouseX, mouseY)

        -- Базовый масштаб спрайта (увеличен в 1.5 раза для видимости)
        local baseScale = 1.5
        -- Коэффициент приседания (0.7 при приседании, иначе 1)
        local crouchFactor = isCrouching and 0.7 or 1.0
        -- Зеркалирование по X (1 вправо, -1 влево)
        local mirror = (mx < player.x) and -1 or 1

        -- Применяем итоговый масштаб
        player.body.xScale = baseScale * mirror
        player.body.yScale = baseScale * crouchFactor
        player.body.alpha = isCrouching and 0.7 or 1.0

        -- Вычисляем угол к мыши и поворачиваем ствол
        local angleRad = math.atan2(my - (player.y - 20), mx - player.x)
        currentAimAngle = angleRad
        barrel.rotation = math.deg(angleRad)

        -- Позиция ствола относительно игрока (подстройте под новый размер)
        barrel.x = math.cos(angleRad) * 25
        barrel.y = -20 + math.sin(angleRad) * 15
    end

    if isShooting and not isReloading then
        local weapon = stats.currentWeapon
        if weapon.name == "Plazmite" then
            if not vars.burst.active then
                startBurst(weapon)
            end
        elseif weapon.name == "AK-47" and weapon.burstModeEnabled then
            if not vars.burst.active then
                startBurst(weapon)
            end
        else
            if now - lastBulletTime > weapon.rate * fireRateMultiplier then
                spawnBul()
                lastBulletTime = now
            end
        end
    else
        if vars.burst.active then cancelBurst() end
    end

    if energyBar then energyBar.width = math.max(1, (energy/stats.maxEnergy)*120) end
    if healthBar then healthBar.width = math.max(1, (hp/stats.maxHp)*120) end
-- ===== ПУЛЬСАЦИЯ КАМЕРЫ И КРАСНЫЙ ОВЕРЛЕЙ ПРИ НИЗКОМ ХП =====
local hpPercent = hp / stats.maxHp

-- Красный оверлей по краям экрана
if hpPercent < 0.5 then
    -- Создаём оверлей, если его нет
    if not lowHpOverlay then
        lowHpOverlay = display.newRect(ui, display.contentCenterX, display.contentCenterY,
            display.actualContentWidth * 1.2, display.actualContentHeight * 1.2)
        lowHpOverlay:setFillColor(1, 0, 0, 0)
        lowHpOverlay:toFront()
        lowHpOverlay.isVisible = true
    end
    
    -- Интенсивность красного (сильнее при меньшем ХП)
    local intensity = (0.5 - hpPercent) * 0.8  -- от 0 до ~0.4
    local pulse = 0.5 + 0.5 * math.sin(system.getTimer() / 500)
    lowHpOverlay:setFillColor(1, 0, 0, intensity * pulse)
    
    -- Пульсация камеры (лёгкое увеличение/уменьшение)
    local scalePulse = 1.0 + (0.015 * (1 - hpPercent / 0.5) * (0.5 + 0.5 * math.sin(system.getTimer() / 400)))
    mainGroup.xScale = scalePulse
    mainGroup.yScale = scalePulse
    
else
    -- Убираем оверлей, если ХП >= 50%
    if lowHpOverlay then
        lowHpOverlay:removeSelf()
        lowHpOverlay = nil
    end
    -- Возвращаем нормальный масштаб (если не был изменён бегом/приседанием)
    if not isRunning and not isCrouching then
        mainGroup.xScale = mainGroup.xScale + (1.0 - mainGroup.xScale) * 0.05
        mainGroup.yScale = mainGroup.yScale + (1.0 - mainGroup.yScale) * 0.05
    end
end
-- ===== МИГАНИЕ РАМОК ПРИ НИЗКОМ ХП/ЭНЕРГИИ (БЕЗ ИЗМЕНЕНИЯ ЦВЕТА) =====
local hpPercent = hp / stats.maxHp
local energyPercent = energy / stats.maxEnergy
local time = system.getTimer() / 1000

-- Мигание рамки здоровья при ХП < 20%
if hpPercent < 0.2 then
    local pulse = 0.5 + 0.5 * math.sin(time * 6)  -- быстрое мигание
    healthBarBack:setStrokeColor(1, 0.3, 0.3, 0.3 + 0.7 * pulse)
else
    healthBarBack:setStrokeColor(1, 0.6, 0.6, 1)
end

-- Мигание рамки энергии при энергии < 20%
if energyPercent < 0.2 then
    local pulse = 0.5 + 0.5 * math.sin(time * 6 + 1)  -- быстрое мигание со сдвигом
    energyBarBack:setStrokeColor(0.5, 0.6, 1, 0.3 + 0.7 * pulse)
else
    energyBarBack:setStrokeColor(0.5, 0.85, 1, 1)
end
if isRunning then
    viewRadius = 4  -- больше видимости
else
    viewRadius = 3
end
for i = #enemies, 1, -1 do
    local z = enemies[i]
    if z and z.x then
        local now = system.getTimer()

        if z.stunned and now >= z.stunnedEndTime then
            z.stunned = false
            z:setLinearVelocity(0, 0)
        end

        z.seesPlayer = canSeePlayer(z, player.x, player.y)
        if z.zombieType == "ghost" then
            z.seesPlayer = true
        end

        if not z.stunned then
            if z.zombieType == "teleporter" then
                if z.seesPlayer then
                    local dx, dy = z.x - player.x, z.y - player.y
                    local distToPlayer = math.sqrt(dx*dx + dy*dy)
                    if distToPlayer > 5 and not z.isAttacking then
                        local vx = (dx/distToPlayer) * z.speed
                        local vy = (dy/distToPlayer) * z.speed
                        z:setLinearVelocity(vx, vy)
                        local angleToPlayer = math.deg(math.atan2(dy, dx)) + 90
                        local curRot = z.rect.rotation or 0
                        local diff = (angleToPlayer - curRot + 180) % 360 - 180
                        z.rect.rotation = curRot + diff * 5 * dt
                        z.moveAngle = math.atan2(dy, dx)
                    end
                end

                if not z.isAttacking and now - (z.lastTeleport or 0) >= z.teleportCooldown then
                    local playerAngle = math.rad(player.body.rotation)
                    local behindX = player.x - math.cos(playerAngle) * 70
                    local behindY = (player.y - 20) - math.sin(playerAngle) * 70
                    if not isValidTeleportPoint(behindX, behindY) then
                        behindX = player.x - math.cos(playerAngle) * 50
                        behindY = (player.y - 20) - math.sin(playerAngle) * 50
                    end
                    z.x, z.y = behindX, behindY
                    teleportFlash(z.x, z.y)
                    z.lastTeleport = now
                    z.isAttacking = true
                    z.attackCount = 0

                    local function performDoubleAttack()
                        if not z or not z.x or isDead then return end
                        if z.stunned then return end
                        local dmgDealt = z.dmg * 1.7
                        hp = hp - dmgDealt
                        showDamageFlash()
                        bloodParticles(player.x, player.y, "player", mainGroup)
                        showWarning("Телепортер ударил!", 1000)
                        if player.body then
                            player.body:setFillColor(1,0,0)
                            timer.performWithDelay(300, function()
                                if not isDead and player and player.body then
                                    player.body:setFillColor(1, 1, 1)
                                end
                            end)
                        end
                        if hp <= 0 then die() end
                        z.attackCount = z.attackCount + 1
                        if z.attackCount >= 2 then
                            local randomAngle = math.random() * 2 * math.pi
                            local radius = 5 * tileSize
                            local newX = player.x + math.cos(randomAngle) * radius
                            local newY = (player.y - 20) + math.sin(randomAngle) * radius
                            if not isValidTeleportPoint(newX, newY) then
                                newX = player.x + math.cos(randomAngle) * (radius * 0.7)
                                newY = (player.y - 20) + math.sin(randomAngle) * (radius * 0.7)
                            end
                            z.x, z.y = newX, newY
                            teleportFlash(z.x, z.y)
                            z.isAttacking = false
                            if z.doubleAttackTimer then timer.cancel(z.doubleAttackTimer); z.doubleAttackTimer = nil end
                        else
                            if z.doubleAttackTimer then timer.cancel(z.doubleAttackTimer) end
                            z.doubleAttackTimer = timer.performWithDelay(z.doubleAttackDelay, performDoubleAttack)
                            table.insert(activeTimers, z.doubleAttackTimer)
                        end
                    end
                    timer.performWithDelay(500, function()
                        performDoubleAttack()
                    end)
                end

                if z.hp <= 0 then
                    if z.doubleAttackTimer then timer.cancel(z.doubleAttackTimer) end
                end

                if not z.seesPlayer then
                    local currentSpeed = z.speed * 0.5
                    if now < z.wanderPauseUntil then
                        z:setLinearVelocity(0, 0)
                    else
                        if not z.wanderTargetX or now > z.wanderUpdateTime then
                            local angle = math.random() * 2 * math.pi
                            local radius = math.random(200, z.wanderRadius)
                            local wx = z.originX + math.cos(angle) * radius
                            local wy = z.originY + math.sin(angle) * radius
                            wx = math.max(0, math.min(mapWidth, wx))
                            wy = math.max(0, math.min(mapHeight, wy))
                            z.wanderTargetX, z.wanderTargetY = wx, wy
                            z.path = getPath(z.x, z.y, z.wanderTargetX, z.wanderTargetY)
                            z.wanderUpdateTime = now + math.random(5000, 10000)
                            if math.random() < 0.2 then
                                z.wanderPauseUntil = now + math.random(1000, 3000)
                            end
                        end
                        local targetX, targetY = z.wanderTargetX, z.wanderTargetY
                        if targetX and targetY then
                            local finalX, finalY = targetX, targetY
                            if z.path and #z.path > 0 then
                                local node = z.path[1]
                                finalX, finalY = node.x, node.y
                                if math.sqrt((finalX - z.x)^2 + (finalY - z.y)^2) < 20 then
                                    table.remove(z.path, 1)
                                end
                            end
                            local dx = finalX - z.x
                            local dy = finalY - z.y
                            local dist = math.sqrt(dx*dx + dy*dy)
                            if dist > 5 and not z.isAttacking then
                                local vx = (dx/dist) * currentSpeed
                                local vy = (dy/dist) * currentSpeed
                                z:setLinearVelocity(vx, vy)
                                local angleToTarget = math.deg(math.atan2(dy, dx)) + 90
                                local curRot = z.rect.rotation or 0
                                local diff = (angleToTarget - curRot + 180) % 360 - 180
                                z.rect.rotation = curRot + diff * 5 * dt
                                z.moveAngle = math.atan2(dy, dx)
                            end
                        end
                    end
                end

            elseif z.zombieType == "acid_zombie" then
                if z.seesPlayer then
                    local dx = player.x - z.x
                    local dy = player.y - z.y
                    local dist = math.sqrt(dx*dx + dy*dy)

                    local angleToPlayerRad = math.atan2(dy, dx)
                    local angleToPlayerDeg = math.deg(angleToPlayerRad) + 90
                    local curRot = z.rect.rotation or 0
                    local diff = (angleToPlayerDeg - curRot + 180) % 360 - 180
                    z.rect.rotation = curRot + diff * 5 * dt
                    z.moveAngle = angleToPlayerRad

                    if dist > 350 then
                        local vx = (dx/dist) * z.speed
                        local vy = (dy/dist) * z.speed
                        z:setLinearVelocity(vx, vy)
                    elseif dist < 250 then
                        local vx = -(dx/dist) * (z.speed * 0.8)
                        local vy = -(dy/dist) * (z.speed * 0.8)
                        z:setLinearVelocity(vx, vy)
                    else
                        z:setLinearVelocity(0, 0)
                    end

                    if now - (z.lastPuke or 0) >= 10000 and dist <= 400 then
                        z.lastPuke = now

                        local coneGroup = display.newGroup()
                        mainGroup:insert(coneGroup)
                        coneGroup.x, coneGroup.y = z.x, z.y

                        local numSegments = 16
                        local halfAngle = math.rad(30)
                        local radius = 400

                        local vertices = {0, 0}
                        for i = -numSegments, numSegments do
                            local a = halfAngle * (i / numSegments)
                            table.insert(vertices, radius * math.cos(a))
                            table.insert(vertices, radius * math.sin(a))
                        end
                        local conePoly = display.newPolygon(coneGroup, 0, 0, vertices)
                        conePoly:setFillColor(0.4, 0.8, 0, 0.4)
                        conePoly.anchorX = 0

                        coneGroup.rotation = math.deg(angleToPlayerRad)

                        transition.to(coneGroup, { alpha = 0, time = 600, onComplete = function() safeRemove(coneGroup) end })

                        local zombieAngle = math.deg(angleToPlayerRad)
                        local angleToPlayer = math.deg(math.atan2(player.y - z.y, player.x - z.x))
                        local angleDiff = math.abs(angleToPlayer - zombieAngle)
                        if angleDiff > 180 then angleDiff = 360 - angleDiff end

                        if angleDiff <= 30 then
                            hp = hp - 20
                            showDamageFlash()
                            bloodParticles(player.x, player.y, "player", mainGroup)
                            applyPoisonEffect()
                            if hp <= 0 then die() end
                        end
                    end
                else
                    z:setLinearVelocity(0, 0)
                end

            elseif z.zombieType == "archer" then
                if z.seesPlayer then
                    local dx = player.x - z.x
                    local dy = player.y - z.y
                    local dist = math.sqrt(dx*dx + dy*dy)

                    local meleeRange = (z.xSize * 0.8) + 20
                    if dist < meleeRange then
                        if not z.isAttacking and now - z.lastAttack > z.attackRate then
                            hp = hp - z.dmg
                            showDamageFlash()
                            bloodParticles(player.x, player.y, "player", mainGroup)
                            z.lastAttack = now
                            z.isAttacking = true
                            timer.performWithDelay(z.attackRate * 0.7, function()
                                if z and z.x then z.isAttacking = false end
                            end)
                            if player.body then
                                player.body:setFillColor(1,0,0)
                                timer.performWithDelay(300, function()
                                    if not isDead and player and player.body then
                                        player.body:setFillColor(1,1,1)
                                    end
                                end)
                            end
                            if hp <= 0 then die() end
                        end
                        z:setLinearVelocity(0, 0)
                    else
                        if dist > z.rangedRange then
                            local vx = (dx/dist) * z.speed
                            local vy = (dy/dist) * z.speed
                            z:setLinearVelocity(vx, vy)
                            local angleToPlayer = math.deg(math.atan2(dy, dx)) + 90
                            local curRot = z.rect.rotation or 0
                            local diff = (angleToPlayer - curRot + 180) % 360 - 180
                            z.rect.rotation = curRot + diff * 5 * dt
                            z.moveAngle = math.atan2(dy, dx)
                        else
                            z:setLinearVelocity(0, 0)
                            local angleToPlayer = math.deg(math.atan2(dy, dx)) + 90
                            local curRot = z.rect.rotation or 0
                            local diff = (angleToPlayer - curRot + 180) % 360 - 180
                            z.rect.rotation = curRot + diff * 5 * dt

                            if now - (z.lastRangedAttack or 0) > z.rangedRate then
                                z.lastRangedAttack = now
                                createArcherArrow(z.x, z.y, player.x, player.y, z.rangedDmg)
                            end
                        end
                    end
                else
                    local currentSpeed = z.speed * 0.5
                    if now < z.wanderPauseUntil then
                        z:setLinearVelocity(0, 0)
                    else
                        if not z.wanderTargetX or now > z.wanderUpdateTime then
                            local angle = math.random() * 2 * math.pi
                            local radius = math.random(200, z.wanderRadius)
                            local wx = z.originX + math.cos(angle) * radius
                            local wy = z.originY + math.sin(angle) * radius
                            wx = math.max(0, math.min(mapWidth, wx))
                            wy = math.max(0, math.min(mapHeight, wy))
                            z.wanderTargetX, z.wanderTargetY = wx, wy
                            z.path = getPath(z.x, z.y, z.wanderTargetX, z.wanderTargetY)
                            z.wanderUpdateTime = now + math.random(5000, 10000)
                            if math.random() < 0.2 then
                                z.wanderPauseUntil = now + math.random(1000, 3000)
                            end
                        end
                        local targetX, targetY = z.wanderTargetX, z.wanderTargetY
                        if targetX and targetY then
                            local finalX, finalY = targetX, targetY
                            if z.path and #z.path > 0 then
                                local node = z.path[1]
                                finalX, finalY = node.x, node.y
                                if math.sqrt((finalX - z.x)^2 + (finalY - z.y)^2) < 20 then
                                    table.remove(z.path, 1)
                                end
                            end
                            local dx = finalX - z.x
                            local dy = finalY - z.y
                            local dist = math.sqrt(dx*dx + dy*dy)
                            if dist > 5 and not z.isAttacking then
                                local vx = (dx/dist) * currentSpeed
                                local vy = (dy/dist) * currentSpeed
                                z:setLinearVelocity(vx, vy)
                                local angleToTarget = math.deg(math.atan2(dy, dx)) + 90
                                local curRot = z.rect.rotation or 0
                                local diff = (angleToTarget - curRot + 180) % 360 - 180
                                z.rect.rotation = curRot + diff * 5 * dt
                                z.moveAngle = math.atan2(dy, dx)
                            end
                        end
                    end
                end

            elseif z.zombieType == "crikey" then
                if z.seesPlayer then
                    if not z.targetX or not z.targetY or now - (z.lastTargetUpdate or 0) > 2000 then
                        local corners = {
                            {x = 0, y = 0},
                            {x = mapWidth, y = 0},
                            {x = 0, y = mapHeight},
                            {x = mapWidth, y = mapHeight}
                        }
                        local maxDist = 0
                        local best = {x = player.x, y = player.y}
                        for _, corner in ipairs(corners) do
                            local dx = corner.x - player.x
                            local dy = corner.y - player.y
                            local dist = dx*dx + dy*dy
                            if dist > maxDist then
                                maxDist = dist
                                best = corner
                            end
                        end
                        z.targetX, z.targetY = best.x, best.y
                        z.lastTargetUpdate = now
                    end
                    local dx = z.targetX - z.x
                    local dy = z.targetY - z.y
                    local dist = math.sqrt(dx*dx + dy*dy)
                    if dist > 5 then
                        local vx = (dx/dist) * z.speed
                        local vy = (dy/dist) * z.speed
                        z:setLinearVelocity(vx, vy)
                        local angleToTarget = math.deg(math.atan2(dy, dx)) + 90
                        local curRot = z.rect.rotation or 0
                        local diff = (angleToTarget - curRot + 180) % 360 - 180
                        z.rect.rotation = curRot + diff * 5 * dt
                        z.moveAngle = math.atan2(dy, dx)
                    end
                else
                    local currentSpeed = z.speed * 0.5
                    if now < z.wanderPauseUntil then
                        z:setLinearVelocity(0, 0)
                    else
                        if not z.wanderTargetX or now > z.wanderUpdateTime then
                            local angle = math.random() * 2 * math.pi
                            local radius = math.random(200, z.wanderRadius)
                            local wx = z.originX + math.cos(angle) * radius
                            local wy = z.originY + math.sin(angle) * radius
                            wx = math.max(0, math.min(mapWidth, wx))
                            wy = math.max(0, math.min(mapHeight, wy))
                            z.wanderTargetX, z.wanderTargetY = wx, wy
                            z.path = getPath(z.x, z.y, z.wanderTargetX, z.wanderTargetY)
                            z.wanderUpdateTime = now + math.random(5000, 10000)
                            if math.random() < 0.2 then
                                z.wanderPauseUntil = now + math.random(1000, 3000)
                            end
                        end
                        local targetX, targetY = z.wanderTargetX, z.wanderTargetY
                        if targetX and targetY then
                            local finalX, finalY = targetX, targetY
                            if z.path and #z.path > 0 then
                                local node = z.path[1]
                                finalX, finalY = node.x, node.y
                                if math.sqrt((finalX - z.x)^2 + (finalY - z.y)^2) < 20 then
                                    table.remove(z.path, 1)
                                end
                            end
                            local dx = finalX - z.x
                            local dy = finalY - z.y
                            local dist = math.sqrt(dx*dx + dy*dy)
                            if dist > 5 and not z.isAttacking then
                                local vx = (dx/dist) * currentSpeed
                                local vy = (dy/dist) * currentSpeed
                                z:setLinearVelocity(vx, vy)
                                local angleToTarget = math.deg(math.atan2(dy, dx)) + 90
                                local curRot = z.rect.rotation or 0
                                local diff = (angleToTarget - curRot + 180) % 360 - 180
                                z.rect.rotation = curRot + diff * 5 * dt
                                z.moveAngle = math.atan2(dy, dx)
                            end
                        end
                    end
                end

            elseif z.zombieType == "ghost" then
                local dx = player.x - z.x
                local dy = player.y - z.y
                local dist = math.sqrt(dx*dx + dy*dy)

                if dist > 5 and not z.isAttacking then
                    local vx = (dx/dist) * z.speed
                    local vy = (dy/dist) * z.speed
                    z:setLinearVelocity(vx, vy)
                else
                    z:setLinearVelocity(0, 0)
                end

                local angleToPlayer = math.deg(math.atan2(dy, dx)) + 90
                local curRot = z.rect.rotation or 0
                local diff = (angleToPlayer - curRot + 180) % 360 - 180
                z.rect.rotation = curRot + diff * 5 * dt
                z.moveAngle = math.atan2(dy, dx)

                local attackRange = (z.xSize * 0.8) + 20
                if dist < attackRange and now - z.lastAttack > z.attackRate then
                    hp = hp - z.dmg
                    showDamageFlash()
                    bloodParticles(player.x, player.y, "player", mainGroup)
                    z.lastAttack = now
                    z.isAttacking = true
                    timer.performWithDelay(z.attackRate * 0.7, function()
                        if z and z.x then z.isAttacking = false end
                    end)
                    if player.body then
                        player.body:setFillColor(1,0,0)
                        timer.performWithDelay(300, function()
                            if not isDead and player and player.body then
                                player.body:setFillColor(1,1,1)
                            end
                        end)
                    end
                    if hp <= 0 then die() end
                end

            elseif z.zombieType == "donor" then
                if z.seesPlayer then
                    local dx = player.x - z.x
                    local dy = player.y - z.y
                    local dist = math.sqrt(dx*dx + dy*dy)

                    if dist > z.throwRange then
                        local vx = (dx/dist) * z.speed
                        local vy = (dy/dist) * z.speed
                        z:setLinearVelocity(vx, vy)
                    else
                        z:setLinearVelocity(0, 0)
                    end

                    local angleToPlayer = math.deg(math.atan2(dy, dx)) + 90
                    local curRot = z.rect.rotation or 0
                    local diff = (angleToPlayer - curRot + 180) % 360 - 180
                    z.rect.rotation = curRot + diff * 5 * dt
                    z.moveAngle = math.atan2(dy, dx)

                    if dist <= z.throwRange and now - (z.lastThrow or 0) >= z.throwCooldown and z.hp > 0 and not player.isInvisible then
                        z.lastThrow = now
                        z.hp = z.hp - z.throwSelfDamage
                        local ratio = z.hp / z.maxHp
                        if z.hpFill then
                            z.hpFill.width = 50 * ratio
                            -- убрано z.hpFill.x
                        end
                        if z.hpText then
                            z.hpText.text = math.floor(z.hp).."/"..z.maxHp
                        end

                        z.scaleFactor = z.scaleFactor * 0.9
                        z.rect.xScale = z.scaleFactor
                        z.rect.yScale = z.scaleFactor
                        z.xScale = z.scaleFactor
                        z.yScale = z.scaleFactor

                        bloodParticles(z.x, z.y, "enemy", mainGroup)

                        createDonorChunk(z.x, z.y, player.x, player.y, z.throwDamage)

                        if z.hp <= 0 then
                            killZombie(z)
                        end
                    end
                end

            elseif z.zombieType == "summoner" then
                if z.seesPlayer then
                    local dx = player.x - z.x
                    local dy = player.y - z.y
                    local dist = math.sqrt(dx*dx + dy*dy)
                    if dist > 5 and not z.isAttacking then
                        local vx = (dx/dist) * z.speed
                        local vy = (dy/dist) * z.speed
                        z:setLinearVelocity(vx, vy)
                        local angleToPlayer = math.deg(math.atan2(dy, dx)) + 90
                        local curRot = z.rect.rotation or 0
                        local diff = (angleToPlayer - curRot + 180) % 360 - 180
                        z.rect.rotation = curRot + diff * 5 * dt
                        z.moveAngle = math.atan2(dy, dx)
                    end

                    if not z.hasSummonedFirst then
                        z.hasSummonedFirst = true
                        z.lastSummonTime = now
                        for _ = 1, 3 do
                            local angle = math.random() * 2 * math.pi
                            local spawnDist = math.random(50, z.summonRadius)
                            local sx = z.x + math.cos(angle) * spawnDist
                            local sy = z.y + math.sin(angle) * spawnDist
                            local col = math.floor(sx / tileSize) + 1
                            local row = math.floor(sy / tileSize) + 1
                            if map[row] and map[row][col] ~= 1 then
                                local pool = {}
                                for name, data in pairs(zombieTypes) do
                                    for j = 1, data.weight do table.insert(pool, name) end
                                end
                                local rName = pool[math.random(#pool)]
                                spawnZombie(zombieTypes[rName], rName, sx, sy)
                            end
                        end
                    elseif now - z.lastSummonTime >= z.summonCooldown then
                        z.lastSummonTime = now
                        for _ = 1, 3 do
                            local angle = math.random() * 2 * math.pi
                            local spawnDist = math.random(50, z.summonRadius)
                            local sx = z.x + math.cos(angle) * spawnDist
                            local sy = z.y + math.sin(angle) * spawnDist
                            local col = math.floor(sx / tileSize) + 1
                            local row = math.floor(sy / tileSize) + 1
                            if map[row] and map[row][col] ~= 1 then
                                local pool = {}
                                for name, data in pairs(zombieTypes) do
                                    for j = 1, data.weight do table.insert(pool, name) end
                                end
                                local rName = pool[math.random(#pool)]
                                spawnZombie(zombieTypes[rName], rName, sx, sy)
                            end
                        end
                    end
                else
                    local currentSpeed = z.speed * 0.5
                    if now < z.wanderPauseUntil then
                        z:setLinearVelocity(0, 0)
                    else
                        if not z.wanderTargetX or now > z.wanderUpdateTime then
                            local angle = math.random() * 2 * math.pi
                            local radius = math.random(200, z.wanderRadius)
                            local wx = z.originX + math.cos(angle) * radius
                            local wy = z.originY + math.sin(angle) * radius
                            wx = math.max(0, math.min(mapWidth, wx))
                            wy = math.max(0, math.min(mapHeight, wy))
                            z.wanderTargetX, z.wanderTargetY = wx, wy
                            z.path = getPath(z.x, z.y, z.wanderTargetX, z.wanderTargetY)
                            z.wanderUpdateTime = now + math.random(5000, 10000)
                            if math.random() < 0.2 then
                                z.wanderPauseUntil = now + math.random(1000, 3000)
                            end
                        end
                        local targetX, targetY = z.wanderTargetX, z.wanderTargetY
                        if targetX and targetY then
                            local finalX, finalY = targetX, targetY
                            if z.path and #z.path > 0 then
                                local node = z.path[1]
                                finalX, finalY = node.x, node.y
                                if math.sqrt((finalX - z.x)^2 + (finalY - z.y)^2) < 20 then
                                    table.remove(z.path, 1)
                                end
                            end
                            local dx = finalX - z.x
                            local dy = finalY - z.y
                            local dist = math.sqrt(dx*dx + dy*dy)
                            if dist > 5 and not z.isAttacking then
                                local vx = (dx/dist) * currentSpeed
                                local vy = (dy/dist) * currentSpeed
                                z:setLinearVelocity(vx, vy)
                                local angleToTarget = math.deg(math.atan2(dy, dx)) + 90
                                local curRot = z.rect.rotation or 0
                                local diff = (angleToTarget - curRot + 180) % 360 - 180
                                z.rect.rotation = curRot + diff * 5 * dt
                                z.moveAngle = math.atan2(dy, dx)
                            end
                        end
                    end
                end

            else
                -- ОБЫЧНЫЕ ЗОМБИ
                if z.seesPlayer then
                    local dxToPlayer = player.x - z.x
                    local dyToPlayer = player.y - z.y
                    local angleToPlayerDeg = math.deg(math.atan2(dyToPlayer, dxToPlayer)) + 90
                    local curRot = z.rect.rotation or 0
                    local diff = (angleToPlayerDeg - curRot + 180) % 360 - 180
                    z.rect.rotation = curRot + diff * 5 * dt
                    z.moveAngle = math.atan2(dyToPlayer, dxToPlayer)

                    if now > (z.nextUpdate or 0) then
                        z.path = getPath(z.x, z.y, player.x, player.y)
                        z.nextUpdate = now + 200 + math.random(-50,50)
                    end

                    local targetX, targetY = player.x, player.y
                    if z.path and #z.path > 0 then
                        local node = z.path[1]
                        targetX, targetY = node.x, node.y
                        if math.sqrt((targetX - z.x)^2 + (targetY - z.y)^2) < 20 then
                            table.remove(z.path, 1)
                        end
                    end

                    local dx = targetX - z.x
                    local dy = targetY - z.y
                    local distToTarget = math.sqrt(dx*dx + dy*dy)

                    if distToTarget > 5 and not z.isAttacking then
                        local vx = (dx/distToTarget) * z.speed
                        local vy = (dy/distToTarget) * z.speed
                        z:setLinearVelocity(vx, vy)
                    end

                    local distToPlayer = math.sqrt((player.x - z.x)^2 + (player.y - z.y)^2)
                    local attackRange = (z.xSize * 0.8) + 20
                    if distToPlayer < attackRange and now - z.lastAttack > z.attackRate then
                        hp = hp - (z.dmg or 10)
                        showDamageFlash()
                        bloodParticles(player.x, player.y, "player", mainGroup)
                        z.lastAttack = now
                        z.isAttacking = true
                        timer.performWithDelay(z.attackRate * 0.7, function()
                            if z and z.x then z.isAttacking = false end
                        end)
                        if player.body then
                            player.body:setFillColor(1,0,0)
                            timer.performWithDelay(300, function()
                                if not isDead and player and player.body then
                                    player.body:setFillColor(1,1,1)
                                end
                            end)
                        end
                        if hp <= 0 then die() end
                    end
                else
                    local currentSpeed = z.speed * 0.5
                    if now < z.wanderPauseUntil then
                        z:setLinearVelocity(0, 0)
                    else
                        if not z.wanderTargetX or now > z.wanderUpdateTime then
                            local angle = math.random() * 2 * math.pi
                            local radius = math.random(200, z.wanderRadius)
                            local wx = z.originX + math.cos(angle) * radius
                            local wy = z.originY + math.sin(angle) * radius
                            wx = math.max(0, math.min(mapWidth, wx))
                            wy = math.max(0, math.min(mapHeight, wy))
                            z.wanderTargetX, z.wanderTargetY = wx, wy
                            z.path = getPath(z.x, z.y, z.wanderTargetX, z.wanderTargetY)
                            z.wanderUpdateTime = now + math.random(5000, 10000)
                            if math.random() < 0.2 then
                                z.wanderPauseUntil = now + math.random(1000, 3000)
                            end
                        end
                        local targetX, targetY = z.wanderTargetX, z.wanderTargetY
                        if targetX and targetY then
                            local finalX, finalY = targetX, targetY
                            if z.path and #z.path > 0 then
                                local node = z.path[1]
                                finalX, finalY = node.x, node.y
                                if math.sqrt((finalX - z.x)^2 + (finalY - z.y)^2) < 20 then
                                    table.remove(z.path, 1)
                                end
                            end
                            local dx = finalX - z.x
                            local dy = finalY - z.y
                            local dist = math.sqrt(dx*dx + dy*dy)
                            if dist > 5 and not z.isAttacking then
                                local vx = (dx/dist) * currentSpeed
                                local vy = (dy/dist) * currentSpeed
                                z:setLinearVelocity(vx, vy)
                                local angleToTarget = math.deg(math.atan2(dy, dx)) + 90
                                local curRot = z.rect.rotation or 0
                                local diff = (angleToTarget - curRot + 180) % 360 - 180
                                z.rect.rotation = curRot + diff * 5 * dt
                                z.moveAngle = math.atan2(dy, dx)
                            end
                        end
                    end
                end
            end
        end

        -- ===== ОБНОВЛЕНИЕ ПОЛОСОК И ТЕКСТА (без ручного позиционирования) =====
        if z.hpFill then
            local ratio = math.max(0, z.hp / z.maxHp)
            z.hpFill.width = 50 * ratio
        end
        if z.hpText then
            z.hpText.text = math.floor(z.hp) .. "/" .. z.maxHp
        end
        -- имя не меняется, остаётся typeName

        -- Лечение healer'ом
        if z.zombieType == "healer" and now - (z.lastHeal or 0) > 3000 then
            z.lastHeal = now
            for _, other in ipairs(enemies) do
                if other ~= z and other.hp and other.hp > 0 then
                    local d = math.sqrt((other.x - z.x)^2 + (other.y - z.y)^2)
                    if d < 150 then
                        other.hp = math.min(other.maxHp, other.hp + 10)
                        local ratio = other.hp / other.maxHp
                        if other.hpFill then
                            other.hpFill.width = 50 * ratio
                            -- убрано other.hpFill.x
                        end
                        if other.hpText then
                            other.hpText.text = math.floor(other.hp).."/"..other.maxHp
                        end
                        healParticles(other.x, other.y - 30, mainGroup)
                        if other.rect then
                            other.rect:setFillColor(0.2, 1, 0.2)
                            timer.performWithDelay(200, function()
                                if other.rect then
                                    if other.zombieType == "healer" then
                                        other.rect:setFillColor(0.2,0.9,0.6)
                                    elseif other.zombieType == "exploder" then
                                        other.rect:setFillColor(0.9,0.3,0.2)
                                    elseif other.zombieType == "teleporter" then
                                        other.rect:setFillColor(0.7,0.2,0.9)
                                    else
                                        other.rect:setFillColor(0.2,0.8,0.2)
                                    end
                                end
                            end)
                        end
                    end
                end
            end
            healParticles(z.x, z.y - 30, mainGroup)
        end

    else
        table.remove(enemies, i)
    end
end


    for a = 1, #enemies do
        local z1 = enemies[a]
        if z1 and z1.x then
            for b = a+1, #enemies do
                local z2 = enemies[b]
                if z2 and z2.x then
                    local dx = z1.x - z2.x
                    local dy = z1.y - z2.y
                    local dist = math.sqrt(dx*dx + dy*dy)
                    local minDist = (z1.xSize + z2.xSize) * 0.6
                    if dist < minDist and dist > 0 then
                        local overlap = (minDist - dist) * 0.5
                        local pushX = (dx / dist) * overlap
                        local pushY = (dy / dist) * overlap
                        z1.x = z1.x + pushX
                        z1.y = z1.y + pushY
                        z2.x = z2.x - pushX
                        z2.y = z2.y - pushY
                        local vx1, vy1 = z1:getLinearVelocity()
                        local vx2, vy2 = z2:getLinearVelocity()
                        z1:setLinearVelocity(vx1 + pushX*20, vy1 + pushY*20)
                        z2:setLinearVelocity(vx2 - pushX*20, vy2 - pushY*20)
                    end
                end
            end
        end
    end

    local nearestCorpse = nil
local minCorpseDist = 999
if not chestLootingActive then   -- не ищем, если уже идёт обыск
    nearestCorpse = findNearestCorpse(150)
    if nearestCorpse then
        minCorpseDist = math.sqrt((player.x - nearestCorpse.x)^2 + (player.y - nearestCorpse.y)^2)
    end
end
    local nearestChest = nil
    local minChestDist = 100
    for _, chest in ipairs(chests) do
        if not chest.isOpened and not chestLootingActive then
            local dx = player.x - chest.x
            local dy = player.y - chest.y
            local dist = math.sqrt(dx*dx + dy*dy)
            if dist < minChestDist then
                minChestDist = dist
                nearestChest = chest
            end
        end
    end

    local nearestDoor = nil
    local minDist = 100
    for _, door in ipairs(doors) do
        local dx = player.x - door.x
        local dy = player.y - door.y
        local dist = math.sqrt(dx*dx + dy*dy)
        if dist < minDist then
            minDist = dist
            nearestDoor = door
        end
    end

    local nearElevator = false
    local elevatorDist = 999
    if elevator then
        local dx = player.x - elevator.x
        local dy = player.y - elevator.y
        elevatorDist = math.sqrt(dx * dx + dy * dy)
        nearElevator = elevatorDist < 100
    end

    if nearElevator and elevatorActive then
        local hintText = _G.getText("elevatorHint")
        if not elevatorHint then
            elevatorHint = display.newText({
                parent = ui,
                text = hintText,
                x = display.contentCenterX,
                y = display.contentCenterY - 120,
                font = native.systemFontBold,
                fontSize = 20
            })
            elevatorHint:setFillColor(0.4, 1, 0.5)
            transition.from(elevatorHint, { time = 200, alpha = 0 })
        else
            elevatorHint.text = hintText
            elevatorHint.alpha = 1
        end
        if chestHint then chestHint.alpha = 0 end
        if corpseHint then corpseHint.alpha = 0 end
        if doorHint then doorHint.alpha = 0 end
    elseif nearestChest and minChestDist < math.min(minCorpseDist, (nearestDoor and minDist or 999)) then
        local hintText = "ОБЫСКАТЬ [E]"
        if not chestHint then
            chestHint = display.newText({
                parent = ui,
                text = hintText,
                x = display.contentCenterX,
                y = display.contentCenterY - 120,
                font = native.systemFontBold,
                fontSize = 20
            })
            chestHint:setFillColor(1, 1, 0)
            transition.from(chestHint, { time = 200, alpha = 0 })
        else
            chestHint.text = hintText
            chestHint.alpha = 1
        end
        if doorHint then doorHint.alpha = 0 end
        if corpseHint then corpseHint.alpha = 0 end
        if elevatorHint then elevatorHint.alpha = 0 end
    elseif nearestCorpse and minCorpseDist < (nearestDoor and minDist or 999) then
        if not corpseHint then
            corpseHint = display.newText({
                parent = ui,
                text = "ОБЫСКАТЬ ТРУП [E]",
                x = display.contentCenterX,
                y = display.contentCenterY - 120,
                font = native.systemFontBold,
                fontSize = 20
            })
            corpseHint:setFillColor(1, 0.8, 0.6)
            transition.from(corpseHint, { time = 200, alpha = 0 })
        else
            corpseHint.alpha = 1
        end
        if chestHint then chestHint.alpha = 0 end
        if doorHint then doorHint.alpha = 0 end
        if elevatorHint then elevatorHint.alpha = 0 end
    else
        if chestHint then chestHint.alpha = 0 end
        if corpseHint then corpseHint.alpha = 0 end
        if elevatorHint then elevatorHint.alpha = 0 end
        if nearestDoor then
            local hintText = nearestDoor.isOpen and "ЗАКРЫТЬ [E]" or "ОТКРЫТЬ [E]"
            if not doorHint then
                doorHint = display.newText({
                    parent = ui,
                    text = hintText,
                    x = display.contentCenterX,
                    y = display.contentCenterY - 120,
                    font = native.systemFontBold,
                    fontSize = 20
                })
                doorHint:setFillColor(1, 1, 0)
                transition.from(doorHint, { time = 200, alpha = 0 })
            else
                doorHint.text = hintText
                doorHint.alpha = 1
            end
        else
            if doorHint then doorHint.alpha = 0 end
        end
    end

    local targetCamX = display.contentCenterX - player.x
    local targetCamY = display.contentCenterY - player.y
    mainGroup.x = mainGroup.x + (targetCamX - mainGroup.x) * 0.1
    mainGroup.y = mainGroup.y + (targetCamY - mainGroup.y) * 0.1

    -- Самонаведение снарядов донора
for i = #donorChunks, 1, -1 do
    local chunk = donorChunks[i]
    if not chunk or not chunk.x then
        table.remove(donorChunks, i)
    else
        local target = chunk.target
        if target and target.x then
            -- Текущий вектор скорости
            local vx, vy = chunk:getLinearVelocity()
            local currentSpeed = math.sqrt(vx*vx + vy*vy)
            if currentSpeed > 0 then
                -- Желаемое направление к игроку
                local dx = target.x - chunk.x
                local dy = (target.y - 20) - chunk.y  -- центр игрока чуть выше
                local dist = math.sqrt(dx*dx + dy*dy)
                if dist > 10 then
                    local desiredAngle = math.atan2(dy, dx)
                    local currentAngle = math.atan2(vy, vx)

                    -- Ограничиваем изменение угла
                    local angleDiff = desiredAngle - currentAngle
                    -- Нормализуем в диапазон [-π, π]
                    angleDiff = (angleDiff + math.pi) % (2*math.pi) - math.pi

                    local maxTurn = chunk.turnRate
                    if math.abs(angleDiff) > maxTurn then
                        angleDiff = (angleDiff > 0) and maxTurn or -maxTurn
                    end

                    local newAngle = currentAngle + angleDiff
                    local newVx = math.cos(newAngle) * chunk.speed
                    local newVy = math.sin(newAngle) * chunk.speed
                    chunk:setLinearVelocity(newVx, newVy)
                    chunk.rotation = math.deg(newAngle)
                end
            end
        end
    end
end
    -- Плавное обновление альфы тумана (без transition.to)
local lerpSpeed = 0.12   -- скорость перехода
for row = 1, #map do
    for col = 1, #map[row] do
        local rect = fogTiles[row] and fogTiles[row][col]
        if rect then
            local diff = rect.targetAlpha - rect.currentAlpha
            if math.abs(diff) > 0.001 then
                rect.currentAlpha = rect.currentAlpha + diff * lerpSpeed
                rect.alpha = rect.currentAlpha
            elseif rect.currentAlpha ~= rect.targetAlpha then
                rect.currentAlpha = rect.targetAlpha
                rect.alpha = rect.currentAlpha
            end
        end
    end
end
    if frameCounter % 3 == 0 then
        updateLayers()
    end

    if minimapPlayerIcon then
        local px = (player.x / mapWidth) * minimapSize
        local py = (player.y / mapHeight) * minimapSize
        minimapPlayerIcon.x = 10 + px
        minimapPlayerIcon.y = 10 + py
    end

    for _, icon in ipairs(minimapZombieIcons) do
    if icon and icon.zombieRef and icon.zombieRef.x then
        local zx = (icon.zombieRef.x / mapWidth) * minimapSize
        local zy = (icon.zombieRef.y / mapHeight) * minimapSize
        icon.x = 10 + zx
        icon.y = 10 + zy

        local zRow = math.floor(icon.zombieRef.y / tileSize) + 1
        local zCol = math.floor(icon.zombieRef.x / tileSize) + 1

        local visible = false
        -- Если клетка исследована – показываем
        if explored[zRow] and explored[zRow][zCol] then
            visible = true
        else
            -- Если не исследована, проверяем прямую видимость
            local dist = math.sqrt((player.x - icon.zombieRef.x)^2 + (player.y - icon.zombieRef.y)^2)
            if dist < 750 and hasLineOfSight(player.x, player.y, icon.zombieRef.x, icon.zombieRef.y) then
                visible = true
            end
        end
        icon.isVisible = visible
    end
end

    for _, icon in ipairs(minimapLootIcons) do
        if icon and icon.lootRef and icon.lootRef.x then
            local lx = (icon.lootRef.x / mapWidth) * minimapSize
            local ly = (icon.lootRef.y / mapHeight) * minimapSize
            icon.x = 10 + lx
            icon.y = 10 + ly
            local lRow = math.floor(icon.lootRef.y / tileSize) + 1
local lCol = math.floor(icon.lootRef.x / tileSize) + 1
icon.isVisible = (explored[lRow] and explored[lRow][lCol]) and true or false
        end
    end

    for _, icon in ipairs(minimapChestIcons) do
        if icon and icon.chestRef and icon.chestRef.x then
            local cx = (icon.chestRef.x / mapWidth) * minimapSize
            local cy = (icon.chestRef.y / mapHeight) * minimapSize
            icon.x = 10 + cx
            icon.y = 10 + cy
            local cRow = math.floor(icon.chestRef.y / tileSize) + 1
local cCol = math.floor(icon.chestRef.x / tileSize) + 1
icon.isVisible = (explored[cRow] and explored[cRow][cCol]) and true or false
        end
    end
    -- Эффект Просвещения на миникарте
    if enlightenmentActive then
        -- Подсветка всех иконок зомби
        for _, icon in ipairs(minimapZombieIcons) do
            if icon then
                icon:setFillColor(1, 0.2, 0.2)
                icon.alpha = 1
            end
        end
        -- Подсветка сундуков
        for _, icon in ipairs(minimapChestIcons) do
            if icon then
                icon:setFillColor(1, 0.8, 0)
                icon.alpha = 1
            end
        end
        -- Подсветка газовых баллонов
        for _, icon in ipairs(gasCanisterIcons) do
            if icon then
                icon:setFillColor(1, 0.2, 0.1)
                icon.alpha = 1
            end
        end
    end
end

local runtimeListenersActive = false
local function setRuntimeListenersActive(active)
    if active and not runtimeListenersActive then
        Runtime:addEventListener("key", onKey)
        Runtime:addEventListener("mouse", onMouse)
        Runtime:addEventListener("enterFrame", onEnterFrame)
        Runtime:addEventListener("collision", onCollision)
        runtimeListenersActive = true
    elseif (not active) and runtimeListenersActive then
        Runtime:removeEventListener("key", onKey)
        Runtime:removeEventListener("mouse", onMouse)
        Runtime:removeEventListener("enterFrame", onEnterFrame)
        Runtime:removeEventListener("collision", onCollision)
        runtimeListenersActive = false
    end
end

function scene:create(e)
    local view = self.view
    self.bgRect = display.newRect(view, display.contentCenterX, display.contentCenterY, display.actualContentWidth, display.actualContentHeight)
    self.bgRect:setFillColor(0.08, 0.08, 0.15)  -- тёмно-синий для заставки
    self.title = display.newText({
        parent = view,
        text = _G.getText("main_door"),
        x = display.contentCenterX,
        y = display.contentCenterY,
        font = native.systemFontBold,
        fontSize = 44
    })
    self.title:setFillColor(1,0.3,0.3)
    self.title.alpha = 0
end

function scene:show(e)
    if e.phase == "will" then
        currentLevelKey = (e.params and e.params.k) or "main_door"
        currentLevelConfig = getLevelConfig(currentLevelKey)
        if self.title then
            self.title.text = _G.getText(currentLevelKey)
        end
    end
    if e.phase == "did" then
        physics.start()
        physics.setGravity(0, 0)
        setRuntimeListenersActive(true)
        currentRewards = e.params.rewards or {}
        -- scene:show, фаза "did"
transition.to(self.title, {
    time = 800,
    alpha = 1,
    delay = 300,
    onComplete = function()
        -- 1. ЧЁРНЫЙ СТАТИЧНЫЙ ФОН (не вращается)
        local bgSpinner = display.newRect(self.view, display.contentCenterX, display.contentCenterY,
            display.actualContentWidth, display.actualContentHeight)
        bgSpinner:setFillColor(0, 0, 0, 1)
        bgSpinner:toBack()

        -- 2. ГРУППА СПИННЕРА (только точки, будет вращаться)
                -- 2. ГРУППА СПИННЕРА (только точки, будет вращаться)
        local spinnerGroup = display.newGroup()
        self.view:insert(spinnerGroup)
        spinnerGroup:toFront()
        spinnerGroup.x = display.contentCenterX
        spinnerGroup.y = display.contentCenterY + 80

        local numDots = 14         -- было 8 → стало 16
        local radius = 13         -- было 25 → стало 12.5
        for i = 1, numDots do
            local angle = (i - 1) * (360 / numDots)
            local dot = display.newCircle(
                spinnerGroup,
                radius * math.cos(math.rad(angle)),
                radius * math.sin(math.rad(angle)),
                3                 -- было 5 → стало 2.5
            )
            dot:setFillColor(1, 1, 1, 0.2 + 0.8 * (i / numDots))
        end

        local function rotateSpinner()
            transition.to(spinnerGroup, {
                rotation = spinnerGroup.rotation + 360,
                time = 1000,
                onComplete = rotateSpinner
            })
        end
        rotateSpinner()

        -- Запускаем создание уровня (невидимого)
        startLevel()

        -- Через 4 секунды убираем загрузочный экран и показываем игру
        timer.performWithDelay(4000, function()
            -- Удаляем спиннер
            if spinnerGroup then
                transition.cancel(spinnerGroup)
                display.remove(spinnerGroup)
                spinnerGroup = nil
            end
            -- Удаляем чёрный фон
            if bgSpinner then
                display.remove(bgSpinner)
                bgSpinner = nil
            end
            self.title.isVisible = false

            -- Даём небольшую задержку (50 мс) для завершения всех процессов
            timer.performWithDelay(50, function()
                if _G.showGame then
                    _G.showGame()
                end
            end)
        end)
    end
})
    end
end

function scene:hide(e)
    if e.phase == "will" then
        setRuntimeListenersActive(false)
    end
end

function scene:destroy(e)


        for _, c in ipairs(gasCanisters) do
        safeRemove(c)
    end
    gasCanisters = {}
    for _, icon in ipairs(gasCanisterIcons) do
        safeRemove(icon)
    end
    gasCanisterIcons = {}
    cancelAllTimers()
    if fogUpdateTimer then timer.cancel(fogUpdateTimer); fogUpdateTimer = nil end
if exploredUpdateTimer then timer.cancel(exploredUpdateTimer); exploredUpdateTimer = nil end
    if fogGroup then
    display.remove(fogGroup)
    fogGroup = nil
end
fogTiles = {}
    setRuntimeListenersActive(false)
    for _, npc in ipairs(npcs) do
        safeRemove(npc)
    end
    if traderMenuGroup then
        safeRemove(traderMenuGroup)
        traderMenuGroup = nil
    end
    npcs = {}
    donorChunks = {}
    resumeGame()
    for _, c in ipairs(corpses) do
        safeRemove(c)
    end
    corpses = {}
    if corpseHint then safeRemove(corpseHint) end
    physics.stop()
    for _, chest in ipairs(chests) do
        safeRemove(chest.group)
        safeRemove(chest.hitBox)
    end
    chests = {}
    for _, icon in ipairs(minimapChestIcons) do
        safeRemove(icon)
    end
    minimapChestIcons = {}
end

scene:addEventListener("create", scene)
scene:addEventListener("show", scene)
scene:addEventListener("hide", scene)
scene:addEventListener("destroy", scene)

return scene