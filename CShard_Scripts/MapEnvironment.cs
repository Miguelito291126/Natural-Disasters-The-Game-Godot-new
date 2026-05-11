using Godot;
using System;

[GlobalClass]
public partial class MapEnvironment : WorldEnvironment
{
    [Export] public DirectionalLight3D Sun;
    [Export] public DirectionalLight3D Moon;

    [Export] public int IngameSpeed = 60; // 1 = Tiempo real, 60 = 1 hora por minuto real
    [Export] public float InitialHour = 12.0f;
    [Export] public float SunBaseEnergy = 2.0f; // Energía normal del sol
    [Export] public float MoonBaseEnergy = 0.2f; // Energía normal de la luna
    public bool IsCloudy = false; // El Map cambiará esto
    public bool IsRaining = false; // El Map cambiará esto
    public override void _Ready()
    {
        // Si no se asignaron en el inspector, buscarlos
        if (Sun == null) Sun = GetNodeOrNull<DirectionalLight3D>("Sun");
        if (Moon == null) Moon = GetNodeOrNull<DirectionalLight3D>("Moon");

        // Inicializar el tiempo en segundos totales
        Globals.Instance.Seconds = InitialHour * 3600.0f; // Convertir horas a segundos
    }

    public override void _Process(double delta)
    {
        // Avanzar tiempo en segundos
        Globals.Instance.Seconds += (float)delta * IngameSpeed;

        _RecalculateTime();
        _UpdateLamps();
    }

    private void _RecalculateTime()
    {
        double secondsInDay = Globals.Instance.Seconds % 86400; // Segundos en un día (24*3600)
        
        Globals.Instance.Day = (int)(Globals.Instance.Seconds / 86400);
        Globals.Instance.Hour = (int)(secondsInDay / 3600);
        Globals.Instance.Minute = (int)((secondsInDay % 3600) / 60);
        
        // Valor de 0.0 a 1.0 que representa el progreso del día
        Globals.Instance.Day = (int)(secondsInDay / 86400.0);
    }

    private void _UpdateLamps()
    {
        float dayProgress = (float)((Globals.Instance.Seconds % 86400) / 86400.0);
        // 0.0 a 360.0. 0 es medianoche, 180 es mediodía.
        float angle = dayProgress * 360.0f; 

        if (Sun != null)
        {
            // Rotación: el Sol gira sobre el eje X
            Sun.RotationDegrees = new Vector3(-angle + 90.0f, 0, 0);
            
            // Intensidad basada en la altura (seno del ángulo)
            float sunFactors = Mathf.Clamp(Mathf.Sin(Mathf.DegToRad(angle - 90f)), 0, 1);
            
            // Si está nublado, reducimos la energía a un 20% en lugar de 0
            float cloudMultiplier = IsCloudy ? 0.2f : 1.0f;
            
            Sun.LightEnergy = sunFactors * SunBaseEnergy * cloudMultiplier;
        }

        if (Moon != null)
        {
            // La luna está a 180 grados de diferencia
            Moon.RotationDegrees = new Vector3(-angle - 90.0f, 0, 0);
            
            // La intensidad de la luna usa el seno invertido
            float moonFactors = Mathf.Clamp(Mathf.Sin(Mathf.DegToRad(angle + 90.0f)), 0, 1);
            
            // La luna también se ve afectada por nubes pero menos drásticamente
            float cloudMultiplier = IsCloudy ? 0.1f : 1.0f;

            Moon.LightEnergy = moonFactors * MoonBaseEnergy * cloudMultiplier;
        }
    }
}