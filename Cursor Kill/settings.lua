local composer = require("composer")
local scene = composer.newScene()

local settingsItems = {}
local allItems = {} 
local confirmGroup
local titleText, backItem
local backgroundEffects = nil

-- =============================================================
-- ДИНАМИЧЕСКИЙ ФОН (как в меню)
-- =============================================================
local function createDynamicBackground(sceneGroup)
    -- Основной фон (тёмный, с изменяемым оттенком)
    local bg = display.newRect(sceneGroup, display.contentCenterX, display.contentCenterY, display.actualContentWidth, display.actualContentHeight)
    bg:setFillColor(0.05, 0.05, 0.1)

    -- Группа для эффектов (круги)
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

    -- Функция движения кругов
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

    -- Функция плавного изменения цвета фона
    local bgHue = 0
    local function animateBG()
        if not bg or not bg.parent then return end
        bgHue = bgHue + 0.001
        local r = 0.05 + 0.02 * math.sin(bgHue)
        local g = 0.05 + 0.01 * math.sin(bgHue + 2)
        local b = 0.1 + 0.02 * math.sin(bgHue + 4)
        bg:setFillColor(r, g, b)
    end

    -- Сохраняем всё в структуру
    backgroundEffects = {
        group = fxGroup,
        bg = bg,
        circles = circles,
        moveCircles = moveCircles,
        animateBG = animateBG,
        listenersActive = false
    }
end

-- Активировать слушатели фона
local function activateBackgroundListeners()
    if backgroundEffects and not backgroundEffects.listenersActive then
        Runtime:addEventListener("enterFrame", backgroundEffects.moveCircles)
        Runtime:addEventListener("enterFrame", backgroundEffects.animateBG)
        backgroundEffects.listenersActive = true
    end
end

-- Деактивировать слушатели фона
local function deactivateBackgroundListeners()
    if backgroundEffects and backgroundEffects.listenersActive then
        Runtime:removeEventListener("enterFrame", backgroundEffects.moveCircles)
        Runtime:removeEventListener("enterFrame", backgroundEffects.animateBG)
        backgroundEffects.listenersActive = false
    end
end

-- Полное удаление фона
local function destroyDynamicBackground()
    deactivateBackgroundListeners()
    if backgroundEffects then
        if backgroundEffects.group then display.remove(backgroundEffects.group) end
        if backgroundEffects.bg then display.remove(backgroundEffects.bg) end
        backgroundEffects = nil
    end
end

-- =============================================================
-- Универсальная функция для наведения мыши
-- =============================================================
local function onMouseEvent(event)
    if confirmGroup or not allItems then return true end

    for i = 1, #allItems do
        local item = allItems[i]
        if item.text and item.text.contentBounds then
            local b = item.text.contentBounds
            local isHover = (event.x >= b.xMin and event.x <= b.xMax and event.y >= b.yMin and event.y <= b.yMax)

            if isHover and not item.isHovered then
                item.isHovered = true
                transition.cancel(item.text)
                transition.to(item.text, { time = 150, xScale = 1.1, yScale = 1.1 })
                if item.underline then
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

-- =============================================================
-- Окно подтверждения смены языка
-- =============================================================
local function showConfirmDialog(sceneGroup, newLang)
    if confirmGroup then display.remove(confirmGroup); confirmGroup = nil end

    confirmGroup = display.newGroup()
    sceneGroup:insert(confirmGroup)

    -- Фон-затемнение
    local overlay = display.newRect(confirmGroup, display.contentCenterX, display.contentCenterY, display.actualContentWidth, display.actualContentHeight)
    overlay:setFillColor(0, 0, 0, 0.6)
    overlay:addEventListener("touch", function() return true end)

    -- Рамка окна
    local box = display.newRoundedRect(confirmGroup, display.contentCenterX, display.contentCenterY, 320, 220, 16)
    box:setFillColor(0.15, 0.15, 0.22); box:setStrokeColor(0.5, 0.5, 0.7); box.strokeWidth = 2

    local confirmTitle = display.newText({
        parent = confirmGroup, text = _G.getText("confirmTitle"),
        x = display.contentCenterX, y = display.contentCenterY - 70,
        font = native.systemFontBold, fontSize = 28
    })
    confirmTitle:setFillColor(1, 0.8, 0.3)

    local confirmMsg = display.newText({
        parent = confirmGroup, text = _G.getText("confirmMessageLanguage"),
        x = display.contentCenterX, y = display.contentCenterY - 25,
        font = native.systemFont, fontSize = 20
    })

    local langName = (newLang == "ru") and _G.getText("russian") or _G.getText("english")
    local langInfo = display.newText({
        parent = confirmGroup, text = "→ " .. langName,
        x = display.contentCenterX, y = display.contentCenterY + 15,
        font = native.systemFont, fontSize = 20
    })
    langInfo:setFillColor(0.6, 0.8, 1)

    -- Кнопка ДА
    local yesText = display.newText({
        parent = confirmGroup, text = _G.getText("yes"),
        x = display.contentCenterX - 60, y = display.contentCenterY + 70,
        font = native.systemFontBold, fontSize = 26
    })
    yesText:setFillColor(0.3, 1, 0.3)

    -- Кнопка НЕТ
    local noText = display.newText({
        parent = confirmGroup, text = _G.getText("no"),
        x = display.contentCenterX + 60, y = display.contentCenterY + 70,
        font = native.systemFontBold, fontSize = 26
    })
    noText:setFillColor(1, 0.3, 0.3)

    yesText:addEventListener("touch", function(e)
        if e.phase == "ended" then
            _G.currentLanguage = newLang
            composer.removeScene("settings") 
            composer.removeScene("menu")
            composer.removeScene("levels")
            composer.removeScene("game")
            composer.removeScene("tutorial")    
            composer.gotoScene("settings", { effect = "fade", time = 200 })
        end
        return true
    end)

    noText:addEventListener("touch", function(e)
        if e.phase == "ended" then display.remove(confirmGroup); confirmGroup = nil end
        return true
    end)

    confirmGroup.alpha = 0
    transition.to(confirmGroup, { time = 200, alpha = 1 })
end

-- =============================================================
-- Вспомогательная функция для линий
-- =============================================================
local function createUnderline(parent, txt)
    local line = display.newLine(parent, txt.x - txt.width / 2, txt.y + 18, txt.x + txt.width / 2, txt.y + 18)
    line:setStrokeColor(1, 0.5, 0.5); line.strokeWidth = 2; line.alpha = 0
    return line
end

-- =============================================================
-- СОЗДАНИЕ СЦЕНЫ
-- =============================================================
function scene:create(event)
    local sceneGroup = self.view
    settingsItems = {}
    allItems = {}

    -- Динамический фон (вместо статичного)
    createDynamicBackground(sceneGroup)

    titleText = display.newText({
        parent = sceneGroup, text = _G.getText("settings"),
        x = display.contentCenterX, y = display.contentCenterY - 180,
        font = native.systemFontBold, fontSize = 44
    })
    titleText:setFillColor(1, 0.6, 0.2)

    local langLabel = (_G.currentLanguage == "ru") and _G.getText("russian") or _G.getText("english")
    local curLangTxt = display.newText({
        parent = sceneGroup, text = _G.getText("currentLang") .. " " .. langLabel,
        x = display.contentCenterX, y = display.contentCenterY - 100,
        font = native.systemFont, fontSize = 24
    })
    curLangTxt:setFillColor(0.7, 0.7, 0.7)

    local langButtons = { { key = "russian", lang = "ru" }, { key = "english", lang = "en" } }
    local startY = display.contentCenterY - 20

    for i, btn in ipairs(langButtons) do
        local y = startY + (i - 1) * 65
        local txt = display.newText({
            parent = sceneGroup, text = _G.getText(btn.key),
            x = display.contentCenterX, y = y,
            font = native.systemFont, fontSize = 30
        })

        if btn.lang == _G.currentLanguage then txt:setFillColor(0.3, 1, 0.5)
        else txt:setFillColor(0.9, 0.9, 0.9) end

        local underline = createUnderline(sceneGroup, txt)
        txt:addEventListener("touch", function(e)
            if e.phase == "ended" and btn.lang ~= _G.currentLanguage then
                showConfirmDialog(sceneGroup, btn.lang)
            end
            return true 
        end)

        local item = { text = txt, underline = underline, isHovered = false }
        settingsItems[#settingsItems + 1] = item
        allItems[#allItems + 1] = item
    end

    local backTxt = display.newText({
        parent = sceneGroup, text = _G.getText("back"),
        x = display.contentCenterX, y = display.contentCenterY + 170,
        font = native.systemFont, fontSize = 28
    })
    backTxt:setFillColor(0.7, 0.7, 1)
    local backUnderline = createUnderline(sceneGroup, backTxt)

    backTxt:addEventListener("touch", function(e)
        if e.phase == "ended" then composer.gotoScene("menu", { effect = "fade", time = 400 }) end
        return true
    end)

    backItem = { text = backTxt, underline = backUnderline, isHovered = false }
    allItems[#allItems + 1] = backItem
end

-- =============================================================
-- ПОКАЗ СЦЕНЫ
-- =============================================================
function scene:show(event)
    if event.phase == "did" then
        Runtime:addEventListener("mouse", onMouseEvent)
        activateBackgroundListeners() -- включаем анимацию фона
    end
end

-- =============================================================
-- СКРЫТИЕ СЦЕНЫ
-- =============================================================
function scene:hide(event)
    if event.phase == "will" then
        Runtime:removeEventListener("mouse", onMouseEvent)
        deactivateBackgroundListeners() -- выключаем анимацию фона
        
        if confirmGroup then display.remove(confirmGroup); confirmGroup = nil end
        
        for i = 1, #allItems do
            local item = allItems[i]
            item.isHovered = false
            transition.cancel(item.text)
            item.text.xScale, item.text.yScale = 1, 1
            if item.underline then transition.cancel(item.underline); item.underline.alpha = 0 end
        end
    end
end

-- =============================================================
-- УНИЧТОЖЕНИЕ СЦЕНЫ
-- =============================================================
function scene:destroy(event)
    Runtime:removeEventListener("mouse", onMouseEvent)
    destroyDynamicBackground() -- полностью удаляем фон
    settingsItems, allItems, backItem = nil, nil, nil
end

scene:addEventListener("create", scene)
scene:addEventListener("show", scene)
scene:addEventListener("hide", scene)
scene:addEventListener("destroy", scene)

return scene