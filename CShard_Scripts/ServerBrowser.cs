using Godot;
using Godot.Collections;
using GodotSteam;

[GlobalClass]
public partial class ServerBrowser : ScrollContainer
{
	public VBoxContainer List;
	public PackedScene Serverinfo = ResourceLoader.Load<PackedScene>("res://Scenes/server_info.tscn");
	public const float TIMEOUT = 3.0f;

	public override void _Ready()
	{
		List = GetNode<VBoxContainer>("List");
		Globals.Instance.ServerBrowser = this;

		// Conectar la señal de Steam
        Steam.LobbyMatchList += OnSteamLobbiesReceived;

        // Timer para refrescar
        Timer cleanTimer = new Timer();
        cleanTimer.WaitTime = 5.0f; 
        cleanTimer.Autostart = true;
        cleanTimer.Timeout += () => RefreshServerList(); 
        AddChild(cleanTimer);
        
        RefreshServerList();
	}

	public void RefreshServerList()
    {
        // Limpiar lista visual antes de pedir nuevos
        foreach (Node n in List.GetChildren()) n.QueueFree();

        if (Globals.Instance.UseSteam)
        {
            GD.Print("Buscando lobbies en Steam...");
            Steam.AddRequestLobbyListDistanceFilter(Steam.LobbyDistanceFilter.Worldwide);
            Steam.AddRequestLobbyListStringFilter("game_id", "natural_disaster_game", Steam.LobbyComparison.LobbyComparisonEqual);
            Steam.RequestLobbyList();
        }
    }

    private void OnSteamLobbiesReceived(Array lobbies)
    {
        GD.Print($"Se encontraron {lobbies.Count} lobbies de Steam.");

        foreach (ulong lobbyId in lobbies)
        {
            var currentinfo = Serverinfo.Instantiate<ServerInfo>();
            
            // Extraer datos del lobby
            string lobbyName = Steam.GetLobbyData(lobbyId, "name");
            string players = Steam.GetLobbyData(lobbyId, "players_count");
            
            // Configurar el nodo visual
            currentinfo.GetNode<Label>("Name").Text = lobbyName + " (Steam) - ";
            currentinfo.GetNode<Label>("Players").Text = players + " / 4 - ";

            // IMPORTANTE: Guardamos el ID del lobby para poder unirnos
            currentinfo.SteamLobbyId = lobbyId;
            currentinfo.IsSteamLobby = true;

            List.AddChild(currentinfo);
        }
    }

}