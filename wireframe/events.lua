--[[
	events.lua
		Event module for BagSync, captures and processes events
--]]

local BSYC = select(2, ...) --grab the addon namespace
local Events = BSYC:NewModule("Events", 'AceEvent-3.0')
local Unit = BSYC:GetModule("Unit")
local Scanner = BSYC:GetModule("Scanner")

function Events:OnEnable()
	self:RegisterEvent('PLAYER_MONEY')
	self:RegisterEvent('GUILD_ROSTER_UPDATE')
	self:RegisterEvent("UNIT_INVENTORY_CHANGED")
	
	self:RegisterEvent('VOID_STORAGE_OPEN', function() Scanner:ScanVoidBank() end)
	self:RegisterEvent('VOID_STORAGE_UPDATE', function() Scanner:ScanVoidBank() end)
	self:RegisterEvent('VOID_STORAGE_CONTENTS_UPDATE', function() Scanner:ScanVoidBank() end)
	self:RegisterEvent('VOID_TRANSFER_DONE', function() Scanner:ScanVoidBank() end)
	
	self:RegisterEvent('MAIL_SHOW', function() Scanner:ScanMailbox() end)
	self:RegisterEvent('MAIL_INBOX_UPDATE', function() Scanner:ScanMailbox() end)
	
	self:RegisterEvent("BANKFRAME_OPENED", function() Scanner:ScanBank() end)
	self:RegisterEvent("PLAYERBANKSLOTS_CHANGED", function() Scanner:ScanBank(true) end)
	self:RegisterEvent("PLAYERREAGENTBANKSLOTS_CHANGED", function() Scanner:ScanReagents() end)
	self:RegisterEvent("REAGENTBANK_PURCHASED", function() Scanner:ScanReagents() end)

end

function Events:PLAYER_MONEY()
	BSYC.db.player.money = Unit:GetUnitInfo().money
end

function Events:GUILD_ROSTER_UPDATE()
	BSYC.db.player.guild = Unit:GetUnitInfo().guild
end

function Events:UNIT_INVENTORY_CHANGED(event, unit)
	if unit == "player" then
		Scanner:SaveEquipment()
	end
end
