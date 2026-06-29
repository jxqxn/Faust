# AGENTS.md — 苏丹的游戏 Godot 克隆项目

## 项目目标

在 `C:\Users\User\Documents\GitHub\Faust` 用 Godot 4.x 克隆 Unity 游戏《苏丹的游戏》。

## 语料库

完整逆向产物在 `C:\Users\User\Documents\GitHub\Faust-local-source\_unpack\`（只读，不拷贝、不修改）。

## 逆向参考与验证

实现游戏逻辑时，使用 `$faust-clone-reference` skill。它提供：信任层级、SRC 指针验证、双信号规则、功能域 MANIFEST 导航、已知陷阱清单。该 skill 提供逆向方法论和验证流程。注意：skill 本身也是 .md 文档——语料库里的 .c 反编译和 dump.cs 才是事实本身，skill 教你怎么找到并验证它们。

## 当前进度

逆向工程阶段完成，无阻塞 Godot 克隆启动的开放项。Godot 工程尚未初始化。

## 技术栈

- 引擎：Godot 4.x
- 脚本：GDScript
- 测试：GUT 或 gdUnit4（待定）
- Live2D：第一版用静态图替代，后续按需接入
