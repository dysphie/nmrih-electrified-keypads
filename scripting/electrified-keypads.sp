#include <sdktools>
#include <sdkhooks>
#include <vscript_proxy>

#define MAXPLAYERS_NMRIH 9

public Plugin myinfo = {
    name        = "[NMRiH] Electrified Keypads",
    author      = "Dysphie",
    description = "Keypads shock players on a wrong code",
    version     = "1.0.1",
    url         = "https://github.com/dysphie/nmrih-electrified-keypads"
};

ConVar cvBaseDmg;
ConVar cvMultDmg;
ConVar cvEnabled;
ConVar cvViewPunch;

int beam;
StringMap lastKeypadUser;
StringMap attemptHistory[MAXPLAYERS_NMRIH+1];

public void OnPluginStart()
{
	cvEnabled = CreateConVar("sm_keypad_shock_damage_enabled", "1", 
		"Enables electrified keypads");

	cvBaseDmg = CreateConVar("sm_keypad_shock_damage_base", "5", 
		"Base damage to deal to players on wrong code");

	cvMultDmg = CreateConVar("sm_keypad_shock_damage_multiplier", "5", 
		"Increments base damage by this amount on each wrong code");

	cvViewPunch = CreateConVar("sm_keypad_shock_viewpunch", "-5.0", 
		"Punches the player's view with the specified force on wrong code");

	AutoExecConfig(true, "plugin.electrified-keypads");

	lastKeypadUser = new StringMap();
	HookEvent("nmrih_reset_map", OnMapReset, EventHookMode_PostNoCopy);
	HookEvent("keycode_enter", OnKeyCodeEnter, EventHookMode_Pre);
	HookEvent("player_death", OnPlayerDeath);
	HookEntityOutput("trigger_keypad", "OnIncorrectCode", OnIncorrectCode);
}

public void OnClientDisconnect(int client)
{
	delete attemptHistory[client];
}

public void OnMapStart()
{
	ClearKeypads();
	beam = PrecacheModel("materials/sprites/laserbeam.vmt", true);
}

void ClearKeypads()
{
	lastKeypadUser.Clear();
	for (int i = 1; i <= MaxClients; i++) {
		if (attemptHistory[i]) {
			attemptHistory[i].Clear();
		}
	}	
}

Action OnIncorrectCode(const char[] output, int keypad, int activator, float delay)
{
	if (0 >= activator > MaxClients || !cvEnabled.BoolValue || !IsValidEntity(keypad)) {
		return Plugin_Continue;
	}

	int keypadRef = EntIndexToEntRef(keypad);

	char key[11];
	IntToString(keypadRef, key, sizeof(key));

	int client;
	if (!lastKeypadUser.GetValue(key, client)) {
		return Plugin_Continue;
	}

	IntToString(keypadRef, key, sizeof(key));

	int numAttempts = 0;

	if (!attemptHistory[client]) {
		attemptHistory[client] = new StringMap();
	} else {
		attemptHistory[client].GetValue(key, numAttempts);
	}

	int dmg = cvBaseDmg.IntValue + cvMultDmg.IntValue * numAttempts;
	attemptHistory[client].SetValue(key, ++numAttempts);
	
	float pos[3];
	RunEntVScriptVector(keypad, pos, "GetCenter()");

	float clientEyes[3];
	GetClientEyePosition(client, clientEyes);
	clientEyes[2] -= 15.0;

	RunEntVScript(client, "ViewPunch(Vector(%.2f, 0.0, 0.0))", cvViewPunch.FloatValue);

	TE_SetupBeamPoints(pos, clientEyes, 
		.ModelIndex=beam, 
		.HaloIndex=0, 
		.StartFrame=0,
		.FrameRate=1,
		.Life=0.1, 
		.Width=0.2, 
		.EndWidth=0.2, 
		.FadeLength=0, 
		.Amplitude=15.0, 
		.Color={0, 128, 255, 255}, 
		.Speed=1);
	TE_SendToAll();

	SparkSound(keypad);
	SDKHooks_TakeDamage(client, keypad, keypad, float(dmg), DMG_SHOCK, .damagePosition=pos);

	return Plugin_Continue;
}

Action OnMapReset(Event event, const char[] name, bool dontBroadcast)
{
	ClearKeypads();
	return Plugin_Continue;
}

Action OnPlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if (client)
		delete attemptHistory[client];

	return Plugin_Continue;
}

Action OnKeyCodeEnter(Event event, const char[] name, bool dontBroadcast)
{
	if (!cvEnabled.BoolValue)
		return Plugin_Continue;

	int client = event.GetInt("player");
	if (0 < client <= MaxClients && IsClientInGame(client))
	{
		int keypad = event.GetInt("keypad_idx");
		if (IsValidEntity(keypad))
		{
			char lastUseKey[11];
			IntToString(EntIndexToEntRef(keypad), lastUseKey, sizeof(lastUseKey));
			lastKeypadUser.SetValue(lastUseKey, client);
		}
	}

	return Plugin_Continue;
}

void SparkSound(int entity)
{
    char soundName[128];
    int channel = SNDCHAN_AUTO;
    int soundLevel = SNDLEVEL_NORMAL;
    float volume = SNDVOL_NORMAL;
    int pitch = SNDPITCH_NORMAL;
    GetGameSoundParams("DoSpark", channel, soundLevel, volume, pitch,
        soundName, sizeof(soundName), entity);

    EmitSoundToAll(soundName, entity, channel, soundLevel,
        SND_CHANGEVOL | SND_CHANGEPITCH, volume, pitch);
}