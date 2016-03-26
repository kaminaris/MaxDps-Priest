-- Author      : Kaminari
-- Create Date : 13:03 2015-04-20

-- Spells
local _MindFlay			= 15407;
local _MindBlast		= 8092;
local _ShadowWordPain	= 589;
local _ShadowWordDeath	= 32379;
local _DevouringPlague	= 2944;
local _MindSpike		= 73510;
local _Mindbender		= 123040;
local _Shadowfiend		= 34433;
local _VampiricTouch	= 34914;

-- Auras
local _SurgeOfDarkness	= 87160;
local _Insanity			= 132573;

-- Talents
local _isClarityOfPower = false;
local _isMindbender = false;

----------------------------------------------
-- Pre enable, checking talents
----------------------------------------------
TDDps_Priest_CheckTalents = function()
	_isClarityOfPower = TD_TalentEnabled('Clarity of Power');
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
	local lcd, currentSpell, gcd = TD_EndCast();
	local timeShift = lcd;
	if gcd > timeShift then
		timeShift = gcd;
	end

	return _Spell;
end

----------------------------------------------
-- Main rotation: Holy
----------------------------------------------
TDDps_Priest_Holy = function()
	local lcd, currentSpell, gcd = TD_EndCast();
	local timeShift = lcd;
	if gcd > timeShift then
		timeShift = gcd;
	end

	return _Spell;
end

----------------------------------------------
-- Main rotation: Shadow
----------------------------------------------
TDDps_Priest_Shadow = function()
	local lcd, currentSpell, gcd = TD_EndCast();
	local timeShift = lcd;
	if gcd > timeShift then
		timeShift = gcd;
	end

	local orbs = UnitPower('player', SPELL_POWER_SHADOW_ORBS);

	local mbCd = TD_SpellAvailable(_MindBlast, timeShift);
	local targetPH = TD_TargetPercentHealth();
	local death = TD_SpellAvailable(_ShadowWordDeath, timeShift);

	local surge = TD_Aura(_SurgeOfDarkness, timeShift);
	local insanity = TD_Aura(_Insanity, timeShift);

	local swp = TD_TargetAura(_ShadowWordPain, timeShift + 5)
	local vt = TD_TargetAura(_VampiricTouch, timeShift + 4)

	if _isMindbender then
		local mb = TD_SpellAvailable(_Mindbender, timeShift);
		TDButton_GlowCooldown(_Mindbender, mb);
	else
		local sf = TD_SpellAvailable(_Shadowfiend, timeShift);
		TDButton_GlowCooldown(_Shadowfiend, sf);
	end

	if orbs >= 3 then
		return _DevouringPlague;
	end

	if mbCd and orbs < 5 and currentSpell ~= 'Mind Blast' then
		return _MindBlast;
	end

	if targetPH < 0.2 and death then
		return _ShadowWordDeath;
	end

	if surge and currentSpell ~= 'Mind Spike' then
		return _MindSpike;
	end

	if insanity then
		return _MindFlay;
	end

	if not swp and not _isClarityOfPower then
		return _ShadowWordPain;
	end

	if not vt and not _isClarityOfPower and currentSpell ~= 'Vampiric Touch' then
		return _VampiricTouch;
	end

	if _isClarityOfPower then
		return _MindSpike;
	end

	return _MindFlay;
end