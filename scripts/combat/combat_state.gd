class_name CombatState
extends RefCounted
## 战斗状态枚举，供 CombatManager 状态机使用。

enum State {
	IDLE,
	PLAYER_TURN,
	TARGETING,
	RESOLVING,
	ENEMY_TURN,
	ANIMATION,
	VICTORY,
	DEFEAT,
}
