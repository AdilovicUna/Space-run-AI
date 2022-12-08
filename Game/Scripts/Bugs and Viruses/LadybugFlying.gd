extends Spatial

# generate a number between 0 and 13
# if we add 4, range will be 4-17
# devide by 1000 so we get a range between 0.004 and 0.017
# with a step of 0.001
# (rand_range would give us numbers such as 0.083425)
export(float) var speed = (randi()%13+4) / 1000.0

