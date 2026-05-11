using Godot;
using Godot.Collections;

[GlobalClass]
public partial class Explosion : Node3D
{
	public int ExplosionForce = 100;
	public int ExplosionDamage = 100;
	public float ExplosionRadius;
	public GpuParticles3D Smoke;
	public GpuParticles3D SmokeShockwaveExplosion;
	public GpuParticles3D Sparks;
	public GpuParticles3D SparksShock;
	public CollisionShape3D colShape;

	// Called when the node enters the scene tree for the first time.
	public override void _Ready()
	{
		colShape = GetNode<CollisionShape3D>("Area3D/CollisionShape3D");
		ExplosionRadius = ((SphereShape3D)GetNode<CollisionShape3D>("Area3D/CollisionShape3D").Shape).Radius;
		Smoke = GetNode<GpuParticles3D>("Smoke");
		SmokeShockwaveExplosion = GetNode<GpuParticles3D>("Smoke shock");
		Sparks = GetNode<GpuParticles3D>("Sparks");
		SparksShock = GetNode<GpuParticles3D>("Sparks shock");
		
		Sparks.Emitting = true;
		SmokeShockwaveExplosion.Emitting = true;
		Smoke.Emitting = true;
		SparksShock.Emitting = true;
	}


	protected void _OnFinished()
	{
		this.QueueFree();
	}
	
	protected void _OnParksFinished()
	{
		colShape.Disabled = true;
	}

	private void _OnArea3DBodyEntered(Node3D body)
	{
		// Aplicar fuerza de explosión a objetos RigidBody3D
		if (body is RigidBody3D rigidBody)
		{
			float distance = GlobalPosition.DistanceTo(rigidBody.GlobalPosition);
			
			// Calcular dirección desde la explosión hacia el objeto
			// Usamos Normalized() para obtener el vector de dirección
			Vector3 direction = (rigidBody.GlobalPosition - GlobalPosition).Normalized();

			// Calcular fuerza basada en la distancia (más cerca = más fuerza)
			// Usamos Mathf.Clamp para asegurar que el valor esté entre 0 y 1
			float forceMultiplier = 1.0f - Mathf.Clamp(distance / ExplosionRadius, 0.0f, 1.0f);
			float force = ExplosionForce * forceMultiplier;

			// Aplicar impulso al RigidBody3D
			// El segundo parámetro es la posición relativa (offset), Vector3.Zero aplica al centro
			rigidBody.ApplyImpulse(direction * force, Vector3.Zero);
		}
	}
}