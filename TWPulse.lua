-- TWPulse.lua (Vanilla 1.12 / Turtle)

-------------------------------------------------
-- Emulation _G pour Vanilla 1.12
-------------------------------------------------
if not _G then
    _G = setmetatable({}, {
        __index = function(t, k)
            return getglobal(k)
        end,
        __newindex = function(t, k, v)
            setglobal(k, v)
        end,
    })
end

-------------------------------------------------
-- Racine
-------------------------------------------------
local TWP = CreateFrame("Frame")

-------------------------------------------------
-- Initialisation
-------------------------------------------------
TWP:RegisterEvent("ADDON_LOADED")

TWP:SetScript("OnEvent", function()
    if event == "ADDON_LOADED" and arg1 == "TWPulse" then

        if not TWPB_P then TWPB_P = 100 end  -- valeur par défaut si jamais la variable n’existe pas

        -- Appliquer la taille sauvegardée
        local size = TWPB_P
        TWP.defaults = TWP.defaults or {}
        TWP.defaults.size = size

        TWPulse:SetWidth(size)
        TWPulse:SetHeight(size)

        if TWPulseUnlock then
            TWPulseUnlock:SetWidth(size)
            TWPulseUnlock:SetHeight(size)
        end

        -- Activer le scan
        TWPulse:EnableMouse(false)
        TWP.scan:Show()
    end
end)

TWP.tracked = {}

-------------------------------------------------
-- Scan des sorts
-------------------------------------------------
TWP.scan = CreateFrame("Frame")
TWP.scan:Hide()
TWP.scan:SetScript("OnShow", function() this.startTime = GetTime() end)

TWP.scan:SetScript("OnUpdate", function()
    local plus = 0.1
    local gt = GetTime() * 1000
    local st = (this.startTime + plus) * 1000
    if gt >= st then
        local maxSpells = 500
        local id = 0
        while (id <= maxSpells) do
            id = id + 1
            local spellName = GetSpellName(id, BOOKTYPE_SPELL)
            if spellName then
                local start, duration, enabled = GetSpellCooldown(id, BOOKTYPE_SPELL)
                local cd = start + duration - GetTime()
                if cd > 1.7 then
                    TWP.tracked[spellName] = id
                end
            end
        end

        for name, spellId in next, TWP.tracked do
            if spellId then
                local start, duration, enabled = GetSpellCooldown(spellId, BOOKTYPE_SPELL)
                local cd = start + duration - GetTime()
                if cd <= 0 then
                    TWP.tracked[name] = nil
                    local tEx = string.split(GetSpellTexture(spellId, BOOKTYPE_SPELL), "\\")
                    local tex = tEx[table.getn(tEx)]
                    TWP.animateQueue[tex] = 1
                    TWP.animation:Show()
                end
            end
        end

        this.startTime = GetTime()
    end
end)

-------------------------------------------------
-- Animation
-------------------------------------------------
TWP.animationFrames = {}
TWP.animateQueue = {}

TWP.animation = CreateFrame("Frame")
TWP.animation:Hide()

TWP.animation:SetScript("OnShow", function() this.startTime = GetTime() end)
TWP.animation:SetScript("OnUpdate", function()
    local plus = 0.01
    local gt = GetTime() * 1000
    local st = (this.startTime + plus) * 1000
    if gt >= st then
        local baseSize = TWP.defaults and TWP.defaults.size or 100
        for tex, alpha in next, TWP.animateQueue do
            if alpha then
                if not TWP.animationFrames[tex] then
                    TWP.animationFrames[tex] = CreateFrame("Frame", "TWP_" .. tex, TWPulse, "TWPulseTemplate")
                end
                local frame = _G["TWP_" .. tex]
                local icon = _G["TWP_" .. tex .. "Icon"]
                icon:SetTexture("Interface\\Icons\\" .. tex)
                frame:Show()
                frame:SetAlpha(alpha)
                local scale = alpha + 0.5
                icon:SetWidth(baseSize * scale)
                icon:SetHeight(baseSize * scale)
                TWP.animateQueue[tex] = TWP.animateQueue[tex] - 0.02
                if TWP.animateQueue[tex] <= 0 then
                    frame:SetAlpha(0)
                    icon:SetWidth(baseSize)
                    icon:SetHeight(baseSize)
                    TWP.animateQueue[tex] = nil
                end
            end
        end

        if TWP.locked then
            if _tablesize(TWP.animateQueue) > 0 then
                TWPulse:Show()
            else
                TWPulse:Hide()
            end
        end
        this.startTime = GetTime()
    end
end)

-------------------------------------------------
-- Helpers
-------------------------------------------------
function _tablesize(t)
    local size = 0
    for i in t do size = size + 1 end
    return size
end

function string:split(delimiter)
    local result = {}
    local from = 1
    local delim_from, delim_to = string.find(self, delimiter, from)
    while delim_from do
        table.insert(result, string.sub(self, from, delim_from - 1))
        from = delim_to + 1
        delim_from, delim_to = string.find(self, delimiter, from)
    end
    table.insert(result, string.sub(self, from))
    return result
end

-------------------------------------------------
-- Options Frame
-------------------------------------------------
local TWPOptions = CreateFrame("Frame", "TWPOptionsFrame", UIParent)
TWPOptions:SetWidth(300)
TWPOptions:SetHeight(200)
TWPOptions:SetPoint("CENTER", UIParent, "CENTER")
TWPOptions:EnableMouse(true)
TWPOptions:SetMovable(true)
TWPOptions:RegisterForDrag("LeftButton")
TWPOptions:SetClampedToScreen(true)

TWPOptions:SetScript("OnDragStart", function(self) this:StartMoving() end)
TWPOptions:SetScript("OnDragStop", function(self) this:StopMovingOrSizing() end)
TWPOptions:SetBackdrop({
    bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
    edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
    tile = true, tileSize = 32, edgeSize = 32,
    insets = { left = 8, right = 8, top = 8, bottom = 8 }
})
TWPOptions:Hide()

-- Titre
TWPOptions.title = TWPOptions:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
TWPOptions.title:SetPoint("TOP", 0, -20)
TWPOptions.title:SetText("TWPulse Options")

-- Checkbox Lock
local lockCheck = CreateFrame("CheckButton", "TWPOptionsLockCheck", TWPOptions, "UICheckButtonTemplate")
lockCheck:SetPoint("TOPLEFT", 20, -60)
lockCheck.text = lockCheck:CreateFontString(nil, "OVERLAY", "GameFontNormal")
lockCheck.text:SetPoint("LEFT", lockCheck, "RIGHT", 4, 0)
lockCheck.text:SetText("Lock Pulse Frame")
lockCheck:SetScript("OnClick", function(self)
    if this:GetChecked() then
        TWP.locked = true
        TWPulseUnlock:Hide()
        TWPulse:Hide()
        TWPulse:EnableMouse(false)
    else
        TWP.locked = false
        TWPulseUnlock:Show()
        TWPulse:Show()
        TWPulse:EnableMouse(true)
    end
end)

-- Slider Taille
local sizeSlider = CreateFrame("Slider", "TWPOptionsSizeSlider", TWPOptions, "OptionsSliderTemplate")
sizeSlider:SetWidth(200)
sizeSlider:SetHeight(16)
sizeSlider:SetPoint("TOP", 0, -120)
sizeSlider:SetMinMaxValues(40, 200)
sizeSlider:SetValueStep(5)

-- Valeur initiale depuis la SaveVariable ou par défaut
sizeSlider:SetValue(TWPB_P or (TWP.defaults and TWP.defaults.size) or 100)

TWPOptionsSizeSliderLow:SetText("40")
TWPOptionsSizeSliderHigh:SetText("200")
TWPOptionsSizeSliderText:SetText("Icon Size")

sizeSlider:SetScript("OnValueChanged", function(self)
    local val = this:GetValue()
    if not TWP.defaults then TWP.defaults = {} end
    TWP.defaults.size = val

    -- Sauvegarde dans la SaveVariable
    TWPB_P = val

    -- Redimensionne le pulse principal
    TWPulse:SetWidth(val)
    TWPulse:SetHeight(val)

    -- Redimensionne le carré de déverrouillage
    if TWPulseUnlock then
        TWPulseUnlock:SetWidth(val)
        TWPulseUnlock:SetHeight(val)
    end

    -- Redimensionne toutes les icônes animées
    for tex, frame in next, TWP.animationFrames do
        if frame then
            local icon = _G[frame:GetName().."Icon"]
            if icon then
                icon:SetWidth(val)
                icon:SetHeight(val)
            end
        end
    end
end)

-- Bouton fermer
local closeBtn = CreateFrame("Button", nil, TWPOptions, "UIPanelButtonTemplate")
closeBtn:SetWidth(80)
closeBtn:SetHeight(22)
closeBtn:SetPoint("BOTTOM", 0, 20)
closeBtn:SetText("Fermer")
closeBtn:SetScript("OnClick", function() TWPOptions:Hide() end)

-------------------------------------------------
-- Slash Command /twp
-------------------------------------------------
SLASH_TWPOPTIONS1 = "/twp"
SlashCmdList["TWPOPTIONS"] = function(msg)
    if TWPOptions:IsShown() then
        TWPOptions:Hide()
    else
        lockCheck:SetChecked(TWP.locked)
        sizeSlider:SetValue(TWP.defaults and TWP.defaults.size or 100)
        TWPOptions:Show()
    end
end
