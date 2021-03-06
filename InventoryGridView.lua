------------------------------------------------------------------
--InventoryGridView.lua
--Author: ingeniousclown
--v1.1.2

--InventoryGridView was designed to try and leverage the default
--UI as much as possible to create a grid view.  The result is
--somewhat hacky, but it works well.

--Main functions for the mod.
------------------------------------------------------------------

local BAGS = ZO_PlayerInventoryBackpack
local BANK = ZO_PlayerBankBackpack
local GUILD_BANK = ZO_GuildBankBackpack

local IGVSettings = nil

local toggleButtonTextures = {}

local _

function InventoryGridView_SetToggleButtonTexture()
    for _,v in pairs(toggleButtonTextures) do
        v:SetTexture(IGVSettings:GetTextureSet().TOGGLE)
    end
end

local function ButtonClickHandler(button)
	IGVSettings:ToggleGrid(button.inventoryId)

	InventoryGridView_ToggleGrid(button.itemArea, not button.itemArea.isGrid)
end

local function AddButton(parentWindow, inventoryId)
    local button = WINDOW_MANAGER:CreateControl(parentWindow:GetName() .. "_GridButton", parentWindow, CT_BUTTON)
    button:SetDimensions(24,24)
    button:SetAnchor(TOP, parentWindow, BOTTOM, 12, 6)
    button:SetFont("ZoFontGameSmall")
    button:SetHandler("OnClicked", ButtonClickHandler)
    button:SetMouseEnabled(true)

    button.itemArea = parentWindow:GetNamedChild("Backpack")
    button.inventoryId = inventoryId

    local texture = WINDOW_MANAGER:CreateControl(parentWindow:GetName() .. "_GridButtonTexture", button, CT_TEXTURE)
    texture:SetAnchorFill()

    table.insert(toggleButtonTextures, texture)

    -- texture:SetColor(1, 1, 1, 1)
end

local function AddGold(rowControl)
    if(not rowControl.dataEntry) then return end
    local bagId = rowControl.dataEntry.data.bagId
    local slotIndex = rowControl.dataEntry.data.slotIndex
    local _, stack, sellPrice = GetItemInfo(bagId, slotIndex)

    if(stack * sellPrice > 0) then
        ZO_ItemTooltip_AddMoney(ItemTooltip, sellPrice * stack)
    end
end

local function AddGoldSoon(rowControl)
    if(rowControl and rowControl.isGrid and IGVSettings:IsShowValueTooltip()) then
        zo_callLater(function() AddGold(rowControl) end, 50)
    end
end

local function InventoryGridViewLoaded(eventCode, addOnName)
    if(addOnName ~= "InventoryGridView") then
        return
    end

    IGVSettings = InventoryGridViewSettings:New()

    local controlWidth = BAGS.controlHeight
    local leftPadding = 25
    local contentsWidth = BAGS:GetNamedChild("Contents"):GetWidth()
    local itemsPerRow = zo_floor((contentsWidth - leftPadding) / (controlWidth))
    local gridSpacing = ((contentsWidth - leftPadding) % itemsPerRow) / itemsPerRow

    BAGS.forceUpdate = false
    BAGS.listHeight = controlWidth
    BAGS.leftPadding = leftPadding
    BAGS.contentsWidth = contentsWidth
    BAGS.itemsPerRow = itemsPerRow
    BAGS.gridSpacing = gridSpacing
    BAGS.bagId = INVENTORY_BACKPACK
    BAGS.isGrid = IGVSettings:IsGrid(BAGS.bagId)
    BAGS.isOutlines = IGVSettings:IsAllowOutline()
    BAGS.gridSize = IGVSettings:GetGridSize()

    controlWidth = BANK.controlHeight
    contentsWidth = BANK:GetNamedChild("Contents"):GetWidth()

    BANK.forceUpdate = true
    BANK.listHeight = controlWidth
    BANK.leftPadding = leftPadding
    BANK.contentsWidth = contentsWidth
    BANK.itemsPerRow = itemsPerRow
    BANK.gridSpacing = gridSpacing
    BANK.bagId = INVENTORY_BANK
    BANK.isGrid = IGVSettings:IsGrid(BANK.bagId)
    BANK.isOutlines = IGVSettings:IsAllowOutline()
    BANK.gridSize = IGVSettings:GetGridSize()

    controlWidth = GUILD_BANK.controlHeight
    contentsWidth = GUILD_BANK:GetNamedChild("Contents"):GetWidth()

    GUILD_BANK.forceUpdate = true
    GUILD_BANK.listHeight = controlWidth
    GUILD_BANK.leftPadding = leftPadding
    GUILD_BANK.contentsWidth = contentsWidth
    GUILD_BANK.itemsPerRow = itemsPerRow
    GUILD_BANK.gridSpacing = gridSpacing
    GUILD_BANK.bagId = INVENTORY_GUILD_BANK
    GUILD_BANK.isGrid = IGVSettings:IsGrid(GUILD_BANK.bagId)
    GUILD_BANK.isOutlines = IGVSettings:IsAllowOutline()
    GUILD_BANK.gridSize = IGVSettings:GetGridSize()

    InitGridView()
    InventoryGridView_ToggleOutlines(BAGS, IGVSettings:IsAllowOutline())
    InventoryGridView_ToggleOutlines(BANK, IGVSettings:IsAllowOutline())
    InventoryGridView_ToggleOutlines(GUILD_BANK, IGVSettings:IsAllowOutline())

    AddButton(ZO_PlayerInventory, BAGS.bagId)
    AddButton(ZO_PlayerBank, BANK.bagId)
    AddButton(ZO_GuildBank, GUILD_BANK.bagId)    
    InventoryGridView_SetToggleButtonTexture()

    ZO_PreHook("ZO_InventorySlot_OnMouseEnter", AddGoldSoon)
end

--initialize
local function InventoryGridViewInitialized()
	EVENT_MANAGER:RegisterForEvent("InventoryGridViewLoaded", EVENT_ADD_ON_LOADED, InventoryGridViewLoaded)
end

InventoryGridViewInitialized()