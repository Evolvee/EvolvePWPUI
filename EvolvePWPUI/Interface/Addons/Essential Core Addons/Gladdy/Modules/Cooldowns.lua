local Gladdy = LibStub("Gladdy")
local L = Gladdy.L

local Cooldown = Gladdy:NewModule("Cooldown", nil, {
    cooldown = true,
	cooldownPos = "RIGHT",
	cooldownSize = 15,
})

function Cooldown:Test(unit)
		local button = Gladdy.buttons[unit]
		self.cooldownSpells = Gladdy:GetCooldownList()
		button.lastCooldownSpell = 1
		local class = "WARRIOR"
		local classLoc = L["Warrior"]
		for k,v in pairs(self.cooldownSpells[class]) do		
			local icon = button.spellCooldownFrame["icon" .. button.lastCooldownSpell]
			icon:Show()
			icon.spellId = k
			icon.texture:SetTexture(Gladdy.spellTextures[k])
			button.spellCooldownFrame["icon" .. button.lastCooldownSpell] = icon
			button.lastCooldownSpell = button.lastCooldownSpell + 1  
		end
end

local function option(params)
    local defaults = {
        get = function(info)
            local key = info.arg or info[#info]
            return Gladdy.dbi.profile[key]
        end,
        set = function(info, value)
            local key = info.arg or info[#info]
            -- hackfix to prevent DR/cooldown to be on the same side
            if( key == "cooldownPos" and value == "LEFT" ) then
              Gladdy.db.drCooldownPos = "RIGHT"
            elseif ( key == "cooldownPos" and value == "RIGHT" ) then
              Gladdy.db.drCooldownPos = "LEFT"
            end
            Gladdy.dbi.profile[key] = value
            Gladdy:UpdateFrame()
        end,
    }

    for k, v in pairs(params) do
        defaults[k] = v
    end

    return defaults
end

function Cooldown:GetOptions()
    return {
		cooldown = option({
            type = "toggle",
            name = L["Enable"],
            desc = L["Enabled cooldown module"],
            order = 4,
        }),
        cooldownSize = option({
            type = "range",
            name = L["Cooldown size"],
            desc = L["Size of each cd icon"],
            order = 5,
            min = 5,
            max = (Gladdy.db.healthBarHeight+Gladdy.db.castBarHeight+Gladdy.db.powerBarHeight+Gladdy.db.bottomMargin)/4,
        }),
		cooldownPos = option({
            type = "select",
            name = L["Position"],
            desc = L["Choose where cooldowns are displayed"],
            order = 6,
            values = {
                ["LEFT"] = L["Left"],
                ["RIGHT"] = L["Right"],
            },
        }),
    }
end

function Gladdy:GetCooldownList()
	return {
		-- Spell Name			   Cooldown[, Spec]
		-- Mage
		["MAGE"] = {
         [1953] 	= 15,    -- Blink
         --[122] 	= 25,    -- Frost Nova
         [2139] 	= 24,    -- Counterspell
         [45438] 	= 300,   -- Ice Block
         [12472] 	= { cd = 180, spec = L["Frost"], },    -- Icy Veins
         [31687] 	= { cd = 180, spec = L["Frost"], },    -- Summon Water Elemental    
         [12043] 	= { cd = 120, spec = L["Arcane"], },   -- Presence of Mind
         [11129] 	= { cd = 120, spec = L["Fire"] },      -- Combustion
		 [120] 	= { cd = 10,
					sharedCD = {
								   [31661] = true,         -- Cone of Cold
								},	spec = L["Fire"] },    -- Dragon's Breath
         [31661] 	= { cd = 20,
					sharedCD = {
								   [120] = true,       	   -- Cone of Cold
								},	spec = L["Fire"] },    -- Dragon's Breath
         [12042] 	= { cd = 120, spec = L["Arcane"], },   -- Arcane Power  
         [11958] 	= { cd = 480, spec = L["Frost"],       -- Coldsnap
            resetCD = { 
               [12472] = true, 
               [45438] = true, 
               [31687] = true,  
            }, 
         },        
      },
      		
		-- Priest
		["PRIEST"] = {
         [10890] 	= { cd = 27, [L["Shadow"]] = 23, },    -- Psychic Scream  
         [34433] 	= { cd = 300, [L["Shadow"]] = 180, },  -- Shadowfiend
         [15487] 	= { cd = 45, spec = L["Shadow"], },    -- Silence
         [10060] 	= { cd = 120, spec = L["Discipline"], }, -- Power Infusion
         [33206] 	= { cd = 180, spec = L["Discipline"], }, -- Pain Suppression
      },
		
		-- Druid
		["DRUID"] = {
         [22812] 	= 60,    -- Barkskin
         [29166] 	= 360,   -- Innervate
         [8983] 	= 60,    -- Bash
         [16689] 	= 60,    -- Natures Grasp
         [17116] 	= { cd = 120, spec = L["Restoration"], } , -- Natures Swiftness
         [33831] 	= { cd = 180, spec = L["Balance"], },  -- Force of Nature
      },
		
		-- Shaman
		["SHAMAN"] = {
		[8042] 	= { cd = 6,         -- Earth Shock
            sharedCD = {
               [8056] = true,       -- Frost Shock
               [8050] = true,       -- Flame Shock
            },
         },
         [30823] 	= { cd = 60, spec = L["Enhancement"], }, -- Shamanistic Rage
         [16166] 	= { cd = 180, spec = L["Elemental"], },  -- Elemental Mastery
         [16188] 	= { cd = 120, spec = L["Restoration"], }, -- Natures Swiftness		 
         [16190] 	= { cd = 300, spec = L["Restoration"], }, -- Mana Tide Totem             
      },
      
      -- Paladin
      ["PALADIN"] = {
         [10278] 	= 180,   -- Blessing of Protection
         [1044] 	= 25,    -- Blessing of Freedom 
         [10308] 	= { cd = 60, [L["Retribution"]] = 40, },   -- Hammer of Justice
         [642] 	= { cd = 300,                             -- Divine Shield
            sharedCD = {
               cd = 60,										-- no actual shared CD but debuff
               [31884] = true,
            },
         },
         [31884] 	= { cd = 180, spec = L["Retribution"],                  -- Avenging Wrath
            sharedCD = {
               cd = 60,
               [642] = true,
            },
         },         
         [20066] 	= { cd = 60, spec = L["Retribution"], },  -- Repentance
         [31842] 	= { cd = 180, spec = L["Holy"], },        -- Divine Illumination
         [31935] 	= { cd = 30, spec = L["Protection"], },   -- Avengers Shield
                                  
      }, 
      
      -- Warlock
      ["WARLOCK"] = {
         [17928] 	= 40,    -- Howl of Terror
         [27223] 	= 120,   -- Death Coil         
         --[19647] 	= { cd = 24 },	-- Spell Lock; how will I handle pet spells?      
         [30414] 	= { cd = 20, spec = L["Destruction"], },  -- Shadowfury               
         [17877] 	= { cd = 15, spec = L["Destruction"], },  -- Shadowburn               
         [18708] 	= { cd = 900, spec = L["Demonology"], },  -- Feldom            
      },  
      
      -- Warrior
      ["WARRIOR"] = {
         --[[6552] 	= { cd = 10,                              -- Pummel
            sharedCD = {
               [72] = true,
            },
         },
         [72] 	   = { cd = 12,                              -- Shield Bash
            sharedCD = {
               [6552] = true,
            },
         }, ]]        
         --[23920] 	= 10,    -- Spell Reflection
         [3411] 	= 30,    -- Intervene
         [676] 	= 60,    -- Disarm       
         [5246] 	= 120,   -- Intimidating Shout 
         --[2565] 	= 60,    -- Shield Block              
         [12292] 	= { cd = 180, spec = L["Arms"], },        -- Death Wish             
         [12975] 	= { cd = 180, },  -- Last Stand         
         [12809] 	= { cd = 30, spec = L["Protection"], },   -- Concussion Blow
         
      },
      
      -- Hunter
      ["HUNTER"] = {
         [19503] 	= 30,    -- Scatter Shot
		 [19263] 	= 300,    -- Deterrence; not on BM but can't do 2 specs
         [14311] 	= { cd = 30,                              -- Freezing Trap
            sharedCD = {
               [13809] = true,       -- Frost Trap
               [34600] = true,       -- Snake Trap
            },
         },
         [13809] 	= { cd = 30,                              -- Frost Trap
            sharedCD = {
               [14311] = true,       -- Freezing Trap
               [34600] = true,       -- Snake Trap
            },
         },
         [34600] 	= { cd = 30,                              -- Snake Trap
            sharedCD = {
               [14311] = true,       -- Freezing Trap
               [13809] = true,       -- Frost Trap
            },
         },
         [34490] 	= { cd = 20, spec = L["Marksmanship"], }, -- Silencing Shot
         [19386] 	= { cd = 60, spec = L["Survival"], },     -- Wyvern Sting       
         [19577] 	= { cd = 60, spec = L["Beast Mastery"],  }, -- Intimidation
         [38373] 	= { cd = 120, spec = L["Beast Mastery"], }, -- The Beast Within
      },
      
      -- Rogue
      ["ROGUE"] = {
         --[1766] 	= 10,    -- Kick
         --[8643] 	= 20,    -- Kidney Shot
         [26669] 	= { cd = 300, [L["Combat"]] = 180,},   -- Evasion
         [31224] 	= 60,    -- Cloak of Shadow
         [26889] 	= { cd = 300, [L["Subtlety"]] = 180,},   -- Vanish        
         [2094] 	= { cd = 180, [L["Subtlety"]] = 90,},    -- Blind
         --[11305] 	= 180,   -- Sprint
         [14177] 	= { cd = 180, spec = L["Assassination"], }, -- Cold Blood
         [13750] 	= { cd = 180, spec = L["Combat"], },      -- Adrenaline Rush
         [13877] 	= { cd = 120, spec = L["Combat"], },      -- Blade Flurry
         [36554] 	= { cd = 30, spec = L["Subtlety"], },     -- Shadowstep
         [14185] 	= { cd = 600, spec = L["Subtlety"],       -- Preparation
            resetCD = {
               [26669] = true,
               [11305] = true,
               [26889] = true,
               [14177] = true,
               [36554] = true,
            },
         },
      },
	["Scourge"] = {
		[7744] = 120, -- Will of the Forsaken
	},
	["BloodElf"] = {
		[28730] = 120, -- Arcane Torrent
	},
	["Tauren"] = {
		[20549] = 120, -- War Stomp
	},
	["Orc"] = {
		
	},
	["Troll"] = {
		
	},
	["NightElf"] = {
		[2651] = { cd = 180, spec = L["Discipline"], }, -- Elune's Grace
		[10797] = { cd = 30, spec = L["Discipline"], }, -- Star Shards
	},
	["Draenei"] = {
		[32548] = { cd = 300, spec = L["Discipline"], }, -- Hymn of Hope
	},
	["Human"] = {
		[13908] = { cd = 600, spec = L["Discipline"], }, -- Desperate Prayer
	},
	["Gnome"] = {
		[20589] = 105, -- Escape Artist
	},
	["Dwarf"] = {
		[20594] = 180, -- Stoneform
		[13908] = { cd = 600, spec = L["Discipline"], }, -- Desperate Prayer
	},		
	}
end