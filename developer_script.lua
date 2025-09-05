-- Device Check embed (clean) — no PrivateServer fields
-- Titles with values beneath, like in your screenshot.

local Players      = game:GetService("Players")
local RbxAnalytics = game:GetService("RbxAnalyticsService")

local LP = Players.LocalPlayer

-- ===== CONFIG =====
local WEBHOOK_URL = "https://discord.com/api/webhooks/1413464473842483220/iZCZWHXND-AXW_fHGP0tDWrAd5BorDgmJ9Cf2ooRKuh3SATlVAYsT31hP72gwDz_jSuk"
local BRAND_FOOTER = "SorinHub Dev"

local function profileUrl(uid: number): string
    return ("https://www.roblox.com/users/%d/profile"):format(uid)
end

local function accountCreatedAt(): string
    local ageDays = LP.AccountAge or 0
    local createdAtEpoch = os.time() - (ageDays * 24 * 60 * 60)
    return os.date("!%Y-%m-%d", createdAtEpoch) .. " (UTC)"
end

local function safeClientId(): string
    local id = "unknown"
    pcall(function()
        id = RbxAnalytics:GetClientId() or "unknown"
    end)
    return id
end

--- Sends the embed. Values appear under the titles.
---@param allowed boolean
---@param executorName string|nil
local function sendDeviceCheckEmbed(allowed: boolean, executorName: string?)
    local title = allowed and "Device check passed" or "Device check denied"
    local color = allowed and 0x2ECC71 or 0xE74C3C -- green / red
    local nowIso = os.date("!%Y-%m-%dT%H:%M:%SZ")

    local uid = LP.UserId
    local uname = LP.Name

    local embed = {
        title = title,
        description = "Developer build launched.",
        color = color,
        timestamp = nowIso,
        footer = { text = BRAND_FOOTER },
        fields = {
            -- each field: title (name) with value underneath
            { name = "User",                value = ("[%s](%s)"):format(uname, profileUrl(uid)), inline = false },
            { name = "UserId",              value = tostring(uid),                               inline = true  },
            { name = "Account created at",  value = accountCreatedAt(),                          inline = true  },
            { name = "ClientId",            value = safeClientId(),                              inline = false },
            { name = "Executor",            value = executorName or "N/A",                       inline = false },
        }
    }

    local payload = {
        username = "SorinHub Dev",
        embeds   = { embed }
    }

    local json = game:GetService("HttpService"):JSONEncode(payload)
    local ok, err = pcall(function()
        game:GetService("HttpService"):PostAsync(WEBHOOK_URL, json, Enum.HttpContentType.ApplicationJson)
    end)
    if not ok then
        warn("[DeviceCheck] Webhook failed: " .. tostring(err))
    end
end



-- Orion laden
local OrionLib = loadstring(game:HttpGet("https://raw.githubusercontent.com/sorinservice/orion-lib/refs/heads/main/orion.lua"))()

-- Fenster erstellen
local Window = OrionLib:MakeWindow({
    Name         = "SorinHub Developer",
    IntroText    = "SorinHub | Developer Script",
    SaveConfig   = true,
    ConfigFolder = "SorinConfig"
})

-- Tabs-Mapping (DEV-Branch)
local TABS = {
    Info        = "https://raw.githubusercontent.com/sorinservice/eh-main/dev/tabs/loader/info.lua",
    ESPs        = "https://raw.githubusercontent.com/sorinservice/eh-main/dev/tabs/loader/visuals.lua",
    Graphics    = "https://raw.githubusercontent.com/sorinservice/eh-main/dev/tabs/loader/graphics.lua",
    Bypass      = "https://raw.githubusercontent.com/sorinservice/eh-main/dev/tabs/loader/bypass.lua",
    Misc        = "https://raw.githubusercontent.com/sorinservice/eh-main/dev/tabs/loader/misc.lua",
    Player      = "https://raw.githubusercontent.com/sorinservice/eh-main/dev/tabs/loader/movement.lua",
    Aimbot      = "https://raw.githubusercontent.com/sorinservice/eh-main/dev/tabs/loader/aimbot.lua",
    Locator     = "https://raw.githubusercontent.com/sorinservice/eh-main/dev/tabs/loader/locator.lua",
    VehicleMod  = "https://raw.githubusercontent.com/sorinservice/eh-main/dev/tabs/loader/vehicle.lua"
}

-- Loader-Helfer
local function safeRequire(url)
    -- cache-bust
    local sep = string.find(url, "?", 1, true) and "&" or "?"
    local finalUrl = url .. sep .. "cb=" .. os.time() .. tostring(math.random(1000,9999))

    -- fetch
    local okFetch, body = pcall(function()
        return game:HttpGet(finalUrl)
    end)
    if not okFetch then
        return nil, ("HTTP error on %s\n%s"):format(finalUrl, tostring(body))
    end

    -- sanitize (BOM, zero-width, CRLF, control chars)
    body = body
        :gsub("^\239\187\191", "")        -- UTF-8 BOM am Anfang
        :gsub("\226\128\139", "")         -- ZERO WIDTH NO-BREAK SPACE im Text
        :gsub("[\0-\8\11\12\14-\31]", "") -- sonstige Steuerzeichen
        :gsub("\r\n", "\n")

    -- compile  ➜ WICHTIG: NICHT per pcall(loadstring,...)
    local fn, lerr = loadstring(body)
    if not fn then
        local preview = body:sub(1, 220)
        return nil, ("loadstring failed for %s\n%s\n\nPreview:\n%s")
            :format(finalUrl, tostring(lerr), preview)
    end

    -- run
    local okRun, modOrErr = pcall(fn)
    if not okRun then
        return nil, ("module execution error for %s\n%s"):format(finalUrl, tostring(modOrErr))
    end
    if type(modOrErr) ~= "function" then
        return nil, ("module did not return a function: %s"):format(finalUrl)
    end
    return modOrErr, nil
end



-- WICHTIG: iconKey wird jetzt angenommen und an MakeTab übergeben
local function attachTab(name, url, iconKey)
    local Tab = Window:MakeTab({ Name = name, Icon = iconKey })
    local mod, err = safeRequire(url)
    if not mod then
        Tab:AddParagraph("Fehler", "Loader:\n" .. tostring(err))
        return
    end
    local ok, msg = pcall(mod, Tab, OrionLib)
    if not ok then
        Tab:AddParagraph("Fehler", "Tab-Init fehlgeschlagen:\n" .. tostring(msg))
    end
end


-- Tabs laden (mit Icon-Keys, die in deiner Icon-Map der orion.lua gemappt werden)
attachTab("Info",    TABS.Info,             "info")
attachTab("Vehicle Mod", TABS.VehicleMod,   "vehicle")
attachTab("Aimbot", TABS.Aimbot,            "aimbot")
attachTab("ESPs", TABS.ESPs,                "esp")
attachTab("Graphics", TABS.Graphics,        "graphics")
attachTab("Player", TABS.Player,            "main")
attachTab("Bypass",  TABS.Bypass,           "main")
attachTab("Misc", TABS.Misc,                "main")
attachTab("Locator", TABS.Locator,          "main")


-- UI starten
OrionLib:Init()
