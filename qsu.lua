local imgui = require 'mimgui'
local encoding = require 'encoding'
local ffi = require 'ffi'
encoding.default = 'CP1251'
u8 = encoding.UTF8

local new = imgui.new
local renderWindow = new.bool(false)
local inputField = new.char[256]()
local str = ffi.string

local json = require 'json'
local requests = require 'requests'

script_author('Matsubaru')
script_name('Быстрый розыск v2')

local id = 0
local nick = ''

local dlstatus = require('moonloader').download_status
local sampev = require 'lib.samp.events'


local version = 1.4
update_state = false
local update_url = requests.get("https://raw.githubusercontent.com/Matsubaru-Code/QSU/refs/heads/main/update.json")
local script_url = "https://github.com/Matsubaru-Code/QSU/raw/refs/heads/main/qsu.lua"
local script_path = thisScript().path
a = decodeJson(update_url.text) -- Получаем её, декодируем



imgui.OnInitialize(function()
    imgui.GetIO().IniFilename = nil
    DarkTheme()
end)

function table.getValueByKey(t, k)
    k = k:gsub('%s+', '')
    local v = t[k]
    if v then return tonumber(v) end
    return 0
end



local serverData = {}
local serverList = {'Texas', 'Florida', 'Nevada', 'Hawaii', 'Indiana'}
local currentServer = 'Texas'



local function su(stat, lvl)
    lua_thread.create(function()
        sampSendChat(u8:decode'/me сняв КПК с тактического пояса, нашёл досье преступника, после чего зайдя в пункт "Wanted"..')
        wait(1000)
        sampSendChat(u8:decode'/me ..ввёл некоторые коррективы в досье преступника, после чего убрал КПК на тактический пояс')
        wait(1000)
        sampSendChat(u8:decode"/su "..id..' '..lvl..' '..stat)
        sampAddChatMessage(u8:decode"/su "..id..' '..lvl..' '..stat, -1)
    end)
end

function main()
    while not isSampAvailable() do wait(0) end
    --sampAddChatMessage(u8:decodea["version"],-1)
    if tonumber(a["version"]) > version then
        sampAddChatMessage(u8:decode"{0079bf}[QSU]:{FFFFFF}Есть обновление! Версия: {03A89E}" .. a["version"], -1)
        update_state = true
    end

    for _, name in ipairs(serverList) do
    serverData[name] = loadConfig(name)
    end
    sampRegisterChatCommand('qsu', function(arg)
        if arg == nil or arg == '' then
            sampAddChatMessage(u8:decode"{0079bf}[QSU]:{FFFFFF} Введите {03A89E}/qsu{FFFFFF} [ID].", -1)
            return
        end
        local playerId = tonumber(arg)
        if not playerId then
            sampAddChatMessage(u8:decode"{0079bf}[QSU]:{FFFFFF} ID должен быть числом.", -1)
            return
        end
        if sampIsPlayerConnected(playerId) then
            renderWindow[0] = not renderWindow[0]
            id = playerId
            nick = sampGetPlayerNickname(id)
        else
            sampAddChatMessage(u8:decode"{0079bf}[QSU]:{FFFFFF} Человека с id: {0079bf}"..playerId..', {c21d1d}не существует.', -1)
        end
    end)
    lua_thread.create(function()
        wait(7000)
        sampAddChatMessage(u8:decode'{0079bf}[QSU]:{FFFFFF} Script was created by {0079bf}Matsubaru Clan', -1)
        sampAddChatMessage(u8:decode'{0079bf}[QSU]:{FFFFFF} Для активации введите {03A89E}/qsu{FFFFFF} [ID].', -1)
    end)
    while true do
        wait(0)
        if not renderWindow[0] then
            imgui.Process = false
        end
        if update_state then
            downloadUrlToFile(script_url, script_path, function(id, status)
                if status == dlstatus.STATUS_ENDDOWNLOADDATA then
                    sampAddChatMessage(u8:decode"{0079bf}[QSU]:{FFFFFF}Скрипт успешно обновлен!", -1)
                    thisScript():reload()
                end
                update_state = false
            end)
            break
        end
    end
end



function loadConfig(server)
    local path = getWorkingDirectory()..'\\config\\'..server:lower()..'.json'
    local file = io.open(path, 'r')

    if not file then
        print('{0079bf}[QSU]:{FFFFFF} Не найден конфиг: '..server)
        return nil
    end

    local content = file:read('*a')
    file:close()

    local ok, data = pcall(json.decode, content)

    if not ok then
        print('{0079bf}[QSU]:{FFFFFF} Ошибка JSON: '..server)
        return nil
    end

    return data
end

local newFrame = imgui.OnFrame(
    function() return renderWindow[0] end,
    function(player)
        local resX, resY = getScreenResolution()
        local sizeX, sizeY = 750, 400
        imgui.SetNextWindowPos(imgui.ImVec2(resX / 2, resY / 2), imgui.Cond.FirstUseEver, imgui.ImVec2(0.5, 0.5))
        imgui.SetNextWindowSize(imgui.ImVec2(sizeX, sizeY), imgui.Cond.FirstUseEver)
        imgui.Begin('Быстрый розыск || '..nick..'['..id..']', renderWindow, imgui.WindowFlags.NoResize + imgui.WindowFlags.NoCollapse)
        imgui.SetWindowFontScale(1.1)

        -- вкладки серверов
        if imgui.BeginTabBar(u8'servers') then
            for _, name in ipairs(serverList) do
                if imgui.BeginTabItem(u8(name)) then
                    currentServer = name
                    imgui.EndTabItem()
                end
            end
            imgui.EndTabBar()
        end

        imgui.Separator()

        -- поле ввода + кнопка
        local inputText = u8:decode(str(inputField))
        local len = #inputText
        local width = math.max(110, math.min(400, len * 8))
        imgui.PushItemWidth(width)
        imgui.InputText(u8'', inputField, 256)
        imgui.SameLine()
        imgui.PopItemWidth()

        imgui.PushStyleVarFloat(imgui.StyleVar.FrameRounding, 8)
        -- Функция очистки номера статьи
        local function cleanArticleNumber(s)
            -- Оставляем только цифры и точку
            s = s:gsub('[^%d%.]', '')
            -- Убираем лишние точки в начале/конце/подряд
            s = s:gsub('^%.', ''):gsub('%.$', ''):gsub('%.%.+', '.')
            return s
        end

        if imgui.Button('Объявить', imgui.ImVec2(90, 25)) then
            local text = u8:decode(str(inputField))
            if text == '' then return end

            local data = serverData[currentServer]
            if not data then
                sampAddChatMessage(u8:decode'{0079bf}[QSU]:{FFFFFF} Ошибка конфига: '..currentServer, -1)
                return
            end

            local articles = {}
            for part in text:gmatch('[^%+]+') do
                local cleaned = cleanArticleNumber(part)
                if cleaned ~= '' then
                    table.insert(articles, cleaned)
                end
            end
            sampAddChatMessage(u8:decode"Обработанные статьи: " .. table.concat(articles, ", "), -1)
            local total = 0
            local result = {}
            local found = false

            for _, art in ipairs(articles) do
                local value = data.zvesdi[art]
                if value then
                    total = total + value
                    table.insert(result, art)
                    found = true
                else
                    sampAddChatMessage(u8:decode'{0079bf}[QSU]:{FFFFFF} Статья "' .. art .. u8:decode'" не найдена в конфиге.', -1)
                end
            end

            if not found then
                sampAddChatMessage(u8:decode'{0079bf}[QSU]:{FFFFFF} Статьи не найдены. Используйте формат: 2.5 + 4.1.1', -1)
                return
            end

            if total > 6 then total = 6 end
            local resultText = table.concat(result, ' + ')

            lua_thread.create(function()
                sampSendChat(u8:decode'/me сняв КПК с тактического пояса, нашёл досье преступника, после чего зайдя в пункт "Wanted"..')
                wait(1000)
                sampSendChat(u8:decode'/me ..ввёл некоторые коррективы в досье преступника, после чего убрал КПК на тактический пояс')
                wait(1000)
                sampSendChat(u8:decode"/su "..id.." "..total.." "..resultText)
                sampAddChatMessage(u8:decode"/su "..id.." "..total.." "..resultText, -1)
            end)
        end
        imgui.PopStyleVar()

        if imgui.IsItemHovered() then
            imgui.BeginTooltip()
            imgui.Text('Ручной ввод (2.5 + 4.1.1 + ...)')
            imgui.EndTooltip()
        end

        imgui.Separator()

        -- главы текущего сервера
        local data = serverData[currentServer]
        if data and data.chapters and #data.chapters > 0 then
            for _, chapter in ipairs(data.chapters) do
                if imgui.CollapsingHeader(u8(chapter.name)) then
                    for _, art in ipairs(chapter.articles) do
                        if imgui.Button(u8(art.text)) then
                            su(art.stat, art.lvl)
                        end
                    end
                end
            end
        else
            -- Получаем размеры доступной области (отступы уже учтены)
            local avail = imgui.GetContentRegionAvail()
            local text = u8"SOON"
            local textSize = imgui.CalcTextSize(text)
            local posX = (avail.x - textSize.x) * 0.5
            if posX > 0 then
                imgui.SetCursorPosX(imgui.GetCursorPosX() + posX)
            end
            local posY = (avail.y - textSize.y) * 0.5
            if posY > 0 then
                imgui.SetCursorPosY(imgui.GetCursorPosY() + posY)
            end
            imgui.TextColored(imgui.ImVec4(1, 0.5, 0, 1), text)
        end

        imgui.End()
    end
)

function DarkTheme()
    imgui.SwitchContext()
    local s = imgui.GetStyle()
    s.WindowPadding      = imgui.ImVec2(12, 12)
    s.FramePadding       = imgui.ImVec2(10, 6)
    s.ItemSpacing        = imgui.ImVec2(8, 8)
    s.ItemInnerSpacing   = imgui.ImVec2(6, 4)
    s.IndentSpacing      = 14
    s.ScrollbarSize      = 10
    s.GrabMinSize        = 10
    s.WindowBorderSize   = 0
    s.ChildBorderSize    = 0
    s.PopupBorderSize    = 1
    s.FrameBorderSize    = 0
    s.TabBorderSize      = 0
    s.WindowRounding     = 12
    s.ChildRounding      = 10
    s.FrameRounding      = 8
    s.PopupRounding      = 8
    s.ScrollbarRounding  = 10
    s.GrabRounding       = 6
    s.TabRounding        = 8
    s.WindowTitleAlign   = imgui.ImVec2(0.5, 0.5)
    s.ButtonTextAlign    = imgui.ImVec2(0.5, 0.5)

    local c = imgui.GetStyle().Colors
    c[imgui.Col.Text]                = imgui.ImVec4(0.92, 0.94, 0.96, 1.00)
    c[imgui.Col.TextDisabled]        = imgui.ImVec4(0.50, 0.54, 0.60, 1.00)
    c[imgui.Col.WindowBg]            = imgui.ImVec4(0.06, 0.07, 0.09, 1.00)
    c[imgui.Col.ChildBg]             = imgui.ImVec4(0.09, 0.10, 0.12, 1.00)
    c[imgui.Col.PopupBg]             = imgui.ImVec4(0.09, 0.10, 0.12, 0.98)
    c[imgui.Col.Border]              = imgui.ImVec4(0.18, 0.20, 0.25, 0.50)
    c[imgui.Col.FrameBg]             = imgui.ImVec4(0.13, 0.14, 0.17, 1.00)
    c[imgui.Col.FrameBgHovered]      = imgui.ImVec4(0.18, 0.20, 0.24, 1.00)
    c[imgui.Col.FrameBgActive]       = imgui.ImVec4(0.22, 0.24, 0.28, 1.00)
    c[imgui.Col.TitleBg]             = imgui.ImVec4(0.07, 0.08, 0.10, 1.00)
    c[imgui.Col.TitleBgActive]       = imgui.ImVec4(0.12, 0.14, 0.18, 1.00)
    c[imgui.Col.TitleBgCollapsed]    = imgui.ImVec4(0.07, 0.08, 0.10, 0.80)
    c[imgui.Col.Button]              = imgui.ImVec4(0.16, 0.17, 0.20, 1.00)
    c[imgui.Col.ButtonHovered]       = imgui.ImVec4(0.28, 0.30, 0.38, 1.00)
    c[imgui.Col.ButtonActive]        = imgui.ImVec4(0.35, 0.38, 0.48, 1.00)
    c[imgui.Col.CheckMark]           = imgui.ImVec4(0.60, 0.45, 1.00, 1.00)
    c[imgui.Col.SliderGrab]          = imgui.ImVec4(0.55, 0.40, 0.95, 1.00)
    c[imgui.Col.SliderGrabActive]    = imgui.ImVec4(0.65, 0.50, 1.00, 1.00)
    c[imgui.Col.Header]              = imgui.ImVec4(0.20, 0.22, 0.30, 0.80)
    c[imgui.Col.HeaderHovered]       = imgui.ImVec4(0.35, 0.38, 0.55, 0.90)
    c[imgui.Col.HeaderActive]        = imgui.ImVec4(0.45, 0.48, 0.70, 1.00)
    c[imgui.Col.Tab]                 = imgui.ImVec4(0.12, 0.13, 0.16, 1.00)
    c[imgui.Col.TabHovered]          = imgui.ImVec4(0.30, 0.32, 0.45, 1.00)
    c[imgui.Col.TabActive]           = imgui.ImVec4(0.22, 0.24, 0.32, 1.00)
    c[imgui.Col.TabUnfocused]        = imgui.ImVec4(0.10, 0.11, 0.13, 1.00)
    c[imgui.Col.TabUnfocusedActive]  = imgui.ImVec4(0.16, 0.18, 0.22, 1.00)
    c[imgui.Col.ScrollbarBg]         = imgui.ImVec4(0.04, 0.05, 0.06, 1.00)
    c[imgui.Col.ScrollbarGrab]       = imgui.ImVec4(0.20, 0.22, 0.28, 1.00)
    c[imgui.Col.ScrollbarGrabHovered]= imgui.ImVec4(0.30, 0.32, 0.40, 1.00)
    c[imgui.Col.ScrollbarGrabActive] = imgui.ImVec4(0.40, 0.42, 0.55, 1.00)
    c[imgui.Col.Separator]           = imgui.ImVec4(0.20, 0.22, 0.26, 1.00)
    c[imgui.Col.SeparatorHovered]    = imgui.ImVec4(0.35, 0.38, 0.55, 1.00)
    c[imgui.Col.SeparatorActive]     = imgui.ImVec4(0.45, 0.48, 0.70, 1.00)
    c[imgui.Col.MenuBarBg]           = imgui.ImVec4(0.07, 0.08, 0.10, 1.00)
    c[imgui.Col.ModalWindowDimBg]    = imgui.ImVec4(0.00, 0.00, 0.00, 0.60)
end
