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
onready var state = get_node("UI/State")

var traps = ["TrapI","TrapO", "TrapMovingI", "TrapX", "TrapWalls", "TrapHex", "TrapHexO", "TrapBalls", "TrapTriangles", "TrapHalfHex"]
var bugs = ["Worm", "LadybugFlying", "LadybugWalking"]
var viruses = ["rotavirus", "Bacteriophage"]
var tokens = ["EnergyToken"]

var agent
var tunnel = 0
var self_playing_agent = false
var shooting_enabled = true
var dists
var rots

var num_of_ticks = 0

# curr_layer cannot be 0 unless the Help menu is actually shown
# because of the End.gd script conditions
var curr_layer = -1

func _ready():
    if not self_playing_agent:
        disable_sound_loops()
        agent = Keyboard.new()
        #curr_layer = 0
        #_show_first_help_layer()
    _start()

func set_agent(agent_str, agent_inst):   
    if agent_str != "Keyboard":
        self_playing_agent = true
    
    agent = agent_inst

func set_tunnel(t):
    tunnel = t - 1

func set_env(parameters):
    # env wasn't specified, so we put everything
    if parameters.size() == 0:
        return
        
    if not "traps" in parameters:
        traps = []
        for param in parameters:
            if param != "bugs" and  param != "viruses" and param != "tokens":
                traps.append("Trap" + param)
                
    if not "bugs" in parameters:
        bugs = []
        
    if not "viruses" in parameters:
        viruses = []
        
    if not "tokens" in parameters:
        tokens = []
    
func set_shooting(shooting):
    shooting_enabled = shooting
    
func set_dists(d):
    dists = d

func set_rots(r):
    rots = r

func disable_sound_loops():
    $UI/Help/Continue/clickSound.stream.loop = false
    $UI/Help/layer1/Skip/clickSound.stream.loop = false
    $UI/Help/layer11/Start/clickSound.stream.loop = false
    $UI/Help/Previous/clickSound.stream.loop = false
    hans.get_node("Sounds/shootSound").stream.loop = false

func _start():
    $Sounds/menuBackgroundSound.stop()    
    help.hide() 
    score.show()
    battery.show()
    timer.start()
    get_tree().paused = false 
    
    for name in traps:
        tunnels.scenes["trap_scenes"].append(load("res://Scenes/Traps/" + name + ".tscn"))
        
    for name in bugs:
        tunnels.scenes["bug_scenes"].append(load("res://Scenes/Characters/Bugs/" + name + ".tscn"))
        
    for name in viruses:
        tunnels.scenes["virus_scenes"].append(load("res://Scenes/Characters/Viruses/" + name + ".tscn"))
        
    for name in tokens:
        tunnels.scenes["token_scenes"].append(load("res://Scenes/Tokens/" + name + ".tscn"))
    
    match tunnel:
        hans.lvl.TWO:
            hans.translation = Vector3(1250,-32,0)
        hans.lvl.THREE:
            hans.translation = Vector3(-1250,-32,0)
    
    tunnels.create_first_level_traps(tunnel)
    if not self_playing_agent:
        $Sounds/gameBackgroundSound.play()

func hide_csg_shapes(node):
    var children = node.get_children()
    for child in children:
        if child is CSGShape or child is AnimationPlayer:
            # child needs to be freed before removed, otherwise there will be leaked instances
            child.queue_free()
            node.remove_child(child)
        else:
            hide_csg_shapes(child)

func _show_first_help_layer():    
    $Sounds/gameBackgroundSound.stop()
    get_tree().paused = true        
    score.hide()
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
        emit_signal("game_finished", score.get_score(), num_of_ticks)
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
