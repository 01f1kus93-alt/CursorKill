local composer = require("composer")
local widget = require("widget")
local save = require("save")
local scene = composer.newScene()
-- ====== ГЛОБАЛЬНЫЕ ПЕРЕМЕННЫЕ ======
brainPieces = 0      -- убрать local
medkits = 0          -- убрать local  
energyDrinks = 0     -- убрать local
grenades = 0         -- убрать local
completedLevels = {} -- убрать local
-- =================================

-- ====== ПЕРЕМЕННЫЕ ======
local titleTapCount = 0
local titleTapTimer = nil
local SECRET_LEVEL_KEY = "admin_test"

local selectedCompletedLevelKey = nil
local selectedButton = nil

local levelInfoGroup = nil
local isLevelInfoOpen = false


local lvlButtonsTable = {}
local backgroundEffects = nil
local lockedHint = nil

-- Forward declaration для таблицы уровней (будет заполнена позже)
local levels

-- ====== ШИФРОВАНИЕ И ЗАГРУЗКА ДАННЫХ ======


-- Функция для отображения предупреждения и выхода
local function showResetWarningAndExit()
    local stage = display.getCurrentStage()
    local overlay = display.newRect(stage, display.contentCenterX, display.contentCenterY,
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


-- ====== ПРОВЕРКА РАЗБЛОКИРОВКИ УРОВНЯ ======
local function isLevelUnlocked(levelDef, completed)
    if not levelDef.requires then return true end
    return completed[levelDef.requires] == true
end

-- ====== ПОДСКАЗКА «УРОВЕНЬ ЗАБЛОКИРОВАН» ======
local function showLockedHint(requiredKey)
    if lockedHint then
        transition.cancel(lockedHint)
        display.remove(lockedHint)
        lockedHint = nil
    end

    local msg
    if requiredKey then
        local prefix = _G.getText("levelLockedPrefix") or "Сначала пройдите: "
        local levelName = _G.getText(requiredKey) or requiredKey
        msg = prefix .. levelName
    else
        msg = _G.getText("levelLocked") or "Уровень заблокирован"
    end

    lockedHint = display.newText({
        parent = scene.view,
        text = msg,
        x = display.contentCenterX,
        y = display.contentCenterY + 120,
        font = native.systemFont,
        fontSize = 20,
        width = display.actualContentWidth - 40,
        align = "center"
    })
    lockedHint:setFillColor(1, 0.6, 0.6)
    lockedHint.alpha = 0
    transition.to(lockedHint, { time = 200, alpha = 1, onComplete = function()
        transition.to(lockedHint, { delay = 1800, time = 400, alpha = 0, onComplete = function()
            if lockedHint then
                display.remove(lockedHint)
                lockedHint = nil
            end
        end})
    end})
end

-- ====== ВЫДЕЛЕНИЕ ПРОЙДЕННОГО УРОВНЯ ======
local function deselectCompletedLevel()
    if selectedButton then
        transition.cancel(selectedButton.text)
        if selectedButton.levelDef and selectedCompletedLevelKey then
            local data = save.loadPlayerData()
            local isThisCompleted = data.completed[selectedButton.levelDef.key]
            if isThisCompleted then
                selectedButton.text.text = "✓ " .. _G.getText(selectedButton.levelDef.key)
                selectedButton.text:setFillColor(0.5, 0.5, 0.5)
            else
                selectedButton.text.text = _G.getText(selectedButton.levelDef.key)
                selectedButton.text:setFillColor(1, 1, 1)
            end
        end
        transition.to(selectedButton.text, { time = 150, xScale = 1.0, yScale = 1.0 })
        selectedButton = nil
    end
    selectedCompletedLevelKey = nil
end

local function selectCompletedLevel(key)
    deselectCompletedLevel()
    selectedCompletedLevelKey = key
    for i = 1, #lvlButtonsTable do
        local item = lvlButtonsTable[i]
        if item.levelDef and item.levelDef.key == key then
            selectedButton = item
            item.text:setFillColor(0.3, 1, 0.3)
            transition.to(item.text, { time = 150, xScale = 1.15, yScale = 1.15 })
            break
        end
    end
end

-- ====== ОБНОВЛЕНИЕ СПИСКА КНОПОК ======
local function refreshLevelButtons(completed)
    deselectCompletedLevel()
    for i = 1, #lvlButtonsTable do
        local item = lvlButtonsTable[i]
        if item.levelDef then
            local unlocked = isLevelUnlocked(item.levelDef, completed)
            local isThisCompleted = completed[item.levelDef.key] or false
            item.text.isLocked = not unlocked
            item.text.isCompleted = isThisCompleted

            if isThisCompleted then
                item.text.text = "✓ " .. (_G.getText(item.levelDef.key) or item.levelDef.key)
                item.text:setFillColor(0.5, 0.5, 0.5)
            elseif unlocked then
                item.text.text = _G.getText(item.levelDef.key) or item.levelDef.key
                item.text:setFillColor(1, 1, 1)
            else
                item.text.text = "🔒 " .. (_G.getText(item.levelDef.key) or item.levelDef.key)
                item.text:setFillColor(0.45, 0.45, 0.5)
            end
        end
    end
end

-- ====== ДИНАМИЧЕСКИЙ ФОН ======
local function createDynamicBackground(sceneGroup)
    local bg = display.newRect(sceneGroup, display.contentCenterX, display.contentCenterY, display.actualContentWidth, display.actualContentHeight)
    bg:setFillColor(0.05, 0.05, 0.1)

    local fxGroup = display.newGroup()
    sceneGroup:insert(fxGroup)

    local circles = {}
    local colors = {
        {0.4, 0.1, 0.1, 0.15},
        {0.2, 0.2, 0.3, 0.1},
        {0.15, 0.15, 0.15, 0.2},
    }

    for i = 1, 5 do
        local col = colors[math.random(#colors)]
        local radius = math.random(150, 300)
        local circle = display.newCircle(fxGroup, math.random(0, display.actualContentWidth), math.random(0, display.actualContentHeight), radius)
        circle:setFillColor(unpack(col))
        circle.blendMode = "add"
        circle.alpha = 0.3

        circle.speedX = (math.random() - 0.5) * 0.2
        circle.speedY = (math.random() - 0.5) * 0.2
        circle.scaleSpeed = (math.random() - 0.5) * 0.002

        table.insert(circles, circle)
    end

    local function moveCircles()
        if not fxGroup or not fxGroup.parent then return end
        for _, c in ipairs(circles) do
            c.x = c.x + c.speedX
            c.y = c.y + c.speedY
            if c.x < -c.width then c.x = display.actualContentWidth + c.width
            elseif c.x > display.actualContentWidth + c.width then c.x = -c.width end
            if c.y < -c.height then c.y = display.actualContentHeight + c.height
            elseif c.y > display.actualContentHeight + c.height then c.y = -c.height end

            local newScale = c.xScale + c.scaleSpeed
            if newScale < 0.8 or newScale > 1.2 then
                c.scaleSpeed = -c.scaleSpeed
                newScale = c.xScale + c.scaleSpeed
            end
            c.xScale, c.yScale = newScale, newScale
        end
    end

    local bgHue = 0
    local function animateBG()
        if not bg or not bg.parent then return end
        bgHue = bgHue + 0.001
        local r = 0.05 + 0.02 * math.sin(bgHue)
        local g = 0.05 + 0.01 * math.sin(bgHue + 2)
        local b = 0.1 + 0.02 * math.sin(bgHue + 4)
        bg:setFillColor(r, g, b)
    end

    backgroundEffects = {
        group = fxGroup,
        bg = bg,
        circles = circles,
        moveCircles = moveCircles,
        animateBG = animateBG,
        listenersActive = false
    }
end

local function activateBackgroundListeners()
    if backgroundEffects and not backgroundEffects.listenersActive then
        Runtime:addEventListener("enterFrame", backgroundEffects.moveCircles)
        Runtime:addEventListener("enterFrame", backgroundEffects.animateBG)
        backgroundEffects.listenersActive = true
    end
end

local function deactivateBackgroundListeners()
    if backgroundEffects and backgroundEffects.listenersActive then
        Runtime:removeEventListener("enterFrame", backgroundEffects.moveCircles)
        Runtime:removeEventListener("enterFrame", backgroundEffects.animateBG)
        backgroundEffects.listenersActive = false
    end
end

local function destroyDynamicBackground()
    deactivateBackgroundListeners()
    if backgroundEffects then
        if backgroundEffects.group then display.remove(backgroundEffects.group) end
        if backgroundEffects.bg then display.remove(backgroundEffects.bg) end
        backgroundEffects = nil
    end
end

-- ====== ЗАПУСК УРОВНЯ ======
local function LevelStart(key)
    local levelDef
    for _, v in ipairs(levels) do
        if v.key == key then
            levelDef = v
            break
        end
    end
    composer.gotoScene("game", {
        params = {
            k = key,
            rewards = levelDef and levelDef.rewards or {}
        },
        effect = "crossFade",
        time = 500
    })
end

-- ====== МЕНЮ ИНФОРМАЦИИ ОБ УРОВНЕ ======
local function closeLevelInfo()
    if levelInfoGroup then
        transition.to(levelInfoGroup, {
            alpha = 0,
            time = 200,
            onComplete = function()
                if levelInfoGroup._close then levelInfoGroup._close() end
                display.remove(levelInfoGroup)
                levelInfoGroup = nil
            end
        })
    end
    isLevelInfoOpen = false
    if scene.uiGroup then
        transition.to(scene.uiGroup, { alpha = 1, time = 300 })
    end
end

local function showLevelInfo(levelDef)
    if isLevelInfoOpen then
        if levelInfoGroup then
            transition.cancel(levelInfoGroup)
            if levelInfoGroup._close then levelInfoGroup._close() end
            display.remove(levelInfoGroup)
            levelInfoGroup = nil
        end
        isLevelInfoOpen = false
    end

    if scene.uiGroup then
        transition.to(scene.uiGroup, { alpha = 0, time = 300 })
    end

    isLevelInfoOpen = true

    levelInfoGroup = display.newGroup()
    scene.view:insert(levelInfoGroup)
    levelInfoGroup.alpha = 0

    local touchCatcher = display.newRect(levelInfoGroup, display.contentCenterX, display.contentCenterY,
        display.actualContentWidth, display.actualContentHeight)
    touchCatcher:setFillColor(0, 0, 0, 0)
    touchCatcher:addEventListener("touch", function(e)
        if e.phase == "ended" then
            closeLevelInfo()
        end
        return true
    end)

    local panelWidth, panelHeight = 340, 380
    local panelX = display.contentCenterX
    local panelY = display.contentCenterY
    local panel = display.newRoundedRect(levelInfoGroup, panelX, panelY, panelWidth, panelHeight, 15)
    panel:setFillColor(0.05, 0.05, 0.1, 0.9)
    panel.strokeWidth = 3
    panel:setStrokeColor(1, 0.5, 0.5)

    local title = display.newText(levelInfoGroup, _G.getText(levelDef.key), panelX, panelY - 150, native.systemFontBold, 28)
    title:setFillColor(0.3, 0.8, 1)

    local diffStr = _G.getText("difficulty") .. ": " .. _G.getText(levelDef.difficulty)
    local diffText = display.newText(levelInfoGroup, diffStr, panelX, panelY - 100, native.systemFont, 18)
    diffText:setFillColor(1, 1, 1)

    local goalStr = _G.getText("levelGoal") .. " " .. levelDef.maxZombies .. " " .. _G.getText("zombies")
    local goalText = display.newText(levelInfoGroup, goalStr, panelX, panelY - 65, native.systemFont, 18)
    goalText:setFillColor(1, 1, 1)

    local rewardY = panelY - 25
    local rewardTitle = display.newText(levelInfoGroup, _G.getText("levelReward") .. ":", panelX, rewardY, native.systemFontBold, 20)
    rewardTitle:setFillColor(1, 0.8, 0.2)
    rewardY = rewardY + 28

    if levelDef.rewards then
        for _, reward in ipairs(levelDef.rewards) do
            local icon, text = "", ""
            if reward.type == "brains" then
                icon = "🧠"
                text = "+" .. reward.amount .. " " .. _G.getText("reward_brains")
            elseif reward.type == "medkit" then
                icon = "🩹"
                text = "+" .. reward.amount .. " " .. _G.getText("reward_medkit")
            elseif reward.type == "energy" then
                icon = "🔋"
                text = "+" .. reward.amount .. " " .. _G.getText("reward_energy")
            elseif reward.type == "grenade" then
                icon = "💣"
                text = "+" .. reward.amount .. " " .. _G.getText("reward_grenade")
            elseif reward.type == "ammo" then
                icon = "🔫"
                text = "+" .. reward.amount .. " " .. _G.getText("reward_ammo") .. " (" .. reward.weapon .. ")"
            end

            local rewardLine = display.newText(levelInfoGroup, icon .. " " .. text, panelX, rewardY, native.systemFont, 16)
            rewardLine:setFillColor(0.8, 0.8, 0.8)
            rewardY = rewardY + 24
        end
    end

    local btnY = panelY + 135
    local btnBattle = display.newText(levelInfoGroup, _G.getText("goToBattle"), panelX, btnY, native.systemFontBold, 24)
    btnBattle:setFillColor(0.3, 1, 0.3)
    local btnBack = display.newText(levelInfoGroup, _G.getText("back"), panelX, btnY + 40, native.systemFontBold, 22)
    btnBack:setFillColor(0.7, 0.7, 1)

    btnBattle:addEventListener("touch", function(e)
        if e.phase == "ended" then
            closeLevelInfo()
            LevelStart(levelDef.key)
        end
        return true
    end)
    btnBack:addEventListener("touch", function(e)
        if e.phase == "ended" then
            closeLevelInfo()
        end
        return true
    end)

    local buttons = {
        { obj = btnBattle, baseColor = {0.3, 1, 0.3} },
        { obj = btnBack,   baseColor = {0.7, 0.7, 1} }
    }
    local function onMouse(e)
        for _, b in ipairs(buttons) do
            if b.obj.contentBounds then
                local bounds = b.obj.contentBounds
                local isHover = (e.x >= bounds.xMin and e.x <= bounds.xMax and
                                 e.y >= bounds.yMin and e.y <= bounds.yMax)
                if isHover and not b.isHovered then
                    b.isHovered = true
                    b.obj:setFillColor(1, 1, 1)
                    transition.to(b.obj, { time = 150, xScale = 1.1, yScale = 1.1 })
                elseif not isHover and b.isHovered then
                    b.isHovered = false
                    b.obj:setFillColor(unpack(b.baseColor))
                    transition.to(b.obj, { time = 150, xScale = 1.0, yScale = 1.0 })
                end
            end
        end
    end
    Runtime:addEventListener("mouse", onMouse)
    levelInfoGroup._onMouse = onMouse
    levelInfoGroup._close = function()
        Runtime:removeEventListener("mouse", onMouse)
    end

    transition.to(levelInfoGroup, {
        alpha = 1,
        time = 300,
        easing = easing.out
    })
end

-- ====== ОБРАБОТЧИК НАЖАТИЯ НА УРОВЕНЬ ======
local function tapOnLevel(ev)
    if (ev.phase == "ended") then
        if ev.target.isLocked then
            showLockedHint(ev.target.levelDef.requires)
            deselectCompletedLevel()
            return true
        end
        local levelDef = ev.target.levelDef
        if not levelDef then return true end

        if ev.target.isCompleted then
            if selectedCompletedLevelKey == ev.target.lvlKey then
                LevelStart(ev.target.lvlKey)
                deselectCompletedLevel()
            else
                selectCompletedLevel(ev.target.lvlKey)
            end
            return true
        end

        deselectCompletedLevel()
        showLevelInfo(levelDef)
    end
    return true
end

-- ====== ТАБЛИЦА УРОВНЕЙ (этажи сверху вниз) ======
levels = {
    -- В таблицу levels (после basement или в нужном порядке) добавляем:
{ key = "four_floor",   floor = 4, difficulty = "medium", requires = "three_floor", maxZombies = 60,
    rewards = {
        { type = "brains", amount = 8 },
        { type = "medkit", amount = 2 },
        { type = "energy", amount = 2 },
        { type = "grenade", amount = 2 }
    },
    actionTap = tapOnLevel
},
    { key = "three_floor",   floor = 3, difficulty = "medium", requires = "two_floor", maxZombies = 45,
        rewards = {
            { type = "brains", amount = 5 },
            { type = "grenade", amount = 2 },
            { type = "medkit", amount = 2 },
            { type = "energy", amount = 2 }
        },
        actionTap = tapOnLevel
    },
    { key = "two_floor",     floor = 2, difficulty = "medium", requires = "main_door", maxZombies = 35,
        rewards = {
            { type = "brains", amount = 2 },
            { type = "grenade", amount = 3 },
            { type = "medkit", amount = 1 }
        },
        actionTap = tapOnLevel
    },
    { key = "main_door",     floor = 1, difficulty = "easy", maxZombies = 15,
        rewards = {
            { type = "brains", amount = 6 },
            { type = "medkit", amount = 1 },
            { type = "energy", amount = 2 },
            { type = "grenade", amount = 1 }
        },
        actionTap = tapOnLevel
    },
    { key = "basement", floor = 0, difficulty = "hard", requires = "three_floor", maxZombies = 55,
        rewards = {
            { type = "brains", amount = 20 },
            { type = "medkit", amount = 3 },
            { type = "energy", amount = 2 },
            { type = "grenade", amount = 3 }
        },
        actionTap = tapOnLevel
    }
}

table.sort(levels, function(a, b) return a.floor > b.floor end)

-- ====== ОБРАБОТЧИК МЫШИ ДЛЯ ПОДСВЕТКИ КНОПОК ======
local function onMouseEvent(event)
    if not lvlButtonsTable or #lvlButtonsTable == 0 then return true end

    for i = 1, #lvlButtonsTable do
        local item = lvlButtonsTable[i]
        if item.text and item.text.contentBounds then
            local isHover = false
            
            if item.inScrollView and scene.scrollView then
                local lx, ly = scene.scrollView:contentToLocal(event.x, event.y)
                local b = item.text
                local halfW = (b.width or 100) / 2
                local halfH = (b.height or 30) / 2
                isHover = (lx >= b.x - halfW and lx <= b.x + halfW and ly >= b.y - halfH and ly <= b.y + halfH)
            else
                local b = item.text.contentBounds
                isHover = (event.x >= b.xMin and event.x <= b.xMax and event.y >= b.yMin and event.y <= b.yMax)
            end

            local locked = item.text.isLocked
            local completed = item.text.isCompleted

            if isHover and not locked and not completed and not item.isHovered then
                item.isHovered = true
                transition.cancel(item.text)
                transition.to(item.text, { time = 150, xScale = 1.15, yScale = 1.15 })
                if item.underline then
                    item.underline.width = item.text.width
                    transition.cancel(item.underline)
                    transition.to(item.underline, { time = 150, alpha = 1 })
                end
            elseif not isHover and item.isHovered then
                item.isHovered = false
                transition.cancel(item.text)
                transition.to(item.text, { time = 150, xScale = 1.0, yScale = 1.0 })
                if item.underline then
                    transition.cancel(item.underline)
                    transition.to(item.underline, { time = 150, alpha = 0 })
                end
            end
        end
    end
    return true
end

-- ====== СЦЕНА: CREATE ======
function scene:create(event)
    local sceneGroup = self.view
    lvlButtonsTable = {}

    createDynamicBackground(sceneGroup)

    local uiGroup = display.newGroup()
    sceneGroup:insert(uiGroup)
    self.uiGroup = uiGroup

    local data = save.loadPlayerData()
    brainPieces = data.brains or 0
    completedLevels = data.completed or {}
    medkits = data.medkits or 0
    energyDrinks = data.energy or 0
    grenades = data.grenades or 0

    -- Панель ресурсов
    local panelX = display.screenOriginX + 15
    local panelY = display.screenOriginY + 15
    local panelWidth = 200
    local statsPanel = display.newRoundedRect(uiGroup, panelX, panelY, panelWidth, 35, 10)
    statsPanel:setFillColor(0.05, 0.05, 0.1, 0.8)
    statsPanel.strokeWidth = 2
    statsPanel:setStrokeColor(1, 0.5, 0.5)
    statsPanel.anchorX = 0
    statsPanel.anchorY = 0

    -- Мозги
    local brainIcon = display.newText({
        parent = uiGroup, text = "🧠",
        x = panelX + 20, y = panelY + 17,
        font = native.systemFont, fontSize = 18
    })
    local brainValue = display.newText({
        parent = uiGroup, text = tostring(brainPieces),
        x = brainIcon.x + 15, y = panelY + 17,
        font = native.systemFontBold, fontSize = 16
    })
    brainValue:setFillColor(1, 0.8, 0.6)
    self.brainValue = brainValue

    -- Аптечки
    local medkitIcon = display.newText({
        parent = uiGroup, text = "🩹",
        x = brainValue.x + 25, y = panelY + 17,
        font = native.systemFont, fontSize = 18
    })
    medkitCountText = display.newText({
        parent = uiGroup, text = tostring(medkits),
        x = medkitIcon.x + 15, y = panelY + 17,
        font = native.systemFontBold, fontSize = 16
    })
    medkitCountText:setFillColor(0.4, 1, 0.4)

    -- Энергетики
    local energyIcon = display.newText({
        parent = uiGroup, text = "🔋",
        x = medkitCountText.x + 25, y = panelY + 17,
        font = native.systemFont, fontSize = 18
    })
    energyCountText = display.newText({
        parent = uiGroup, text = tostring(energyDrinks),
        x = energyIcon.x + 15, y = panelY + 17,
        font = native.systemFontBold, fontSize = 16
    })
    energyCountText:setFillColor(1, 1, 0.4)

    -- Гранаты
    local grenadeIcon = display.newText({
        parent = uiGroup, text = "💣",
        x = energyCountText.x + 25, y = panelY + 17,
        font = native.systemFont, fontSize = 18
    })
    grenadeCountText = display.newText({
        parent = uiGroup, text = tostring(grenades),
        x = grenadeIcon.x + 15, y = panelY + 17,
        font = native.systemFontBold, fontSize = 16
    })
    grenadeCountText:setFillColor(1, 0.5, 0.4)

    -- Заголовок
    local title = display.newText({
        parent = uiGroup,
        text = _G.getText("levelsTitle"),
        x = display.contentCenterX,
        y = display.contentCenterY - 180,
        font = native.systemFontBold,
        fontSize = 36,
    })
    title:setFillColor(0.3, 0.8, 1)

    -- Секретный уровень по тройному тапу
    title:addEventListener("touch", function(e)
        if e.phase == "ended" then
            titleTapCount = titleTapCount + 1
            if titleTapTimer then timer.cancel(titleTapTimer) end

            if titleTapCount >= 3 then
                titleTapCount = 0
                composer.gotoScene("game", {
                    params = { k = SECRET_LEVEL_KEY, rewards = {} },
                    effect = "crossFade", time = 500
                })
            else
                titleTapTimer = timer.performWithDelay(1000, function()
                    titleTapCount = 0
                end)
            end
        end
        return true
    end)

    -- ScrollView для списка уровней
    local scrollTop = title.y + 60
    local scrollBottom = display.contentCenterY + 120
    local scrollViewHeight = scrollBottom - scrollTop

    local scrollLeft = display.screenOriginX
    local scrollContentWidth = display.actualContentWidth
    local scrollContentHeight = math.max(scrollViewHeight, #levels * 55 + 40)

    local scrollView = widget.newScrollView({
        top = scrollTop,
        left = scrollLeft,
        width = scrollContentWidth,
        height = scrollViewHeight,
        scrollWidth = scrollContentWidth,
        scrollHeight = scrollContentHeight,
        hideBackground = true,
        horizontalScrollDisabled = true,
        isBounceEnabled = true,
    })
    scrollView.id = "levelsScrollView"
    uiGroup:insert(scrollView)
    self.scrollView = scrollView

    local startY = -108
    local spacing = 50

    for i, v in ipairs(levels) do
        local levelTitle = v.key
        if _G.getText then
            local localized = _G.getText(v.key)
            if localized and localized ~= "" then
                levelTitle = localized
            end
        end

        local y = startY + (i - 1) * spacing
        local txt = display.newText({
            parent = scrollView,
            text = levelTitle,
            x = 0,  
            y = y,
            font = native.systemFont,
            fontSize = 28,
        })
        txt.lvlKey = v.key
        txt.levelDef = v
        txt:addEventListener("touch", v.actionTap)

        local underline = display.newRect(scrollView, txt.x, y + 18, 180, 2)
        underline:setFillColor(1, 0.5, 0.5)
        underline.alpha = 0

        lvlButtonsTable[#lvlButtonsTable + 1] = { 
            text = txt, 
            underline = underline, 
            isHovered = false, 
            levelDef = v,
            inScrollView = true 
        }
    end

    refreshLevelButtons(completedLevels)

    -- Кнопка "Назад"
    local backTxt = display.newText({
        parent = uiGroup,
        text = _G.getText and _G.getText("back") or "Back",
        x = display.contentCenterX,
        y = scrollBottom + 30,
        font = native.systemFont,
        fontSize = 28,
    })
    backTxt:setFillColor(0.7, 0.7, 1)

    local backUnderline = display.newRect(uiGroup, backTxt.x, backTxt.y + 15, 100, 2)
    backUnderline:setFillColor(1, 0.5, 0.5)
    backUnderline.alpha = 0

    backTxt:addEventListener("touch", function(e)
        if e.phase == "ended" then
            composer.gotoScene("menu", { effect = "fade", time = 400 })
        end
        return true
    end)

    lvlButtonsTable[#lvlButtonsTable + 1] = { text = backTxt, underline = backUnderline, isHovered = false, inScrollView = false }

    -- Сброс выделения при клике в пустую область
    sceneGroup:addEventListener("touch", function(e)
        if e.phase == "ended" then
            if isLevelInfoOpen then return false end
            if not e.target or (not e.target.lvlKey and e.target ~= backTxt) then
                deselectCompletedLevel()
            end
        end
        return false
    end)

    -- Обработчик колесика мыши
    function self:onMouseScroll(event)
        if event.type == "scroll" and self.scrollView and self.scrollView.scrollBy then
            local dy = event.scrollY * -20
            self.scrollView:scrollBy(0, dy)
            return true
        end
        return false
    end
end

-- ====== СЦЕНА: SHOW ======
function scene:show(event)
    local phase = event.phase
    if (phase == "will") then
        local data = save.loadPlayerData()
        brainPieces = data.brains or 0
        medkits = data.medkits or 0
        energyDrinks = data.energy or 0
        grenades = data.grenades or 0
        completedLevels = data.completed or {}
        replayedLevels = data.replayed or {}
        
        -- Обновляем глобальные переменные для save.lua
        _G.brainPieces = brainPieces
        _G.medkits = medkits
        _G.energyDrinks = energyDrinks
        _G.grenades = grenades
        _G.completedLevels = completedLevels
        _G.replayedLevels = replayedLevels
        
        if self.brainValue then 
            self.brainValue.text = tostring(brainPieces) 
        end
        if medkitCountText then 
            medkitCountText.text = tostring(medkits) 
        end
        if energyCountText then 
            energyCountText.text = tostring(energyDrinks) 
        end
        if grenadeCountText then 
            grenadeCountText.text = tostring(grenades) 
        end
        if completedLevels then 
            refreshLevelButtons(completedLevels) 
        end

    elseif (phase == "did") then
        Runtime:addEventListener("mouse", onMouseEvent)
        self._scrollWrapper = function(ev) return self:onMouseScroll(ev) end
        Runtime:addEventListener("mouse", self._scrollWrapper)
        activateBackgroundListeners()
    end
end

-- ====== СЦЕНА: HIDE ======
function scene:hide(event)
    local phase = event.phase
    if (phase == "will") then
        if isLevelInfoOpen then
            if levelInfoGroup then
                transition.cancel(levelInfoGroup)
                if levelInfoGroup._close then levelInfoGroup._close() end
                display.remove(levelInfoGroup)
                levelInfoGroup = nil
            end
            isLevelInfoOpen = false
        end
        Runtime:removeEventListener("mouse", onMouseEvent)
        if self._scrollWrapper then
            Runtime:removeEventListener("mouse", self._scrollWrapper)
            self._scrollWrapper = nil
        end
        deactivateBackgroundListeners()

        if lvlButtonsTable then
            for i = 1, #lvlButtonsTable do
                local it = lvlButtonsTable[i]
                if it and it.text then
                    transition.cancel(it.text)
                    it.isHovered = false
                    it.text.xScale, it.text.yScale = 1, 1
                    if it.underline then transition.cancel(it.underline); it.underline.alpha = 0 end
                end
            end
        end
    end
end

-- ====== СЦЕНА: DESTROY ======
function scene:destroy(event)
    if isLevelInfoOpen then
        if levelInfoGroup then
            if levelInfoGroup._close then levelInfoGroup._close() end
            display.remove(levelInfoGroup)
            levelInfoGroup = nil
        end
        isLevelInfoOpen = false
    end
    Runtime:removeEventListener("mouse", onMouseEvent)
    Runtime:removeEventListener("mouse", scene.onMouseScroll)
    destroyDynamicBackground()
    lvlButtonsTable = nil
    self.uiGroup = nil
end

scene:addEventListener("create", scene)
scene:addEventListener("show", scene)
scene:addEventListener("hide", scene)
scene:addEventListener("destroy", scene)

return scene