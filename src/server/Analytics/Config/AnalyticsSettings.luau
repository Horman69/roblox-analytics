

-- Настройки системы аналитики
local AnalyticsSettings = {
    -- Основные настройки системы
    DEBUG_MODE = true, -- Включает подробное логирование
    SAVE_INTERVAL = 300, -- Интервал сохранения (в секундах)

    -- Настройки сессии игрока
    SESSION = {
        MIN_DURATION = 30, -- Минимальная длительность сессии
        INACTIVITY_TIMEOUT = 600 -- Таймаут неактивности
    },

    -- Настройки отслеживания событий
    TRACKING = {
        CHECKPOINTS = true, -- Отслеживание чекпоинтов
        PLAYTIME = true, -- Отслеживание времени игры
        EXITS = true -- Отслеживание выходов
    },

    -- Настройки экспорта данных
    EXPORT = {
        FORMAT = "JSON", -- Формат экспорта (JSON/CSV)
        AUTO_EXPORT = true, -- Автоматический экспорт
        INTERVAL = 3600 -- Интервал экспорта (в секундах)
    }
}

return AnalyticsSettings
