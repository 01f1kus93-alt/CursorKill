local composer = require("composer")
local scene = composer.newScene()
local json = require("json")

-- =============================================================
-- НАСТРОЙКИ (JSONBIN & STORAGE)
-- =============================================================
local VERSION_URL = "https://api.jsonbin.io/v3/b/69b6ccc3aa77b81da9e85299"
local MASTER_KEY = "$2a$10$vdXQ4G2Ba0K/AaAcjArOUu51lJOjUNff4L7xiF45B5yLAdpO1hC1a"
local CURRENT_VERSION = "0.9"
local VERSION_NAME = "pre alpha stable"

local settingsFile = "app_settings.json"

local function saveSettings(data)
    local path = system.pathForFile(settingsFile, system.DocumentsDirectory)
    local file = io.open(path, "w")
    if file then
        file:write(json.encode(data))
        io.close(file)
    end
end

local function loadSettings()
    local path = system.pathForFile(settingsFile, system.DocumentsDirectory)
    local file = io.open(path, "r")
    if file then
        local contents = file:read("*a")
        io.close(file)
        return json.decode(contents) or {}
    end
    return {}
end

local appSettings = loadSettings()
local menuItems = {}
local titleText, verTxt, fikustext
local loadingGroup, progressBar, progressText, statusText
local updateOverlay = nil
local versionChecked = false
local menuShown = false
local backgroundEffects = nil

-- =============================================================
-- ФУНКЦИЯ НАВЕДЕНИЯ МЫШИ (Hover)
-- =============================================================
local function onMouseEvent(event)
    if updateOverlay or loadingGroup or not menuItems then return true end
    
    for i = 1, #menuItems do
        local item = menuItems[i]
        if item.text and item.text.contentBounds then
            local b = item.text.contentBounds
            local isHover = (event.x >= b.xMin and event.x <= b.xMax and event.y >= b.yMin and event.y <= b.yMax)

            if isHover and not item.isHovered then
                item.isHovered = true
                
                if not item.text.pulse then
                    transition.to(item.text, { time = 150, xScale = 1.1, yScale = 1.1 })
                end
                
                if item.underline then 
                    transition.to(item.underline, { time = 150, alpha = 1 }) 
                end

            elseif not isHover and item.isHovered then
                item.isHovered = false
                
                if not item.text.pulse then
                    transition.to(item.text, { time = 150, xScale = 1, yScale = 1 })
                end
                
                if item.underline then 
                    transition.to(item.underline, { time = 150, alpha = 0 }) 
                end
            end
        end
    end
    return true
end


-- =============================================================
-- ВСПОМОГАТЕЛЬНЫЕ ФУНКЦИИ
-- =============================================================
local function updateProgress(percent, message)
    if progressBar and progressText then
        progressBar.width = 300 * (percent / 100)
        progressText.text = math.floor(percent) .. "%"
    end
    if statusText and message then statusText.text = message end
end

local function showMessageWindow(title, message, showContinue, onContinue)
    if not scene.view then return end
    if updateOverlay then display.remove(updateOverlay); updateOverlay = nil end

    local sceneGroup = scene.view
    updateOverlay = display.newGroup()
    sceneGroup:insert(updateOverlay)

    local bgOverlay = display.newRect(updateOverlay, display.contentCenterX, display.contentCenterY, display.actualContentWidth, display.actualContentHeight)
    bgOverlay:setFillColor(0, 0, 0, 0.8); bgOverlay:addEventListener("touch", function() return true end)

    local window = display.newRoundedRect(updateOverlay, display.contentCenterX, display.contentCenterY, 500, 320, 20)
    window:setFillColor(0.1, 0.1, 0.15); window.strokeWidth = 4; window:setStrokeColor(1, 0.3, 0.3)

    local tTxt = display.newText({ parent = updateOverlay, text = title, x = display.contentCenterX, y = display.contentCenterY - 90, font = native.systemFontBold, fontSize = 26 })
    tTxt:setFillColor(1, 0.3, 0.3)

    local desc = display.newText({ parent = updateOverlay, text = message, x = display.contentCenterX, y = display.contentCenterY - 20, width = 420, align = "center", font = native.systemFont, fontSize = 18 })

    local tgBtn = display.newRoundedRect(updateOverlay, display.contentCenterX - 120, display.contentCenterY + 80, 200, 50, 15)
    tgBtn:setFillColor(0, 0.45, 0.85)
    display.newText({ parent = updateOverlay, text = "@CursorKill", x = tgBtn.x, y = tgBtn.y, font = native.systemFontBold, fontSize = 22 })
    tgBtn:addEventListener("tap", function() system.openURL("https://t.me/@CursorKill"); return true end)

    if showContinue then
        local continueBtn = display.newRoundedRect(updateOverlay, display.contentCenterX + 120, display.contentCenterY + 80, 200, 50, 15)
        continueBtn:setFillColor(0.3, 0.3, 0.3)
        display.newText({ parent = updateOverlay, text = "ПРОДОЛЖИТЬ", x = continueBtn.x, y = continueBtn.y, font = native.systemFontBold, fontSize = 22 })
        continueBtn:addEventListener("tap", function()
            display.remove(updateOverlay); updateOverlay = nil
            if onContinue then onContinue() end
            return true
        end)
    end
    updateOverlay.alpha = 0; transition.to(updateOverlay, { time = 400, alpha = 1 })
end

local function hideLoadingAndShowMenu()
    if menuShown then return end
    menuShown = true
    if loadingGroup then
        transition.to(loadingGroup, { time = 300, alpha = 0, onComplete = function() display.remove(loadingGroup); loadingGroup = nil end })
    end
    for _, item in ipairs(menuItems) do if item.text then transition.to(item.text, { time = 500, alpha = 1 }) end end
    if titleText then transition.to(titleText, { time = 500, alpha = 1 }) end
    if verTxt then transition.to(verTxt, { time = 500, alpha = 1 }) end
    if fikustext then transition.to(fikustext, { time = 500, alpha = 0.5 }) end
end

local function checkAppVersion()
    if versionChecked then return end
    versionChecked = true

    updateProgress(30, "Подключение к серверу...")
    print("Checking version at URL: " .. VERSION_URL)

    local params = { 
        headers = { 
            ["X-Master-Key"] = MASTER_KEY,
            ["Content-Type"] = "application/json"
        },
        timeout = 10
    }

    network.request(VERSION_URL, "GET", function(event)
        print("Version check response status:", event.status)
        
        if event.isError then
            print("Version check error:", event.errorMessage or "unknown")
            updateProgress(100, "Ошибка подключения")
            timer.performWithDelay(500, hideLoadingAndShowMenu)
            return
        end

        if event.status ~= 200 then
            print("Version check HTTP error:", event.status)
            updateProgress(100, "Ошибка сервера")
            timer.performWithDelay(500, hideLoadingAndShowMenu)
            return
        end

        local success, data = pcall(json.decode, event.response)
        if not success then
            print("JSON decode error")
            updateProgress(100, "Некорректный ответ")
            timer.performWithDelay(500, hideLoadingAndShowMenu)
            return
        end

        print("Decoded JSON:", json.encode(data))
        
        if not data or not data.record or data.record.actualVersion == nil then
            print("Missing actualVersion field")
            updateProgress(100, "Некорректный формат")
            timer.performWithDelay(500, hideLoadingAndShowMenu)
            return
        end

        local serverVersion = tostring(data.record.actualVersion)
        print("Server version:", serverVersion, "Current version:", CURRENT_VERSION)

        if serverVersion ~= CURRENT_VERSION then
            updateProgress(100, "Обнаружена новая версия")
            showMessageWindow("НОВАЯ ВЕРСИЯ!", 
                "Актуальная: " .. serverVersion .. "\nВаша: " .. CURRENT_VERSION, 
                true, hideLoadingAndShowMenu)
        else
            updateProgress(100, "Готово")
            hideLoadingAndShowMenu()
        end
    end, params)
end

-- =============================================================
-- ДИНАМИЧЕСКИЙ ФОН
-- =============================================================
local function createDynamicBackground(sceneGroup)
    local bg = display.newRect(sceneGroup, display.contentCenterX, display.contentCenterY, display.actualContentWidth, display.actualContentHeight)
    bg:setFillColor(0.05, 0.05, 0.1)
    local fxGroup = display.newGroup(); sceneGroup:insert(fxGroup)
    local circles = {}
    local colors = {{0.4, 0.1, 0.1, 0.15}, {0.2, 0.2, 0.3, 0.1}, {0.15, 0.15, 0.15, 0.2}}
    for i = 1, 5 do
        local radius = math.random(150, 300)
        local circle = display.newCircle(fxGroup, math.random(0, display.actualContentWidth), math.random(0, display.actualContentHeight), radius)
        circle:setFillColor(unpack(colors[math.random(#colors)])); circle.blendMode = "add"; circle.alpha = 0.3
        circle.speedX, circle.speedY, circle.scaleSpeed = (math.random()-0.5)*0.2, (math.random()-0.5)*0.2, (math.random()-0.5)*0.002
        table.insert(circles, circle)
    end
    backgroundEffects = { group = fxGroup, bg = bg, circles = circles, active = false,
        moveCircles = function()
            for _, c in ipairs(circles) do
                c.x, c.y = c.x + c.speedX, c.y + c.speedY
                if c.x < -c.width then c.x = display.actualContentWidth + c.width elseif c.x > display.actualContentWidth + c.width then c.x = -c.width end
                local newS = c.xScale + c.scaleSpeed; if newS < 0.8 or newS > 1.2 then c.scaleSpeed = -c.scaleSpeed end
                c.xScale, c.yScale = newS, newS
            end
        end,
        animateBG = function()
            local hue = system.getTimer() * 0.0005
            bg:setFillColor(0.05 + 0.02 * math.sin(hue), 0.05 + 0.01 * math.sin(hue+2), 0.1 + 0.02 * math.sin(hue+4))
        end
    }
end

local function activateBackground()
    if backgroundEffects and not backgroundEffects.active then
        Runtime:addEventListener("enterFrame", backgroundEffects.moveCircles)
        Runtime:addEventListener("enterFrame", backgroundEffects.animateBG)
        backgroundEffects.active = true
    end
end

-- =============================================================
-- СОЗДАНИЕ СЦЕНЫ
-- =============================================================
function scene:create(event)
    local sceneGroup = self.view
    createDynamicBackground(sceneGroup)

    titleText = display.newText({ parent = sceneGroup, text = _G.getText("title"), x = display.contentCenterX, y = display.contentCenterY - 180, font = native.systemFontBold, fontSize = 52 })
    titleText:setFillColor(1, 0.3, 0.3); titleText.alpha = 0

    verTxt = display.newText(sceneGroup, CURRENT_VERSION.." "..VERSION_NAME, display.contentCenterX, display.contentCenterY - 140, native.systemFontBold, 15)
    verTxt:setFillColor(0.6, 0.4, 0.4); verTxt.alpha = 0

    local buttons = {
        { key = "start", scene = "levels" },
        { key = "settings", scene = "settings" },
        { key = "tutorial", scene = "tutorial" },
        { key = "exit", action = function() native.requestExit() end }
    }

    local startY = display.contentCenterY - 50
    for i, btn in ipairs(buttons) do
        local y = startY + (i - 1) * 70
        local txt = display.newText({ parent = sceneGroup, text = _G.getText(btn.key), x = display.contentCenterX, y = y, font = native.systemFont, fontSize = 34 })
        txt:setFillColor(0.9, 0.9, 0.9); txt.alpha = 0

        if btn.key == "tutorial" and not appSettings.tutorialDone then
            txt.pulse = transition.to(txt, { time = 1700, xScale = 1.2, yScale = 1.2, iterations = -1, transition = easing.continuousLoop })
        end

        txt:addEventListener("touch", function(e)
            if e.phase == "ended" then
                if btn.key == "tutorial" and not appSettings.tutorialDone then
                    appSettings.tutorialDone = true; saveSettings(appSettings)
                    if txt.pulse then transition.cancel(txt.pulse); txt.xScale, txt.yScale = 1, 1 end
                end
                if btn.scene and menuShown then composer.gotoScene(btn.scene, { effect = "fade", time = 300 })
                elseif btn.action then btn.action() end
            end
            return true
        end)

        local underline = display.newLine(sceneGroup, txt.x - txt.width/2, y + 24, txt.x + txt.width/2, y + 24)
        underline:setStrokeColor(1, 0.4, 0.4); underline.strokeWidth = 2; underline.alpha = 0
        menuItems[#menuItems + 1] = { text = txt, underline = underline, isHovered = false }
    end

    fikustext = display.newText(sceneGroup, "f1kusdev", display.contentCenterX, display.contentCenterY - 210, native.systemFontBold, 22)
    fikustext.alpha = 0; fikustext:setFillColor(0.6, 0.4, 0.4)
    fikustext:addEventListener("touch", function(e)
        if e.phase == "ended" then
            transition.to(fikustext, { time=75, alpha=1, onComplete=function() transition.to(fikustext, { time=50, alpha=0.5 }) end })
            system.openURL("https://t.me/@CursorKill")
        end
        return true
    end)

    -- ГРУППА ЗАГРУЗКИ (СДЕЛАНА ПОЛУПРОЗРАЧНОЙ, ЧТОБЫ БЫЛ ВИДЕН ДИНАМИЧЕСКИЙ ФОН)
    loadingGroup = display.newGroup(); sceneGroup:insert(loadingGroup)
    local lBg = display.newRect(loadingGroup, display.contentCenterX, display.contentCenterY, display.actualContentWidth, display.actualContentHeight)
    lBg:setFillColor(0, 0, 0, 0.6)  -- Изменено с 0.95 на 0.6, чтобы фон просвечивал
    progressBar = display.newRoundedRect(loadingGroup, display.contentCenterX-150, display.contentCenterY, 0, 26, 8)
    progressBar:setFillColor(1,0.3,0.3); progressBar.anchorX = 0
    progressText = display.newText({ parent = loadingGroup, text = "0%", x = display.contentCenterX, y = display.contentCenterY-30, font = native.systemFontBold, fontSize = 24 })
    statusText = display.newText({ parent = loadingGroup, text = "Инициализация...", x = display.contentCenterX, y = display.contentCenterY+30, font = native.systemFont, fontSize = 18 })
end

function scene:show(event)
    if event.phase == "did" then
        Runtime:addEventListener("mouse", onMouseEvent)
        activateBackground()  -- Запускаем анимацию фона (она будет видна сквозь полупрозрачный loadingGroup)
        if not versionChecked then checkAppVersion() elseif not menuShown then hideLoadingAndShowMenu() end
    end
end

function scene:hide(event)
    if event.phase == "will" then
        Runtime:removeEventListener("mouse", onMouseEvent)
        if backgroundEffects then
            Runtime:removeEventListener("enterFrame", backgroundEffects.moveCircles)
            Runtime:removeEventListener("enterFrame", backgroundEffects.animateBG)
            backgroundEffects.active = false
        end
    end
end

scene:addEventListener("create", scene)
scene:addEventListener("show", scene)
scene:addEventListener("hide", scene)
return scene