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
local _LegacyOfTheVoid = 193225;

local _isLegacyoftheVoid = false;
local _isMindbender = false;
local _isReaperofSouls = false;
local _isPowerInfusion = false;
local _isMindSpike = false;

MaxDps.Priest = {};

MaxDps.Priest.CheckTalents = function()
	MaxDps:CheckTalents();
	_isLegacyoftheVoid  = MaxDps:HasTalent(_LegacyOfTheVoid);
	_isReaperofSouls  = MaxDps:HasTalent(_ReaperofSouls);
	_isPowerInfusion  = MaxDps:HasTalent(_PowerInfusion);
	_isMindbender = MaxDps:HasTalent(_Mindbender);
	_isMindSpike = MaxDps:HasTalent(_MindSpike);
end

function MaxDps:EnableRotationModule(mode)
	mode = mode or 1;
	MaxDps.Description = 'Priest Module [Shadow]';
	MaxDps.ModuleOnEnable = MaxDps.Priest.CheckTalents;
	if mode == 1 then
		MaxDps.NextSpell = MaxDps.Priest.Discipline;
	end;
	if mode == 2 then
		MaxDps.NextSpell = MaxDps.Priest.Holy;
	end;
	if mode == 3 then
		MaxDps.NextSpell = MaxDps.Priest.Shadow;
	end;
end

function MaxDps.Priest.Discipline()
	local timeShift, currentSpell, gcd = MaxDps:EndCast();

	return nil;
end

function MaxDps.Priest.Holy()
	local timeShift, currentSpell, gcd = MaxDps:EndCast();

	return nil;
end

function MaxDps.Priest.Shadow()
	local timeShift, currentSpell, gcd = MaxDps:EndCast();

	local insa = UnitPower('player', SPELL_POWER_INSANITY);

	local voidT = MaxDps:SpellAvailable(_VoidTorrent, timeShift);
	local voidB = MaxDps:SpellAvailable(_VoidBolt, timeShift + 0.5);

	-- Fix a bug when void bolt tooltip does not refresh
	local voidBolt = _VoidBolt;
	if MaxDps:FindSpell(_VoidEruption) then
		voidBolt = _VoidEruption;
	end

	local shadowFiend = _Shadowfiend;
	if _isMindbender then
		shadowFiend = _Mindbender;
	end
	local shadowF = MaxDps:SpellAvailable(shadowFiend, timeShift);

	local pi = MaxDps:SpellAvailable(_PowerInfusion, timeShift);
	local mb = MaxDps:SpellAvailable(_MindBlast, timeShift + 0.5);

	local swd, swdCharges, swdMax = MaxDps:SpellCharges(_ShadowWordDeath, timeShift + 0.5);

	local sf = MaxDps:PersistentAura(_Shadowform);
	local vf, vCharges = MaxDps:PersistentAura(_Voidform);

	local swp, swpCd = MaxDps:TargetAura(_ShadowWordPain, timeShift + 3);
	local vt, vtCd = MaxDps:TargetAura(_VampiricTouch, timeShift + 4);

	local targetPh = MaxDps:TargetPercentHealth();
	local canDeath = targetPh < 0.2 or (_isReaperofSouls and targetPh < 0.35);

	if not sf and not vf then
		return _Shadowform;
	end

	MaxDps:GlowCooldown(_PowerInfusion, _isPowerInfusion and pi);

	-- void form rotation
	if vf or MaxDps:SameSpell(currentSpell, _VoidEruption) then
		if swp and vt and (swpCd < 5 or vtCd < 6) then
			return voidBolt;
		end

		if voidT and not MaxDps:SameSpell(currentSpell, _VoidTorrent) then
			return _VoidTorrent;
		end

		if voidB then
			return voidBolt;
		end

		if vCharges < 20 and shadowF then
			return shadowFiend;
		end

		if swdCharges >= swdMax and canDeath then
			return _ShadowWordDeath;
		end

		if mb and not MaxDps:SameSpell(currentSpell, _MindBlast) then
			return _MindBlast;
		end

		if insa < 20 and swdCharges > 0 and canDeath then
			return _ShadowWordDeath;
		end

		if vCharges > 20 and shadowF then
			return shadowFiend;
		end

		if not vt and not MaxDps:SameSpell(currentSpell, _VampiricTouch) then
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

		if mb and not MaxDps:SameSpell(currentSpell, _MindBlast) then
			return _MindBlast;
		end

		if not vt and not MaxDps:SameSpell(currentSpell, _VampiricTouch) then
			return _VampiricTouch;
		end

		if not swp then
			return _ShadowWordPain;
		end
	end

	if _isMindSpike then
		return _MindSpike;
	else
		return _MindFlay;
	end
end