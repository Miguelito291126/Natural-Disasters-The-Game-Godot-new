using Godot;
using Godot.Collections;

[GlobalClass]
public partial class HUD : CanvasLayer
{
	public Player Player;
	private float timer = 0.0f;

	public TextureRect Hearth;
	public Label Label;
	public Label Fps;
	public AudioStreamPlayer HearthbeatSound;
	public AnimationPlayer AnimationPlayer;


	public override void _EnterTree()
	{
		// Intentamos obtener el ID del nombre, pero con precaución
		string parentName = GetParent().Name;
		int id;
		if (int.TryParse(parentName, out id))
		{
			SetMultiplayerAuthority(id);
		}
		else
		{
			// Si el nombre no es un número, usamos la autoridad del padre (el Player)
			SetMultiplayerAuthority(GetParent().GetMultiplayerAuthority());
		}
	}

	public override void _Ready()
	{
		Player = GetParent<Player>();
		
		// Nodos
		Hearth = GetNode<TextureRect>("Panel/Panel2/Heart");
		Label = GetNode<Label>("Panel/Label");
		Fps = GetNode<Label>("FPS");
		HearthbeatSound = GetNode<AudioStreamPlayer>("Heartbeat");
		AnimationPlayer = GetNode<AnimationPlayer>("Panel/Panel2/Heart/AnimationPlayer");

		// Solo mostramos el HUD si somos el dueño de este jugador
		this.Visible = IsMultiplayerAuthority();
		
		if(IsMultiplayerAuthority())
		{
			AnimationPlayer.Play("Hearth_Animation");
		}
	}

	public override void _Process(double delta)
	{
		// Si no soy el dueño, no hago nada (ahorra rendimiento)
		if(!IsMultiplayerAuthority()) return;

		// Lógica de latidos
		float normalTemp = 37f;
		float temp = Player.BodyTemperature;
		float deltaTemp = Mathf.Abs(temp - normalTemp);
		
		// Frecuencia basada en temperatura
		float freq = 1.0f + (deltaTemp * 0.15f);
		freq = Mathf.Clamp(freq, 0.8f, 4.0f);
		AnimationPlayer.SpeedScale = freq;

		double interval = 1.0 / freq;

		timer += (float)delta * freq; 
			
		if (timer >= 1.2) // 1.2 es un valor base para un latido tranquilo
		{
			if (!HearthbeatSound.Playing) 
			{
				HearthbeatSound.PitchScale = Mathf.Lerp(1.0f, 1.3f, freq / 4.0f); // El tono sube un poco al agitarse
				HearthbeatSound.Play();
			}
			timer = 0;
		}

		// FPS y Datos
		Fps.Visible = Globals.Instance.GlobalsData.FPS;
		if (Fps.Visible) Fps.Text = "FPS: " + Engine.GetFramesPerSecond();

		// Actualización de Texto
		Label.Text = $"Temperature: {Mathf.Snapped(Globals.Instance.Temperature, 0.1)}Cº\n" +
					$"Humidity: {Mathf.Round(Globals.Instance.Humidity)}%\n" +
					$"Wind Direction: {Mathf.Round(Globals.Instance.ConvertVectorToAngle(Globals.Instance.WindDirection))}\n" +
					$"Wind Speed: {Mathf.Round(Globals.Instance.WindSpeed)}km/s\n" +
					$"Body Heart: {Mathf.Round(Player.Hearth)}%\n" +
					$"Body Temperature: {Mathf.Snapped(Player.BodyTemperature, 0.1)}C\n" +
					$"Body Oxygen: {Mathf.Round(Player.BodyOxygen)}%\n" +
					$"Local Wind Speed: {Mathf.Round(Player.BodyWind)}km/s";
	}


}