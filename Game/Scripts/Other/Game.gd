extends Node

signal game_finished(score)

onready var hans = get_node("Hans") 
onready var tunnels = get_node("Tunnels")
onready var score = get_node("UI/Score")
onready var end = get_node("UI/End")
onready var help = get_node("UI/Help")
onready var cont = get_node("UI/Help/Continue")
onready var prev = get_node("UI/Help/Previous")
onready var battery = get_node("UI/Battery")
onready var timer = get_node("UI/Battery/DropTimer")
onready var pause = get_node("PauseAndResume/Pause")
onready var pause_popup = get_node("PauseAndResume/Pause_popup")

var agent = Keyboard.new()
var self_playing_agent = false
# curr_layer cannot be 0 unless the Help menu is actually shown
# because of the End.gd script conditions
var curr_layer = -1

func _ready():
    if not self_playing_agent:
        disable_sound_loops()
        curr_layer = 0
        _show_first_help_layer()
    else:
        _start()

func set_agent(a):
    if a != "Keyboard":
        self_playing_agent = true
        
    match (a):        
        "Static":
            agent = Static.new()
        "Random":
            agent = Random.new()


func disable_sound_loops():
    $PauseAndResume/Pause_popup/Resume/clickSound.stream.loop = false
    $PauseAndResume/Pause/clickSound.stream.loop = false
    $UI/Help/Continue/clickSound.stream.loop = false
    $UI/Help/layer1/Skip/clickSound.stream.loop = false
    $UI/Help/layer11/Start/clickSound.stream.loop = false
    $UI/Help/Previous/clickSound.stream.loop = false
    hans.get_node("Sounds/shootSound").stream.loop = false

func _start():
    $Sounds/menuBackgroundSound.stop()    
    help.hide() 
    score.show()
    pause.show()
    battery.show()
    timer.start()
    get_tree().paused = false 
    
    for name in ["TrapI","TrapO", "TrapMovingI", "TrapX", "TrapWalls", "TrapHex", 
                    "TrapHexO", "TrapBalls", "TrapTriangles", "TrapHalfHex"]:
        tunnels.trap_scenes.append(load("res://Scenes/Traps/" + name + ".tscn"))
        
    for name in ["Worm", "LadybugFlying", "LadybugWalking"]:
        tunnels.bug_scenes.append(load("res://Scenes/Characters/Bugs/" + name + ".tscn"))
        
    for name in ["Rotavirus", "Bacteriophage"]:
        tunnels.virus_scenes.append(load("res://Scenes/Characters/Viruses/" + name + ".tscn"))
        
    tunnels.token_scenes.append(load("res://Scenes/Tokens/EnergyToken.tscn"))
    
    tunnels.create_first_level_traps()
    if not self_playing_agent:
        $Sounds/gameBackgroundSound.play()

func hide_csg_shapes(node):
    if node is CSGShape or node is AnimationPlayer:
        node.queue_free()
    var children = node.get_children()
    for child in children:
        hide_csg_shapes(child)

func _show_first_help_layer():    
    $Sounds/gameBackgroundSound.stop()
    get_tree().paused = true        
    score.hide()
    pause.hide()
    battery.hide()
    timer.stop()
    help.show()
    prev.hide()
    
    var layer = help.get_child(curr_layer)
    layer.show()
    if not self_playing_agent:
        $Sounds/menuBackgroundSound.play()

func _show_help_layer():
    if curr_layer == 10:
        cont.hide()
    else:
        cont.show()
        
    prev.show()    
        
    var layer = help.get_child(curr_layer)
    layer.show()
        
func _game_over():
    if not self_playing_agent:    
        $Sounds/gameBackgroundSound.stop()
        $Sounds/gameOverSound.play()	
        
    get_tree().paused = true    
    end.show()
    battery.hide()
    timer.stop()
    if self_playing_agent:
        emit_signal("game_finished", score.get_score())
        queue_free()
    else:
        score._display_Final_Score()
        var end_children = end.get_children()
        yield(get_tree().create_timer(2), "timeout")	
        
        
        # a little animation for the end of the game
        end_children[0].show()
        yield(get_tree().create_timer(1.2), "timeout")	
        end_children[0].hide()
        end_children[1].show()
        yield(get_tree().create_timer(1.2), "timeout")
        
        end_children[2].show()
       
func _on_Resume_pressed():
    if not self_playing_agent:    
        $Sounds/menuBackgroundSound.stop()
        $Sounds/gameBackgroundSound.stream_paused = false
        $PauseAndResume/Pause_popup/Resume/clickSound.play()
    pause.show()
    score.show()
    battery.show()
    timer.start()    
    pause_popup.hide()
    get_tree().paused = false

func _on_Pause_pressed():
    if not self_playing_agent:    
        $Sounds/gameBackgroundSound.stream_paused = true
        $Sounds/menuBackgroundSound.play()    
        $PauseAndResume/Pause/clickSound.play()
        
    pause_popup.show()
    pause.hide()
    score.hide()
    battery.hide()
    timer.stop()    
    get_tree().paused = true

func _on_Continue_pressed():
    if not self_playing_agent:
        $UI/Help/Continue/clickSound.play()
    help.get_child(curr_layer).hide()
    curr_layer += 1
    _show_help_layer()


func _on_Skip_pressed():
    curr_layer = -1
    if not self_playing_agent:    
        $UI/Help/layer1/Skip/clickSound.play()
    _start()


func _on_Start_pressed():
    if not self_playing_agent:    
        $UI/Help/layer11/Start/clickSound.play()
    _start()


func _on_Previous_pressed():
    if not self_playing_agent:    
        $UI/Help/Previous/clickSound.play()
        
    help.get_child(curr_layer).hide()
    curr_layer -= 1
    if curr_layer == 0:
        _show_first_help_layer()
    else:
        _show_help_layer()
