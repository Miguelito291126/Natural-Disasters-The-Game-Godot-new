using Godot;
using Godot.Collections;

[GlobalClass]
public partial class Earthquake : Node3D
{
	[Export] public float Magnitude = 7;
	[Export] public float MagnitudeModifier = 0;
	public ulong NextPhysicsTime = Time.GetTicksMsec();
	public ulong SpawnTime = Time.GetTicksMsec();
	[Export] public Array<int> Life = new Array<int> {15, 20};


	public AudioStreamPlayer3D StartWeakEarthquake;
	public AudioStreamPlayer3D StartStrongEarthquake;
	public AudioStreamPlayer EarthquakeSound;
	public AudioStreamPlayer3D EarthqueakeAftershotSound;

	public override void _PhysicsProcess(double delta)
	{
		MagnitudeModulateSound();
		ProcessMagnitude();
		MagnitudeModifierIncrement(delta);
	}


	public override void _Process(double delta)
	{
		DestroyAllHouses();
	}

	public async override void _Ready()
	{
		StartWeakEarthquake = GetNode<AudioStreamPlayer3D>("earquake_start_sound_weak");
		StartStrongEarthquake = GetNode<AudioStreamPlayer3D>("earquake_start_sound_strong");
		EarthquakeSound = GetNode<AudioStreamPlayer>("earquake_sound");
		EarthqueakeAftershotSound = GetNode<AudioStreamPlayer3D>("earqueake_aftershot");
		PlayInitialSounds();
		DestroyAllHouses();

		await ToSignal(GetTree().CreateTimer(GD.RandRange(Life[0], Life[1])), SceneTreeTimer.SignalName.Timeout);
		EarthquakeDecay();
	}

	public void PlayInitialSounds()
	{
		if(Magnitude > 5)
		{
			StartStrongEarthquake.Play();
		}
		else
		{
			StartWeakEarthquake.Play();
		}
	}

	public void EarthquakeDecay()
	{
		if(GD.RandRange(1, 2) == 1)
		{
			CreateEarthquakeWithParent();
		}
		QueueFree();
	}

	// Esto libera el nodo actual, elimin�ndolo del escenario
	public void SendClientsideEffects(Player ply, float amplitude)
	{
		if(GD.Randi() % 8 == 0)
		{
			ply.CameraNode.StartScreenShake(0.6f, amplitude * 2, 25);
		}
	}

	public bool CanDoPhysics(ulong next_time)
	{
		if(Engine.GetFramesPerSecond() > 0)
		{
			// Asegrate de que no estemos dividiendo por cero
			ulong current_time = (ulong)Engine.GetFramesDrawn() / (ulong)Engine.GetFramesPerSecond();
			// Obtener el tiempo actual del juego
			if(current_time >= NextPhysicsTime)
			{
				if(Globals.Instance.HitChance(1))
				{
					NextPhysicsTime = current_time + ((ulong)GD.RandRange(0, 250) / 100);
				}
				else
				{
					NextPhysicsTime = current_time + next_time;
				}
				return true;
			}
		}
		return false;
	}

	public void DoPhysics()
	{
		// Obtener el valor del ConVar "gdisasters_envearthquake_simquality"
		float mag = Magnitude * MagnitudeModifier;


		// Si no podemos hacer fsica en este momento o la magnitud es menor que 3, no hacemos nada
		if(mag < 3)
		{
			Globals.Instance.PrintRole("Mag its low");
			return ;
		}

		Vector3 vec = (mag * 25) * new Vector3(GD.RandRange( - 15, 15) / 10, GD.RandRange( - 5, 4) / 10, GD.RandRange( - 15, 15) / 10);
		Vector3 ang_vv = new Vector3((GD.RandRange( - 15, 15) / 10), GD.RandRange( - 5, 4) / 10, GD.RandRange( - 15, 15) / 10) * (mag * 8);


		// Si hay una posibilidad de golpear, incrementamos la velocidad angular
		if(Globals.Instance.HitChance(2))
		{
			ang_vv *= 20;
		}


		// Aplicar efectos a los jugadores
		foreach(Node3D v in GetTree().GetNodesInGroup("player"))
		{
			if(v is Player player && player.IsOnFloor())
			{
				if(3 <= mag && mag < 4)
				{
					
				}
				else if(4 <= mag && mag < 5)
				{
					
				}
				else if(5 <= mag && mag < 6)
				{
					
				}
				else if(6 <= mag && mag < 7)
				{
					
				}
				else if(7 <= mag && mag < 8)
				{
					
				}
				else if(8 <= mag && mag < 9)
				{
					player.SetVelocity(vec * 1.125f);
				}
				else if(9 <= mag && mag < 10)
				{
					player.SetVelocity(vec * 1.5f);
				}
				else if(10 <= mag && mag < 11)
				{
					player.SetVelocity(vec * 2f);
				}
				else if(11 <= mag && mag < 12)
				{
					player.SetVelocity(vec * 2.125f);
				}
				else if(12 <= mag && mag < 13)
				{
					player.SetVelocity(vec * 2.5f);
				}
			}
		}


		// Aplicar efectos a las entidades
		foreach(Node3D v in GetTree().GetNodesInGroup("movable_objects"))
		{
			if(v is RigidBody3D rigidBody3D)
			{
				var vel_mod = 1 - Mathf.Clamp(rigidBody3D.GetLinearVelocity().Length() / 2000, 0, 1);
				var ang_v = ang_vv * vel_mod;

				if(3 <= mag && mag < 4)
				{
					if(GD.RandRange(1, 2) == 1)
					{
						rigidBody3D.ApplyImpulse(ang_v);
					}
				}
				else if(4 <= mag && mag < 5)
				{
					if(GD.RandRange(1, 2) == 1)
					{
						rigidBody3D.ApplyImpulse(ang_v);
						Unfreeze(rigidBody3D, mag);
					}
				}
				else if(5 <= mag && mag < 6)
				{
					if(GD.RandRange(1, 2) == 1)
					{
						rigidBody3D.ApplyImpulse(ang_v);
						Unfreeze(rigidBody3D, mag);
					}
				}
				else if(6 <= mag && mag < 7)
				{
					if(GD.RandRange(1, 2) == 1)
					{
						rigidBody3D.ApplyImpulse(ang_v * 2);
						Unfreeze(rigidBody3D, mag);
					}
				}
				else if(7 <= mag && mag < 8)
				{
					if(GD.RandRange(1, 2) == 1)
					{
						rigidBody3D.ApplyImpulse(ang_v * 4);
						Unfreeze(rigidBody3D, mag);
					}
				}
				else if(8 <= mag && mag < 9)
				{
					if(GD.RandRange(1, 2) == 1)
					{
						rigidBody3D.ApplyImpulse(ang_v * 8);
						Unfreeze(rigidBody3D, mag);
					}
				}
				else if(9 <= mag && mag < 10)
				{
					if(GD.RandRange(1, 2) == 1)
					{
						rigidBody3D.ApplyImpulse(ang_v * 12);
						Unfreeze(rigidBody3D, mag);
					}
				}
				else if(10 <= mag && mag < 11)
				{
					if(GD.RandRange(1, 2) == 1)
					{
						rigidBody3D.ApplyImpulse(ang_v * 24);
						Unfreeze(rigidBody3D, mag);
					}
				}
				else if(11 <= mag && mag < 12)
				{
					if(GD.RandRange(1, 2) == 1)
					{
						rigidBody3D.ApplyImpulse(ang_v * 36);
						Unfreeze(rigidBody3D, mag);
					}
				}
				else if(12 <= mag && mag < 13)
				{
					if(GD.RandRange(1, 2) == 1)
					{
						rigidBody3D.ApplyImpulse(ang_v * 40);
						Unfreeze(rigidBody3D, mag);
					}
				}
			}
			else if(v is House house)
			{
				if(GD.RandRange(1, 2) == 1)
				{
					Destroy(house);
				}
			}
		}
	}

	public void Unfreeze(Node3D v, float _mag)
	{
		if(GD.RandRange(1, 1024 - (25.6 * _mag)) == 1)
		{
			if(GodotObject.IsInstanceValid(v) && v is RigidBody3D rigidBody3D)	
			{
				rigidBody3D.Sleeping = false;
				rigidBody3D.Freeze = false;
			}
		}
		if(GD.RandRange(1, 512 - (25.6 * _mag)) == 1)
		{
			if(GodotObject.IsInstanceValid(v) && v is House house)
			{
				Destroy(house);
			}
		}
	}

	public void Destroy(House v)
	{
		if(IsInstanceValid(v))
		{
	
			v.Rpc(House.MethodName.Destroy);

		}
	}

	public void DestroyAllHouses()
	{

		// Destruir todas las casas al iniciar el terremoto
		foreach(Node3D house in GetTree().GetNodesInGroup("Hause"))
		{
			if(house is House house1 && IsInstanceValid(house1) )
			{
				Destroy(house1);
			}
		}
	}


	public void MagnitudeModulateSound()
	{
		float volume = this.Magnitude;
		// Asumiendo que self.magnitude es una propiedad que representa la magnitud del terremoto
		float vol_mod = Mathf.Pow(volume / 10, 3);
		float distance_mod = 0;


		// Calcula la modulaci�n de volumen basada en la distancia al jugador (ejemplo simplificado)
		Vector3 local_player_pos = Globals.Instance.LocalPlayer.Position;
		// Obtn la posicin del jugador local
		PhysicsRayQueryParameters3D ray_params = PhysicsRayQueryParameters3D.Create(local_player_pos, local_player_pos + new Vector3(0, 0,  - 3000));
		Dictionary ray_result = GetWorld3D().DirectSpaceState.IntersectRay(ray_params);
		if(ray_result.Count > 0)
		{
			distance_mod = 1 - (((Vector3)ray_result["position"]).DistanceTo(local_player_pos) / 3000);
		}

		vol_mod *= distance_mod;


		if (EarthquakeSound != null && !EarthquakeSound.Playing)
		{
			EarthquakeSound.Play();


			EarthquakeSound.VolumeDb = vol_mod;
		}


		
	}


	public void CreateEarthquakeWithParent()
	{
		var decider = GD.Randi() % (int)Mathf.Floor(Magnitude * 2) == 1;
		if (!decider)
		{
			if ((int)Mathf.Floor(Magnitude) > 1)
			{
				EarthqueakeAftershotSound.Play();
				float aftershock_magnitude = Mathf.Clamp(Mathf.Floor(Magnitude) - (GD.Randi() % 3), 1, 12);
				
				// Cargamos e instanciamos
				var scene = ResourceLoader.Load<PackedScene>("res://Scenes/earthquake.tscn");
				Earthquake aftershock = scene.Instantiate<Earthquake>();
				
				aftershock.Magnitude = (int)aftershock_magnitude;
				
				// Importante: Añadir al árbol ANTES de modificar la posición global
				GetParent().AddChild(aftershock, true);
				
				// Corregido: Asignación directa de la posición global
				if (GetParent() is Node3D parent3D)
				{
					aftershock.GlobalPosition = parent3D.GlobalPosition;
				}

				aftershock.Show();
			}
		}
		else
		{
			EarthqueakeAftershotSound.Play();
			var foreshock_magnitude = Mathf.Clamp(Mathf.Floor(Magnitude) - GD.Randi() % 3, 1, 12);
			var scene = ResourceLoader.Load<PackedScene>("res://Scenes/earthquake.tscn");
			Earthquake foreshock = scene.Instantiate<Earthquake>();
			
			foreshock.Magnitude = (int)foreshock_magnitude;
			foreshock.Position = Position;
			GetParent().AddChild(foreshock, true);

			if (GetParent() is Node3D parent3D)
			{
				foreshock.GlobalPosition = parent3D.GlobalPosition;
			}

			foreshock.Show();
		}
	}

	public void MagnitudeModifierIncrement(double delta)
	{

		// Ajustar el valor de MagnitudeModifier
		MagnitudeModifier = Mathf.Clamp(MagnitudeModifier + ((float)delta / 4), 0, 1);
	}

	public float GetRealMagnitude()
	{
		return Magnitude * MagnitudeModifier;
	}

	public void ProcessMagnitude()
	{
		var mag = Magnitude * MagnitudeModifier;

		if(mag >= 0 && mag < 1)
		{
			Globals.Instance.PrintRole("Mag its very low");
		}
		else if(mag >= 1 && mag < 2)
		{
			MagnitudeOne();
		}
		else if(mag >= 2 && mag < 3)
		{
			MagnitudeTwo();
		}
		else if(mag >= 3 && mag < 4)
		{
			MagnitudeThree();
		}
		else if(mag >= 4 && mag < 5)
		{
			MagnitudeFour();
		}
		else if(mag >= 5 && mag < 6)
		{
			MagnitudeFive();
		}
		else if(mag >= 6 && mag < 7)
		{
			MagnitudeSix();
		}
		else if(mag >= 7 && mag < 8)
		{
			MagnitudeSeven();
		}
		else if(mag >= 8 && mag < 9)
		{
			MagnitudeEight();
		}
		else if(mag >= 9 && mag < 10)
		{
			MagnitudeNine();
		}
		else if(mag >= 10 && mag < 11)
		{
			MagnitudeTen();
		}
		else if(mag >= 11 && mag < 12)
		{
			MagnitudeEleven();
		}
		else if(mag >= 12 && mag < 13)
		{
			MagnitudeTwelve();
		}
		else
		{
			Globals.Instance.PrintRole("Mag its very high");
		}
	}

	public void MagnitudeOne()
	{
		var percentage = Mathf.Clamp(Magnitude / 1.99, 0, 1);
		var bxa = GD.RandRange( - 5, 5) / 100;
		var bya = GD.RandRange( - 5, 5) / 100;
		var mxa = (GD.RandRange( - 4, 4) / 100) * percentage;
		var mya = (GD.RandRange( - 4, 4) / 100) * percentage;
		var xa = bxa + mxa;
		var ya = bya + mya;
		foreach(Node3D v in GetTree().GetNodesInGroup("player"))
		{
			if(v is Player player && player.IsOnFloor())
			{
				SendClientsideEffects(player, 0.1f);
			}
		}

		DoPhysics();
	}

	public void MagnitudeTwo()
	{
		var percentage = Mathf.Clamp(Magnitude / 2.99, 0, 1);
		var bxa = GD.RandRange( - 10, 10) / 100;
		var bya = GD.RandRange( - 10, 10) / 100;
		var mxa = (GD.RandRange( - 5, 5) / 100) * percentage;
		var mya = (GD.RandRange( - 5, 5) / 100) * percentage;
		var xa = bxa + mxa;
		var ya = bya + mya;
		foreach(Node3D v in GetTree().GetNodesInGroup("player"))
		{
			if(v is Player player && player.IsOnFloor())
			{
				SendClientsideEffects(player, 0.2f);
			}
		}
		DoPhysics();
	}

	public void MagnitudeThree()
	{
		var percentage = Mathf.Clamp(Magnitude / 3.99, 0, 1);
		var bxa = GD.RandRange( - 15, 15) / 100;
		var bya = GD.RandRange( - 15, 15) / 100;
		var mxa = (GD.RandRange( - 5, 5) / 100) * percentage;
		var mya = (GD.RandRange( - 5, 5) / 100) * percentage;
		var xa = bxa + mxa;
		var ya = bya + mya;
		foreach(Node3D v in GetTree().GetNodesInGroup("player"))
		{
			if(v is Player player && player.IsOnFloor())
			{
				SendClientsideEffects(player, 0.3f);
			}
		}
		DoPhysics();
	}

	public void MagnitudeFour()
	{
		var percentage = Mathf.Clamp(Magnitude / 4.99, 0, 1);
		var bxa = GD.RandRange( - 20, 20) / 100;
		var bya = GD.RandRange( - 20, 20) / 100;
		var mxa = (GD.RandRange( - 5, 5) / 100) * percentage;
		var mya = (GD.RandRange( - 5, 5) / 100) * percentage;
		var xa = bxa + mxa;
		var ya = bya + mya;
		foreach(Node3D v in GetTree().GetNodesInGroup("player"))
		{
			if(v is Player player && player.IsOnFloor())
			{
				SendClientsideEffects(player, 0.4f);
			}
		}
		DoPhysics();
	}

	public void MagnitudeFive()
	{
		var percentage = Mathf.Clamp(Magnitude / 5.99, 0, 1);
		var bxa = GD.RandRange( - 25, 25) / 100;
		var bya = GD.RandRange( - 25, 25) / 100;
		var mxa = (GD.RandRange( - 5, 5) / 100) * percentage;
		var mya = (GD.RandRange( - 5, 5) / 100) * percentage;
		var xa = bxa + mxa;
		var ya = bya + mya;
		foreach(Node3D v in GetTree().GetNodesInGroup("player"))
		{
			if(v is Player player && player.IsOnFloor())
			{
				SendClientsideEffects(player, 0.5f);
			}
		}
		DoPhysics();
	}

	public void MagnitudeSix()
	{
		var percentage = Mathf.Clamp(Magnitude / 6.99, 0, 1);
		var bxa = GD.RandRange( - 30, 30) / 100;
		var bya = GD.RandRange( - 30, 30) / 100;
		var mxa = (GD.RandRange( - 5, 5) / 100) * percentage;
		var mya = (GD.RandRange( - 5, 5) / 100) * percentage;
		var xa = bxa + mxa;
		var ya = bya + mya;
		foreach(Node3D v in GetTree().GetNodesInGroup("player"))
		{
			if(v is Player player && player.IsOnFloor())
			{
				SendClientsideEffects(player, 2f);
			}
		}
		DoPhysics();
	}

	public void MagnitudeSeven()
	{
		var percentage = Mathf.Clamp(Magnitude / 7.99, 0, 1);
		var bxa = GD.RandRange( - 35, 35) / 100;
		var bya = GD.RandRange( - 35, 35) / 100;
		var mxa = (GD.RandRange( - 5, 5) / 100) * percentage;
		var mya = (GD.RandRange( - 5, 5) / 100) * percentage;
		var xa = bxa + mxa;
		var ya = bya + mya;
		foreach(Node3D v in GetTree().GetNodesInGroup("player"))
		{
			if(v is Player player && player.IsOnFloor())
			{
				SendClientsideEffects(player, 4f);
			}
		}
		DoPhysics();
	}

	public void MagnitudeEight()
	{
		var percentage = Mathf.Clamp(Magnitude / 8.99, 0, 1);
		var bxa = GD.RandRange( - 40, 40) / 100;
		var bya = GD.RandRange( - 40, 40) / 100;
		var mxa = (GD.RandRange( - 5, 5) / 100) * percentage;
		var mya = (GD.RandRange( - 5, 5) / 100) * percentage;
		var xa = bxa + mxa;
		var ya = bya + mya;
		foreach(Node3D v in GetTree().GetNodesInGroup("player"))
		{
			if(v is Player player && player.IsOnFloor())
			{
				SendClientsideEffects(player, 8f);
			}
		}
		DoPhysics();
	}

	public void MagnitudeNine()
	{
		var percentage = Mathf.Clamp(Magnitude / 9.99, 0, 1);
		var bxa = GD.RandRange( - 45, 45) / 100;
		var bya = GD.RandRange( - 45, 45) / 100;
		var mxa = (GD.RandRange( - 5, 5) / 100) * percentage;
		var mya = (GD.RandRange( - 5, 5) / 100) * percentage;
		var xa = bxa + mxa;
		var ya = bya + mya;
		foreach(Node3D v in GetTree().GetNodesInGroup("player"))
		{
			if(v is Player player && player.IsOnFloor())
			{
				SendClientsideEffects(player, 16f);
			}
		}
		DoPhysics();
	}

	public void MagnitudeTen()
	{
		var percentage = Mathf.Clamp(Magnitude / 10.99, 0, 1);
		var bxa = GD.RandRange( - 50, 50) / 100;
		var bya = GD.RandRange( - 50, 50) / 100;
		var mxa = (GD.RandRange( - 5, 5) / 100) * percentage;
		var mya = (GD.RandRange( - 5, 5) / 100) * percentage;
		var xa = bxa + mxa;
		var ya = bya + mya;
		foreach(Node3D v in GetTree().GetNodesInGroup("player"))
		{
			if(v is Player player && player.IsOnFloor())
			{
				SendClientsideEffects(player, 38f);
			}
		}
		DoPhysics();
	}

	public void MagnitudeEleven()
	{
		var percentage = Mathf.Clamp(Magnitude / 11.99, 0, 1);
		var bxa = GD.RandRange( - 55, 55) / 100;
		var bya = GD.RandRange( - 55, 55) / 100;
		var mxa = (GD.RandRange( - 5, 5) / 100) * percentage;
		var mya = (GD.RandRange( - 5, 5) / 100) * percentage;
		var xa = bxa + mxa;
		var ya = bya + mya;
		foreach(Node3D v in GetTree().GetNodesInGroup("player"))
		{
			if(v is Player player && player.IsOnFloor())
			{
				SendClientsideEffects(player, 38f);
			}
		}
		DoPhysics();
	}

	public void MagnitudeTwelve()
	{
		var percentage = Mathf.Clamp(Magnitude / 12.99, 0, 1);
		var bxa = GD.RandRange( - 1250, 1250) / 100;
		var bya = GD.RandRange( - 1250, 1250) / 100;
		var mxa = (GD.RandRange( - 425, 425) / 100) * percentage;
		var mya = (GD.RandRange( - 425, 425) / 100) * percentage;
		var xa = bxa + mxa;
		var ya = bya + mya;
		foreach(Node3D v in GetTree().GetNodesInGroup("player"))
		{
			if(v is Player player && player.IsOnFloor())
			{
				SendClientsideEffects(player, 38f);
			}
		}
		DoPhysics();
	}


}