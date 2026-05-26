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
-- local classtable
local LibRangeCheck = LibStub('LibRangeCheck-3.0', true)

local Insanity
local InsanityMax
local InsanityDeficit
local Mana
local ManaMax
local ManaDeficit
local ManaPerc

local Discipline = {}
addonTable.Discipline = Discipline

local function ClearCDs()
end

function Discipline:AoE()
    if not Discipline.classtable then Discipline.classtable = MaxDps.SpellTable or {} end
    if not cooldown then cooldown = (MaxDps.FrameData and MaxDps.FrameData.cooldown) or {} end
    if not buff then buff = (MaxDps.FrameData and MaxDps.FrameData.buff) or {} end
    if not debuff then debuff = (MaxDps.FrameData and MaxDps.FrameData.debuff) or {} end
    if not talents then talents = (MaxDps.FrameData and MaxDps.FrameData.talents) or {} end
    if (MaxDps:CheckSpellUsable(Discipline.classtable.HolyNova, 'HolyNova')) and cooldown[Discipline.classtable.HolyNova].ready then
        if not setSpell then setSpell = Discipline.classtable.HolyNova end
    end
end

function Discipline:st()
    if not Discipline.classtable then Discipline.classtable = MaxDps.SpellTable or {} end
    if not cooldown then cooldown = (MaxDps.FrameData and MaxDps.FrameData.cooldown) or {} end
    if not buff then buff = (MaxDps.FrameData and MaxDps.FrameData.buff) or {} end
    if not debuff then debuff = (MaxDps.FrameData and MaxDps.FrameData.debuff) or {} end
    if not talents then talents = (MaxDps.FrameData and MaxDps.FrameData.talents) or {} end
    if (MaxDps:CheckSpellUsable(Discipline.classtable.ShadowWordPain, 'ShadowWordPain')) and (MaxDps:FindDeBuffAuraData(Discipline.classtable.ShadowWordPain).refreshable) and cooldown[Discipline.classtable.ShadowWordPain].ready then
        if not setSpell then setSpell = Discipline.classtable.ShadowWordPain end
    end
    if (MaxDps:CheckSpellUsable(Discipline.classtable.HolyFire, 'HolyFire')) and (MaxDps:FindDeBuffAuraData(Discipline.classtable.HolyFire).refreshable) and cooldown[Discipline.classtable.HolyFire].ready then
        if not setSpell then setSpell = Discipline.classtable.HolyFire end
    end
    if (MaxDps:CheckSpellUsable(Discipline.classtable.Smite, 'Smite')) and cooldown[Discipline.classtable.Smite].ready then
        if not setSpell then setSpell = Discipline.classtable.Smite end
    end
end

function Discipline:callaction()
    if targets > 1 then
        Discipline:AoE()
    end
    Discipline:st()
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
    Discipline.classtable = MaxDps.SpellTable or {}
    SpellHaste = UnitSpellHaste('player')
    SpellCrit = GetCritChance()
    Insanity = UnitPower('player', InsanityPT)
    InsanityMax = UnitPowerMax('player', InsanityPT)
    InsanityDeficit = InsanityMax - Insanity
    ManaPerc = (Mana / ManaMax) * 100


    Discipline.classtable.HolyNova = 15237
    Discipline.classtable.ShadowWordPain = 589
    Discipline.classtable.HolyFire = 14914
    Discipline.classtable.Smite = 585

    setSpell = nil
    ClearCDs()

    Discipline:callaction()
    if setSpell then return setSpell end
end
