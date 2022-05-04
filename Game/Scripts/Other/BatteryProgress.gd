extends TextureProgress

onready var game = get_parent().get_parent()

func _on_DropTimer_timeout():
    decrease_value()
    
func decrease_value():
    if game.tokens.size() > 0:
        value -= 1
        
    get_child(0).text = String(value) + "%"
    
    if value == 0:
        game._game_over()
        
func update_timer():
    $DropTimer.wait_time -= 0.02
