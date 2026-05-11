using Godot;
using Godot.Collections;

[GlobalClass]
public partial class Thunder : Node3D
{
	[Export] public PackedScene ExplosionScene = ResourceLoader.Load<PackedScene>("res://Scenes/thunder_explosion.tscn");
	private GpuParticles3D _spark;
    private GpuParticles3D _light;
    private GpuParticles3D _star;


	// Called when the node enters the scene tree for the first time.
	public override void _Ready()
	{
		// Asignación de nodos
		_spark = GetNode<GpuParticles3D>("spark");
        _light = GetNode<GpuParticles3D>("light");
        _star = GetNode<GpuParticles3D>("star");
        
        _spark.Emitting = true;
        _light.Emitting = true;
        _star.Emitting = true;

		if (Multiplayer.IsServer())
		{
			CallDeferred(MethodName.SpawnExplosion);
		}
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

	protected void _OnSparkFinished()
	{
		this.QueueFree();
	}

}