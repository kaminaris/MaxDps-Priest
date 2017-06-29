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

MaxDps.Priest = {};

MaxDps.Priest.CheckTalents = function()
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

function MaxDps.Priest.Discipline(_, timeShift, currentSpell, gcd, talents)
	return nil;
end

function MaxDps.Priest.Holy(_, timeShift, currentSpell, gcd, talents)
	return nil;
end

function MaxDps.Priest.Shadow(_, timeShift, currentSpell, gcd, talents)
	local insa = UnitPower('player', SPELL_POWER_INSANITY);

	-- Fix a bug when void bolt tooltip does not refresh
	local voidBolt = _VoidBolt;
	if MaxDps:FindSpell(_VoidEruption) then
		voidBolt = _VoidEruption;
	end

	local shadowFiend = _Shadowfiend;
	if talents[_Mindbender] then
		shadowFiend = _Mindbender;
	end
	local shadowF = MaxDps:SpellAvailable(shadowFiend, timeShift);

	local swd, swdCharges, swdMax = MaxDps:SpellCharges(_ShadowWordDeath, timeShift + 0.5);

	local swp, swpCd = MaxDps:TargetAura(_ShadowWordPain, timeShift);
	local vt, vtCd = MaxDps:TargetAura(_VampiricTouch, timeShift);

	local vf, vCharges = MaxDps:PersistentAura(_Voidform);
	if not MaxDps:PersistentAura(_Shadowform) and not vf then
		return _Shadowform;
	end

	if talents[_PowerInfusion] then
		MaxDps:GlowCooldown(_PowerInfusion, MaxDps:SpellAvailable(_PowerInfusion, timeShift));
	end

	-- void form rotation
	if vf or MaxDps:SameSpell(currentSpell, _VoidEruption) then
		-- If dot is not present on target AT ALL
		if not vt and not MaxDps:SameSpell(currentSpell, _VampiricTouch) then
			return _VampiricTouch;
		end

		if not swp then
			return _ShadowWordPain;
		end

		if MaxDps:SpellAvailable(_VoidTorrent, timeShift) and not MaxDps:SameSpell(currentSpell, _VoidTorrent) and
			swpCd > 5 and vtCd > 5 then
			return _VoidTorrent;
		end

		if MaxDps:SpellAvailable(_VoidBolt, timeShift + 0.3) then
			return voidBolt;
		end

		if vCharges < 20 and shadowF then
			return shadowFiend;
		end

		local targetPh = MaxDps:TargetPercentHealth();
		local canDeath = targetPh < 0.2 or (talents[_ReaperofSouls] and targetPh < 0.35);
		if swdCharges >= swdMax and canDeath then
			return _ShadowWordDeath;
		end

		if MaxDps:SpellAvailable(_MindBlast, timeShift + 0.3) and not MaxDps:SameSpell(currentSpell, _MindBlast) then
			return _MindBlast;
		end

		if insa < 20 and swdCharges >= 1 and canDeath then
			return _ShadowWordDeath;
		end

		if vCharges > 20 and shadowF then
			return shadowFiend;
		end
	else
		-- normal rotation
		if insa >= 100 or (talents[_LegacyoftheVoid] and insa >= 70) then
			return _VoidEruption;
		end

		if vtCd < 6 and not MaxDps:SameSpell(currentSpell, _VampiricTouch) then
			return _VampiricTouch;
		end

		if swpCd < 5 then
			return _ShadowWordPain;
		end

		if MaxDps:SpellAvailable(_MindBlast, timeShift + 0.5) and not MaxDps:SameSpell(currentSpell, _MindBlast) then
			return _MindBlast;
		end
	end

	if talents[_MindSpike] then
		return _MindSpike;
	else
		return _MindFlay;
	end
end