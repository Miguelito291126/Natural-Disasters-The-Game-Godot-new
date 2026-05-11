using Godot;
using Godot.Collections;

[GlobalClass]
public partial class ServerInfo : HBoxContainer
{
    public string ServerIp = "";
    public string ServerPort = "";
    public string ServerLocalIp = "";
    
    // Nuevas variables para Steam
    public ulong SteamLobbyId = 0;
    public bool IsSteamLobby = false;

    public void JoinServer() 
    {
        if (IsSteamLobby)
        {
            GD.Print($"Uniéndose a Lobby de Steam: {SteamLobbyId}");
            Globals.Instance.JoinGame("", 0, SteamLobbyId);
        }
        else
        {
            // Tu lógica original de IP Directa
            string targetIp = (ServerIp == Globals.Instance.PublicIp) ? ServerLocalIp : ServerIp;
            int port = ServerPort.ToInt();
            
            Globals.Instance.PlayMultiplayerClient(targetIp, port);
        }
    }
}
