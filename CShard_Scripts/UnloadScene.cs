using Godot;
using Godot.Collections;

[GlobalClass]
public partial class UnloadScene : Node
{
	[Signal]
	public delegate void ProgressChangedEventHandler(float progress);
	[Signal]
	public delegate void UnloadDoneEventHandler();

	public static UnloadScene Instance { get; private set; }

	public override void _Ready()
	{
		if(Instance != null)
		{
			GD.PrintErr("Ya existe una instancia de UnloadScene. Esto no debera pasar, pero si est pasando, se est creando una nueva instancia de UnloadScene para evitar errores fatales. Si este mensaje aparece ms de una vez, por favor reporta este error a los desarrolladores.");
		}
		Instance = this;
	}


	public static string UnloadingScreenPath = "res://Scenes/loading_screen.tscn";
	public PackedScene UnloadingScreenScene = ResourceLoader.Load<PackedScene>(UnloadingScreenPath);
	public PackedScene UnloaderResource;
	public Variant Scene;
	public string ScenePath;
	public Array Progress = new Array();

	public bool UseSubTheads = false;

	public async void unloadscene(Node current_scene)
	{

		if(current_scene != null)
		{
			ScenePath = current_scene.SceneFilePath;
			Scene = current_scene;
		}

		LoadingScreen UnloadingScreenInstance = UnloadingScreenScene.Instantiate<LoadingScreen>();
		Globals.Instance.Main.AddChild(UnloadingScreenInstance);

		this.ProgressChanged += UnloadingScreenInstance.UpdateProgressBar;
		this.UnloadDone += UnloadingScreenInstance.FadeOutLoadingScreen;

		await ToSignal(UnloadingScreenInstance, LoadingScreen.SignalName.SafeToLoad);

		if(current_scene != null)
		{
			if(GodotObject.IsInstanceValid(current_scene))
			{
				current_scene.QueueFree();
			}
		}

		var loader_next_scene = ResourceLoader.LoadThreadedRequest(ScenePath, "", UseSubTheads);
		if(loader_next_scene == Error.Ok)
		{
			Globals.Instance.PrintRole("unloading...");
			SetProcess(true);
		}
	}

	public void ClearNodegameExceptSpawner()
	{
		if(!IsInstanceValid(Globals.Instance.Main))
		{
			return ;
		}

		foreach(Node child in Globals.Instance.Main.GetChildren())
		{
			if(child.Name != "MapSpawner")
			{
				// aqu� pon el nombre exacto de tu spawner en la escena
				child.QueueFree();
			}
		}
	}

	public override void _Process(double _delta)
	{
		ResourceLoader.ThreadLoadStatus load_status = ResourceLoader.LoadThreadedGetStatus(ScenePath, Progress);
		switch(load_status)
		{
			case ResourceLoader.ThreadLoadStatus.InvalidResource:
				Globals.Instance.PrintRole("failed to load: invalid resource");
				SetProcess(false);
				return ;
			case ResourceLoader.ThreadLoadStatus.Failed:
			
				Globals.Instance.PrintRole("failed to load");
				SetProcess(false);
				return ; 

			case ResourceLoader.ThreadLoadStatus.InProgress:
				EmitSignal(SignalName.ProgressChanged, Progress[0]);
				break; 
			case ResourceLoader.ThreadLoadStatus.Loaded:
			
				Globals.Instance.PrintRole("Completed");
				EmitSignal(SignalName.ProgressChanged, 1.0);
				EmitSignal(SignalName.UnloadDone);
				SetProcess(false);
				break; 
		}
	}


}