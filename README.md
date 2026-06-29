# CastleSky

`CastleSky` 是一个使用 Godot 4.7 制作中的横版冒险动作闯关游戏。当前阶段的重点不是做完整关卡，而是一步一步把角色动作、手感、动画衔接和基础场景搭起来，方便后续继续扩展成完整的 ARPG / platformer 项目。

目前项目已经完成了第一版角色控制框架：移动、奔跑、跳跃、蹲下、滑铲、后翻滚、受击测试、治疗动作和治疗音效。

## 当前操作键位

| 功能 | 键位 |
| --- | --- |
| 向左移动 | `A` / `Left` |
| 向右移动 | `D` / `Right` |
| 下蹲 / 滑铲触发 | `S` / `Down` |
| 奔跑 | `Shift` |
| 跳跃 | `Space` |
| 后翻滚 | `Q` |
| 治疗 | `U` |
| 测试受击 1 | `H + 1` |
| 测试受击 2 | `H + 2` |
| 测试受击 3 | `H + 3` |

## 已实现动作

### 站立与移动

角色默认处于 `idle` 状态。

移动链路：

```text
idle -> 按方向键 -> walk
walk -> 松开方向键 -> idle
```

当前移动速度：

```text
walk: 130
run: 300
```

### 奔跑

只要方向键和 `Shift` 同时处于按下状态，就会进入奔跑。

奔跑链路：

```text
方向键 + Shift -> run_start -> run
run + 松开 Shift 但方向键还按着 -> run_start 倒放 -> walk
run + 松开方向键 -> run_stop -> idle
```

说明：

`run_start` 用来表现从移动进入奔跑的启动动作。  
从奔跑回到普通移动时，目前使用 `run_start` 倒放，作为 `run_to_walk` 的过渡。  
`run_turn` 暂时移除，后续如果要做转身衔接，会重新单独实现。

### 跳跃

普通跳跃使用 `jump` 动画，共 24 帧。

跳跃分段：

| 帧范围 | 含义 |
| --- | --- |
| 1-4 | 准备起跳 |
| 5-10 | 上升循环 |
| 11-16 | 空中停留 |
| 16-20 | 下落循环 |
| 21-24 | 落地 |

跳跃链路：

```text
Space -> prepare -> up loop -> air -> fall loop -> land -> idle / walk / run_start
```

跳跃规则：

起跳时如果没有按方向键，就是垂直跳。  
在跳跃前 1-20 帧期间，如果按下左或右，会锁定为对应方向的斜跳。  
落地后会根据当前输入回到 `idle`、`walk` 或 `run_start`。

当前跳跃参数：

```text
gravity: 1200
jump velocity: -430
jump horizontal speed: 180
```

### 蹲下

按住 `S` 或 `Down` 进入蹲下。

蹲下动画链路：

```text
按住 S/Down -> crouch enter(1-6) -> crouch idle loop(7-9)
松开 S/Down -> crouch exit(10-13) -> idle / walk / run_start
```

说明：

蹲下期间角色不会水平移动。  
素材中的第 14-15 帧目前没有使用。

### 滑铲

滑铲只在奔跑期间触发。

滑铲链路：

```text
run_start / run + 按 S/Down -> slide -> idle / walk / run_start
```

滑铲规则：

滑铲使用两层动画：`slide_char` 作为角色主层，`slide_merged` 作为特效层。  
特效层只在第 5-13 帧显示。  
按住 `S/Down` 不会连续触发滑铲，必须松开后再按一次才能再次滑铲。

当前滑铲参数：

```text
slide speed: 360
slide frame time: 0.03
```

### 后翻滚

按 `Q` 触发后翻滚。

后翻滚链路：

```text
Q -> back_dodge -> idle / walk / run_start
```

说明：

后翻滚目前只使用 `back dodge(fx included).png` 这一张合并贴图，不再使用单独的特效层。  
动作期间角色会朝当前面向的反方向位移。  
后翻滚结束后会根据当前输入回到地面状态。

当前后翻滚参数：

```text
back dodge speed: 260
back dodge frame time: 0.02
```

### 受击测试

目前受击动作是测试用，不是正式战斗系统。

测试链路：

```text
H + 1 -> hit
H + 2 -> normal_hit
H + 3 -> hard_hit
```

说明：

`hit` 使用 `normal hit` 的前 10 帧。  
`normal_hit` 使用 `normal hit` 的完整 22 帧。  
`hard_hit` 使用 `hard hit` 的完整 34 帧。  
受击期间角色停止水平移动，动画结束后回到地面状态。

### 治疗

按 `U` 触发治疗。

治疗链路：

```text
U -> heal + heal.mp3 -> idle / walk / run_start
```

说明：

治疗使用 `healing_merged.png`。  
治疗音效使用 `assets/audio/heal.mp3`。  
音效已调整到大约匹配治疗动画前段表现。

当前治疗参数：

```text
heal frame time: 0.05
heal sound pitch scale: 1.28
```

## 当前场景结构

主场景：

```text
levels/level_01.tscn
```

主要节点结构：

```text
Level01
Background
Ground
Player
  CollisionShape2D
  Visual
  SlideFx
  HealSfx
  Camera2D
```

角色脚本：

```text
scripts/player.gd
```

角色动画资源：

```text
assets/characters/player_01/player_frames.tres
```

治疗音效：

```text
assets/audio/heal.mp3
```

背景图：

```text
assets/backgrounds/level01_bg.png
```

## 相机与项目设置

当前相机挂在 `Player` 下，跟随角色移动。

相机关键设置：

```text
Process Callback: Physics
Position Smoothing: Enabled
Zoom: 2.3, 2.3
Offset: 0, -85
```

项目物理帧率：

```text
physics_ticks_per_second: 165
```

这个设置是为了匹配高刷新率显示器，让移动和相机跟随看起来更顺。

## 开发记录

已经完成：

- 导入角色资源包并整理到 `assets/characters/player_01`
- 创建第一关基础场景 `level_01`
- 配置 `Player` 为 `CharacterBody2D`
- 配置 `Ground` 为 `StaticBody2D`
- 实现基础移动和奔跑
- 实现 `run_start`、`run_stop`、`run_to_walk` 动作衔接
- 暂时移除 `run_turn`，避免转向闪帧和方向错乱
- 实现普通跳跃和落地动画
- 实现蹲下三段式动画
- 实现奔跑滑铲和滑铲特效层
- 实现后翻滚
- 实现三种受击测试动画
- 实现治疗动作和治疗音效
- 添加基础背景，方便判断跳跃高度和移动距离
- 调整相机跟随，减少拉扯感
- 移除攻击逻辑，准备后续从第一段攻击重新开始

## 暂未实现 / 后续计划

接下来可以继续做：

- 第一段普通攻击 `1x atk`
- 连段攻击 `2x atk`、`2x-1 atk`、`2x-2 atk`
- 重击 `3x atk`
- 攻击判定 hitbox
- 敌人基础 AI
- 受击、伤害、生命值系统
- 空中冲刺
- 二段跳
- 墙滑与墙跳
- 梯子动作
- 悬崖攀爬动作
- 关卡机关和可交互物
- UI、血条、体力条
- 宣传视频用的演示关卡
