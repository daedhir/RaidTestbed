local _G = _G

local RaidTestbed = LibStub("AceAddon-3.0"):NewAddon("RaidTestbed", "AceEvent-3.0")
_G.RaidTestbed = RaidTestbed

local RaidTestbedUtils = {}

-- Need table formatted like so:
--[[
local debuffs = {
   DebuffName = {
      Frame = true,
      Overlay = true,
      RCorner = false,
      LCorner = false,
      colorR = 0.5,
      colorG = 0.5,
      colorB = 0.5,
   },
]]--

local MyConsole = LibStub("AceConsole-3.0")

local getBuffOption, getDebuffOption, setBuffOption, setDebuffOption
do
   function getBuffOption(info)
      return nil
   end

   function getDebuffOption(info)
      return nil
   end

   function makeBuffOption(info, value)
      MyConsole:Print('SetBuffOption')
      MyConsole:Print(info)
      MyConsole:Print(value)
      if not RaidTestbed.db.char.buffs then
	 RaidTestbed.db.char.buffs = {}
      end
      RaidTestbed.db.char.buffs[value] = {
	 Frame = true,
	 Overlay = true,
	 colorR = 0.5,
	 colorG = 0.5,
	 colorB = 0.5,
	 colorAlph = 1,
      }
      local lastndx = RaidTestbed.db.char.lastndx
      RaidTestbed.db.char.lastndx = RaidTestbedUtils:CreateAura(value, lastndx)
      LibStub("AceConfigRegistry-3.0"):NotifyChange("RaidTestbed")
      MyConsole:Print(RaidTestbed.db.char.buffs[value].colorR)
   end

   function makeDebuffOption(info, value)
      MyConsole:Print('SetDebuffOption')
      MyConsole:Print(info)
      MyConsole:Print(value)
      if not RaidTestbed.db.char.buffs then
	 RaidTestbed.db.char.debuffs = {}
      end
      RaidTestbed.db.char.debuffs[value] = {
	 Frame = 1,
	 Overlay = 1,
	 colorR = 0.5,
	 colorG = 0.5,
	 colorB = 0.5,
	 colorAlph = 1,
      }
   end

   function setOpt(info, value)
      print(info[#info])
      local key = info[#info]
      RaidTestbed.db.char[key] = value
   end

   function getOpt(info)
      local key = info[#info]
      return RaidTestbed.db.char[key]
   end

   function setColor(info, ...)
      local key = info[#info]
      local r, g, b, a = ...
      RaidTestbed.db.char[key].r = r
      RaidTestbed.db.char[key].g = g
      RaidTestbed.db.char[key].b = b
      RaidTestbed.db.char[key].a = a
   end

   function getColor(info)
      local key = info[#info]
      local val = RaidTestbed.db.char[key]
      local r, g, b, a = val.r, val.g, val.b, val.a
      return r, g, b, a
   end
      
end


RaidTestbed.options = {
   type = "group",
   args = {
      global = {
	 type = "group",
	 name = "Global Settings",
	 order = 1,
	 args = {
	    __header1 = {
	       type = "description",
	       name = "Input buff/debuff name to add to frames",
	       order = 1,
	    },
	    makeBuff = {
	       name = "Input buff name",
	       type = "input",
	       desc = "Input a buff spell name to add an option group",
	       set = makeBuffOption,
	       get = getBuffOption,
	       multiline = false,
	       usage = "Arcane Brilliance",
	       order = 10,
	    },
	    makeDebuff = {
	       name = "Input debuff name",
	       type = "input",
	       desc = "Input a debuff spell name to add an option group",
	       set = makeDebuffOption,
	       get = getDebuffOption,
	       multiline = false,
	       usage = "Frost Blast",
	       --width = "half",
	       order = 15,
	    },
	 },	 
      },
      char = {
	 type = "group",
	 name = "Buffs and debuffs",
	 order = 5,
	 args = {
	 },
      },
   },
}

local defaults = {
   profile = {
      makeBuff = nil,
      makeDebuff = nil,
   },
}

function RaidTestbed:LoadAuras()
   local ndx = 1
   if not RaidTestbed.db.char.buffs then
      RaidTestbed.db.char.buffs = {}
   end
   local opt = RaidTestbed.options
   local ch = RaidTestbed.db.char
   for key, val in pairs(RaidTestbed.db.char.buffs) do
      ndx = RaidTestbedUtils:CreateAura(key, ndx)
   end
end

local frames = {}
RaidTestbed.frames = frames

function RaidTestbed:OnInitialize()
   MyConsole:Print("OnInit")
   self.db = LibStub("AceDB-3.0"):New("RaidTestbedDB", nil, true)
   self.db.RegisterCallback(self, "OnProfileChanged", "Refresh")
   self.db.RegisterCallback(self, "OnProfileCopied", "Refresh")
   self.db.RegisterCallback(self, "OnProfileReset", "Refresh")
   self.options.args.profiles = LibStub("AceDBOptions-3.0"):GetOptionsTable(self.db)
   self.options.args.profiles.order = 100
end

function RaidTestbed:OnEnable()
   print("OnEnable")
   LibStub("AceConfigRegistry-3.0"):RegisterOptionsTable("RaidTestbed",
							 self.options,
							 nil)
   local ACD = LibStub("AceConfigDialog-3.0")
   self.OptionsPanel = ACD:AddToBlizOptions(self.name, self.name, nil, "global")
   RaidTestbed:LoadAuras()
   self.OptionsPanel.Char = ACD:AddToBlizOptions(self.name, "Auras",
						 self.name, "char")
   self.OptionsPanel.Profiles = ACD:AddToBlizOptions(self.name, "Profiles",
						     self.name, "profiles")
   RaidTestbed:RegisterEvent("UNIT_AURA")

   local party_ = "party"
   local raid_ = "raid"
   for ndx = 1, 4 do
      local frame = RaidTestbedUtils:CreateExtender(party_..tostring(ndx))
      RaidTestbed.frames[raid_..ndx] = frame
   end
   for ndx = 1, 40 do
      local frame = RaidTestbedUtils:CreateExtender(raid_..tostring(ndx))
      RaidTestbed.frames[raid_..ndx] = frame
   end
end

function RaidTestbed:UNIT_AURA(unit)
   local frame = RaidTestbed.frames[unit]
   if not frame then return end

end

function RaidTestbed:Refresh()
   return nil
end

function RaidTestbedUtils:PartyType()
   local junk, instanceType = IsInInstance()
   if instanceType == "arena" then
      return instanceType
   end
   if instanceType == "pvp" then
      return "bg"
   end
   if GetNumRaidMembers > 0 then
      if instanceType == "none" and GetZonePVPInfo() == "combat" then
	 return "bg"
      end
      local diff = GetRaidDifficulty()
      if diff == 2 or diff == 4 then
	 return "heroicRaid"
      else
	 return "raid"
      end
   end
   if GetNumPartyMembers() > 0 then
      return "party"
   end
   return
end

function RaidTestbedUtils:CreateExtender(...)
   local unit = ...
   return unit
end

function RaidTestbedUtils:CreateAura(spell, ndx)
   local opt = RaidTestbed.options
   local ch = RaidTestbed.db.char
   local ndx_ = ndx
   opt.args.char.args[spell.."Title"] = {
      type = "description",
      name = spell,
      order = ndx_,
   }
   ndx_ = ndx_ + 1

   opt.args.char.args[spell.."Overlay"] = {
      name = "Overlay",
      type = "toggle",
      desc = "Show a colored frame overlay.",
      set = setOpt,
      get = getOpt,
      width = "half",
      order = ndx_,
   }
   ndx_ = ndx_ + 1
   if not ch[spell.."Overlay"] then
      ch[spell.."Overlay"] = ch.buffs[spell].Overlay
   end

   opt.args.char.args[spell.."Frame"] = {
      name = "Border",
      type = "toggle",
      desc = "Show a colored frame border.",
      set = setOpt,
      get = getOpt,
      width = "half",
      order = ndx_,
   }
   ndx_ = ndx_ + 1
   if not ch[spell.."Frame"] then
      ch[spell.."Frame"] = ch.buffs[spell].Frame
   end

   opt.args.char.args[spell.."Color"] = {
      name = "Color",
      type = "color",
      desc = "Color for all indicators for this aura.",
      hasAlpha = true,
      set = setColor,
      get = getColor,
      order = ndx_,
   }
   ndx_ = ndx_ + 1
   ch.lastndx = ndx_
   return ndx_

end
