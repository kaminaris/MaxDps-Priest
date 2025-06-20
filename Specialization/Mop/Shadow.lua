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
local ManaPerc

local Shadow = {}

function Shadow:precombat()
    if (MaxDps:CheckSpellUsable(classtable.PowerWordFortitude, 'PowerWordFortitude')) and (not aura.stamina.up) and cooldown[classtable.PowerWordFortitude].ready and not UnitAffectingCombat('player') then
        if not setSpell then setSpell = classtable.PowerWordFortitude end
    end
    if (MaxDps:CheckSpellUsable(classtable.InnerFire, 'InnerFire')) and cooldown[classtable.InnerFire].ready and not UnitAffectingCombat('player') then
        if not setSpell then setSpell = classtable.InnerFire end
    end
    if (MaxDps:CheckSpellUsable(classtable.Shadowform, 'Shadowform')) and cooldown[classtable.Shadowform].ready and not UnitAffectingCombat('player') then
        if not setSpell then setSpell = classtable.Shadowform end
    end
    if (MaxDps:CheckSpellUsable(classtable.VolcanicPotion, 'VolcanicPotion')) and cooldown[classtable.VolcanicPotion].ready and not UnitAffectingCombat('player') then
        if not setSpell then setSpell = classtable.VolcanicPotion end
    end
end


local function ClearCDs()
    MaxDps:GlowCooldown(classtable.Shadowfiend, false)
end

function Shadow:callaction()
    if (MaxDps:CheckSpellUsable(classtable.VolcanicPotion, 'VolcanicPotion')) and (MaxDps:Bloodlust(1) or ttd <= 40) and cooldown[classtable.VolcanicPotion].ready then
        if not setSpell then setSpell = classtable.VolcanicPotion end
    end
    if (MaxDps:CheckSpellUsable(classtable.DevouringPlague, 'DevouringPlague')) and (shadow_orb == 3 and ( cooldown[classtable.MindBlast].remains <2 or targethealthPerc <20 )) and cooldown[classtable.DevouringPlague].ready then
        if not setSpell then setSpell = classtable.DevouringPlague end
    end
    if (MaxDps:CheckSpellUsable(classtable.ShadowWordDeath, 'ShadowWordDeath')) and (targets <= 5 and ( (MaxDps.tier and MaxDps.tier[13].count >= 2 and 1 or 0) == 1 )) and cooldown[classtable.ShadowWordDeath].ready then
        if not setSpell then setSpell = classtable.ShadowWordDeath end
    end
    if (MaxDps:CheckSpellUsable(classtable.MindBlast, 'MindBlast')) and (targets <= 6 and cooldown[classtable.MindBlast].ready) and cooldown[classtable.MindBlast].ready then
        if not setSpell then setSpell = classtable.MindBlast end
    end
    if (MaxDps:CheckSpellUsable(classtable.ShadowWordPain, 'ShadowWordPain')) and (( not debuff[classtable.ShadowWordPainDeBuff].up or debuff[classtable.ShadowWordPainDeBuff].remains <1 ) and true) and cooldown[classtable.ShadowWordPain].ready then
        if not setSpell then setSpell = classtable.ShadowWordPain end
    end
    if (MaxDps:CheckSpellUsable(classtable.ShadowWordDeath, 'ShadowWordDeath')) and (targets <= 5 and ( (MaxDps.tier and MaxDps.tier[13].count >= 2 and 1 or 0) == 0 )) and cooldown[classtable.ShadowWordDeath].ready then
        if not setSpell then setSpell = classtable.ShadowWordDeath end
    end
    if (MaxDps:CheckSpellUsable(classtable.VampiricTouch, 'VampiricTouch')) and (( not debuff[classtable.VampiricTouchDeBuff].up or debuff[classtable.VampiricTouchDeBuff].remains <( classtable and classtable.VampiricTouch and GetSpellInfo(classtable.VampiricTouch).castTime /1000 or 0) + 1 ) and true) and cooldown[classtable.VampiricTouch].ready then
        if not setSpell then setSpell = classtable.VampiricTouch end
    end
    if (MaxDps:CheckSpellUsable(classtable.DevouringPlague, 'DevouringPlague')) and (shadow_orb == 3) and cooldown[classtable.DevouringPlague].ready then
        if not setSpell then setSpell = classtable.DevouringPlague end
    end
    if (MaxDps:CheckSpellUsable(classtable.MindSpike, 'MindSpike')) and (targets <= 6 and buff[classtable.SurgeofDarknessBuff].up) and cooldown[classtable.MindSpike].ready then
        if not setSpell then setSpell = classtable.MindSpike end
    end
    if (MaxDps:CheckSpellUsable(classtable.Shadowfiend, 'Shadowfiend')) and (cooldown[classtable.Shadowfiend].ready) and cooldown[classtable.Shadowfiend].ready then
        MaxDps:GlowCooldown(classtable.Shadowfiend, cooldown[classtable.Shadowfiend].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.MindSear, 'MindSear')) and (targets >= 3) and cooldown[classtable.MindSear].ready then
        if not setSpell then setSpell = classtable.MindSear end
    end
    if (MaxDps:CheckSpellUsable(classtable.MindFlay, 'MindFlay')) and cooldown[classtable.MindFlay].ready then
        if not setSpell then setSpell = classtable.MindFlay end
    end
    if (MaxDps:CheckSpellUsable(classtable.ShadowWordDeath, 'ShadowWordDeath')) and cooldown[classtable.ShadowWordDeath].ready then
        if not setSpell then setSpell = classtable.ShadowWordDeath end
    end
    if (MaxDps:CheckSpellUsable(classtable.MindBlast, 'MindBlast')) and (buff[classtable.DivineInsightShadowBuff].up and cooldown[classtable.MindBlast].ready) and cooldown[classtable.MindBlast].ready then
        if not setSpell then setSpell = classtable.MindBlast end
    end
    if (MaxDps:CheckSpellUsable(classtable.ShadowWordPain, 'ShadowWordPain')) and cooldown[classtable.ShadowWordPain].ready then
        if not setSpell then setSpell = classtable.ShadowWordPain end
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
    ManaPerc = (Mana / ManaMax) * 100
    --for spellId in pairs(MaxDps.Flags) do
    --    self.Flags[spellId] = false
    --    self:ClearGlowIndependent(spellId, spellId)
    --end

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
