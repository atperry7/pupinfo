--[[

Copyright © 2019, Arrchie of Asura
All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:

    * Redistributions of source code must retain the above copyright
      notice, this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright
      notice, this list of conditions and the following disclaimer in the
      documentation and/or other materials provided with the distribution.
    * Neither the name of <addon name> nor the
      names of its contributors may be used to endorse or promote products
      derived from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL <your name> BE LIABLE FOR ANY
DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
(INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

]]
require("tables")
require "utility"
local files = require("files")
local packets = require("packets")
local res = require("resources")
local player = windower.ffxi.get_player()

_addon.name = "pupinfo"
_addon.author = "Arrchie"
_addon.version = "1.0.0"
_addon.command = "pupinfo"
-- _addon.commands = {'some', 'extra', 'commands',}

--[[
    Attempting to achieve
    - Watch puppet debuffs
    - Monitor puppet damage
    - Monitor puppet stats
]]
local puppet_debuffs = {}
local puppet_stats = {}
local puppet_dmg = {}

local categories = {
    [01] = "Melee attack",
    [02] = "Finish ranged attack",
    [03] = "Finish weapon skill",
    [04] = "Finish spell casting",
    [05] = "Finish item use",
    [06] = "Use job ability",
    [07] = "Begin weapon skill or TP move",
    [08] = "Begin spell casting or interrupt casting",
    [09] = "Begin item use or interrupt usage",
    [10] = "Unknown",
    [11] = "Finish TP move",
    [12] = "Begin ranged attack",
    [13] = "Pet completes ability/WS",
    [14] = "Unblinkable job ability",
    [15] = "Some RUN job abilities"
}

windower.register_event(
    "load",
    function()
        local filename = "pupinfo_debug_" .. os.date("%m_%d_%y") .. ".log"

        --Open the file to write to -- this can only append to the file nothing else
        debug_file = io.open(windower.addon_path .. "data/" .. filename, "a")

        --Set the output
        io.output(debug_file)
    end
)

windower.register_event(
    "incoming chunk",
    function(id, original, modified, injected, blocked)
        local pet = windower.ffxi.get_mob_by_target("pet")

        if not player or not pet or injected then
            return
        end

        local parsedInfo = packets.parse("incoming", original)

        if not parsedInfo then
            return
        end

        if id == 0x44 then
            if parsedInfo["Current HP"] and parsedInfo["Current MP"] then
                debug("Puppet HP: " .. tostring(parsedInfo["Current HP"]) .. " / " .. tostring(parsedInfo["Max HP"]))
                debug("Puppet MP: " .. tostring(parsedInfo["Current MP"]) .. " / " .. tostring(parsedInfo["Max MP"]))
            end

        elseif id == 0x67 or id == 0x068 then
            --
            --[[
                Pet TP seems to come across only once when its updating (gained or lost)
                General updates that come through will not hold the current TP value
            ]]
            if parsedInfo["Pet TP"] > 0 and parsedInfo["Message Type"] == 4 then
                debug("Puppet TP: " .. tostring(parsedInfo["Pet TP"]))

            end
        elseif id == 0x119 then
            debug("Ability Recasts [Ignored for Now]")
        end

        io.flush()
    end
)

windower.register_event('action', function(act)
    local pet = windower.ffxi.get_mob_by_target("pet")

    if not player or not pet then
        return
    end

    --Pet Performing Actions
    if act.actor_id == pet.id then

        --Check through all targets that are affected by an action
        for _, target in pairs(act.targets) do
            local mob_found = windower.ffxi.get_mob_by_id(target.id)

            if mob_found then
                debug("Action Performed by Puppet: " .. res.monster_abilities[act.param].en .. " : Damage [" .. tostring(target.param) .. "]")
            end
        end

    else
        --Check through all targets that are affected by an action
        for _, target in pairs(act.targets) do
            
            if target.id == pet.id then
                debug("Action against Puppet: " .. categories[act.category] .. " ")
            end

        end
    end

    io.flush()
end)

windower.register_event(
    "unload",
    function()
        --Make sure we close the file once done
        io.close(debug_file)
    end
)

function debug(message)
    --Write to that output
    io.write("[" .. os.date() .. "] - Debug - " .. message .. "\n")
end
