local HttpService = game:GetService("HttpService")

-- Типы данных
export type GameMetrics = {
    sessionCount: number,
    averageSessionTime: number,
    checkpointCompletionRates: {[string]: number},
    commonDropPoints: {[string]: number},
    uniquePlayers: number,
    retention: {
        day1: number,
        day7: number,
        day30: number
    }
}

local MetricsAggregator = {}
MetricsAggregator.__index = MetricsAggregator

-- Создание нового агрегатора
function MetricsAggregator.new()
    local self = setmetatable({}, MetricsAggregator)
    self._sessions = {}
    self._config = require(script.Parent.Parent:WaitForChild("Config"):WaitForChild("AnalyticsSettings"))
    return self
end

-- Добавление сессии для анализа
function MetricsAggregator:addSession(sessionData)
    if not sessionData then
        warn("⚠️ [MetricsAggregator] Получены пустые данные сессии")
        return
    end
    
    table.insert(self._sessions, sessionData)
    self:_logEvent("SESSION_ADDED", sessionData)
end

-- Получение всех метрик
function MetricsAggregator:getMetrics(): GameMetrics
    local metrics: GameMetrics = {
        sessionCount = #self._sessions,
        averageSessionTime = self:_calculateAverageSessionTime(),
        checkpointCompletionRates = self:_calculateCheckpointRates(),
        commonDropPoints = self:_analyzeDropPoints(),
        uniquePlayers = self:_countUniquePlayers(),
        retention = self:_calculateRetention()
    }
    
    self:_logEvent("METRICS_CALCULATED", metrics)
    return metrics
end

-- Расчёт среднего времени сессии
function MetricsAggregator:_calculateAverageSessionTime(): number
    local totalTime = 0
    local validSessions = 0
    
    for _, session in ipairs(self._sessions) do
        if session.duration and session.duration >= self._config.SESSION.MIN_DURATION then
            totalTime += session.duration
            validSessions += 1
        end
    end
    
    return validSessions > 0 and (totalTime / validSessions) or 0
end

-- Расчёт процента прохождения чекпоинтов
function MetricsAggregator:_calculateCheckpointRates(): {[string]: number}
    local checkpointCounts = {}
    local totalSessions = #self._sessions
    
    for _, session in ipairs(self._sessions) do
        for checkpoint, _ in pairs(session.checkpoints) do
            checkpointCounts[checkpoint] = (checkpointCounts[checkpoint] or 0) + 1
        end
    end
    
    local rates = {}
    for checkpoint, count in pairs(checkpointCounts) do
        rates[checkpoint] = totalSessions > 0 and (count / totalSessions * 100) or 0
    end
    
    return rates
end

-- Анализ точек выхода
function MetricsAggregator:_analyzeDropPoints(): {[string]: number}
    local dropPoints = {}
    local totalDrops = 0
    
    for _, session in ipairs(self._sessions) do
        if session.dropReason then
            dropPoints[session.dropReason] = (dropPoints[session.dropReason] or 0) + 1
            totalDrops += 1
        end
    end
    
    local rates = {}
    for reason, count in pairs(dropPoints) do
        rates[reason] = totalDrops > 0 and (count / totalDrops * 100) or 0
    end
    
    return rates
end

-- Подсчёт уникальных игроков
function MetricsAggregator:_countUniquePlayers(): number
    local players = {}
    local count = 0
    
    for _, session in ipairs(self._sessions) do
        if not players[session.userId] then
            players[session.userId] = true
            count += 1
        end
    end
    
    return count
end

-- Расчёт показателей удержания
function MetricsAggregator:_calculateRetention(): {day1: number, day7: number, day30: number}
    local now = os.time()
    local dayInSeconds = 86400 -- 24 * 60 * 60
    
    local function getRetentionForDays(days: number): number
        local threshold = now - (days * dayInSeconds)
        local activePlayers = {}
        local totalPlayers = {}
        
        for _, session in ipairs(self._sessions) do
            totalPlayers[session.userId] = true
            if session.lastActive > threshold then
                activePlayers[session.userId] = true
            end
        end
        
        local activeCount = 0
        for _ in pairs(activePlayers) do
            activeCount += 1
        end
        
        local totalCount = 0
        for _ in pairs(totalPlayers) do
            totalCount += 1
        end
        
        return totalCount > 0 and (activeCount / totalCount * 100) or 0
    end
    
    return {
        day1 = getRetentionForDays(1),
        day7 = getRetentionForDays(7),
        day30 = getRetentionForDays(30)
    }
end

-- Логирование событий
function MetricsAggregator:_logEvent(eventType: string, data: any?)
    if not self._config.DEBUG_MODE then return end
    
    print(string.format(
        "📊 [MetricsAggregator] %s | Data: %s",
        eventType,
        data and HttpService:JSONEncode(data) or "none"
    ))
end

return MetricsAggregator