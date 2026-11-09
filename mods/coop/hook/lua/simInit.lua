local ReallyOnCreateArmyBrain = OnCreateArmyBrain
function OnCreateArmyBrain(index, brain, name, nickname)
    ReallyOnCreateArmyBrain(index, brain, name, nickname)

    -- Stuff this army into the HumanPlayers set, if applicable.
    if StringStartsWith(name, "Player") then
        ScenarioInfo.HumanPlayers[name] = index
    end
end

-- SetupSession loads the scenario data into a global. This is the One True Copy of scenario data.
-- This means that now is a really good time to fart about with scenario data.
local ReallySetupSession = SetupSession
function SetupSession()
    ReallySetupSession()

    ScenarioInfo.HumanPlayers = {}

    -- Erase alliances that refer to armies that we don't have players for.
    -- This shouldn't really be necessary, but things catch fire trying to create alliances to
    -- nonexistent armies otherwise.
    for k, army in Scenario.Armies do
        if army.Alliances then
            local newAlliances = {}
            for aName, aType in army.Alliances do
                if ScenarioInfo.ArmySetup[aName] then
                    newAlliances[aName] = aType
                end
            end
            army.Alliances = newAlliances
        end
    end
end

local ReallyBeginSession = BeginSession
function BeginSession()
    ReallyBeginSession()

    -- Hide scores for AI's and make them able to place orders outside the playable rect
    for i = 1, table.getn(ArmyBrains) do
        if not table.find(ScenarioInfo.HumanPlayers, i) then
            SetArmyShowScore(i, false)
            SetIgnorePlayableRect(i, true)
        end
    end
end

-- Mission scripts hard-code player army colors in OnStart (e.g.
-- `ScenarioFramework.SetUEFPlayerColor(Player1)`), which overwrites the color each
-- player picked in the lobby. The engine already applied the lobby colors when the
-- armies were created, so ignore script color changes for human player armies.
local ReallySetArmyColor = SetArmyColor
function SetArmyColor(army, r, g, b)
    local name = army
    if type(army) == 'number' then
        name = ArmyBrains[army] and ArmyBrains[army].Name
    end
    local setup = name and ScenarioInfo.ArmySetup and ScenarioInfo.ArmySetup[name]
    if setup and setup.Human then
        return
    end
    return ReallySetArmyColor(army, r, g, b)
end
