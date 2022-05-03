extends ColorRect

onready var game = get_parent().get_parent()

func _unhandled_input(event):
    # reset the game if enter is pressed
    if event.is_action_pressed("ui_accept") and $TryAgain.visible:
        var hans = get_node("../../Hans")
        hans.free()
        var _result = get_tree().reload_current_scene()
        get_tree().paused = false
        
    elif event.is_action_pressed("enter") and game.curr_layer == 0:
        game._on_Skip_pressed()
