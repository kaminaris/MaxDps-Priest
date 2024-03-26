local _, addonTable = ...
local Priest = addonTable.Priest
local MaxDps = _G.MaxDps
if not MaxDps then return end

local UnitPower = UnitPower
local UnitHealth = UnitHealth
local UnitAura = UnitAura
local GetSpellDescription = GetSpellDescription
local UnitHealthMax = UnitHealthMax
local UnitPowerMax = UnitPowerMax
local SpellHaste
local SpellCrit

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

local Insanity
local InsanityMax
local InsanityDeficit
local Mana
local ManaMax
local ManaDeficit

local Shadow = {}

local holding_crash
local pool_for_cds
local max_vts
local is_vt_possible
local dots_up
local manual_vts_applied

local function CheckSpellCosts(spell,spellstring)
    if not IsSpellKnownOrOverridesKnown(spell) then return false end
    if spellstring == 'TouchofDeath' then
        if targethealthPerc < 15 then
            return true
        else
            return false
        end
    end
    local costs = GetSpellPowerCost(spell)
    if type(costs) ~= 'table' and spellstring then print('no cost found for ',spellstring) return true end
    for i,costtable in pairs(costs) do
        if UnitPower('player', costtable.type) < costtable.cost then
            return false
        end
    end
    return true
end



local function CheckEquipped(checkName)
    for i=1,14 do
        local itemID = GetInventoryItemID('player', i)
        local itemName = itemID and C_Item.GetItemInfo(itemID) or ''
        if checkName == itemName then
            return true
        end
    end
    return false
end




local function CheckTrinketNames(checkName)
    --if slot == 1 then
    --    slot = 13
    --end
    --if slot == 2 then
    --    slot = 14
    --end
    for i=13,14 do
        local itemID = GetInventoryItemID('player', i)
        local itemName = C_Item.GetItemInfo(itemID)
        if checkName == itemName then
            return true
        end
    end
    return false
end


local function CheckTrinketCooldown(slot)
    if slot == 1 then
        slot = 13
    end
    if slot == 2 then
        slot = 14
    end
    if slot == 13 or slot == 14 then
        local itemID = GetInventoryItemID('player', slot)
        local _, duration, _ = C_Item.GetItemCooldown(itemID)
        if duration == 0 then return true else return false end
    else
        local tOneitemID = GetInventoryItemID('player', 13)
        local tTwoitemID = GetInventoryItemID('player', 14)
        local tOneitemName = C_Item.GetItemInfo(tOneitemID)
        local tTwoitemName = C_Item.GetItemInfo(tTwoitemID)
        if tOneitemName == slot then
            local _, duration, _ = C_Item.GetItemCooldown(tOneitemID)
            if duration == 0 then return true else return false end
        end
        if tTwoitemName == slot then
            local _, duration, _ = C_Item.GetItemCooldown(tTwoitemID)
            if duration == 0 then return true else return false end
        end
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
    if (MaxDps:FindSpell(classtable.Flask) and CheckSpellCosts(classtable.Flask, 'Flask')) and cooldown[classtable.Flask].ready then
        return classtable.Flask
    end
    if (MaxDps:FindSpell(classtable.Food) and CheckSpellCosts(classtable.Food, 'Food')) and cooldown[classtable.Food].ready then
        return classtable.Food
    end
    if (MaxDps:FindSpell(classtable.Augmentation) and CheckSpellCosts(classtable.Augmentation, 'Augmentation')) and cooldown[classtable.Augmentation].ready then
        return classtable.Augmentation
    end
    if (MaxDps:FindSpell(classtable.SnapshotStats) and CheckSpellCosts(classtable.SnapshotStats, 'SnapshotStats')) and cooldown[classtable.SnapshotStats].ready then
        return classtable.SnapshotStats
    end
    if (MaxDps:FindSpell(classtable.Shadowform) and CheckSpellCosts(classtable.Shadowform, 'Shadowform')) and (not buff[classtable.ShadowformBuff].up) and cooldown[classtable.Shadowform].ready then
        return classtable.Shadowform
    end
    if (MaxDps:FindSpell(classtable.ShadowCrash) and CheckSpellCosts(classtable.ShadowCrash, 'ShadowCrash')) and (targets <= 8 and not (select(2,IsInInstance()) == 'party') and ( not (MaxDps.tier and MaxDps.tier[31].count >= 4) or targets >1 )) and cooldown[classtable.ShadowCrash].ready then
        return classtable.ShadowCrash
    end
    if (MaxDps:FindSpell(classtable.VampiricTouch) and CheckSpellCosts(classtable.VampiricTouch, 'VampiricTouch')) and (not talents[classtable.ShadowCrash] or targets >8 or (select(2,IsInInstance()) == 'party') or (MaxDps.tier and MaxDps.tier[31].count >= 4) and targets == 1) and cooldown[classtable.VampiricTouch].ready then
        return classtable.VampiricTouch
    end
end
function Shadow:aoe()
    local aoe_variablesCheck = Shadow:aoe_variables()
    if aoe_variablesCheck then
        return aoe_variablesCheck
    end
    if (MaxDps:FindSpell(classtable.VampiricTouch) and CheckSpellCosts(classtable.VampiricTouch, 'VampiricTouch')) and (max_vts >0 and not manual_vts_applied and not (select(2,GetSpellCooldown(classtable.ShadowCrash)) >=5 ) or not talents[classtable.WhisperingShadows] and debuff[classtable.VampiricTouch].refreshable and ttd >= 18 and ( debuff[classtable.VampiricTouchDeBuff].up or not dots_up )) and cooldown[classtable.VampiricTouch].ready then
        return classtable.VampiricTouch
    end
    if (MaxDps:FindSpell(classtable.ShadowCrash) and CheckSpellCosts(classtable.ShadowCrash, 'ShadowCrash')) and (not holding_crash and debuff[classtable.VampiricTouchDeBuff].refreshable or debuff[classtable.VampiricTouchDeBuff].remains <= ttd and not buff[classtable.VoidformBuff].up) and cooldown[classtable.ShadowCrash].ready then
        return classtable.ShadowCrash
    end
    if (ttd <30 or ttd >15 and ( not holding_crash or targets >2 )) then
        local cdsCheck = Shadow:cds()
        if cdsCheck then
            return Shadow:cds()
        end
    end
    if (MaxDps:FindSpell(classtable.Mindbender) and CheckSpellCosts(classtable.Mindbender, 'Mindbender')) and (( debuff[classtable.ShadowWordPainDeBuff].up and dots_up or (select(2,GetSpellCooldown(classtable.ShadowCrash)) >=5 ) and talents[classtable.WhisperingShadows] ) and ( ttd <30 or ttd >15 ) and ( not talents[classtable.DarkAscension] or cooldown[classtable.DarkAscension].remains <gcd or ttd <15 )) and cooldown[classtable.Mindbender].ready then
        return classtable.Mindbender
    end
    if (MaxDps:FindSpell(classtable.DevouringPlague) and CheckSpellCosts(classtable.DevouringPlague, 'DevouringPlague')) and (talents[classtable.DistortedReality] and ( debuff[classtable.DevouringPlague].count == 0 or InsanityDeficit <= 20 ) and ttd * ( not debuff[classtable.DevouringPlagueDeBuff].up )) and cooldown[classtable.DevouringPlague].ready then
        return classtable.DevouringPlague
    end
    if (MaxDps:FindSpell(classtable.ShadowWordDeath) and CheckSpellCosts(classtable.ShadowWordDeath, 'ShadowWordDeath')) and (( (MaxDps.tier and MaxDps.tier[31].count >= 4) or ( UnitExists('pet') and UnitName('pet')  == 'fiend' ) and talents[classtable.InescapableTorment] and (MaxDps.tier and MaxDps.tier[31].count >= 2) ) and debuff[classtable.DevouringPlagueDeBuff].remains) and cooldown[classtable.ShadowWordDeath].ready then
        return classtable.ShadowWordDeath
    end
    if (MaxDps:FindSpell(classtable.MindBlast) and CheckSpellCosts(classtable.MindBlast, 'MindBlast')) and (( cooldown[classtable.MindBlast].fullRecharge <= gcd + select(4,GetSpellInfo(classtable.MindBlast))  /1000 or GetTotemDuration('fiend') <= select(4,GetSpellInfo(classtable.MindBlast))  /1000 + gcd ) and ( UnitExists('pet') and UnitName('pet')  == 'fiend' ) and talents[classtable.InescapableTorment] and GetTotemDuration('fiend') >select(4,GetSpellInfo(classtable.MindBlast))  /1000 and targets <= 7 and not buff[classtable.MindDevourerBuff].up and debuff[classtable.DevouringPlagueDeBuff].remains >MaxDps:GetTimeToPct(30) and debuff[classtable.DevouringPlagueDeBuff].remains) and cooldown[classtable.MindBlast].ready then
        return classtable.MindBlast
    end
    if (MaxDps:FindSpell(classtable.ShadowWordDeath) and CheckSpellCosts(classtable.ShadowWordDeath, 'ShadowWordDeath')) and (GetTotemDuration('fiend') <= 2 and ( UnitExists('pet') and UnitName('pet')  == 'fiend' ) and talents[classtable.InescapableTorment] and targets <= 7 and debuff[classtable.DevouringPlagueDeBuff].remains) and cooldown[classtable.ShadowWordDeath].ready then
        return classtable.ShadowWordDeath
    end
    if (MaxDps:FindSpell(classtable.VoidBolt) and CheckSpellCosts(classtable.VoidBolt, 'VoidBolt')) and cooldown[classtable.VoidBolt].ready then
        return classtable.VoidBolt
    end
    if (MaxDps:FindSpell(classtable.DevouringPlague) and CheckSpellCosts(classtable.DevouringPlague, 'DevouringPlague')) and (talents[classtable.DistortedReality] and ttd * ( not debuff[classtable.DevouringPlagueDeBuff].up )) and cooldown[classtable.DevouringPlague].ready then
        return classtable.DevouringPlague
    end
    if (MaxDps:FindSpell(classtable.DevouringPlague) and CheckSpellCosts(classtable.DevouringPlague, 'DevouringPlague')) and (( debuff[classtable.DevouringPlague].remains <= gcd and not pool_for_cds or InsanityDeficit <= 20 or buff[classtable.VoidformBuff].up and cooldown[classtable.VoidBolt].remains >buff[classtable.VoidformBuff].remains and cooldown[classtable.VoidBolt].remains <= buff[classtable.VoidformBuff].remains + 2 ) and not talents[classtable.DistortedReality]) and cooldown[classtable.DevouringPlague].ready then
        return classtable.DevouringPlague
    end
    if (MaxDps:FindSpell(classtable.VampiricTouch) and CheckSpellCosts(classtable.VampiricTouch, 'VampiricTouch')) and (max_vts >0 and ( cooldown[classtable.ShadowCrash].remains >= debuff[classtable.VampiricTouchDeBuff].remains or holding_crash ) and not (select(2,GetSpellCooldown(classtable.ShadowCrash)) >=5 ) or not talents[classtable.WhisperingShadows] and debuff[classtable.VampiricTouch].refreshable and ttd >= 18 and ( debuff[classtable.VampiricTouchDeBuff].up or not dots_up )) and cooldown[classtable.VampiricTouch].ready then
        return classtable.VampiricTouch
    end
    if (MaxDps:FindSpell(classtable.ShadowWordDeath) and CheckSpellCosts(classtable.ShadowWordDeath, 'ShadowWordDeath')) and (dots_up and talents[classtable.InescapableTorment] and ( UnitExists('pet') and UnitName('pet')  == 'fiend' ) and ( ( not talents[classtable.InsidiousIre] and not talents[classtable.IdolofYoggsaron] ) or buff[classtable.DeathspeakerBuff].up ) and not (MaxDps.tier and MaxDps.tier[31].count >= 2) and debuff[classtable.DevouringPlagueDeBuff].remains) and cooldown[classtable.ShadowWordDeath].ready then
        return classtable.ShadowWordDeath
    end
    if (MaxDps:FindSpell(classtable.MindSpikeInsanity) and CheckSpellCosts(classtable.MindSpikeInsanity, 'MindSpikeInsanity')) and (dots_up and cooldown[classtable.MindBlast].fullRecharge >= gcd * 3 and talents[classtable.IdolofCthun] and ( not cooldown[classtable.VoidTorrent].up or not talents[classtable.VoidTorrent] ) and debuff[classtable.DevouringPlagueDeBuff].remains) and cooldown[classtable.MindSpikeInsanity].ready then
        return classtable.MindSpikeInsanity
    end
    if (MaxDps:FindSpell(classtable.MindFlayInsanity) and CheckSpellCosts(classtable.MindFlayInsanity, 'MindFlayInsanity')) and (buff[classtable.MindFlayInsanityBuff].up and dots_up and cooldown[classtable.MindBlast].fullRecharge >= gcd * 3 and talents[classtable.IdolofCthun] and ( not cooldown[classtable.VoidTorrent].up or not talents[classtable.VoidTorrent] ) and debuff[classtable.DevouringPlagueDeBuff].remains) and cooldown[classtable.MindFlayInsanity].ready then
        return classtable.MindFlayInsanity
    end
    if (MaxDps:FindSpell(classtable.MindBlast) and CheckSpellCosts(classtable.MindBlast, 'MindBlast')) and (dots_up and ( not buff[classtable.MindDevourerBuff].up or cooldown[classtable.VoidEruption].up and talents[classtable.VoidEruption] ) and debuff[classtable.DevouringPlagueDeBuff].remains) and cooldown[classtable.MindBlast].ready then
        return classtable.MindBlast
    end
    if (MaxDps:FindSpell(classtable.VoidTorrent) and CheckSpellCosts(classtable.VoidTorrent, 'VoidTorrent')) and (( not holding_crash or targets% ( debuff[classtable.VampiricTouch].count + targets) <1.5 ) and ( debuff[classtable.DevouringPlagueDeBuff].remains >= 2.5 or buff[classtable.VoidformBuff].up ) and debuff[classtable.DevouringPlagueDeBuff].remains) and cooldown[classtable.VoidTorrent].ready then
        return classtable.VoidTorrent
    end
    if (MaxDps:FindSpell(classtable.MindFlayInsanity) and CheckSpellCosts(classtable.MindFlayInsanity, 'MindFlayInsanity')) and (buff[classtable.MindFlayInsanityBuff].up and talents[classtable.IdolofCthun] and debuff[classtable.DevouringPlagueDeBuff].remains) and cooldown[classtable.MindFlayInsanity].ready then
        return classtable.MindFlayInsanity
    end
    local fillerCheck = Shadow:filler()
    if fillerCheck then
        return fillerCheck
    end
    max_vts = targets >12 and 1 or 0
    is_vt_possible = false
    if ttd >= 18 then
        is_vt_possible = true
    end
    dots_up = ( debuff[classtable.VampiricTouch].count + 8 * ( (select(2,GetSpellCooldown(classtable.ShadowCrash)) >=5 ) and talents[classtable.WhisperingShadows] and 1 or 0 )) >= max_vts or not is_vt_possible
    if holding_crash and talents[classtable.WhisperingShadows] then
        holding_crash = ( max_vts - debuff[classtable.VampiricTouch].count ) <4
    end
    manual_vts_applied = ( debuff[classtable.VampiricTouch].count + 8 * (not holding_crash and 0 or 1) ) >= max_vts or not is_vt_possible
end
function Shadow:aoe_variables()
    max_vts = targets >12 and 1 or 0
    is_vt_possible = false
    if ttd >= 18 then
        is_vt_possible = true
    end
    dots_up = ( debuff[classtable.VampiricTouch].count + 8 * ( (select(2,GetSpellCooldown(classtable.ShadowCrash)) >=5 ) and talents[classtable.WhisperingShadows] and 1 or 0 )) >= max_vts or not is_vt_possible
    if holding_crash and talents[classtable.WhisperingShadows] then
        holding_crash = ( max_vts - debuff[classtable.VampiricTouch].count ) <4
    end
    manual_vts_applied = ( debuff[classtable.VampiricTouch].count + 8 * (not holding_crash and 0 or 1) ) >= max_vts or not is_vt_possible
end
function Shadow:cds()
    --if (MaxDps:FindSpell(classtable.Potion) and CheckSpellCosts(classtable.Potion, 'Potion')) and (buff[classtable.VoidformBuff].up or buff[classtable.PowerInfusionBuff].up or buff[classtable.DarkAscensionBuff].up and ( ttd <= cooldown[classtable.PowerInfusion].remains + 15 ) or ttd <= 30) and cooldown[classtable.Potion].ready then
    --    return classtable.Potion
    --end
    if (MaxDps:FindSpell(classtable.DivineStar) and CheckSpellCosts(classtable.DivineStar, 'DivineStar')) and (( targets >1 or targets >= 5 ) and CheckEquipped('BelorrelostheSuncaller') and CheckTrinketCooldown('Belorrelos the Suncaller') <= gcd) and cooldown[classtable.DivineStar].ready then
        return classtable.DivineStar
    end
    if (MaxDps:FindSpell(classtable.PowerInfusion) and CheckSpellCosts(classtable.PowerInfusion, 'PowerInfusion')) and (( buff[classtable.VoidformBuff].up or buff[classtable.DarkAscensionBuff].up )) and cooldown[classtable.PowerInfusion].ready then
        return classtable.PowerInfusion
    end
    --(not cooldown[classtable.Shadowfiend].up and ( ( UnitExists('pet') and UnitName('pet')  == 'fiend' ) and cooldown[classtable.Shadowfiend].remains >= 4 or not talents[classtable.Mindbender] or targets >2 and not talents[classtable.InescapableTorment] ) and ( cooldown[classtable.MindBlast].charges == 0 or timeInCombat >15 ))
    if (MaxDps:FindSpell(classtable.VoidEruption) and CheckSpellCosts(classtable.VoidEruption, 'VoidEruption')) and cooldown[classtable.VoidEruption].ready then
        return classtable.VoidEruption
    end
    if (MaxDps:FindSpell(classtable.DarkAscension) and CheckSpellCosts(classtable.DarkAscension, 'DarkAscension')) and (( UnitExists('pet') and UnitName('pet')  == 'fiend' ) and cooldown[classtable.Shadowfiend].remains >= 4 or not talents[classtable.Mindbender] and not cooldown[classtable.Shadowfiend].up or targets >2 and not talents[classtable.InescapableTorment]) and cooldown[classtable.DarkAscension].ready then
        return classtable.DarkAscension
    end
    if (MaxDps:FindSpell(classtable.DesperatePrayer) and CheckSpellCosts(classtable.DesperatePrayer, 'DesperatePrayer')) and (curentHP <= 75) and cooldown[classtable.DesperatePrayer].ready then
        return classtable.DesperatePrayer
    end
end
function Shadow:filler()
    if (MaxDps:FindSpell(classtable.VampiricTouch) and CheckSpellCosts(classtable.VampiricTouch, 'VampiricTouch')) and (buff[classtable.UnfurlingDarknessBuff].up and debuff[classtable.VampiricTouch].remains) and cooldown[classtable.VampiricTouch].ready then
        return classtable.VampiricTouch
    end
    if (MaxDps:FindSpell(classtable.ShadowWordDeath) and CheckSpellCosts(classtable.ShadowWordDeath, 'ShadowWordDeath')) and (targetHP <20 or ( buff[classtable.DeathspeakerBuff].up or (MaxDps.tier and MaxDps.tier[31].count >= 2) ) and debuff[classtable.DevouringPlagueDeBuff].up) and cooldown[classtable.ShadowWordDeath].ready then
        return classtable.ShadowWordDeath
    end
    if (MaxDps:FindSpell(classtable.MindSpikeInsanity) and CheckSpellCosts(classtable.MindSpikeInsanity, 'MindSpikeInsanity')) and (debuff[classtable.DevouringPlagueDeBuff].remains >( select(4,GetSpellInfo(classtable.MindSpikeInsanity)) /1000) and debuff[classtable.DevouringPlagueDeBuff].remains) and cooldown[classtable.MindSpikeInsanity].ready then
        return classtable.MindSpikeInsanity
    end
    if (MaxDps:FindSpell(classtable.MindFlayInsanity) and CheckSpellCosts(classtable.MindFlayInsanity, 'MindFlayInsanity')) and (buff[classtable.MindFlayInsanityBuff].up and debuff[classtable.DevouringPlagueDeBuff].remains) and cooldown[classtable.MindFlayInsanity].ready then
        return classtable.MindFlayInsanity
    end
    if (MaxDps:FindSpell(classtable.Mindgames) and CheckSpellCosts(classtable.Mindgames, 'Mindgames')) and (debuff[classtable.DevouringPlagueDeBuff].remains) and cooldown[classtable.Mindgames].ready then
        return classtable.Mindgames
    end
    if (MaxDps:FindSpell(classtable.ShadowWordDeath) and CheckSpellCosts(classtable.ShadowWordDeath, 'ShadowWordDeath')) and (talents[classtable.InescapableTorment] and ( UnitExists('pet') and UnitName('pet')  == 'fiend' ) and ttd) and cooldown[classtable.ShadowWordDeath].ready then
        return classtable.ShadowWordDeath
    end
    if (MaxDps:FindSpell(classtable.Halo) and CheckSpellCosts(classtable.Halo, 'Halo')) and (targets >1) and cooldown[classtable.Halo].ready then
        return classtable.Halo
    end
    if (MaxDps:FindSpell(classtable.MindSpike) and CheckSpellCosts(classtable.MindSpike, 'MindSpike')) and (debuff[classtable.DevouringPlagueDeBuff].remains) and cooldown[classtable.MindSpike].ready then
        return classtable.MindSpike
    end
    if (MaxDps:FindSpell(classtable.MindFlay) and CheckSpellCosts(classtable.MindFlay, 'MindFlay')) and (debuff[classtable.DevouringPlagueDeBuff].remains) and cooldown[classtable.MindFlay].ready then
        return classtable.MindFlay
    end
    if (MaxDps:FindSpell(classtable.DivineStar) and CheckSpellCosts(classtable.DivineStar, 'DivineStar')) and cooldown[classtable.DivineStar].ready then
        return classtable.DivineStar
    end
    if (MaxDps:FindSpell(classtable.ShadowCrash) and CheckSpellCosts(classtable.ShadowCrash, 'ShadowCrash')) and (not (MaxDps.tier and MaxDps.tier[31].count >= 4)) and cooldown[classtable.ShadowCrash].ready then
        return classtable.ShadowCrash
    end
    if (MaxDps:FindSpell(classtable.ShadowWordDeath) and CheckSpellCosts(classtable.ShadowWordDeath, 'ShadowWordDeath')) and (targetHP <20) and cooldown[classtable.ShadowWordDeath].ready then
        return classtable.ShadowWordDeath
    end
    if (MaxDps:FindSpell(classtable.ShadowWordDeath) and CheckSpellCosts(classtable.ShadowWordDeath, 'ShadowWordDeath')) and (debuff[classtable.DevouringPlagueDeBuff].remains) and cooldown[classtable.ShadowWordDeath].ready then
        return classtable.ShadowWordDeath
    end
    if (MaxDps:FindSpell(classtable.ShadowWordPain) and CheckSpellCosts(classtable.ShadowWordPain, 'ShadowWordPain')) and ((MaxDps.tier and MaxDps.tier[31].count >= 4) and debuff[classtable.DevouringPlagueDeBuff].remains) and cooldown[classtable.ShadowWordPain].ready then
        return classtable.ShadowWordPain
    end
    if (MaxDps:FindSpell(classtable.ShadowWordPain) and CheckSpellCosts(classtable.ShadowWordPain, 'ShadowWordPain')) and (not (MaxDps.tier and MaxDps.tier[31].count >= 4) and debuff[classtable.ShadowWordPain].remains) and cooldown[classtable.ShadowWordPain].ready then
        return classtable.ShadowWordPain
    end
end
function Shadow:main()
    dots_up = debuff[classtable.VampiricTouch].count == targets or (select(2,GetSpellCooldown(classtable.ShadowCrash)) >=5 ) and talents[classtable.WhisperingShadows]
    if (ttd <30 or ttd >15 and ( not holding_crash or targets >2 )) then
        local cdsCheck = Shadow:cds()
        if cdsCheck then
            return Shadow:cds()
        end
    end
    if (MaxDps:FindSpell(classtable.Mindbender) and CheckSpellCosts(classtable.Mindbender, 'Mindbender')) and (dots_up and ( ttd <30 or ttd >15 ) and ( not talents[classtable.DarkAscension] or cooldown[classtable.DarkAscension].remains <gcd or ttd <15 )) and cooldown[classtable.Mindbender].ready then
        return classtable.Mindbender
    end
    if (MaxDps:FindSpell(classtable.DevouringPlague) and CheckSpellCosts(classtable.DevouringPlague, 'DevouringPlague')) and (debuff[classtable.DevouringPlague].remains <= gcd or InsanityDeficit <= 16 and not talents[classtable.DistortedReality] or targets == 1 or debuff[classtable.DevouringPlague].remains <= gcd) and cooldown[classtable.DevouringPlague].ready then
        return classtable.DevouringPlague
    end
    if (MaxDps:FindSpell(classtable.ShadowWordDeath) and CheckSpellCosts(classtable.ShadowWordDeath, 'ShadowWordDeath')) and (( (MaxDps.tier and MaxDps.tier[31].count >= 4) or ( UnitExists('pet') and UnitName('pet')  == 'fiend' ) and talents[classtable.InescapableTorment] and (MaxDps.tier and MaxDps.tier[31].count >= 2) ) and debuff[classtable.DevouringPlagueDeBuff].up) and cooldown[classtable.ShadowWordDeath].ready then
        return classtable.ShadowWordDeath
    end
    if (MaxDps:FindSpell(classtable.MindBlast) and CheckSpellCosts(classtable.MindBlast, 'MindBlast')) and (( UnitExists('pet') and UnitName('pet')  == 'fiend' ) and talents[classtable.InescapableTorment] and GetTotemDuration('fiend') >MaxDps:GetTimeToPct(30) and targets <= 7 and debuff[classtable.DevouringPlagueDeBuff].remains >MaxDps:GetTimeToPct(30) and ( cooldown[classtable.MindBlast].fullRecharge <= gcd + MaxDps:GetTimeToPct(30) ) or GetTotemDuration('fiend') <= MaxDps:GetTimeToPct(30) + gcd) and cooldown[classtable.MindBlast].ready then
        return classtable.MindBlast
    end
    if (MaxDps:FindSpell(classtable.ShadowWordDeath) and CheckSpellCosts(classtable.ShadowWordDeath, 'ShadowWordDeath')) and (debuff[classtable.DevouringPlagueDeBuff].up and GetTotemDuration('fiend') <= 2 and ( UnitExists('pet') and UnitName('pet')  == 'fiend' ) and talents[classtable.InescapableTorment] and targets <= 7) and cooldown[classtable.ShadowWordDeath].ready then
        return classtable.ShadowWordDeath
    end
    if (MaxDps:FindSpell(classtable.VoidBolt) and CheckSpellCosts(classtable.VoidBolt, 'VoidBolt')) and (dots_up) and cooldown[classtable.VoidBolt].ready then
        return classtable.VoidBolt
    end
    if (MaxDps:FindSpell(classtable.DevouringPlague) and CheckSpellCosts(classtable.DevouringPlague, 'DevouringPlague')) and (ttd <= ( select(4,GetSpellInfo(classtable.DevouringPlague)) /1000 ) + 4) and cooldown[classtable.DevouringPlague].ready then
        return classtable.DevouringPlague
    end
    if (MaxDps:FindSpell(classtable.DevouringPlague) and CheckSpellCosts(classtable.DevouringPlague, 'DevouringPlague')) and (( debuff[classtable.DevouringPlague].remains <= gcd or debuff[classtable.DevouringPlague].remains <3 and cooldown[classtable.VoidTorrent].up ) or InsanityDeficit <= 20 or buff[classtable.VoidformBuff].up and cooldown[classtable.VoidBolt].remains >buff[classtable.VoidformBuff].remains and cooldown[classtable.VoidBolt].remains <= buff[classtable.VoidformBuff].remains + 2 or buff[classtable.MindDevourerBuff].up and debuff[classtable.DevouringPlague].remains <1.2 and not talents[classtable.DistortedReality] or targets == 1 or debuff[classtable.DevouringPlague].remains <= gcd) and cooldown[classtable.DevouringPlague].ready then
        return classtable.DevouringPlague
    end
    if (MaxDps:FindSpell(classtable.ShadowWordDeath) and CheckSpellCosts(classtable.ShadowWordDeath, 'ShadowWordDeath')) and ((MaxDps.tier and MaxDps.tier[31].count >= 2)) and cooldown[classtable.ShadowWordDeath].ready then
        return classtable.ShadowWordDeath
    end
    if (MaxDps:FindSpell(classtable.ShadowCrash) and CheckSpellCosts(classtable.ShadowCrash, 'ShadowCrash')) and (not holding_crash and ( debuff[classtable.VampiricTouchDeBuff].refreshable or buff[classtable.DeathsTormentBuff].count >9 and (MaxDps.tier and MaxDps.tier[31].count >= 4) )) and cooldown[classtable.ShadowCrash].ready then
        return classtable.ShadowCrash
    end
    if (MaxDps:FindSpell(classtable.ShadowWordPain) and CheckSpellCosts(classtable.ShadowWordPain, 'ShadowWordPain')) and (buff[classtable.DeathsTormentBuff].count >9 and (MaxDps.tier and MaxDps.tier[31].count >= 4) and ( not holding_crash or not talents[classtable.ShadowCrash] )) and cooldown[classtable.ShadowWordPain].ready then
        return classtable.ShadowWordPain
    end
    if (MaxDps:FindSpell(classtable.ShadowWordDeath) and CheckSpellCosts(classtable.ShadowWordDeath, 'ShadowWordDeath')) and (dots_up and talents[classtable.InescapableTorment] and ( UnitExists('pet') and UnitName('pet')  == 'fiend' ) and ( ( not talents[classtable.InsidiousIre] and not talents[classtable.IdolofYoggsaron] ) or buff[classtable.DeathspeakerBuff].up ) and not (MaxDps.tier and MaxDps.tier[31].count >= 2)) and cooldown[classtable.ShadowWordDeath].ready then
        return classtable.ShadowWordDeath
    end
    if (MaxDps:FindSpell(classtable.VampiricTouch) and CheckSpellCosts(classtable.VampiricTouch, 'VampiricTouch')) and (debuff[classtable.VampiricTouch].refreshable and ttd >= 12 and ( cooldown[classtable.ShadowCrash].remains >= debuff[classtable.VampiricTouchDeBuff].remains and not (select(2,GetSpellCooldown(classtable.ShadowCrash)) >=5 ) or holding_crash or not talents[classtable.WhisperingShadows] ) and debuff[classtable.VampiricTouch].remains) and cooldown[classtable.VampiricTouch].ready then
        return classtable.VampiricTouch
    end
    if (MaxDps:FindSpell(classtable.MindBlast) and CheckSpellCosts(classtable.MindBlast, 'MindBlast')) and (( not buff[classtable.MindDevourerBuff].up or cooldown[classtable.VoidEruption].up and talents[classtable.VoidEruption] )) and cooldown[classtable.MindBlast].ready then
        return classtable.MindBlast
    end
    if (MaxDps:FindSpell(classtable.VoidTorrent) and CheckSpellCosts(classtable.VoidTorrent, 'VoidTorrent')) and (not holding_crash and debuff[classtable.DevouringPlagueDeBuff].remains >= 2.5) and cooldown[classtable.VoidTorrent].ready then
        return classtable.VoidTorrent
    end
    local fillerCheck = Shadow:filler()
    if fillerCheck then
        return fillerCheck
    end
end

function Priest:Shadow()
    fd = MaxDps.FrameData
    ttd = (fd.timeToDie and fd.timeToDie) or 500
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
    SpellHaste = UnitSpellHaste('target')
    SpellCrit = GetCritChance()
    Insanity = UnitPower('player', InsanityPT)
    InsanityMax = UnitPowerMax('player', InsanityPT)
    InsanityDeficit = InsanityMax - Insanity
    classtable.ShadowformBuff = 232698
    classtable.VampiricTouchDeBuff = 34914
    classtable.VoidformBuff = 194249
    classtable.ShadowWordPainDeBuff = 589
    classtable.DevouringPlagueDeBuff = 335467
    classtable.MindDevourerBuff = 373204
    classtable.DeathspeakerBuff = 392511
    classtable.MindFlayInsanityBuff = 391401
    classtable.PowerInfusionBuff = 10060
    classtable.DarkAscensionBuff = 391109
    classtable.UnfurlingDarknessBuff = 341282
    classtable.DeathsTormentBuff = 423726
    classtable.MindFlayInsanity = 391403
    classtable.MindSpikeInsanity = 407466
    classtable.MindFlay = 15407
    classtable.VoidBolt = 205448

    holding_crash = false
    pool_for_cds = ( cooldown[classtable.VoidEruption].remains <= gcd * 3 and talents[classtable.VoidEruption] or cooldown[classtable.DarkAscension].up and talents[classtable.DarkAscension] ) or talents[classtable.VoidTorrent] and talents[classtable.PsychicLink] and cooldown[classtable.VoidTorrent].remains <= 4 and ( targets <2 and targets >1 ) and not buff[classtable.VoidformBuff].up
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
    if (ttd <30 or ttd >15 and ( not holding_crash or targets >2 )) then
        local cdsCheck = Shadow:cds()
        if cdsCheck then
            return Shadow:cds()
        end
    end
    local fillerCheck = Shadow:filler()
    if fillerCheck then
        return fillerCheck
    end
    if (ttd <30 or ttd >15 and ( not holding_crash or targets >2 )) then
        local cdsCheck = Shadow:cds()
        if cdsCheck then
            return Shadow:cds()
        end
    end
    local fillerCheck = Shadow:filler()
    if fillerCheck then
        return fillerCheck
    end

end
