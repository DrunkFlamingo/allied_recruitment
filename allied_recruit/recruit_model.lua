local Log = require("allied_recruit/log")
local RecruitOption = {}--# assume RecruitOption: RECRUIT_OPTION

--v function(unit_set: vector<string>, faction: string, condition: function(human_faction: string, other_faction: string) --> boolean, incident: string, cooldown: number) --> RECRUIT_OPTION
function RecruitOption.new(unit_set, faction, condition, incident, cooldown)
    local self ={};
    setmetatable(self, {
        __index = RecruitOption
    })--# assume self: RECRUIT_OPTION

    self.faction = faction;
    callback = function(context)
        local human_faction = context:character():faction():name()
        local other_faction = context:character():region():owning_faction():name()
        return ((not other_faction == human_faction) and condition(human_faction, other_faction));
    end --:function(context: WHATEVER) --> boolean

    self.condition = callback 
    self.incident = incident 
    self.faction = faction
    self.cached_cooldown = cooldown
    self.cooldown = 0 --:number
    self.unit_set = unit_set;

    return self;
end

--v function(self: RECRUIT_OPTION, context: WHATEVER) --> boolean
function RecruitOption.check_validity(self, context)
    return self.condition(context)
end;

--v function(self: RECRUIT_OPTION) --> boolean
function RecruitOption.off_cooldown(self) 
    return (self.cooldown == 0)
end

--v function(self: RECRUIT_OPTION) 
function RecruitOption.trigger(self)
    --# assume GLOBAL_SELECTED_CHAR: CA_CQI
    cm:trigger_incident(get_character_by_cqi(GLOBAL_SELECTED_CHAR):faction():name() , self.incident, true);
    for i = 1, #self.unit_set do
        cm:grant_unit_to_character(GLOBAL_SELECTED_CHAR, self.unit_set[i]);
    end
end

--v function(self: RECRUIT_OPTION)
function RecruitOption.activate(self)
    core:add_listener(
        self.faction.."_ally_recruit",
        "FactionTurnStart",
        function(context)
           return true; 
        end,
        function(context)
            local regions = context:faction():region_list();
            --# assume ally_recruit_master_table: map<string, RECRUIT_OPTION>
            if ally_recruit_master_table == nil then 
                ally_recruit_master_table = {};
            end;
            for i = 0, regions:num_items() - 1 do
                local r = regions:item_at(i);
                if not ally_recruit_master_table[r:name()] == self then 
                    ally_recruit_master_table[r:name()] = self;
                end
            end
        end,
        true);
                
end;






return {
    new = RecruitOption.new;
}