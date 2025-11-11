extends HSlider

# Enhanced Volume Slider with continuous controller adjustment
# Attach this script to volume sliders for better controller support

var adjustment_speed: float = 50.0  # Units per second when holding
var adjustment_timer: Timer

func _ready():
	# Create and configure timer for continuous adjustment
	adjustment_timer = Timer.new()
	adjustment_timer.wait_time = 0.1  # 10 times per second
	adjustment_timer.timeout.connect(_on_adjustment_timer_timeout)
	add_child(adjustment_timer)
	
	# Connect focus events
	focus_entered.connect(_on_focus_entered)
	focus_exited.connect(_on_focus_exited)
	
	# Enable processing to check input states
	set_process(false)

var current_direction: int = 0  # -1 for left, 1 for right, 0 for none

func _on_focus_entered():
	set_process(true)
	print("Volume slider focused - D-pad should work now")

func _on_focus_exited():
	set_process(false)
	current_direction = 0
	adjustment_timer.stop()
	print("Volume slider unfocused")

func _process(_delta):
	if not has_focus():
		return
	
	# Check current input states instead of relying on events
	var left_pressed = Input.is_action_pressed("ui_left")
	var right_pressed = Input.is_action_pressed("ui_right")
	
	var new_direction = 0
	if left_pressed and not right_pressed:
		new_direction = -1
	elif right_pressed and not left_pressed:
		new_direction = 1
	
	# Start/stop adjustment based on direction change
	if new_direction != current_direction:
		current_direction = new_direction
		
		if current_direction == 0:
			_stop_adjustment()
			print("Stopping adjustment")
		elif current_direction == -1:
			_start_adjustment()
			print("Starting left adjustment")
		elif current_direction == 1:
			_start_adjustment()
			print("Starting right adjustment")

func _start_adjustment():
	if not adjustment_timer.is_stopped():
		return
	adjustment_timer.start()
	_adjust_value()  # Immediate first adjustment

func _stop_adjustment():
	current_direction = 0
	adjustment_timer.stop()

func _on_adjustment_timer_timeout():
	_adjust_value()

func _adjust_value():
	if current_direction == -1:
		value = max(min_value, value - 2.5)  # 2.5% per step
	elif current_direction == 1:
		value = min(max_value, value + 2.5)  # 2.5% per step