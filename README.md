# FPGA Project Template

一个面向 **Verilog / SystemVerilog FPGA 开发** 的通用工程模板。

当前模板以 **VS Code + Verilog-HDL/SystemVerilog + Verible + ModelSim SE-64 + Vivado** 为核心工具链，目标是把源码、仿真、综合、实现和工具生成文件明确分离，并尽量通过通用脚本完成重复工作。

> 当前版本重点覆盖：
>
> - HDL 编写与格式化 / 静态检查
> - ModelSim 自动编译、仿真与 WLF 波形记录
> - Vivado Non-Project Mode 综合
> - Vivado `opt_design -> place_design -> route_design` 实现流程
> - 统一把工具生成物放入 `build/`
>
> 当前版本**尚未把真实板卡 Bitstream / JTAG 下载做成通用自动化流程**。在真正上板前，需要先加入与你的开发板完全匹配的 XDC 约束。

---

## 1. 核心工具链

本模板的核心开发链如下：

```text
VS Code
  |
  +-- Verilog-HDL/SystemVerilog
  |     HDL 语法高亮、代码编辑辅助
  |
  +-- Verible
  |     格式化、Lint、Language Server
  |
  +-- ModelSim SE-64
  |     RTL / Testbench 功能仿真、WLF 波形调试
  |
  +-- Vivado
        综合、实现、时序/资源/DRC 报告
```

可以简单记成：

```text
VS Code 写
Verible 查
ModelSim 仿
Vivado 做
```

### 1.1 VS Code

VS Code 是主要编辑器和工程入口，用来编辑：

- `.v` / `.vh`
- `.sv` / `.svh`
- `.xdc`
- `.tcl`
- `.do`
- `.f`
- Markdown 文档

建议从**工程根目录**打开整个项目，而不是只打开某个子目录。

### 1.2 Verilog-HDL/SystemVerilog 扩展

提供 Verilog / SystemVerilog 的基础编辑体验，例如：

- 语法高亮
- 文件类型识别
- 基础语言支持

### 1.3 Verible

Verible 作为 VS Code 的 HDL 辅助工具，负责：

- `verible-verilog-format`：代码格式化
- `verible-verilog-lint`：静态规则检查
- `verible-verilog-ls`：Language Server

Verible **不是仿真器，也不是综合器**。

### 1.4 ModelSim SE-64

ModelSim 负责功能仿真：

```text
RTL + Testbench
      |
      v
    vlog
      |
      v
    vsim
      |
      +--> WLF 波形数据库
      +--> transcript 日志
```

当前脚本已经支持：

- `.v`
- `.sv`
- `.vh`
- `.svh`
- `+incdir+...`
- 通用 Testbench 顶层选择

### 1.5 Vivado

Vivado 当前采用 **Non-Project Mode**，不依赖固定 `.xpr` 工程。

当前流程：

```text
RTL + XDC
   |
   v
synth_design
   |
   v
*_synth.dcp
   |
   v
opt_design
   |
   v
place_design
   |
   v
route_design
   |
   v
*_route.dcp + reports
```

这种方式更适合把工程作为 Git 模板管理，因为源码和构建产物之间的边界比较清楚。

---

## 2. 已验证环境

当前模板是在以下环境中逐步验证的：

```text
Windows
ModelSim SE-64 10.6e
Vivado 2023.2
Git
VS Code
Verible
```

其他版本通常也可以使用，但如果工具命令参数或 Tcl 行为有变化，需要自行调整脚本。

---

## 3. 工程目录结构

推荐结构：

```text
FPGA-project-template/
|
+-- rtl/
|   +-- example.sv
|   +-- filelist.f
|
+-- tb/
|   +-- example_tb.sv
|
+-- include/
|   +-- ... .vh / .svh
|
+-- constr/
|   +-- filelist.f
|   +-- ... .xdc
|
+-- sim/
|   +-- filelist.f
|   +-- modelsim/
|       +-- run.do
|       +-- wave.do
|
+-- scripts/
|   +-- vivado_synth.tcl
|   +-- vivado_impl.tcl
|
+-- ip/
|   +-- ...
|
+-- docs/
|   +-- ...
|
+-- build/
|   +-- modelsim/
|   +-- vivado/
|
+-- .vscode/
|   +-- settings.json
|
+-- .rules.verible_lint
+-- .editorconfig
+-- .gitattributes
+-- .gitignore
+-- LICENSE
+-- README.md
```

其中：

```text
源码 / 配置 / 脚本 -> Git 管理
build/             -> 工具生成物，通常不提交 Git
```

---

## 4. 每个目录的用途

### `rtl/`

存放**可综合 RTL 源码**。

例如：

```text
rtl/top.sv
rtl/uart_tx.v
rtl/fifo.sv
rtl/common_pkg.sv
```

不要把 Testbench 放入这里。

### `tb/`

存放 Testbench，仅用于仿真，不参与正常硬件综合。

例如：

```text
tb/top_tb.sv
```

### `include/`

存放 HDL 头文件，例如：

```text
include/defines.vh
include/parameters.svh
```

源码通常通过：

```systemverilog
`include "parameters.svh"
```

使用这些文件。

### `constr/`

存放 Vivado XDC 约束，例如：

```text
constr/pins.xdc
constr/clock.xdc
constr/timing.xdc
```

它决定真实硬件中的：

- FPGA 管脚
- I/O 电气标准
- 时钟约束
- 其他时序约束

**更换开发板时，这通常是必须重点修改的目录。**

### `sim/`

存放仿真相关配置。

当前主要有：

```text
sim/filelist.f
sim/modelsim/run.do
sim/modelsim/wave.do
```

> 当前版本**不使用 `sim/config.tcl`**。
>
> 如果看到旧文档或旧分支中存在 `config.tcl`，请不要照搬到当前流程。

### `scripts/`

存放 Vivado Tcl 自动化脚本。

目前：

```text
vivado_synth.tcl
vivado_impl.tcl
```

### `ip/`

预留给项目使用的 IP、IP 配置或与 IP 相关的版本控制文件。

不同 IP 的最佳管理方式可能不同，尤其是 Vivado 自动生成的大量缓存文件不应全部提交。

### `docs/`

存放设计文档，例如：

- 系统框图
- 状态机图
- WaveDrom 时序图
- 接口说明
- 设计笔记

### `build/`

所有主要构建产物统一放到这里。

典型内容：

```text
build/
+-- modelsim/
|   +-- work/
|   +-- simulation.wlf
|   +-- transcript
|   +-- transcript_view
|   +-- modelsim.ini
|
+-- vivado/
    +-- logs/
    |   +-- vivado_synth.log
    |   +-- vivado_synth.jou
    |   +-- vivado_impl.log
    |   +-- vivado_impl.jou
    |
    +-- synth/
    |   +-- <top>_synth.dcp
    |   +-- utilization_synth.rpt
    |   +-- timing_synth.rpt
    |
    +-- impl/
        +-- <top>_opt.dcp
        +-- <top>_place.dcp
        +-- <top>_route.dcp
        +-- utilization_route.rpt
        +-- timing_route.rpt
        +-- drc_route.rpt
```

`build/` 可以删除后重新生成，不应作为项目源码来源。

---

## 5. 配置文件与脚本说明

## 5.1 `.vscode/settings.json`

用于项目级 VS Code 配置。

典型职责：

- `.v` / `.vh` 识别为 Verilog
- `.sv` / `.svh` 识别为 SystemVerilog
- 设置 4 空格缩进
- 设置 Verible 为 Verilog / SystemVerilog 默认格式化器

当前 Verible 扩展 ID 使用：

```json
"chipsalliance.verible"
```

如果换电脑后 VS Code 提示找不到 formatter，请先确认对应扩展已安装。

---

## 5.2 `.rules.verible_lint`

Verible Lint 的项目级规则配置。

例如可以用于限制行长度、启用或关闭某些 HDL 风格规则。

这是**代码规范配置**，不会影响 ModelSim 仿真或 Vivado 综合结果。

---

## 5.3 `.editorconfig`

用于统一不同编辑器中的基本文本格式，例如：

- 缩进方式
- 缩进宽度
- 行尾
- 文件末尾换行

这样同一仓库在不同电脑或编辑器中更不容易出现无意义格式差异。

---

## 5.4 `.gitattributes`

用于控制 Git 对文件的处理方式，例如文本文件行尾规范。

Windows / Linux 混合开发时尤其有用。

---

## 5.5 `.gitignore`

用于阻止工具生成物进入 Git。

应该至少忽略：

```text
build/
transcript
vivado*.log
vivado*.jou
```

如果某个工具产生新的缓存目录，也应根据实际情况补充到 `.gitignore`。

---

## 5.6 `rtl/filelist.f`

这是 **Vivado 综合源文件列表**。

示例：

```text
+incdir+include

rtl/common_pkg.sv
rtl/uart_tx.v
rtl/top.sv
```

作用：

- 指定哪些 RTL 参与综合
- 指定 HDL 读取顺序
- 指定 include 搜索路径

### 编译顺序非常重要

如果存在 package / 依赖关系，应把被依赖文件放前面：

```text
rtl/common_pkg.sv
rtl/module_using_pkg.sv
rtl/top.sv
```

Testbench 不应放入 `rtl/filelist.f`。

---

## 5.7 `sim/filelist.f`

这是 **ModelSim 仿真文件列表**。

当前 `run.do` 直接读取这个文件，**不再读取 `sim/config.tcl`**。

推荐格式：

```text
+incdir+include

rtl/example.sv

tb/example_tb.sv
```

支持：

```text
+incdir+<目录>
+top+<仿真顶层 module>
.v
.sv
.vh
.svh
```

### 仿真顶层选择规则

当前 `run.do` 的 `TOP_MODULE` 优先级是：

```text
1. sim/filelist.f 中显式写出的 +top+<module>
2. 否则自动使用 filelist.f 中最后一个 .v/.sv 文件的文件名
```

例如：

```text
rtl/example.sv
tb/example_tb.sv
```

最后一个 HDL 文件是：

```text
tb/example_tb.sv
```

因此自动推导：

```text
TOP_MODULE = example_tb
```

这要求文件名和 module 名一致：

```systemverilog
module example_tb;
```

如果文件名和 module 名不一致，例如：

```text
tb/test.sv
```

内部却是：

```systemverilog
module uart_tb;
```

请显式写：

```text
+top+uart_tb

+incdir+include
rtl/uart.sv
tb/test.sv
```

因此新项目一般**不需要修改 `run.do`**，只需要正确维护 `sim/filelist.f`。

---

## 5.8 `sim/modelsim/run.do`

这是 ModelSim 的通用自动仿真脚本。

当前版本负责：

```text
检查工程根目录
   |
创建 build/modelsim
   |
重建 work 库
   |
读取 sim/filelist.f
   |
解析 +top+ / +incdir+
   |
.v  -> Verilog 编译
.sv -> SystemVerilog 编译
   |
自动确定 Testbench 顶层
   |
vsim -voptargs=+acc
   |
记录 /<TOP_MODULE>/*
   |
run -all
   |
生成 simulation.wlf
```

### 当前版本的重要约定

```text
不依赖 sim/config.tcl
```

所有项目级仿真配置尽量通过：

```text
sim/filelist.f
```

完成。

### 为什么使用 `-voptargs=+acc`

这是为了保留调试时需要的信号访问能力，便于 `log` 和 Wave 窗口查看信号。

### 为什么不是 `log -r /*`

当前脚本针对 ModelSim SE-64 10.6e 使用：

```tcl
set TOP_SCOPE "/$TOP_MODULE"
log -r "$TOP_SCOPE/*"
```

这种方式在当前环境中比直接 `log -r /*` 更稳定。

---

## 5.9 `sim/modelsim/wave.do`

这是通用波形显示脚本。

它不依赖：

- Testbench 名称
- DUT 名称
- 具体信号名称
- `sim/config.tcl`

打开：

```text
build/modelsim/simulation.wlf
```

后，脚本执行：

```tcl
add wave -r simulation:/*
```

把 `simulation` dataset 中已经记录的信号递归加入 Wave 窗口。

当前 `run.do` 固定生成：

```text
simulation.wlf
```

所以 `wave.do` 默认使用 dataset：

```text
simulation
```

如果未来修改 WLF 文件名，需要同步确认 dataset 名称与 `wave.do` 是否仍一致。

---

## 5.10 `constr/filelist.f`

Vivado XDC 约束文件列表。

例如：

```text
constr/pins.xdc
constr/clock.xdc
constr/timing.xdc
```

`vivado_synth.tcl` 会按顺序读取这些文件。

如果当前只是验证 RTL 综合流程，也可以暂时保持为空；但在真实板卡生成 Bitstream 之前，必须提供正确约束。

---

## 5.11 `scripts/vivado_synth.tcl`

Vivado 通用综合脚本。

主要流程：

```text
读取 rtl/filelist.f
读取 constr/filelist.f
读取 .v / .sv
设置 include 路径
synth_design
write_checkpoint
report_utilization
report_timing_summary
```

运行时通过命令行传入：

```text
RTL 顶层 module
FPGA Part
```

因此通常不需要为了换项目而改 Tcl 主体。

---

## 5.12 `scripts/vivado_impl.tcl`

Vivado Implementation 脚本。

输入：

```text
build/vivado/synth/<TOP_MODULE>_synth.dcp
```

执行：

```text
opt_design
place_design
route_design
```

并生成：

```text
<top>_opt.dcp
<top>_place.dcp
<top>_route.dcp
utilization_route.rpt
timing_route.rpt
drc_route.rpt
```

Implementation 使用综合 DCP 中已经保存的器件信息，因此当前命令只需要再次传入顶层名称，用于定位正确 DCP 文件。

---

## 6. 下载与首次使用

推荐把 GitHub 仓库设置为 **Template Repository**。

### 方法 A：GitHub `Use this template`

推荐方式：

```text
模板仓库
   |
Use this template
   |
创建自己的新仓库
   |
git clone 新仓库
```

这样新项目不会继承模板仓库自己的 Git 历史关系。

### 方法 B：直接 Clone

```powershell
git clone <repository-url> my-fpga-project
cd my-fpga-project
```

如果这是准备独立发展的项目，需要根据自己的 Git 使用方式处理远程仓库。

---

## 7. 新电脑环境准备

所有核心工具建议加入 Windows `PATH`。

安装完成后在 VS Code PowerShell 中验证。

### Git

```powershell
git --version
```

### ModelSim

```powershell
vsim -version
vlog -version
where.exe vsim
where.exe vlog
```

### Verible

```powershell
verible-verilog-format --version
verible-verilog-lint --version
verible-verilog-ls --version
```

### Vivado

```powershell
vivado -version
where.exe vivado
```

如果某个命令提示：

```text
The term 'xxx' is not recognized...
```

通常说明对应工具的可执行目录没有加入 PATH，或 VS Code 在修改 PATH 前已经启动，需要完全关闭后重新打开。

---

## 8. ModelSim 使用方法

下面命令均建议从**工程根目录**执行。

### 8.1 第一次创建输出目录

因为 transcript 文件在 `run.do` 执行前就会被 ModelSim 打开，所以首次运行前先确保目录存在：

```powershell
New-Item -ItemType Directory -Force build\modelsim | Out-Null
```

### 8.2 运行仿真

```powershell
vsim -c -l build\modelsim\transcript -do sim\modelsim\run.do
```

成功后主要得到：

```text
build/modelsim/work/
build/modelsim/simulation.wlf
build/modelsim/transcript
```

### 8.3 查看 WLF

```powershell
vsim -l build\modelsim\transcript_view -view build\modelsim\simulation.wlf
```

进入 ModelSim GUI 后，在 Transcript 执行：

```tcl
do sim/modelsim/wave.do
```

即可自动把已记录信号加入 Wave 窗口。

### 8.4 `log` 与 `add wave` 的区别

```text
run.do 中的 log
    -> 决定哪些信号被写进 WLF

wave.do 中的 add wave
    -> 决定 GUI 当前显示哪些已记录信号
```

因此：

> WLF 中没有被记录的信号，之后仅靠 `add wave` 无法恢复。

---

## 9. Vivado 综合使用方法

### 9.1 创建日志目录

Vivado 的 `-log` / `-journal` 在 Tcl 脚本执行前就需要打开文件，因此先保证目录存在：

```powershell
New-Item -ItemType Directory -Force build\vivado\logs | Out-Null
```

### 9.2 运行 Synthesis

通用格式：

```powershell
vivado -mode batch -log build\vivado\logs\vivado_synth.log -journal build\vivado\logs\vivado_synth.jou -source scripts\vivado_synth.tcl -tclargs <TOP_MODULE> <FPGA_PART>
```

例如当前 Zynq-7020 示例：

```powershell
vivado -mode batch -log build\vivado\logs\vivado_synth.log -journal build\vivado\logs\vivado_synth.jou -source scripts\vivado_synth.tcl -tclargs example xc7z020clg400-2
```

成功后得到类似：

```text
build/vivado/synth/example_synth.dcp
build/vivado/synth/utilization_synth.rpt
build/vivado/synth/timing_synth.rpt
```

---

## 10. Vivado Implementation 使用方法

必须先成功完成 Synthesis。

通用格式：

```powershell
vivado -mode batch -log build\vivado\logs\vivado_impl.log -journal build\vivado\logs\vivado_impl.jou -source scripts\vivado_impl.tcl -tclargs <TOP_MODULE>
```

当前示例：

```powershell
vivado -mode batch -log build\vivado\logs\vivado_impl.log -journal build\vivado\logs\vivado_impl.jou -source scripts\vivado_impl.tcl -tclargs example
```

输出：

```text
build/vivado/impl/example_opt.dcp
build/vivado/impl/example_place.dcp
build/vivado/impl/example_route.dcp
build/vivado/impl/utilization_route.rpt
build/vivado/impl/timing_route.rpt
build/vivado/impl/drc_route.rpt
```

---

## 11. 下载模板后，如何改成自己的项目

这是使用本模板最重要的一部分。

一般**不需要修改通用 Tcl / DO 脚本本身**，优先修改文件列表、顶层参数和 XDC。

### 11.1 替换 RTL

把你的可综合 RTL 放到：

```text
rtl/
```

然后修改：

```text
rtl/filelist.f
```

例如：

```text
+incdir+include

rtl/common_pkg.sv
rtl/clk_div.v
rtl/uart_tx.v
rtl/top.sv
```

如果删除了 `example.sv`，务必把 `rtl/filelist.f` 中的旧条目也删除。

---

### 11.2 替换 Testbench

把 Testbench 放到：

```text
tb/
```

然后修改：

```text
sim/filelist.f
```

例如：

```text
+incdir+include

rtl/common_pkg.sv
rtl/uart_tx.v
rtl/top.sv

tb/top_tb.sv
```

推荐把 Testbench 顶层 HDL 文件放在 `sim/filelist.f` 最后。

如果：

```text
文件名 = top_tb.sv
module = top_tb
```

则无需 `+top+`。

如果不同：

```text
文件名 = test.sv
module = top_tb
```

应写：

```text
+top+top_tb
```

---

### 11.3 修改 include 路径

如果头文件都在默认：

```text
include/
```

继续使用：

```text
+incdir+include
```

如果项目存在多个头文件目录，可以写多行：

```text
+incdir+include
+incdir+rtl/include
+incdir+ip/include
```

ModelSim 和 Vivado 的相应 filelist 都要根据实际需要配置。

---

### 11.4 修改 Vivado RTL 顶层

Vivado 顶层不是从 `sim/filelist.f` 推导的。

综合时直接通过命令传入：

```text
-tclargs <TOP_MODULE> <FPGA_PART>
```

例如 RTL：

```systemverilog
module uart_top (...);
```

则：

```powershell
vivado ... -tclargs uart_top <FPGA_PART>
```

Implementation 同样使用：

```powershell
vivado ... -tclargs uart_top
```

顶层名必须与综合生成的 DCP 名对应。

---

### 11.5 更换 FPGA / 开发板

更换开发板时至少检查两个完全不同的概念：

```text
FPGA Part
XDC 板级约束
```

#### FPGA Part

例如当前示例：

```text
xc7z020clg400-2
```

换板后不能继续照抄。

必须查询板上 FPGA 芯片的：

- 器件系列
- 型号
- 封装
- speed grade

然后在综合命令中改成新的 Vivado Part：

```powershell
-tclargs <TOP_MODULE> <NEW_FPGA_PART>
```

例如：

```powershell
vivado ... -tclargs top xc7a35tcsg324-1
```

这里只是示例，实际 Part 必须以你的硬件为准。

#### XDC

**不同开发板绝对不能随意共用管脚约束。**

需要根据开发板原理图 / 官方 Master XDC / 用户手册建立对应约束：

```text
constr/pins.xdc
constr/clock.xdc
```

再加入：

```text
constr/filelist.f
```

例如：

```text
constr/pins.xdc
constr/clock.xdc
```

典型 XDC 会涉及：

```tcl
set_property PACKAGE_PIN ... [get_ports ...]
set_property IOSTANDARD ... [get_ports ...]
create_clock ...
```

引脚、IOSTANDARD 和时钟周期必须与真实硬件一致。

---

### 11.6 修改约束后必须重新综合

当前流程中 XDC 在 `vivado_synth.tcl` 阶段读入，因此修改 XDC 后应重新运行：

```text
Synthesis
   -> Implementation
```

不要继续复用旧的 `<top>_synth.dcp`。

---

### 11.7 更改 WLF 文件名

正常情况下不需要修改：

```text
build/modelsim/simulation.wlf
```

如果你在 `run.do` 中改了：

```tcl
set WLF_FILE ...
```

则需要同步检查：

```text
wave.do
ModelSim 打开 WLF 的命令
```

因为 `wave.do` 当前使用：

```tcl
simulation:/*
```

---

## 12. 新项目适配速查表

| 变化 | 通常需要修改 |
|---|---|
| 新增/删除 RTL | `rtl/`、`rtl/filelist.f`、`sim/filelist.f` |
| 新 Testbench | `tb/`、`sim/filelist.f` |
| Testbench 文件名与 module 名不同 | `sim/filelist.f` 增加 `+top+<module>` |
| 新头文件目录 | `+incdir+...` |
| 更换 RTL 顶层 | Vivado 命令中的 `<TOP_MODULE>` |
| 更换 FPGA 芯片 | Vivado 命令中的 `<FPGA_PART>` |
| 更换开发板 | FPGA Part + `constr/*.xdc` + `constr/filelist.f` |
| 新增管脚/接口 | XDC + RTL 顶层端口 |
| 修改时钟 | XDC 中的时钟约束 |
| 修改 ModelSim 波形数据库名 | `run.do` + `wave.do` + 查看命令 |
| 修改代码风格 | `.rules.verible_lint` / `.editorconfig` |
| 工具产生新的缓存文件 | `.gitignore` |

**当前流程不需要 `sim/config.tcl`。**

---

## 13. 推荐开发流程

对于一般 RTL 项目：

```text
1. 在 rtl/ 写设计
        |
2. Verible Format / Lint
        |
3. 在 tb/ 写 Testbench
        |
4. 更新 sim/filelist.f
        |
5. ModelSim 仿真
        |
6. 查看 WLF / wave.do
        |
7. 更新 rtl/filelist.f
        |
8. 准备 XDC
        |
9. Vivado Synthesis
        |
10. Vivado Implementation
        |
11. 查看 timing / utilization / DRC
        |
12. 后续再生成 Bitstream / 上板
```

不要把“仿真通过”理解成“可以直接上板”。

真实硬件还必须满足：

- 正确 FPGA Part
- 正确管脚
- 正确 IOSTANDARD
- 正确时钟约束
- Implementation / DRC / Timing 满足要求

---

## 14. 当前示例工程

模板中的 `example.sv` / `example_tb.sv` 主要用于验证开发链是否工作。

它们的目的不是代表真实工程，而是测试：

```text
VS Code
-> Verible
-> ModelSim
-> WLF
-> Vivado Synthesis
-> Vivado Implementation
```

下载模板后可以在确认工具链正常后删除示例文件，并换成自己的 RTL / Testbench。

---

## 15. 关于当前 Zynq-7020 示例

当前测试命令中使用：

```text
xc7z020clg400-2
```

这是当前测试环境中的目标器件示例。

**不要因为模板里出现这个字符串，就默认你的开发板也是这个 Part。**

换板时必须重新确认完整器件型号。

---

## 16. 当前尚未自动化的部分

目前模板已经完成：

```text
HDL 编辑
Verible
ModelSim 仿真
WLF 波形
Vivado Synthesis
opt_design
place_design
route_design
```

暂未作为通用模板固定下来的部分：

```text
真实开发板完整 XDC
write_bitstream
Hardware Manager / JTAG 自动下载
Zynq PS / Block Design 的通用管理
```

建议先熟悉实际板卡的 Vivado / XDC / Bitstream / JTAG 基础流程后，再继续增加这些自动化功能。

---

## 17. Git 建议

一个功能完成后及时提交：

```powershell
git status
git add .
git commit -m "Describe the change"
git push
```

不要提交：

```text
build/
ModelSim work 库
WLF
transcript
Vivado log/journal
Vivado 临时缓存
```

应该提交：

```text
RTL
Testbench
filelist
XDC
DO/Tcl 脚本
VS Code 配置
Verible 配置
README
```

---

## 18. 常见问题

### ModelSim 找不到工程文件

确认当前 PowerShell 位于工程根目录：

```powershell
pwd
```

然后再运行：

```powershell
vsim -c -l build\modelsim\transcript -do sim\modelsim\run.do
```

### ModelSim 找不到顶层

检查：

```text
sim/filelist.f
```

如果最后一个 `.v/.sv` 文件名不能代表顶层 module，请使用：

```text
+top+your_testbench
```

### 打开 WLF 后 Wave 窗口为空

打开 WLF 只表示打开波形数据库，不等于自动显示信号。

执行：

```tcl
do sim/modelsim/wave.do
```

### Vivado 提示没有 Timing Constraint

如果 `constr/filelist.f` 没有加载实际时钟 XDC，这是正常现象。

在真实硬件项目中需要补充正确时钟约束。

### 根目录出现 `transcript`

使用：

```powershell
-l build\modelsim\transcript
```

并确保 `build/modelsim` 在启动 ModelSim 前存在。

### 根目录出现 `vivado.log` / `vivado.jou`

启动 Vivado 时使用：

```text
-log build\vivado\logs\...
-journal build\vivado\logs\...
```

并确保 `build/vivado/logs` 已提前创建。

---

## 19. 设计原则

这个模板的核心原则不是“把所有 FPGA 工具都塞进工程”，而是：

```text
源码清楚
配置集中
文件顺序明确
板卡约束明确
仿真与综合分离
生成物全部进入 build
尽量不把项目名/板卡名写死在通用脚本中
```

因此，创建新项目时优先修改：

```text
rtl/filelist.f
sim/filelist.f
constr/filelist.f
Vivado 命令中的 TOP_MODULE / FPGA_PART
```

而不是复制一份脚本后到处修改脚本内部常量。

---

## License

见 `LICENSE`。
