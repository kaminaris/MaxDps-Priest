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
local ShadowOrbsPT = Enum.PowerType.ShadowOrbs

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

local ShadowOrbs
local Insanity
local InsanityMax
local InsanityDeficit
local Mana
local ManaMax
local ManaDeficit
local ManaPerc

local Discipline = {}

function Discipline:precombat()
end


local function ClearCDs()
end

function Discipline:callaction()
    if (MaxDps:CheckSpellUsable(classtable.PowerWordSolace, 'PowerWordSolace')) and cooldown[classtable.PowerWordSolace].ready then
        if not setSpell then setSpell = classtable.PowerWordSolace end
    end

    if targets >= 3 then
        if (MaxDps:CheckSpellUsable(classtable.DivineStar, 'DivineStar')) and cooldown[classtable.DivineStar].ready then
            if not setSpell then setSpell = classtable.DivineStar end
        end
        if (MaxDps:CheckSpellUsable(classtable.Cascade, 'Cascade')) and cooldown[classtable.Cascade].ready then
            if not setSpell then setSpell = classtable.Cascade end
        end
    end

    if (MaxDps:CheckSpellUsable(classtable.Penance, 'Penance')) and cooldown[classtable.Penance].ready then
        if not setSpell then setSpell = classtable.Penance end
    end

    if (MaxDps:CheckSpellUsable(classtable.ShadowWordPain, 'ShadowWordPain')) and debuff[classtable.ShadowWordPain].refreshable then
        if not setSpell then setSpell = classtable.ShadowWordPain end
    end

    if (MaxDps:CheckSpellUsable(classtable.HolyFire, 'HolyFire')) and cooldown[classtable.HolyFire].ready then
        if not setSpell then setSpell = classtable.HolyFire end
    end
    if (MaxDps:CheckSpellUsable(classtable.Smite, 'Smite')) and cooldown[classtable.Smite].ready then
        if not setSpell then setSpell = classtable.Smite end
    end
end
function Priest:Discipline()
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
    ShadowOrbs = UnitPower('player', ShadowOrbsPT)
    InsanityDeficit = InsanityMax - Insanity
    ManaPerc = (Mana / ManaMax) * 100
    --for spellId in pairs(MaxDps.Flags) do
    --    self.Flags[spellId] = false
    --    self:ClearGlowIndependent(spellId, spellId)
    --end

    local function debugg()
    end

    classtable.MindFlay = 15407

    classtable.PowerWordFortitudeBuff = 21562
    classtable.InnerFireBuff = 588
    classtable.ShadowformBuff = 15473
    classtable.SurgeofDarknessBuff = 87160
    classtable.DivineInsightShadowBuff = 124430
    classtable.ShadowWordPainDeBuff = 589
    classtable.VampiricTouchDeBuff = 34914
    classtable.PowerWordSolace = 129250

    --if MaxDps.db.global.debugMode then
    --   debugg()
    --end

    setSpell = nil
    ClearCDs()

    Discipline:precombat()

    Discipline:callaction()
    if setSpell then return setSpell end
end
