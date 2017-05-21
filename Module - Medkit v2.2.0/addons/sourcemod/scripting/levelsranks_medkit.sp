#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <lvl_ranks>

#define PLUGIN_NAME "Levels Ranks"
#define PLUGIN_AUTHOR "RoadSide Romeo & R1KO"

int		g_iMedkitPlayer[MAXPLAYERS+1],
		g_iMedkitCount,
		g_iMedkitMinHP,
		g_iMedkitMaxHP,
		g_iMedkitRank,
		m_iHealth;

public Plugin myinfo = {name = "[LR] Module - Medkit", author = PLUGIN_AUTHOR, version = PLUGIN_VERSION}
public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	switch(GetEngineVersion())
	{
		case Engine_CSGO, Engine_CSS: LogMessage("[%s Medkit] Запущен успешно", PLUGIN_NAME);
		default: SetFailState("[%s Medkit] Плагин работает только на CS:GO и CS:S", PLUGIN_NAME);
	}
}

public void OnPluginStart()
{
	LR_ModuleCount();
	HookEvent("round_start", Event_Medkit);
	LoadTranslations("levels_ranks_medkit.phrases");
	m_iHealth = FindSendPropInfo("CCSPlayer", "m_iHealth");
}

public void OnMapStart() 
{
	char sPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, sPath, sizeof(sPath), "configs/levels_ranks/medkit.ini");
	KeyValues hLR_Medkit = new KeyValues("LR_Medkit");

	if(!hLR_Medkit.ImportFromFile(sPath) || !hLR_Medkit.GotoFirstSubKey())
	{
		SetFailState("[%s Medkit] : фатальная ошибка - файл не найден (%s)", PLUGIN_NAME, sPath);
	}

	hLR_Medkit.Rewind();

	if(hLR_Medkit.JumpToKey("Settings"))
	{
		g_iMedkitRank = hLR_Medkit.GetNum("rank", 0);
		g_iMedkitCount = hLR_Medkit.GetNum("count", 1);
		g_iMedkitMinHP = hLR_Medkit.GetNum("minhealth", 30);
		g_iMedkitMaxHP = hLR_Medkit.GetNum("maxhealth", 100);
	}
	else SetFailState("[%s Medkit] : фатальная ошибка - секция Settings не найдена", PLUGIN_NAME);
	delete hLR_Medkit;
}

public void Event_Medkit(Handle hEvent, char[] sEvName, bool bDontBroadcast)
{
	for(int i = 1; i <= MaxClients; i++)
	{
		g_iMedkitPlayer[i] = g_iMedkitCount;
	}
}

public void LR_OnMenuCreated(int iClient, int iRank, Menu& hMenu)
{
	if(iRank == g_iMedkitRank)
	{
		char sText[64];
		SetGlobalTransTarget(iClient);

		if(LR_GetClientRank(iClient) >= g_iMedkitRank)
		{
			FormatEx(sText, sizeof(sText), "%t", "Medkit_ON");
			hMenu.AddItem("Medkit", sText);
		}
		else
		{
			FormatEx(sText, sizeof(sText), "%t", "Medkit_OFF", g_iMedkitRank);
			hMenu.AddItem("Medkit", sText, ITEMDRAW_DISABLED);
		}
	}
}

public void LR_OnMenuItemSelected(int iClient, int iRank, const char[] sInfo)
{
	if(iRank == g_iMedkitRank)
	{
		if(strcmp(sInfo, "Medkit") == 0)
		{
			LR_MenuInventory(iClient);
			UseMedkit(iClient);
		}
	}
}

void UseMedkit(int iClient)
{
	if(!IsPlayerAlive(iClient))
	{
		LR_PrintToChat(iClient, "%t", "Alive");
		return;
	}

	if(GetClientTeam(iClient) < 2)
	{
		LR_PrintToChat(iClient, "%t", "InTeam");
		return;
	}

	if(g_iMedkitPlayer[iClient] < 1)
	{
		LR_PrintToChat(iClient, "%t", "Nothing");
		return;
	}

	if(GetEntData(iClient, m_iHealth) > g_iMedkitMinHP)
	{
		LR_PrintToChat(iClient, "%t", "NoMedic");
		return;
	}

	g_iMedkitPlayer[iClient]--;
	SetEntData(iClient, m_iHealth, g_iMedkitMaxHP);
}