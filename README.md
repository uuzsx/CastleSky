# CastleSky

`CastleSky` 是一个使用 Godot 4.7 制作的横版冒险动作闯关游戏。当前阶段的重点是先把玩家角色的移动、跳跃、空中机动、连段攻击、Boss 木桩、受击反馈和 UI 框架打磨清楚，方便后续继续扩展成完整的 platformer / ARPG 项目。

目前项目已经形成一套偏高速动作游戏的基础手感：移动和奔跑会影响跳跃距离、二段跳距离、dash 距离和落地动作，空中攻击又能和 dash、二段跳互相衔接。

## 项目入口

| 类型 | 路径 |
| --- | --- |
| 主场景 | `levels/level_01.tscn` |
| 玩家脚本 | `scripts/player.gd` |
| Agis 脚本 | `scripts/agis.gd` |
| 玩家动画资源 | `assets/characters/player_01/player_frames.tres` |
| Agis 动画资源 | `assets/enemies/agis/agis_frames.tres` |
| UI 资源 | `assets/ui/ornate_fantasy/` |
| 音效资源 | `assets/audio/` |

## 当前键位

| 功能 | 键位 |
| --- | --- |
| 左移 | `A` / `Left` |
| 右移 | `D` / `Right` |
| 上方向输入 | `W` / `Up` |
| 下蹲 / 滑铲输入 | `S` / `Down` |
| 奔跑 | `Shift` |
| 跳跃 / 二段跳 | `Space` |
| 地面后翻滚 / 空中 dash | `K` |
| 普通攻击 / 空中攻击 | `J` |
| 空中升空攻击 | `W + J` / `Up + J` |
| 治疗 | `U` |
| 玩家扣血测试 | `T` |
| 受击测试 1 | `H + 1` |
| 受击测试 2 | `H + 2` |
| 受击测试 3 | `H + 3` |

## 核心参数

| 参数 | 当前值 | 说明 |
| --- | --- | --- |
| `WALK_SPEED` | `125.0` | 普通移动速度 |
| `RUN_SPEED` | `300.0` | 奔跑速度 |
| `GRAVITY` | `1200.0` | 普通重力 |
| `JUMP_VELOCITY` | `-430.0` | 一段跳初速度 |
| `DOUBLE_JUMP_VELOCITY` | `-390.0` | 二段跳初速度 |
| `AIR_DASH_WALK_SPEED` | `250.0` | 行走速度体系下的空中 dash |
| `AIR_DASH_RUN_SPEED` | `360.0` | 奔跑速度体系下的空中 dash |
| `SLIDE_SPEED` | `360.0` | 滑铲速度 |
| `BACK_DODGE_SPEED` | `260.0` | 后翻滚速度 |
| `PLAYER_MAX_HP` | `100.0` | 玩家最大生命 |

## 玩家状态总览

玩家当前主要状态包括：

```text
IDLE
WALK_START / WALK
RUN_START / RUN / RUN_TURN / RUN_TO_WALK / RUN_STOP
CROUCH
SLIDE
BACK_DODGE
JUMP / DOUBLE_JUMP / AIR_DASH / LAND / ROLL_LAND
LIGHT_ATTACK_1-5
JUMP_ATTACK_1 / JUMP_ATTACK_2
HURT
HEAL
```

## 移动与奔跑

普通移动使用 `A/D` 或方向键。按下方向键后会先进入 `walk_start`，然后循环 `walk`。

```text
idle -> 按方向键 -> walk_start -> walk
walk -> 松开方向键 -> idle
```

奔跑由方向键和 `Shift` 共同触发。

```text
方向键 + Shift -> run_start -> run
run + 松开 Shift 但方向键仍按住 -> run_to_walk -> walk
run + 松开方向键 -> run_stop -> idle
```

当前 `run_turn` 已接入转向逻辑：玩家奔跑时不松开 `Shift`，直接切换反方向，会先播放 `run_turn`，播放完后再回到 `run`。

## 跳跃系统

普通跳跃使用完整 `jump` 动画，共 24 帧。

| 帧范围 | 含义 |
| --- | --- |
| 1-4 | 准备起跳 |
| 5-10 | 上升 loop |
| 11-16 | 空中停留 |
| 16-20 | 下落 loop |
| 21-24 | 落地收尾 |

跳跃链路：

```text
Space -> prepare -> up loop -> air -> fall loop -> land -> idle / walk / run_start
```

跳跃会继承当前速度体系：

- 行走时起跳，水平速度继承 `WALK_SPEED`。
- 奔跑时起跳，水平速度继承 `RUN_SPEED`。
- 垂直起跳后，在 1-20 帧期间按左右方向，会锁定对应方向。

## 二段跳

二段跳使用 `double jump_vertical` 和 `double jump_forward`。

当前规则：

- 垂直二段跳：没有水平方向时触发，不接 roll landing。
- 行走方向二段跳：继承行走速度，不接 roll landing。
- 奔跑方向二段跳：继承奔跑速度，落地前会插入 `roll_landing`。

奔跑方向二段跳落地链路：

```text
double_jump_forward -> fall loop -> roll_landing -> run
```

普通一段跳落地仍然使用 `jump` 的 21-24 帧。奔跑二段跳的 `roll_landing` 是额外插入的衔接动作。

## Dash

空中按 `K` 触发 dash。地面按 `K` 是后翻滚。

dash 特点：

- 只能在空中触发。
- 一段跳和二段跳期间都可以 dash。
- dash 距离取决于进入空中状态时的速度体系。
- 行走体系 dash 速度为 `250.0`。
- 奔跑体系 dash 速度为 `360.0`。
- dash 会刷新一次空中攻击机会。
- dash 可以被空中攻击中断，避免冲过目标后打不中。
- dash 可以穿过 Agis。

dash 视觉层：

- 主体动画使用 `aerial dash` 第一排 6 帧。
- 烟雾使用 `aerial dash_smoke`，在 dash 起点原地播放，不跟随玩家。
- 残影使用 `aerial dash_fx`，同样在 dash 起点播放。

## 下蹲

下蹲使用 `S/Down`。

```text
按住 S/Down -> crouch enter(1-6) -> crouch idle loop(7-9)
松开 S/Down -> crouch exit(10-13) -> idle / walk / run_start
```

下蹲期间角色不进行水平移动。

## 滑铲

滑铲在奔跑期间按 `S/Down` 触发。

```text
run_start / run + S/Down -> slide -> idle / walk / run_start
```

滑铲规则：

- 滑铲速度为 `360.0`。
- 17 帧动画，40ms 每帧。
- 1-2 帧为 from。
- 3-15 帧为 slide。
- 16-17 帧为 to idle。
- 按住 `S/Down` 不会连续触发，必须松开后再按。
- 滑铲期间可以穿过 Agis。

## 后翻滚

地面按 `K` 触发后翻滚。

```text
K -> back_dodge -> idle / walk / run_start
```

后翻滚规则：

- 使用 `back dodge(fx included)` 合并贴图。
- 24 帧动画，35ms 每帧。
- 移动方向是当前面朝方向的反方向。
- 后翻滚期间可以穿过 Agis。

## 地面攻击

地面普通攻击使用 `J`，当前是五段连段。

```text
J -> 1段
短时间内 J -> 2段
短时间内 J -> 3段 + 4段自动衔接
短时间内 J -> 5段
```

连段窗口：

```text
LIGHT_ATTACK_COMBO_WINDOW = 0.3s
```

也就是说，如果超过 0.3 秒没有继续按 `J`，下一次攻击会从第一段重新开始。

### 地面攻击素材与帧率

| 段数 | 动画 | 贴图 | 帧数 | 每帧时间 |
| --- | --- | --- | --- | --- |
| 1段 | `light_attack_1` | `1x atk_merged.png` | 17 | 40ms |
| 2段 | `light_attack_2` | `2x atk_merged(short).png` | 19 | 40ms |
| 3段 | `light_attack_3` | `2x-1 atk_merged.png` | 6 | 40ms |
| 4段 | `light_attack_4` | `2x-2 atk_merged.png` | 10 | 40ms |
| 5段 | `light_attack_5` | `3x atk_merged.png` | 34 | 35ms |

### 地面攻击移动

地面攻击不会默认滑行。只有按住攻击朝向的方向键时，才会在指定帧内轻微推进。

| 段数 | 推进帧 | 速度 |
| --- | --- | --- |
| 1段 | 1-10 帧 | `15.0` |
| 2段 | 1-10 帧 | `15.0` |
| 3段 | 不推进 | `0.0` |
| 4段 | 不推进 | `0.0` |
| 5段 | 1-18 帧 | `30.0` |

注意：代码里的帧编号从 0 开始，所以 1-10 帧对应 `<= 9`，1-18 帧对应 `<= 17`。

### 地面攻击命中帧

| 段数 | 命中触发帧 | 伤害 |
| --- | --- | --- |
| 1段 | 第 7 帧附近 | `8` |
| 2段 | 第 7 帧附近 | `10` |
| 3段 | 第 4 帧附近 | `6` |
| 4段 | 第 4 帧附近 | `12` |
| 5段 | 第 13 帧附近 | `25` |

## 空中攻击

空中攻击使用 `J` 和 `W/Up + J`。

当前空中攻击设计是：

```text
空中 J -> jump_attack_1
成功打出 jump_attack_1 后，W/Up + J -> jump_attack_2
成功打出 jump_attack_2 后，奖励一次 jump_attack_1
奖励 jump_attack_1 后，空中攻击链结束
```

完整链路：

```text
jump_attack_1 -> jump_attack_2 -> bonus jump_attack_1 -> fall / land
```

### 空中攻击与机动刷新

理论上每次空中机动会刷新一次空中攻击机会：

- 一段跳后，可以空中攻击一次。
- dash 后，可以再次空中攻击。
- 二段跳后，可以再次空中攻击。

空中攻击细节：

- 普通 `jump_attack_1` 会继承进入攻击前的水平速度。
- 如果从行走跳进入，继承行走体系速度。
- 如果从奔跑跳进入，继承奔跑体系速度。
- 如果从 dash 进入，继承 dash 速度。
- `jump_attack_2` 是升空攻击，需要 `W/Up + J`，不继承水平速度。
- 成功打出 `jump_attack_2` 后，奖励一次 `jump_attack_1`。
- 奖励的 `jump_attack_1` 不继承速度，因为升空攻击已经清掉水平动量。
- 空中攻击期间不受重力影响，开始时会把垂直速度清零。

### 空中攻击素材与帧率

| 动作 | 贴图 | 帧数 | 每帧时间 |
| --- | --- | --- | --- |
| 空中一段 | `jump attack 1x_merged.png` | 9 | 40ms |
| 空中二段 / 升空攻击 | `jump atk 2x_merged.png` | 8 | 100ms |

空中二段贴图尺寸为 `400x224`，当前按 `4列 x 2行` 切成 8 帧，每帧 `100x112`。

## 受击与治疗

### 受击测试

当前玩家受击仍然是测试功能：

```text
H + 1 -> hit
H + 2 -> normal_hit
H + 3 -> hard_hit
```

受击期间玩家停止水平移动，动画结束后返回地面状态。

### 治疗

```text
U -> heal + heal.mp3 -> idle / walk / run_start
```

治疗使用 `healing_merged.png`，音效使用 `assets/audio/heal.mp3`。当前玩家 UI 中已有血条显示，`T` 可以测试扣血。

## Agis 木桩 Boss

Agis 当前作为木桩 Boss，用于测试攻击、受击、伤害数字、Boss 血条和死亡流程。

### 登场

当玩家接近 Agis 到一定距离后，Agis 播放登场动画。

```text
玩家接近 -> Agis intro -> Boss 血条从空补满 -> idle
```

登场期间：

- Agis 无敌。
- 玩家攻击不会扣血。
- Boss 血条显示，并从左到右补满。

### 受击

Agis 有两个 HurtBox 判定：

- 上半身：横向较宽，用于头部和手臂区域。
- 下半身：较窄竖向区域，避免打空气也造成伤害。

受击反馈：

- 命中后根据命中区域播放 hit fx。
- hit fx 使用 `hit_fx_1` 或 `hit_fx_2` 随机播放。
- Agis 受击时会闪白 `0.1s`。
- 会生成伤害数字。
- 普通伤害颜色为 `48C0B0`。
- 重击伤害颜色为 `5D4CB7`。

### 死亡

Agis 血量为 `300`。

死亡流程：

```text
HP <= 0 -> Boss 血条立刻隐藏 -> 播放 death -> 播放死亡音效 -> 关闭主碰撞体和 HurtBox -> 死亡动画结束后隐藏尸体
```

死亡动画当前时长为 4 秒，死亡音效为 `assets/audio/agis_death.mp3`。

### 碰撞策略

Agis 主身体碰撞体仍然保留，但主节点 `collision_layer = 0`，所以玩家正常移动、奔跑、跳跃时可以穿过 Agis，不会被 Boss 身体挡住。

保留主碰撞体的原因是为了后续避免 Boss 或场景逻辑出现掉出地图等问题，同时不影响当前战斗爽感。

## UI

当前已有两套 UI：

- 玩家 UI：头像框、血条、预留状态条。
- Boss UI：Agis 名字、Boss 血条框、程序渲染血量条。

字体：

```text
assets/fonts/antiquity-print.ttf
```

Boss 血条特点：

- 登场时从空补满。
- 死亡瞬间立刻隐藏。
- 名字 `Agis` 显示在血条上方。

## 相机与项目设置

相机挂在 `Player` 下。

关键设置：

```text
Process Callback: Physics
Position Smoothing: Enabled
Zoom: 2.3, 2.3
Offset: 0, -85
```

项目物理帧率：

```text
physics/common/physics_ticks_per_second = 165
```

这个设置用于匹配高刷新率显示器，让移动和相机跟随更顺。

## 当前开发重点

已经完成的核心内容：

- 玩家基础移动、行走、奔跑、转向、停止衔接。
- 一段跳、二段跳、奔跑二段跳落地翻滚。
- 空中 dash、烟雾、残影、穿 Boss。
- 下蹲、滑铲、后翻滚。
- 地面五段攻击。
- 空中一段、升空攻击、奖励空中一段。
- 玩家受击测试、治疗和血条。
- Agis 木桩 Boss、登场、血条、受击、死亡。
- 伤害数字和 hit fx。
- 玩家 UI 和 Boss UI。

后续可以继续做：

- Agis 正式攻击玩家。
- 玩家防御、受身或无敌帧。
- 更多敌人和关卡机关。
- 玩家体力条 / 魔法条机制。
- 墙滑、墙跳、梯子、悬崖动作。
- 正式关卡流程和胜负条件。
