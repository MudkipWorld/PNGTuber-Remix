# PNGTuber Remix 1.4.5 运动逻辑差异说明

日期：2026-10-18
范围：用户提供的 Windows 汉化运行包，与 GitHub V1.4.5 标签源码的对比。

## 结论

本次检查发现：两份程序虽然都标注为 1.4.5，但 Drag Snap 状态切换处理和拖拽平滑算法不同。此前保护版使用 GitHub 标签源码，因此同一工程、同一数值在用户原有汉化版与保护版之间可能表现不同。问题不只是参数显示或传递错误。

已将保护版制作端及播放端的五个相关运动脚本对齐到用户提供的运行包。此结论仅针对下面标识的样本；现有证据不能确定差异由谁、何时引入，也不能说明所有汉化版都有此差异。

## 对比样本

- GitHub 仓库：<https://github.com/MudkipWorld/PNGTuber-Remix/tree/V1.4.5>
- 标签：`V1.4.5`；提交：`6b093894e33d804368367a0e98e1dc3722e4909b`。
- 本地样本：用户提供的 Windows 汉化版 `PNGTube Remix.pck`。
- 运行包 SHA256：`350E2FB208D2D297E1A52C632F1853EE264EB3C4F6691E5176ED151E96594781`。
- 对比方法：恢复本地运行包的 GDScript，逐项对比源码，并检查修复后编译脚本的 MD5。没有修改原安装包或用户工程。

## 差异一 触发吸附后没有同步重置拖拽跟随点

当切换状态产生的位置变化大于 `drag_snap`，且阈值不是 `999999.0` 时，GitHub 标签源码只重置 `Modifier` 的全局位置。用户运行包还会同步重置 `Dragger`：

```gdscript
%Modifier.global_position = %Modifier1.global_position
%Dragger.global_position = %Modifier.global_position
```

第二行是关键差异。缺少它时，画面位置虽然进行了吸附，拖拽跟随点仍保留先前位置，后续运动计算可能继续产生拖拽残留。阈值判定使用严格大于；`999999.0` 是这段逻辑中不触发吸附的特殊值。

涉及四个脚本：

- `Scripts/Objects/sprite_object.gd`
- `Scripts/Objects/append_object.gd`
- `Scripts/Objects/comment_object.gd`
- `Scripts/Misc/mesh_object.gd`

## 差异二 拖拽平滑计算不同

涉及 `Scripts/Objects/ObjectComponents/movements.gd` 的 `drag()`。两边都会按 `1.0 / dragSpeed` 更新跟随点，但后续计算不同。

GitHub 标签源码维护一个跨帧保留的 `shadow_drag`：

```gdscript
shadow_drag = shadow_drag.lerp(dragger.global_position - target, 0.85)
applied_pos += shadow_drag
```

用户运行包将跟随点转换到角色局部坐标，再进行插值：

```gdscript
applied_pos = applied_pos.lerp(actor.to_local(dragger.global_position), 0.5)
```

这是算法差异，不是两个系数之间可以直接换算的数值差异。相同 Drag Snap 和 Drag 参数不保证两套算法产生相同轨迹。本次修复使用用户运行包的局部坐标算法，并移除不再使用的 `shadow_drag` 状态。

## 验证结果

- 两个安装目录的物理更新率均为 60，最大物理步数均为 10，抖动补偿均为 0.5；这些设置不能解释本次差异。
- 修复前，吸附跟随点重置和拖拽参考输出的回归测试失败；修复后通过。临界阈值及 `999999.0` 的不吸附行为也通过测试。
- 使用用户当前工程的两个状态，固定 60 Hz 输入运行 240 帧，每 40 帧切换状态。15,840 行记录包含 Modifier 坐标、Dragger 坐标和 drag_snap；修复版与恢复出的本地运行包运动脚本之间，最大数值差为 0。
- 修复后五个运动脚本的编译 GDC 内容 MD5 与用户运行包逐项一致。这里只比较相关脚本，不意味着两个完整程序相同。
- 保护格式回归测试通过；保护文件导出前后的示例运动对比为 11,700 个采样，最大差值为 0。

## 使用与验证边界

制作端和播放端均应使用包含 Drag Snap 修复的版本。保护格式和密钥未改变，原保护文件不需要因本次运动修复而重新导出。

以上是源码、编译内容和固定输入的数值验证，不代表所有模型、实际麦克风、OBS 捕获、不同帧率与设备环境均已完整验收。鼠标快捷键的个人设置覆盖问题属于另一条输入处理链路，不是本说明中的运动算法差异。
