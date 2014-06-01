

local LAM = LibStub("LibAddonMenu-1.0")
InventoryGridViewSettings = ZO_Object:Subclass()
local settings = nil

local BAGS = ZO_PlayerInventoryBackpack
local BANK = ZO_PlayerBankBackpack
local GUILD_BANK = ZO_GuildBankBackpack

local SKIN_CHOICES = { "Classic", "Rushmik", "Clean: by Tonyleila" }

local TEXTURES = {
	["Classic"] = {
		BACKGROUND = "InventoryGridView/assets/griditem_background.dds", --set to black?
		OUTLINE = "InventoryGridView/assets/griditem_outline.dds",
		HOVER = "InventoryGridView/assets/griditem_hover.dds",
		TOGGLE = "InventoryGridView/assets/grid_view_toggle_button.dds"
	},
	["Rushmik"] = {
		BACKGROUND = "InventoryGridView/assets/rushmik_background.dds",
		OUTLINE = "InventoryGridView/assets/rushmik_outline.dds",
		HOVER = "InventoryGridView/assets/rushmik_background.dds",
		TOGGLE = "InventoryGridView/assets/grid_view_toggle_button.dds"
	},
	["Clean: by Tonyleila"] = {
		BACKGROUND = "InventoryGridView/assets/tonyleila_background.dds",
		OUTLINE = "InventoryGridView/assets/tonyleila_outline.dds",
		HOVER = "InventoryGridView/assets/tonyleila_hover.dds",
		TOGGLE = "InventoryGridView/assets/tonyleila_toggle_button.dds"
	}
}

local QUALITY_OPTIONS = {
	"Trash", "Normal", "Magic", "Arcane", "Artifact", "Legendary"
}

local QUALITY = {
	["Trash"] = ITEM_QUALITY_TRASH,
	["Normal"] = ITEM_QUALITY_NORMAL,
	["Magic"] = ITEM_QUALITY_MAGIC,
	["Arcane"] = ITEM_QUALITY_ARCANE,
	["Artifact"] = ITEM_QUALITY_ARTIFACT,
	["Legendary"] = ITEM_QUALITY_LEGENDARY
}
 
--LAM extension
local function LAMAddExample(panelID, controlName, ctTexture, maxHeight, sliderToBind, updateFunction, warning, warningText)
	local example = WINDOW_MANAGER:CreateControl(controlName, ZO_OptionsWindowSettingsScrollChild, CT_CONTROL)
	example:SetAnchor(TOPLEFT, LAM.lastAddedControl[panelID], BOTTOMLEFT, 0, 6)
	example:SetAnchor(TOPRIGHT, LAM.lastAddedControl[panelID], BOTTOMRIGHT, 0, 6)
	example:SetHeight(maxHeight + 4)
	example.controlType = OPTIONS_EXAMPLE
	example.system = SETTING_TYPE_UI
	example.panel = panelID
	-- example.text = text
	-- example.tooltipText = tooltip
	example.showValue = true

	ctTexture:SetParent(example)
	ctTexture:SetAnchor(CENTER, example, CENTER)

	local sliderControl = sliderToBind:GetNamedChild("Slider")
	local sliderValue = sliderToBind:GetNamedChild("ValueLabel")

	example:SetHandler("OnShow", function()
			updateFunction(sliderValue:GetText())
		end)

	local originalHandler = sliderControl:GetHandler("OnValueChanged")
	sliderControl:SetHandler("OnValueChanged", function(self, value)
			originalHandler(self, value)
			updateFunction(sliderValue:GetText())
		end)
	
	-- if warning then
	-- 	example.warning = wm:CreateControlFromVirtual(controlName.."WarningIcon", example, "ZO_Options_WarningIcon")
	-- 	example.warning:SetAnchor(RIGHT, slidercontrol, LEFT, -5, 0)
	-- 	example.warning.tooltipText = warningText
	-- end
	
	ZO_OptionsWindow_InitializeControl(example)
	
	LAM.lastAddedControl[panelID] = example
	
	return example
end


function InventoryGridViewSettings:New()
	local obj = ZO_Object.New(self)
	obj:Initialize()
	return obj
end

function InventoryGridViewSettings:Initialize()
	local defaults = {
        isInventoryGrid = true,
        isBankGrid = true,
        isGuildBankGrid = true,
        allowRarityColor = true,
        gridSize = 52,
        minimumQuality = "Magic",
        skinChoice = "Rushmik",
        valueTooltip = true
    }

    settings = ZO_SavedVars:New("InventoryGridView_Settings", 2, nil, defaults)
    self:CreateOptionsMenu()
	InventoryGridView_SetMinimumQuality(QUALITY[settings.minimumQuality])
	InventoryGridView_SetTextureSet(TEXTURES[settings.skinChoice])
end

function InventoryGridViewSettings:IsGrid( inventoryId )
	if(inventoryId == INVENTORY_BACKPACK) then
		return settings.isInventoryGrid
	elseif(inventoryId == INVENTORY_BANK) then
		return settings.isBankGrid
	elseif(inventoryId == INVENTORY_GUILD_BANK) then
		return settings.isGuildBankGrid
	end
end

function InventoryGridViewSettings:ToggleGrid( inventoryId )
	if(inventoryId == INVENTORY_BACKPACK) then
		settings.isInventoryGrid = not settings.isInventoryGrid
	elseif(inventoryId == INVENTORY_BANK) then
		settings.isBankGrid = not settings.isBankGrid
	elseif(inventoryId == INVENTORY_GUILD_BANK) then
		settings.isGuildBankGrid = not settings.isGuildBankGrid
	end
end

function InventoryGridViewSettings:IsAllowOutline()
	return settings.allowRarityColor
end

function InventoryGridViewSettings:GetGridSize()
	return settings.gridSize
end

function InventoryGridViewSettings:GetTextureSet()
	return TEXTURES[settings.skinChoice]
end

function InventoryGridViewSettings:IsShowValueTooltip()
	return settings.valueTooltip
end

function InventoryGridViewSettings:CreateOptionsMenu()
	--example texture for skin and slider
	local example = WINDOW_MANAGER:CreateControl("IGV_Grid_Size_Example_Texture", GuiRoot, CT_CONTROL)
	example:SetMouseEnabled(true)

	local ex_bg = WINDOW_MANAGER:CreateControl("IGV_Grid_Size_Example_Texture_BG", example, CT_TEXTURE)
	ex_bg:SetAnchorFill(example)
	ex_bg:SetTexture(self:GetTextureSet().BACKGROUND)

	local ex_outline = WINDOW_MANAGER:CreateControl("IGV_Grid_Size_Example_Texture_Outline", example, CT_TEXTURE)
	ex_outline:SetAnchorFill(example)
	ex_outline:SetTexture(self:GetTextureSet().OUTLINE)
	ex_outline:SetHidden(not self:IsAllowOutline())

	local ex_hover = WINDOW_MANAGER:CreateControl("IGV_Grid_Size_Example_Texture_Hover", example, CT_TEXTURE)
	ex_hover:SetAnchorFill(example)
	ex_hover:SetTexture(self:GetTextureSet().HOVER)
	ex_hover:SetHidden(true)

	example:SetHandler("OnMouseEnter", 
		function()
			ex_hover:SetHidden(false)
		end)
	example:SetHandler("OnMouseExit", 
		function()
			ex_hover:SetHidden(true)
		end)

	--now actually set up the panel
	local panel = LAM:CreateControlPanel("InventoryGridViewSettingsPanel", "Inventory Grid View Settings")
	LAM:AddHeader(panel, "IGV_Settings_header", "Inventory Grid View")
	LAM:AddDropdown(panel, "IGV_Skin_Dropdown", "Skin", "Which skin would you like to use for Grid View?",
					SKIN_CHOICES,
					function() return settings.skinChoice end,
					function(value)
						settings.skinChoice = value
						InventoryGridView_SetTextureSet(TEXTURES[value], true)
						ex_bg:SetTexture(self:GetTextureSet().BACKGROUND)
						ex_outline:SetTexture(self:GetTextureSet().OUTLINE)
						ex_hover:SetTexture(self:GetTextureSet().HOVER)
						InventoryGridView_SetToggleButtonTexture()
					end)

	LAM:AddCheckbox(panel, "IGV_Rarity_Outlines", "Rarity outlines", "Toggle the outlines on or off.",
					function() return self:IsAllowOutline() end,	--getFunc
					function()							--setFunc
						settings.allowRarityColor = not settings.allowRarityColor
						InventoryGridView_ToggleOutlines(BAGS, settings.allowRarityColor)
						InventoryGridView_ToggleOutlines(BANK, settings.allowRarityColor)
						InventoryGridView_ToggleOutlines(GUILD_BANK, settings.allowRarityColor)
						ex_outline:SetHidden(not self:IsAllowOutline())
					end)

	LAM:AddDropdown(panel, "IGV_Min_Rarity_Dropdown", "Minimum outline quality", "Don't show outlines under this quality",
					QUALITY_OPTIONS,
					function() return settings.minimumQuality end,	--getFunc
					function(value)							--setFunc
						settings.minimumQuality = value
						InventoryGridView_SetMinimumQuality(QUALITY[value], true)
					end)

	local slider = LAM:AddSlider(panel, "IGV_Grid_Size", "Grid size", "Set how big or small the grid icons are.", 24, 96, 4,
					function() return settings.gridSize end,
					function(value)
						settings.gridSize = value
						BAGS.gridSize = value
						BANK.gridSize = value
						GUILD_BANK.gridSize = value
						InventoryGridView_ToggleOutlines(BAGS, settings.allowRarityColor)
						InventoryGridView_ToggleOutlines(BANK, settings.allowRarityColor)
						InventoryGridView_ToggleOutlines(GUILD_BANK, settings.allowRarityColor)
					end)

	LAMAddExample(panel, "IGV_Grid_Size_Example", example, 96, slider, function(value)
			example:SetDimensions(value, value)
		end)

	LAM:AddCheckbox(panel, "IGV_Value_Tooltip", "Tooltip gold", "Should we add the stack's value to the tooltip in grid view?",
					function() return settings.valueTooltip end,	--getFunc
					function()							--setFunc
						settings.valueTooltip = not settings.valueTooltip
					end)
end