using Godot;
using Godot.Collections;

[GlobalClass]
public partial class PlayersListMenu : CanvasLayer
{
	public VBoxContainer List;
	public PackedScene PlayerInfo = ResourceLoader.Load<PackedScene>("res://Scenes/player_info.tscn");

	public override void _Ready()
	{
		List = GetNode<VBoxContainer>("Panel/List");
		this.Visible = false;
	}

	[Rpc(MultiplayerApi.RpcMode.AnyPeer, CallLocal = true)]
	public void SyncPlayers(Array players_array)
	{
		UpdateList(players_array);
	}

	public void UpdateList(Array players_array)
	{
		// Limpiar lista
		foreach(Node child in List.GetChildren())
		{
			if(child.Name == "Info")
			{
				continue;
			}
			child.QueueFree();
		}

		// Rellenar UI
		foreach(Dictionary p in players_array)
		{
			var inst = PlayerInfo.Instantiate();
			inst.GetNode<Label>("Username").Text = p["username"].AsString();
			inst.GetNode<Label>("Points").Text =  p["points"].ToString();
			List.AddChild(inst);
		}
	}
	public override void _Process(double _delta)
	{
		// Solo el servidor sincroniza
		if (!Multiplayer.IsServer())
		{
			return;
		}

		// Construir arreglo de datos
		Array data = new();
		foreach(Player player_data in Globals.Instance.PlayersConected)
		{
			if(IsInstanceValid(player_data))
			{
				data.Add(new Dictionary {
					{"username", player_data.Username},
					{"points", player_data.Points}
				});
			}
		}

		// Enviar a todos
		Rpc(MethodName.SyncPlayers, data);
	}

	public override void _Input(InputEvent _event)
	{
		// Check if chat is open - replace with your actual Globals implementation
		if(Globals.Instance.IsChatOpen)
		{
			return;
		}

		if(Input.IsActionJustPressed("List of players"))
		{
			this.Visible = !this.Visible;
		}
	}
}