extends Node
class_name Icons

func _ready() -> void:
	generate_icons_sequentially.call_deferred()

func generate_icons_sequentially() -> void:
	disable_all_subviewports()

	for child in get_children():
		if child is SubViewport:
			enable_all_children_in_viewport(child)
			var cam = find_camera_recursive(child)
			if cam == null:
				printerr("[ERROR] No hay Camera3D en %s" % child.name)
				continue

			print("Procesando: %s..." % child.name)
			cam.current = true
			child.render_target_update_mode = SubViewport.UPDATE_ONCE

			await get_tree().process_frame
			await RenderingServer.frame_post_draw

			var img = child.get_texture().get_image()
			if img and not img.is_empty():
				var path = "res://icons/%s.png" % child.name
				img.save_png(path)
				print("[EXITO] Guardado: %s" % path)

			cam.current = false
			child.render_target_update_mode = SubViewport.UPDATE_DISABLED
			disable_all_children_in_viewport(child)
			await get_tree().process_frame

	print(">>> Generación completada.")

func find_camera_recursive(node: Node) -> Camera3D:
	if node is Camera3D: return node
	for child in node.get_children():
		var found = find_camera_recursive(child)
		if found: return found
	return null

func disable_all_subviewports() -> void:
	for child in get_children():
		if child is SubViewport:
			child.render_target_update_mode = SubViewport.UPDATE_DISABLED
			disable_all_children_in_viewport(child)

func disable_all_children_in_viewport(vp: SubViewport) -> void:
	for child in vp.get_children():
		if child is DirectionalLight3D or child is WorldEnvironment or child is Camera3D:
			continue
		if child is Node3D:
			child.visible = false

func enable_all_children_in_viewport(vp: SubViewport) -> void:
	for child in vp.get_children():
		if child is DirectionalLight3D or child is WorldEnvironment or child is Camera3D:
			continue
		if child is Node3D:
			child.visible = true