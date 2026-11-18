# BRAINROT BAY

make.fun「roblox-brainrot-01」参赛项目：一个复古像素风的 3D brainrot 收集游戏（Rojo 项目）。

## 玩法

- 标题画面按 **Space** 或点 PLAY 开始。
- 在棋盘田野里找搞怪角色，靠近后 **按住 E** 抓起来扛在头上，跑回自己的基地就会自动放上底座，每秒产金币。
- 越往海边（+X）越稀有：7 档稀有度（Common → Secret），5 种突变（Gold x2 / Diamond x3 / Lava x5 / Rainbow x10）。
- **酱汁海啸**：每隔一段时间从海边扫向基地，在田野里被追上会被拍飞、丢掉扛着的角色；跑回基地或躲进 SAFE 避难所。
- **鸽子小偷 Pinchy**：会来偷你基地里最值钱的角色，碰到它能抢回来；基地里的 LOCK 垫可以临时上锁挡住它。
- 右侧按钮：SHOP（速度 / 背负数 / 底座数升级）、REBIRTH（重置换永久收入倍率）、LOCK、INDEX（图鉴）、HOME。
- 底座上的角色按 **F** 卖出；每波海浪后随机触发 DOUBLE CASH / MUTATION STORM / LEGEND RAIN 事件。

## 目录

- `src/shared`：配置、经济公式、角色模型生成（共享）
- `src/server`：世界生成、玩家数据、田野、基地、海浪、小偷、商店、事件
- `src/client`：HUD、面板、特效、标题画面
- `game.rbxl` 由 `rojo build default.project.json --output game.rbxl` 生成
- `screenshots/`：4 张 Studio 截图，`1-cover.jpg` 为封面

## 运行检查

    mkdir -p out && MAKEFUN_OUTPUT_DIR=out node main.ts
