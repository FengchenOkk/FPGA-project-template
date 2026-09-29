# ============================================================
# Vivado 通用 RTL 综合脚本
#
# 文件：
#
#   scripts/vivado_synth.tcl
#
#
# 使用方法：
#
#   必须从 FPGA 工程根目录执行：
#
#   vivado -mode batch \
#          -source scripts/vivado_synth.tcl \
#          -tclargs <TOP_MODULE> <FPGA_PART>
#
#
# 例如：
#
#   vivado -mode batch \
#          -source scripts/vivado_synth.tcl \
#          -tclargs example xc7z020clg400-2
#
#
# 本脚本完成：
#
#   1. 获取工程根目录
#   2. 读取命令行中的顶层模块和 FPGA Part
#   3. 创建 build/vivado/synth
#   4. 读取 rtl/filelist.f
#   5. .v  按 Verilog 读取
#   6. .sv 按 SystemVerilog 读取
#   7. 设置 include 搜索目录
#   8. 执行 Vivado 综合
#   9. 保存综合后的 DCP
#  10. 生成综合报告
#
#
# 本脚本采用 Vivado Non-Project Mode。
#
# 不创建 .xpr 工程，
# 所有生成文件统一放入：
#
#   build/vivado/
#
# ============================================================



# ============================================================
# 1. 获取 FPGA 工程根目录
# ============================================================

# 本脚本规定从工程根目录启动 Vivado。
#
# 例如：
#
#   E:/FPGAprogram/FPGA-project-template
#
# 因此 pwd 就是工程根目录。

set PROJECT_ROOT [file normalize [pwd]]



# ============================================================
# 2. 读取命令行参数
# ============================================================

# 本脚本需要两个参数：
#
#   argv[0] → RTL 顶层模块名称
#   argv[1] → FPGA Part
#
# 例如：
#
#   -tclargs example xc7z020clg400-2
#

if {$argc < 2} {

    puts ""
    puts "============================================================"
    puts "错误：缺少 Vivado 综合参数。"
    puts ""
    puts "正确用法："
    puts ""
    puts "  vivado -mode batch \\"
    puts "         -source scripts/vivado_synth.tcl \\"
    puts "         -tclargs <TOP_MODULE> <FPGA_PART>"
    puts ""
    puts "例如："
    puts ""
    puts "  vivado -mode batch \\"
    puts "         -source scripts/vivado_synth.tcl \\"
    puts "         -tclargs example xc7z020clg400-2"
    puts "============================================================"
    puts ""

    exit 1
}


# RTL 顶层模块名称。
#
# 注意：
#   这里填写的是 module 名称，
#   不是文件名。

set TOP_MODULE [lindex $argv 0]


# FPGA 完整 Part。
#
# 你当前的 ZYNQ7020：
#
#   xc7z020clg400-2

set FPGA_PART [lindex $argv 1]



# ============================================================
# 3. 设置工程路径
# ============================================================

# 综合源文件列表。

set FILELIST [file join $PROJECT_ROOT rtl filelist.f]


# XDC 约束文件列表

set XDC_FILELIST [file join $PROJECT_ROOT constr filelist.f]


# Vivado 综合生成文件目录。

set BUILD_DIR [file join $PROJECT_ROOT build vivado synth]


# 综合后的 Design Checkpoint。

set DCP_FILE [file join $BUILD_DIR "${TOP_MODULE}_synth.dcp"]


# 综合资源使用报告。

set UTIL_REPORT [file join $BUILD_DIR "utilization_synth.rpt"]


# 综合时序摘要。

set TIMING_REPORT [file join $BUILD_DIR "timing_synth.rpt"]



# ============================================================
# 4. 检查工程文件
# ============================================================

if {![file exists $FILELIST]} {

    puts ""
    puts "============================================================"
    puts "错误：找不到 Vivado 综合文件列表："
    puts ""
    puts "  $FILELIST"
    puts ""
    puts "请确认存在："
    puts ""
    puts "  rtl/filelist.f"
    puts "============================================================"
    puts ""

    exit 1
}



# ============================================================
# 5. 初始化 include 路径列表
# ============================================================

set INCLUDE_DIRS {}



# ============================================================
# 6. 定义相对路径转换函数
# ============================================================

# filelist 中使用工程相对路径：
#
#   rtl/example.sv
#
# 这里将它转换成完整绝对路径。

proc resolve_path {root path} {

    if {[file pathtype $path] eq "absolute"} {
        return [file normalize $path]
    }

    return [file normalize [file join $root $path]]
}



# ============================================================
# 7. 显示本次综合参数
# ============================================================

puts ""
puts "============================================================"
puts " Vivado RTL 综合"
puts "============================================================"

puts "工程根目录："
puts "  $PROJECT_ROOT"

puts ""

puts "RTL 顶层模块："
puts "  $TOP_MODULE"

puts ""

puts "FPGA Part："
puts "  $FPGA_PART"

puts ""

puts "综合文件列表："
puts "  $FILELIST"

puts ""

puts "构建目录："
puts "  $BUILD_DIR"

puts "============================================================"
puts ""



# ============================================================
# 8. 创建 Vivado 构建目录
# ============================================================

file mkdir $BUILD_DIR


# 将 Vivado 当前工作目录切换到 build/vivado/synth。
#
# 因此 Vivado 自动生成的：
#
#   vivado.log
#   vivado.jou
#
# 等文件也会尽量留在 build 目录。

cd $BUILD_DIR



# ============================================================
# 9. 读取 rtl/filelist.f
# ============================================================

set fp [open $FILELIST r]


while {[gets $fp line] >= 0} {


    # 删除行首和行尾空白。

    set line [string trim $line]


    # 跳过空行。

    if {$line eq ""} {
        continue
    }


    # 跳过以 # 开头的注释。

    if {[string match "#*" $line]} {
        continue
    }



    # ========================================================
    # 10. 处理 +incdir+
    # ========================================================

    if {[string match "+incdir+*" $line]} {

        # 删除：
        #
        #   +incdir+
        #
        # 只保留实际路径。

        set incdir [string range $line 8 end]


        # 转换成绝对路径。

        set incdir_abs [resolve_path $PROJECT_ROOT $incdir]


        if {![file isdirectory $incdir_abs]} {

            puts ""
            puts "警告：include 目录不存在："
            puts "  $incdir_abs"
            puts ""
        }


        lappend INCLUDE_DIRS $incdir_abs


        puts "发现头文件搜索目录："
        puts "  $incdir_abs"
        puts ""

        continue
    }



    # ========================================================
    # 11. 获取 RTL 源文件路径
    # ========================================================

    set SOURCE_FILE [resolve_path $PROJECT_ROOT $line]


    if {![file exists $SOURCE_FILE]} {

        puts ""
        puts "============================================================"
        puts "错误：找不到 RTL 源文件："
        puts ""
        puts "  $SOURCE_FILE"
        puts ""
        puts "请检查："
        puts ""
        puts "  rtl/filelist.f"
        puts "============================================================"
        puts ""

        close $fp
        exit 1
    }



    # 获取文件扩展名。

    set EXT [string tolower [file extension $SOURCE_FILE]]



    # ========================================================
    # 12. Verilog：.v
    # ========================================================

    if {$EXT eq ".v"} {

        puts "读取 Verilog："
        puts "  $line"

        # read_verilog：
        #
        # 将普通 Verilog RTL 读入 Vivado
        # 当前 Non-Project Mode 设计。

        read_verilog $SOURCE_FILE



    # ========================================================
    # 13. SystemVerilog：.sv
    # ========================================================

    } elseif {$EXT eq ".sv"} {

        puts "读取 SystemVerilog："
        puts "  $line"

        # -sv：
        #
        # 明确告诉 Vivado 使用 SystemVerilog 模式。

        read_verilog -sv $SOURCE_FILE



    # ========================================================
    # 14. HDL 头文件
    # ========================================================

    } elseif {$EXT eq ".vh" || $EXT eq ".svh"} {

        # 头文件由：
        #
        #   `include
        #
        # 引入，不需要独立综合。

        puts "跳过 HDL 头文件："
        puts "  $line"



    # ========================================================
    # 15. 未知文件类型
    # ========================================================

    } else {

        puts ""
        puts "警告：Vivado 综合脚本不认识该文件类型："
        puts "  $line"
        puts ""
    }


    puts ""
}


close $fp


# ============================================================
# 读取 XDC 约束文件
# ============================================================

puts ""
puts "============================================================"
puts " 读取 XDC 约束"
puts "============================================================"
puts ""

if {[file exists $XDC_FILELIST]} {

    set xdc_fp [open $XDC_FILELIST r]

    while {[gets $xdc_fp line] >= 0} {

        # 去掉行首和行尾空白
        set line [string trim $line]

        # 跳过空行
        if {$line eq ""} {
            continue
        }

        # 跳过注释
        if {[string match "#*" $line]} {
            continue
        }

        # 转换成绝对路径
        set XDC_FILE [resolve_path $PROJECT_ROOT $line]

        # 检查文件是否存在
        if {![file exists $XDC_FILE]} {

            puts ""
            puts "============================================================"
            puts "错误：找不到 XDC 约束文件："
            puts ""
            puts "  $XDC_FILE"
            puts ""
            puts "请检查："
            puts ""
            puts "  constr/filelist.f"
            puts "============================================================"
            puts ""

            close $xdc_fp
            exit 1
        }

        puts "读取 XDC："
        puts "  $line"
        puts ""

        read_xdc $XDC_FILE
    }

    close $xdc_fp

} else {

    puts "未找到 constr/filelist.f"
    puts "当前设计将不加载 XDC 约束。"
}

puts ""



# ============================================================
# 16. 执行 Vivado 综合
# ============================================================

puts ""
puts "============================================================"
puts " 开始 Vivado 综合"
puts "============================================================"
puts ""


# synth_design：
#
#   -top
#       指定 RTL 顶层 module。
#
#   -part
#       指定目标 FPGA 器件。
#
#   -include_dirs
#       指定 Verilog/SystemVerilog `include 搜索目录。
#
#
# 你的 ZYNQ7020：
#
#   xc7z020clg400-2
#
# Vivado 会从前面 read_verilog 读入的 RTL 中
# 找到 TOP_MODULE 并开始综合。



synth_design \
    -top $TOP_MODULE \
    -part $FPGA_PART \
    -include_dirs $INCLUDE_DIRS



# ============================================================
# 17. 保存综合后的 Design Checkpoint
# ============================================================

# .dcp：
#
# Vivado Design Checkpoint。
#
# 它保存综合后的网表和设计状态，
# 以后 Implementation 可以直接继续使用。

write_checkpoint \
    -force \
    $DCP_FILE



# ============================================================
# 18. 生成资源使用报告
# ============================================================

# 查看综合后使用了多少：
#
#   LUT
#   Flip-Flop
#   BRAM
#   DSP
#   IO
#
# 等 FPGA 资源。

report_utilization \
    -file $UTIL_REPORT



# ============================================================
# 19. 生成综合时序报告
# ============================================================

# 当前模板还没有正式 XDC 时，
# Timing Report 可能提示时钟未约束。
#
# 这是正常的。
#
# 等后面配置 constr/*.xdc 后，
# 才会开始做真正有意义的时序分析。

report_timing_summary \
    -file $TIMING_REPORT



# ============================================================
# 20. 综合完成
# ============================================================

puts ""
puts "============================================================"
puts " Vivado 综合完成"
puts ""
puts "综合 Checkpoint："
puts "  $DCP_FILE"
puts ""
puts "资源报告："
puts "  $UTIL_REPORT"
puts ""
puts "时序报告："
puts "  $TIMING_REPORT"
puts "============================================================"
puts ""


exit