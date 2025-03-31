local DataStoreService = game:GetService("DataStoreService")
local HttpService = game:GetService("HttpService")

export type ExportFormat = "JSON" | "CSV"
export type ExportData = {
    timestamp: number,
    sessionData: {[string]: any},
    metrics: {[string]: any}
}

local DataExporter = {}
DataExporter.__index = DataExporter

local EXPORT_COOLDOWN = 5 -- минимальный интервал между экспортами
local lastExportTime = 0

function DataExporter.new()
    local self = setmetatable({}, DataExporter)
    self._dataStore = DataStoreService:GetDataStore("AnalyticsExport")
    self._settings = require(script.Parent.Parent:WaitForChild("Config"):WaitForChild("AnalyticsSettings"))
    return self
end

function DataExporter:exportData(data: ExportData, format: ExportFormat): (boolean, string)
    local currentTime = os.time()
    
    -- Проверяем интервал
    if currentTime - lastExportTime < EXPORT_COOLDOWN then
        return false, "⚠️ Слишком частые запросы экспорта"
    end

    if not data then
        return false, "❌ Отсутствуют данные для экспорта"
    end

    local success, result = pcall(function()
        if format == "JSON" then
            return self:_exportJSON(data)
        elseif format == "CSV" then
            return self:_exportCSV(data)
        end
        error("Неподдерживаемый формат экспорта: " .. format)
    end)

    if not success then
        warn("⚠️ [DataExporter] Ошибка экспорта:", result)
        return false, result
    end

    lastExportTime = currentTime
    return true, result
end

function DataExporter:_exportJSON(data: ExportData): string
    local success, result = pcall(function()
        return HttpService:JSONEncode({
            exportTime = os.date("%Y-%m-%d %H:%M:%S"),
            data = data
        })
    end)

    if not success then
        error("Ошибка JSON экспорта: " .. tostring(result))
    end

    self:_saveExport("json", result)
    return result
end

function DataExporter:_exportCSV(data: ExportData): string
    local lines = {
        "Timestamp,PlayerID,PlayerName,SessionDuration,Checkpoints,DropReason"
    }

    -- Преобразуем данные сессий в CSV
    for _, session in pairs(data.sessionData) do
        local checkpoints = table.concat(session.checkpoints, "|")
        local line = string.format(
            "%d,%d,%s,%d,%s,%s",
            session.sessionStart,
            session.userId,
            session.playerName,
            session.duration or 0,
            checkpoints,
            session.dropReason or "none"
        )
        table.insert(lines, line)
    end

    local csvContent = table.concat(lines, "\n")
    self:_saveExport("csv", csvContent)
    return csvContent
end

function DataExporter:_saveExport(format: string, content: string)
    local timestamp = os.date("%Y%m%d_%H%M%S")
    local key = string.format("export_%s_%s", timestamp, format)

    local success, err = pcall(function()
        self._dataStore:SetAsync(key, content)
    end)

    if not success then
        warn("⚠️ [DataExporter] Ошибка сохранения экспорта:", err)
    else
        print(string.format("📊 [DataExporter] Экспорт сохранен: %s", key))
    end
end

return DataExporter