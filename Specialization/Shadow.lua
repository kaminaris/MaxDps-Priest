local _, addonTable = ...
local Priest = addonTable.Priest
local MaxDps = _G.MaxDps
if not MaxDps then return end
local LibStub = LibStub
local setSpell

local ceil = ceil
local floor = floor
local fmod = fmod
local format = format
local max = max
local min = min
local pairs = pairs
local select = select
local strsplit = strsplit
local GetTime = GetTime

local UnitAffectingCombat = UnitAffectingCombat
local UnitCastingInfo = UnitCastingInfo
local UnitChannelInfo = UnitChannelInfo
local UnitClass = UnitClass
local UnitExists = UnitExists
local UnitGUID = UnitGUID
local UnitName = UnitName
local UnitSpellHaste = UnitSpellHaste
local UnitThreatSituation = UnitThreatSituation
local UnitPower = UnitPower
local UnitHealth = UnitHealth
local UnitAura = C_UnitAuras.GetAuraDataByIndex
local UnitAuraByName = C_UnitAuras.GetAuraDataBySpellName
local UnitHealthMax = UnitHealthMax
local UnitPowerMax = UnitPowerMax
local SpellHaste
local SpellCrit
local GetSpellInfo = C_Spell.GetSpellInfo
local GetSpellCooldown = C_Spell.GetSpellCooldown
local GetSpellCastCount = C_Spell.GetSpellCastCount
local GetUnitSpeed = GetUnitSpeed
local GetCritChance = GetCritChance
local GetInventoryItemLink = GetInventoryItemLink
local GetItemInfo = C_Item.GetItemInfo
local GetItemSpell = C_Item.GetItemSpell
local GetNamePlates = C_NamePlate.GetNamePlates and C_NamePlate.GetNamePlates or GetNamePlates
local GetPowerRegenForPowerType = GetPowerRegenForPowerType
local GetSpellName = C_Spell and C_Spell.GetSpellName and C_Spell.GetSpellName or GetSpellInfo
local GetTotemInfo = GetTotemInfo
local IsStealthed = IsStealthed
local IsCurrentSpell = C_Spell and C_Spell.IsCurrentSpell
local CombatLogGetCurrentEventInfo = CombatLogGetCurrentEventInfo

local ManaPT = Enum.PowerType.Mana
local RagePT = Enum.PowerType.Rage
local FocusPT = Enum.PowerType.Focus
local EnergyPT = Enum.PowerType.Energy
local ComboPointsPT = Enum.PowerType.ComboPoints
local RunesPT = Enum.PowerType.Runes
local RunicPowerPT = Enum.PowerType.RunicPower
local SoulShardsPT = Enum.PowerType.SoulShards
local DemonicFuryPT = Enum.PowerType.DemonicFury
local BurningEmbersPT = Enum.PowerType.BurningEmbers
local LunarPowerPT = Enum.PowerType.LunarPower
local HolyPowerPT = Enum.PowerType.HolyPower
local MaelstromPT = Enum.PowerType.Maelstrom
local ChiPT = Enum.PowerType.Chi
local InsanityPT = Enum.PowerType.Insanity
local ArcaneChargesPT = Enum.PowerType.ArcaneCharges
local FuryPT = Enum.PowerType.Fury
local PainPT = Enum.PowerType.Pain
local EssencePT = Enum.PowerType.Essence
local RuneBloodPT = Enum.PowerType.RuneBlood
local RuneFrostPT = Enum.PowerType.RuneFrost
local RuneUnholyPT = Enum.PowerType.RuneUnholy

local fd
local ttd
local timeShift
local gcd
local cooldown
local buff
local debuff
local talents
local targets
local targetHP
local targetmaxHP
local targethealthPerc
local curentHP
local maxHP
local healthPerc
local timeInCombat
local className, classFilename, classId = UnitClass('player')
local classtable
local LibRangeCheck = LibStub('LibRangeCheck-3.0', true)

local Mana
local ManaMax
local ManaDeficit
local ManaPerc
local ManaRegen
local ManaRegenCombined
local ManaTimeToMax
local Insanity
local InsanityMax
local InsanityDeficit
local InsanityPerc
local InsanityRegen
local InsanityRegenCombined
local InsanityTimeToMax

local Shadow = {}

local trinket_1_buffs = false
local trinket_2_buffs = false
local dr_force_prio = 1
local me_force_prio = 1
local max_vts = 12
local is_vt_possible = false
local pooling_mindblasts = 0
local holding_crash = false
local pool_for_cds = false
local dots_up = false
local manual_vts_applied = false


local function GetTotemInfoByName(name)
    local info = {
        duration = 0,
        remains = 0,
        up = false,
    }
    for index=1,MAX_TOTEMS do
        local arg1, totemName, startTime, duration, icon = GetTotemInfo(index)
        local remains = math.floor(startTime+duration-GetTime())
        if (totemName == name ) then
            info.duration = duration
            info.up = true
            info.remains = remains
            break
        end
    end
    return info
end

local function GetTotemInfoById(sSpellID)
    local info = {
        duration = 0,
        remains = 0,
        up = false,
    }
    for index=1,MAX_TOTEMS do
        local arg1, totemName, startTime, duration, icon, modRate, spellID = GetTotemInfo(index)
        local sName = sSpellID and GetSpellInfo(sSpellID).name or ''
        local remains = math.floor(startTime+duration-GetTime())
        if (spellID == sSpellID) or (totemName == sName ) then
            info.duration = duration
            info.up = true
            info.remains = remains
            break
        end
    end
    return info
end

local function GetTotemTypeActive(i)
   local arg1, totemName, startTime, duration, icon = GetTotemInfo(i)
   return duration > 0
end


function Shadow:precombat()
    if (MaxDps:CheckSpellUsable(classtable.PowerWordFortitude, 'PowerWordFortitude')) and (not buff[classtable.PowerWordFortitude].up) and cooldown[classtable.PowerWordFortitude].ready and not UnitAffectingCombat('player') then
        if not setSpell then setSpell = classtable.PowerWordFortitude end
    end
    if (MaxDps:CheckSpellUsable(classtable.Shadowform, 'Shadowform')) and (not buff[classtable.ShadowformBuff].up) and cooldown[classtable.Shadowform].ready and not UnitAffectingCombat('player') then
        if not setSpell then setSpell = classtable.Shadowform end
    end
    trinket_1_buffs = (MaxDps:HasBuffEffect('13', 'intellect') or MaxDps:HasBuffEffect('13', 'mastery') or MaxDps:HasBuffEffect('13', 'versatility') or MaxDps:HasBuffEffect('13', 'haste') or MaxDps:HasBuffEffect('13', 'crit') or MaxDps:CheckTrinketNames('SignetofthePriory')) and (MaxDps:CheckTrinketCooldownDuration('13') >= 20)
    trinket_2_buffs = (MaxDps:HasBuffEffect('14', 'intellect') or MaxDps:HasBuffEffect('14', 'mastery') or MaxDps:HasBuffEffect('14', 'versatility') or MaxDps:HasBuffEffect('14', 'haste') or MaxDps:HasBuffEffect('14', 'crit') or MaxDps:CheckTrinketNames('SignetofthePriory')) and (MaxDps:CheckTrinketCooldownDuration('14') >= 20)
    dr_force_prio = 1
    me_force_prio = 1
    max_vts = 12
    is_vt_possible = false
    pooling_mindblasts = 0
    if (MaxDps:CheckSpellUsable(classtable.Halo, 'Halo')) and (MaxDps:boss() and targets <= 4 and (ttd >= 120 or targets <= 2) and not talents[classtable.PowerSurge]) and cooldown[classtable.Halo].ready and not UnitAffectingCombat('player') then
        MaxDps:GlowCooldown(classtable.Halo, cooldown[classtable.Halo].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.ShadowCrash, 'ShadowCrash') and talents[classtable.ShadowCrash]) and (targets <= 12) and cooldown[classtable.ShadowCrash].ready and not UnitAffectingCombat('player') then
        if not setSpell then setSpell = classtable.ShadowCrash end
    end
    if (MaxDps:CheckSpellUsable(classtable.VampiricTouch, 'VampiricTouch')) and ((not talents[classtable.WhisperingShadows] or not (MaxDps.spellHistory[1] == classtable.ShadowCrash)) and (not (talents[classtable.ShadowCrash] and true or false) or targets >12 or not MaxDps:boss())) and cooldown[classtable.VampiricTouch].ready and not UnitAffectingCombat('player') then
        if not setSpell then setSpell = classtable.VampiricTouch end
    end
end
function Shadow:aoe()
    Shadow:aoe_variables()
    if (MaxDps:CheckSpellUsable(classtable.VampiricTouch, 'VampiricTouch')) and ((max_vts >0 and not manual_vts_applied and not (MaxDps.spellHistory[1] == classtable.ShadowCrash)) and not buff[classtable.EntropicRiftBuff].up) and cooldown[classtable.VampiricTouch].ready then
        if not setSpell then setSpell = classtable.VampiricTouch end
    end
    if (MaxDps:CheckSpellUsable(classtable.ShadowCrash, 'ShadowCrash') and talents[classtable.ShadowCrash]) and (not holding_crash) and cooldown[classtable.ShadowCrash].ready then
        if not setSpell then setSpell = classtable.ShadowCrash end
    end
end
function Shadow:aoe_variables()
    max_vts = math.max(targets , 12)
    is_vt_possible = false
    if ttd >= 18 then
        is_vt_possible = true
    end
    dots_up = (MaxDps:DebuffCounter(classtable.VampiricTouchDeBuff) + 8*(((MaxDps.spellHistory[1] == classtable.ShadowCrash) and IsSpellKnownOrOverridesKnown(classtable.ShadowCrash)) and 1 or 0))>=max_vts or not is_vt_possible
    if holding_crash and IsSpellKnownOrOverridesKnown(classtable.ShadowCrash) and (targets >1) then
        holding_crash = (max_vts - MaxDps:DebuffCounter(classtable.VampiricTouchDeBuff))<4 and math.huge >15 or math.huge <10 and targets>(max_vts - MaxDps:DebuffCounter(classtable.VampiricTouchDeBuff))
    end
    manual_vts_applied = (MaxDps:DebuffCounter(classtable.VampiricTouchDeBuff) + 8*(holding_crash and 0 or 1))>=max_vts or not is_vt_possible
end
function Shadow:cds()
    if (MaxDps:CheckSpellUsable(classtable.PowerInfusion, 'PowerInfusion')) and ((buff[classtable.VoidformBuff].up or buff[classtable.DarkAscensionBuff].up and (ttd <= 80 or ttd >= 140)) and (not buff[classtable.PowerInfusionBuff].up or (MaxDps.tier and MaxDps.tier[33].count >= 4) and buff[classtable.PowerInfusionBuff].remains <= 15)) and cooldown[classtable.PowerInfusion].ready then
        MaxDps:GlowCooldown(classtable.PowerInfusion, cooldown[classtable.PowerInfusion].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.Halo, 'Halo')) and (talents[classtable.PowerSurge] and (( UnitExists('pet') and UnitName('pet')  == 'Fiend' ) and cooldown[classtable.Fiend].remains >= 4 and talents[classtable.Mindbender] or not talents[classtable.Mindbender] and not cooldown[classtable.Fiend].ready or targets >2 and not talents[classtable.InescapableTorment] or not talents[classtable.DarkAscension]) and (cooldown[classtable.MindBlast].charges == 0 or not cooldown[classtable.VoidTorrent].ready or not talents[classtable.VoidEruption] or cooldown[classtable.VoidEruption].remains >= gcd*4 or buff[classtable.MindDevourerBuff].up and talents[classtable.MindDevourer])) and cooldown[classtable.Halo].ready then
        MaxDps:GlowCooldown(classtable.Halo, cooldown[classtable.Halo].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.VoidEruption, 'VoidEruption') and talents[classtable.VoidEruption]) and ((( UnitExists('pet') and UnitName('pet')  == 'Fiend' ) and cooldown[classtable.Fiend].remains >= 4 or not talents[classtable.Mindbender] and not cooldown[classtable.Fiend].ready or targets >2 and not talents[classtable.InescapableTorment]) and (cooldown[classtable.MindBlast].charges == 0 or timeInCombat >15 or buff[classtable.MindDevourerBuff].up and talents[classtable.MindDevourer] or buff[classtable.PowerSurgeBuff].up)) and cooldown[classtable.VoidEruption].ready then
        MaxDps:GlowCooldown(classtable.VoidEruption, cooldown[classtable.VoidEruption].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.DarkAscension, 'DarkAscension') and talents[classtable.DarkAscension]) and ((( UnitExists('pet') and UnitName('pet')  == 'Fiend' ) and cooldown[classtable.Fiend].remains >= 4 or not talents[classtable.Mindbender] and not cooldown[classtable.Fiend].ready or targets >2 and not talents[classtable.InescapableTorment]) and (MaxDps:DebuffCounter(classtable.DevouringPlagueDeBuff) >= 1 or Insanity>=(20-(5 * (talents[classtable.MindsEye] and talents[classtable.MindsEye] or 0))+(5 * (talents[classtable.DistortedReality] and talents[classtable.DistortedReality] or 0))-(( UnitExists('pet') and UnitName('pet')  == 'Fiend' and 1 or 0) * 2)))) and cooldown[classtable.DarkAscension].ready then
        if not setSpell then setSpell = classtable.DarkAscension end
    end
    Shadow:trinkets()
    if (MaxDps:CheckSpellUsable(classtable.DesperatePrayer, 'DesperatePrayer')) and (healthPerc <= 75) and cooldown[classtable.DesperatePrayer].ready then
        MaxDps:GlowCooldown(classtable.DesperatePrayer, cooldown[classtable.DesperatePrayer].ready)
    end
end
function Shadow:heal_for_tof()
    if (MaxDps:CheckSpellUsable(classtable.Halo, 'Halo')) and cooldown[classtable.Halo].ready then
        MaxDps:GlowCooldown(classtable.Halo, cooldown[classtable.Halo].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.DivineStar, 'DivineStar')) and cooldown[classtable.DivineStar].ready then
        if not setSpell then setSpell = classtable.DivineStar end
    end
    if (MaxDps:CheckSpellUsable(classtable.HolyNova, 'HolyNova')) and (buff[classtable.RhapsodyBuff].count == 20 and talents[classtable.Rhapsody]) and cooldown[classtable.HolyNova].ready then
        if not setSpell then setSpell = classtable.HolyNova end
    end
end
function Shadow:main()
    if targets <3 then
        dots_up = MaxDps:DebuffCounter(classtable.VampiricTouchDeBuff) == targets or (MaxDps.spellHistory[1] == classtable.ShadowCrash)
    end
    if ((MaxDps:GetPartyState() == 'raid') and MaxDps:boss() and ttd <30 or ttd >15 and (not holding_crash or targets >2)) then
        Shadow:cds()
    end
    if (MaxDps:CheckSpellUsable(classtable.Mindbender, 'Mindbender') and talents[classtable.Mindbender]) and ((debuff[classtable.ShadowWordPainDeBuff].up and dots_up or (MaxDps.spellHistory[1] == classtable.ShadowCrash)) and (not cooldown[classtable.Halo].ready or not (talents[classtable.PowerSurge] and true or false)) and ((MaxDps:GetPartyState() == 'raid') and MaxDps:boss() and ttd <30 or ttd >15) and (not talents[classtable.DarkAscension] or cooldown[classtable.DarkAscension].remains <gcd or (MaxDps:GetPartyState() == 'raid') and MaxDps:boss() and ttd <15)) and cooldown[classtable.Mindbender].ready then
        if not setSpell then setSpell = classtable.Mindbender end
    end
    if (MaxDps:CheckSpellUsable(classtable.ShadowWordDeath, 'ShadowWordDeath')) and (false and talents[classtable.DevourMatter]) and cooldown[classtable.ShadowWordDeath].ready then
        if not setSpell then setSpell = classtable.ShadowWordDeath end
    end
    if (MaxDps:CheckSpellUsable(classtable.VoidBlast, 'VoidBlast') and talents[classtable.VoidBlast]) and ((debuff[classtable.DevouringPlagueDeBuff].remains >= timeShift or buff[classtable.EntropicRiftBuff].remains <= gcd or (UnitChannelInfo('player') and select(8,UnitChannelInfo('player')) == classtable.VoidTorrent) and talents[classtable.VoidEmpowerment]) and (InsanityDeficit >= 16 or cooldown[classtable.MindBlast].fullRecharge <= gcd or buff[classtable.EntropicRiftBuff].remains <= gcd)) and cooldown[classtable.VoidBlast].ready then
        if not setSpell then setSpell = classtable.VoidBlast end
    end
    if (MaxDps:CheckSpellUsable(classtable.DevouringPlague, 'DevouringPlague')) and (buff[classtable.VoidformBuff].up and talents[classtable.PerfectedForm] and buff[classtable.VoidformBuff].remains <= gcd and talents[classtable.VoidEruption]) and cooldown[classtable.DevouringPlague].ready then
        if not setSpell then setSpell = classtable.DevouringPlague end
    end
    if (MaxDps:CheckSpellUsable(classtable.VoidBolt, 'VoidBolt')) and (InsanityDeficit >16 and cooldown[classtable.VoidBolt].remains%gcd <= 0.1) and cooldown[classtable.VoidBolt].ready then
        if not setSpell then setSpell = classtable.VoidBolt end
    end
    if (MaxDps:CheckSpellUsable(classtable.DevouringPlague, 'DevouringPlague')) and (MaxDps:DebuffCounter(classtable.DevouringPlagueDeBuff) <= 1 and debuff[classtable.DevouringPlagueDeBuff].remains <= gcd and (not talents[classtable.VoidEruption] or cooldown[classtable.VoidEruption].remains >= gcd*3) or InsanityDeficit <= 35 or buff[classtable.MindDevourerBuff].up or buff[classtable.EntropicRiftBuff].up or buff[classtable.PowerSurgeBuff].up and buff[classtable.Tww3Archon4pcHelperBuff].count <4 and buff[classtable.AscensionBuff].up) and cooldown[classtable.DevouringPlague].ready then
        if not setSpell then setSpell = classtable.DevouringPlague end
    end
    if (MaxDps:CheckSpellUsable(classtable.VoidTorrent, 'VoidTorrent')) and (not holding_crash and (debuff[classtable.DevouringPlagueDeBuff].remains >= 2.5 and (cooldown[classtable.DarkAscension].remains >= 12 or not talents[classtable.DarkAscension] or not talents[classtable.VoidBlast]) or cooldown[classtable.VoidEruption].remains <= 3 and talents[classtable.VoidEruption])) and cooldown[classtable.VoidTorrent].ready then
        if not setSpell then setSpell = classtable.VoidTorrent end
    end
    if (MaxDps:CheckSpellUsable(classtable.VoidVolley, 'VoidVolley')) and (buff[classtable.VoidVolleyBuff].remains <= 5 or buff[classtable.EntropicRiftBuff].up and cooldown[classtable.VoidBlast].remains >buff[classtable.EntropicRiftBuff].remains or ttd <= 5) and cooldown[classtable.VoidVolley].ready then
        if not setSpell then setSpell = classtable.VoidVolley end
    end
    if (MaxDps:CheckSpellUsable(classtable.MindFlay, 'MindFlay')) and (buff[classtable.MindFlayInsanityBuff].up) and cooldown[classtable.MindFlay].ready then
        if not setSpell then setSpell = classtable.MindFlay end
    end
    if (MaxDps:CheckSpellUsable(classtable.ShadowCrash, 'ShadowCrash') and talents[classtable.ShadowCrash]) and (not holding_crash and not (MaxDps.spellHistory[1] == classtable.ShadowCrash)) and cooldown[classtable.ShadowCrash].ready then
        if not setSpell then setSpell = classtable.ShadowCrash end
    end
    if (MaxDps:CheckSpellUsable(classtable.VampiricTouch, 'VampiricTouch')) and (debuff[classtable.VampiricTouchDeBuff].refreshable and ttd >12 and (debuff[classtable.VampiricTouchDeBuff].up or not dots_up) and (max_vts >0 or targets == 1) and (cooldown[classtable.ShadowCrash].remains >= debuff[classtable.VampiricTouchDeBuff].remains or holding_crash or not IsSpellKnownOrOverridesKnown(classtable.ShadowCrash)) and (not (MaxDps.spellHistory[1] == classtable.ShadowCrash))) and cooldown[classtable.VampiricTouch].ready then
        if not setSpell then setSpell = classtable.VampiricTouch end
    end
    if (MaxDps:CheckSpellUsable(classtable.MindBlast, 'MindBlast')) and ((not buff[classtable.MindDevourerBuff].up or not talents[classtable.MindDevourer] or cooldown[classtable.VoidEruption].ready and talents[classtable.VoidEruption])) and cooldown[classtable.MindBlast].ready then
        if not setSpell then setSpell = classtable.MindBlast end
    end
    if (MaxDps:CheckSpellUsable(classtable.VoidVolley, 'VoidVolley')) and cooldown[classtable.VoidVolley].ready then
        if not setSpell then setSpell = classtable.VoidVolley end
    end
    if (MaxDps:CheckSpellUsable(classtable.DevouringPlague, 'DevouringPlague')) and (buff[classtable.VoidformBuff].up and talents[classtable.VoidEruption] or buff[classtable.PowerSurgeBuff].up or talents[classtable.DistortedReality]) and cooldown[classtable.DevouringPlague].ready then
        if not setSpell then setSpell = classtable.DevouringPlague end
    end
    if (MaxDps:CheckSpellUsable(classtable.Halo, 'Halo')) and (targets >1) and cooldown[classtable.Halo].ready then
        MaxDps:GlowCooldown(classtable.Halo, cooldown[classtable.Halo].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.ShadowCrash, 'ShadowCrash') and talents[classtable.ShadowCrash]) and (not holding_crash and math.huge >= 30 and talents[classtable.DescendingDarkness] and math.huge >= 30) and cooldown[classtable.ShadowCrash].ready then
        if not setSpell then setSpell = classtable.ShadowCrash end
    end
    if (MaxDps:CheckSpellUsable(classtable.ShadowWordDeath, 'ShadowWordDeath')) and (targethealthPerc <20 or talents[classtable.Deathspeaker] and targethealthPerc <35) and cooldown[classtable.ShadowWordDeath].ready then
        if not setSpell then setSpell = classtable.ShadowWordDeath end
    end
    if (MaxDps:CheckSpellUsable(classtable.ShadowWordDeath, 'ShadowWordDeath')) and (talents[classtable.InescapableTorment] and ( UnitExists('pet') and UnitName('pet')  == 'Fiend' )) and cooldown[classtable.ShadowWordDeath].ready then
        if not setSpell then setSpell = classtable.ShadowWordDeath end
    end
    if (MaxDps:CheckSpellUsable(classtable.MindFlay, 'MindFlay')) and cooldown[classtable.MindFlay].ready then
        if not setSpell then setSpell = classtable.MindFlay end
    end
    if (MaxDps:CheckSpellUsable(classtable.DivineStar, 'DivineStar')) and cooldown[classtable.DivineStar].ready then
        if not setSpell then setSpell = classtable.DivineStar end
    end
    if (MaxDps:CheckSpellUsable(classtable.ShadowCrash, 'ShadowCrash') and talents[classtable.ShadowCrash]) and (math.huge >20) and cooldown[classtable.ShadowCrash].ready then
        if not setSpell then setSpell = classtable.ShadowCrash end
    end
    if (MaxDps:CheckSpellUsable(classtable.ShadowWordDeath, 'ShadowWordDeath')) and (targethealthPerc <20) and cooldown[classtable.ShadowWordDeath].ready then
        if not setSpell then setSpell = classtable.ShadowWordDeath end
    end
    if (MaxDps:CheckSpellUsable(classtable.ShadowWordDeath, 'ShadowWordDeath')) and (debuff[classtable.DevouringPlagueDeBuff].up) and cooldown[classtable.ShadowWordDeath].ready then
        if not setSpell then setSpell = classtable.ShadowWordDeath end
    end
    if (MaxDps:CheckSpellUsable(classtable.ShadowWordPain, 'ShadowWordPain')) and cooldown[classtable.ShadowWordPain].ready then
        if not setSpell then setSpell = classtable.ShadowWordPain end
    end
end
function Shadow:trinkets()
end


local function ClearCDs()
    MaxDps:GlowCooldown(classtable.Halo, false)
    MaxDps:GlowCooldown(classtable.Silence, false)
    MaxDps:GlowCooldown(classtable.PowerInfusion, false)
    MaxDps:GlowCooldown(classtable.VoidEruption, false)
    MaxDps:GlowCooldown(classtable.DesperatePrayer, false)
    MaxDps:GlowCooldown(classtable.hyperthread_wristwraps, false)
    MaxDps:GlowCooldown(classtable.aberrant_spellforge, false)
    MaxDps:GlowCooldown(classtable.neural_synapse_enhancer, false)
    MaxDps:GlowCooldown(classtable.flarendos_pilot_light, false)
    MaxDps:GlowCooldown(classtable.geargrinders_spare_keys, false)
    MaxDps:GlowCooldown(classtable.spymasters_web, false)
end

function Shadow:callaction()
    if (MaxDps:CheckSpellUsable(classtable.Silence, 'Silence')) and cooldown[classtable.Silence].ready then
        MaxDps:GlowCooldown(classtable.Silence, ( select(8,UnitCastingInfo('target')) ~= nil and not select(8,UnitCastingInfo('target')) or select(7,UnitChannelInfo('target')) ~= nil and not select(7,UnitChannelInfo('target'))) )
    end
    holding_crash = false
    pool_for_cds = (cooldown[classtable.VoidEruption].remains <= gcd*3 and talents[classtable.VoidEruption] or cooldown[classtable.DarkAscension].ready and talents[classtable.DarkAscension]) or talents[classtable.VoidTorrent] and talents[classtable.PsychicLink] and cooldown[classtable.VoidTorrent].remains <= 4 and not holding_crash and not buff[classtable.VoidformBuff].up
    if (targets >2) then
        Shadow:aoe()
    end
    Shadow:main()
end
function Priest:Shadow()
    fd = MaxDps.FrameData
    ttd = (fd.timeToDie and fd.timeToDie) or 500
    timeShift = fd.timeShift
    gcd = fd.gcd
    cooldown = fd.cooldown
    buff = fd.buff
    debuff = fd.debuff
    talents = fd.talents
    targets = MaxDps:SmartAoe()
    targetHP = UnitHealth('target')
    targetmaxHP = UnitHealthMax('target')
    targethealthPerc = (targetHP >0 and targetmaxHP >0 and (targetHP / targetmaxHP) * 100) or 100
    curentHP = UnitHealth('player')
    maxHP = UnitHealthMax('player')
    healthPerc = (curentHP / maxHP) * 100
    timeInCombat = MaxDps.combatTime or 0
    classtable = MaxDps.SpellTable
    local trinket1ID = GetInventoryItemID('player', 13)
    local trinket2ID = GetInventoryItemID('player', 14)
    local MHID = GetInventoryItemID('player', 16)
    classtable.trinket1 = (trinket1ID and select(2,GetItemSpell(trinket1ID)) ) or 0
    classtable.trinket2 = (trinket2ID and select(2,GetItemSpell(trinket2ID)) ) or 0
    classtable.main_hand = (MHID and select(2,GetItemSpell(MHID)) ) or 0
    Mana = UnitPower('player', ManaPT)
    ManaMax = UnitPowerMax('player', ManaPT)
    ManaDeficit = ManaMax - Mana
    ManaPerc = (Mana / ManaMax) * 100
    ManaRegen = GetPowerRegenForPowerType(ManaPT)
    ManaTimeToMax = ManaDeficit / ManaRegen
    Insanity = UnitPower('player', InsanityPT)
    InsanityMax = UnitPowerMax('player', InsanityPT)
    InsanityDeficit = InsanityMax - Insanity
    InsanityPerc = (Insanity / InsanityMax) * 100
    InsanityRegen = GetPowerRegenForPowerType(InsanityPT)
    InsanityTimeToMax = InsanityDeficit / InsanityRegen
    SpellHaste = UnitSpellHaste('player')
    SpellCrit = GetCritChance()
    --for spellId in pairs(MaxDps.Flags) do
    --    self.Flags[spellId] = false
    --    self:ClearGlowIndependent(spellId, spellId)
    --end
    classtable.ShadowformBuff = 232698
    classtable.VoidformBuff = 194249
    classtable.EntropicRiftBuff = 447444
    classtable.PowerInfusionBuff = 10060
    classtable.DarkAscensionBuff = 391109
    classtable.BloodlustBuff = 2825
    classtable.MindDevourerBuff = 373204
    classtable.PowerSurgeBuff = 453109
    classtable.RhapsodyBuff = 390636
    classtable.Tww3Archon4pcHelperBuff = 0
    classtable.AscensionBuff = 391109
    classtable.VoidVolleyBuff = 1242171
    classtable.MindFlayInsanityBuff = 391401
    classtable.TwistofFateBuff = 390978
    classtable.TwistofFateCanTriggerOnAllyHealBuff = 0
    classtable.AberrantSpellforgeBuff = 0
    classtable.SpymastersReportBuff = 451199
    classtable.SpymastersWebBuff = 444959
    classtable.ShadowWordPainDeBuff = 589
    classtable.DevouringPlagueDeBuff = 335467
    classtable.VampiricTouchDeBuff = 34914
    classtable.Fiend = 34433
    classtable.VoidBolt = 205448
    classtable.ShadowCrash = talents[457042] and 457042 or 205385

    local function debugg()
        talents[classtable.PowerSurge] = 1
        talents[classtable.WhisperingShadows] = 1
        talents[classtable.ShadowCrash] = 1
        talents[classtable.Mindbender] = 1
        talents[classtable.InescapableTorment] = 1
        talents[classtable.DarkAscension] = 1
        talents[classtable.VoidEruption] = 1
        talents[classtable.MindDevourer] = 1
        talents[classtable.Rhapsody] = 1
        talents[classtable.DevourMatter] = 1
        talents[classtable.VoidEmpowerment] = 1
        talents[classtable.PerfectedForm] = 1
        talents[classtable.VoidBlast] = 1
        talents[classtable.DistortedReality] = 1
        talents[classtable.DescendingDarkness] = 1
        talents[classtable.Deathspeaker] = 1
        talents[classtable.EntropicRift] = 1
    end


    --if MaxDps.db.global.debugMode then
    --   debugg()
    --end

    setSpell = nil
    ClearCDs()

    Shadow:precombat()

    Shadow:callaction()
    if setSpell then return setSpell end
end
