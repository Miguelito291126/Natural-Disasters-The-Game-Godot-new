using Godot;
using Godot.Collections;

[GlobalClass]
public partial class House : StaticBody3D
{
	public Node3D Door;
	public CollisionShape3D DoorCollisionShape;
	public Node3D HauseModel;
	[Export] public AudioStreamPlayer3D DoorOpenSound;
	[Export] public AudioStreamPlayer3D DoorCloseSound;

	[Export] public bool DoorOpen = false;
	[Export] public bool Destrolled = false;

	[Export] public PackedScene Bokenhause = ResourceLoader.Load<PackedScene>("res://Scenes/breakable_hause.tscn");

	//# Factor extra de escala para las piezas destruidas. Las mallas del Breakable
	//# estn en unidades ms pequeas que la casa; aumenta si se ven diminutas.
	[Export] public float BreakableScaleFactor = 2.6f;

	[Rpc(MultiplayerApi.RpcMode.AnyPeer, CallLocal = true)]
	public void OpenDoor()
	{
		Globals.Instance.PrintRole("Open the door");
		Door.Rotation = new Vector3(0, Mathf.DegToRad(145), 0);
		DoorCollisionShape.Disabled = true;
		if(!DoorOpenSound.Playing)
		{
			DoorOpenSound.Play();
		}
		DoorOpen = true;
	}

	[Rpc(MultiplayerApi.RpcMode.AnyPeer, CallLocal = true)]
	public void CloseDoor()
	{
		Globals.Instance.PrintRole("Close the door");
		Door.Rotation = new Vector3(0, Mathf.DegToRad(0), 0);
		DoorCollisionShape.Disabled = false;
		if(!DoorCloseSound.Playing)
		{
			DoorCloseSound.Play();
		}
		DoorOpen = false;
	}


	public void Interact()
	{

		if(!DoorOpen)
		{
			Rpc(MethodName.OpenDoor);
		}
		else
		{
			Rpc(MethodName.CloseDoor);
		}
	}

	[Rpc(MultiplayerApi.RpcMode.AnyPeer, CallLocal = true)]
	public void Destroy()
	{
		if(Destrolled)
		{
			return ;
		}

		Node3D Broken_Hause = Bokenhause.Instantiate<Node3D>();
		GetParent().AddChild(Broken_Hause);
		Broken_Hause.GlobalTransform = HauseModel.GlobalTransform;
		Destrolled = true;

		// Guardar path en Globals
		Globals.Instance.AddDestrolledNodes(this.GetPath());
		this.QueueFree();
	}

	protected void _OnArea3dBodyEntered(Node3D body)
	{
		if(body.IsInGroup("Meteor"))
		{
			Rpc(MethodName.Destroy);
		}
	}

	protected void _OnArea3dAreaEntered(Area3D area)
	{
		if(area.IsInGroup("Tornado") || area.IsInGroup("Water_Area") || area.IsInGroup("Explosion") || area.IsInGroup("Lava_Area"))
		{
			Rpc(MethodName.Destroy);
		}
	}

	public override void _Ready()
	{
		Door = GetNode<Node3D>("hause/pivot");
		DoorCollisionShape = GetNode<CollisionShape3D>("DoorCollision");
		HauseModel = GetNode<Node3D>("hause");
	}
}