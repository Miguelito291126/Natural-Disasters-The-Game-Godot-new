using Godot;
using Godot.Collections;

[GlobalClass]
public partial class LoadingScreen : CanvasLayer
{
	[Signal]
	public delegate void SafeToLoadEventHandler();

	public ProgressBar ProgressBar;
	public AnimationPlayer Animationplayer;

	public void UpdateProgressBar(float new_value)
	{
		// Verificamos si la ProgressBar es válida y no ha sido liberada (disposed)
		if (IsInstanceValid(ProgressBar)) 
		{
			ProgressBar.SetValueNoSignal(new_value * 100);
		}
	}

	public async void FadeOutLoadingScreen()
	{
		// 1. Verificación de seguridad inicial
		if (!IsInstanceValid(this) || Animationplayer == null) return;

		// Aseguramos que la animación exista antes de darle Play
		if (Animationplayer.HasAnimation("fade_out"))
		{
			Animationplayer.Play("fade_out");
			
			// 2. Esperamos a que termine la animación
			await ToSignal(Animationplayer, AnimationPlayer.SignalName.AnimationFinished);
			
			// 3. Verificación post-await: fundamental después de cualquier ToSignal
			// Si el usuario cerró el juego o cambió de escena rápido, el objeto podría ser nulo aquí
			if (IsInstanceValid(this))
			{
				this.QueueFree();
			}
		}
		else
		{
			// Si no hay animación, liberamos el nodo inmediatamente para no bloquear el flujo
			this.QueueFree();
		}
	}


	public override void _Ready()
	{
		ProgressBar = GetNodeOrNull<ProgressBar>("Control/ProgressBar");
		Animationplayer = GetNodeOrNull<AnimationPlayer>("AnimationPlayer");

		if (ProgressBar == null || Animationplayer == null)
		{
			GD.PrintErr("Error: No se encontraron los nodos hijos en LoadingScreen. Revisa los nombres en la escena.");
		}
	}
}