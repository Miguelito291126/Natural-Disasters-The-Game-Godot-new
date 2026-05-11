using Godot;
using Godot.Collections;

[GlobalClass]
public partial class SpawnMenu : CanvasLayer
{
	public GridContainer Container;
	[Export] public Array<Node3D> Spawnlist = new();
	[Export] public Array<Button> Buttonlist = new();
	[Export] public Array<Node3D> Spawnedobject = new();
	public Camera3d Camera;

	public PackedScene EntityScene = ResourceLoader.Load<PackedScene>("res://Scenes/entity.tscn");
	public Array<string> SpawnList = new() {
				"res://Scenes/meteor.tscn", 
				"res://Scenes/tornado.tscn", 
				"res://Scenes/volcano.tscn", 
				"res://Scenes/tsunami.tscn", 
				"res://Scenes/earthquake.tscn", 
				"res://Scenes/thunder.tscn", 
				"res://Scenes/cube.tscn", 
				"res://Scenes/sphere.tscn", 
				"res://Scenes/hause.tscn", 
				};

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
		Container = GetNode<GridContainer>("Panel/GridContainer");
		Camera = GetParent().GetNode<Camera3d>("head/Camera3D");
		Visible = false;

		LoadSpawnlistEntities();
		LoadButtons();
	}

	protected Player _GetLocalPlayer()
	{
		foreach(Node3D p in GetTree().GetNodesInGroup("player"))
		{

			if(p is Player player && player.IsMultiplayerAuthority())
			{
				return player;
			}
		}

		return null;
	}


	public void LoadSpawnlistEntities()
	{
		foreach(string spawn in SpawnList)
		{
			Node3D node = ResourceLoader.Load<PackedScene>(spawn).Instantiate<Node3D>();
			Spawnlist.Add(node);
		}
	}


	public void LoadButtons()
	{
		foreach(Node3D i in Spawnlist)
		{
			// 1. Instanciamos como Control (o el tipo que sea tu UI)
			var entity = EntityScene.Instantiate<Control>();
			
			var label = entity.GetNode<Label>("Label");
			label.Text = i.Name;
			
			var icon = entity.GetNode<TextureButton>("Icon");
			
			// 2. Lógica de iconos (simplificada con C#)

			string nodeName = i.Name.ToString(); // Convertimos StringName a string

			string[] candidates = {
				$"res://icons/{nodeName}_icon.png",
				$"res://icons/{nodeName.Replace(" ", "_")}_icon.png",
				$"res://icons/{nodeName.ToLower().Replace(" ", "_")}_icon.png",
				$"res://icons/{nodeName.ToLower().Replace(" ", "")}_icon.png"
			};


			Texture2D icon_image = null;
			foreach(string path in candidates)
			{
				if (ResourceLoader.Exists(path)) {
					icon_image = GD.Load<Texture2D>(path);
					break;
				}
			}

			icon.TextureNormal = icon_image ?? GD.Load<Texture2D>("res://icons/default_icon.png");

			Container.AddChild(entity);

			// 3. Conexión de señal corregida usando eventos de C#
			icon.Pressed += () => OnPress(i);
		}
	}


	public void OnPress(Node3D i)
	{
		var player = _GetLocalPlayer();
		if(player == null || !player.AdminMode) return;
		if(!IsMultiplayerAuthority()) return;

		var raycast = GetParent<Player>().Interactor;

		if(raycast.IsColliding())
		{
			Vector3 collision_point = raycast.GetCollisionPoint();
			Vector3 collision_normal = raycast.GetCollisionNormal();

			Node3D new_i = (Node3D)i.Duplicate();
			new_i.Transform = Transform3D.Identity; 

			Spawnedobject.Add(new_i);
			new_i.SetMultiplayerAuthority(1);
			Globals.Instance.Map.AddChild(new_i, true);

			if (new_i is Meteors)
			{
				new_i.GlobalPosition = collision_point + (collision_normal * 0.5f) + new Vector3(0, 1000, 0);
				
			}
			else
			{
				new_i.GlobalPosition = collision_point + (collision_normal * 0.5f);
			}
			
			Globals.Instance.PrintRole($"Spawned {i.Name} at {new_i.GlobalPosition}");
		}
	}

	public void Spawnmenu()
	{
		Globals.Instance.IsSpawnMenuOpen = !Globals.Instance.IsSpawnMenuOpen;

		if(Globals.Instance.IsSpawnMenuOpen)
		{
			Callable.From(() => {
				Input.MouseMode = Input.MouseModeEnum.Visible;
			}).CallDeferred();
		}
		else
		{
			Callable.From(() => {
				Input.MouseMode = Input.MouseModeEnum.Captured;
			}).CallDeferred();
		}

		this.Visible = Globals.Instance.IsSpawnMenuOpen;
	}


	public void Remove()
	{
		if(Spawnedobject.Count > 0)
		{
			var last = Spawnedobject[Spawnedobject.Count - 1];
			Spawnedobject.RemoveAt(Spawnedobject.Count - 1);

			if(GodotObject.IsInstanceValid(last))
			{
				last.QueueFree();
			}
		}
	}


	public override void _Process(double _delta)
	{

		if(!IsMultiplayerAuthority())
		{
			return ;
		}

		if(Globals.Instance.Gamemode == "survival")
		{
			return ;
		}

		if(Input.IsActionJustPressed("Spawnmenu"))
		{
			Spawnmenu();
		}

		if(Input.IsActionJustPressed("Remove"))
		{
			Remove();
		}
	}


}