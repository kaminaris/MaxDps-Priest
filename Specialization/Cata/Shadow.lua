local _, addonTable = ...
local Priest = addonTable.Priest
local MaxDps = _G.MaxDps
if not MaxDps then return end
local setSpell

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
local GetSpellCount = C_Spell.GetSpellCastCount

local ManaPT = Enum.PowerType.Mana
local RagePT = Enum.PowerType.Rage
local FocusPT = Enum.PowerType.Focus
local EnergyPT = Enum.PowerType.Energy
local ComboPointsPT = Enum.PowerType.ComboPoints
local RunesPT = Enum.PowerType.Runes
local RunicPowerPT = Enum.PowerType.RunicPower
local SoulShardsPT = Enum.PowerType.SoulShards
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
local classtable
local LibRangeCheck = LibStub('LibRangeCheck-3.0', true)

local Insanity
local InsanityMax
local InsanityDeficit
local Mana
local ManaMax
local ManaDeficit
local ManaPerc

local Shadow = {}



local function GetTotemDuration(name)
    for index=1,MAX_TOTEMS do
        local arg1, totemName, startTime, duration, icon = GetTotemInfo(index)
        local est_dur = math.floor(startTime+duration-GetTime())
        if (totemName == name and est_dur and est_dur > 0) then return est_dur else return 0 end
    end
end




local function GetTotemDuration(name)
    for index=1,MAX_TOTEMS do
        local arg1, totemName, startTime, duration, icon = GetTotemInfo(index)
        local est_dur = math.floor(startTime+duration-GetTime())
        if (totemName == name and est_dur and est_dur > 0) then return est_dur else return 0 end
    end
end


function Shadow:precombat()
    if (MaxDps:CheckSpellUsable(classtable.Shadowform, 'Shadowform')) and (not buff[classtable.ShadowformBuff].up) and cooldown[classtable.Shadowform].ready and not UnitAffectingCombat('player') then
        if not setSpell then setSpell = classtable.Shadowform end
    end
    if (MaxDps:CheckSpellUsable(classtable.PowerWordFortitude, 'PowerWordFortitude')) and (not buff[classtable.PowerWordFortitudeBuff].up) and cooldown[classtable.PowerWordFortitude].ready and not UnitAffectingCombat('player') then
        if not setSpell then setSpell = classtable.PowerWordFortitude end
    end
    if (MaxDps:CheckSpellUsable(classtable.InnerFire, 'InnerFire')) and (not buff[classtable.InnerFire].up) and cooldown[classtable.InnerFire].ready and not UnitAffectingCombat('player') then
        if not setSpell then setSpell = classtable.InnerFire end
    end
    if (MaxDps:CheckSpellUsable(classtable.VampiricEmbrace, 'VampiricEmbrace')) and (not buff[classtable.VampiricEmbrace].up) and cooldown[classtable.VampiricEmbrace].ready and not UnitAffectingCombat('player') then
        if not setSpell then setSpell = classtable.VampiricEmbrace end
    end
    if (MaxDps:CheckSpellUsable(classtable.MindSpike, 'MindSpike')) and cooldown[classtable.MindSpike].ready and not UnitAffectingCombat('player') then
        if not setSpell then setSpell = classtable.MindSpike end
    end
end
function Shadow:st()
    if (MaxDps:CheckSpellUsable(classtable.MindSpike, 'MindSpike')) and (not debuff[classtable.MindSpikeDeBuff].up and not debuff[classtable.ShadowWordPainDeBuff].up and not debuff[classtable.DevouringPlagueDeBuff].up and not debuff[classtable.VampiricTouchDeBuff].up) and cooldown[classtable.MindSpike].ready then
        if not setSpell then setSpell = classtable.MindSpike end
    end
    if (MaxDps:CheckSpellUsable(classtable.Shadowfiend, 'Shadowfiend')) and (not UnitExists('pet') and timeInCombat <5) and cooldown[classtable.Shadowfiend].ready then
        if not setSpell then setSpell = classtable.Shadowfiend end
    end
    if (MaxDps:CheckSpellUsable(classtable.MindFlay, 'MindFlay')) and (debuff[classtable.ShadowWordPainDeBuff].up and debuff[classtable.ShadowWordPainDeBuff].remains <gcd + 1) and cooldown[classtable.MindFlay].ready then
        if not setSpell then setSpell = classtable.MindFlay end
    end
    if (MaxDps:CheckSpellUsable(classtable.ShadowWordPain, 'ShadowWordPain')) and (not debuff[classtable.ShadowWordPainDeBuff].up) and cooldown[classtable.ShadowWordPain].ready then
        if not setSpell then setSpell = classtable.ShadowWordPain end
    end
    if (MaxDps:CheckSpellUsable(classtable.MindFlay, 'MindFlay')) and (not ( buff[classtable.ShadowOrbBuff].count >= 1 and buff[classtable.DarkEvangelismBuff].count >= 5 ) and timeInCombat <= ( 2 * gcd + 2.5 * 3 )) and cooldown[classtable.MindFlay].ready then
        if not setSpell then setSpell = classtable.MindFlay end
    end
    if (MaxDps:CheckSpellUsable(classtable.MindBlast, 'MindBlast')) and (buff[classtable.ShadowOrbBuff].up) and cooldown[classtable.MindBlast].ready then
        if not setSpell then setSpell = classtable.MindBlast end
    end
    if (MaxDps:CheckSpellUsable(classtable.VampiricTouch, 'VampiricTouch')) and (debuff[classtable.VampiricTouchDeBuff].remains <debuff[classtable.VampiricTouchDeBuff].tick_time) and cooldown[classtable.VampiricTouch].ready then
        if not setSpell then setSpell = classtable.VampiricTouch end
    end
    if (MaxDps:CheckSpellUsable(classtable.DevouringPlague, 'DevouringPlague')) and (debuff[classtable.DevouringPlagueDeBuff].remains <debuff[classtable.DevouringPlagueDeBuff].tick_time) and cooldown[classtable.DevouringPlague].ready then
        if not setSpell then setSpell = classtable.DevouringPlague end
    end
    if (MaxDps:CheckSpellUsable(classtable.MindBlast, 'MindBlast')) and cooldown[classtable.MindBlast].ready then
        if not setSpell then setSpell = classtable.MindBlast end
    end
    if (MaxDps:CheckSpellUsable(classtable.Archangel, 'Archangel')) and (buff[classtable.DarkEvangelismBuff].count == 5 and ( debuff[classtable.VampiricTouchDeBuff].remains >5 and debuff[classtable.DevouringPlagueDeBuff].remains >5 )) and cooldown[classtable.Archangel].ready then
        if not setSpell then setSpell = classtable.Archangel end
    end
    if (MaxDps:CheckSpellUsable(classtable.Shadowfiend, 'Shadowfiend')) and (not UnitExists('pet')) and cooldown[classtable.Shadowfiend].ready then
        if not setSpell then setSpell = classtable.Shadowfiend end
    end
    if (MaxDps:CheckSpellUsable(classtable.ShadowWordDeath, 'ShadowWordDeath')) and (targetHP <25 or ManaPerc <20) and cooldown[classtable.ShadowWordDeath].ready then
        if not setSpell then setSpell = classtable.ShadowWordDeath end
    end
    if (MaxDps:CheckSpellUsable(classtable.Dispersion, 'Dispersion')) and (ManaPerc <10) and cooldown[classtable.Dispersion].ready then
        if not setSpell then setSpell = classtable.Dispersion end
    end
    if (MaxDps:CheckSpellUsable(classtable.MindFlay, 'MindFlay')) and (not ( debuff[classtable.VampiricTouchDeBuff].remains <gcd or debuff[classtable.DevouringPlagueDeBuff].remains <gcd or cooldown[classtable.MindBlast].remains <gcd )) and cooldown[classtable.MindFlay].ready then
        if not setSpell then setSpell = classtable.MindFlay end
    end
end
function Shadow:aoe()
    if (MaxDps:CheckSpellUsable(classtable.MindSear, 'MindSear')) and (targets >5) and cooldown[classtable.MindSear].ready then
        if not setSpell then setSpell = classtable.MindSear end
    end
    if (MaxDps:CheckSpellUsable(classtable.ShadowWordPain, 'ShadowWordPain')) and (false and debuff[classtable.ShadowWordPainDeBuff].remains <debuff[classtable.ShadowWordPainDeBuff].tick_time) and cooldown[classtable.ShadowWordPain].ready then
        if not setSpell then setSpell = classtable.ShadowWordPain end
    end
    if (MaxDps:CheckSpellUsable(classtable.VampiricTouch, 'VampiricTouch')) and (false and debuff[classtable.VampiricTouchDeBuff].remains <debuff[classtable.VampiricTouchDeBuff].tick_time and ttd >= debuff[classtable.VampiricTouchDeBuff].duration) and cooldown[classtable.VampiricTouch].ready then
        if not setSpell then setSpell = classtable.VampiricTouch end
    end
    if (MaxDps:CheckSpellUsable(classtable.DevouringPlague, 'DevouringPlague')) and (false and debuff[classtable.DevouringPlagueDeBuff].remains <debuff[classtable.DevouringPlagueDeBuff].tick_time) and cooldown[classtable.DevouringPlague].ready then
        if not setSpell then setSpell = classtable.DevouringPlague end
    end
    if (MaxDps:CheckSpellUsable(classtable.MindBlast, 'MindBlast')) and (buff[classtable.ShadowOrbBuff].up) and cooldown[classtable.MindBlast].ready then
        if not setSpell then setSpell = classtable.MindBlast end
    end
    if (MaxDps:CheckSpellUsable(classtable.MindFlay, 'MindFlay')) and (debuff[classtable.ShadowWordPainDeBuff].up and debuff[classtable.ShadowWordPainDeBuff].remains <gcd + 1) and cooldown[classtable.MindFlay].ready then
        if not setSpell then setSpell = classtable.MindFlay end
    end
    if (MaxDps:CheckSpellUsable(classtable.ShadowWordDeath, 'ShadowWordDeath')) and (targetHP <25 and targets <4 or ManaPerc <15) and cooldown[classtable.ShadowWordDeath].ready then
        if not setSpell then setSpell = classtable.ShadowWordDeath end
    end
    if (MaxDps:CheckSpellUsable(classtable.MindSear, 'MindSear')) and cooldown[classtable.MindSear].ready then
        if not setSpell then setSpell = classtable.MindSear end
    end
end


local function ClearCDs()
end

function Shadow:callaction()
    if (MaxDps:CheckSpellUsable(classtable.Shadowform, 'Shadowform')) and (not buff[classtable.ShadowformBuff].up) and cooldown[classtable.Shadowform].ready then
        if not setSpell then setSpell = classtable.Shadowform end
    end
    if (targets >= 2) then
        Shadow:aoe()
    end
    Shadow:st()
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
    Mana = UnitPower('player', ManaPT)
    ManaMax = UnitPowerMax('player', ManaPT)
    ManaDeficit = ManaMax - Mana
    ManaPerc = (Mana / ManaMax) * 100
    targetHP = UnitHealth('target')
    targetmaxHP = UnitHealthMax('target')
    targethealthPerc = (targetHP >0 and targetmaxHP >0 and (targetHP / targetmaxHP) * 100) or 100
    curentHP = UnitHealth('player')
    maxHP = UnitHealthMax('player')
    healthPerc = (curentHP / maxHP) * 100
    timeInCombat = MaxDps.combatTime or 0
    classtable = MaxDps.SpellTable
    SpellHaste = UnitSpellHaste('player')
    SpellCrit = GetCritChance()
    Insanity = UnitPower('player', InsanityPT)
    InsanityMax = UnitPowerMax('player', InsanityPT)
    InsanityDeficit = InsanityMax - Insanity
    --for spellId in pairs(MaxDps.Flags) do
    --    self.Flags[spellId] = false
    --    self:ClearGlowIndependent(spellId, spellId)
    --end
    classtable.ShadowformBuff = 15473
    classtable.PowerWordFortitudeBuff = 79105
    classtable.MindSpikeDeBuff = 73510
    classtable.MindSpikeDeBuff = 73510
    classtable.ShadowWordPainDeBuff = 589
    classtable.DevouringPlagueDeBuff = 2944
    classtable.VampiricTouchDeBuff = 34914
    classtable.ShadowOrbBuff = 77487
    classtable.DarkEvangelismBuff = 87118
    classtable.Shadowform = 15473
    classtable.PowerWordFortitude = 79105
    classtable.InnerFire = 588
    classtable.VampiricEmbrace = 15286
    classtable.MindSpike = 73510
    classtable.ShadowWordPain = 589
    classtable.DevouringPlague = 2944
    classtable.VampiricTouch = 34914
    classtable.Shadowfiend = 34433
    classtable.MindFlay = 15407
    classtable.MindBlast = 8092
    classtable.Archangel = 87151
    classtable.ShadowWordDeath = 32379
    classtable.Dispersion = 47585
    classtable.MindSear = 48045

    local function debugg()
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
