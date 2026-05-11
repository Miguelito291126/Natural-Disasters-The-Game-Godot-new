using Godot;
using Godot.Collections;

[GlobalClass]
public partial class Tornado : Area3D
{
	[Export] public float MovementSpeed = 10;
	[Export] public float MovementRadius = 50;

	[Export] public float RayLength = 1000;
	[Export] public float GroundHeight = 0;

	[Export] public float TornadoStrength = 100;
	[Export] public float Radius = 10;


	public RayCast3D RayCast;

	public override void _Ready()
	{
		RayCast = GetNode<RayCast3D>("RayCast");
		RayCast.TargetPosition = new Vector3(0,  - RayLength, 0);
		RayCast.ForceRaycastUpdate();
		SetProcess(true);
	}

	public override void _Process(double delta)
	{
		if(RayCast.IsColliding())
		{
			GroundHeight = RayCast.GetCollisionPoint().Y;
			GlobalPosition = new Vector3(GlobalPosition.X, GroundHeight, GlobalPosition.Z);
			// Mantener el tornado a la altura del suelo

		}// Genera una nueva posicin aleatoria dentro del radio de movimiento


		var new_position = new Vector3((float)GD.RandRange( -MovementRadius, MovementRadius), 0, (float)GD.RandRange( - MovementRadius, MovementRadius));


		// Aplica movimiento hacia la nueva posicin
		var direction = (new_position - GlobalPosition).Normalized();
		Translate(direction * MovementSpeed * (float)delta);
	}


	public override void _PhysicsProcess(double _delta)
	{
		foreach(Node3D body in GetOverlappingBodies())
		{
			if(body.IsInGroup("movable_objects") && body is RigidBody3D rigidBody3D)
			{
				var direction = (body.GlobalPosition - GlobalPosition).Normalized();
				var perpendicular_direction = new Vector3( - direction.Z, 0, direction.X);
				// Direcci�n perpendicular al vector hacia el tornado
				var force = perpendicular_direction * TornadoStrength;
				rigidBody3D.ApplyCentralImpulse(force);
				rigidBody3D.Freeze = false;
			}
			else if(body.IsInGroup("player") && body is Player playerBody)
			{
				var direction = (body.GlobalPosition - GlobalPosition).Normalized();
				var perpendicular_direction = new Vector3( - direction.Z, 0, direction.X);
				// Direccin perpendicular al vector hacia el tornado
				var force = perpendicular_direction * TornadoStrength;
				playerBody.ApplyDisastersPush(force);
			}
		}
	}


}