using Godot;
using Godot.Collections;

[GlobalClass]
public partial class WarningHud : CanvasLayer
{
	public Label Label;

	public override void _EnterTree()
	{
		// Intentamos obtener el ID del nombre, pero con precaución
		SetMultiplayerAuthority(Multiplayer.GetUniqueId());
	}

	public override void _Ready()
	{
		Label = GetNode<Label>("Panel/Label");

		this.Visible = IsMultiplayerAuthority();
		if(!IsMultiplayerAuthority())
		{
			return ;
		}
	}


	// Called every frame. 'delta' is the elapsed time since the previous frame.
	public override void _Process(double _delta)
	{
		// 1. Verificamos que este HUD pertenezca al jugador local
		if(!IsMultiplayerAuthority())
		{
			return;
		}

		// ELIMINADO: if(!Multiplayer.IsServer()) { return; } 
		// Todos los jugadores necesitan ver la hora, no solo el server.

		if(Globals.Instance.Started)
		{
			// Formateamos la hora y minutos desde Globals
			string timeString = Globals.Instance.Hour.ToString("D2") + ":" + Globals.Instance.Minute.ToString("D2");
			string weatherInfo = "Current Disasters/Weather is: \n" + Globals.Instance.CurrentWeatherAndDisaster;

			if(Globals.Instance.Gamemode != "survival")
			{
				Label.Text = weatherInfo + "\nTime:\n" + timeString;
			}
			else
			{
				// Globals.Instance.Timer debe estar sincronizado para que los clientes vean el TimeLeft
				Label.Text = weatherInfo + "\nTime Left for the next disasters: \n" + 
							Globals.Instance.TimeLeft.ToString("F2") + "\nTime:\n" + timeString;
			}
		}
		else
		{
			Label.Text = "Waiting for players... Time remain: \n" + Globals.Instance.TimeLeft.ToString("F2");
		}
	}


}