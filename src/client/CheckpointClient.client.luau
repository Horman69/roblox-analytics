local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

-- Функция для логирования с меткой времени
local function debugLog(message: string, ...: any)
    print(string.format("[%s] %s", os.date("%H:%M:%S"), string.format(message, ...)))
end

-- Проверяем среду выполнения
if not RunService:IsClient() then
    error("⚠️ Этот скрипт должен выполняться только на клиенте!")
    return
end

-- Получаем игрока
local player = Players.LocalPlayer
if not player then
    error("⚠️ [ANALYTICS] Локальный игрок не найден!")
    return
end

-- Инициализация аналитики
local Analytics = {
    lastEvent = nil,
    lastEventTime = 0,
    EVENT_COOLDOWN = 1,
    events = {
        checkpoint = ReplicatedStorage:WaitForChild("CheckpointEvent"),
        session = ReplicatedStorage:WaitForChild("SessionEvent"),
        custom = ReplicatedStorage:WaitForChild("CustomEvent")
    }
}

-- Отправка событий аналитики
function Analytics:sendEvent(eventType: string, data: any)
    local currentTime = os.time()
    
    -- Защита от спама
    if currentTime - self.lastEventTime < self.EVENT_COOLDOWN then
        return false
    end
    
    -- Проверяем существование события
    local event = self.events[eventType]
    if not event then
        warn("⚠️ [ANALYTICS] Неизвестный тип события:", eventType)
        return false
    end
    
    -- Отправляем событие
    local success, err = pcall(function()
        event:FireServer(data)
        debugLog("📤 [ANALYTICS] Отправлено событие %s: %s", eventType, tostring(data))
    end)
    
    if not success then
        warn("⚠️ [ANALYTICS] Ошибка отправки события:", err)
        return false
    end
    
    self.lastEventTime = currentTime
    self.lastEvent = eventType
    return true
end

-- Автоматическое отслеживание сессии
local function startSessionTracking()
    -- Отправляем событие начала сессии
    Analytics:sendEvent("session", {
        action = "start",
        timestamp = os.time()
    })
    
    -- Отслеживаем выход игрока
    game:BindToClose(function()
        Analytics:sendEvent("session", {
            action = "end",
            timestamp = os.time()
        })
    end)
end

-- Запускаем отслеживание
startSessionTracking()
debugLog("✅ [ANALYTICS] Клиент аналитики инициализирован")

return Analytics