local composer = require("composer")
display.setStatusBar(display.HiddenStatusBar)

-- ============================================================
--  ГЛОБАЛЬНЫЕ ПЕРЕВОДЫ
--  Структура: _G.languages[язык][ключ] = текст
--  Для добавления нового языка скопируйте секцию en или ru
--  и переведите значения.
-- ============================================================
_G.languages = {
    ru = {
        -- ====== ОБЩИЙ ИНТЕРФЕЙС ======
        title = "Cursor Kill",
        start = "Уровни",
        settings = "Настройки",
        exit = "Выйти",
        back = "Назад",
        language = "Язык",
        russian = "Русский",
        english = "Английский",
        confirmTitle = "Подтверждение",
        confirmMessageLanguage = "Сменить язык?",
        yes = "Да",
        no = "Нет",
        currentLang = "Текущий язык:",
        levelsTitle = "Выбор уровня",
        levelComplete = "Уровень пройден!",
        levelLocked = "Сначала пройдите предыдущий уровень",
        levelLockedPrefix = "Сначала пройдите: ",
        elevatorOpened = "Лифт открыт",
        elevatorHint = "Нажмите E чтобы зайти",
        dead = "Смерть",
        guide = "Добро пожаловать в Cursor Kill\n\nПробел = рывок\nШифт = бег\nКтрл = присед\nR = перезарядка\nЛКМ = выстрел\n1/2 = смена оружия\n\n[ Нажмите, чтобы начать ]",
        tutorial = "Туториал",

        -- ====== УРОВНИ ======
        main_door = "Главный вход",
        two_floor = "Этаж 2",
        three_floor = "Этаж 3",
        four_floor = "Этаж 4",
        basement = "Подвал",

        difficulty = "Сложность",
        levelGoal = "Цель: зачистить",
        zombies = "зомби",
        levelReward = "Награда",
        goToBattle = "В бой",
        easy = "Лёгкий",
        medium = "Средний",
        hard = "Тяжёлый",

        -- ====== НАГРАДЫ ======
        reward_brains = "Мозги",
        reward_medkit = "Аптечка",
        reward_energy = "Энергетик",
        reward_grenade = "Граната",
        reward_ammo = "Патроны",

        -- ====== УПРАВЛЕНИЕ ======
        extra_use = "ЭКСТРА-НАВЫК",
        move_control = "ПЕРЕМЕЩЕНИЕ",
        interact = "Взаимодействие",
        fire_mode = "Режим огня",
        extra_switch = "Смена экстра",
        ultimate_switch = "Смена ульты",
        run_control = "УСКОРЕНИЕ (БЕГ)",
        crouch_control = "ПРИСЕД / ТИХО",
        dash_control = "РЫВОК",
        fire_control = "ОГОНЬ / УДАР",
        aim_control = "ПРИЦЕЛИВАНИЕ",
        reload_control = "ПЕРЕЗАРЯДКА",
        weapon_select = "ВЫБОР ОРУЖИЯ",
        pause_control = "ПАУЗА",
        mouse_left = "ЛКМ",
        mouse_right = "ПКМ",
        heal_control = "АПТЕЧКА",
        energy_control = "ЭНЕРГЕТИК",
        long_aim = "Зажмите для прицеливания",
        energy_active = "Энергетик уже активирован",
        grenade_throw = "ГРАНАТА",
        ultimate = "УЛЬТА",

        -- ====== ОРУЖИЕ ======
        pistol = "Пистолет",
        rifle = "Автомат",
        shotgun = "Дробовик",
        aimWait = "Подождите пока линия станет зеленой для прицеливания",

        -- ====== ПРОЧЕЕ ======
        trader = "Трейдер",
    },
    en = {
        -- ====== COMMON UI ======
        interact = "Interact",
fire_mode = "Fire mode",
extra_switch = "Switch extra",
ultimate_switch = "Switch ultimate",
        title = "Cursor Kill",
        start = "Levels",
        settings = "Settings",
        exit = "Exit",
        back = "Back",
        language = "Language",
        russian = "Russian",
        english = "English",
        confirmTitle = "Confirmation",
        confirmMessageLanguage = "Change language?",
        yes = "Yes",
        no = "No",
        currentLang = "Current language:",
        levelsTitle = "Level Select",
        levelComplete = "Level complete!",
        levelLocked = "Complete the previous level first",
        levelLockedPrefix = "Complete previous level: ",
        elevatorOpened = "Elevator unlocked",
        elevatorHint = "Press E to enter",
        dead = "Dead",
        guide = "Welcome to Cursor Kill\n\nSpace = Dash\nShift = Run\nCtrl = Crouch\nR = Reload\nLMB = Shoot\n1/2 = change weapon\n\n[ Click to start ]",
        tutorial = "Tutorial",

        -- ====== LEVELS ======
        main_door = "Main entrance",
        two_floor = "Floor 2",
        four_floor = "Floor 4",
        three_floor = "Floor 3",
        basement = "Basement",

        difficulty = "Difficulty",
        levelGoal = "Goal: eliminate",
        zombies = "zombies",
        levelReward = "Reward",
        goToBattle = "Fight",
        easy = "Easy",
        medium = "Medium",
        hard = "Hard",

        -- ====== REWARDS ======
        reward_brains = "Brains",
        reward_medkit = "Medkit",
        reward_energy = "Energy Drink",
        reward_grenade = "Grenade",
        reward_ammo = "Ammo",

        -- ====== CONTROLS ======
        extra_use = "EXTRA SKILL",
        move_control = "MOVEMENT",
        run_control = "SPRINT (RUN)",
        crouch_control = "CROUCH / STEALTH",
        dash_control = "DASH",
        fire_control = "FIRE / ATTACK",
        aim_control = "AIMING",
        reload_control = "RELOAD",
        weapon_select = "WEAPON SELECT",
        pause_control = "PAUSE",
        mouse_left = "LMB",
        mouse_right = "RMB",
        heal_control = "MEDKIT",
        energy_control = "ENERGY DRINK",
        long_aim = "Aim a bit longer",
        energy_active = "ENERGY BOOST ALREADY ACTIVE",
        grenade_throw = "USE GRENADE",
        ultimate = "ULTIMATE",

        -- ====== WEAPONS ======
        pistol = "Pistol",
        rifle = "Rifle",
        shotgun = "Shotgun",
        aimWait = "Wait until the line turns green to aim",

        -- ====== OTHER ======
        trader = "Trader",
    }
}

-- Текущий язык (по умолчанию русский)
_G.currentLanguage = "ru"

-- Функция для получения перевода
function _G.getText(key)
    if _G.languages[_G.currentLanguage] and _G.languages[_G.currentLanguage][key] then
        return _G.languages[_G.currentLanguage][key]
    end
    return key
end
print(system.pathForFile("", system.DocumentsDirectory))
-- Переход в главное меню
composer.gotoScene("menu")