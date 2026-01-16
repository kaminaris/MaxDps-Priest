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

local function ClearCDs()
end

--function Shadow:st()
--end

function Shadow:callaction()
    if (MaxDps:CheckSpellUsable(classtable.Shadowform, 'Shadowform')) and (not buff[classtable.Shadowform].up) and cooldown[classtable.Shadowform].ready then
        if not setSpell then setSpell = classtable.Shadowform end
    end
    if (MaxDps:CheckSpellUsable(classtable.VampiricEmbrace, 'VampiricEmbrace')) and ttd >= 60 and cooldown[classtable.VampiricEmbrace].ready then
        if not setSpell then setSpell = classtable.VampiricEmbrace end
    end
    if (MaxDps:CheckSpellUsable(classtable.VampiricTouch, 'VampiricTouch')) and (MaxDps:FindADAuraData(classtable.VampiricTouch).refreshable) and cooldown[classtable.VampiricTouch].ready then
        if not setSpell then setSpell = classtable.VampiricTouch end
    end
    if (MaxDps:CheckSpellUsable(classtable.ShadowWordPain, 'ShadowWordPain')) and (MaxDps:FindADAuraData(classtable.ShadowWordPain).refreshable) and cooldown[classtable.ShadowWordPain].ready then
        if not setSpell then setSpell = classtable.ShadowWordPain end
    end
    if (MaxDps:CheckSpellUsable(classtable.MindBlast, 'MindBlast')) and cooldown[classtable.MindBlast].ready then
        if not setSpell then setSpell = classtable.MindBlast end
    end
    --if (MaxDps:CheckSpellUsable(classtable.ShadowWordDeath, 'ShadowWordDeath')) and healthPerc >= 50 and cooldown[classtable.ShadowWordDeath].ready then
    --    if not setSpell then setSpell = classtable.ShadowWordDeath end
    --end
    if (MaxDps:CheckSpellUsable(classtable.MindFlay, 'MindFlay')) and cooldown[classtable.MindFlay].ready then
        if not setSpell then setSpell = classtable.MindFlay end
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


    classtable.Shadowform = 15473
    classtable.VampiricEmbrace = 15286
    classtable.VampiricTouch = 34917
    classtable.ShadowWordPain = 25367
    classtable.MindBlast = 10947
    classtable.ShadowWordDeath = 32996
    classtable.MindFlay = 25387

    setSpell = nil
    ClearCDs()

    Shadow:callaction()
    if setSpell then return setSpell end
end
