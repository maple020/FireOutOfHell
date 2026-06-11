extends Node
## 阶段1验收测试脚本
## 使用方法：在RunManager中调用 start_new_run(12345) 后进入战斗场景

## 推荐测试流程：
## 1. 固定Seed: 12345
## 2. 起始牌组: [hellfire_strike, soul_shield, ash_draw, flame_lash] x 2
## 3. 敌人: imp (2只) 或 hellhound (1只)
## 4. 连续完成3场战斗，验证无报错

## 预期结果：
## - 每回合抽5张牌，能量恢复到3
## - 卡牌点击后正确结算伤害/格挡/抽牌
## - 敌人显示意图并正确执行
## - 玩家死亡或敌人全灭时战斗结束且只结算一次