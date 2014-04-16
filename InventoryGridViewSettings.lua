

local LAM = LibStub("LibAddonMenu-1.0")
InventoryGridViewSettings = ZO_Object:Subclass()
local settings = nil

local BAGS = ZO_PlayerInventoryBackpack
local BANK = ZO_PlayerBankBackpack
local GUILD_BANK = ZO_GuildBankBackpack

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
        gridSize = 52
    }

    settings = ZO_SavedVars:New("InventoryGridView_Settings", 1, nil, defaults)
    self:CreateOptionsMenu()
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

function InventoryGridViewSettings:CreateOptionsMenu()
	local panel = LAM:CreateControlPanel("InventoryGridViewSettingsPanel", "Inventory Grid View Settings")
	LAM:AddHeader(panel, "IGV_Settings_header", "Inventory Grid View")
	LAM:AddCheckbox(panel, "IGV_Rarity_Outlines", "Rarity outlines", "Toggle the outlines on or off.",
					function() return self:IsAllowOutline() end,	--getFunc
					function()							--setFunc
						settings.allowRarityColor = not settings.allowRarityColor
						InventoryGridView_ToggleOutlines(BAGS, settings.allowRarityColor)
						InventoryGridView_ToggleOutlines(BANK, settings.allowRarityColor)
						InventoryGridView_ToggleOutlines(GUILD_BANK, settings.allowRarityColor)
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

	local example = WINDOW_MANAGER:CreateControl("IGV_Grid_Size_Example_Texture", GuiRoot, CT_TEXTURE)
	example:SetTexture("InventoryGridView/assets/griditem_outline.dds")
	LAMAddExample(panel, "IGV_Grid_Size_Example", example, 96, slider, function(value)
			example:SetDimensions(value, value)
		end)

end

