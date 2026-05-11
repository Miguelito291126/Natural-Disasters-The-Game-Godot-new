using Godot;
using Godot.Collections;

[GlobalClass]
public partial class DataResource : Resource
{
	public DataResource Data;

	public DataResource()
	{
		Data = this;
	}

	public static string Path = "user://GlobalsData.tres";


	//Globals Settings
	[Export] public bool Vsync = false;
	[Export] public bool FPS = false;
	[Export] public int Antialiasing = 0;
	[Export] public int Antitropic = 0;
	[Export] public float Volumen = 1;
	[Export] public float VolumenMusic = 1;
	[Export] public float TimerDisasters = 60;
	[Export] public bool Fullscreen = false;
	[Export] public int Resolution = 0;
	[Export] public int Quality = 0;



	public void SaveFile()
	{
		Error err = ResourceSaver.Save(this, Path);
		if (err != Error.Ok)
		{
			GD.PrintErr($"Error al guardar la configuración: {err}");
		}
	}

	public static DataResource LoadFile()
	{
		if (!FileAccess.FileExists(Path))
		{
			return new DataResource();
		}

		try 
		{
			// Intentamos cargar el recurso
			var loadedResource = ResourceLoader.Load(Path, "", ResourceLoader.CacheMode.Replace);
			
			// Si el cast falla (InvalidCastException) o es nulo, creamos uno nuevo
			if (loadedResource is DataResource data)
			{
				return data;
			}
		}
		catch (System.Exception e)
		{
			GD.PrintErr($"Fallo crítico al cargar datos: {e.Message}. Creando nuevo archivo...");
		}

		// Si llegamos aquí, algo falló con el archivo viejo, así que devolvemos uno limpio
		return new DataResource();
	}





}