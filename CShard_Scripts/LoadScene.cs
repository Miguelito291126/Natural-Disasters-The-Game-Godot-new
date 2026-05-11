using Godot;
using Godot.Collections;

[GlobalClass]
public partial class LoadScene : Node
{

	public static LoadScene Instance { get; private set; }

	public override void _Ready()
	{
		if(Instance != null)
		{
			GD.PrintErr("Ya existe una instancia de LoadScene. Esto no debera pasar, pero si est pasando, se est creando una nueva instancia de LoadScene para evitar errores fatales. Si este mensaje aparece ms de una vez, por favor reporta este error a los desarrolladores.");
		}
		Instance = this;
	}

	[Signal]
	public delegate void ProgressChangedEventHandler(float progress);

	[Signal]
	public delegate void LoadDoneEventHandler();

	public Dictionary<string, string> GAME_SCENE = new() {
			{"map", "res://Scenes/map.tscn"},
			};

	public static string LoadingScreenPath = "res://Scenes/loading_screen.tscn";
	public PackedScene LoadingScreenScene = ResourceLoader.Load<PackedScene>(LoadingScreenPath);
	public PackedScene LoaderResource;
	public string ScenePath;
	public Array Progress = new Array();

	public bool UseSubTheads = false;


	public async void loadscene(Node current_scene, string next_scene)
	{

		if(next_scene != null)
		{
			ScenePath = next_scene;
		}

		LoadingScreen loadingScreenInstance = LoadingScreenScene.Instantiate<LoadingScreen>();
		Globals.Instance.Main.AddChild(loadingScreenInstance);

		// Suscribirse a los eventos de C#
		this.ProgressChanged += loadingScreenInstance.UpdateProgressBar;
		this.LoadDone += loadingScreenInstance.FadeOutLoadingScreen;

		// Usar el nombre de señal generado por Godot
		await ToSignal(loadingScreenInstance, LoadingScreen.SignalName.SafeToLoad);

		if(current_scene != null && IsInstanceValid(current_scene))
		{
			current_scene.QueueFree();
		}
		else
		{
			Globals.Instance.PrintRole("No current scene to free");
		}


		if(GAME_SCENE.ContainsKey(ScenePath))
		{
			ScenePath = GAME_SCENE[ScenePath];
		}

		var loader_next_scene = ResourceLoader.LoadThreadedRequest(ScenePath, "", UseSubTheads);
		if(loader_next_scene == Error.Ok)
		{
			Globals.Instance.PrintRole("loading...");
			SetProcess(true);
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
			{
				EmitSignal(SignalName.ProgressChanged, Progress[0]);
				break; }
			case ResourceLoader.ThreadLoadStatus.Loaded:
			{
				Globals.Instance.PrintRole("Completed");

				if(ScenePath == "res://Scenes/main.tscn")
				{

				}
				else
				{
					Node new_scene = ((PackedScene)ResourceLoader.LoadThreadedGet(ScenePath)).Instantiate();
					if(IsInstanceValid(new_scene))
					{
						Globals.Instance.Main.AddChild(new_scene);
					}
				}

				EmitSignal(SignalName.ProgressChanged, 1.0);
				EmitSignal(SignalName.LoadDone);
				SetProcess(false);
				break; }
		}
	}


}