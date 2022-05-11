extends Spatial

export var speed = 100
onready var sound = get_parent().get_node("../../Hans/Sounds/ShootSomethingDownSound")
onready var score = get_parent().get_node("../../UI/Score")
onready var game = get_parent().get_parent().get_parent()

const QUEUE_FREE_TIME = 3
var timer = 0

func _physics_process(delta):
    # give bullet speed and direction
    global_translate(Vector3.LEFT * speed * delta)
    
    # remove the bullet form the scene after certian time
    timer += delta
    if timer >= QUEUE_FREE_TIME:
        queue_free()

func _on_Area_body_entered(body):
    # bullets can't hit Hans so we disregard if it happens
    if "Hans" in body.name:
        return
        
    if body is KinematicBody and not "Trap" in body.name and not "Token" in body.name:
        # remove the hit obstacle
        #print(body.hit)
        body.hit += 1
        if body.hit == 3:
            body.hit = 0
            if not game.self_playing_agent:
                sound.play()
            body.queue_free()
                
        # increase score by 10
        score._on_Shooting_Obstacle()
        
    # remove the bullet when it hits anything, including traps
    queue_free()
