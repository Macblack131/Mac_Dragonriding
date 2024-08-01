local vigorWidgetId = 4460
local timeDelay = 0.1

Mac_DragonridingMixin = {}

function Mac_DragonridingMixin:OnLoad()
  self:RegisterEvent("UPDATE_UI_WIDGET")
end

function Mac_DragonridingMixin:OnEvent(event, ...)
  if event == "UPDATE_UI_WIDGET" then
    if UIWidgetPowerBarContainerFrame and UIWidgetPowerBarContainerFrame.widgetFrames[vigorWidgetId] then
      local widgetInfo = C_UIWidgetManager.GetFillUpFramesWidgetVisualizationInfo(vigorWidgetId)
      if (UIWidgetPowerBarContainerFrame.widgetFrames[vigorWidgetId]:IsShown()) then
        UIWidgetPowerBarContainerFrame.widgetFrames[vigorWidgetId]:Hide()
      end
      if not self:IsShown() then
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
          self:SetStatusBarTexture("Interface/Addons/Mac_Dragonriding/speed-lane2")
        end
      end
    end
    if info.removedAuraInstanceIDs then
      for _, v in pairs(info.removedAuraInstanceIDs) do
        if v == self.auraInstanceID then
          self.auraInstanceID = nil
          self:SetStatusBarTexture("Interface/Addons/Mac_Dragonriding/speed-lane")
        end
      end
    end
  end
end

function SpeedLaneMixin:OnUpdate()
  if GetTime() > (self.time + timeDelay) then
    self.time = GetTime()
    local widgetInfo = C_UIWidgetManager.GetFillUpFramesWidgetVisualizationInfo(vigorWidgetId)
    if widgetInfo.numTotalFrames == 0 then
      local parent = self:GetParent()
      parent:Hide()
    end
    local isGliding, canGlide, forwardSpeed = C_PlayerInfo.GetGlidingInfo()
    local value = (68.36 / 100) * forwardSpeed
    self:SetValue(value)
    self.Text:SetText(math.modf(forwardSpeed))
  end
end