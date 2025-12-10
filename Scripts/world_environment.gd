extends WorldEnvironment

@onready var Sun = $Sun
@onready var Moon = $Moon

var minutes_per_day = 1440
var minutes_per_hour = 60
var ingame_to_real_minute_duration = (2 * PI) / minutes_per_day
var sun_node # Referencia al nodo del sol
var celestial_speed_per_hour = 15  # Velocidad a la que el sol se mueve en grados por hora
var sun_angle = -90 # Ángulo inicial del sol
var moon_angle = 90
var interpolation_speed = 1.0

var GlobalsData: DataResource = DataResource.load_file()


@export var ingame_speed = 1
@export var initial_hour = 12:
    set(h):
        initial_hour = h
        Globals.time = ingame_to_real_minute_duration * initial_hour * minutes_per_hour

var past_minute = -1.0

func _ready():
    if multiplayer.is_server():
        Globals.time = ingame_to_real_minute_duration * initial_hour * minutes_per_hour


func _process(delta):
    if multiplayer.is_server():
        Globals.time += delta * ingame_to_real_minute_duration * ingame_speed
        _recalculate_time(delta)

func _recalculate_time(delta):
    var total_minutes = int(Globals.time / ingame_to_real_minute_duration)
    Globals.Day = int(total_minutes / minutes_per_day)

    var current_day_minutes = total_minutes % minutes_per_day
    Globals.Hour = int(current_day_minutes / minutes_per_hour)
    Globals.Minute = int(current_day_minutes % minutes_per_hour)

    if past_minute != Globals.Minute:
        past_minute = Globals.Minute

    # Hora en formato decimal
    var time_of_day = Globals.Hour + Globals.Minute / 60.0

    # Ángulo objetivo en grados
    sun_angle = 90.0 + (time_of_day * celestial_speed_per_hour)
    moon_angle = -90.0 + (time_of_day * celestial_speed_per_hour)

    # Normalizar a [0, 360)
    sun_angle = fmod(sun_angle, 360.0)
    if sun_angle < 0.0:
        sun_angle += 360.0

    moon_angle = fmod(moon_angle, 360.0)
    if moon_angle < 0.0:
        moon_angle += 360.0

    # Interpolar usando la función que hace la rotación por la ruta más corta
    var t = clamp(interpolation_speed * delta, 0.0, 1.0)
    Sun.rotation_degrees.x = rad_to_deg(lerp_angle(deg_to_rad(Sun.rotation_degrees.x), deg_to_rad(sun_angle), t))
    Moon.rotation_degrees.x = rad_to_deg(lerp_angle(deg_to_rad(Moon.rotation_degrees.x), deg_to_rad(moon_angle), t))