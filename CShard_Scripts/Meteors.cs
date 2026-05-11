using Godot;
using Godot.Collections;

[GlobalClass]
public partial class Meteors : RigidBody3D
{
	[Export]  public PackedScene ExplosionScene = ResourceLoader.Load<PackedScene>("res://Scenes/explosion.tscn");
	[Export] public bool IsVolcanoRock = false;
	

	// Called when the node enters the scene tree for the first time.
	public override void _Ready()
	{
		// Solo mover hacia arriba si NO es una roca del volc�n
		if(!IsVolcanoRock)
		{
			this.GlobalPosition += new Vector3(0, 1000, 0);
		}
	}


	protected void _OnBodyEntered(Node3D body)
	{
		// En RigidBody3D, 'body' suele ser el OTRO objeto, 
        // así que 'body == this' raramente será cierto, pero es buena seguridad.
        if (body == this) return;

        // Solo el servidor debería manejar la lógica de instanciar explosiones si hay daño
        if (Multiplayer.IsServer())
        {
            CallDeferred(MethodName.SpawnExplosion);
        }
        
        // Eliminamos el meteoro
        QueueFree();
	}

	private void SpawnExplosion()
    {
        if (ExplosionScene == null) return;

        Node3D explosionNode = ExplosionScene.Instantiate<Node3D>();
        

        explosionNode.TopLevel = true; // Asegura que no herede movimientos raros


        // Usamos CallDeferred para añadir el nodo de forma segura fuera del paso de física
        GetParent().AddChild(explosionNode, true);
        
        // Establecemos la posición. 
        // Usamos CallDeferred para la posición también si el nodo aún no está en el árbol

        explosionNode.GlobalPosition = GlobalPosition;
        explosionNode.Position = Position;
    }


}