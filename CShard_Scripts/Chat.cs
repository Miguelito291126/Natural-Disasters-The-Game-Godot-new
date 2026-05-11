using System.Linq;
using System.Reflection;
using Godot;
using Godot.Collections;

[GlobalClass]
public partial class Chat : CanvasLayer
{
    public TextEdit TextEdit;
    public LineEdit LineEdit;
    public Button Button;

    public Array<string> History = new Array<string>();
    public int HistoryIndex = -1;

	private Array<string> _autocompleteMatches = new Array<string>();
	private int _autocompleteIndex = 0;

    // 1. DICCIONARIO CORREGIDO (Nombres exactos de los métodos en C#)
    public Dictionary<string, Dictionary<string, Variant>> DevCommands = new Dictionary<string, Dictionary<string, Variant>>{
        {"god_mode", new Dictionary<string, Variant>{
            {"desc", "Activa modo Dios."},
            {"method", nameof(_CmdGodModePlayer)}, // Usamos nameof para evitar errores de dedo
            {"args", 0}}},
        {"ungod_mode", new Dictionary<string, Variant>{
            {"desc", "Desactiva modo Dios."},
            {"method", nameof(_CmdUngodModePlayer)},
            {"args", 0}}},
        {"kill_player", new Dictionary<string, Variant>{
            {"desc", "Mata a un jugador. /kill_player Nombre"},
            {"method", nameof(_CmdKillPlayer)},
            {"args", 1}}},
        {"damage_player", new Dictionary<string, Variant>{
            {"desc", "Daña a un jugador. /damage_player Nombre Cantidad"},
            {"method", nameof(_CmdDamagePlayer)},
            {"args", 2}}},
        {"spawn_disaster", new Dictionary<string, Variant>{
            {"desc", "Genera desastre. /spawn_disaster Nombre"},
            {"method", nameof(_CmdSpawnDisasterWeather)},
            {"args", 1}}},
        {"admin", new Dictionary<string, Variant>{
            {"desc", "Da admin. /admin Nombre"},
            {"method", nameof(_CmdAdminModePlayer)},
            {"args", 1}}},
        {"unadmin", new Dictionary<string, Variant>{
            {"desc", "Quita admin. /unadmin Nombre"},
            {"method", nameof(_CmdUnadminModePlayer)},
            {"args", 1}}}
    };

    // --- LÓGICA DE COMANDOS (Asegúrate que reciban STRING) ---

    public string _CmdGodModePlayer()
    {
        var player = _GetLocalPlayer();
        if (player == null) return "Error: Jugador local no encontrado";
        player.GodMode = true;
        return "God Mode activado";
    }

    public string _CmdUngodModePlayer()
    {
        var player = _GetLocalPlayer();
        if (player == null) return "Error: Jugador local no encontrado";
        player.GodMode = false;
        return "God Mode desactivado";
    }

    public string _CmdKillPlayer(string playerName)
    {
        foreach (Node p in GetTree().GetNodesInGroup("player"))
        {
            if (p is Player player && player.Username == playerName)
            {
                player.Damage(999);
                return $"{playerName} fue eliminado.";
            }
        }
        return "Jugador no encontrado.";
    }

    public string _CmdDamagePlayer(string playerName, string amount)
    {
        if (!int.TryParse(amount, out int damageVal)) return "Cantidad de daño inválida.";
        
        foreach (Node p in GetTree().GetNodesInGroup("player"))
        {
            if (p is Player player && player.Username == playerName)
            {
                player.Damage(damageVal);
                return $"{playerName} recibió {damageVal} de daño.";
            }
        }
        return "Jugador no encontrado.";
    }

	public string _CmdSpawnDisasterWeather(string disasterName)
    {
        if (Globals.Instance != null)
        {
            Globals.Instance.Rpc(Globals.MethodName.SetWeatherAndDisaster, disasterName, -1);
            return $"Desastre enviado: {disasterName}";
        }
        return "Error de Globals.";
    }

	public string _CmdAdminModePlayer(string playerName)
		{
			// Buscamos al jugador por nombre en el grupo "player"
			Player target = GetTree().GetNodesInGroup("player")
				.OfType<Player>()
				.FirstOrDefault(p => p.Username == playerName);

			if (target == null) return $"Jugador no encontrado: {playerName}";

			// Ejecutamos el RPC en el jugador objetivo para cambiar su permiso
			// El servidor manda la orden a todos (especialmente al cliente del jugador)
			target.Rpc(Player.MethodName._SetAdminMode, true);
			
			return $"Permisos de ADMIN otorgados a {playerName}";
		}

    public string _CmdUnadminModePlayer(string playerName)
    {
        Player target = GetTree().GetNodesInGroup("player")
            .OfType<Player>()
            .FirstOrDefault(p => p.Username == playerName);

        if (target == null) return $"Jugador no encontrado: {playerName}";

        target.Rpc(Player.MethodName._SetAdminMode, false);
        
        return $"Permisos de ADMIN removidos a {playerName}";
    }

    // --- PROCESAMIENTO Y RED ---

    public void _RunCommand(string cmd)
    {
        string[] parts = cmd.StripEdges().Split(" ", false);
        if (parts.Length == 0) return;

        string commandName = parts[0].ToLower();
        if (!DevCommands.ContainsKey(commandName))
        {
            _ConsolePrint($"Comando desconocido: {commandName}");
            return;
        }

        var cmdInfo = DevCommands[commandName];
        string methodName = cmdInfo["method"].AsString();
        int requiredArgsCount = cmdInfo["args"].AsInt32();
        
        string[] args = parts.Skip(1).ToArray();

        if (args.Length < requiredArgsCount)
        {
            _ConsolePrint($"Uso: /{commandName} {cmdInfo["desc"]}");
            return;
        }

        // --- USAMOS REFLEXIÓN PARA EVITAR EL ERROR DE GODOT ---
        MethodInfo method = GetType().GetMethod(methodName);
        
        if (method != null)
        {
            try 
            {
                // Convertimos los argumentos al tipo que espera el método
                object[] invokeArgs = args.Take(requiredArgsCount).Cast<object>().ToArray();
                
                // Si el método no tiene argumentos, pasamos null
                if (requiredArgsCount == 0) invokeArgs = null;

                object result = method.Invoke(this, invokeArgs);
                if (result != null) _ConsolePrint(result.ToString());
            }
            catch (TargetParameterCountException)
            {
                _ConsolePrint($"Error: El método {methodName} espera un número distinto de argumentos.");
            }
            catch (System.Exception e)
            {
                _ConsolePrint($"Error al ejecutar comando: {e.InnerException?.Message ?? e.Message}");
            }
        }
        else
        {
            _ConsolePrint($"Error: No se encontró el método '{methodName}' en la clase Chat.");
        }
    }

    [Rpc(MultiplayerApi.RpcMode.AnyPeer, CallLocal = true)]
    public void MsgRpc(string username, string data)
    {
        // 1. Mostrar el mensaje para todos
        TextEdit.Text += $"{username}: {data}\n";
        _ScrollToBottom();

        // 2. Si es comando, ejecutar SOLO en el servidor por seguridad y sincronización
        if (data.StartsWith("/") && Multiplayer.IsServer())
        {
            string commandWithoutSlash = data.Substring(1);
            
            // Validar admin antes de ejecutar
            Player sender = GetTree().GetNodesInGroup("player")
                .OfType<Player>()
                .FirstOrDefault(p => p.Username == username);

            if (sender != null && sender.AdminMode)
            {
                _RunCommand(commandWithoutSlash);
            }
        }
    }

    // --- FUNCIONES DE APOYO (Input y UI) ---

    public override void _Ready()
    {
        TextEdit = GetNode<TextEdit>("Panel/TextEdit");
        LineEdit = GetNode<LineEdit>("Panel/Panel2/LineEdit");
        Button = GetNode<Button>("Panel/Panel2/Button");

        if (!IsMultiplayerAuthority())
        {
            this.Visible = false;
            return;
        }
        
        // Conectar señales por código para estar seguros
        LineEdit.FocusEntered += _OnLineEditFocusEntered;
        LineEdit.FocusExited += _OnLineEditFocusExited;
        Button.Pressed += _OnButtonPressed;
    }

	public override void _Input(InputEvent @event)
	{
		if (!IsMultiplayerAuthority()) return;

		// Abrir chat
		if (@event.IsActionPressed("Chat") && !LineEdit.HasFocus())
		{
			LineEdit.GrabFocus();
			GetViewport().SetInputAsHandled(); // Evita que la "T" se escriba en el LineEdit
		}

		if (LineEdit.HasFocus() && @event is InputEventKey k && k.Pressed)
		{
			if (k.Keycode == Key.Tab)
			{
				_HandleAutocomplete();
				GetViewport().SetInputAsHandled(); // ¡CRUCIAL! Evita que el Tab cambie el foco de la UI
			}
			else if (k.Keycode == Key.Enter)
			{
				_OnButtonPressed();
			}
			else if (k.Keycode == Key.Escape)
			{
				LineEdit.ReleaseFocus();
			}
			// Historial (Flechas arriba/abajo)
			else if (k.Keycode == Key.Up) { _HandleHistory(-1); GetViewport().SetInputAsHandled(); }
			else if (k.Keycode == Key.Down) { _HandleHistory(1); GetViewport().SetInputAsHandled(); }
		}
	}

	private void _HandleAutocomplete()
	{
		string currentText = LineEdit.Text.ToLower();
		
		// Si el texto empieza con /, buscamos sin el slash
		string searchKey = currentText.StartsWith("/") ? currentText.Substring(1) : currentText;

		// Si es una nueva búsqueda (no estamos ciclando), regeneramos la lista de coincidencias
		if (_autocompleteMatches.Count == 0 || !searchKey.StartsWith(_autocompleteMatches[_autocompleteIndex].Substring(0, Mathf.Min(searchKey.Length, _autocompleteMatches[_autocompleteIndex].Length))))
		{
			_autocompleteMatches = new Array<string>(DevCommands.Keys.Where(k => k.StartsWith(searchKey)).ToArray());
			_autocompleteIndex = 0;
		}
		else
		{
			// Si ya hay una lista, pasamos al siguiente
			_autocompleteIndex = (_autocompleteIndex + 1) % _autocompleteMatches.Count;
		}

		if (_autocompleteMatches.Count > 0)
		{
			LineEdit.Text = "/" + _autocompleteMatches[_autocompleteIndex];
			LineEdit.CaretColumn = LineEdit.Text.Length; // Mover cursor al final
		}
	}

	private void _HandleHistory(int direction)
	{
		if (History.Count == 0) return;

		HistoryIndex += direction;
		HistoryIndex = Mathf.Clamp(HistoryIndex, 0, History.Count - 1);
		
		LineEdit.Text = History[HistoryIndex];
		LineEdit.CaretColumn = LineEdit.Text.Length;
	}

    public void _OnButtonPressed()
    {
        if (string.IsNullOrWhiteSpace(LineEdit.Text)) return;

        Rpc(MethodName.MsgRpc, Globals.Instance.Username, LineEdit.Text);
        
        History.Add(LineEdit.Text);
        LineEdit.Text = "";
        LineEdit.ReleaseFocus();
    }

    public Player _GetLocalPlayer()
    {
        return GetTree().GetNodesInGroup("player")
            .OfType<Player>()
            .FirstOrDefault(p => p.IsMultiplayerAuthority());
    }

    private void _ScrollToBottom()
    {
        CallDeferred(MethodName._DoScrollToBottom);
    }

    private void _DoScrollToBottom()
    {
        var scroll = TextEdit.GetVScrollBar();
        TextEdit.ScrollVertical = (double)scroll.MaxValue;
    }

    public void _ConsolePrint(string text) => TextEdit.Text += $"[SYSTEM]: {text}\n";
    public void _OnLineEditFocusEntered() => Globals.Instance.IsChatOpen = true;
    public void _OnLineEditFocusExited() => Globals.Instance.IsChatOpen = false;
}