using System.Collections.Generic;
using Godot;
using Godot.Collections;

[GlobalClass]
public partial class PauseMenu : CanvasLayer
{
	public bool MouseActionState = false;

	public WorldEnvironment Worldenvironment;
	public DirectionalLight3D Light;
	public DirectionalLight3D Light2;

	public Control MainMenu;
	public Control Settings;
	public CheckButton Fullscreen;
	public CheckButton Vsync;
	public CheckButton Fps;
	public OptionButton AntiAliasing;
	public OptionButton AntiTropic;
	public HSlider Volumen;
	public HSlider VolumenMusic;
	public HSlider Time;
	public OptionButton Quality;
	public OptionButton Resolutions;

	
	public Godot.Collections.Dictionary<string, Vector2I> ResolutionsDic = new Godot.Collections.Dictionary<string, Vector2I>() {
			{"2400x1080 ", new Vector2I(2400, 1080)},
			{"1920x1080", new Vector2I(1920, 1080)},
			{"1600x900", new Vector2I(1600, 900)},
			{"1440x1080", new Vector2I(1440, 1080)},
			{"1440x900", new Vector2I(1440, 900)},
			{"1366x768", new Vector2I(1366, 768)},
			{"1360x768", new Vector2I(1360, 768)},
			{"1280x1024", new Vector2I(1280, 1024)},
			{"1280x962", new Vector2I(1280, 962)},
			{"1280x960", new Vector2I(1280, 960)},
			{"1280x800", new Vector2I(1280, 800)},
			{"1280x768", new Vector2I(1280, 768)},
			{"1280x720", new Vector2I(1280, 720)},
			{"1176x664", new Vector2I(1176, 664)},
			{"1152x648", new Vector2I(1152, 648)},
			{"1024x768", new Vector2I(1024, 768)},
			{"800x600", new Vector2I(800, 600)},
			{"720x480", new Vector2I(720, 480)},
			};

	public DataResource GlobalsData = DataResource.LoadFile();

	public void Addresolutions()
	{
		var current_resolution = Globals.Instance.GlobalsData.Resolution;
		var index = 0;

		foreach(KeyValuePair<string, Vector2I> r in ResolutionsDic)
		{
			Resolutions.AddItem(r.Key, index);
			index += 1;
		}
	}


	// Called when the node enters the scene tree for the first time.
	public override void _Ready()
	{
		MainMenu = GetNode<Control>("Panel/Menu");
		Settings = GetNode<Control>("Panel/Settings");
		Fullscreen = GetNode<CheckButton>("Panel/Settings/Fullscreen");
		Vsync = GetNode<CheckButton>("Panel/Settings/Vsync");
		Fps = GetNode<CheckButton>("Panel/Settings/Fps");
		AntiAliasing = GetNode<OptionButton>("Panel/Settings/Antialiasing");
		AntiTropic = GetNode<OptionButton>("Panel/Settings/Antitropic");
		Volumen = GetNode<HSlider>("Panel/Settings/Volumen");
		VolumenMusic = GetNode<HSlider>("Panel/Settings/VolumenMusic");
		Time = GetNode<HSlider>("Panel/Settings/Time");
		Quality = GetNode<OptionButton>("Panel/Settings/Quality");
		Resolutions = GetNode<OptionButton>("Panel/Settings/Resolutions");

		Worldenvironment = Globals.Instance.Map.Worldenvironment;
		Light = Globals.Instance.Map.Worldenvironment.Sun;
		Light2 = Globals.Instance.Map.Worldenvironment.Moon;

		if(!IsMultiplayerAuthority())
		{
			this.Hide();
			return ;
		}

		this.Hide();
		MainMenu.Show();
		Settings.Hide();

		LoadGameScene();
	}


	public void LoadGameScene()
	{
		Addresolutions();

		_OnAntialiasingItemSelected(Globals.Instance.GlobalsData.Antialiasing);
		_OnAntitropicItemSelected(Globals.Instance.GlobalsData.Antitropic);
		_OnVsycnToggled(Globals.Instance.GlobalsData.Vsync);
		_OnVolumenValueChanged(Globals.Instance.GlobalsData.Volumen);
		_OnVolumenMusicValueChanged(Globals.Instance.GlobalsData.VolumenMusic);
		_OnResolutionsItemSelected(Globals.Instance.GlobalsData.Resolution);
		_OnFullscreenToggled(Globals.Instance.GlobalsData.Fullscreen);
		_OnFpsToggled(Globals.Instance.GlobalsData.FPS);
		_OnTimeValueChanged(Globals.Instance.GlobalsData.TimerDisasters);
		_OnOptionButtonItemSelected(Globals.Instance.GlobalsData.Quality);


		Fullscreen.ButtonPressed = Globals.Instance.GlobalsData.Fullscreen;
		Fps.ButtonPressed = Globals.Instance.GlobalsData.FPS;
		Vsync.ButtonPressed = Globals.Instance.GlobalsData.Vsync;
		Volumen.Value = Globals.Instance.GlobalsData.Volumen;
		VolumenMusic.Value = Globals.Instance.GlobalsData.VolumenMusic;
		Time.Value = Globals.Instance.GlobalsData.TimerDisasters;
		Quality.Selected = Globals.Instance.GlobalsData.Quality;
		Resolutions.Selected = Globals.Instance.GlobalsData.Resolution;
		AntiAliasing.Selected = Globals.Instance.GlobalsData.Antialiasing;
		AntiTropic.Selected = Globals.Instance.GlobalsData.Antitropic;
	}


	protected void _OnIpTextChanged(string new_text)
	{
		Globals.Instance.Ip = new_text;
	}


	protected void _OnPortTextChanged(string new_text)
	{
		Globals.Instance.Port = int.Parse(new_text);
	}


	protected void _OnPlayPressed()
	{
		MainMenu.Hide();
		Settings.Hide();
	}


	protected void _OnSettingsPressed()
	{
		MainMenu.Hide();
		Settings.Show();
	}


	protected void _OnExitPressed()
	{
		Pause();
		Globals.Instance.CloseConection();
	}

	public override void _ExitTree()
	{
		Globals.Instance.TemperatureTarget = Globals.Instance.TemperatureOriginal;
		Globals.Instance.HumidityTarget = Globals.Instance.HumidityOriginal;
		Globals.Instance.PressureTarget = Globals.Instance.PressureOriginal;
		Globals.Instance.WindDirectionTarget = Globals.Instance.WindDirectionOriginal;
		Globals.Instance.WindSpeedTarget = Globals.Instance.WindSpeedOriginal;
	}

	protected void _OnFpsToggled(bool toggled_on)
	{
		Globals.Instance.GlobalsData.FPS = toggled_on;
		Globals.Instance.GlobalsData.SaveFile();
	}


	protected void _OnVsycnToggled(bool toggled_on)
	{
		Globals.Instance.GlobalsData.Vsync = toggled_on;

		if(toggled_on)
		{
			DisplayServer.WindowSetVsyncMode(DisplayServer.VSyncMode.Enabled);
		}
		else
		{
			DisplayServer.WindowSetVsyncMode(DisplayServer.VSyncMode.Disabled);
		}

		Globals.Instance.GlobalsData.SaveFile();
	}

	protected void _OnBackPressed()
	{
		MainMenu.Show();
		Settings.Hide();
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


	public void MouseAction()
	{
		if(MouseActionState)
		{
			Callable.From(() => {
				Input.MouseMode = Input.MouseModeEnum.Captured;
			}).CallDeferred();
		}
		else
		{
			Callable.From(() => {
				Input.MouseMode = Input.MouseModeEnum.Visible;
			}).CallDeferred();
		}

		MouseActionState = !MouseActionState;
	}

	public void Pause()
	{
		Globals.Instance.IsPauseMenuOpen = !Globals.Instance.IsPauseMenuOpen;

		if(Multiplayer.MultiplayerPeer is OfflineMultiplayerPeer)
		{
			GetTree().Paused = false;
		}

		if(!Globals.Instance.IsPauseMenuOpen)
		{
			Callable.From(() => {
				Input.MouseMode = Input.MouseModeEnum.Captured;
			}).CallDeferred();
		}
		else
		{
			Callable.From(() => {
				Input.MouseMode = Input.MouseModeEnum.Visible;
			}).CallDeferred();
		}

		this.Visible = Globals.Instance.IsPauseMenuOpen;
	}


	public override void _Process(double _delta)
	{
		if(!IsMultiplayerAuthority())
		{
			return ;
		}

		if(Input.IsActionJustPressed("Mouse Action"))
		{
			MouseAction();
		}

		if(Input.IsActionJustPressed("Pause"))
		{
			Pause();
		}
	}


	protected void _OnTimeValueChanged(float value)
	{
		var player = _GetLocalPlayer();
		if(player == null || !player.AdminMode)
		{
			Globals.Instance.PrintRole("You dont have perms");
			return ;
		}

		if(!Globals.Instance.Started)
		{
			return ;
		}

		Globals.Instance.GlobalsData.TimerDisasters = value;
		Globals.Instance.GlobalsData.SaveFile();
		Globals.Instance.Timer.WaitTime = value;
	}


	protected void _OnVolumenValueChanged(float value)
	{
		Globals.Instance.GlobalsData.Volumen = value;
		AudioServer.SetBusVolumeDb(AudioServer.GetBusIndex("Master"), Mathf.LinearToDb(value));
		Globals.Instance.GlobalsData.SaveFile();
	}


	protected void _OnResolutionsItemSelected(int index)
	{
		Globals.Instance.GlobalsData.Resolution = index;
		var size = ResolutionsDic.GetValueOrDefault(Resolutions.GetItemText(index));
		DisplayServer.WindowSetSize(size);
		Globals.Instance.GlobalsData.SaveFile();
	}


	protected void _OnFullscreenToggled(bool toggled_on)
	{
		Globals.Instance.GlobalsData.Fullscreen = toggled_on;
		if(toggled_on == true)
		{
			DisplayServer.WindowSetMode(DisplayServer.WindowMode.Fullscreen);
		}
		else
		{
			DisplayServer.WindowSetMode(DisplayServer.WindowMode.Windowed);
		}
		Globals.Instance.GlobalsData.SaveFile();
	}

	protected void _OnResetPlayerPressed()
	{
		Pause();
		GetParent<Player>()._ResetPlayer();
	}

	protected void _OnReturnPressed()
	{
		Pause();
	}

	protected void _OnVolumenMusicValueChanged(float value)
	{
		Globals.Instance.GlobalsData.VolumenMusic = value;
		AudioServer.SetBusVolumeDb(AudioServer.GetBusIndex("Music"), Mathf.LinearToDb(value));
		Globals.Instance.GlobalsData.SaveFile();
	}

	protected void _OnOptionButtonItemSelected(int index)
	{

		switch(index)
		{
			case 0:
			{
				Light.ShadowEnabled = false;
				Light2.ShadowEnabled = false;
				Light.DirectionalShadowMode = DirectionalLight3D.ShadowMode.Orthogonal;
				Worldenvironment.Environment.SdfgiEnabled = false;
				Worldenvironment.Environment.GlowEnabled = false;
				Worldenvironment.Environment.SsaoEnabled = false;
				break; }
			case 1:
			{
				Light.ShadowEnabled = true;
				Light2.ShadowEnabled = true;
				Light.DirectionalShadowMode = DirectionalLight3D.ShadowMode.Parallel2Splits;
				Worldenvironment.Environment.SdfgiEnabled = false;
				Worldenvironment.Environment.GlowEnabled = true;
				Worldenvironment.Environment.SsaoEnabled = false;
				break; }
			case 2:
			{
				Light.ShadowEnabled = true;
				Light2.ShadowEnabled = true;
				Light.DirectionalShadowMode = DirectionalLight3D.ShadowMode.Parallel4Splits;
				Worldenvironment.Environment.SdfgiEnabled = true;
				Worldenvironment.Environment.GlowEnabled = true;
				Worldenvironment.Environment.SsaoEnabled = true;
				break; }
		}

		Globals.Instance.GlobalsData.Quality = index;
		Globals.Instance.GlobalsData.SaveFile();
	}

	protected void _OnAntialiasingItemSelected(int index)
	{
		Globals.Instance.GlobalsData.Antialiasing = index;

		var viewport = GetViewport();

		switch(index)
		{
			case 0:
			{viewport.Msaa3D = Viewport.Msaa.Disabled;
				break; }
			case 1:
			{viewport.Msaa3D = Viewport.Msaa.Msaa2X;
				break; }
			case 2:
			{viewport.Msaa3D = Viewport.Msaa.Msaa4X;
				break; }
			case 3:
			{viewport.Msaa3D = Viewport.Msaa.Msaa8X;
				break; }
		}

		Globals.Instance.GlobalsData.SaveFile();
	}


	protected void _OnAntitropicItemSelected(int index)
	{
		Globals.Instance.GlobalsData.Antitropic = index;

		int[] levels = { 1, 2, 4, 8, 16 };

		if(index >= 0 && index < levels.Length)
		{
			int value = levels[index];
			ProjectSettings.SetSetting("rendering/textures/default_filters/anisotropic_filtering_level", value);
		}

		Globals.Instance.GlobalsData.SaveFile();
	}

}