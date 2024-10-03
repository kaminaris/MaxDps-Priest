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
local className, classFilename, classId = UnitClass('player')
local currentSpec = GetSpecialization()
local currentSpecName = currentSpec and select(2, GetSpecializationInfo(currentSpec)) or 'None'
local classtable
local LibRangeCheck = LibStub('LibRangeCheck-3.0', true)

local Insanity
local InsanityMax
local InsanityDeficit
local Mana
local ManaMax
local ManaDeficit

local Shadow = {}



local function GetTotemDuration(name)
    for index=1,MAX_TOTEMS do
        local arg1, totemName, startTime, duration, icon = GetTotemInfo(index)
        local est_dur = math.floor(startTime+duration-GetTime())
        if (totemName == name and est_dur and est_dur > 0) then return est_dur else return 0 end
    end
end




local function ClearCDs()
end

function Shadow:callaction()
    if (MaxDps:CheckSpellUsable(classtable.Fortitude, 'Fortitude')) and cooldown[classtable.Fortitude].ready then
        if not setSpell then setSpell = classtable.Fortitude end
    end
    if (MaxDps:CheckSpellUsable(classtable.InnerFire, 'InnerFire')) and cooldown[classtable.InnerFire].ready then
        if not setSpell then setSpell = classtable.InnerFire end
    end
    if (MaxDps:CheckSpellUsable(classtable.ShadowForm, 'ShadowForm')) and cooldown[classtable.ShadowForm].ready then
        if not setSpell then setSpell = classtable.ShadowForm end
    end
    if (MaxDps:CheckSpellUsable(classtable.VampiricEmbrace, 'VampiricEmbrace')) and cooldown[classtable.VampiricEmbrace].ready then
        if not setSpell then setSpell = classtable.VampiricEmbrace end
    end
    if (MaxDps:CheckSpellUsable(classtable.MindBlast, 'MindBlast')) and cooldown[classtable.MindBlast].ready then
        if not setSpell then setSpell = classtable.MindBlast end
    end
    if (MaxDps:CheckSpellUsable(classtable.ShadowWordPain, 'ShadowWordPain')) and (( not debuff[classtable.ShadowWordPainDeBuff].up or debuff[classtable.ShadowWordPainDeBuff].remains <gcd + 0.5 ) and miss_up) and cooldown[classtable.ShadowWordPain].ready then
        if not setSpell then setSpell = classtable.ShadowWordPain end
    end
    if (MaxDps:CheckSpellUsable(classtable.DevouringPlague, 'DevouringPlague')) and (( not debuff[classtable.DevouringPlagueDeBuff].up or debuff[classtable.DevouringPlagueDeBuff].remains <gcd + 1.0 ) and miss_up) and cooldown[classtable.DevouringPlague].ready then
        if not setSpell then setSpell = classtable.DevouringPlague end
    end
    if (MaxDps:CheckSpellUsable(classtable.VampiricTouch, 'VampiricTouch')) and (( not debuff[classtable.VampiricTouchDeBuff].up or debuff[classtable.VampiricTouchDeBuff].remains <( classtable and classtable.VampiricTouch and GetSpellInfo(classtable.VampiricTouch).castTime /1000 ) + 2.5 ) and miss_up) and cooldown[classtable.VampiricTouch].ready then
        if not setSpell then setSpell = classtable.VampiricTouch end
    end
    if (MaxDps:CheckSpellUsable(classtable.Archangel, 'Archangel')) and (buff[classtable.DarkEvangelismBuff].count >= 5 and debuff[classtable.VampiricTouchDeBuff].remains >5 and debuff[classtable.DevouringPlagueDeBuff].remains >5) and cooldown[classtable.Archangel].ready then
        if not setSpell then setSpell = classtable.Archangel end
    end
    if (MaxDps:CheckSpellUsable(classtable.ShadowWordDeath, 'ShadowWordDeath')) and cooldown[classtable.ShadowWordDeath].ready then
        if not setSpell then setSpell = classtable.ShadowWordDeath end
    end
    if (MaxDps:CheckSpellUsable(classtable.ShadowFiend, 'ShadowFiend')) and cooldown[classtable.ShadowFiend].ready then
        if not setSpell then setSpell = classtable.ShadowFiend end
    end
    if (MaxDps:CheckSpellUsable(classtable.ShadowWordDeath, 'ShadowWordDeath')) and (mana_pct <10) and cooldown[classtable.ShadowWordDeath].ready then
        if not setSpell then setSpell = classtable.ShadowWordDeath end
    end
    if (MaxDps:CheckSpellUsable(classtable.MindFlay, 'MindFlay')) and cooldown[classtable.MindFlay].ready then
        if not setSpell then setSpell = classtable.MindFlay end
    end
    if (MaxDps:CheckSpellUsable(classtable.ShadowWordDeath, 'ShadowWordDeath')) and cooldown[classtable.ShadowWordDeath].ready then
        if not setSpell then setSpell = classtable.ShadowWordDeath end
    end
    if (MaxDps:CheckSpellUsable(classtable.DevouringPlague, 'DevouringPlague')) and (mana_pct >10) and cooldown[classtable.DevouringPlague].ready then
        if not setSpell then setSpell = classtable.DevouringPlague end
    end
    if (MaxDps:CheckSpellUsable(classtable.Dispersion, 'Dispersion')) and cooldown[classtable.Dispersion].ready then
        if not setSpell then setSpell = classtable.Dispersion end
    end
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
    classtable.bloodlust = 0
    classtable.ShadowWordPainDeBuff = 589
    classtable.DevouringPlagueDeBuff = 335467
    classtable.VampiricTouchDeBuff = 34914
    classtable.DarkEvangelismBuff = 0
    setSpell = nil
    ClearCDs()

    Shadow:callaction()
    if setSpell then return setSpell end
end
