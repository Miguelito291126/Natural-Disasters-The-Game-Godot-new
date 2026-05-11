using Godot;
using Godot.Collections;


// Variables para el efecto de sacudida de pantalla
[GlobalClass]
public partial class Camera3d : Camera3D
{
	public float ShakeDuration = 0.5f;
	public float ShakeAmplitude = 0.1f;
	public float ShakeFrequency = 30.0f;


	// Variables internas para controlar el efecto de sacudida
	public float ShakeTimer = 0.0f;
	public Vector3 OriginalPosition = Vector3.Zero;
	public Vector3 ShakeOffset = Vector3.Zero;

	public override void _Ready()
	{
		OriginalPosition = Position;
	}

	public override void _Process(double delta)
	{

		// Si el temporizador de sacudida est� activo
		if(ShakeTimer > 0.0)
		{

			// Calcular el desplazamiento de la sacudida
			ShakeOffset.X = (float)((GD.Randf() * 2.0 - 1.0) * ShakeAmplitude);
			ShakeOffset.Y = (float)((GD.Randf() * 2.0 - 1.0) * ShakeAmplitude);
			ShakeOffset.Z = (float)((GD.Randf() * 2.0 - 1.0) * ShakeAmplitude);


			// Aplicar el desplazamiento de la sacudida a la posici�n de la c�mara
			Position = OriginalPosition + ShakeOffset;


			// Reducir el temporizador de sacudida
			ShakeTimer -= (float)delta;


			// Si el temporizador llega a cero, restaurar la posicin original
			if(ShakeTimer <= 0.0f)
			{
				Position = OriginalPosition;
			}
		}
	}

	public void StartScreenShake(float duration, float amplitude, float frequency)
	{

		// Iniciar la sacudida de pantalla
		ShakeDuration = duration;
		ShakeAmplitude = amplitude;
		ShakeFrequency = frequency;
		ShakeTimer = duration;
	}


}