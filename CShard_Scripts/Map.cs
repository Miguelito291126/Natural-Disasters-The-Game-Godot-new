using System.Linq;
using Godot;
using Godot.Collections;

[GlobalClass]
public partial class Map : Node3D
{
	public MapEnvironment Worldenvironment;
	[Export] public PackedScene SnowDecalScene;
	[Export] public PackedScene SandDecalScene;
	


	public string CurrentDisaster = "";
	public Array<Node3D> ActiveDisasterNodes = new Array<Node3D>();
	public Array<Node3D> ActiveDecals = new Array<Node3D>();
	public bool IsSpawningLightning = false;


	public override void _ExitTree()
	{
		// Desconectar la señal para evitar que Globals llame a un objeto destruido
		Globals.Instance.CurrentWeatherAndDisasterChanged -= _OnDisasterChanged;

		if(Multiplayer.IsServer())
		{
			Globals.Instance.Rpc(Globals.MethodName.SetWeatherAndDisaster, "Original", -1);
			Globals.Instance.Timer.Stop();
			Globals.Instance.Started = false;
		}
	}

	public override void _Ready()
	{
		Worldenvironment = GetNodeOrNull<MapEnvironment>("WorldEnvironment");

		Globals.Instance.Map = this;
		
		if (!Globals.Instance.IsConnected(nameof(Globals.CurrentWeatherAndDisasterChanged), Callable.From((System.Action<string>)_OnDisasterChanged)))
		{
			Globals.Instance.CurrentWeatherAndDisasterChanged += _OnDisasterChanged;
		}

		if(Multiplayer.IsServer())
		{
			Globals.Instance.Rpc(Globals.MethodName.SetWeatherAndDisaster, "Original", -1);

			if(Globals.Instance.Gamemode == "survival")
			{
				if(!OS.HasFeature("dedicated_server"))
				{
					Globals.Instance.MultiplayerPlayerSpawner();
				}

				foreach(int i in Multiplayer.GetPeers())
				{
					Globals.Instance.MultiplayerPlayerSpawner(i);
				}

				Globals.Instance.Timer.WaitTime = Globals.Instance.GlobalsData.TimerDisasters;
				Globals.Instance.Timer.Start();
			}

			else
			{

				if(!OS.HasFeature("dedicated_server"))
				{
					Globals.Instance.MultiplayerPlayerSpawner();
				}

				foreach(int i in Multiplayer.GetPeers())
				{
					Globals.Instance.MultiplayerPlayerSpawner(i);
				}

			}
		}
	}


	// Llama a la función wind para cada objeto en la escena
	public override void _PhysicsProcess(double _delta)
	{
		foreach (var child in GetChildren())
		{
			if (child is Node3D node3D)
			{
				Globals.Instance.Wind(node3D);
			}
		}
	}


	public override void _Process(double _delta)
	{

		if(Multiplayer.IsServer())
		{
			var args = OS.GetCmdlineUserArgs();
			bool isServer = OS.HasFeature("dedicated_server") || (args != null && args.Contains("server"));

			if(isServer)
			{
				Globals.Instance.Started = true;
			}
			else
			{
				if(Multiplayer.MultiplayerPeer == null || Multiplayer.MultiplayerPeer is OfflineMultiplayerPeer)
				{
					Globals.Instance.Started = true;
					return;
				}

				if(Globals.Instance.Gamemode == "survival")
				{
					if(Globals.Instance.PlayersConected.Count > 1)
					{
						Globals.Instance.Started = true;
					}
					else
					{
						Globals.Instance.Started = false;
					}
				}
				else
				{
					Globals.Instance.Started = true;
				}
			}
		}
	}

	protected void _StartSunOriginal()
	{
		Globals.Instance.TemperatureTarget = Globals.Instance.TemperatureOriginal;
		Globals.Instance.HumidityTarget = Globals.Instance.HumidityOriginal;
		Globals.Instance.BradiationTarget = Globals.Instance.BradiationOriginal;
		Globals.Instance.OxygenTarget = Globals.Instance.OxygenOriginal;
		Globals.Instance.PressureTarget = Globals.Instance.PressureOriginal;
		Globals.Instance.WindDirectionTarget = Globals.Instance.WindDirectionOriginal;
		Globals.Instance.WindSpeedTarget = Globals.Instance.WindSpeedOriginal;

		_UpdateEnvironment();
	}


	protected void _StartTsunami()
	{
		Tsunami tsunami = Globals.Instance.TsunamiScene.Instantiate<Tsunami>();
		tsunami.Position = new Vector3(0, 0, 0);
		AddChild(tsunami, true);
		ActiveDisasterNodes.Add(tsunami);

		Globals.Instance.TemperatureTarget = (float)GD.RandRange(20f, 31f);
		Globals.Instance.HumidityTarget = (float)GD.RandRange(0f, 20f);
		Globals.Instance.BradiationTarget = 0f;
		Globals.Instance.OxygenTarget = 100f;
		Globals.Instance.PressureTarget = (float)GD.RandRange(10000f, 10020f);
		Globals.Instance.WindDirectionTarget = new Vector3((float)GD.RandRange(-1f, 1f), 0, (float)GD.RandRange(-1f, 1f));
		Globals.Instance.WindSpeedTarget = (float)GD.RandRange(0f, 10f);

		_UpdateEnvironment();
	}


	protected void _StartThunderstorm()
	{

		Globals.Instance.TemperatureTarget = (float)GD.RandRange(5f, 15f);
		Globals.Instance.HumidityTarget = (float)GD.RandRange(30f, 40f);
		Globals.Instance.BradiationTarget = 0f;
		Globals.Instance.OxygenTarget = 100f;
		Globals.Instance.PressureTarget = (float)GD.RandRange(8000f, 9000f);
		Globals.Instance.WindDirectionTarget = new Vector3((float)GD.RandRange(-1f, 1f), 0, (float)GD.RandRange(-1f, 1f));
		Globals.Instance.WindSpeedTarget = (float)GD.RandRange(0f, 30f);

		_UpdateEnvironment();
		_SpawnLightningTimer();
	}


	protected void _StartMeteorShower()
	{
		Globals.Instance.TemperatureTarget = (float)GD.RandRange(20f, 31f);
		Globals.Instance.HumidityTarget = (float)GD.RandRange(0f, 20f);
		Globals.Instance.PressureTarget = (float)GD.RandRange(10000f, 10020f);
		Globals.Instance.BradiationTarget = 0f;
		Globals.Instance.OxygenTarget = 100f;
		Globals.Instance.WindDirectionTarget = new Vector3((float)GD.RandRange(-1f, 1f), 0, (float)GD.RandRange(-1f, 1f));
		Globals.Instance.WindSpeedTarget = (float)GD.RandRange(0f, 10f);

		_SpawnMeteorShowerTimer();
		_UpdateEnvironment();
	}

	protected void _StartBlizzard()
	{
		Globals.Instance.TemperatureTarget = (float)GD.RandRange(-20f, -35f);
		Globals.Instance.HumidityTarget = (float)GD.RandRange(20f, 30f);
		Globals.Instance.BradiationTarget = 0f;
		Globals.Instance.OxygenTarget = 100f;
		Globals.Instance.PressureTarget = (float)GD.RandRange(8000f, 9020f);
		Globals.Instance.WindDirectionTarget = new Vector3((float)GD.RandRange(-1f, 1f), 0, (float)GD.RandRange(-1f, 1f));
		Globals.Instance.WindSpeedTarget = (float)GD.RandRange(40f, 50f);


		_UpdateEnvironment();
	}


	protected void _StartSandstorm()
	{
		Globals.Instance.TemperatureTarget = (float)GD.RandRange(30f, 35f);
		Globals.Instance.HumidityTarget = (float)GD.RandRange(0f, 5f);
		Globals.Instance.BradiationTarget = 0f;
		Globals.Instance.OxygenTarget = 100f;
		Globals.Instance.PressureTarget = (float)GD.RandRange(10000f, 10020f);
		Globals.Instance.WindDirectionTarget = new Vector3((float)GD.RandRange(-1f, 1f), 0, (float)GD.RandRange(-1f, 1f));
		Globals.Instance.WindSpeedTarget = (float)GD.RandRange(30f, 50f);

		_UpdateEnvironment();
	}

	protected void _StartVolcano()
	{
		Globals.Instance.TemperatureTarget = (float)GD.RandRange(20f, 31f);
		Globals.Instance.HumidityTarget = (float)GD.RandRange(0f, 20f);
		Globals.Instance.BradiationTarget = 0f;
		Globals.Instance.OxygenTarget = 100f;
		Globals.Instance.PressureTarget = (float)GD.RandRange(10000f, 10020f);
		Globals.Instance.WindDirectionTarget = new Vector3((float)GD.RandRange(-1f, 1f), 0, (float)GD.RandRange(-1f, 1f));
		Globals.Instance.WindSpeedTarget = (float)GD.RandRange(0f, 10f);

		Vector3 rand_pos = new Vector3((float)GD.RandRange(0f, 4097f), 1000f, (float)GD.RandRange(0f, 4097f));
		PhysicsDirectSpaceState3D space_state = GetWorld3D().DirectSpaceState;
		PhysicsRayQueryParameters3D ray = PhysicsRayQueryParameters3D.Create(rand_pos, rand_pos - new Vector3(0f, 10000f, 0f));
		Dictionary result = space_state.IntersectRay(ray);

		Volcano volcano = Globals.Instance.VolcanoScene.Instantiate<Volcano>();
		if(result.ContainsKey("position"))
		{
			volcano.Position = (Vector3)result["position"];
		}
		else
		{
			volcano.Position = new Vector3((float)GD.RandRange(0f, 4097f), 0f, (float)GD.RandRange(0f, 4097f));
		}
		ActiveDisasterNodes.Add(volcano);

		AddChild(volcano, true);

		_UpdateEnvironment();
	}


	protected void _StartTornado()
	{

		Vector3 rand_pos = new Vector3((float)GD.RandRange(0f, 4097f), 1000f, (float)GD.RandRange(0f, 4097f));
		PhysicsDirectSpaceState3D space_state = GetWorld3D().DirectSpaceState;
		PhysicsRayQueryParameters3D ray = PhysicsRayQueryParameters3D.Create(rand_pos, rand_pos - new Vector3(0f, 10000f, 0f));
		Dictionary result = space_state.IntersectRay(ray);


		Tornado tornado = Globals.Instance.TornadoScene.Instantiate<Tornado>();
		if(result.ContainsKey("position"))
		{
			tornado.Position = (Vector3)result["position"];
		}
		else
		{
			tornado.Position = new Vector3((float)GD.RandRange(0f, 4097f), 0f, (float)GD.RandRange(0f, 4097f));
		}
		AddChild(tornado, true);
		ActiveDisasterNodes.Add(tornado);

		Globals.Instance.TemperatureTarget = (float)GD.RandRange(5f, 15f);
		Globals.Instance.HumidityTarget = (float)GD.RandRange(30f, 40f);
		Globals.Instance.BradiationTarget = 0f;
		Globals.Instance.OxygenTarget = 100f;
		Globals.Instance.PressureTarget = (float)GD.RandRange(8000f, 9000f);
		Globals.Instance.WindDirectionTarget = new Vector3((float)GD.RandRange(-1f, 1f), 0, (float)GD.RandRange(-1f, 1f));
		Globals.Instance.WindSpeedTarget = (float)GD.RandRange(0f, 30f);

		_UpdateEnvironment();
		_SpawnLightningTimer();
	}


	protected void _StartAcidRain()
	{
		Globals.Instance.TemperatureTarget = (float)GD.RandRange(20f, 31f);
		Globals.Instance.HumidityTarget = (float)GD.RandRange(0f, 20f);
		Globals.Instance.BradiationTarget = 100f;
		Globals.Instance.OxygenTarget = 100f;
		Globals.Instance.PressureTarget = (float)GD.RandRange(10000f, 10020f);
		Globals.Instance.WindDirectionTarget = new Vector3((float)GD.RandRange(-1f, 1f), 0, (float)GD.RandRange(-1f, 1f));
		Globals.Instance.WindSpeedTarget = (float)GD.RandRange(0f, 10f);

		_UpdateEnvironment();
	}

	protected void _StartEarthquake()
	{
		Globals.Instance.TemperatureTarget = (float)GD.RandRange(20f, 31f);
		Globals.Instance.HumidityTarget = (float)GD.RandRange(0f, 20f);
		Globals.Instance.BradiationTarget = 0f;
		Globals.Instance.OxygenTarget = 100f;
		Globals.Instance.PressureTarget = (float)GD.RandRange(10000f, 10020f);
		Globals.Instance.WindDirectionTarget = new Vector3((float)GD.RandRange(-1f, 1f), 0, (float)GD.RandRange(-1f, 1f));
		Globals.Instance.WindSpeedTarget = (float)GD.RandRange(0f, 10f);

		var earquake = Globals.Instance.EarthquakeScene.Instantiate<Earthquake>();
		AddChild(earquake, true);
		ActiveDisasterNodes.Add(earquake);

		_UpdateEnvironment();
	}


	protected void _StartSun()
	{
		Globals.Instance.TemperatureTarget = (float)GD.RandRange(20f, 31f);
		Globals.Instance.HumidityTarget = (float)GD.RandRange(0f, 20f);
		Globals.Instance.BradiationTarget = 0f;
		Globals.Instance.OxygenTarget = 100f;
		Globals.Instance.PressureTarget = (float)GD.RandRange(10000f, 10020f);
		Globals.Instance.WindDirectionTarget = new Vector3((float)GD.RandRange(-1f, 1f), 0, (float)GD.RandRange(-1f, 1f));
		Globals.Instance.WindSpeedTarget = (float)GD.RandRange(0f, 10f);

		_UpdateEnvironment();
	}


	protected void _StartCloud()
	{
		Globals.Instance.TemperatureTarget = (float)GD.RandRange(20f, 25f);
		Globals.Instance.HumidityTarget = (float)GD.RandRange(10f, 30f);
		Globals.Instance.BradiationTarget = 0f;
		Globals.Instance.OxygenTarget = 100;
		Globals.Instance.PressureTarget = (float)GD.RandRange(9000, 10000);
		Globals.Instance.WindDirectionTarget = new Vector3((float)GD.RandRange( - 1, 1), 0, (float)GD.RandRange( - 1, 1));
		Globals.Instance.WindSpeedTarget = (float)GD.RandRange(0, 10);


		_UpdateEnvironment();
	}


	protected void _StartRaining()
	{

		Globals.Instance.TemperatureTarget = (float)GD.RandRange(10f, 20f);
		Globals.Instance.HumidityTarget = (float)GD.RandRange(20f, 40f);
		Globals.Instance.BradiationTarget = 0f;
		Globals.Instance.OxygenTarget = 100f;
		Globals.Instance.PressureTarget = (float)GD.RandRange(9000f, 9020f);
		Globals.Instance.WindDirectionTarget = new Vector3((float)GD.RandRange(-1f, 1f), 0, (float)GD.RandRange(-1f, 1f));
		Globals.Instance.WindSpeedTarget = (float)GD.RandRange(0f, 20f);

		_UpdateEnvironment();
	}

	protected void _StartStorm()
	{
		Globals.Instance.TemperatureTarget = (float)GD.RandRange(5f, 15f);
		Globals.Instance.HumidityTarget = (float)GD.RandRange(30f, 40f);
		Globals.Instance.BradiationTarget = 0f;
		Globals.Instance.OxygenTarget = 100f;
		Globals.Instance.PressureTarget = (float)GD.RandRange(8000f, 9000f);
		Globals.Instance.WindDirectionTarget = new Vector3((float)GD.RandRange(-1f, 1f), 0, (float)GD.RandRange(-1f, 1f));
		Globals.Instance.WindSpeedTarget = (float)GD.RandRange(30f, 60f);

		_UpdateEnvironment();
		_SpawnLightningTimer();
	}


	protected void _StartDustStorm()
	{
		Globals.Instance.TemperatureTarget = (float)GD.RandRange(30f, 40f);
		Globals.Instance.HumidityTarget = (float)GD.RandRange(0f, 10f);
		Globals.Instance.BradiationTarget = 0f;
		Globals.Instance.OxygenTarget = 0f;
		Globals.Instance.PressureTarget = (float)GD.RandRange(10000f, 10020f);
		Globals.Instance.WindDirectionTarget = new Vector3((float)GD.RandRange(-1f, 1f), 0, (float)GD.RandRange(-1f, 1f));
		Globals.Instance.WindSpeedTarget = (float)GD.RandRange(0f, 50f);

		_UpdateEnvironment();
	}

	protected void _OnDisasterChanged(string new_disaster)
	{
		// Limpiar el desastre anterior
		_CleanupDisaster();
		CurrentDisaster = new_disaster;

		// Iniciar el nuevo desastre usando switch
		switch (new_disaster)
		{
			case "Tsunami":
				_StartTsunami();
				break;

			case "Thunderstorm":
				_StartThunderstorm();
				break;

			case "Meteors shower":
				_StartMeteorShower();
				break;

			case "blizzard":
				_StartBlizzard();
				_SpawnDecals(SnowDecalScene, 200);
				break;

			case "Sand Storm":
				_StartSandstorm();
				_SpawnDecals(SandDecalScene, 200);
				break;

			case "Volcano":
				_StartVolcano();
				break;

			case "Tornado":
				_StartTornado();
				break;

			case "Acid rain":
				_StartAcidRain();
				break;

			case "Earthquake":
				_StartEarthquake();
				break;

			case "Sun":
				_StartSun();
				break;

			case "Cloud":
				_StartCloud();
				break;

			case "Raining":
				_StartRaining();
				break;

			case "Storm":
				_StartStorm();
				break;

			case "Dust Storm":
				_StartDustStorm();
				break;

			default:
				// Esto se ejecuta si new_disaster no coincide con ninguno de los anteriores
				_StartSunOriginal();
				break;
		}
	}

	protected void _CleanupDisaster()
	{
		IsSpawningLightning = false;


		// Limpiar efectos del desastre anterior
		foreach(Node3D node in ActiveDisasterNodes)
		{
			if(IsInstanceValid(node))
			{
				node.QueueFree();
			}
		}
		ActiveDisasterNodes.Clear();

		if(Globals.Instance.Gamemode == "survival")
		{
			Globals.Instance.Rpc(Globals.MethodName.AddPoints, 100);
		}
	}

	protected void _SpawnDecals(PackedScene scene, int amount)
	{
		if(!Multiplayer.IsServer())
		{
			return ;
		}

		var space_state = GetWorld3D().DirectSpaceState;

		for (int i = 0; i < amount; i++)
		{


			var rand_pos = new Vector3((float)GD.RandRange(0, 4097), 1000, (float)GD.RandRange(0, 4097));
	
			var ray = PhysicsRayQueryParameters3D.Create(rand_pos, rand_pos - new Vector3(0, 2000, 0));

			var result = space_state.IntersectRay(ray);

			if(result.ContainsKey("position"))
			{
				Decal decal = scene.Instantiate<Decal>();


				// Tamañó aleatorio entre 3 y 500
				float random_size = (float)(float)GD.RandRange(3.0, 500.0);
				decal.Size = new Vector3(random_size, random_size, random_size);

				decal.Position = (Vector3)result["position"] + new Vector3(0, 0.05f, 0);
				decal.Rotation = new Vector3(0, (float)(float)GD.RandRange(0, Mathf.Tau), 0);

				AddChild(decal, true);
				ActiveDecals.Append(decal);
			}
		}
	}


	protected async void _SpawnDecalsOverTime(PackedScene scene, int total, float delay)
	{
		for (int i = 0; i < total; i++)
		{
			_SpawnDecals(scene, 1);
			await ToSignal(GetTree().CreateTimer(delay), SceneTreeTimer.SignalName.Timeout);
		}
	}


	protected async void _SpawnMeteorShowerTimer()
	{
		while(Globals.Instance.CurrentWeatherAndDisaster == "Meteors shower")
		{
			Meteors meteor = Globals.Instance.MeteorScene.Instantiate<Meteors>();
			Vector3 rand_pos = new Vector3((float)GD.RandRange(0, 4097), 1000, (float)GD.RandRange(0, 4097));
			meteor.Position = rand_pos;
			AddChild(meteor, true);
			ActiveDisasterNodes.Add(meteor);

			await ToSignal(GetTree().CreateTimer(1), SceneTreeTimer.SignalName.Timeout);
		}
	}

	protected void _UpdateEnvironment()
	{
		// 1. Verificación de seguridad: ¿El nodo Worldenvironment sigue existiendo?
		if (!GodotObject.IsInstanceValid(this) || !GodotObject.IsInstanceValid(Worldenvironment))
		{
			return;
		}

		var player = Globals.Instance.LocalPlayer;
		if (!GodotObject.IsInstanceValid(player))
		{
			return;
		}

		var is_outdoor = Globals.Instance.is_outdoor(player);

		// Usar una variable local para el environment para evitar múltiples llamadas al getter nativo
		var env = Worldenvironment.Environment;
		if (env == null) return;

		// Ajustes por desastre
		switch(CurrentDisaster)
		{
			case "blizzard":
			{
				player.SnowNode.Emitting = is_outdoor;
				Worldenvironment.Environment.VolumetricFogAlbedo = new Color(1, 1, 1);
				break; }
			case "Sand Storm":
			{
				player.SandNode.Emitting = is_outdoor;
				Worldenvironment.Environment.VolumetricFogAlbedo = new Color(1, 0.647059f, 0);
				break; }
			case "Acid rain":
			{
				player.RainNode.Emitting = is_outdoor;
				Worldenvironment.Environment.VolumetricFogAlbedo = new Color(0, 1, 0);
				break; }
			case "Dust Storm":
			{
				player.DustNode.Emitting = is_outdoor;
				Worldenvironment.Environment.VolumetricFogAlbedo = new Color(0, 0, 0);
				break; }
			default:
			{
				player.SnowNode.Emitting = false;
				player.SandNode.Emitting = false;
				player.DustNode.Emitting = false;
				Worldenvironment.Environment.VolumetricFogAlbedo = new Color(1, 1, 1);
				break; }
		}


		// Cuando hay lluvia/tormenta u otros eventos que requieren niebla, activarla s�lo si el jugador est� al aire libre
		var foggy_disasters = new Array<string>{"Thunderstorm", "Raining", "Storm", "Tornado", "blizzard", "Sand Storm", "Cloud", "Acid rain", "Dust Storm"};
		var rain_disasters = new Array<string>{"Thunderstorm", "Raining", "Storm", "Tornado", "Acid rain"};
		Worldenvironment.IsCloudy = foggy_disasters.Contains(CurrentDisaster);
		Worldenvironment.IsRaining = rain_disasters.Contains(CurrentDisaster);
		Worldenvironment.Environment.VolumetricFogEnabled = Worldenvironment.IsCloudy && is_outdoor;

		// Nodos de partculas generales
		player.RainNode.Emitting = (Worldenvironment.IsRaining) && is_outdoor;


		// Ajuste de nubes

		((ShaderMaterial)Worldenvironment.Environment.Sky.SkyMaterial).SetShaderParameter("clouds_fuzziness", ( Worldenvironment.IsCloudy ? 0.25 : 1 ));
	}

	protected async void _SpawnLightningTimer()
	{
		if(IsSpawningLightning)
		{
			return ;
		}

		// Evitar m�ltiples instancias del timer
		IsSpawningLightning = true;

		while(Globals.Instance.CurrentWeatherAndDisaster == "Thunderstorm" && IsSpawningLightning)
		{
			var player = Globals.Instance.LocalPlayer;

			if(GodotObject.IsInstanceValid(player) && Globals.Instance.is_outdoor(player))
			{
				if((float)GD.RandRange(1, 25) == 25)
				{
					Thunder lighting = Globals.Instance.ThunderstormScene.Instantiate<Thunder>();
					var rand_pos = new Vector3((float)GD.RandRange(0, 4097), 1000, (float)GD.RandRange(0, 4097));
					var space_state = GetWorld3D().DirectSpaceState;

					if(space_state != null)
					{
						var ray = PhysicsRayQueryParameters3D.Create(rand_pos, rand_pos - new Vector3(0, 10000, 0));
						var result = space_state.IntersectRay(ray);

						if(result.ContainsKey("position"))
						{
							lighting.Position = (Vector3)result["position"];
						}
						else
						{
							lighting.Position = new Vector3((float)GD.RandRange(0, 4097), 0, (float)GD.RandRange(0, 4097));
						}
					}
					else
					{
						lighting.Position = new Vector3((float)GD.RandRange(0, 4097), 0, (float)GD.RandRange(0, 4097));
					}

					AddChild(lighting, true);
					ActiveDisasterNodes.Add(lighting);
				}
			}

			await ToSignal(GetTree().CreateTimer(0.5), SceneTreeTimer.SignalName.Timeout);
		}

		IsSpawningLightning = false;
	}

}