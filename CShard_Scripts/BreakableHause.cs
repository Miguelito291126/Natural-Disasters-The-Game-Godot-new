using System.Threading.Tasks;
using Godot;

[GlobalClass]
public partial class BreakableHause : Node3D
{
	public override async void _Ready()
	{
		await ToSignal(GetTree().CreateTimer(5f), SceneTreeTimer.SignalName.Timeout);
		this.QueueFree();
	}
}