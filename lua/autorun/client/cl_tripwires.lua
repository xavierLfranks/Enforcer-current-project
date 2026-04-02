print("[Enforcer's Tripwire Events!] Client loaded – Area System + Dynamic Fields!")

local ActivePreviewAreas = {}

hook.Add("PostDrawOpaqueRenderables", "TripwireAreaPreview", function()
    for name, area in pairs(ActivePreviewAreas) do
        if area.min and area.max then
            render.DrawWireframeBox(Vector(0,0,0), Angle(0,0,0), area.min, area.max, Color(0,255,255,255), true)
            render.DrawBox(Vector(0,0,0), Angle(0,0,0), area.min, area.max, Color(0,255,255,20), true)
        end
    end
end)

-- ====================== DETAILED EDITOR (with fixes) ======================
local function OpenDetailedEditor(existingID)
    local editor = vgui.Create("DFrame")
    editor:SetTitle(existingID and "Edit Tripwire: " .. existingID or "Create New Tripwire")
    editor:SetSize(780, 760)
    editor:Center()
    editor:MakePopup()

    editor.Paint = function(self, w, h)
        draw.RoundedBox(8, 0, 0, w, h, Color(30,30,35,255))
        draw.RoundedBox(8, 2, 2, w-4, h-4, Color(45,45,55,255))
    end

    -- Tripwire ID
    local idLabel = vgui.Create("DLabel", editor)
    idLabel:SetPos(20, 30)
    idLabel:SetText("Tripwire ID (use this in MQS Run Console Command)")
    idLabel:SetTextColor(Color(255,255,255))
    local idEntry = vgui.Create("DTextEntry", editor)
    idEntry:SetPos(20, 55)
    idEntry:SetSize(300, 30)
    idEntry:SetText(existingID or "mytripwire")

    -- Trigger Prop (renamed from Attached)
    local propLabel = vgui.Create("DLabel", editor)
    propLabel:SetPos(20, 100)
    propLabel:SetText("Trigger Prop (optional)")
    local propEntry = vgui.Create("DTextEntry", editor)
    propEntry:SetPos(20, 125)
    propEntry:SetSize(300, 30)
    propEntry:SetText("Click button below to select...")

    local selectBtn = vgui.Create("DButton", editor)
    selectBtn:SetPos(340, 125)
    selectBtn:SetSize(200, 30)
    selectBtn:SetText("Select Prop with Toolgun")
    selectBtn.DoClick = function()
        editor:Close()
        RunConsoleCommand("gmod_tool", "tripwiretool")
    end

    -- Trigger Area (renamed)
    local areaLabel = vgui.Create("DLabel", editor)
    areaLabel:SetPos(20, 170)
    areaLabel:SetText("Trigger Area")
    local areaCombo = vgui.Create("DComboBox", editor)
    areaCombo:SetPos(20, 195)
    areaCombo:SetSize(300, 30)
    areaCombo:AddChoice("None (use prop only)")
    local files = file.Find("tripwires/areas/*.json", "DATA")
    for _, f in ipairs(files) do
        local name = string.StripExtension(f)
        areaCombo:AddChoice(name)
    end
    areaCombo:ChooseOptionID(1)

    -- Trigger
    local triggerLabel = vgui.Create("DLabel", editor)
    triggerLabel:SetPos(20, 240)
    triggerLabel:SetText("Trigger")
    local triggerCombo = vgui.Create("DComboBox", editor)
    triggerCombo:SetPos(20, 265)
    triggerCombo:SetSize(300, 30)
    triggerCombo:AddChoice("Player Enters Area")
    triggerCombo:AddChoice("Player Leaves Area")
    triggerCombo:AddChoice("Player Stays in Area")
    triggerCombo:AddChoice("Player Presses E on Prop")
    triggerCombo:AddChoice("Player First Spawn")
    triggerCombo:ChooseOptionID(1)

    -- Effect + Dynamic field panel
    local effectLabel = vgui.Create("DLabel", editor)
    effectLabel:SetPos(20, 310)
    effectLabel:SetText("Effect")
    local effectCombo = vgui.Create("DComboBox", editor)
    effectCombo:SetPos(20, 335)
    effectCombo:SetSize(300, 30)
    effectCombo:AddChoice("Run Console Command")
    effectCombo:AddChoice("Spawn Entity / NPC")
    effectCombo:AddChoice("Play Cutscene / Video")
    effectCombo:AddChoice("Play Audio")
    effectCombo:AddChoice("Kill Player / Party")
    effectCombo:AddChoice("Teleport Player / Party")
    effectCombo:AddChoice("Damage Player")
    effectCombo:AddChoice("Continue to Next MQS Objective")
    effectCombo:ChooseOptionID(1)

    -- Dynamic field panel (right side)
    local dynamicPanel = vgui.Create("DPanel", editor)
    dynamicPanel:SetPos(340, 310)
    dynamicPanel:SetSize(400, 300)
    dynamicPanel.Paint = function() end

    local commandEntry = nil

    local function UpdateDynamicFields()
        dynamicPanel:Clear()
        if effectCombo:GetSelected() == "Run Console Command" then
            local cmdLabel = vgui.Create("DLabel", dynamicPanel)
            cmdLabel:SetPos(0, 0)
            cmdLabel:SetText("Command to run:")
            local entry = vgui.Create("DTextEntry", dynamicPanel)
            entry:SetPos(0, 25)
            entry:SetSize(380, 30)
            entry:SetText("say Hello from tripwire!")
            commandEntry = entry
        end
    end

    effectCombo.OnSelect = UpdateDynamicFields
    timer.Simple(0.1, UpdateDynamicFields) -- initial update

    -- End Effect
    local endLabel = vgui.Create("DLabel", editor)
    endLabel:SetPos(20, 380)
    endLabel:SetText("End Effect")
    local endCombo = vgui.Create("DComboBox", editor)
    endCombo:SetPos(20, 405)
    endCombo:SetSize(300, 30)
    endCombo:AddChoice("Despawn Tripwire")
    endCombo:AddChoice("Renew (ready again)")
    endCombo:AddChoice("One-Time Use Only")
    endCombo:AddChoice("Cooldown (seconds)")
    endCombo:AddChoice("Permanent (stays forever)")
    endCombo:AddChoice("Chain Another Tripwire / Command")
    endCombo:ChooseOptionID(1)

    -- Save
    local saveBtn = vgui.Create("DButton", editor)
    saveBtn:SetPos(20, 460)
    saveBtn:SetSize(300, 40)
    saveBtn:SetText("SAVE TRIPWIRE")
    saveBtn.DoClick = function()
        local id = idEntry:GetText()
        local data = {
            id = id,
            prop = propEntry:GetText(),
            area = areaCombo:GetSelected(),
            trigger = triggerCombo:GetSelected(),
            effect = effectCombo:GetSelected(),
            endeffect = endCombo:GetSelected()
        }
        if commandEntry then
            data.command = commandEntry:GetText()
        end
        local json = util.TableToJSON(data, true)
        file.Write("tripwires/" .. id .. ".json", json)
        chat.AddText(Color(0,255,100), "[Tripwires] ✅ Saved tripwire: " .. id)
        editor:Close()
        RunConsoleCommand("tripwire_editor")
    end

    local closeBtn = vgui.Create("DButton", editor)
    closeBtn:SetPos(340, 460)
    closeBtn:SetSize(300, 40)
    closeBtn:SetText("Cancel")
    closeBtn.DoClick = function() editor:Close() end
end

-- ====================== MAIN MANAGER ======================
concommand.Add("tripwire_editor", function()
    local frame = vgui.Create("DFrame")
    frame:SetTitle("Enforcer's Tripwire Events!")
    frame:SetSize(900, 620)
    frame:Center()
    frame:MakePopup()
    frame:SetBackgroundBlur(true)

    frame.Paint = function(self, w, h)
        draw.RoundedBox(8, 0, 0, w, h, Color(30,30,35,255))
        draw.RoundedBox(8, 2, 2, w-4, h-4, Color(45,45,55,255))
    end

    local list = vgui.Create("DListView", frame)
    list:Dock(FILL)
    list:AddColumn("Tripwire ID")
    list:AddColumn("Prop")
    list:AddColumn("Area")
    list:AddColumn("Trigger")
    list:AddColumn("Effect")
    list:AddColumn("End Effect")

    local function RefreshList()
        list:Clear()
        local files = file.Find("tripwires/*.json", "DATA")
        for _, f in ipairs(files) do
            local id = string.StripExtension(f)
            list:AddLine(id, "—", "—", "—", "—", "—")
        end
    end

    RefreshList()

    local btnPanel = vgui.Create("DPanel", frame)
    btnPanel:Dock(BOTTOM)
    btnPanel:SetTall(50)
    btnPanel.Paint = function() end

    local createBtn = vgui.Create("DButton", btnPanel)
    createBtn:Dock(LEFT)
    createBtn:SetWide(200)
    createBtn:SetText("Create New Tripwire")
    createBtn.DoClick = function()
        OpenDetailedEditor(nil)
    end

    local manageAreasBtn = vgui.Create("DButton", btnPanel)
    manageAreasBtn:Dock(LEFT)
    manageAreasBtn:SetWide(200)
    manageAreasBtn:SetText("Manage Areas/Zones")
    manageAreasBtn.DoClick = OpenAreaManager

    local refreshBtn = vgui.Create("DButton", btnPanel)
    refreshBtn:Dock(LEFT)
    refreshBtn:SetWide(180)
    refreshBtn:SetText("Refresh List")
    refreshBtn.DoClick = RefreshList
end)

-- ====================== AREA MANAGEMENT ======================
function OpenAreaManager()
    local manager = vgui.Create("DFrame")
    manager:SetTitle("Manage Areas / Zones")
    manager:SetSize(800, 600)
    manager:Center()
    manager:MakePopup()

    manager.Paint = function(self, w, h)
        draw.RoundedBox(8, 0, 0, w, h, Color(30,30,35,255))
        draw.RoundedBox(8, 2, 2, w-4, h-4, Color(45,45,55,255))
    end

    local list = vgui.Create("DListView", manager)
    list:Dock(FILL)
    list:AddColumn("Area Name")
    list:AddColumn("Min")
    list:AddColumn("Max")

    local function RefreshAreas()
        list:Clear()
        local files = file.Find("tripwires/areas/*.json", "DATA")
        for _, f in ipairs(files) do
            local name = string.StripExtension(f)
            local data = util.JSONToTable(file.Read("tripwires/areas/" .. f, "DATA") or "{}")
            if data.min and data.max then
                list:AddLine(name, tostring(data.min), tostring(data.max))
            end
        end
    end

    RefreshAreas()

    list.OnRowRightClick = function(self, lineID, line)
        local name = line:GetColumnText(1)
        local menu = DermaMenu()
        menu:AddOption("Rename", function()
            Derma_StringRequest("Rename Area", "New name:", name, function(newName)
                file.Rename("tripwires/areas/" .. name .. ".json", "tripwires/areas/" .. newName .. ".json")
                RefreshAreas()
            end)
        end)
        menu:AddOption("Delete", function()
            Derma_Query("Delete area " .. name .. "?", "Confirm", "Yes", function()
                file.Delete("tripwires/areas/" .. name .. ".json")
                ActivePreviewAreas[name] = nil
                RefreshAreas()
            end, "No")
        end)
        menu:AddOption(ActivePreviewAreas[name] and "Stop Preview" or "Preview in World", function()
            if ActivePreviewAreas[name] then
                ActivePreviewAreas[name] = nil
            else
                local data = util.JSONToTable(file.Read("tripwires/areas/" .. name .. ".json", "DATA") or "{}")
                if data.min and data.max then
                    ActivePreviewAreas[name] = {min = data.min, max = data.max}
                end
            end
        end)
        menu:Open()
    end

    local closeBtn = vgui.Create("DButton", manager)
    closeBtn:Dock(BOTTOM)
    closeBtn:SetTall(40)
    closeBtn:SetText("Close")
    closeBtn.DoClick = function() manager:Close() end
end