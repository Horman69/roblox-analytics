local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local HttpService = game:GetService("HttpService")

export type SessionData = {
    userId: number,
    playerName: string,
    sessionStart: number,
    lastActive: number,
    checkpoints: {[string]: number},
    deaths: number,
    dropReason: string?,
    duration: number?
}

local SessionTracker = {}
SessionTracker.__index = SessionTracker

-- Приватные переменные
local _activeSessions: {[number]: SessionData} = {}
local _analyticsStore = DataStoreService:GetDataStore("GameAnalytics")

-- Создание нового трекера
function SessionTracker.new()
    local self = setmetatable({}, SessionTracker)
    -- Используем WaitForChild для надёжной загрузки конфига
    self._config = require(script.Parent.Parent:WaitForChild("Config"):WaitForChild("AnalyticsSettings"))
    return self
end

-- Получение всех активных сессий
function SessionTracker:getAllSessions(): {[number]: SessionData}
    return _activeSessions
end

-- Получение конкретной сессии
function SessionTracker:getSession(player: Player): SessionData?
    if not player then return nil end
    return _activeSessions[player.UserId]
end

function SessionTracker:startTracking(player: Player): SessionData?
    if not player then 
        warn("⚠️ [SessionTracker] Получен nil player в startTracking")
        return nil
    end

    local session: SessionData = {
        userId = player.UserId,
        playerName = player.Name,
        sessionStart = os.time(),
        lastActive = os.time(),
        checkpoints = {},
        deaths = 0
    }
    
    _activeSessions[player.UserId] = session
    self:_logEvent("SESSION_START", player)
    return session
end

function SessionTracker:updateActivity(player: Player, checkpointId: string?)
    if not player then return end
    
    local session = _activeSessions[player.UserId]
    if session then
        session.lastActive = os.time()
        if checkpointId then
            session.checkpoints[checkpointId] = os.time()
            self:_logEvent("CHECKPOINT_REACHED", player, {checkpoint = checkpointId})
        end
    end
end

function SessionTracker:endTracking(player: Player, reason: string?)
    if not player then return end
    
    local session = _activeSessions[player.UserId]
    if session then
        session.duration = os.time() - session.sessionStart
        session.dropReason = reason
        
        self:_saveSession(session)
        _activeSessions[player.UserId] = nil
        self:_logEvent("SESSION_END", player, {
            duration = session.duration,
            reason = reason
        })
    end
end

-- Приватные методы
function SessionTracker:_logEvent(eventType: string, player: Player, data: any?)
    if not self._config.DEBUG_MODE then return end
    
    local logMessage = string.format(
        "📊 [%s] %s | Player: %s | Data: %s",
        eventType,
        os.date("%H:%M:%S"),
        player.Name,
        data and HttpService:JSONEncode(data) or "none"
    )
    
    print(logMessage)
end

function SessionTracker:_saveSession(session: SessionData)
    if not session then return end
    
    local success, err = pcall(function()
        local sessionKey = string.format(
            "session_%d_%d",
            session.userId,
            session.sessionStart
        )
        
        _analyticsStore:SetAsync(sessionKey, session)
        self:_logEvent("SESSION_SAVED", {UserId = session.userId, Name = session.playerName})
    end)
    
    if not success then
        warn("⚠️ [SessionTracker] Ошибка сохранения сессии:", err)
    end
end

return SessionTracker