using Godot;
using System.Linq;
using System.Threading.Tasks;

[GlobalClass]
public partial class Icons : Node
{
    public override void _Ready()
    {
        CallDeferred(MethodName.GenerateIconsSequentially);
    }

    private async void GenerateIconsSequentially()
    {
		DisableAllSubViewports();

        // 2. Procesamos uno por uno
        foreach (Node child in GetChildren())
        {
            if (child is SubViewport viewport)
            {
                EnableAllChildsInSubViewports(viewport);
				Camera3D cam = FindCameraRecursive(viewport);
				if (cam == null)
				{
					GD.PrintErr($"[ERROR] No hay ninguna Camera3D dentro de {viewport.Name}. Saltando...");
					continue;
				}

				GD.Print($"Procesando: {viewport.Name}...");

				cam.Current = true;
				viewport.RenderTargetUpdateMode = SubViewport.UpdateMode.Once;

                await ToSignal(GetTree(), SceneTree.SignalName.ProcessFrame);
                await ToSignal(RenderingServer.Singleton, RenderingServer.SignalName.FramePostDraw);

				var texture = viewport.GetTexture();
				if (texture == null) continue;

                Image img = viewport.GetTexture().GetImage();
				

                if (img != null && !img.IsEmpty())
                {
                    string path = $"res://icons/{viewport.Name}.png";
                    img.SavePng(path);
                    GD.Print($"[EXITO] Guardado: {path}");
                }

				cam.Current = false;
                viewport.RenderTargetUpdateMode = SubViewport.UpdateMode.Disabled;
                DisableAllChildsInSubViewports(viewport);

                await ToSignal(GetTree(), SceneTree.SignalName.ProcessFrame);
            }
        }

        GD.Print(">>> Generación secuencial completada sin errores.");
    }

	private Camera3D FindCameraRecursive(Node parent)
	{
		if (parent is Camera3D camera) return camera;
		
		foreach (Node child in parent.GetChildren())
		{
			var found = FindCameraRecursive(child);
			if (found != null) return found;
		}
		return null;
	}

    private void DisableAllSubViewports()
    {
        foreach (Node child in GetChildren())
        {
            if (child is not SubViewport viewport) continue;

            GD.Print($"[INFO] Desactivando SubViewport: {child.Name}");
            viewport.RenderTargetUpdateMode = SubViewport.UpdateMode.Disabled;
            GD.Print($"[INFO] Desactivando todos los hijos en SubViewport: {child.Name}");
            DisableAllChildsInSubViewports(viewport);
        }
    }

    private void DisableAllChildsInSubViewports(SubViewport vp)
    {
        foreach (Node child in vp.GetChildren())
        {
            if (child is DirectionalLight3D || child is WorldEnvironment || child is Camera3D)
            {
                GD.Print($"[INFO] Nodo '{child.Name}' dentro de '{vp.Name}' es una luz o cámara. No se cambiará su visibilidad.");
                continue; // No queremos desactivar luces ni cámaras, solo objetos visibles
            }
    
            if (child is Node3D child3D)
            {
                child3D.Visible = false;
            }
            else
            {
                GD.PrintErr($"[WARNING] Nodo '{child.Name}' dentro de '{vp.Name}' no es Node3D. No se puede cambiar su visibilidad.");
            }
        }
    }

    private void EnableAllChildsInSubViewports(SubViewport vp)
    {
        foreach (Node child in vp.GetChildren())
        {  
            if (child is DirectionalLight3D || child is WorldEnvironment || child is Camera3D)
            {
                GD.Print($"[INFO] Nodo '{child.Name}' dentro de '{vp.Name}' es una luz o cámara. No se cambiará su visibilidad.");
                continue; // No queremos desactivar luces ni cámaras, solo objetos visibles
            }

            if (child is Node3D child3D)
            {
                child3D.Visible = true;
            }
            else
            {
                GD.PrintErr($"[WARNING] Nodo '{child.Name}' dentro de '{vp.Name}' no es Node3D. No se puede cambiar su visibilidad.");
            }
        }
    }
}


