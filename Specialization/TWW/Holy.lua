
local _, addonTable = ...

--- @type MaxDps
if not MaxDps then return end

local Priest = addonTable.Priest
local MaxDps = MaxDps
local UnitPower = UnitPower
local UnitHealth = UnitHealth
local UnitAura = C_UnitAuras.GetAuraDataByIndex
local GetSpellDescription = GetSpellDescription
local GetSpellPowerCost = C_Spell.GetSpellPowerCost
local UnitHealthMax = UnitHealthMax
local UnitPowerMax = UnitPowerMax
local PowerTypeMana = Enum.PowerType.Mana

local fd
local cooldown
local buff
local debuff
local talents
local timetodie
local targets
local mana
local manaMax
local manaDeficit
local insanity
local targetHP
local targetmaxHP
local targethealthPerc
local curentHP
local maxHP
local healthPerc

local className, classFilename, classId = UnitClass('player')
local currentSpec = GetSpecialization()
local currentSpecName = currentSpec and select(2, GetSpecializationInfo(currentSpec)) or "None"
local classtable

function Priest:Holy()
    fd = MaxDps.FrameData
    cooldown = fd.cooldown
    buff = fd.buff
    debuff = fd.debuff
    talents = fd.talents
	timetodie = fd.timetodie or 0
    targets = MaxDps:SmartAoe()
    mana = UnitPower('player', PowerTypeMana)
    manaMax = UnitPowerMax('player', PowerTypeMana)
    manaDeficit = manaMax - mana
    targetHP = UnitHealth('target')
    targetmaxHP = UnitHealthMax('target')
    targethealthPerc = (targetHP / targetmaxHP) * 100
    curentHP = UnitHealth('player')
    maxHP = UnitHealthMax('player')
    healthPerc = (curentHP / maxHP) * 100
    classtable = MaxDps.SpellTable
    classtable.RhapsodyBuff = 390636
	--setmetatable(classtable, Priest.spellMeta)
    if targets >= 3  then
        return Priest:HolyMultiTarget()
    end
    return Priest:HolySingleTarget()
end

--optional abilities list

--Single-Target Rotation
function Priest:HolySingleTarget()
    --Holy Fire
    if cooldown[classtable.HolyFire].ready then
        return classtable.HolyFire
    end
    --Mindgames (if talented)
    if talents[classtable.Mindgames] and cooldown[classtable.Mindgames].ready then
        return classtable.Mindgames
    end
    --Shadow Word: Pain (if the target will survive for the full duration)
    if talents[classtable.ShadowWordPain] and debuff[classtable.ShadowWordPain].refreshable and timetodie >= 16 and cooldown[classtable.ShadowWordPain].ready then
        return classtable.ShadowWordPain
    end
    --Holy Word: Chastise (if you do not need the incapacitate/stun for cc)
    --Divine Star
    if talents[classtable.DivineStar] and cooldown[classtable.DivineStar].ready then
        return classtable.DivineStar
    end
    --Smite
    if cooldown[classtable.Smite].ready then
        return classtable.Smite
    end
end

--Multiple-Target Rotation
function Priest:HolyMultiTarget()
    --Divine Star
    if talents[classtable.DivineStar] and cooldown[classtable.DivineStar].ready then
        return classtable.DivineStar
    end
    --Holy Fire
    if cooldown[classtable.HolyFire].ready then
        return classtable.HolyFire
    end
    --Mindgames (if talented)
    if talents[classtable.Mindgames] and cooldown[classtable.Mindgames].ready then
        return classtable.Mindgames
    end
    --Holy Nova with 16+ stacks of Rhapsody
    if talents[classtable.HolyNova] and buff[classtable.RhapsodyBuff].count >= 16 and cooldown[classtable.HolyNova].ready then
        return classtable.HolyNova
    end
    --Shadow Word: Pain (if the target will survive for the full duration)
    if talents[classtable.ShadowWordPain] and debuff[classtable.ShadowWordPain].refreshable and timetodie >= 16 and cooldown[classtable.ShadowWordPain].ready then
        return classtable.ShadowWordPain
    end
    --Holy Nova
    if talents[classtable.HolyNova] and cooldown[classtable.HolyNova].ready then
        return classtable.HolyNova
    end
end
