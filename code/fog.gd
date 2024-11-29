extends Node2D

# Reference to the particles node
@export var particles_node: CPUParticles2D
# The material used for the particles
@export var particle_material: ShaderMaterial
# Base amount and opacity
@export var base_particle_amount: int = 10
@export var max_particle_amount: int = 100
@export var base_opacity: float = 0.2
@export var max_opacity: float = 1.0

# Count of enemies
var enemy_count: int = 0

# Called when an enemy is spawned
func on_enemy_spawned():
	enemy_count += 1
	update_particles()

# Called when an enemy is destroyed
func on_enemy_destroyed():
	enemy_count = max(0, enemy_count - 1)
	update_particles()

# Update the particle amount and opacity based on the enemy count
func update_particles():
	# Calculate particle amount and opacity based on enemy count
	var normalized_count = float(enemy_count) / 10.0 # Adjust divisor for sensitivity
	var new_amount = clamp(int(base_particle_amount + (max_particle_amount - base_particle_amount) * normalized_count), base_particle_amount, max_particle_amount)
	var new_opacity = clamp(base_opacity + (max_opacity - base_opacity) * normalized_count, base_opacity, max_opacity)

	# Apply changes
	particles_node.amount = new_amount
	if particle_material:
		particle_material.set_shader_param("particle_opacity", new_opacity)
