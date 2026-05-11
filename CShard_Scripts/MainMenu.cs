using System.Collections.Generic;
using System.Linq;
using Godot;
using Godot.Collections;

[GlobalClass]
public partial class MainMenu : Control
{
	public Control MainMenuPanel;
	public Label Tittle;
	public new Control Multiplayer;
	public Control MultiplayerList;
	public Control Settings;
	public Control PlayMenu;
	public LineEdit Username;
	public LineEdit IpText;
	public LineEdit PortText;
	public CheckButton Fullscreen;
	public CheckButton Vsync;
	public CheckButton Fps;
	public OptionButton AntiAliasing;
	public OptionButton AntiTropic;
	public HSlider Volumen;
	public HSlider VolumenMusic;
	public HSlider Time;
	public OptionButton Quality;
	public AudioStreamPlayer Music;
	public Label ErrorText;
	public OptionButton Resolutions;
	public Label Version;
	public Label Credits;
	public CheckButton PrivateButton;
	public CheckButton PrivateButton_ListMenu;
	public LineEdit PortText_ListMenu;
	public LineEdit Username_ListMenu;

	public bool MultiplayerMode = false;

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

	public void Addresolutions()
	{
		var current_resolution = Globals.Instance.GlobalsData.Resolution;
		var index = 0;

		foreach(System.Collections.Generic.KeyValuePair<string, Vector2I> r in ResolutionsDic)
		{
			Resolutions.AddItem(r.Key, index);
			index += 1;
		}
	}


	// Called when the node enters the scene tree for the first time.
	public async override void _Ready()
	{
		MainMenuPanel = GetNode<Control>("Panel/Menu");
		Tittle = GetNode<Label>("Panel/Menu/HBoxContainer/Title");
		Multiplayer = GetNode<Control>("Panel/Multiplayer");
		MultiplayerList = GetNode<Control>("Panel/MultiplayerList");
		Settings = GetNode<Control>("Panel/Settings");
		PlayMenu = GetNode<Control>("Panel/Play");
		Username = GetNode<LineEdit>("Panel/Multiplayer/Username");
		IpText = GetNode<LineEdit>("Panel/Multiplayer/Ip");
		PortText = GetNode<LineEdit>("Panel/Multiplayer/Port");
		Username_ListMenu = GetNode<LineEdit>("Panel/MultiplayerList/Username");
		PortText_ListMenu = GetNode<LineEdit>("Panel/MultiplayerList/Port");
		Fullscreen = GetNode<CheckButton>("Panel/Settings/Fullscreen");
		Vsync = GetNode<CheckButton>("Panel/Settings/Vsync");
		Fps = GetNode<CheckButton>("Panel/Settings/Fps");
		AntiAliasing = GetNode<OptionButton>("Panel/Settings/Antialiasing");
		AntiTropic = GetNode<OptionButton>("Panel/Settings/Antitropic");
		Volumen = GetNode<HSlider>("Panel/Settings/Volumen");
		VolumenMusic = GetNode<HSlider>("Panel/Settings/VolumenMusic");
		Time = GetNode<HSlider>("Panel/Play/Time");
		Quality = GetNode<OptionButton>("Panel/Settings/Quality");
		Music = GetNode<AudioStreamPlayer>("Music");
		ErrorText = GetNode<Label>("Panel/Multiplayer/Label");
		Resolutions = GetNode<OptionButton>("Panel/Settings/Resolutions");
		Version = GetNode<Label>("Panel/Version");
		Credits = GetNode<Label>("Panel/Credits");
		PrivateButton = GetNode<CheckButton>("Panel/Multiplayer/PrivateCheck");
		PrivateButton_ListMenu = GetNode<CheckButton>("Panel/MultiplayerList/PrivateCheck");
		Globals.Instance.MainMenu = this;

		MainMenuPanel.Show();
		Tittle.Show();
		Multiplayer.Hide();
		Settings.Hide();
		MultiplayerList.Hide();
		PlayMenu.Hide();

		Version.Text = "V" + Globals.Instance.Version;
		Tittle.Text = (string)Globals.Instance.Gamename;
		Credits.Text = "by " + Globals.Instance.Credits;


		LoadGameScene();

		var args = OS.GetCmdlineUserArgs();
		bool isServer = OS.HasFeature("dedicated_server") || (args != null && args.Contains("server"));

		if (isServer)
		{
			Globals.Instance.PrintRole("Starting server setup...");

			// 1. PROCESAR ARGUMENTOS (Sin bloqueos)
			if (args != null)
			{
				for (int i = 0; i < args.Length; i++)
				{
					switch (args[i])
					{
						case "--port": case "port": case "-p":
							if (i + 1 < args.Length)
							{
								Globals.Instance.Port = args[i + 1].ToInt();
								i++; // Saltamos el valor
							}
							break;

						case "--gamemode": case "gamemode": case "-g":
							if (i + 1 < args.Length)
							{
								Globals.Instance.Gamemode = args[i + 1];
								i++; // Saltamos el valor
							}
							break;
					}
				}
			}

			Globals.Instance.PrintRole($"Config - Port: {Globals.Instance.Port}, Mode: {Globals.Instance.Gamemode}, IP: {Globals.Instance.PublicIp}");

			// Esperamos un poco para asegurar que el árbol de nodos esté totalmente listo
			await ToSignal(GetTree().CreateTimer(1.0), SceneTreeTimer.SignalName.Timeout);
			
			Globals.Instance.PrintRole("Init dedicated server now...");
			Globals.Instance.CreateGame(Globals.Instance.Port);
		}
	}

	public void LoadGameScene()
	{
		Addresolutions();

		IpText.Text = Globals.Instance.Ip;
		PortText.Text = Globals.Instance.Port.ToString();
		Username.Text = Globals.Instance.Username;
		PrivateButton.ButtonPressed = Globals.Instance.privateMode;
		PrivateButton_ListMenu.ButtonPressed = Globals.Instance.privateMode;
		Username_ListMenu.Text = Globals.Instance.Username;
		PortText_ListMenu.Text = Globals.Instance.Port.ToString();

		_OnAntialiasingItemSelected(Globals.Instance.GlobalsData.Antialiasing);
		_OnAntitropicItemSelected(Globals.Instance.GlobalsData.Antitropic);
		_OnVsycnToggled(Globals.Instance.GlobalsData.Vsync);
		_OnVolumenValueChanged(Globals.Instance.GlobalsData.Volumen);
		_OnVolumenMusicValueChanged(Globals.Instance.GlobalsData.VolumenMusic);
		_OnResolutionsItemSelected(Globals.Instance.GlobalsData.Resolution);
		_OnFullscreenToggled(Globals.Instance.GlobalsData.Fullscreen);
		_OnFpsToggled(Globals.Instance.GlobalsData.FPS);
		_OnUsernameTextChanged(Globals.Instance.Username);
		_OnHSlider2ValueChanged(Globals.Instance.GlobalsData.TimerDisasters);
		_OnOptionButtonItemSelected(Globals.Instance.GlobalsData.Quality);

		Fullscreen.ButtonPressed = Globals.Instance.GlobalsData.Fullscreen;
		Fps.ButtonPressed = Globals.Instance.GlobalsData.FPS;
		Vsync.ButtonPressed = Globals.Instance.GlobalsData.Vsync;
		Volumen.Value = Globals.Instance.GlobalsData.Volumen;
		VolumenMusic.Value = Globals.Instance.GlobalsData.VolumenMusic;
		Time.Value = Globals.Instance.GlobalsData.TimerDisasters;
		Quality.Selected = Globals.Instance.GlobalsData.Quality;
		AntiAliasing.Selected = Globals.Instance.GlobalsData.Antialiasing;
		Resolutions.Selected = Globals.Instance.GlobalsData.Resolution;
		AntiTropic.Selected = Globals.Instance.GlobalsData.Antitropic;
	}
		
	public async override void _Process(double _delta)
	{
		if(this.Visible)
		{
			await ToSignal(Music, AudioStreamPlayer.SignalName.Finished);
			Music.Play();
		}
		else
		{
			Music.Stop();
		}
	}

	protected void _OnIpTextChanged(string new_text)
	{
		Globals.Instance.Ip = new_text;
	}


	protected void _OnPortTextChanged(string new_text)
	{
		Globals.Instance.Port = new_text.ToInt();
	}


	protected async void _OnJoinPressed()
	{
		if(Globals.Instance.Username.Count() < 10 && Globals.Instance.Username.Count() >= 1)
		{
			Globals.Instance.PlayMultiplayerClient(Globals.Instance.Ip, Globals.Instance.Port);
		}
		else
		{
			ErrorText.Visible = true;
			await ToSignal(GetTree().CreateTimer(2), SceneTreeTimer.SignalName.Timeout);
			ErrorText.Visible = false;
		}
	}


	protected void _OnHostPressed()
	{
		MultiplayerMode = true;
		MainMenuPanel.Hide();
		Multiplayer.Hide();
		Settings.Hide();
		MultiplayerList.Hide();
		PlayMenu.Show();
	}


	protected void _OnMultiplayerPressed()
	{
		MainMenuPanel.Hide();
		
		Settings.Hide();
		
		PlayMenu.Hide();

		if (Globals.Instance.UseSteam)
		{
			MultiplayerList.Show();
		}
		else
		{
			Multiplayer.Show();
		}
	}

	protected void _OnSandboxPressed()
	{
		Globals.Instance.Gamemode = "sandbox";
		if(MultiplayerMode)
		{
			Globals.Instance.PlayMultiplayerServer(Globals.Instance.Port);
		}
		else
		{
			LoadScene.Instance.loadscene(this, "map");
		}
	}

	protected void _OnSurvivalPressed()
	{
		Globals.Instance.Gamemode = "survival";
		if(MultiplayerMode)
		{
			Globals.Instance.PlayMultiplayerServer(Globals.Instance.Port);
		}
		else
		{
			LoadScene.Instance.loadscene(this, "map");
		}
	}


	protected void _OnSettingsPressed()
	{
		MainMenuPanel.Hide();
		Multiplayer.Hide();
		Settings.Show();
		MultiplayerList.Hide();
		PlayMenu.Hide();
	}


	protected void _OnExitPressed()
	{
		GetTree().Quit();
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


	protected void _OnBackOptionsPressed()
	{
		MainMenuPanel.Show();
		Multiplayer.Hide();
		Settings.Hide();
		MultiplayerList.Hide();
		PlayMenu.Hide();
	}


	protected void _OnUsernameTextChanged(string new_text)
	{
		Globals.Instance.Username = new_text;
		Globals.Instance.GlobalsData.SaveFile();
	}


	protected void _OnHSlider2ValueChanged(float value)
	{
		Globals.Instance.GlobalsData.TimerDisasters = value;
		Globals.Instance.GlobalsData.SaveFile();
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
		GetTree().Root.Size = size;
		Globals.Instance.GlobalsData.SaveFile();
	}


	protected void _OnFullscreenToggled(bool toggled_on)
	{
		if(toggled_on == true)
		{
			DisplayServer.WindowSetMode(DisplayServer.WindowMode.Fullscreen);
		}
		else
		{
			DisplayServer.WindowSetMode(DisplayServer.WindowMode.Windowed);
		}
		Globals.Instance.GlobalsData.Fullscreen = toggled_on;
		Globals.Instance.GlobalsData.SaveFile();
	}


	protected void _OnSingleplayerPressed()
	{
		MultiplayerMode = false;
		MainMenuPanel.Hide();
		Multiplayer.Hide();
		Settings.Hide();
		MultiplayerList.Hide();
		PlayMenu.Show();
	}


	protected void _OnVolumenMusicValueChanged(float value)
	{
		Globals.Instance.GlobalsData.VolumenMusic = value;
		AudioServer.SetBusVolumeDb(AudioServer.GetBusIndex("Music"), Mathf.LinearToDb(value));
		Globals.Instance.GlobalsData.SaveFile();
	}


	protected void _OnOptionButtonItemSelected(int index)
	{
		Globals.Instance.GlobalsData.Quality = index;
		Globals.Instance.GlobalsData.SaveFile();
	}



	protected void _OnBackMultiplayerPressed()
	{
		MainMenuPanel.Show();
		Multiplayer.Hide();
		Settings.Hide();
		MultiplayerList.Hide();
		PlayMenu.Hide();
	}


	protected void _OnBackSingleplayerPressed()
	{
		MainMenuPanel.Show();
		Multiplayer.Hide();
		Settings.Hide();
		MultiplayerList.Hide();
		PlayMenu.Hide();
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

	public void _on_private_check_toggled(bool pressed)
	{
		Globals.Instance.privateMode = pressed;
	}
}