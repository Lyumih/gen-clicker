extends Node2D

## Характеристики героя
@export var hero := {
	"gold": 0,
	"attack": {
		"value": 2,
		"level": 1,
		"cost_up": 4,
	},
	"attack_speed": {
		"value": 1.0,
		"level": 1,
		"cost_up": 10,
	}
}

# Характеристики врага
@export var enemy = {
	"health": 4,
	"max_health": 4,
	"level": 1,
	"gold": 3
}

## Обновить информацию по игроку
func _ready() -> void:
	$Timer.wait_time = hero.attack_speed.value
	update_info_player()

## Обновляет статистику по игроку
func update_info_player():
	%InfoPlayer.text = "Золото %s. Атака %s" % [hero.gold, hero.attack.value]
	%UpAttack.text = "Прокачать атаку +1(%s)\nЗолото %s. " % [hero.attack.value, hero.attack.cost_up]
	%Attack.text = "Атака %s" % [hero.attack.value]
	%Enemy.text = "Враг. Ур. %s\nЗдоровье: %s\nЗолото: 1 - %s" % [enemy.level, enemy.health, enemy.gold + enemy.level]
	%UpAttack.disabled = hero.gold <= hero.attack.cost_up
	%UpAttackTime.disabled = (hero.gold <= hero.attack_speed.cost_up) || hero.attack_speed.value <= 0.2
	%UpAttackTime.text = "Прокачать скорость атаки +0.1(%s)\nЗолото %s. " % [hero.attack_speed.value, hero.attack_speed.cost_up]

## Атака по врагу для получения золота
func _on_attack_button_down() -> void:
	enemy.health -= hero.attack.value
	if (enemy.health <= 0):
		enemy.health = randi_range(1, enemy.max_health * enemy.level)
		enemy.level += 1
		hero.gold += randi_range(1, enemy.gold + enemy.level)
	update_info_player()
	

## Прокачка урона за золота.
func _on_up_attack_button_down() -> void:
	if (hero.gold > hero.attack.cost_up):
		hero.attack.value += 1
		hero.attack.level += 1
		hero.gold -= hero.attack.cost_up
		hero.attack.cost_up += hero.attack.value
	update_info_player()

## Атака по таймеру
func _on_timer_timeout() -> void:
	_on_attack_button_down()

## Прокачка скорости атаки (таймера).
func _on_up_attack_time_button_down() -> void:
	if (hero.gold > hero.attack_speed.cost_up):
		if (hero.attack_speed.value <= 0.2):
			return
		hero.attack_speed.value -= 0.1
		hero.attack_speed.level += 1
		hero.gold -= hero.attack_speed.cost_up
		hero.attack_speed.cost_up =  hero.attack_speed.level * 10
		$Timer.wait_time = hero.attack_speed.value
	update_info_player()
