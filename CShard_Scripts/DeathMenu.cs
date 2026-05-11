using Godot;
using Godot.Collections;

[GlobalClass]
public partial class DeathMenu : CanvasLayer
{
	public override void _Ready()
	{
		this.Hide();
	}

	protected void _OnReturnPressed()
	{
		if(Multiplayer.MultiplayerPeer is OfflineMultiplayerPeer)
		{
			GetTree().Paused = false;
		}

		GetParent<Player>()._ResetPlayer();
		
		Callable.From(() => {
				Input.MouseMode = Input.MouseModeEnum.Captured;
		}).CallDeferred();

		this.Hide();
	}


	protected void _OnExitPressed()
	{
		Globals.Instance.CloseConection();
	}


}