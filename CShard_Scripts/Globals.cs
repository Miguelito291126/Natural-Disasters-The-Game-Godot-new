using System.Linq;
using Godot;
using Godot.Collections;
using steam;


[GlobalClass]
public partial class Globals : Node
{
	[Signal]
	public delegate void CurrentWeatherAndDisasterChangedEventHandler(string new_disaster);

	public static Globals Instance { get; private set; }

	//Editor
	public Variant Version = ProjectSettings.GetSetting("application/config/version");
	public Variant Gamename = ProjectSettings.GetSetting("application/config/name");
	public string Credits = "Miguel Jimenez";


	//Network
	[Export] public string Ip;
	[Export] public string PublicIp;
	[Export] public string LocalIp;

	[Export] public int Port = 5555;
	[Export] public int Points;
	[Export] public string Username = "Player";
	[Export] public Array<Player> PlayersConected;
	public MultiplayerPeer Multiplayerpeer;
	[Export] public bool IsSteamRunning = false;
	[Export] public bool UseSteam = false;
	[Export] public ulong SteamLobbyId = 0;
	[Export] public ulong SteamId = 0;


	//Globals Weather
	[Export] public float Temperature = 23f;
	[Export] public float Pressure = 10000f;
	[Export] public float Oxygen = 100f;
	[Export] public float Bradiation = 0f;
	[Export] public float Humidity = 25f;
	[Export] public Vector3 WindDirection = new Vector3(1f, 0f, 0f);
	[Export] public float WindSpeed = 0f;
	[Export] public bool IsRaining = false;
	public Variant Gravity = ProjectSettings.GetSetting("physics/3d/default_gravity");


	//Globals Time
	[Export] public float Time = 0.0f;
	[Export] public float TimeLeft = 0.0f;
	[Export] public int Day = 0;
	[Export] public int Hour = 0;
	[Export] public int Minute = 0;


	//Globals Weather target
	[Export] public float TemperatureTarget = 23f;
	[Export] public float PressureTarget = 10000f;
	[Export] public float OxygenTarget = 100f;
	[Export] public float BradiationTarget = 0f;
	[Export] public float HumidityTarget = 25f;
	[Export] public Vector3 WindDirectionTarget = new Vector3(1f, 0f, 0f);
	[Export] public float WindSpeedTarget = 0;


	//Globals Weather original
	[Export] public float TemperatureOriginal = 23f;
	[Export] public float PressureOriginal = 10000f;
	[Export] public float OxygenOriginal = 100f;
	[Export] public float BradiationOriginal = 0f;
	[Export] public float HumidityOriginal = 25f;
	[Export] public Vector3 WindDirectionOriginal = new Vector3(1f, 0f, 0f);
	[Export] public float WindSpeedOriginal = 0f;

	[Export] public float Seconds = 0.0f;

	[Export] public Main Main;
	[Export] public MainMenu MainMenu;
	[Export] public Map Map;
	[Export] public ServerBrowser ServerBrowser;
	[Export] public Player LocalPlayer;

	[Export] public Dictionary BoundingRadiusAreas = new Dictionary{};

	[Export] public string NodeGroup = "Destrollable";
	[Export] public Array<string> DestrolledNode = new Array<string>();
	[Export] public bool Started = false;
	[Export] public string Gamemode = "survival";
	[Export] public DataResource GlobalsData;

	private string _CurrentWeatherAndDisaster = "Original";
	[Export] public string CurrentWeatherAndDisaster
	{
		set
		{
			if(_CurrentWeatherAndDisaster != value)
			{
				_CurrentWeatherAndDisaster = value;
				EmitSignal(SignalName.CurrentWeatherAndDisasterChanged, value);
			}
		}
		get 
		{ 
			return _CurrentWeatherAndDisaster; 
		}
	}
	


	[Export] public int CurrentWeatherAndDisasterID = 0;

	public PackedScene PlayerScene = ResourceLoader.Load<PackedScene>("res://Scenes/player.tscn");
	public PackedScene ThunderstormScene = ResourceLoader.Load<PackedScene>("res://Scenes/thunder.tscn");
	public PackedScene MeteorScene = ResourceLoader.Load<PackedScene>("res://Scenes/meteor.tscn");
	public PackedScene TornadoScene = ResourceLoader.Load<PackedScene>("res://Scenes/tornado.tscn");
	public PackedScene TsunamiScene = ResourceLoader.Load<PackedScene>("res://Scenes/tsunami.tscn");
	public PackedScene VolcanoScene = ResourceLoader.Load<PackedScene>("res://Scenes/volcano.tscn");
	public PackedScene EarthquakeScene = ResourceLoader.Load<PackedScene>("res://Scenes/earthquake.tscn");

	public Timer Timer;

	[Export] public Dictionary<string, Variant> RoomList = new Dictionary<string, Variant>{{"Name", "Name"},{"Players", 0}};

	[Export] public bool IsChatOpen = false;
	[Export] public bool IsPauseMenuOpen = false;
	[Export] public bool IsSpawnMenuOpen = false;

	[Export] public string Character = "blue";
	[Export] public Array<string> AvalibleCharacters = new Array<string>{"blue", "red", "green", "yellow"};
	[Export] public Dictionary<int, string> AssignedCharacter = new Dictionary<int, string>{};
	[Export] public HttpRequest http;
	[Export] public string masterServerUrl = "http://miguelito2911.serveminecraft.net:5000";
	[Export] public bool privateMode = false; // Nueva variable para rastrear si somos el servidor
	
	public float ConvertMetoSU(float metres)
	{
		return (int)(metres * 39.37f) / 0.75f;
	}

	public int ConvertKMPHtoMe(float kmph)
	{
		return (int)((kmph * 1000) / 3600);
	}

	public int ConvertVectorToAngle(Vector3 vector)
	{
		var x = vector.X;
		var y = vector.Z;

		return (int)(360 + Mathf.RadToDeg(Mathf.Atan2(y, x))) % 360;
	}

	protected PhysicsDirectSpaceState3D _GetDirectSpaceState(Node node)
	{
		// 1. Intentamos obtener el World3D del nodo si es válido y es Node3D
		if (IsInstanceValid(node) && node is Node3D node3D)
		{
			var world = node3D.GetWorld3D();
			if (world != null) return world.DirectSpaceState;
		}

		// 2. Si falló lo anterior, intentamos obtenerlo desde la escena actual
		var currentScene = GetTree()?.CurrentScene as Node3D;
		return currentScene?.GetWorld3D()?.DirectSpaceState;
	}

	public bool PerformTraceCollision(Node3D ply, Vector3 direction)
	{
		var start_pos = ply.GlobalPosition;
		var end_pos = start_pos + direction * 1000;
		var space_state = _GetDirectSpaceState(ply);
		if(space_state == null)
		{
			return false;
		}

		var ray = PhysicsRayQueryParameters3D.Create(start_pos, end_pos);
		if (ply is Player player) 
		{
			ray.Exclude = new Array<Rid> { player.GetRid() };
		}
		
		var result = space_state.IntersectRay(ray);
		return result != new Dictionary{};
	}


	public Vector3 PerformTraceWind(Node3D ply,Vector3 direction)
	{
		Vector3 start_pos = ply.GlobalPosition;
		Vector3 end_pos = start_pos + direction * 60000;
		PhysicsDirectSpaceState3D space_state = _GetDirectSpaceState(ply);
		if(space_state == null)
		{
			return end_pos;
		}
		PhysicsRayQueryParameters3D ray = PhysicsRayQueryParameters3D.Create(start_pos, end_pos);

		if (ply is Player player) 
		{
			ray.Exclude = new Array<Rid> { player.GetRid() };
		}
		
		Dictionary result = space_state.IntersectRay(ray);
		if(result != new Dictionary{} && result.ContainsKey("position"))
		{
			return (Vector3)result["position"];
		}
		else
		{
			return end_pos;
		}
	}

	public Dictionary<Node, int> GetNodeByIdRecursive(Node node, int node_id)
	{
		if(node.GetInstanceId().Equals(node_id))
		{
			return new Dictionary<Node, int>{{node, node_id}};
		}

		foreach(Node child in node.GetChildren())
		{
			Dictionary<Node, int> result = GetNodeByIdRecursive(child, node_id);
			if(result != null)
			{
				return result;
			}
		}

		return null;
	}

	public bool IsBelowSky(Node3D ply)
	{
		if (ply == null || !ply.IsInsideTree())
			return true;

		PhysicsDirectSpaceState3D space_state = _GetDirectSpaceState(ply);
		if (space_state == null) return true;

		Vector3 start_pos = ply.GlobalPosition + new Vector3(0, 2.0f, 0);
		Vector3 end_pos = start_pos + new Vector3(0, 1000, 0); // 1km es suficiente para la mayoría de mapas

		var ray = PhysicsRayQueryParameters3D.Create(start_pos, end_pos);

		if (ply is Player player) 
		{
			ray.Exclude = new Array<Rid> { player.GetRid() };
		}

		var result = space_state.IntersectRay(ray);

		// Si el conteo es 0, no hay nada arriba (está bajo el cielo)
		return result.Count == 0;
	}



	public bool IsOutdoor(Node3D ply)
	{
		if (ply == null) return true;

		if (!ply.IsInsideTree()) return true;

		bool hitSky = IsBelowSky(ply);

		if (ply is Player player && ply.IsInGroup("player"))
		{
			player.Outdoor = hitSky;
		}

		return hitSky;
	}


	public bool IsInwater(Node ply)
	{
		if(ply.IsInGroup("player")&& ply is Player player)
		{
			return player.IsInWater;
		}
		return false;
	}

	public bool IsUnderwater(Node ply)
	{
		if(ply.IsInGroup("player") && ply is Player player)
		{
			return player.IsUnderWater;
		}
		return false;
	}

	public bool IsInlava(Node ply)
	{
		if(ply.IsInGroup("player") && ply is Player player)
		{
			return player.IsInLava;
		}
		return false;
	}

	public bool IsUnderlava(Node ply)
	{
		if(ply.IsInGroup("player") && ply is Player player)
		{
			return player.IsUnderLava;
		}
		return false;
	}


	public Vector3 Vec2ToVec3(Vector3 vector)
	{
		return new Vector3(vector.X, 0, vector.Y);
	}

	public bool IsSomethingBlockingWind(Node3D entity)
	{
		// 1. Empezamos el rayo un poco más arriba (ej. 1.5m) para no chocar con el suelo
		Vector3 start_pos = entity.GlobalPosition + new Vector3(0, 1.5f, 0);
		
		// 2. Reducimos el alcance. 300m es mucho. 
		// Un valor entre 10 y 20 metros suele ser suficiente para "cobertura".
		float rayLength = 15.0f; 
		Vector3 end_pos = start_pos - (WindDirection * rayLength);

		PhysicsDirectSpaceState3D space_state = _GetDirectSpaceState(entity);
		if(space_state == null) return false;

		var ray = PhysicsRayQueryParameters3D.Create(start_pos, end_pos);

		// 3. Excluimos al jugador para que el rayo no choque con su propia espalda
		if (entity is Player player) 
		{
			ray.Exclude = new Array<Rid> { player.GetRid() };
		}

		// ACTIVAR CAPAS 8 (Casa) y 9 (Terreno)
		// Usamos (1 << índice). El índice es (Número de Capa - 1)
		uint mask = (1 << 7); // Capa 8
		mask |= (1 << 8);     // Capa 9

		ray.CollisionMask = mask; // Solo colisiona con las capas 8 y 9

		var result = space_state.IntersectRay(ray);

		// Si el resultado no está vacío, algo bloquea el viento
		return result.Count > 0;
	}

	public float CalculeBoundingRadius(Node3D entity)
	{
		float max_radius = 0.0f;

		foreach (Node child in entity.GetChildren())
		{
			// Recursividad: Si tiene hijos, acumulamos el radio máximo
			if (child.GetChildCount() > 0 && child is Node3D childNode)
			{
				max_radius = Mathf.Max(max_radius, CalculeBoundingRadius(childNode));
			}

			if (child is MeshInstance3D meshInstance)
			{
				Mesh mesh = meshInstance.Mesh;
				if (mesh == null) continue;

				Aabb aabb = mesh.GetAabb();
				
				// 1. Definir los 8 vértices locales de la AABB
				Vector3[] vertices = new Vector3[] {
					aabb.Position,
					aabb.Position + new Vector3(aabb.Size.X, 0, 0),
					aabb.Position + new Vector3(0, aabb.Size.Y, 0),
					aabb.Position + new Vector3(0, 0, aabb.Size.Z),
					aabb.Position + new Vector3(aabb.Size.X, aabb.Size.Y, 0),
					aabb.Position + new Vector3(aabb.Size.X, 0, aabb.Size.Z),
					aabb.Position + new Vector3(0, aabb.Size.Y, aabb.Size.Z),
					aabb.Position + aabb.Size,
				};

				// 2. Transformar vértices y calcular radio en un solo paso
				foreach (Vector3 v in vertices)
				{
					// Transformamos el vértice al espacio global o del padre
					Vector3 globalVertex = meshInstance.Transform * v;
					
					// Calculamos la distancia al origen del objeto original
					float distance = globalVertex.Length();
					max_radius = Mathf.Max(max_radius, distance);
				}
			}
		}
		return max_radius;
	}



	public Array SearchInNode(Node node, Vector3 origin, float radius, Array result)
	{
		foreach(int i in GD.Range(node.GetChildCount()))
		{
			Node child = node.GetChild(i);
			if(child is Node3D child3D && IsInstanceValid(child3D))
			{
				// Solo considerar nodos Spatial (puedes ajustar esto segn tus necesidades)
				var distance = origin.DistanceTo(child3D.GlobalPosition);
				if(distance <= radius)
				{
					result.Add(child3D);
				}
			}

			// Recursin si el nodo tiene hijos
			if(child.GetChildCount() > 0)
			{
				SearchInNode(child, origin, radius, result);
			}
		}

		return result;
	}

	public Array FindInSphere(Vector3 origin, float radius)
	{
		var result = new Array();
		var scene_root = GetTree().GetRoot();

		result = SearchInNode(scene_root, origin, radius, result);

		return result;
	}

	public void Wind(Node3D obj)
	{
		if(!IsInstanceValid(obj)) return;

		// Verificar si el objeto es un jugador
		if(obj.IsInGroup("player") && obj is Player player)
		{
			bool outdoor = IsOutdoor(player);
			bool blocked = IsSomethingBlockingWind(player);

			// LOG DE DEPURACIÓN: Si ves esto en consola sabrás por qué es 0
			// GD.Print($"Outdoor: {outdoor}, Blocked: {blocked}, GlobalWind: {WindSpeed}");

			float local_wind = WindSpeed;

			if(!outdoor || blocked)
			{
				local_wind = 0;
			}

			player.BodyWind = local_wind;

			// Aplicar movimiento
			if(local_wind >= 30) // Solo si hay viento fuerte
			{
				Vector3 wind_vel = WindDirection * local_wind;
				var delta_velocity = wind_vel - player.velocity;
				player.ApplyDisastersPush(delta_velocity * 0.3f);
			}
		}

		else if(obj.IsInGroup("movable_objects") && obj is RigidBody3D body)
		{
			if(GodotObject.IsInstanceValid(body) && IsOutdoor(body) && !IsSomethingBlockingWind(body))
			{
				var wind_vel = WindDirection * (float)WindSpeed;
				var delta_velocity = wind_vel - body.LinearVelocity;


				// Aplica fuerza en vez de modificar directamente la velocidad
				body.ApplyCentralForce(delta_velocity * 0.3f * body.Mass);
			}
		}

		else if(obj.IsInGroup("movable_objects") && obj is StaticBody3D staticBody)
		{
			if(GodotObject.IsInstanceValid(staticBody))
			{
				if((staticBody.IsInGroup("Destrollable") || staticBody.IsInGroup("Hause")) && staticBody is House house)
				{
					if(WindSpeed > 100)
					{
						house.Destroy();
					}
				}
			}
		}
	}


	public float GetArea(Node3D entity)
	{
		// Intentamos obtener el valor desde el objeto (funciona si existe la propiedad en un script)
		Variant value = entity.Get("BoundingRadiusArea");

		if (value.VariantType == Variant.Type.Nil) 
		{
			// No existe la propiedad, calculamos y guardamos (opcionalmente)
			float area = Mathf.Pi * Mathf.Pow(CalculeBoundingRadius(entity), 2);
			
			// Si quieres intentar guardarlo en el objeto mismo:
			// entity.Set("BoundingRadiusArea", area); 
			
			return area;
		}

		return value.AsSingle();
	}



	public float GetFrameMultiplier()
	{
		var frame_time = (float)Engine.GetFramesPerSecond();
		if(frame_time == 0)
		{
			return 0;
		}
		else
		{
			return (float)60 / frame_time;
		}
	}

	public float GetPhysicsMultiplier()
	{
		var physics_interval = (float)GetPhysicsProcessDeltaTime();
		return (200.0f / 3.0f) / physics_interval;
	}

	public bool HitChance(int chance)
	{
		if(Multiplayer.IsServer())
		{

			// En el servidor
			return GD.Randf() < (Mathf.Clamp(chance * GetPhysicsMultiplier(), 0, 100) / 100);
		}
		else
		{

			// En el cliente
			return GD.Randf() < (Mathf.Clamp(chance * GetFrameMultiplier(), 0, 100) / 100);
		}
	}

	[Rpc(MultiplayerApi.RpcMode.AnyPeer, CallLocal = true)]
	public void SyncPlayerList()
	{
		PlayersConected?.Clear();

		foreach(Node3D v in GetTree().GetNodesInGroup("player"))
		{
			if(v is not Player p) continue;
			if(IsInstanceValid(p))
			{
				PlayersConected.Add(p);
			}
		}
	}


	// Funci�n para verificar si hay jugadores con el mismo nombre
	public bool HayJugadoresConMismoNombre(string nombre_a_verificar, Node excluir_jugador = null)
	{
		var contador = 0;
		foreach(Node3D v in GetTree().GetNodesInGroup("player"))
		{
			if (v is not Player player) continue;
			// Si se debe excluir un jugador especfico, saltarlo
			if(excluir_jugador != null && player == excluir_jugador)
			{
				continue;
			}

			Variant username = player.Get("username");
			// Verificar si el nombre coincide
			if(IsInstanceValid(player) && username.VariantType != Variant.Type.Nil  && username.AsString() == nombre_a_verificar)
			{
				contador += 1;

				// Si encontramos al menos uno con el mismo nombre, retornar true
				if(contador >= 1)
				{
					return true;
				}
			}
		}

		return false;
	}


	// Funci�n para obtener todos los jugadores que tienen el mismo nombre
	public Array ObtenerJugadoresConMismoNombre(string nombre_a_verificar, Node excluir_jugador = null)
	{
		var jugadores_duplicados = new Array();

		foreach(Node3D v in GetTree().GetNodesInGroup("player"))
		{
			if (v is not Player player) continue;

			// Si se debe excluir un jugador especfico, saltarlo
			if(excluir_jugador != null && player == excluir_jugador)
			{
				continue;
			}


			// Verificar si el nombre coincide
			if(GodotObject.IsInstanceValid(player) && player.Username == nombre_a_verificar)
			{
				jugadores_duplicados.Add(player);
			}
		}

		return jugadores_duplicados;
	}


	// Funci�n para contar cu�ntos jugadores tienen el mismo nombre
	public int ContarJugadoresConMismoNombre(string nombre_a_verificar, Node excluir_jugador = null)
	{
		var contador = 0;
		foreach(Node3D p in GetTree().GetNodesInGroup("player"))
		{
			if (p is not Player player) continue;

			// Si se debe excluir un jugador especfico, saltarlo
			if(excluir_jugador != null && player == excluir_jugador)
			{
				continue;
			}

			var username = player.Get("username");
			// Verificar si el nombre coincide
			if(GodotObject.IsInstanceValid(player) && username.VariantType != Variant.Type.Nil && username.AsString() == nombre_a_verificar)
			{
				contador += 1;
			}
		}

		return contador;
	}


	public void PrintRole(string msg)
	{
		var peer = Multiplayer.MultiplayerPeer;

		if(peer == null || peer is OfflineMultiplayerPeer)
		{
			GD.Print(msg);
			return;
		}

		bool IsServer = Multiplayer.IsServer();
		if(IsServer)
		{
			// Azul
			GD.PrintRich("[color=blue][Server] " + msg + "[/color]");
		}
		else
		{
			// Amarillo
			GD.PrintRich("[color=yellow][Client] " + msg + "[/color]");
		}
	}


	public async void PlayMultiplayerServer(int port)
	{	
		if (UseSteam)
		{
			var peer = new SteamMultiplayerPeer();
			Error error = peer.CreateServer(port);
			if(error == Error.Ok)
			{
				Multiplayerpeer = peer;
				Multiplayer.MultiplayerPeer = Multiplayerpeer;
				if(Multiplayer.IsServer())
				{
					var args = OS.GetCmdlineUserArgs();
					bool isServer = OS.HasFeature("dedicated_server") || (args != null && args.Contains("server"));

					if(isServer)
					{
						PrintRole("Dedicated server init");

						await ToSignal(GetTree().CreateTimer(2), SceneTreeTimer.SignalName.Timeout);


						LoadScene.Instance.loadscene(MainMenu, "map");
					}
					else
					{
						PrintRole("Server init");

						LoadScene.Instance.loadscene(MainMenu, "map");
					}
				}
			}
			else
			{
				PrintRole("Fatal Error in server");
			}
		}
		else
		{
			
			if (!privateMode)
			{
				UpnpSetup(port);
			}

			var peer = new ENetMultiplayerPeer();
			Error error = peer.CreateServer(port, 4);
			if(error == Error.Ok)
			{
				Multiplayerpeer = peer;
				Multiplayer.MultiplayerPeer = Multiplayerpeer;
				if(Multiplayer.IsServer())
				{
					var args = OS.GetCmdlineUserArgs();
					bool isServer = OS.HasFeature("dedicated_server") || (args != null && args.Contains("server"));

					if(isServer)
					{
						PrintRole("Dedicated server init");

						await ToSignal(GetTree().CreateTimer(2), SceneTreeTimer.SignalName.Timeout);


						LoadScene.Instance.loadscene(MainMenu, "map");
					}
					else
					{
						PrintRole("Server init");

						LoadScene.Instance.loadscene(MainMenu, "map");
					}
				}
			}
			else
			{
				PrintRole("Fatal Error in server");
			}

		}
	}

	[Rpc(MultiplayerApi.RpcMode.AnyPeer)]
	public void RequestPickObject(NodePath player_path, NodePath target_path)
	{

		// Solo el servidor debe ejecutar esta lgica
		if(!Multiplayer.IsServer())
		{
			return ;
		}

		var root = GetTree().GetRoot();

		Player player = root.GetNodeOrNull<Player>(player_path);
		Node3D target = root.GetNodeOrNull<Node3D>(target_path);

		if(player == null || target == null)
		{
			return ;
		}

		if(!target.IsInGroup("Pickable"))
		{
			return ;
		}


		// Colocar el objeto en la mano del jugador
		target.GlobalPosition = player.HandNode.GlobalPosition;
		target.GlobalRotation = player.HandNode.GlobalRotation;

		if (target is CollisionObject3D collisionObject)
		{
			// Pone la capa 2 en true
			collisionObject.SetCollisionLayerValue(2, true);
		}

		if(target is RigidBody3D rigidBody3)
		{
			rigidBody3.LinearVelocity = new Vector3(0.1f, 3, 0.1f);
		}
	}

	public void PlayMultiplayerClient(string ip, int port)
	{
		ENetMultiplayerPeer peer = new ENetMultiplayerPeer();
		var error = peer.CreateClient(ip, port);
		if(error == Error.Ok)
		{
			Multiplayerpeer = peer;
			Multiplayer.MultiplayerPeer = Multiplayerpeer;
			if(!Multiplayer.IsServer())
			{
				PrintRole("Client Init");
			}
		}
		else
		{
			PrintRole("Fatal Error in client");
		}
	}

	public void PlayMultiplayerClientSteam(ulong identityRemote, int port = 5555)
	{
		var peer = new SteamMultiplayerPeer();
		var error = peer.CreateClient(identityRemote, port);
		if(error == Error.Ok)
		{
			Multiplayerpeer = peer;
			Multiplayer.MultiplayerPeer = Multiplayerpeer;
			if(!Multiplayer.IsServer())
			{
				PrintRole("Client Init");
			}
		}
		else
		{
			PrintRole("Fatal Error in client");
		}
	}

	public void MultiplayerConnectionFailed()
	{
		PrintRole("Client disconected");
		
		PlayersConected?.Clear();
		AssignedCharacter?.Clear();
		DestrolledNode?.Clear();
		
		// Safety check for the Multiplayer API
		if (GetTree() != null) 
		{
			Multiplayerpeer = new OfflineMultiplayerPeer();
			Multiplayer.MultiplayerPeer = Multiplayerpeer;
		}

		// Safety check for your Scene Loader
		if (LoadScene.Instance != null)
		{
			LoadScene.Instance.loadscene(Map, "res://Scenes/main_menu.tscn");
		}
		else
		{
			GD.PrintErr("Error: LoadScene.Instance is null!");
			// Fallback to standard change scene if your custom loader fails
			GetTree().ChangeSceneToFile("res://Scenes/main_menu.tscn");
		}
	}

	[Rpc(MultiplayerApi.RpcMode.AnyPeer, CallLocal = true)]
	public void AssingCharacter(string charac)
	{
		foreach(string c in AvalibleCharacters)
		{
			if(c == charac)
			{
				Character = charac;
				break;
			}
		}

		if(LocalPlayer != null && GodotObject.IsInstanceValid(LocalPlayer))
		{
			LocalPlayer.Character = charac;
		}

		PrintRole("Asignado el personaje: " + charac);
	}

	[Rpc(MultiplayerApi.RpcMode.Authority, CallLocal = true)]
	public bool AssingCharacterToPlayer(long id, string charac)
	{
		var chosen_char = charac;


		// Si el char recibido no es v�lido o ya est� ocupado, buscamos el siguiente disponible.
		if(chosen_char == null || chosen_char == "" || !IsCharacterAvalible(chosen_char))
		{
			chosen_char = GetNextAvalibleCharacter();
		}

		if(chosen_char == null || chosen_char == "" || !IsCharacterAvalible(chosen_char))
		{
			PrintRole("No hay personaje disponible para el id " + id.ToString());
			return false;
		}

		AssignedCharacter[(int)id] = chosen_char;
		AssingCharacter(chosen_char);
		PrintRole("Asignado al id " + id.ToString() + " el personaje " + chosen_char);
		return true;
	}

	[Rpc(MultiplayerApi.RpcMode.AnyPeer, CallLocal = true)]
	public void SyncAssignedCharacter(Dictionary<int, string> data)
	{
		AssignedCharacter = new Dictionary<int, string>();
		foreach (var key in data.Keys)
		{
			AssignedCharacter[(int)key] = data[key].ToString();
		}

		// APLICAR A LOS NODOS EXISTENTES
		foreach (var entry in AssignedCharacter)
		{
			int peerId = entry.Key;
			string characterName = entry.Value;

			// Buscamos el nodo del jugador en el mapa usando su ID como nombre
			if (Map != null)
			{
				Player p = Map.GetNodeOrNull<Player>(peerId.ToString());
				if (p != null)
				{
					p.Character = characterName;
					// Aquí deberías llamar a una función dentro de tu clase Player 
					// que actualice el Sprite o el Color.
					// p.UpdateAppearance(); 
				}
			}
		}
	}

	public bool IsCharacterAvalible(string charac)
	{
		foreach(int id in AssignedCharacter.Keys)
		{
			if(AssignedCharacter[id] == charac)
			{
				return false;
			}
		}

		return true;
	}


	public string GetNextAvalibleCharacter()
	{
		foreach(string charac in AvalibleCharacters)
		{
			if(IsCharacterAvalible(charac))
			{
				return charac;
			}
		}

		return null;
	}


	public void MultiplayerServerDisconnected()
	{
		PrintRole("Client disconnected");

		// Ensure collections aren't null before clearing
		PlayersConected?.Clear();
		AssignedCharacter?.Clear();
		DestrolledNode?.Clear();

		// Safety check for the Multiplayer API
		if (GetTree() != null) 
		{
			Multiplayerpeer = new OfflineMultiplayerPeer();
			Multiplayer.MultiplayerPeer = Multiplayerpeer;
		}



		// Safety check for your Scene Loader
		if (LoadScene.Instance != null)
		{
			LoadScene.Instance.loadscene(Map, "res://Scenes/main_menu.tscn");
		}
		else
		{
			GD.PrintErr("Error: LoadScene.Instance is null!");
			// Fallback to standard change scene if your custom loader fails
			GetTree().ChangeSceneToFile("res://Scenes/main_menu.tscn");
		}
	}


	public void MultiplayerConnectionServerSucess()
	{
		PrintRole("connected to server");
		UnloadScene.Instance.unloadscene(MainMenu);
	}

	public override void _ExitTree()
	{
		Multiplayer.PeerConnected -= MultiplayerPlayerSpawner;
		Multiplayer.PeerDisconnected -= MultiplayerPlayerRemover;
		Multiplayer.ServerDisconnected -= MultiplayerServerDisconnected;
		Multiplayer.ConnectedToServer -= MultiplayerConnectionServerSucess;
		Multiplayer.ConnectionFailed -= MultiplayerConnectionFailed;

		TemperatureTarget = TemperatureOriginal;
		HumidityTarget = HumidityOriginal;
		PressureTarget = PressureOriginal;
		WindDirectionTarget = WindDirectionOriginal;
		WindSpeedTarget = WindSpeedOriginal;
	}


	public override void _Process(double _delta)
	{
		if(!Multiplayer.HasMultiplayerPeer()) return;
		if(!Multiplayer.IsServer()) return;

		// Usamos un factor de velocidad (ajusta el 0.5f a tu gusto) multiplicado por delta
		float weight = (float)(0.5f * _delta); 

		TimeLeft = (float)Timer.TimeLeft;
		Temperature = Mathf.Lerp(Temperature, TemperatureTarget, weight);
		Humidity = Mathf.Lerp(Humidity, HumidityTarget, weight);
		Bradiation = Mathf.Lerp(Bradiation, BradiationTarget, weight);
		Pressure = Mathf.Lerp(Pressure, PressureTarget, weight);
		Oxygen = Mathf.Lerp(Oxygen, OxygenTarget, weight);
		WindSpeed = Mathf.Lerp(WindSpeed, WindSpeedTarget, weight);
		
		// Para vectores se usa una aproximación similar
		WindDirection = WindDirection.Lerp(WindDirectionTarget, weight).Normalized();

		// Clamp después del Lerp para mantener los límites
		Temperature = Mathf.Clamp(Temperature, -275.5f, 275.5f);
		Humidity = Mathf.Clamp(Humidity, 0, 100);
		Bradiation = Mathf.Clamp(Bradiation, 0, 100);
		Pressure = Mathf.Clamp(Pressure, 0, 100000);
		Oxygen = Mathf.Clamp(Oxygen, 0, 100);
		WindSpeed = Mathf.Clamp(WindSpeed, 0, 300);
		
		if (IsSteamRunning)
        {
            Steam.RunCallbacks();
        }
	}


	public override void _Ready()
	{

		if(Instance != null)
		{
			GD.PushError("Ya existe una instancia de Globals. Esto no deber�a pasar, asegurate de que solo haya un nodo Globals en la escena.");
			this.QueueFree();
			return ;
		}
		Instance = this;

		Timer = GetNode<Timer>("Timer");
		http = GetNode<HttpRequest>("MasterServerRequest");

		Multiplayer.PeerConnected += MultiplayerPlayerSpawner;
		Multiplayer.PeerDisconnected += MultiplayerPlayerRemover;
		Multiplayer.ServerDisconnected += MultiplayerServerDisconnected;
		Multiplayer.ConnectedToServer += MultiplayerConnectionServerSucess;
		Multiplayer.ConnectionFailed += MultiplayerConnectionFailed;

		Multiplayerpeer = new OfflineMultiplayerPeer();
		Multiplayer.MultiplayerPeer = Multiplayerpeer;
		
		GlobalsData = DataResource.LoadFile();

		InitSteam();

		FetchPublicIp();
		FetchLocalIp();
	}
	private void InitSteam()
	{
		try 
		{
			// En lugar de usar la respuesta automática, forzamos una lectura manual
			// Primero verificamos si Steam está abierto a nivel de sistema
			if (!Steam.IsSteamRunning()) 
			{
				GD.PrintErr("Steam no está abierto. Por favor, abre Steam.");
				IsSteamRunning = false;
				UseSteam = false;
				return;
			}

			var result = Steam.SteamInit();
			
			// Verificamos si el objeto de respuesta es válido y tiene estatus 0 (OK)
			if (result != null && result.Status == 0) 
			{
				IsSteamRunning = true;
				UseSteam = true;
				SteamId = Steam.GetSteamID();
				GD.Print("Steam inicializado correctamente vía C#.");
			}
			else 
			{
				IsSteamRunning = false;
				UseSteam = false;
				GD.PrintErr("SteamInit falló. Asegúrate de tener el archivo steam_appid.txt");
			}
		}
		catch (System.Exception e)
		{
			// Esto captura el error de "KeyNotFoundException" y evita que el juego se cierre
			GD.PrintErr("Error al leer el diccionario de Steam: " + e.Message);
			IsSteamRunning = false;
			UseSteam = false;
		}
	}

	public void CreateGame(int port)
	{
		if (UseSteam)
		{
			// Crear Lobby en Steam primero
			Steam.CreateLobby(Steam.LobbyType.Public, 4);
		}
		else
		{
			// Crear servidor ENet directo (Android / LAN)
			PlayMultiplayerServer(port);
		}
	}

	private void OnLobbyCreated(long result, ulong lobbyId)
	{
		if (result == 1) // 1 = Success
		{
			SteamLobbyId = lobbyId;
			Steam.SetLobbyData(lobbyId, "game_id", "elemental_adventure");
			Steam.SetLobbyData(lobbyId, "host_id", SteamId.ToString());
			Steam.SetLobbyData(lobbyId, "name", Username);
			Steam.SetLobbyData(lobbyId, "players", PlayersConected.Count.ToString());
			º
			// Iniciar el peer de Steam
			PlayMultiplayerServer(Port);
			
			GD.Print("Servidor de Steam creado con éxito.");
		}
	}

	public void JoinGame(string targetIp, int targetPort, ulong lobbyId = 0)
	{
		if (UseSteam && lobbyId != 0)
		{
			Steam.JoinLobby(lobbyId);
		}
		else
		{
			// Conexión directa por IP (Android)
			PlayMultiplayerClient(targetIp, targetPort);
		}
	}

	private void OnLobbyJoined(ulong lobbyId, long permissions, bool locked, long response)
	{
		if (response == 1)
		{
			ulong hostId = Steam.GetLobbyOwner(lobbyId);
			PlayMultiplayerClientSteam(hostId, Port);
		}
	}

	private void OnLobbyMatchList(Godot.Collections.Array lobbies)
	{
		GD.Print($"Se encontraron {lobbies.Count} lobbies.");
		// Aquí disparas tu lógica para actualizar la interfaz del buscador
	}


	public void MultiplayerPlayerSpawner(long peer_id = 1)
	{
		if(!Multiplayer.IsServer())
		{
			return;
		}

		if(Map != null && IsInstanceValid(Map))
		{
			PrintRole("Joined player id: " + peer_id.ToString());
			Player player = PlayerScene.Instantiate<Player>();
			player.Name = peer_id.ToString();
			Map.AddChild(player, true);


			bool assigned_ok = true;

			if(!AssignedCharacter.ContainsKey((int)peer_id))
			{
				string next_character = GetNextAvalibleCharacter();
				assigned_ok = AssingCharacterToPlayer(peer_id, next_character);
			}

			if(assigned_ok)
			{
				Rpc(MethodName.SyncAssignedCharacter, AssignedCharacter);
				SyncAssignedCharacter(AssignedCharacter);
				Rpc(MethodName.SyncPlayerList);
				RpcId(peer_id, MethodName.SyncDestrolledNodes, DestrolledNode);
				RpcId(peer_id, MethodName.SetWeatherAndDisaster, CurrentWeatherAndDisaster, CurrentWeatherAndDisasterID);
			}
			else
			{
				PrintRole("No se pudo asignar personaje al jugador con id: " + peer_id.ToString());
			}
		}

		else
		{
			Rpc(MethodName.SyncAssignedCharacter, AssignedCharacter);
			SyncAssignedCharacter(AssignedCharacter);
			Rpc(MethodName.SyncPlayerList);
			RpcId(peer_id, MethodName.SyncDestrolledNodes, DestrolledNode);
			PrintRole("No se pudo aadir al jugador con el id: " + peer_id.ToString());
		}
	}


	public async void MultiplayerPlayerRemover(long peer_id = 1)
	{
		if(!Multiplayer.IsServer())
		{
			return ;
		}


		// Intentar obtener el jugador de forma segura
		Player player_node = Map.GetNodeOrNull<Player>(peer_id.ToString());
		if(player_node != null && IsInstanceValid(player_node))
		{
			PrintRole("Disconected player id: " + peer_id.ToString());
			player_node.QueueFree();

			await ToSignal(player_node, Player.SignalName.TreeExited);

			if(AssignedCharacter.ContainsKey((int)peer_id))
			{
				AssignedCharacter.Remove((int)peer_id);
			}


			
			Rpc(MethodName.SyncAssignedCharacter, AssignedCharacter);
			SyncAssignedCharacter(AssignedCharacter);
			Rpc(MethodName.SyncPlayerList);
		}


		else
		{
			if(AssignedCharacter.ContainsKey((int)peer_id))
			{
				AssignedCharacter.Remove((int)peer_id);
			}
			Rpc(MethodName.SyncAssignedCharacter, AssignedCharacter);
			SyncAssignedCharacter(AssignedCharacter);
			Rpc(MethodName.SyncPlayerList);
			PrintRole("player no found: " + peer_id.ToString());
		}
	}


	public void SyncWeatherAndDisaster()
	{
		if(Multiplayer.IsServer())
		{
			var random_weather_and_disaster = GD.RandRange(0, 13);
			Rpc(MethodName.SetWeatherAndDisaster, "", random_weather_and_disaster);
		}
	}

	// 1. Define la lista de nombres fuera del método (como variable de clase)
	private string[] _weatherNames = {
		"Sun", "Cloud", "Raining", "Storm", "Thunderstorm", 
		"Tsunami", "Meteors shower", "Volcano", "Tornado", 
		"Acid rain", "Earthquake", "Sand Storm", "blizzard", "Dust Storm"
	};

	[Rpc(MultiplayerApi.RpcMode.Authority, CallLocal = true)]
	public void SetWeatherAndDisaster(string name = "", int index = -1)
	{
		// Por defecto, asumimos que no se encontró
		CurrentWeatherAndDisaster = "Original";
		CurrentWeatherAndDisasterID = -1;

		// Caso A: Si recibimos un número (int)
		if (name == "" && index >= 0)
		{
			int idx = index;
			if (idx >= 0 && idx < _weatherNames.Length)
			{
				CurrentWeatherAndDisaster = _weatherNames[idx];
				CurrentWeatherAndDisasterID = idx;
			}
		}
		// Caso B: Si recibimos un texto (string)
		else if (name != "" && index == -1)
		{
			int idx = System.Array.IndexOf(_weatherNames, name);
			
			if (idx != -1)
			{
				CurrentWeatherAndDisaster = name;
				CurrentWeatherAndDisasterID = idx;
			}
		}
		else
		{
			CurrentWeatherAndDisaster = name;
			CurrentWeatherAndDisasterID = index;
		}
	}

	[Rpc(MultiplayerApi.RpcMode.AnyPeer, CallLocal = true)]
	public void AddPoints()
	{
		Points += 1;
	}

	[Rpc(MultiplayerApi.RpcMode.AnyPeer, CallLocal = true)]
	public void RemovePoints()
	{
		Points -= 1;

		if(Points < 0)
		{
			Points = 0;
		}
	}


	public void CloseConection()
	{

		var peer = Multiplayer.MultiplayerPeer;
				
		// Si no hay peer o est� desconectado o es offline volver al men�
		if(peer == null || peer is OfflineMultiplayerPeer || peer.GetConnectionStatus() != MultiplayerPeer.ConnectionStatus.Connected)
		{
			MultiplayerServerDisconnected();
			return;
		}

		if (UseSteam && IsSteamRunning)
		{
			// Si estamos usando Steam, salimos del lobby antes de cerrar la conexión
			if (SteamLobbyId != 0)
			{
				Steam.LeaveLobby(SteamLobbyId);
				SteamLobbyId = 0;
			}
		}

		// Si est� conectado cerrar conexi�n
		peer.Close();
		Multiplayerpeer.Close();
	}

	protected void _OnTimerTimeout()
	{
		if(Gamemode == "survival")
		{
			if(Started)
			{
				SyncWeatherAndDisaster();
			}
			else
			{
				Multiplayer.MultiplayerPeer.Close();
			}
		}
	}

	[Rpc(MultiplayerApi.RpcMode.Authority, CallLocal = true)]
	public void SyncDestrolledNodes(Array<string> Hauses)
	{
		foreach(string house_name in Hauses)
		{
			var house = GetTree().GetCurrentScene().GetNodeOrNull(house_name);
			if(house != null && IsInstanceValid(house))
			{
				house.QueueFree();
			}
		}
	}

	public void AddDestrolledNodes(string Name)
	{
		if(!Multiplayer.IsServer())
		{
			return;
		}

		if(!DestrolledNode.Contains(Name))
		{
			DestrolledNode.Add(Name);
		}
	}

	public void RemoveDestrolledNodes(string Name)
	{
		if(!Multiplayer.IsServer())
		{
			return;
		}

		if(DestrolledNode.Contains(Name))
		{
			DestrolledNode.Remove(Name);
		}
	}

	public void RemoveAllDestrolledNodes()
	{
		if(!Multiplayer.IsServer())
		{
			return;
		}

		foreach(string i in DestrolledNode)
		{
			RemoveDestrolledNodes(i);
		}
	}

	public void UpnpSetup(int port)
	{
		var upnp = new Upnp();
		int discoverResult = upnp.Discover();

		if (discoverResult == (int)Upnp.UpnpResult.Success)
		{
			if (upnp.GetGateway() != null && upnp.GetGateway().IsValidGateway())
			{
				upnp.AddPortMapping(port, port, "Godot_Game", "UDP");
				GD.Print("Puerto " + port.ToString() + " mapeado en el router via UPNP.");
				GD.Print("La IP Pública es: " + PublicIp);
			}
			else
            {
                GD.PrintErr("UPNP: No se encontró un Gateway válido.");
            }
		}
		else
        {
            GD.PrintErr("UPNP Discover falló con código: " + discoverResult);
            // Si falla el UPNP (por ejemplo, si el router lo tiene desactivado),
            // PublicIp se quedará vacía. Podrías poner una IP por defecto o manejar el error.
        }
	}

	public void FetchPublicIp()
    {
        var upnp = new Upnp();
        
        // El descubrimiento es necesario para encontrar el Gateway (Router)
        int discoverResult = upnp.Discover();

        if (discoverResult == (int)Upnp.UpnpResult.Success)
        {
            if (upnp.GetGateway() != null && upnp.GetGateway().IsValidGateway())
            {
                // Esta es la función clave que obtiene la IP externa
                PublicIp = upnp.QueryExternalAddress();
                GD.Print("IP Pública: " + PublicIp);
            }
            else
            {
                GD.PrintErr("UPNP: No se encontró un Gateway válido.");
            }
        }
        else
        {
            GD.PrintErr("UPNP Discover falló con código: " + discoverResult);
            // Si falla el UPNP (por ejemplo, si el router lo tiene desactivado),
            // PublicIp se quedará vacía. Podrías poner una IP por defecto o manejar el error.
        }
    }

	public void FetchLocalIp()
	{
		// Obtenemos todas las IPs de la máquina
		foreach (string ip in IP.GetLocalAddresses())
		{
			// Filtramos para quedarnos con la de la red local (típicamente 192.168.x.x)
			if (ip.StartsWith("192.168.") || ip.StartsWith("10."))
			{
				LocalIp = ip;
				GD.Print("IP Local: " + LocalIp);
				break;
			}
		}
	}
	public override void _Notification(int what)
	{
		// Detectamos cuando el usuario cierra la ventana o sale del juego
		if (what == NotificationWMCloseRequest || what == NotificationPredelete)
		{
			if (UseSteam && IsSteamRunning)
			{
				// Si estamos usando Steam, salimos del lobby antes de cerrar la conexión
				if (SteamLobbyId != 0)
				{
					Steam.LeaveLobby(SteamLobbyId);
					SteamLobbyId = 0;
				}
			}
		}
	}
}