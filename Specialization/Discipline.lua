
local _, addonTable = ...

--- @type MaxDps
if not MaxDps then return end

local Priest = addonTable.Priest
local MaxDps = MaxDps
local UnitPower = UnitPower
local UnitHealth = UnitHealth
local UnitAura = UnitAura
local GetSpellDescription = GetSpellDescription
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

function Priest:Discipline()
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
    classtable.PurgetheWickedDot = 204213
    if talents[classtable.UltimatePenitence] then
		MaxDps:GlowCooldown(classtable.UltimatePenitence, cooldown[classtable.UltimatePenitence].ready)
	end
    if talents[classtable.Shadowfiend] then
		MaxDps:GlowCooldown(classtable.Shadowfiend, cooldown[classtable.Shadowfiend].ready)
	end
	--setmetatable(classtable, Priest.spellMeta)
    if targets > 1  then
        return Priest:DisciplineMultiTarget()
    end
    return Priest:DisciplineSingleTarget()
end

--optional abilities list

--Single-Target Rotation
function Priest:DisciplineSingleTarget()
    if talents[classtable.PurgetheWicked] and debuff[classtable.PurgetheWickedDot].refreshable and cooldown[classtable.PurgetheWicked].ready then
        return classtable.PurgetheWicked
    end
    if not talents[classtable.PurgetheWicked] and debuff[classtable.ShadowWordPain].refreshable and cooldown[classtable.ShadowWordPain].ready then
        return classtable.ShadowWordPain
    end
    --Mindgames (if talented)
    if talents[classtable.Mindgames] and cooldown[classtable.Mindgames].ready then
        return classtable.Mindgames
    end
    if cooldown[classtable.Penance].ready then
        return classtable.Penance
    end
    if cooldown[classtable.MindBlast].ready then
        return classtable.MindBlast
    end
    if talents[classtable.DivineStar] and cooldown[classtable.DivineStar].ready then
        return classtable.DivineStar
    end
    if talents[classtable.Halo] and cooldown[classtable.Halo].ready then
        return classtable.Halo
    end
    if cooldown[classtable.Smite].ready then
        return classtable.Smite
    end
end

--Multiple-Target Rotation
function Priest:DisciplineMultiTarget()
    if talents[classtable.PurgetheWicked] and debuff[classtable.PurgetheWickedDot].refreshable and cooldown[classtable.PurgetheWicked].ready then
        return classtable.PurgetheWicked
    end
    if not talents[classtable.PurgetheWicked] and debuff[classtable.ShadowWordPain].refreshable and cooldown[classtable.ShadowWordPain].ready then
        return classtable.ShadowWordPain
    end
    --Mindgames (if talented)
    if talents[classtable.Mindgames] and cooldown[classtable.Mindgames].ready then
        return classtable.Mindgames
    end
    if cooldown[classtable.Penance].ready then
        return classtable.Penance
    end
    if cooldown[classtable.MindBlast].ready then
        return classtable.MindBlast
    end
    if talents[classtable.DivineStar] and cooldown[classtable.DivineStar].ready then
        return classtable.DivineStar
    end
    if talents[classtable.Halo] and cooldown[classtable.Halo].ready then
        return classtable.Halo
    end
    if cooldown[classtable.Smite].ready then
        return classtable.Smite
    end
end
