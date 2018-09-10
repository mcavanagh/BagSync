--[[
	tooltip.lua
		Tooltip module for BagSync
--]]

local BSYC = select(2, ...) --grab the addon namespace
local Tooltip = BSYC:NewModule("Tooltip", 'AceEvent-3.0')
local Unit = BSYC:GetModule("Unit")
local Data = BSYC:GetModule("Data")
local L = LibStub("AceLocale-3.0"):GetLocale("BagSync", true)

function Tooltip:HexColor(color, str)
	if type(color) == "table" then
		return string.format("|cff%02x%02x%02x%s|r", (color.r or 1) * 255, (color.g or 1) * 255, (color.b or 1) * 255, tostring(str))
	elseif type(color) == "string" then
		string.format("|cff%s%s|r", tostring(color), tostring(str))
	end
	return str
end

function Tooltip:GetSortIndex(unitObj)
	if unitObj then
		if not unitObj.isGuild and unitObj.realm == Unit:GetUnitInfo().realm then
			return 1
		elseif not unitObj.isGuild and unitObj.isConnectedRealm then
			return 2
		elseif not unitObj.isGuild then
			return 3
		end
	end
	return 4
end

function Tooltip:ColorizeUnit(unitObj)
	if not unitObj.data then return nil end
	
	if unitObj.isGuild then
		return self:HexColor(BSYC.db.options.colors.first, select(2, Unit:GetUnitAddress(unitObj.name)) )
	end
	
	local player = Unit:GetUnitInfo()
	local tmpTag = ""
	
	--first colorize by class color
	if BSYC.db.options.enableUnitClass and RAID_CLASS_COLORS[unitObj.data.class] then
		tmpTag = self:HexColor(RAID_CLASS_COLORS[unitObj.data.class], unitObj.name)
	else
		tmpTag = self:HexColor(BSYC.db.options.colors.first, unitObj.name)
	end
	
	--add green checkmark
	if unitObj.name == player.name and unitObj.realm == player.realm and BSYC.db.options.enableTooltipGreenCheck then
		local ReadyCheck = [[|TInterface\RaidFrame\ReadyCheck-Ready:0|t]]
		tmpTag = ReadyCheck.." "..tmpTag
	end
	
	--add faction icons
	if BSYC.db.options.enableFactionIcons then
		local FactionIcon = [[|TInterface\Icons\Achievement_worldevent_brewmaster:18|t]]
		
		if unitObj.data.faction == "Alliance" then
			FactionIcon = [[|TInterface\Icons\Inv_misc_tournaments_banner_human:18|t]]
		elseif unitObj.data.faction == "Horde" then
			FactionIcon = [[|TInterface\Icons\Inv_misc_tournaments_banner_orc:18|t]]
		end
		
		tmpTag = FactionIcon.." "..tmpTag
	end
	
	--add crossrealm and bnet tags
	local realm = unitObj.realm
	local realmTag = ""
	
	if BSYC.db.options.enableRealmAstrickName then
		realm = "*"
	elseif BSYC.db.options.enableRealmShortName then
		realm = string.sub(realm, 1, 5)
	end
	
	if BSYC.db.options.enableBNetAccountItems and not unitObj.isConnectedRealm then
		realmTag = BSYC.db.options.enableRealmIDTags and L.TooltipBattleNetTag.." "
		tmpTag = self:HexColor(BSYC.db.options.colors.bnet, "["..realmTag..realm.."]").." "..tmpTag
	end
	
	if BSYC.db.options.enableCrossRealmsItems and unitObj.isConnectedRealm and unitObj.realm ~= player.realm then
		realmTag = BSYC.db.options.enableRealmIDTags and L.TooltipCrossRealmTag.." "
		tmpTag = self:HexColor(BSYC.db.options.colors.cross, "["..realmTag..realm.."]").." "..tmpTag
	end
	
	return tmpTag
end

function Tooltip:MoneyTooltip()
	local tooltip = _G["BagSyncMoneyTooltip"] or nil
	
	if (not tooltip) then
			tooltip = CreateFrame("GameTooltip", "BagSyncMoneyTooltip", UIParent, "GameTooltipTemplate")
			
			local closeButton = CreateFrame("Button", nil, tooltip, "UIPanelCloseButton")
			closeButton:SetPoint("TOPRIGHT", tooltip, 1, 0)
			
			tooltip:SetToplevel(true)
			tooltip:EnableMouse(true)
			tooltip:SetMovable(true)
			tooltip:SetClampedToScreen(true)
			
			tooltip:SetScript("OnMouseDown",function(self)
					self.isMoving = true
					self:StartMoving();
			end)
			tooltip:SetScript("OnMouseUp",function(self)
				if( self.isMoving ) then
					self.isMoving = nil
					self:StopMovingOrSizing()
				end
			end)
	end

	local usrData = {}
	
	tooltip:ClearLines()
	tooltip:ClearAllPoints()
	tooltip:SetOwner(UIParent, "ANCHOR_NONE")
	tooltip:SetPoint("CENTER",UIParent,"CENTER",0,0)
	tooltip:AddLine("BagSync")
	tooltip:AddLine(" ")
	
	--loop through our characters
	local usrData = {}
	local total = 0
	local player = Unit:GetUnitInfo()
	
	for unitObj in Data:IterateUnits() do
		if unitObj.data.money and unitObj.data.money > 0 then
			table.insert(usrData, { unitObj=unitObj, colorized=self:ColorizeUnit(unitObj), sortIndex=Tooltip:GetSortIndex(unitObj) } )
		end
	end
	
	--sort the list by our sortIndex then by realm and finally by name
	table.sort(usrData, function(a, b)
		if a.sortIndex  == b.sortIndex then
			if a.unitObj.realm == b.unitObj.realm then
				return a.unitObj.name < b.unitObj.name;
			end
			return a.unitObj.realm < b.unitObj.realm;
		else
			return a.sortIndex < b.sortIndex;
		end
	  
	end)

	for i=1, table.getn(usrData) do
		--use GetMoneyString and true to seperate it by thousands
		tooltip:AddDoubleLine(usrData[i].colorized, GetMoneyString(usrData[i].unitObj.data.money, true), 1, 1, 1, 1, 1, 1)
		total = total + usrData[i].unitObj.data.money
	end
	if BSYC.db.options.showTotal and total > 0 then
		tooltip:AddLine(" ")
		tooltip:AddDoubleLine(self:HexColor(BSYC.db.options.colors.total, L.TooltipTotal), GetMoneyString(total, true), 1, 1, 1, 1, 1, 1)
	end
	
	tooltip:AddLine(" ")
	tooltip:Show()
end