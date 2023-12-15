
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

function Priest:Shadow()
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
	insanity = UnitPower('player', Enum.PowerType.Insanity)
    targetHP = UnitHealth('target')
    targetmaxHP = UnitHealthMax('target')
    targethealthPerc = (targetHP / targetmaxHP) * 100
    curentHP = UnitHealth('player')
    maxHP = UnitHealthMax('player')
    healthPerc = (curentHP / maxHP) * 100
    classtable = MaxDps.SpellTable
	classtable.MindSpikeInsanity = 407466
	classtable.MindSpikeInsanityBuff = 407468
	classtable.MindFlayInsanity = 391403
    classtable.MindDevourerBuff = 373204
    classtable.VoidBolt = 205448
    classtable.VoidformBuff = 194249
	--setmetatable(classtable, Priest.spellMeta)
    --if targets > 1  then
    --    return Priest:ShadowMultiTarget()
    --end
    return Priest:ShadowSingleTarget()
end

--optional abilities list

--Single-Target Rotation
function Priest:ShadowSingleTarget()
	--Keep Vampiric Touch and Shadow Word: Pain active by using Vampiric Touch to apply both DoTs. Use Shadow Crash if available when you need to refresh and you do not need to hold for adds coming in less than 15 seconds. Refresh these during the proper pandemic window (see below).
	if talents[classtable.ShadowCrash] and (debuff[classtable.VampiricTouch].refreshable or debuff[classtable.ShadowWordPain].refreshable) and cooldown[classtable.ShadowCrash].ready then
		return classtable.ShadowCrash
	end
	if (debuff[classtable.VampiricTouch].refreshable or debuff[classtable.ShadowWordPain].refreshable) and cooldown[classtable.VampiricTouch].ready then
		return classtable.VampiricTouch
	end
	--Cast Mindbender.
    if talents[classtable.Mindbender] and cooldown[classtable.Mindbender].ready then
        return classtable.Mindbender
    end
	--Cast Void Eruption to enter Voidform. Make sure Mind Blast charges are on cooldown before entering Voidform.
    if talents[classtable.VoidEruption] and (not cooldown[classtable.MindBlast].ready) and cooldown[classtable.VoidEruption].ready then
        return classtable.VoidEruption
    end
	--Cast Dark Ascension.
    if talents[classtable.DarkAscension] and cooldown[classtable.DarkAscension].ready then
        return classtable.DarkAscension
    end
	--Cast Power Infusion.
    if talents[classtable.PowerInfusion] and cooldown[classtable.PowerInfusion].ready then
        return classtable.PowerInfusion
    end
	--Spend Insanity on Devouring Plague. Spread this DoT around to all available targets with Distorted Reality while continuing to focus targets that have the DoT active. Maintain maximum uptime on the DoT without capping on Insanity.
	if talents[classtable.DevouringPlague] and (insanity >= 50 or buff[classtable.MindDevourerBuff].up ) and cooldown[classtable.DevouringPlague].ready then
		return classtable.DevouringPlague
	end
	--Cast Shadow Word: Death if Mindbender is active with the Priest Shadow 10.2 Class Set 2pc or you have the Priest Shadow 10.2 Class Set 4pc regardless of the state of Mindbender.
    if talents[classtable.ShadowWordDeath] and (talents[classtable.Mindbender] and cooldown[classtable.Mindbender].duration >= 45 and (MaxDps.Tier and MaxDps.Tier[31].count >= 2) or (talents[classtable.Mindbender] and MaxDps.Tier and MaxDps.Tier[31].count >= 4)) and cooldown[classtable.ShadowWordDeath].ready then
        return classtable.ShadowWordDeath
    end
	--Cast Mind Blast if Mindbender is active and you are capped on charges or will cap charges soon. Cast at high priority if Mindbender will expire otherwise (2 seconds or less).
    if talents[classtable.Mindbender] and (cooldown[classtable.Mindbender].duration >= 45 and ((talents[classtable.ThoughtHarvester] and cooldown[classtable.MindBlast].charges >= 1) or (not talents[classtable.ThoughtHarvester] and cooldown[classtable.MindBlast].ready))) and cooldown[classtable.MindBlast].ready then
        return classtable.MindBlast
    end
	--Cast Void Bolt.
    if talents[classtable.VoidEruption] and buff[classtable.VoidformBuff].up and cooldown[classtable.VoidBolt].ready then
        return classtable.VoidBolt
    end
	--Cast Shadow Word: Death if still available and you have the Priest Shadow 10.2 Class Set 2pc equipped.
    if talents[classtable.ShadowWordDeath] and MaxDps.Tier and MaxDps.Tier[31].count >= 2 and cooldown[classtable.ShadowWordDeath].ready then
        return classtable.ShadowWordDeath
    end
	--Cast Shadow Crash with the Priest Shadow 10.2 Class Set 4pc if you have 10 or more stacks of Death's Torment and you are not holding for upcoming adds.
    if talents[classtable.ShadowCrash] and MaxDps.Tier and MaxDps.Tier[31].count >= 4 and buff[classtable.DeathsTorment].count >= 10 and cooldown[classtable.ShadowCrash].ready then
        return classtable.ShadowCrash
    end
	--Cast Shadow Word: Pain with the Priest Shadow 10.2 Class Set 4pc if you have 10 or more stacks of Death's Torment and Shadow Crash is unavailable, and you are not holding for adds.
    if MaxDps.Tier and MaxDps.Tier[31].count >= 4 and buff[classtable.DeathsTorment].count >= 10 and not cooldown[classtable.ShadowCrash].ready and cooldown[classtable.ShadowWordPain].ready then
        return classtable.ShadowWordPain
    end
	--Cast Mind Blast if Mind Devourer is not active.
    if (talents[classtable.MindDevourer] and not buff[classtable.MindDevourerBuff].up) and cooldown[classtable.MindBlast].ready then
        return classtable.MindBlast
    end
	--Cast Void Torrent if you are not saving for adds coming soon, and Devouring Plague will last for at least 2.5 seconds or you are facing multiple targets. You can interrupt the channel ONLY if Shadow Word: Death is available and Mindbender is active with the Priest Shadow 10.2 Class Set 2pc.
    if talents[classtable.VoidTorrent] and timetodie >= 2.5 and cooldown[classtable.VoidTorrent].ready then
        return classtable.VoidTorrent
    end
	--Cast Vampiric Touch to consume Unfurling Darkness.
	if talents[classtable.UnfurlingDarkness] and buff[classtable.UnfurlingDarknessBuff].up and cooldown[classtable.VampiricTouch].ready then
        return classtable.VampiricTouch
    end
	--Cast Mind Spike: Insanity.
	if talents[classtable.SurgeofInsanity] and buff[classtable.MindSpikeInsanityBuff].up and cooldown[classtable.MindSpikeInsanity].ready then
        return classtable.MindSpike
    end
	--Cast Mindgames.
    if talents[classtable.Mindgames] and cooldown[classtable.Mindgames].ready then
        return classtable.Mindgames
    end
	--Cast Halo if it will hit at least 2 targets.
    if talents[classtable.Halo] and targets >= 2 and cooldown[classtable.Halo].ready then
        return classtable.Halo
    end
	--Cast Mind Spike.
    if talents[classtable.MindSpike] and cooldown[classtable.MindSpike].ready then
        return classtable.MindSpike
    end
    if talents[classtable.DivineStar] and cooldown[classtable.DivineStar].ready then
        return classtable.DivineStar
    end
    if cooldown[classtable.ShadowWordPain].ready then
        return classtable.ShadowWordPain
    end
end

--Multiple-Target Rotation
function Priest:ShadowMultiTarget()

end
