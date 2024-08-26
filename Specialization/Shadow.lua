local _, addonTable = ...
local Priest = addonTable.Priest
local MaxDps = _G.MaxDps
if not MaxDps then return end

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

local dr_force_prio
local me_force_prio
local max_vts
local is_vt_possible
local pooling_mindblasts
local holding_crash
local pool_for_cds
local dots_up
local manual_vts_applied

local function GetTotemDuration(name)
    for index=1,MAX_TOTEMS do
        local arg1, totemName, startTime, duration, icon = GetTotemInfo(index)
        local est_dur = math.floor(startTime+duration-GetTime())
        if (totemName == name and est_dur and est_dur > 0) then return est_dur else return 0 end
    end
end

function Shadow:precombat()
    --if (MaxDps:CheckSpellUsable(classtable.Shadowform, 'Shadowform')) and (not buff[classtable.ShadowformBuff].up) and cooldown[classtable.Shadowform].ready then
    --    return classtable.Shadowform
    --end
    dr_force_prio = 0
    me_force_prio = 1
    max_vts = 0
    is_vt_possible = 0
    pooling_mindblasts = 0
    --if (MaxDps:CheckSpellUsable(classtable.ShadowCrash, 'ShadowCrash')) and (math.huge >= 25 and targets <= 8 and ( not (MaxDps.tier and MaxDps.tier[31].count >= 4) or targets >1 )) and cooldown[classtable.ShadowCrash].ready then
    --    return classtable.ShadowCrash
    --end
    --if (MaxDps:CheckSpellUsable(classtable.VampiricTouch, 'VampiricTouch')) and (not talents[classtable.ShadowCrash] or math.huge <25 or targets >8 or (MaxDps.tier and MaxDps.tier[31].count >= 4) and targets == 1) and cooldown[classtable.VampiricTouch].ready then
    --    return classtable.VampiricTouch
    --end
end
function Shadow:aoe()
    local aoe_variablesCheck = Shadow:aoe_variables()
    if aoe_variablesCheck then
        return aoe_variablesCheck
    end
    if (MaxDps:CheckSpellUsable(classtable.VampiricTouch, 'VampiricTouch')) and (( debuff[classtable.VampiricTouchDeBuff].refreshable and ttd >= 18 and ( debuff[classtable.VampiricTouchDeBuff].up or not dots_up ) ) and ( ( max_vts >0 and not manual_vts_applied and not (classtable and classtable.ShadowCrash and GetSpellCooldown(classtable.ShadowCrash).duration >=5 ) or not talents[classtable.WhisperingShadows] ) and not buff[classtable.EntropicRiftBuff].up )) and cooldown[classtable.VampiricTouch].ready then
        return classtable.VampiricTouch
    end
    if (MaxDps:CheckSpellUsable(classtable.ShadowCrash, 'ShadowCrash')) and (not holding_crash and ( debuff[classtable.VampiricTouchDeBuff].refreshable or debuff[classtable.VampiricTouchDeBuff].remains <= ttd and not buff[classtable.VoidformBuff].up and ( math.huge - debuff[classtable.VampiricTouchDeBuff].remains ) <15 )) and cooldown[classtable.ShadowCrash].ready then
        return classtable.ShadowCrash
    end
end
function Shadow:main()
    if targets <3 then
        dots_up = true--debuff[classtable.VampiricTouchDebuff].count  == targets or (classtable and classtable.ShadowCrash and GetSpellCooldown(classtable.ShadowCrash).duration >=5 ) and talents[classtable.WhisperingShadows]
    end
    if talents[classtable.VoidBlast] and ( cooldown[classtable.VoidTorrent].remains <( holding_crash * math.huge ) ) <= gcd * ( 1 + (talents[classtable.MindMelt] and talents[classtable.MindMelt] or 0) * 3 ) then
        pooling_mindblasts = 1
    else
        pooling_mindblasts = 0
    end
    if (MaxDps:boss() and ttd <30 or ttd >15 and ( not holding_crash or targets >2 )) then
        local cdsCheck = Shadow:cds()
        if cdsCheck then
            return Shadow:cds()
        end
    end
    if (MaxDps:CheckSpellUsable(classtable.Mindbender, 'Mindbender')) and (( debuff[classtable.ShadowWordPainDeBuff].up and dots_up or (classtable and classtable.ShadowCrash and GetSpellCooldown(classtable.ShadowCrash).duration >=5 ) and talents[classtable.WhisperingShadows] ) and ( MaxDps:boss() and ttd <30 or ttd >15 ) and ( not talents[classtable.DarkAscension] or cooldown[classtable.DarkAscension].remains <gcd or MaxDps:boss() and ttd <15 )) and cooldown[classtable.Mindbender].ready then
        return classtable.Mindbender
    end
    if (MaxDps:CheckSpellUsable(classtable.ShadowWordDeath, 'ShadowWordDeath')) and (true and talents[classtable.DevourMatter]) and cooldown[classtable.ShadowWordDeath].ready then
        return classtable.ShadowWordDeath
    end
    if (MaxDps:CheckSpellUsable(classtable.VoidBlast, 'VoidBlast')) and (not talents[classtable.MindDevourer] or not buff[classtable.MindDevourerBuff].up or buff[classtable.EntropicRiftBuff].remains <= gcd) and cooldown[classtable.VoidBlast].ready then
        return classtable.VoidBlast
    end
    if (MaxDps:CheckSpellUsable(classtable.MindBlast, 'MindBlast')) and (buff[classtable.VoidformBuff].up and cooldown[classtable.MindBlast].fullRecharge <= gcd and ( not talents[classtable.InsidiousIre] or debuff[classtable.DevouringPlagueDeBuff].remains >= timeShift ) and ((( cooldown[classtable.VoidBolt].remains % gcd - cooldown[classtable.VoidBolt].remains % gcd ) * gcd <= 0.25 and (cooldown[classtable.VoidBolt].remains % gcd - cooldown[classtable.VoidBolt].remains % gcd ) >= 0.01)) or true) and cooldown[classtable.MindBlast].ready then
        return classtable.MindBlast
    end
    if (MaxDps:CheckSpellUsable(classtable.VoidBolt, 'VoidBolt')) and (InsanityDeficit >16 and cooldown[classtable.VoidBolt].remains <= 0.1) and cooldown[classtable.VoidBolt].ready then
        return classtable.VoidBolt
    end
    if (MaxDps:CheckSpellUsable(classtable.DevouringPlague, 'DevouringPlague')) and (debuff[classtable.DevouringPlagueDeBuff].count  <= 1 and debuff[classtable.DevouringPlagueDeBuff].remains <= gcd and ( not talents[classtable.VoidEruption] or cooldown[classtable.VoidEruption].remains >= gcd * 3 ) or InsanityDeficit <= 16) and cooldown[classtable.DevouringPlague].ready then
        return classtable.DevouringPlague
    end
    if (MaxDps:CheckSpellUsable(classtable.VoidTorrent, 'VoidTorrent')) and (( debuff[classtable.DevouringPlagueDeBuff].up or talents[classtable.VoidEruption] and cooldown[classtable.VoidEruption].ready ) and talents[classtable.EntropicRift] and not holding_crash) and cooldown[classtable.VoidTorrent].ready then
        return classtable.VoidTorrent
    end
    if (MaxDps:CheckSpellUsable(classtable.ShadowWordDeath, 'ShadowWordDeath')) and (talents[classtable.DepthofShadows]) and cooldown[classtable.ShadowWordDeath].ready then
        return classtable.ShadowWordDeath
    end
    if (MaxDps:CheckSpellUsable(classtable.MindBlast, 'MindBlast')) and (( cooldown[classtable.MindBlast].fullRecharge <= gcd + timeShift or GetTotemDuration('fiend') <= timeShift + gcd ) and ( UnitExists('pet') and UnitName('pet')  == 'fiend' ) and talents[classtable.InescapableTorment] and GetTotemDuration('fiend') >= timeShift and targets <= 7 and ( not buff[classtable.MindDevourerBuff].up or not talents[classtable.MindDevourer] ) and debuff[classtable.DevouringPlagueDeBuff].remains >timeShift and not pooling_mindblasts) and cooldown[classtable.MindBlast].ready then
        return classtable.MindBlast
    end
    if (MaxDps:CheckSpellUsable(classtable.ShadowWordDeath, 'ShadowWordDeath')) and (GetTotemDuration('fiend') <= ( gcd + 1 ) and ( UnitExists('pet') and UnitName('pet')  == 'fiend' ) and talents[classtable.InescapableTorment] and targets <= 7) and cooldown[classtable.ShadowWordDeath].ready then
        return classtable.ShadowWordDeath
    end
    if (MaxDps:CheckSpellUsable(classtable.VoidBolt, 'VoidBolt')) and (cooldown[classtable.VoidBolt].remains <= 0.1) and cooldown[classtable.VoidBolt].ready then
        return classtable.VoidBolt
    end
    if (( buff[classtable.MindSpikeInsanityBuff].count >2 and talents[classtable.MindSpike] or buff[classtable.MindFlayInsanityBuff].count >2 and not talents[classtable.MindSpike] ) and talents[classtable.EmpoweredSurges] and not cooldown[classtable.VoidEruption].ready) then
        local empowered_fillerCheck = Shadow:empowered_filler()
        if empowered_fillerCheck then
            return Shadow:empowered_filler()
        end
    end
    if (MaxDps:CheckSpellUsable(classtable.DevouringPlague, 'DevouringPlague')) and (MaxDps:boss() and ttd <= ( classtable and classtable.DevouringPlague and GetSpellInfo(classtable.DevouringPlague).castTime /1000 ) + 4) and cooldown[classtable.DevouringPlague].ready then
        return classtable.DevouringPlague
    end
    if (MaxDps:CheckSpellUsable(classtable.DevouringPlague, 'DevouringPlague')) and (InsanityDeficit <= 35 and talents[classtable.DistortedReality] or buff[classtable.DarkAscensionBuff].up or buff[classtable.MindDevourerBuff].up and cooldown[classtable.MindBlast].ready and ( cooldown[classtable.VoidEruption].remains >= 3 * gcd or not talents[classtable.VoidEruption] ) or buff[classtable.EntropicRiftBuff].up) and cooldown[classtable.DevouringPlague].ready then
        return classtable.DevouringPlague
    end
    if (MaxDps:CheckSpellUsable(classtable.VoidTorrent, 'VoidTorrent')) and (not holding_crash and not talents[classtable.EntropicRift] and debuff[classtable.DevouringPlagueDeBuff].remains >= 2.5) and cooldown[classtable.VoidTorrent].ready then
        return classtable.VoidTorrent
    end
    if (MaxDps:CheckSpellUsable(classtable.ShadowCrash, 'ShadowCrash')) and (debuff[classtable.VampiricTouchDeBuff].refreshable and not holding_crash) and cooldown[classtable.ShadowCrash].ready then
        return classtable.ShadowCrash
    end
    if (MaxDps:CheckSpellUsable(classtable.VampiricTouch, 'VampiricTouch')) and (debuff[classtable.VampiricTouchDeBuff].refreshable and ttd >12 and ( debuff[classtable.VampiricTouchDeBuff].up or not dots_up ) and ( max_vts >0 or targets == 1 ) and ( cooldown[classtable.ShadowCrash].remains >= debuff[classtable.VampiricTouchDeBuff].remains or holding_crash or not talents[classtable.WhisperingShadows] ) and ( not (classtable and classtable.ShadowCrash and GetSpellCooldown(classtable.ShadowCrash).duration >=5 ) or not talents[classtable.WhisperingShadows] )) and cooldown[classtable.VampiricTouch].ready then
        return classtable.VampiricTouch
    end
    if (MaxDps:CheckSpellUsable(classtable.ShadowWordDeath, 'ShadowWordDeath')) and (dots_up and buff[classtable.DeathspeakerBuff].up) and cooldown[classtable.ShadowWordDeath].ready then
        return classtable.ShadowWordDeath
    end
    if (MaxDps:CheckSpellUsable(classtable.MindBlast, 'MindBlast')) and (( not buff[classtable.MindDevourerBuff].up or not talents[classtable.MindDevourer] or cooldown[classtable.VoidEruption].ready and talents[classtable.VoidEruption] ) and not pooling_mindblasts) and cooldown[classtable.MindBlast].ready then
        return classtable.MindBlast
    end
    local fillerCheck = Shadow:filler()
    if fillerCheck then
        return fillerCheck
    end
end
function Shadow:aoe_variables()
    max_vts = targets
    is_vt_possible = 1
    if ttd >= 18 and debuff[classtable.VampiricTouchDeBuff].refreshable then
        is_vt_possible = 1
    end
    dots_up = true--( debuff[classtable.VampiricTouchDebuff].count  + 8 * ( (classtable and classtable.ShadowCrash and GetSpellCooldown(classtable.ShadowCrash).duration >=5 ) and talents[classtable.WhisperingShadows] ) ) >= max_vts or not is_vt_possible
    if holding_crash and talents[classtable.WhisperingShadows] and (targets >1) then
        holding_crash = ( max_vts - debuff[classtable.VampiricTouchDeBuff].count  ) <4 and math.huge >15 or math.huge <10 and 1 >( max_vts - debuff[classtable.VampiricTouchDeBuff].count  )
    end
    manual_vts_applied = ( debuff[classtable.VampiricTouchDeBuff].count  + 8 * (not holding_crash and 1 or 0) ) >= (max_vts and 1 or 0) or not is_vt_possible
end
function Shadow:cds()
    if (MaxDps:CheckSpellUsable(classtable.PowerInfusion, 'PowerInfusion')) and (( buff[classtable.VoidformBuff].up or buff[classtable.DarkAscensionBuff].up and ( MaxDps:boss() and ttd <= 80 or ttd >= 140 ) )) and cooldown[classtable.PowerInfusion].ready then
        MaxDps:GlowCooldown(classtable.PowerInfusion, cooldown[classtable.PowerInfusion].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.Halo, 'Halo')) and (talents[classtable.PowerSurge] and ( ( UnitExists('pet') and UnitName('pet')  == 'fiend' ) and cooldown[classtable.Fiend].remains >= 4 and talents[classtable.Mindbender] or not talents[classtable.Mindbender] and not cooldown[classtable.Fiend].ready or targets >2 and not talents[classtable.InescapableTorment] or not talents[classtable.DarkAscension] ) and ( cooldown[classtable.MindBlast].charges == 0 or not talents[classtable.VoidEruption] or cooldown[classtable.VoidEruption].remains >= gcd * 4 )) and cooldown[classtable.Halo].ready then
        return classtable.Halo
    end
    if (MaxDps:CheckSpellUsable(classtable.VoidEruption, 'VoidEruption')) and (not cooldown[classtable.Fiend].ready and ( ( UnitExists('pet') and UnitName('pet')  == 'fiend' ) and cooldown[classtable.Fiend].remains >= 4 or not talents[classtable.Mindbender] or targets >2 and not talents[classtable.InescapableTorment] ) and ( cooldown[classtable.MindBlast].charges == 0 or timeInCombat >15 )) and cooldown[classtable.VoidEruption].ready then
        return classtable.VoidEruption
    end
    if (MaxDps:CheckSpellUsable(classtable.DarkAscension, 'DarkAscension')) and (( UnitExists('pet') and UnitName('pet')  == 'fiend' ) and cooldown[classtable.Fiend].remains >= 4 or not talents[classtable.Mindbender] and not cooldown[classtable.Fiend].ready or targets >2 and not talents[classtable.InescapableTorment]) and cooldown[classtable.DarkAscension].ready then
        return classtable.DarkAscension
    end
    local trinketsCheck = Shadow:trinkets()
    if trinketsCheck then
        return trinketsCheck
    end
    --if (MaxDps:CheckSpellUsable(classtable.DesperatePrayer, 'DesperatePrayer')) and (curentHP <= 75) and cooldown[classtable.DesperatePrayer].ready then
    --    return classtable.DesperatePrayer
    --end
end
function Shadow:filler()
    if (MaxDps:CheckSpellUsable(classtable.VampiricTouch, 'VampiricTouch')) and (buff[classtable.UnfurlingDarknessBuff].up) and cooldown[classtable.VampiricTouch].ready then
        return classtable.VampiricTouch
    end
    if (debuff[classtable.DevouringPlagueDeBuff].remains >( classtable and classtable.MindSpike and GetSpellInfo(classtable.MindSpike).castTime / 1000 ) or not talents[classtable.MindSpike]) then
        local empowered_fillerCheck = Shadow:empowered_filler()
        if empowered_fillerCheck then
            return Shadow:empowered_filler()
        end
    end
    if (MaxDps:CheckSpellUsable(classtable.ShadowWordDeath, 'ShadowWordDeath')) and (targetHP <20 or ( buff[classtable.DeathspeakerBuff].up or (MaxDps.tier and MaxDps.tier[31].count >= 2) ) and debuff[classtable.DevouringPlagueDeBuff].up) and cooldown[classtable.ShadowWordDeath].ready then
        return classtable.ShadowWordDeath
    end
    if (MaxDps:CheckSpellUsable(classtable.ShadowWordDeath, 'ShadowWordDeath')) and (talents[classtable.InescapableTorment] and ( UnitExists('pet') and UnitName('pet')  == 'fiend' )) and cooldown[classtable.ShadowWordDeath].ready then
        return classtable.ShadowWordDeath
    end
    if (MaxDps:CheckSpellUsable(classtable.DevouringPlague, 'DevouringPlague')) and (buff[classtable.VoidformBuff].up or cooldown[classtable.DarkAscension].ready or buff[classtable.MindDevourerBuff].up) and cooldown[classtable.DevouringPlague].ready then
        return classtable.DevouringPlague
    end
    if (MaxDps:CheckSpellUsable(classtable.Halo, 'Halo')) and (targets >1) and cooldown[classtable.Halo].ready then
        return classtable.Halo
    end
    local empowered_fillerCheck = Shadow:empowered_filler()
    if empowered_fillerCheck then
        return empowered_fillerCheck
    end
    if (MaxDps:CheckSpellUsable(classtable.MindSpike, 'MindSpike')) and talents[classtable.MindSpike] and cooldown[classtable.MindSpike].ready then
        return classtable.MindSpike
    end
    if (MaxDps:CheckSpellUsable(classtable.MindFlay, 'MindFlay')) and not talents[classtable.MindSpike] and cooldown[classtable.MindFlay].ready then
        return classtable.MindFlay
    end
    if (MaxDps:CheckSpellUsable(classtable.DivineStar, 'DivineStar')) and cooldown[classtable.DivineStar].ready then
        return classtable.DivineStar
    end
    if (MaxDps:CheckSpellUsable(classtable.ShadowCrash, 'ShadowCrash')) and (math.huge >20 and not (MaxDps.tier and MaxDps.tier[31].count >= 4)) and cooldown[classtable.ShadowCrash].ready then
        return classtable.ShadowCrash
    end
    if (MaxDps:CheckSpellUsable(classtable.ShadowWordDeath, 'ShadowWordDeath')) and (targetHP <20) and cooldown[classtable.ShadowWordDeath].ready then
        return classtable.ShadowWordDeath
    end
    if (MaxDps:CheckSpellUsable(classtable.ShadowWordDeath, 'ShadowWordDeath')) and cooldown[classtable.ShadowWordDeath].ready then
        return classtable.ShadowWordDeath
    end
    if (MaxDps:CheckSpellUsable(classtable.ShadowWordPain, 'ShadowWordPain')) and ((MaxDps.tier and MaxDps.tier[31].count >= 4)) and cooldown[classtable.ShadowWordPain].ready then
        return classtable.ShadowWordPain
    end
    if (MaxDps:CheckSpellUsable(classtable.ShadowWordPain, 'ShadowWordPain')) and (not (MaxDps.tier and MaxDps.tier[31].count >= 4)) and cooldown[classtable.ShadowWordPain].ready then
        return classtable.ShadowWordPain
    end
end
function Shadow:empowered_filler()
    if (MaxDps:CheckSpellUsable(classtable.MindSpikeInsanity, 'MindSpikeInsanity')) and cooldown[classtable.MindSpikeInsanity].ready then
        return classtable.MindSpikeInsanity
    end
    if (MaxDps:CheckSpellUsable(classtable.MindFlayInsanity, 'MindFlayInsanity')) and (buff[classtable.MindFlayInsanityBuff].up) and cooldown[classtable.MindFlayInsanity].ready then
        return classtable.MindFlayInsanity
    end
end
function Shadow:trinkets()
end

function Shadow:callaction()
    if (MaxDps:CheckSpellUsable(classtable.Silence, 'Silence')) and cooldown[classtable.Silence].ready then
        MaxDps:GlowCooldown(classtable.Silence, ( select(8,UnitCastingInfo('target')) ~= nil and not select(8,UnitCastingInfo('target')) or select(7,UnitChannelInfo('target')) ~= nil and not select(7,UnitChannelInfo('target'))) )
    end
    holding_crash = math.huge <15
    pool_for_cds = ( cooldown[classtable.VoidEruption].remains <= gcd * 3 and talents[classtable.VoidEruption] or cooldown[classtable.DarkAscension].ready and talents[classtable.DarkAscension] ) or talents[classtable.VoidTorrent] and talents[classtable.PsychicLink] and cooldown[classtable.VoidTorrent].remains <= 4 and ( (targets <2) and targets >1 or math.huge <= 5 or targets >= 6 and not holding_crash ) and not buff[classtable.VoidformBuff].up
    if (targets >2) then
        local aoeCheck = Shadow:aoe()
        if aoeCheck then
            return Shadow:aoe()
        end
    end
    local mainCheck = Shadow:main()
    if mainCheck then
        return mainCheck
    end
    local aoe_variablesCheck = Shadow:aoe_variables()
    if aoe_variablesCheck then
        return aoe_variablesCheck
    end
    if (MaxDps:boss() and ttd <30 or ttd >15 and ( not holding_crash or targets >2 )) then
        local cdsCheck = Shadow:cds()
        if cdsCheck then
            return Shadow:cds()
        end
    end
    if (( buff[classtable.MindSpikeInsanityBuff].count >2 and talents[classtable.MindSpike] or buff[classtable.MindFlayInsanityBuff].count >2 and not talents[classtable.MindSpike] ) and talents[classtable.EmpoweredSurges] and not cooldown[classtable.VoidEruption].ready) then
        local empowered_fillerCheck = Shadow:empowered_filler()
        if empowered_fillerCheck then
            return Shadow:empowered_filler()
        end
    end
    --if (not buff[classtable.TwistofFateBuff].up and ( talents[classtable.Rhapsody] or talents[classtable.DivineStar] or talents[classtable.Halo] )) then
    --    local heal_for_tofCheck = Shadow:heal_for_tof()
    --    if heal_for_tofCheck then
    --        return Shadow:heal_for_tof()
    --    end
    --end
    local fillerCheck = Shadow:filler()
    if fillerCheck then
        return fillerCheck
    end
    local trinketsCheck = Shadow:trinkets()
    if trinketsCheck then
        return trinketsCheck
    end
    --if (not buff[classtable.TwistofFateBuff].up and ( talents[classtable.Rhapsody] or talents[classtable.DivineStar] or talents[classtable.Halo] )) then
    --    local heal_for_tofCheck = Shadow:heal_for_tof()
    --    if heal_for_tofCheck then
    --        return Shadow:heal_for_tof()
    --    end
    --end
    if (debuff[classtable.DevouringPlagueDeBuff].remains >( classtable and classtable.MindSpike and GetSpellInfo(classtable.MindSpike).castTime / 1000 ) or not talents[classtable.MindSpike]) then
        local empowered_fillerCheck = Shadow:empowered_filler()
        if empowered_fillerCheck then
            return Shadow:empowered_filler()
        end
    end
    local empowered_fillerCheck = Shadow:empowered_filler()
    if empowered_fillerCheck then
        return empowered_fillerCheck
    end
    --if (line_cd == 5) then
    --    local heal_for_tofCheck = Shadow:heal_for_tof()
    --    if heal_for_tofCheck then
    --        return Shadow:heal_for_tof()
    --    end
    --end
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
    targethealthPerc = (targetHP / targetmaxHP) * 100
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
    classtable.VoidBolt = 228266
    for spellId in pairs(MaxDps.Flags) do
        self.Flags[spellId] = false
        self:ClearGlowIndependent(spellId, spellId)
    end
    classtable.ShadowformBuff = 232698
    classtable.VampiricTouchDeBuff = 34914
    classtable.EntropicRiftBuff = 0
    classtable.VoidformBuff = 232698
    classtable.ShadowWordPainDeBuff = 589
    classtable.MindDevourerBuff = 373204
    classtable.DevouringPlagueDeBuff = 335467
    classtable.MindSpikeInsanityBuff = 407466
    classtable.MindFlayInsanityBuff = 391401
    classtable.DarkAscensionBuff = 391109
    classtable.DeathspeakerBuff = 392511
    classtable.UnfurlingDarknessBuff = 341282
    classtable.TwistofFateBuff = 390978
    classtable.Mindbender = talents[200174] and 200174 or 34433
    classtable.MindFlayInsanity = 391403
    classtable.MindSpikeInsanity = 407466
    classtable.ShadowCrash = MaxDps:FindSpell(205385) and 205385 or MaxDps:FindSpell(457042) and 457042

    local precombatCheck = Shadow:precombat()
    if precombatCheck then
        return Shadow:precombat()
    end

    local callactionCheck = Shadow:callaction()
    if callactionCheck then
        return Shadow:callaction()
    end
end
