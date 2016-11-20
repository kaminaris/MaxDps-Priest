-- Author      : Kaminari
-- Create Date : 13:03 2015-04-20

-- Forms
local _Voidform = 194249;
local _Shadowform = 232698;

-- Spells
local _LegacyoftheVoid = 193225;
local _VoidEruption = 228260;
local _VoidBolt = 205448;
local _ShadowWordPain = 589;
local _VampiricTouch = 34914;
local _MindBlast = 8092;
local _MindFlay = 15407;
local _VoidTorrent = 205065;
local _Shadowfiend = 34433;
local _ShadowWordDeath = 32379;
local _MindSpike = 73510;
local _MindSear = 48045;
local _Sanlayn = 199855;
local _AuspiciousSpirits = 155271;
local _ShadowyInsight = 162452;
local _Mindbender = 200174;
local _Dispersion = 47585;
local _ShadowCrash = 205385;
local _ReaperofSouls = 199853;
local _ShadowWordVoid = 205351;
local _ShadowyApparitions = 78203;
local _FortressoftheMind = 193195;
local _PowerInfusion = 10060;
local _SurrendertoMadness = 193223;
local _LingeringInsanity = 197937;
local _TwistofFate = 109142;
local _VoidRay = 205371;
local _Heroism = 32182;
local _Bloodlust = 2825;
local _TimeWarp = 80353;
local _Berserking = 26297;
local _FromtheShadows = 193642;


-- Talents
local _isLegacyoftheVoid = false;
local _isMindbender = false;
local _isReaperofSouls = false;

----------------------------------------------
-- Pre enable, checking talents
----------------------------------------------
TDDps_Priest_CheckTalents = function()
	_isLegacyoftheVoid  = TD_TalentEnabled('Legacy of the Void');
	_isReaperofSouls  = TD_TalentEnabled('Reaper of Souls');
	_isMindbender = TD_TalentEnabled('Mindbender');
	-- other checking functions
end

----------------------------------------------
-- Enabling Addon
----------------------------------------------
function TDDps_Priest_EnableAddon(mode)
mode = mode or 1;
_TD["DPS_Description"] = "TD Priest DPS supports: Shadow";
_TD["DPS_OnEnable"] = TDDps_Priest_CheckTalents;
if mode == 1 then
	_TD["DPS_NextSpell"] = TDDps_Priest_Discipline;
end;
if mode == 2 then
	_TD["DPS_NextSpell"] = TDDps_Priest_Holy;
end;
if mode == 3 then
	_TD["DPS_NextSpell"] = TDDps_Priest_Shadow;
end;
TDDps_EnableAddon();
end

----------------------------------------------
-- Main rotation: Discipline
----------------------------------------------
TDDps_Priest_Discipline = function()
	local timeShift, currentSpell, gcd = TD_EndCast();

	return nil;
end

----------------------------------------------
-- Main rotation: Holy
----------------------------------------------
TDDps_Priest_Holy = function()
	local timeShift, currentSpell, gcd = TD_EndCast();

	return nil;
end

----------------------------------------------
-- Main rotation: Shadow
----------------------------------------------
TDDps_Priest_Shadow = function()
	local timeShift, currentSpell, gcd = TD_EndCast();

	local insa = UnitPower('player', SPELL_POWER_INSANITY);

	local voidT = TD_SpellAvailable(_VoidTorrent, timeShift);
	local voidB = TD_SpellAvailable(_VoidBolt, timeShift + 1);
	local shadowF = TD_SpellAvailable(_Shadowfiend, timeShift);
	local mb = TD_SpellAvailable(_MindBlast, timeShift + 1);
	local swd, swdCharges, swdMax = TD_SpellCharges(_ShadowWordDeath, timeShift + 0.5);

	local sf = TD_PersistentAura(_Shadowform);
	local vf, vCharges = TD_PersistentAura(_Voidform);

	local swp = TD_TargetAura(_ShadowWordPain, timeShift + 3);
	local vt = TD_TargetAura(_VampiricTouch, timeShift + 4);

	local targetPh = TD_TargetPercentHealth();
	local canDeath = targetPh < 0.2 or (_isReaperofSouls and targetPh < 0.35);

	if not sf and not vf then
		return _Shadowform;
	end

	-- void form rotation
	if vf or currentSpell == 'Void Eruption' then
		if voidT and currentSpell ~= 'Void Torrent' then
			return _VoidTorrent;
		end

		if voidB then
			return _VoidEruption;
		end

		if vCharges < 20 and shadowF then
			return _Shadowfiend;
		end

		if swdCharges >= swdMax and canDeath then
			return _ShadowWordDeath;
		end

		if mb and currentSpell ~= 'Mind Blast' then
			return _MindBlast;
		end

		if insa < 20 and swdCharges > 0 and canDeath then
			return _ShadowWordDeath;
		end

		if vCharges > 20 and shadowF then
			return _Shadowfiend;
		end

		if not vt and currentSpell ~= 'Vampiric Touch' then
			return _VampiricTouch;
		end

		if not swp then
			return _ShadowWordPain;
		end
	else
		-- normal rotation
		if insa >= 100 or (_isLegacyoftheVoid and insa >= 70) then
			return _VoidEruption;
		end

		if mb and currentSpell ~= 'Mind Blast' then
			return _MindBlast;
		end

		if not vt and currentSpell ~= 'Vampiric Touch' then
			return _VampiricTouch;
		end

		if not swp then
			return _ShadowWordPain;
		end
	end

	return _MindFlay;
end