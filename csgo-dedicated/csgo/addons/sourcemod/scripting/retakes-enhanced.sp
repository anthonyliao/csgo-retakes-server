#if !defined PLUGIN_SP
#define PLUGIN_SP

#pragma semicolon 1
#pragma newdecls required

#define RETAKE_PREFIX ("[Retakes-Enhanced]")

#include <clientprefs>
#include <sourcemod>
#include <sdktools>
#include <cstrike>
#include <sdkhooks>
#include <halflife>

int g_lastWinningTeam = CS_TEAM_CT;
int g_winStreak = 0;

public Plugin myinfo = 
{
    name = "CSGO Retakes Enhanced",
    author = "anthonyliao",
    description = "Enhancements to CSGO Retakes mode",
    version = "0.2",
    url = ""
};

bool IsClientValid(int client) {
    int consoleClient = 0;
    return client > consoleClient && client <= MaxClients && IsClientInGame(client) && !IsClientSourceTV(client);
}

bool IsClientInGamePlaying(int client) {
    if (!IsClientValid(client)) {
        return false;
    }

    return (IsClientInGame(client) && (CS_TEAM_CT == GetClientTeam(client) || CS_TEAM_T == GetClientTeam(client)));
}

void ScrambleTeams() {
    char playerName[MAX_NAME_LENGTH];
    for (int i = 1; i < MaxClients; i++) {
        if (!IsClientInGame(i)) {
            continue;
        }
        
        if (!IsClientInGamePlaying(i)) {
            continue;
        }

        int currentTeam = GetClientTeam(i);
        GetClientName(i, playerName, sizeof(playerName));
        int randomTeam = GetRandomInt(2, 3);
        if (currentTeam != randomTeam) {
            PrintToServer("%s Assigning %s from team %d to team %d", RETAKE_PREFIX, playerName, currentTeam, randomTeam);
            CS_SwitchTeam(i, randomTeam);
        }
    }
}

public Action Command_ScrambleTeams(int client, int args) {
    PrintToConsole(client, "%s Scrambling teams...", RETAKE_PREFIX);
    PrintToChatAll("%s Scrambling teams...", RETAKE_PREFIX);
    ScrambleTeams();
    CS_TerminateRound(1.5, CSRoundEnd_Draw, false);
    return Plugin_Handled;
}

public Action Event_OnRoundEnd(Event event, char[] name, bool dontBroadcast) {
    int winningTeam = GetEventInt(event, "winner");

    if (winningTeam == g_lastWinningTeam) {
        g_winStreak = g_winStreak + 1;
    } else {
        g_lastWinningTeam = winningTeam;
        g_winStreak = 1;
    }

    PrintToServer("%s Team %d has a %d round win streak", RETAKE_PREFIX, winningTeam, g_winStreak);

    if (g_winStreak >= 3) {
        PrintToChatAll("%s %d round win streak. Scrambling teams...", RETAKE_PREFIX, g_winStreak);
        ScrambleTeams();
        g_winStreak = 0;
    }

    return Plugin_Continue;
}

public void OnPluginStart() { 
    PrintToServer("%s Plugin loaded", RETAKE_PREFIX);
    PrintToChatAll("%s Plugin loaded", RETAKE_PREFIX);
    g_winStreak = 0;
    RegAdminCmd("sm_scramble", Command_ScrambleTeams, ADMFLAG_GENERIC);
    HookEvent("round_end", Event_OnRoundEnd, EventHookMode_Pre);
}

public void OnPluginEnd() {
    PrintToServer("%s Plugin unloaded", RETAKE_PREFIX);
    PrintToChatAll("%s Plugin unloaded", RETAKE_PREFIX);
}
