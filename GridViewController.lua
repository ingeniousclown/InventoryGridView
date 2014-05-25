------------------------------------------------------------------
--GridViewController.lua
--Author: ingeniousclown

--This is mostly a re-implementation of ZO_ScrollList_UpdateScroll
--and copies of all the local functions necessary to make it work.

--It also includes an init to add all the necessary fields to
--convert the list to grid view.
------------------------------------------------------------------

local LIST_SLOT_BACKGROUND = [[EsoUI/Art/Miscellaneous/listItem_backdrop.dds]]
local LIST_SLOT_HOVER = [[EsoUI/Art/Miscellaneous/listitem_highlight.dds]]
local ICON_MULT = 0.77

local minimumQuality = ITEM_QUALITY_TRASH

local TEXTURE_SET = nil

-------------------------
--my own util functions
-------------------------

local function GetTopLeftTargetPosition(index, itemsPerRow, controlWidth, controlHeight, leftPadding, gridSpacing)
    local controlTop = zo_floor((index-1) / itemsPerRow) * (controlHeight + gridSpacing)
    local controlLeft = ((index-1) % itemsPerRow) * (controlWidth + gridSpacing) + leftPadding

    return controlTop, controlLeft
end

local function AddColor(control)
    if(not control.dataEntry) then return end

    local bagId = control.dataEntry.data.bagId
    local slotIndex = control.dataEntry.data.slotIndex
    local _, _, _, _, _, _, _, quality = GetItemInfo(bagId, slotIndex)
    local r, g, b = GetInterfaceColor(INTERFACE_COLOR_TYPE_ITEM_QUALITY_COLORS, quality)

    local alpha = 1
    if(quality < minimumQuality) then
        alpha = 0
    end

    control:GetNamedChild("Bg"):SetColor(r, g, b, 1)
    control:GetNamedChild("Outline"):SetColor(r, g, b, alpha)
    control:GetNamedChild("Highlight"):SetColor(r, g, b, 0)
end

local function ReshapeSlot(control, isGrid, isOutlines, width, height, forceUpdate)
    if control == nil then return end

    -- if(control.isGrid == nil) then control.isGrid = false end

    --i pulled this out of the below part of the function because it wasn't
    --being hidden correctly.  My guess is that some other function unhides
    --the control

    control:GetNamedChild("SellPrice"):SetHidden(isGrid)
    if(control.isGrid ~= isGrid or forceUpdate) then
        control.isGrid = isGrid
        local thisName = control:GetName()

        local button = control:GetNamedChild("Button")
        local bg = control:GetNamedChild("Bg")
        local new = control:GetNamedChild("NewStatus")
        local name = control:GetNamedChild("Name")
        local stat = control:GetNamedChild("StatValue")
        local sell = control:GetNamedChild("SellPrice")
        local highlight = control:GetNamedChild("Highlight")
        -- local research = control:GetNamedChild("Research")
        local outline = control:GetNamedChild("Outline")
        if(not outline) then
            outline = WINDOW_MANAGER:CreateControl(control:GetName() .. "Outline", control, CT_TEXTURE)
            outline:SetAnchor(CENTER, control, CENTER)
        end

        button:ClearAnchors()
        new:ClearAnchors()
        control:SetDimensions(width, height)
        button:SetDimensions(height * ICON_MULT, height * ICON_MULT)
        outline:SetDimensions(height, height)
        
        if(isGrid) then
            button:SetAnchor(CENTER, control, CENTER)

            new:SetDimensions(5,5)
            new:SetAnchor(TOPLEFT, control, TOPLEFT, 10, 10)

            name:SetHidden(true)
            stat:SetHidden(true)
            highlight:SetTexture(TEXTURE_SET.HOVER)
            highlight:SetTextureCoords(0, 1, 0, 1)

            bg:SetTexture(TEXTURE_SET.BACKGROUND)
            bg:SetTextureCoords(0, 1, 0, 1)
            sell:SetAlpha(0)

            if(isOutlines) then
                outline:SetTexture(TEXTURE_SET.OUTLINE)
                outline:SetHidden(false)
            else
                outline:SetHidden(true)
            end
            AddColor(control)

            -- if(research) then
            --     research:SetHidden(true)
            -- end
        else
            button:SetAnchor(CENTER, control, TOPLEFT, 47, 26)

            new:SetAnchor(CENTER, control, TOPLEFT, 20, 27)

            name:SetHidden(false)
            stat:SetHidden(false)
            outline:SetHidden(true)

            highlight:SetTexture(LIST_SLOT_HOVER)
            highlight:SetColor(1, 1, 1, 0)
            highlight:SetTextureCoords(0, 1, 0, .625)

            bg:SetTexture(LIST_SLOT_BACKGROUND)
            bg:SetTextureCoords(0, 1, 0, .8125)
            bg:SetColor(1, 1, 1, 1)
            sell:SetAlpha(1)
        end
    end
end

local function ReshapeSlots(self)
    local allControlsParent = self:GetNamedChild("Contents")
    local numControls = allControlsParent:GetNumChildren()
    
    local width, height
    if self.isGrid then 
        width = self.gridSize
        height = self.gridSize
    else 
        width = self.contentsWidth
        height = self.listHeight
    end

    for i = 2, numControls do
        ReshapeSlot(allControlsParent:GetChild(i), self.isGrid, self.isOutlines, width, height, self.forceUpdate)
    end

    if(self.forceUpdate) then
        for _,v in pairs(self.dataTypes[1].pool["m_Free"]) do
            ReshapeSlot(v, self.isGrid, self.isOutlines, width, height, self.forceUpdate)
        end
    end

    self.forceUpdate = false
end

--------------------------------------------------------------------------------------
--the following functions are ported from scrolltemplates.lua because they're local
--and necessary for the UpdateList function to work correctly
--------------------------------------------------------------------------------------

--scrolltemplates.lua line 139
local function UpdateScrollFade(useFadeGradient, scroll, slider, sliderValue)
    if(useFadeGradient) then
        local sliderMin, sliderMax = slider:GetMinMax()
        sliderValue = sliderValue or slider:GetValue()

        if(sliderValue > sliderMin) then
            scroll:SetFadeGradient(1, 0, 1, zo_min(sliderValue - sliderMin, 64))
        else
            scroll:SetFadeGradient(1, 0, 0, 0)
        end
        
        if(sliderValue < sliderMax) then
            scroll:SetFadeGradient(2, 0, -1, zo_min(sliderMax - sliderValue, 64))
        else
            scroll:SetFadeGradient(2, 0, 0, 0);
        end
    else
        scroll:SetFadeGradient(1, 0, 0, 0)
        scroll:SetFadeGradient(2, 0, 0, 0)
    end
end

--scrolltemplates.lua line 425
local function AreSelectionsEnabled(self)
    return self.selectionTemplate or self.selectionCallback
end

--scrolltemplates.lua line 580
local function RemoveAnimationOnControl(control, animationFieldName)
    if control[animationFieldName] then
        control[animationFieldName]:PlayBackward()
    end
end

--scrolltemplates.lua line 596
local function UnhighlightControl(self, control) 
    RemoveAnimationOnControl(control, "HighlightAnimation")

    self.highlightedControl = nil

    if(self.highlightCallback) then
        self.highlightCallback(control, false)
    end
end

--scrolltemplates.lua line 612
local function UnselectControl(self, control)
    RemoveAnimationOnControl(control, "SelectionAnimation")

    self.selectedControl = nil
end

--scrolltemplates.lua line 740
--Determines if one piece of selected data is the "same" as the other. Used mainly to
--keep an item selected even when the data for the list is updated if they share some
--property determined by the equality function. For example, if you have an item with
--id=1 and state=up and replace it with id=1 and state=down, the selection will be maintained
--if the equality function only compares ids.  
local function AreDataEqualSelections(self, data1, data2)
    if(data1 == data2) then
        return true
    end

    if(data1 == nil or data2 == nil) then
        return false
    end        

    local dataEntry1 = data1.dataEntry
    local dataEntry2 = data2.dataEntry
    if(dataEntry1.typeId == dataEntry2.typeId) then
        local equalityFunction = self.dataTypes[dataEntry1.typeId].equalityFunction
        if(equalityFunction) then
            return equalityFunction(data1, data2)
        end
    end

    return false
end

--scrolltemplates.lua line 825
local function FreeActiveScrollListControl(self, i)
    local currentControl = self.activeControls[i]
    local currentDataEntry = currentControl.dataEntry
    local dataType = self.dataTypes[currentDataEntry.typeId]
    
    if(self.highlightTemplate and currentControl == self.highlightedControl) then
        UnhighlightControl(self, currentControl)
        if(self.highlightLocked) then
            self.highlightLocked = false
        end
    end

    if(currentControl == self.pendingHighlightControl) then
        self.pendingHighlightControl = nil
    end
    
    if(AreSelectionsEnabled(self) and currentControl == self.selectedControl) then
        UnselectControl(self, currentControl)
    end
    
    if(dataType.hideCallback) then
        dataType.hideCallback(currentControl, currentControl.dataEntry.data)
    end
    
    dataType.pool:ReleaseObject(currentControl.key)
    currentControl.key = nil
    currentControl.dataEntry = nil
    self.activeControls[i] = self.activeControls[#self.activeControls]
    self.activeControls[#self.activeControls] = nil
end

local function ResizeScrollBar(self, scrollableDistance)
    local scrollBarHeight = self.scrollbar:GetHeight()
    local scrollListHeight = ZO_ScrollList_GetHeight(self)
    if(scrollableDistance > 0) then
        self.scrollbar:SetEnabled(true)
        self.scrollbar:SetHidden(false)
        self.scrollbar:SetMinMax(0, scrollableDistance)
        self.scrollbar:SetThumbTextureHeight(scrollBarHeight * scrollListHeight /(scrollableDistance + scrollListHeight))
        if(self.offset > scrollableDistance) then
            self.offset = scrollableDistance
        end
    else
        self.offset = 0
        self.scrollbar:SetMinMax(0, 0)
        self.scrollbar:SetEnabled(false)
        self.scrollbar:SetThumbTextureHeight(scrollBarHeight)

        if(self.hideScrollBarOnDisabled) then
            self.scrollbar:SetHidden(true)
        end
    end
end
--end copied functions

--------------------------------------------------------------------------------------
--meat of the mod - modified ZO_ScrollList_UpdateScroll(self)
--------------------------------------------------------------------------------------

--modified version of function ZO_ScrollList_UpdateScroll(self)
--this is lightly modified to turn the view into a grid view
--from esoui\libraries\zo_templates\scrolltemplates.lua line 1157
local consideredMap = {}

local function UpdateScroll_Grid(self)
    local windowHeight = ZO_ScrollList_GetHeight(self)
    local controlHeight = self.gridSize
    local controlWidth = self.gridSize
    local activeControls = self.activeControls
    local leftPadding = self.leftPadding
    local offset = self.offset


    local itemsPerRow = zo_floor((self.contentsWidth - leftPadding) / (controlWidth))
    -- local gridSpacing = ((self.contentsWidth - leftPadding) % itemsPerRow) / (itemsPerRow - 1)

    -- local itemsPerRow = zo_floor((self.contentsWidth - leftPadding) / (controlWidth))
    local numRows = zo_ceil((PLAYER_INVENTORY.inventories[self.bagId].numUsedSlots or 0) / itemsPerRow)
    local gridSpacing = ((self.contentsWidth - leftPadding) - (itemsPerRow * controlWidth)) / (itemsPerRow - 1)

    ResizeScrollBar(self, (numRows * controlHeight + gridSpacing * (numRows - 1)) - windowHeight)
    UpdateScrollFade(self.useFadeGradient, self.contents, self.scrollbar, offset)
    
    --remove active controls that are now hidden
    local i = 1
    local numActive = #activeControls
    while(i <= numActive) do
        local currentDataEntry = activeControls[i].dataEntry
        
        if(currentDataEntry.bottom < offset or currentDataEntry.top > offset + windowHeight) then
            FreeActiveScrollListControl(self, i)
            numActive = numActive - 1
        else
            i = i + 1
        end
        
        consideredMap[currentDataEntry] = true
    end
        
    --add revealed controls
    local firstInViewIndex = zo_floor(offset / controlHeight)+1
   
    local data = self.data
    local dataTypes = self.dataTypes
    local visibleData = self.visibleData
    local mode = self.mode
    
    local i = firstInViewIndex
    local visibleDataIndex = visibleData[i]
    local dataEntry = data[visibleDataIndex]
    local bottomEdge = offset + windowHeight
    
    local controlTop, controlLeft
    
    --removed isUniform check because we're assuming always uniform
    if(dataEntry) then
        controlTop, controlLeft = GetTopLeftTargetPosition(i, itemsPerRow, controlWidth, controlHeight, leftPadding, gridSpacing)
    end
    while(dataEntry and controlTop <= bottomEdge) do
        if(not consideredMap[dataEntry]) then
            local dataType = dataTypes[dataEntry.typeId]
            local controlPool = dataType.pool
            local control, key = controlPool:AcquireObject()
            
            control:SetHidden(false)
            control.dataEntry = dataEntry
            control.key = key
            --add grid table value
            control.isGrid = false
            if(dataType.setupCallback) then
                dataType.setupCallback(control, dataEntry.data, self)
            end
            table.insert(activeControls, control)
            consideredMap[dataEntry] = true
            
            if(AreDataEqualSelections(self, dataEntry.data, self.selectedData)) then
                SelectControl(self, control)
            end
            
            --even uniform active controls need to know their position to determine if they are still active

            dataEntry.top = controlTop
            dataEntry.bottom = controlTop + controlHeight
            dataEntry.left = controlLeft
            dataEntry.right = controlLeft + controlWidth
        end
        i = i + 1
        visibleDataIndex = visibleData[i]
        dataEntry = data[visibleDataIndex]
        --removed isUniform check because we're assuming always uniform
        if(dataEntry) then
            controlTop, controlLeft = GetTopLeftTargetPosition(i, itemsPerRow, controlWidth, controlHeight, leftPadding, gridSpacing)
        end
    end
    
    --update positions
    local contents = self.contents
    local numActive = #activeControls
    
    for i = 1, numActive do
        local currentControl = activeControls[i]
        local currentData = currentControl.dataEntry
        local controlOffset = currentData.top - offset
        local controlOffsetX = currentData.left

        currentControl:ClearAnchors()
        currentControl:SetAnchor(TOPLEFT, contents, TOPLEFT, controlOffsetX, controlOffset)
        --removed other anchor because this will no longer stretch across the contents pane
    end  
    
    --reset considered
    for k,v in pairs(consideredMap) do
        consideredMap[k] = nil
    end

    --reshape the slots to finish the illusion
    --this is done in the toggle function, but this ensures that any NEW slots get reshaped
    ReshapeSlots(self)
end

--interface to toggle grid view on and off
function InventoryGridView_ToggleGrid(self, toggle)
    self.isGrid = toggle
    self.forceUpdate = true
    ZO_ScrollList_ResetToTop(self)
    
    ReshapeSlots(self)
    while(#self.activeControls > 0) do
        FreeActiveScrollListControl(self, 1)
    end

    if(toggle) then
        UpdateScroll_Grid(self)
    else
        ZO_ScrollList_UpdateScroll(self)
        ResizeScrollBar(self, (#self.data * self.controlHeight) - ZO_ScrollList_GetHeight(self))
    end

    ZO_ScrollList_RefreshVisible(self)
    ReshapeSlots(self)
end

-- InventoryGridView_ToggleOutlines(ZO_PlayerInventoryBackpack, true)
function InventoryGridView_ToggleOutlines(self, toggle)
    self.isOutlines = toggle
    self.forceUpdate = self.isGrid

    --no need to update if current in list view
    if not self.forceUpdate then return end

    while(#self.activeControls > 0) do
        FreeActiveScrollListControl(self, 1)
    end

    if(self.isGrid) then
        UpdateScroll_Grid(self)
    else
        ZO_ScrollList_UpdateScroll(self)
    end

    ReshapeSlots(self)
end

function InventoryGridView_SetMinimumQuality(quality, forceUpdate)
    minimumQuality = quality
    ZO_PlayerInventoryBackpack.forceUpdate = forceUpdate or false
    ZO_PlayerBankBackpack.forceUpdate = forceUpdate or false
    ZO_GuildBankBackpack.forceUpdate = forceUpdate or false
    ReshapeSlots(ZO_PlayerInventoryBackpack)
    ReshapeSlots(ZO_PlayerBankBackpack)
    ReshapeSlots(ZO_GuildBankBackpack)
end

function InventoryGridView_SetTextureSet(textureSet, forceUpdate)
    TEXTURE_SET = textureSet
    ZO_PlayerInventoryBackpack.forceUpdate = forceUpdate or false
    ZO_PlayerBankBackpack.forceUpdate = forceUpdate or false
    ZO_GuildBankBackpack.forceUpdate = forceUpdate or false
    ReshapeSlots(ZO_PlayerInventoryBackpack)
    ReshapeSlots(ZO_PlayerBankBackpack)
    ReshapeSlots(ZO_GuildBankBackpack)
end

--hook function!  to be called before "ZO_ScrollList_UpdateScroll"
--thanks to Seerah for teaching me about this possibility
local function ScrollController(self)
    if(self.isGrid) then
        UpdateScroll_Grid(self)
        return true
    else
        return false
    end
end

--add necessary fields to the default UI's controls to facilitate the grid view
function InitGridView( isGrid )
    ZO_PreHook("ZO_ScrollList_UpdateScroll", ScrollController)

    for _,v in pairs(PLAYER_INVENTORY.inventories) do
        local listView = v.listView
        if listView and listView.dataTypes and listView.dataTypes[1] then
            local hookedFunctions = listView.dataTypes[1].setupCallback             
            
            listView.dataTypes[1].setupCallback = 
                function(rowControl, slot)                      
                    hookedFunctions(rowControl, slot)
                    rowControl.isGrid = isGrid
                end             
        end
    end
end