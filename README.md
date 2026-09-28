# FPGA Project Template

A vendor-independent FPGA/RTL project template.

## Directory Structure

```text
.
├── rtl/         # Synthesizable RTL source files 同步RTL源文件
├── tb/          # Testbench files 测试文件
├── include/     # Verilog/SystemVerilog headers Verilog/systemverilog头文件
├── constr/      # FPGA constraint files FPGA约束文件
├── sim/         # Simulation configuration and scripts 模拟仿真和脚本
├── scripts/     # Build, synthesis and utility scripts 脚本文件
├── ip/          # IP configuration files IP配置文件
├── docs/        # Documentation 文档
└── build/       # Generated build files (ignored by Git) 构建文件，生成的垃圾文件