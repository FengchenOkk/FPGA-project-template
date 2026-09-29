# ============================================================
# ModelSim 自动仿真脚本
#
# 文件位置：
#
#   sim/modelsim/run.do
#
# 使用方法：
#
#   必须先进入 FPGA 工程根目录，例如：
#
#   E:/FPGAprogram/FPGA-project-template
#
#   然后执行：
#
#   vsim -c -l build/modelsim/transcript -do sim/modelsim/run.do
#
# 如需显式指定仿真顶层，可在执行前设置环境变量：
#
#   $env:TOP_MODULE = "my_tb"
#
# 未显式指定时，脚本使用 filelist.f 中最后一个 .v/.sv 文件的
# 文件名（不含扩展名）作为仿真顶层。因此建议将 Testbench 放在
# filelist.f 的最后，并让文件名与顶层 module 名称一致。
#
#
# 本脚本完成以下工作：
#
#   1. 获取 FPGA 工程根目录
#   2. 检查 sim/filelist.f 是否存在
#   3. 创建 build/modelsim 构建目录
#   4. 创建干净的 ModelSim work 库
#   5. 读取 sim/filelist.f
#   6. 读取 +incdir+ 头文件搜索目录
#   7. .v  文件按照 Verilog 编译
#   8. .sv 文件按照 SystemVerilog 编译
#   9. 加载 Testbench 顶层
#  10. 记录仿真波形
#  11. 一直运行到 Testbench 执行 $finish
#  12. 将波形保存为 simulation.wlf
#
#
# 所有 ModelSim 生成文件统一放入：
#
#   build/modelsim/
#
# 从而避免污染：
#
#   rtl/
#   tb/
#   include/
#   sim/
#
# 等源码目录。
# ============================================================



# ============================================================
# 1. 获取 FPGA 工程根目录
# ============================================================

# pwd：
#   返回 ModelSim 当前的工作目录。
#
# 本脚本规定：
#
#   ModelSim 必须从 FPGA 工程根目录启动。
#
# 例如 PowerShell 当前位于：
#
#   E:/FPGAprogram/FPGA-project-template
#
# 然后执行：
#
#   vsim -c -do sim/modelsim/run.do
#
# 那么：
#
#   [pwd]
#
# 就应该得到：
#
#   E:/FPGAprogram/FPGA-project-template
#
#
# file normalize：
#   将路径转换成规范的绝对路径。
#

set PROJECT_ROOT [file normalize [pwd]]



# ============================================================
# 2. 设置工程中的主要路径
# ============================================================

# ModelSim 所有生成文件存放目录：
#
#   build/modelsim/
#

set BUILD_DIR [file join $PROJECT_ROOT build modelsim]


# ModelSim 编译库实际存放位置：
#
#   build/modelsim/work/
#

set WORK_DIR [file join $BUILD_DIR work]


# ModelSim 波形数据库：
#
#   build/modelsim/simulation.wlf
#

set WLF_FILE [file join $BUILD_DIR simulation.wlf]


# 仿真源文件列表：
#
#   sim/filelist.f
#

set FILELIST [file join $PROJECT_ROOT sim filelist.f]



# ============================================================
# 3. 初始化通用仿真顶层选择
# ============================================================

# 顶层模块按以下优先级确定：
#
#   1. 执行 run.do 前已设置的 Tcl 变量 TOP_MODULE
#   2. 环境变量 TOP_MODULE
#   3. filelist.f 中最后一个 .v/.sv 文件的文件名
#
# 第 3 种方式要求 Testbench 文件名与其顶层 module 名称一致。

if {[info exists TOP_MODULE]} {
    set TOP_MODULE [string trim $TOP_MODULE]
} else {
    set TOP_MODULE ""
}

if {$TOP_MODULE eq "" && [info exists ::env(TOP_MODULE)]} {
    set TOP_MODULE [string trim $::env(TOP_MODULE)]
}

# 读取 filelist.f 时持续更新；最后保留最后一个 .v/.sv 文件名。
set AUTO_TOP_MODULE ""



# ============================================================
# 4. 初始化 include 搜索目录列表
# ============================================================

# filelist.f 中可能存在：
#
#   +incdir+include
#
# INCLUDE_DIRS 用来保存所有找到的 include 搜索目录。
#

set INCLUDE_DIRS {}



# ============================================================
# 5. 检查当前目录是否为正确的 FPGA 工程根目录
# ============================================================

# 我们使用：
#
#   sim/filelist.f
#
# 作为判断工程根目录是否正确的重要依据。
#
# 如果找不到这个文件，
# 通常说明没有从 FPGA 工程根目录启动 ModelSim。
#

if {![file exists $FILELIST]} {

    puts ""
    puts "============================================================"
    puts "错误：当前目录似乎不是正确的 FPGA 工程根目录。"
    puts ""
    puts "当前目录："
    puts "  $PROJECT_ROOT"
    puts ""
    puts "没有找到："
    puts "  $FILELIST"
    puts ""
    puts "请先进入 FPGA 工程根目录，例如："
    puts ""
    puts "  cd E:/FPGAprogram/FPGA-project-template"
    puts ""
    puts "然后执行："
    puts ""
    puts "  vsim -c -l build/modelsim/transcript -do sim/modelsim/run.do"
    puts "============================================================"
    puts ""

    quit -code 1 -f
}



# ============================================================
# 6. 定义路径转换函数
# ============================================================

# filelist.f 中推荐使用相对路径：
#
#   rtl/example.v
#   rtl/example.sv
#   tb/example_tb.sv
#
# 而不要使用：
#
#   E:/FPGAprogram/...
#
# 这样整个工程移动到其他硬盘或电脑后，
# filelist.f 仍然可以继续使用。
#
#
# resolve_path 的作用：
#
#   rtl/example.sv
#
#             ↓
#
#   E:/FPGAprogram/FPGA-project-template/rtl/example.sv
#

proc resolve_path {root path} {

    # 如果传入的已经是绝对路径，
    # 直接规范化后返回。

    if {[file pathtype $path] eq "absolute"} {
        return [file normalize $path]
    }


    # 如果是相对路径，
    # 则将其拼接到 FPGA 工程根目录。

    return [file normalize [file join $root $path]]
}



# ============================================================
# 7. 显示当前仿真配置
# ============================================================

puts ""
puts "============================================================"
puts " ModelSim FPGA 仿真"
puts "============================================================"

puts "工程根目录："
puts "  $PROJECT_ROOT"

puts ""

puts "构建目录："
puts "  $BUILD_DIR"

puts ""

puts "源文件列表："
puts "  $FILELIST"

puts "============================================================"
puts ""



# ============================================================
# 8. 创建 ModelSim 构建目录
# ============================================================

# 创建：
#
#   build/modelsim/
#
# 如果目录已经存在，
# file mkdir 不会因此报错。
#

file mkdir $BUILD_DIR



# ============================================================
# 9. 切换 ModelSim 工作目录
# ============================================================

# ModelSim 运行过程中可能产生：
#
#   modelsim.ini
#   transcript
#   simulation.wlf
#   work/
#
# 等文件。
#
# 因此将当前工作目录切换到：
#
#   build/modelsim/
#
# 避免这些生成文件污染工程根目录。
#

cd $BUILD_DIR



# ============================================================
# 10. 创建干净的 ModelSim work 库
# ============================================================

# ModelSim 不能直接执行 .v/.sv 源文件。
#
# HDL 文件需要先经过 vlog 编译，
# 再保存到 ModelSim 的逻辑库中。
#
# 最常用的默认逻辑库名称为：
#
#   work
#
#
# 为了避免上一次的编译结果影响本次仿真，
# 每次运行时先删除旧 work 库。
#

if {[file exists $WORK_DIR]} {

    puts "删除旧的 ModelSim work 库："
    puts "  $WORK_DIR"
    puts ""

    file delete -force $WORK_DIR
}


# 创建新的物理库目录。

vlib $WORK_DIR


# 将 ModelSim 的逻辑库：
#
#   work
#
# 映射到：
#
#   build/modelsim/work
#

vmap work $WORK_DIR



# ============================================================
# 11. 开始读取 sim/filelist.f
# ============================================================

puts ""
puts "============================================================"
puts " 开始读取 HDL 源文件列表"
puts "============================================================"
puts ""


# 以只读方式打开 filelist.f。

set fp [open $FILELIST r]



# ============================================================
# 12. 一行一行解析 filelist.f
# ============================================================

while {[gets $fp line] >= 0} {


    # --------------------------------------------------------
    # 删除当前行首尾的空格
    # --------------------------------------------------------

    set line [string trim $line]


    # --------------------------------------------------------
    # 空行直接跳过
    # --------------------------------------------------------

    if {$line eq ""} {
        continue
    }


    # --------------------------------------------------------
    # 以 # 开头的行为注释
    # --------------------------------------------------------

    if {[string match "#*" $line]} {
        continue
    }



    # ========================================================
    # 13. 处理 +incdir+
    # ========================================================

    # filelist.f 中可以写：
    #
    #   +incdir+include
    #
    # 表示：
    #
    #   include/
    #
    # 是 Verilog/SystemVerilog 头文件搜索目录。
    #
    #
    # 当 HDL 中出现：
    #
    #   `include "defines.vh"
    #
    # 或：
    #
    #   `include "parameters.svh"
    #
    # vlog 就会到这些 include 目录中搜索文件。
    #

    if {[string match "+incdir+*" $line]} {


        # 去掉：
        #
        #   +incdir+
        #
        # 得到实际路径。
        #
        # 例如：
        #
        #   +incdir+include
        #
        #             ↓
        #
        #   include
        #

        set incdir [string range $line 8 end]


        # 将相对路径转换成绝对路径。

        set incdir_abs [resolve_path $PROJECT_ROOT $incdir]


        # 检查 include 目录是否真实存在。

        if {![file isdirectory $incdir_abs]} {

            puts "警告：include 目录不存在："
            puts "  $incdir_abs"
            puts ""
        }


        # 保存成 ModelSim vlog 可以识别的格式：
        #
        #   +incdir+E:/.../include
        #

        lappend INCLUDE_DIRS "+incdir+$incdir_abs"


        puts "发现头文件搜索目录："
        puts "  $incdir_abs"
        puts ""

        continue
    }



    # ========================================================
    # 14. 解析 HDL 源文件路径
    # ========================================================

    # 将：
    #
    #   rtl/example.sv
    #
    # 转换成：
    #
    #   E:/.../rtl/example.sv
    #

    set SOURCE_FILE [resolve_path $PROJECT_ROOT $line]


    # 检查源文件是否存在。
    #
    # 如果 filelist.f 中写错文件名，
    # 直接停止仿真，而不是继续运行。

    if {![file exists $SOURCE_FILE]} {

        puts ""
        puts "============================================================"
        puts "错误：找不到 HDL 源文件："
        puts ""
        puts "  $SOURCE_FILE"
        puts ""
        puts "请检查 sim/filelist.f。"
        puts "============================================================"
        puts ""

        close $fp
        quit -code 1 -f
    }



    # ========================================================
    # 15. 获取文件扩展名
    # ========================================================

    # 例如：
    #
    #   counter.v
    #
    #       → .v
    #
    #   fifo.sv
    #
    #       → .sv
    #

    set EXT [string tolower [file extension $SOURCE_FILE]]


    # 未显式指定 TOP_MODULE 时，默认使用 filelist.f 中最后一个
    # .v/.sv 文件的文件名作为仿真顶层。

    if {$EXT eq ".v" || $EXT eq ".sv"} {
        set AUTO_TOP_MODULE [file rootname [file tail $SOURCE_FILE]]
    }



# ========================================================
# 16. 根据 HDL 文件类型选择编译方式
# ========================================================

# --------------------------------------------------------
# Verilog：.v
# --------------------------------------------------------

if {$EXT eq ".v"} {

    puts "编译 Verilog："
    puts "  $line"

    # .v 文件按照标准 Verilog 模式进行编译。
    #
    # 注意：
    #   这里没有添加 -sv。
    #
    # 因此如果 .v 文件中误用了 SystemVerilog 专用语法，
    # ModelSim 会正常报错。
    #
    # 这样可以保证：
    #
    #   .v  → Verilog
    #   .sv → SystemVerilog

    vlog \
        -work work \
        {*}$INCLUDE_DIRS \
        $SOURCE_FILE

# --------------------------------------------------------
# SystemVerilog：.sv
# --------------------------------------------------------

} elseif {$EXT eq ".sv"} {

    puts "编译 SystemVerilog："
    puts "  $line"

    # -sv：
    #
    # 明确告诉 ModelSim 使用 SystemVerilog 编译模式。
    #
    # 因此可以使用：
    #
    #   logic
    #   always_ff
    #   always_comb
    #   package
    #   interface
    #
    # 等 SystemVerilog 语法。

    vlog \
        -sv \
        -work work \
        {*}$INCLUDE_DIRS \
        $SOURCE_FILE

# --------------------------------------------------------
# HDL 头文件：.vh / .svh
# --------------------------------------------------------

} elseif {$EXT eq ".vh" || $EXT eq ".svh"} {

    # .vh 与 .svh 通常通过：
    #
    #   `include "xxx.vh"
    #
    # 或：
    #
    #   `include "xxx.svh"
    #
    # 被其他 HDL 文件包含。
    #
    # 因此它们通常不作为独立 compilation unit 编译。
    #
    # 如果不小心将它们写进 filelist.f，
    # 这里会直接跳过。

    puts "跳过 HDL 头文件："
    puts "  $line"

# --------------------------------------------------------
# 其他未知文件类型
# --------------------------------------------------------

} else {

    puts ""
    puts "警告：无法识别的仿真源文件类型："
    puts "  $line"
    puts ""
}


# 每处理完一个 filelist 条目后输出一个空行，
# 让 ModelSim Transcript 更容易阅读。
puts ""

}



# ============================================================
# 17. 关闭 filelist.f
# ============================================================

close $fp



# ============================================================
# 18. 确定仿真顶层模块
# ============================================================

if {$TOP_MODULE eq ""} {
    set TOP_MODULE $AUTO_TOP_MODULE
}

if {$TOP_MODULE eq ""} {
    puts ""
    puts "============================================================"
    puts "错误：无法确定仿真顶层模块。"
    puts ""
    puts "请确认 sim/filelist.f 至少包含一个 .v 或 .sv 文件，"
    puts "或者在运行前设置 TOP_MODULE。"
    puts "============================================================"
    puts ""

    quit -code 1 -f
}

puts "仿真顶层模块："
puts "  $TOP_MODULE"
puts ""



# ============================================================
# 19. HDL 编译完成
# ============================================================

puts ""
puts "============================================================"
puts " HDL 编译完成"
puts "============================================================"
puts ""



# ============================================================
# 20. 删除旧的 WLF 波形文件
# ============================================================

# 避免旧的 simulation.wlf 与本次仿真混淆。

if {[file exists $WLF_FILE]} {
    file delete -force $WLF_FILE
}



# ============================================================
# 21. 加载 Testbench
# ============================================================

puts "加载仿真顶层："
puts "  work.$TOP_MODULE"
puts ""


# -voptargs=+acc：
#
# ModelSim 在启动仿真之前会对设计进行优化。
#
# 优化能够提高仿真速度，
# 但某些内部信号可能因此无法被外部访问，
# 从而导致后面的：
#
#   log
#   add wave
#
# 找不到需要观察的信号。
#
# +acc 表示在优化时保留对设计对象的访问能力。
#
# 对于需要查看波形、调试 RTL 的仿真非常重要。
#
# 我们不使用 -novopt 完全关闭优化，
# 而是在保留优化的同时开启信号访问权限。

vsim \
    -voptargs=+acc \
    -wlf $WLF_FILE \
    work.$TOP_MODULE



# ============================================================
# 22. 记录仿真信号
# ============================================================

# ModelSim 中当前 Testbench 的层级通常为：
#
#   /<TOP_MODULE>
#
# 这里根据实际选择的 TOP_MODULE 构造波形记录顶层路径。

set TOP_SCOPE "/$TOP_MODULE"


# 显示当前准备记录的仿真层级。

puts "记录波形层级："
puts "  $TOP_SCOPE/*"
puts ""


# log：
#   告诉 ModelSim 将信号变化写入 WLF 波形数据库。
#
# -r：
#   recursive，递归记录所有子模块中的信号。
#
# 明确指定 Testbench 层级比使用根层级通配符更加可靠，
# 特别是对于较老版本的 ModelSim。

log -r "$TOP_SCOPE/*"



# ============================================================
# 23. 开始运行仿真
# ============================================================

puts ""
puts "============================================================"
puts " 开始运行仿真"
puts "============================================================"
puts ""


# run -all：
#
# 持续运行，
# 直到 Testbench 中执行：
#
#   $finish;
#
# 或出现其他仿真终止条件。
#

run -all



# ============================================================
# 24. 仿真完成
# ============================================================

puts ""
puts "============================================================"
puts " ModelSim 仿真完成"
puts ""
puts "波形数据库："
puts "  $WLF_FILE"
puts ""
puts "构建目录："
puts "  $BUILD_DIR"
puts "============================================================"
puts ""



# ============================================================
# 25. 退出 ModelSim
# ============================================================

quit -f
