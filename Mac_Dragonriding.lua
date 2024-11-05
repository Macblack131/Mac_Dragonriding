local vigorWidgetId = 4460
local timeDelay = 0.1
local isMovable = false

SLASH_MACDRAGONRIDINGUNLOCKFRAME1 = "/Mac_Dragonriding.unlockFrame"
SLASH_MACDRAGONRIDINGLOCKFRAME1 = "/Mac_Dragonriding.lockFrame"
SLASH_MACDRAGONRIDINGRESETFRAME1 = "/Mac_Dragonriding.resetFrame"

SlashCmdList.MACDRAGONRIDINGUNLOCKFRAME = function()
		print("Фрэйм разблокирован")
    isMovable = true
end
SlashCmdList.MACDRAGONRIDINGLOCKFRAME = function()
		print("Позиция заблокирована")
    isMovable = false
end
SlashCmdList.MACDRAGONRIDINGRESETFRAME = function()
		print("Позиция сброшена")
    Mac_Dragonriding:ClearAllPoints();
    Mac_Dragonriding:SetPoint("CENTER", nil, "CENTER", 0, 0)
end

local UnitAura = function(unitToken, index, filter)
  local auraData = C_UnitAuras.GetAuraDataByIndex(unitToken, index, filter)
  if not auraData then
      return nil
  end

  return AuraUtil.UnpackAuraData(auraData)
end

Mac_DragonridingMixin = {}

function Mac_DragonridingMixin:OnLoad()
  self:RegisterEvent("UPDATE_UI_WIDGET")
  self:RegisterEvent("ADDON_LOADED")
  self:SetMovable(true)
  self:SetScript("OnMouseDown", function(self, button)
    if isMovable == true then
      self:StartMoving()
    end
  end)
  self:SetScript("OnMouseUp", function(self, button)
      self:StopMovingOrSizing()
      self:SetUserPlaced(true)
  end)
end

function Mac_DragonridingMixin:OnEvent(event, ...)
  -- local addOnName = ...
  -- if addOnName == "Mac_Dragonriding" then
	-- 	Mac_DragonridingDB = Mac_DragonridingDB or {}
  --   Mac_DragonridingDB.point = Mac_DragonridingDB.point or "CENTER"
  --   Mac_DragonridingDB.relativeTo = Mac_DragonridingDB.relativeTo or nil
  --   Mac_DragonridingDB.relativePoint = Mac_DragonridingDB.relativePoint or "CENTER"
  --   Mac_DragonridingDB.offsetX = Mac_DragonridingDB.offsetX or 0
  --   Mac_DragonridingDB.offsetY = Mac_DragonridingDB.offsetY or 0
  --   self:SetPoint(Mac_DragonridingDB.point, Mac_DragonridingDB.relativeTo, Mac_DragonridingDB.relativePoint , Mac_DragonridingDB.offsetX, Mac_DragonridingDB.offsetY)
	-- end

  if event == "UPDATE_UI_WIDGET" then
    if UIWidgetPowerBarContainerFrame and UIWidgetPowerBarContainerFrame.widgetFrames[vigorWidgetId] then
      local widgetInfo = C_UIWidgetManager.GetFillUpFramesWidgetVisualizationInfo(vigorWidgetId)
      if (UIWidgetPowerBarContainerFrame.widgetFrames[vigorWidgetId]:IsShown()) then
        --print(GetTime(), "vigorWidgetId is Shown")
        UIWidgetPowerBarContainerFrame.widgetFrames[vigorWidgetId]:Hide()
      
        if not self:IsShown() then
          --print("dddd")
            for i = 1, 40 do
              local name, _, _, _, _, _, _, _, _, spellId = UnitAura("player", i)
              if name ~= nil then
                local mountID = C_MountJournal.GetMountFromSpell(spellId)
                if mountID ~= nil then
                  local name, _, icon = C_MountJournal.GetMountInfoByID(mountID)
                  self.Icon:SetTexture(icon)
                  self.Text:SetText(name)
                  self:Show()
                  self.ReservesOfVigor:Update(widgetInfo)
                  UIWidgetPowerBarContainerFrame:Layout()
                  EncounterBar:Layout()
                  return
                end
              end
            end
        end
      end
      if self:IsShown() and self.ReservesOfVigor.numTotalFrames ~= widgetInfo.numTotalFrames then -- Обновляет ReservesOfVigor при изменении числа запасов бодрости
        self.ReservesOfVigor:Update(widgetInfo)
      end
    end
  end
end

ReservesOfVigorMixin = {}

function ReservesOfVigorMixin:OnLoad()
  self.reserveOfEnergyPool = CreateFramePool("StatusBar", self, "ReserveOfEnergyTemplate")
end

function ReservesOfVigorMixin:Update(widgetInfo)
  self.numTotalFrames = widgetInfo.numTotalFrames
  self.reserveOfEnergyPool:ReleaseAll()
  for i = 1, widgetInfo.numTotalFrames do
    local reserveOfEnergy = self.reserveOfEnergyPool:Acquire()
    reserveOfEnergy.auraInstanceID = auraInstanceID
    reserveOfEnergy.layoutIndex = i
    reserveOfEnergy:Show()
  end
  self:Layout()
end

ReserveOfEnergyMixin = {}

function ReserveOfEnergyMixin:OnLoad()
  self.time = GetTime()
  self:SetMinMaxValues(0, 100)
end

function ReserveOfEnergyMixin:OnUpdate()
    if GetTime() > (self.time + timeDelay) then
      self.time = GetTime()
      local widgetInfo = C_UIWidgetManager.GetFillUpFramesWidgetVisualizationInfo(vigorWidgetId)
      if widgetInfo ~= nil then
        if (widgetInfo.numFullFrames >= self.layoutIndex) then
          local value = (62.5 / 100) * widgetInfo.fillMax
          self:SetValue(value + 18.75)
        elseif (widgetInfo.numFullFrames + 1 == self.layoutIndex) then
          local value = (62.5 / 100) * widgetInfo.fillValue
          self:SetValue(value + 18.75)
        else
          local value = (62.5 / 100) * widgetInfo.fillMin
          self:SetValue(value + 18.75)
        end
        if self:GetValue() == 81.25 then
          self:SetStatusBarTexture("Interface/Addons/Mac_Dragonriding/boost-of-energy-band")
        else
          self:SetStatusBarTexture("Interface/Addons/Mac_Dragonriding/boost-of-energy-frame2222222")
        end
      end
    end
  end

SpeedLaneMixin = {}

function SpeedLaneMixin:OnLoad()
  self:RegisterEvent("UNIT_AURA")
  self.time = GetTime()
  self:SetMinMaxValues(0, 100)
end

function SpeedLaneMixin:OnEvent(event, ...)
  local unit, info = ...
  if unit == "player" then
    if info.addedAuras then
      for _, v in pairs(info.addedAuras) do
        if v.spellId == 377234 then
          self.auraInstanceID = v.auraInstanceID
          self:SetStatusBarTexture("Interface/Addons/Mac_Dragonriding/speed-lane4")
        end
      end
    end
    if info.removedAuraInstanceIDs then
      for _, v in pairs(info.removedAuraInstanceIDs) do
        if v == self.auraInstanceID then
          self.auraInstanceID = nil
          self:SetStatusBarTexture("Interface/Addons/Mac_Dragonriding/speed-lane3")
        end
      end
    end
  end
end

function SpeedLaneMixin:OnUpdate()
  if GetTime() > (self.time + timeDelay) then
    self.time = GetTime()
    local widgetInfo = C_UIWidgetManager.GetFillUpFramesWidgetVisualizationInfo(vigorWidgetId)
    if widgetInfo ~= nil and widgetInfo.numTotalFrames ~= 0 then
        --local widgetInfo = C_UIWidgetManager.GetFillUpFramesWidgetVisualizationInfo(vigorWidgetId)
        -- if widgetInfo == nil or widgetInfo.numTotalFrames == 0 then
        --     print("parent:Hide()")
        --     local parent = self:GetParent()
        --     parent:Hide()
        -- end
        local isGliding, canGlide, forwardSpeed = C_PlayerInfo.GetGlidingInfo()
        local value = (55.08 / 100) * forwardSpeed
        self:SetValue(value)
        self.Text:SetText(math.modf(forwardSpeed))
    else
      print("parent:Hide()")
      local parent = self:GetParent()
      parent:Hide()
    end
  end
end