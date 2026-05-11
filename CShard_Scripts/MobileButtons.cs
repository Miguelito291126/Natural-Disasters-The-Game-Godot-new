using Godot;
using Godot.Collections;


// Called when the node enters the scene tree for the first time.
[GlobalClass]
public partial class mobile_buttons : CanvasLayer
{
	public override void _Ready()
	{
		this.Visible = IsMultiplayerAuthority();

		if(!IsMultiplayerAuthority())
		{
			return ;
		}

		this.Visible = true;
	}


}