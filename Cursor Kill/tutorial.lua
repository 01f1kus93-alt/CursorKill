local composer = require("composer")
local scene = composer.newScene()

local uiButtons = {}
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
-- ФУНКЦИЯ НАВЕДЕНИЯ МЫШИ
-- =============================================================
local function onMouseEvent(event)
    if not uiButtons then return true end
    for i = 1, #uiButtons do
        local item = uiButtons[i]
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
-- СОЗДАНИЕ СЦЕНЫ
-- =============================================================
function scene:create(event)
    local sceneGroup = self.view
    uiButtons = {}

    -- Динамический фон (вместо статичного)
    createDynamicBackground(sceneGroup)

    -- Заголовок
    local title = display.newText({
        parent = sceneGroup,
        text = _G.getText("tutorial"),
        x = display.contentCenterX,
        y = 50,
        font = native.systemFontBold,
        fontSize = 38,
    })
    title:setFillColor(0.3, 0.8, 1)

    -- Начальная позиция для строк управления
    local startY = 85
    local stepY = 22
    local fontSize = 15

    -- Функция для отрисовки строк управления
    local function addControl(labelKey, keyText, highlight)
        local row = display.newGroup()
        sceneGroup:insert(row)

        local lbl = display.newText({
            parent = row,
            text = _G.getText(labelKey),
            x = display.contentCenterX - 30,
            y = 0,
            font = native.systemFont,
            fontSize = fontSize,
        })
        lbl.anchorX = 1
        lbl:setFillColor(0.6, 0.6, 0.7)

        local k = display.newText({
            parent = row,
            text = keyText,
            x = display.contentCenterX + 30,
            y = 0,
            font = native.systemFontBold,
            fontSize = fontSize,
        })
        k.anchorX = 0
        if highlight then
            k:setFillColor(1, 0.8, 0.2)
        else
            k:setFillColor(1, 0.8, 0.3)
        end

        row.y = startY
        startY = startY + stepY
    end

    -- ===== ДВИЖЕНИЕ =====
    addControl("move_control", "W, A, S, D / Стрелки")
    addControl("run_control", "L-SHIFT / R-SHIFT")
    addControl("crouch_control", "L-CTRL / R-CTRL")
    addControl("dash_control", "SPACE")
    startY = startY + 4

    -- ===== БОЕВЫЕ ДЕЙСТВИЯ =====
    addControl("fire_control", "ENTER / " .. _G.getText("mouse_left"))
    addControl("aim_control", _G.getText("mouse_right"))
    addControl("reload_control", "R")
    addControl("weapon_select", "1, 2, 3, 4, 5, 6")
    startY = startY + 4

    -- ===== ПРЕДМЕТЫ И СПОСОБНОСТИ =====
    addControl("heal_control", "V")
    addControl("energy_control", "C")
    addControl("grenade_throw", "G")
    addControl("extra_use", "F")
    addControl("ultimate", "X")
    startY = startY + 4

    -- ===== ИНТЕРФЕЙС =====
    addControl("pause_control", "ESC")
    addControl("interact", "E")  -- Добавляем взаимодействие (двери, сундуки, трейдер)

    -- ===== ДОПОЛНИТЕЛЬНО =====
    addControl("fire_mode", "Q (AK-47)")   -- Переключение режима стрельбы
    addControl("extra_switch", "Z")        -- Переключение экстра-способности
    addControl("ultimate_switch", "TAB")   -- Переключение ультимейта

    -- ===== ПОДСКАЗКА ПО МЫШИ =====
    local mouseHint = display.newText({
        parent = sceneGroup,
        text = "🖱 ЛКМ = стрельба | ПКМ = прицеливание (зажать)",
        x = display.contentCenterX,
        y = startY + 10,
        font = native.systemFont,
        fontSize = 14,
    })
    mouseHint:setFillColor(0.5, 0.5, 0.6)

    -- Кнопка Назад (фиксированная позиция)
    local backY = display.actualContentHeight - 60
    local backTxt = display.newText({
        parent = sceneGroup,
        text = _G.getText("back"),
        x = display.contentCenterX,
        y = backY,
        font = native.systemFont,
        fontSize = 28,
    })
    backTxt:setFillColor(0.7, 0.7, 1)

    local backUnderline = display.newLine(sceneGroup, backTxt.x - backTxt.width/2, backTxt.y + 15, backTxt.x + backTxt.width/2, backTxt.y + 15)
    backUnderline:setStrokeColor(1, 0.5, 0.5)
    backUnderline.strokeWidth = 2
    backUnderline.alpha = 0

    backTxt:addEventListener("touch", function(e)
        if e.phase == "ended" then
            composer.gotoScene("menu", { effect = "fade", time = 400 })
        end
        return true
    end)

    uiButtons[#uiButtons + 1] = { text = backTxt, underline = backUnderline, isHovered = false }
end

-- =============================================================
-- ПОКАЗ СЦЕНЫ
-- =============================================================
function scene:show(event)
    if event.phase == "did" then
        Runtime:addEventListener("mouse", onMouseEvent)
        activateBackgroundListeners()
    end
end

-- =============================================================
-- СКРЫТИЕ СЦЕНЫ
-- =============================================================
function scene:hide(event)
    if event.phase == "will" then
        Runtime:removeEventListener("mouse", onMouseEvent)
        deactivateBackgroundListeners()

        -- Сброс визуального состояния кнопок
        for i = 1, #uiButtons do
            local it = uiButtons[i]
            transition.cancel(it.text)
            it.isHovered = false
            it.text.xScale, it.text.yScale = 1, 1
            if it.underline then it.underline.alpha = 0 end
        end
    end
end

-- =============================================================
-- УНИЧТОЖЕНИЕ СЦЕНЫ
-- =============================================================
function scene:destroy(event)
    Runtime:removeEventListener("mouse", onMouseEvent)
    destroyDynamicBackground()
end

scene:addEventListener("create", scene)
scene:addEventListener("show", scene)
scene:addEventListener("hide", scene)
scene:addEventListener("destroy", scene)

return scene