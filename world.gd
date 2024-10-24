extends Node2D

## Категории для логов истории. INFO - общая информация (по умолчанию). BATTLE - логи боя. UPGRADE - улучшения и покупки
enum HISTORY {INFO, BATTLE, UPGRADE}

## Характеристики героя
@export var hero := {
	"gold": 100000,
	"attack": {
		"value": 2,
		"level": 1,
		"cost_up": 4,
	},
	"tmp": {
		"attack": 0
	},
	"weapon": {
		"id": 0,
		"effect_id": 0,
		"level": 1
	},
	"attack_speed": {
		"value": 2.0,
		"level": 1,
		"cost_up": 10,
	}
}

## Доступное оружие
@export var weapons = [
	{"id": 0, "name": "Кулаки", "attack": 1, "attack_speed": 2.0, "effect_id": 0},
	{"id": 1, "name": "Меч", "attack": 2, "attack_speed": 1.5, "effect_id": 1},
	{"id": 2, "name": "Копьё", "attack": 3, "attack_speed": 3.5, "effect_id": 2},
	{"id": 3, "name": "Копьё", "attack": 4, "attack_speed": 3, "effect_id": 3},
]

## Доступные эффекты оружий
@export var effects = [
	{"id": 0, "name": "Нет эффекта", "effect": func (): pass},
	{"id": 1, "name": "Критический удар", 
		"effect": func (): 
	hero.tmp.attack = 100500
	print(hero)
	},
	{"id": 2, "name": "Двойное золото", "effect": func (): pass},
	{"id": 3, "name": "Двойной удар", "effect": func (): pass},
]

# Характеристики врага
@export var enemy = {
	"health": 4,
	"max_health": 4,
	"level": 1,
	"gold": 3
}

## Обновить информацию по игроку
func _ready() -> void:
	%TimerAutoattack.wait_time = calc().total.attack_speed
	update_info_player()

## Обновляет статистику по игроку
func update_info_player():
	%InfoPlayer.text = "Золото %s. Атака %s" % [hero.gold, hero.attack.value]
	%UpAttack.text = "Прокачать свою атаку +1(%s)\nЗолото %s. " % [hero.attack.value, hero.attack.cost_up]
	%Attack.text = "Атака на %s\nСкорость атаки: %s" % [calc().total.attack, calc().total.attack_speed]
	%Enemy.text = "Враг. Ур. %s\nЗдоровье: %s\nЗолото: 1 - %s" % [enemy.level, enemy.health, enemy.gold + enemy.level]
	%UpAttack.disabled = hero.gold <= hero.attack.cost_up
	%UpAttackTime.disabled = (hero.gold <= hero.attack_speed.cost_up) || hero.attack_speed.value <= 0.2
	%UpAttackTime.text = "Прокачать скорость атаки +0.1(%s)\nЗолото %s. " % [hero.attack_speed.value, hero.attack_speed.cost_up]
	var weapon = weapons[hero.weapon.id]
	var effect = effects[weapon.effect_id]
	%WeaponInfo.text = "Оружие: %s ур.%s\nАтака: %s(%s)\nСкорость атаки: %s\nЭффект: %s" % [weapon.name, hero.weapon.level, calc().weapon.attack, weapon.attack, weapon.attack_speed, effect.name]

## Посчитать общий урон для атаки
func calc():
	var weapon = weapons[hero.weapon.id]
	var weapon_attack = weapon.attack * (1 + hero.weapon.level / 10)
	return {
		"total": {
			"attack": hero.attack.value + weapon_attack + hero.tmp.attack,
			"attack_speed": hero.attack_speed.value + weapon.attack_speed
		},
		"weapon":{
			"attack": weapon_attack,
		},
	}

## Прокси для получения текущего уровня оружия
func get_hero_weapon():
	return weapons[hero.weapon.id]

## АТАКА по врагу для получения золота
func _on_attack_button_down() -> void:
	effects[weapons[hero.weapon.id].effect_id].effect.call()
	enemy.health -= calc().total.attack
	add_history('Удар на %s. Здоровья: %s' % [ calc().total.attack, enemy.health ], HISTORY.BATTLE)
	hero.tmp.attack = 0
	print( calc())
	#effects[1].effect.call(hero)
	if chance_level_up(hero.weapon.level, 'оружия ' + get_hero_weapon().name):
		hero.weapon.level += 1
	if (enemy.health <= 0):
		enemy.health = randi_range(1, enemy.max_health * enemy.level)
		enemy.level += 1
		add_history('Враг повержен. Уровень врага увеличился до %s' % [ enemy.level ], HISTORY.BATTLE)
		hero.gold += randi_range(1, enemy.gold + enemy.level)
	update_info_player()

## Прокачка урона за золота.
func _on_up_attack_button_down() -> void:
	if (hero.gold > hero.attack.cost_up):
		hero.gold -= hero.attack.cost_up
		if chance_level_up(hero.attack.level, 'Атаки'):
			hero.attack.value += 1
			hero.attack.level += 1
			hero.attack.cost_up += hero.attack.value
	update_info_player()
	
	
## Получить результат увелечения уровня с определённым шансом
func chance_level_up(level: int, name_target: String):
	var chance = randi_range(1, 100)
	var success = false
	if chance > level || chance == 1:
		success = true
	if success:
		add_history('Уровень %s поднялся до %s с шансом %s' % [name_target, level+1, chance], HISTORY.UPGRADE)
		return true
	prints("FALSE chance", chance, level, success)
	return false

## Добавление логов истории по категории. INFO по умолчанию.
func add_history(text: String, type: HISTORY = HISTORY.INFO):
	var prefix = ''
	match type:
		HISTORY.INFO: prefix = 'Общее' 
		HISTORY.BATTLE: prefix = 'Бой' 
		HISTORY.UPGRADE: prefix = 'Улучшение' 
	
	%HistoryList.add_item('[' + prefix + '] ' + text)

## Атака по таймеру
func _on_timer_timeout() -> void:
	_on_attack_button_down()

## Прокачка скорости атаки (таймера).
func _on_up_attack_time_button_down() -> void:
	if (hero.gold > hero.attack_speed.cost_up):
		if (hero.attack_speed.value <= 0.2):
			return
		hero.gold -= hero.attack_speed.cost_up
		if chance_level_up(hero.attack_speed.level, 'Скорость атаки'):
			hero.attack_speed.value -= 0.1
			hero.attack_speed.level += 1
			hero.attack_speed.cost_up =  hero.attack_speed.level * 10
			%TimerAutoattack.wait_time = hero.attack_speed.value
	update_info_player()

## Смена оружия
func _on_weapon_select_item_selected(index: int) -> void:
	hero.weapon.id = index
	add_history('Смена оружия на %s' % weapons[hero.weapon.id].name)
	update_info_player()

## Переключение автоатаки
func _on_autoattack_toggle_toggled(toggled_on: bool) -> void:
	if toggled_on: %TimerAutoattack.start();
	else: %TimerAutoattack.stop()
