using Godot;
using Godot.Collections;

[GlobalClass]
public partial class Main : Node3D
{
	public override void _Ready()
	{
		Globals.Instance.Main = this;
		LoadScene.Instance.loadscene(null, "res://Scenes/main_menu.tscn");
	}


}