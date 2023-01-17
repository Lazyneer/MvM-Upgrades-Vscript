//Script written by Lazyneer

hasRecievedCash <- {}
deathStreak <- {}
for(local i = 1; i <= Constants.Server.MAX_PLAYERS; i++)
{
    hasRecievedCash[i] <- false
    deathStreak[i] <- 0
}

function OnGameEvent_teamplay_round_start(params)
{
    ForceEnableUpgrades(2)
    ClearUpgradeStations()
    ResetCanteens()

    //Use this function to spawn an upgrade station
    SpawnUpgradeSign(-1120, -1648, 368, 90, 112)
    SpawnUpgradeSign(816, -1888, 416, 0, 160)
    SpawnUpgradeStation(-1184, -4104, -192, 0)
    SpawnUpgradeStation(1184, 4104, -192, 180)
    SpawnUpgradeSign(-816, 1888, 416, 180, 160)
    SpawnUpgradeSign(1120, 1648, 368, 270, 112)
}

function OnGameEvent_teamplay_round_win(params)
{
    ResetPlayers()
}

function OnGameEvent_teamplay_restart_round(params)
{
    ResetPlayers()
}

function OnGameEvent_player_spawn(params)
{
    local client = GetPlayerFromUserID(params.userid)
    if(!hasRecievedCash[client.entindex()])
    {
        client.SetCurrency(500)
        client.GrantOrRemoveAllUpgrades(true, false)
        hasRecievedCash[client.entindex()] = true
    }

    if(deathStreak[client.entindex()] >= 3)
    {
        AddCurrency(client, 100)
        deathStreak[client.entindex()] = 0
    }
}

function OnGameEvent_player_disconnect(params)
{
    local client = GetPlayerFromUserID(params.userid)
    if(client.IsValid())
    {
        hasRecievedCash[client.entindex()] = false
        deathStreak[client.entindex()] = 0
    }
}

function ResetPlayers()
{
    for(local i = 1; i <= Constants.Server.MAX_PLAYERS; i++)
    {
        hasRecievedCash[i] = false
        deathStreak[i] = 0
    }
}

function ResetCanteens()
{
    local ent = null
    while(ent = Entities.FindByClassname(ent, "tf_powerup_bottle"))
    {
        NetProps.SetPropInt(ent, "m_usNumCharges", 0)
        NetProps.SetPropBool(ent, "m_bActive", false)
        ent.RemoveAttribute("critboost")
        ent.RemoveAttribute("ubercharge")
        ent.RemoveAttribute("building instant upgrade")
        ent.RemoveAttribute("refill_ammo")
        ent.RemoveAttribute("recall")
    }
}

function ClearUpgradeStations()
{
    local ent = null
    while(ent = Entities.FindByName(ent, "vscript_upgrade_station"))
    {
        ent.Kill()
    }
}

//Spawns a full upgrade station, only right angles allowed
function SpawnUpgradeStation(x, y, z, angle)
{
    local pos = Vector(x, y, z)
    local ang = Vector(0, angle, 0)

    SpawnEntityFromTable("prop_dynamic", 
    {
        targetname  = "vscript_upgrade_station",
        model       = "models/props_mvm/mvm_upgrade_center.mdl",
        origin      = pos,
        angles      = ang,
        disableshadows  = 1,
        solid       = 6
    })

    SpawnEntityFromTable("prop_dynamic", 
    {
        targetname  = "vscript_upgrade_station",
        model       = "models/props_mvm/mvm_upgrade_tools.mdl",
        origin      = pos,
        angles      = ang,
        disableshadows  = 1
    })

    local mins = Vector(-32, -128, -64)
    local maxs = Vector(32, 128, 64)

    pos.z += 64
    switch(ang.y)
    {
        case 0:
            pos.x += 96
            break
        case 90:
            pos.y += 96
            mins.x = mins.y
            mins.y = maxs.x * -1
            maxs.x = mins.x * -1
            maxs.y = mins.y * -1
            break
        case 180:
            pos.x -= 96
            break
        case 270:
            pos.y -= 96
            mins.x = mins.y
            mins.y = maxs.x * -1
            maxs.x = mins.x * -1
            maxs.y = mins.y * -1
            break
    }
    local brush = SpawnEntityFromTable("func_upgradestation", 
    {
        targetname  = "vscript_upgrade_station",
        origin      = pos
    })

    brush.KeyValueFromInt("solid", 2)
    brush.KeyValueFromString("mins", mins.x.tostring() + " " + mins.y.tostring() + " " + mins.z.tostring())
    brush.KeyValueFromString("maxs", maxs.x.tostring() + " " + maxs.y.tostring() + " " + maxs.z.tostring())
}

//Spawns a sign, works with any rotation
function SpawnUpgradeSign(x, y, z, angle, height = 128)
{
    local pos = Vector(x, y, z)
    local ang = Vector(0, angle, 0)
    local size = 32
    local offset = 32

    SpawnEntityFromTable("prop_dynamic", 
    {
        targetname  = "vscript_upgrade_station",
        model       = "models/props_mvm/mvm_upgrade_sign.mdl",
        origin      = pos,
        angles      = ang,
        disableshadows  = 1,
        solid       = 6,
        DefaultAnim = "idle"
    })

    local brush = SpawnEntityFromTable("func_upgradestation", 
    {
        targetname  = "vscript_upgrade_station",
        origin      = pos
    })

    local mins = Vector(size * -1, size * -1, height * -1)
    local maxs = Vector(size, size, 0)

    if(offset > 0)
    {
        local qAngle = QAngle(0, angle, 0)
        local foward = qAngle.Forward()
        foward *= offset
        mins += foward
        maxs += foward
    }

    brush.KeyValueFromInt("solid", 2)
    brush.KeyValueFromString("mins", mins.x.tostring() + " " + mins.y.tostring() + " " + mins.z.tostring())
    brush.KeyValueFromString("maxs", maxs.x.tostring() + " " + maxs.y.tostring() + " " + maxs.z.tostring())
}

function AddCurrency(client, cash)
{
    client.SetCurrency(client.GetCurrency() + cash)
}

function OnGameEvent_player_death(params)
{
    //Dead Ringer
    if(params.death_flags & 32)
        return

    local attacker = GetPlayerFromUserID(params.attacker)
    local assister = GetPlayerFromUserID(params.assister)
    local victim = GetPlayerFromUserID(params.userid)
    
    if(attacker != null)
    {
        if(attacker != victim && attacker.GetTeam() != victim.GetTeam())
        {
            AddCurrency(attacker, 100)
            deathStreak[attacker.entindex()] = 0
            deathStreak[victim.entindex()] += 1
        }
    }

    if(assister != null)
    {
        if(assister != victim && assister.GetTeam() != victim.GetTeam())
        {
            if(assister.GetPlayerClass() == Constants.ETFClass.TF_CLASS_MEDIC)
            {
                AddCurrency(assister, 100)
                deathStreak[assister.entindex()] = 0
            }
            else
                AddCurrency(assister, 50)
        }
    }
}

function OnGameEvent_teamplay_point_captured(params)
{
    for(local i = 1; i <= Constants.Server.MAX_PLAYERS; i++)
    {
        local client = PlayerInstanceFromIndex(i)
        if(client == null)
            continue

        //100 is added to the cappers without hooking this event
        //Cappers get 200, the rest of the team 100
        if(client.GetTeam() == params.team)
            AddCurrency(client, 100)
    }
}

function OnGameEvent_teamplay_flag_event(params)
{
    //Capture
    if(params.eventtype == 2)
    {
        local player = GetPlayerFromUserID(params.player)
        for(local i = 1; i <= Constants.Server.MAX_PLAYERS; i++)
        {
            local client = PlayerInstanceFromIndex(i)
            if(client == null)
                continue

            if(client == player)
                AddCurrency(client, 300)
            else if(client.GetTeam() == player.GetTeam())
                AddCurrency(client, 200)
        }
    }
}

__CollectGameEventCallbacks(this)