local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

-- Безопасная загрузка модулей
local function safeRequire(path)
    local success, result = pcall(function()
        return require(path)
    end)
    
    if not success then
        warn("⚠️ Ошибка загрузки модуля:", path:GetFullName())
        return nil
    end
    
    return result
end

-- Инициализация компонентов
local Analytics = {
    Settings = safeRequire(script.Parent.Analytics.Config.AnalyticsSettings),
    SessionTracker = safeRequire(script.Parent.Analytics.Modules.SessionTracker),
    MetricsAggregator = safeRequire(script.Parent.Analytics.Modules.MetricsAggregator),
    DataExporter = safeRequire(script.Parent.Analytics.Modules.DataExporter)
}

-- Проверка загрузки модулей
for name, module in pairs(Analytics) do
    if not module then
        error(string.format("❌ Не удалось загрузить модуль: %s", name))
        return
    end
end

-- Создание экземпляров
local sessionTracker = Analytics.SessionTracker.new()
local metricsAggregator = Analytics.MetricsAggregator.new()
local dataExporter = Analytics.DataExporter.new()

-- Создание RemoteEvents для клиент-серверного взаимодействия
local function createRemoteEvents()
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    
    local events = {
        "AnalyticsEvent",
        "CheckpointEvent",
        "SessionEvent"
    }
    
    for _, eventName in ipairs(events) do
        if not ReplicatedStorage:FindFirstChild(eventName) then
            local event = Instance.new("RemoteEvent")
            event.Name = eventName
            event.Parent = ReplicatedStorage
            print(string.format("✅ Создан RemoteEvent: %s", eventName))
        end
    end
end

-- Автоматический экспорт данных
local lastExportTime = 0

RunService.Heartbeat:Connect(function()
    local currentTime = os.time()
    if currentTime - lastExportTime >= Analytics.Settings.EXPORT.INTERVAL then
        local metrics = metricsAggregator:getMetrics()
        local exportData = {
            timestamp = currentTime,
            sessionData = sessionTracker:getAllSessions(),
            metrics = metrics
        }
        
        local success, result = pcall(function()
            return dataExporter:exportData(
                exportData, 
                Analytics.Settings.EXPORT.FORMAT
            )
        end)
        
        if success then
            print("📊 [ANALYTICS] Данные успешно экспортированы")
        else
            warn("⚠️ [ANALYTICS] Ошибка экспорта:", result)
        end
        
        lastExportTime = currentTime
    end
end)

-- Обработчики событий игроков
Players.PlayerAdded:Connect(function(player)
    local success, err = pcall(function()
        sessionTracker:startTracking(player)
        print(string.format("✅ [ANALYTICS] Начато отслеживание игрока: %s", player.Name))
    end)
    
    if not success then
        warn(string.format("⚠️ [ANALYTICS] Ошибка отслеживания игрока %s: %s", player.Name, err))
    end
end)

Players.PlayerRemoving:Connect(function(player)
    local success, err = pcall(function()
        sessionTracker:endTracking(player, "player_left")
        metricsAggregator:addSession(sessionTracker:getSession(player))
        print(string.format("✅ [ANALYTICS] Завершено отслеживание игрока: %s", player.Name))
    end)
    
    if not success then
        warn(string.format("⚠️ [ANALYTICS] Ошибка завершения сессии игрока %s: %s", player.Name, err))
    end
end)

-- Создаем RemoteEvents при запуске
createRemoteEvents()

print("✅ [ANALYTICS] Система аналитики инициализирована")