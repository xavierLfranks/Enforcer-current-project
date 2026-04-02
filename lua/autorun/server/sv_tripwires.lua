EnforcerTripwires = EnforcerTripwires or {}
EnforcerTripwires.Tripwires = EnforcerTripwires.Tripwires or {}

file.CreateDir("tripwires")

util.AddNetworkString("EnforcerTripwire.Save")
util.AddNetworkString("EnforcerTripwire.Trigger")

print("[Enforcer's Tripwire Events!] Server loaded – fully standalone!")

-- Simple trigger command (for MQS "Run Console Command")
concommand.Add("tripwire_trigger", function(ply, cmd, args)
    local id = args[1]
    if EnforcerTripwires.Tripwires[id] then
        EnforcerTripwires.Tripwires[id]:Trigger(ply)
    else
        if IsValid(ply) then ply:ChatPrint("[Tripwires] Tripwire '"..(id or "none").."' not found!") end
    end
end)