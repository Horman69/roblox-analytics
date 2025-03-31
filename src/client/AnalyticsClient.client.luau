local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

-- Типы для аналитики
type AnalyticsEvent = {
    type: string,
    data: any,
    timestamp: number
}

-- Основной модуль аналитики
local Analytics = {
    _lastEvent = nil,
    _lastEventTime = 0,
    _EVENT_COOLDOWN = 1,
    _initialized = false
}

-- Инициализация системы
function Analytics:init()
    if self._initialized then return end

    -- Получаем игрока
    local player = Players.LocalPlayer
    if not player then
        warn("⚠️ [ANALYTICS] Локальный игрок не найден!")
        return
    end

    -- Получаем RemoteEvent
    self._analyticsEvent = ReplicatedStorage:WaitForChild("AnalyticsEvent", 10)
    if not self._analyticsEvent then
        warn("⚠️ [ANALYTICS] AnalyticsEvent не найден!")
        return
    end

    -- Отправляем событие начала сессии
    self:sendEvent("SESSION_START", {
        playerId = player.UserId,
        playerName = player.Name,
        startTime = os.time()
    })

    -- Отслеживаем отключение игрока через RemoteEvent
    Players.PlayerRemoving:Connect(function(plr)
        if plr == player then
            self:sendEvent("SESSION_END", {
                playerId = player.UserId,
                endTime = os.time()
            })
        end
    end)

    self._initialized = true
    print("✅ [ANALYTICS] Клиент аналитики инициализирован")
end

-- Отправка события
function Analytics:sendEvent(eventType: string, data: any): boolean
    if not self._initialized then
        warn("⚠️ [ANALYTICS] Система не инициализирована!")
        return false
    end

    local currentTime = os.time()
    
    -- Защита от спама
    if currentTime - self._lastEventTime < self._EVENT_COOLDOWN then
        return false
    end

    -- Отправляем событие
    local success, err = pcall(function()
        self._analyticsEvent:FireServer({
            type = eventType,
            data = data,
            timestamp = currentTime
        })
    end)

    if not success then
        warn("⚠️ [ANALYTICS] Ошибка отправки события:", err)
        return false
    end

    self._lastEvent = eventType
    self._lastEventTime = currentTime
    return true
end

-- Инициализируем аналитику
Analytics:init()

return Analytics