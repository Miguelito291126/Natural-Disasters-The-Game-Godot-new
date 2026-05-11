using Godot;
using Godot.Collections;

[GlobalClass]
public partial class Tsunami : Area3D
{
	public Node3D tsunami;
	[Export] public int Speed = 100;
	[Export] public int TsunamiStrength = 100;
	[Export] public Vector3 Direction = new Vector3(0, 0, 1);
	[Export] public float DistanceTraveled = 0.0f;
	[Export] public float TotalDistance = 4097.0f;

	// Adjust this value based on your scene
	public override void _PhysicsProcess(double delta)
	{
		GlobalPosition += Direction * Speed * (float)delta;

		foreach(Node3D body in GetOverlappingBodies())
		{
			if(body.IsInGroup("movable_objects") && body is RigidBody3D rigidBody3D)
			{
				var force = Direction.Normalized() * TsunamiStrength * (float)delta;
				rigidBody3D.ApplyCentralImpulse(force);
				rigidBody3D.Freeze = false;
			}
			// Dentro del foreach de Tsunami.cs
			else if(body.IsInGroup("player") && body is Player playerBody)
			{
				// Calculamos el empuje (puedes ajustar el multiplicador 1.5f a tu gusto)
				Vector3 pushForce = Direction.Normalized() * Speed * 1.5f; 
				
				// Llamamos a la nueva función del jugador
				playerBody.ApplyDisastersPush(pushForce);
			}
		}
	}

	public override void _Ready()
	{
		tsunami = GetNode<Node3D>("tsunami");
	}
}