-- =============================================
-- Enforcer Tripwire Tool + Area System
-- =============================================

TOOL = TOOL or {}          -- Standard GMod stool setup
tools = tools or {}        -- Safety net for the original error

-- Tool info
TOOL.Category   = "Enforcer"
TOOL.Name       = "#tool.tripwiretool.name"
TOOL.Command    = nil
TOOL.ConfigName = ""

if CLIENT then
    language.Add("tool.tripwiretool.name", "Tripwire Tool")
    language.Add("tool.tripwiretool.desc", "Left click = select props | Right click = finalize | R = cancel | C = toggle Area Draw mode")
end

-- Variables
TOOL.SelectedProps = TOOL.SelectedProps or {}
TOOL.DrawingArea   = false
TOOL.AreaStart     = nil
TOOL.AreaEnd       = nil

-- ====================== CLIENT LOGIC ======================
if CLIENT then
    local CPressed = false

    function TOOL:Think()
        -- C key = toggle Area Draw mode
        if input.IsKeyDown(KEY_C) and not CPressed then
            CPressed = true
            self.DrawingArea = not self.DrawingArea
            chat.AddText(Color(0,255,255), "[Tripwires] Area Draw mode: " .. (self.DrawingArea and "ON" or "OFF"))
        elseif not input.IsKeyDown(KEY_C) then
            CPressed = false
        end

        -- R key = full reset
        if input.IsKeyDown(KEY_R) then
            self.SelectedProps = {}
            self.DrawingArea   = false
            self.AreaStart     = nil
            self.AreaEnd       = nil
            RunConsoleCommand("tripwire_editor")
        end
    end

    -- Cyan area preview while drawing
    hook.Add("PostDrawOpaqueRenderables", "TripwireAreaPreview", function()
        local ply = LocalPlayer()
        local wep = ply:GetActiveWeapon()
        if not IsValid(wep) or wep:GetClass() ~= "gmod_tool" then return end

        local tool = wep:GetToolObject()
        if not tool or tool.Mode ~= "tripwiretool" or not tool.DrawingArea or not tool.AreaStart then return end

        local endPos = tool.AreaEnd or ply:GetEyeTrace().HitPos
        local min = Vector(math.min(tool.AreaStart.x, endPos.x), math.min(tool.AreaStart.y, endPos.y), math.min(tool.AreaStart.z, endPos.z))
        local max = Vector(math.max(tool.AreaStart.x, endPos.x), math.max(tool.AreaStart.y, endPos.y), math.max(tool.AreaStart.z, endPos.z))

        render.DrawWireframeBox(Vector(0,0,0), Angle(0,0,0), min, max, Color(0,255,255,255), true)
        render.DrawBox(Vector(0,0,0), Angle(0,0,0), min, max, Color(0,255,255,20), true)
    end)
end

-- ====================== SHARED LOGIC ======================
function TOOL:LeftClick(tr)
    if self.DrawingArea then
        if not self.AreaStart then
            self.AreaStart = tr.HitPos
            chat.AddText(Color(0,255,255), "[Tripwires] Area start set — click again or right-click to finalize")
        else
            self.AreaEnd = tr.HitPos
        end
        return true
    end

    -- Normal prop selection
    if not IsValid(tr.Entity) or tr.Entity:IsPlayer() then return false end
    local ent = tr.Entity

    if table.HasValue(self.SelectedProps, ent) then
        table.RemoveByValue(self.SelectedProps, ent)
        chat.AddText(Color(255,100,100), "[Tripwires] Deselected prop")
    else
        table.insert(self.SelectedProps, ent)
        chat.AddText(Color(100,255,100), "[Tripwires] Selected prop (" .. #self.SelectedProps .. " total)")
    end
    return true
end

function TOOL:RightClick(tr)
    if self.DrawingArea and self.AreaStart then
        self.AreaEnd = tr.HitPos
        self:FinalizeArea()
        return true
    end

    if #self.SelectedProps == 0 then
        chat.AddText(Color(255,100,100), "[Tripwires] No props selected!")
        return false
    end

    chat.AddText(Color(0,255,255), "[Tripwires] Selection finalized – returning to editor...")
    self.SelectedProps = {}
    RunConsoleCommand("tripwire_editor")
    return true
end

function TOOL:FinalizeArea()
    if not self.AreaStart or not self.AreaEnd then return end

    Derma_StringRequest("Name this Area", "Enter a name for this area:", "myarea", function(name)
        local areaData = {
            name   = name,
            start  = self.AreaStart,
            endpos = self.AreaEnd,
            min    = Vector(math.min(self.AreaStart.x, self.AreaEnd.x), math.min(self.AreaStart.y, self.AreaEnd.y), math.min(self.AreaStart.z, self.AreaEnd.z)),
            max    = Vector(math.max(self.AreaStart.x, self.AreaEnd.x), math.max(self.AreaStart.y, self.AreaEnd.y), math.max(self.AreaStart.z, self.AreaEnd.z))
        }

        file.CreateDir("tripwires/areas")
        file.Write("tripwires/areas/" .. name .. ".json", util.TableToJSON(areaData, true))

        chat.AddText(Color(0,255,100), "[Tripwires] ✅ Saved area: " .. name)

        self.DrawingArea = false
        self.AreaStart   = nil
        self.AreaEnd     = nil
        RunConsoleCommand("tripwire_editor")
    end, nil, "Save Area", "Cancel")
end

-- ====================== REGISTER THE TOOL ======================
-- This runs after everything is loaded (fixes the original error)
hook.Add("Initialize", "Enforcer_TripwireTool_Register", function()
    tool.Register(TOOL, "tripwiretool")   -- ← correct function + order
    print("[Enforcer's Tripwire Events!] ✅ TRIPWIRE TOOL + AREA SYSTEM LOADED SUCCESSFULLY")
end)