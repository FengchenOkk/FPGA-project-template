# ============================================================
# Vivado 通用 Implementation 脚本
#
# 使用方法：
#
#   vivado -mode batch \
#          -source scripts/vivado_impl.tcl \
#          -tclargs <TOP_MODULE>
#
# 例如：
#
#   vivado -mode batch \
#          -source scripts/vivado_impl.tcl \
#          -tclargs example
#
#
# 本脚本完成：
#
#   1. 打开综合生成的 DCP
#   2. opt_design
#   3. place_design
#   4. route_design
#   5. 保存各阶段 DCP
#   6. 生成资源、时序和 DRC 报告
#
# 所有生成文件放入：
#
#   build/vivado/impl/
#
# ============================================================


# ============================================================
# 1. 获取工程根目录
# ============================================================

set PROJECT_ROOT [file normalize [pwd]]


# ============================================================
# 2. 获取命令行参数
# ============================================================

if {$argc < 1} {

    puts ""
    puts "============================================================"
    puts "错误：缺少 RTL 顶层模块名称。"
    puts ""
    puts "正确用法："
    puts ""
    puts "  vivado -mode batch \\"
    puts "         -source scripts/vivado_impl.tcl \\"
    puts "         -tclargs <TOP_MODULE>"
    puts ""
    puts "例如："
    puts ""
    puts "  vivado -mode batch \\"
    puts "         -source scripts/vivado_impl.tcl \\"
    puts "         -tclargs example"
    puts "============================================================"
    puts ""

    exit 1
}

set TOP_MODULE [lindex $argv 0]


# ============================================================
# 3. 设置路径
# ============================================================

set SYNTH_DIR [file join $PROJECT_ROOT build vivado synth]
set IMPL_DIR  [file join $PROJECT_ROOT build vivado impl]

# 综合阶段生成的 DCP
set SYNTH_DCP [file join $SYNTH_DIR "${TOP_MODULE}_synth.dcp"]

# Implementation 各阶段 DCP
set OPT_DCP   [file join $IMPL_DIR "${TOP_MODULE}_opt.dcp"]
set PLACE_DCP [file join $IMPL_DIR "${TOP_MODULE}_place.dcp"]
set ROUTE_DCP [file join $IMPL_DIR "${TOP_MODULE}_route.dcp"]

# 报告
set UTIL_REPORT   [file join $IMPL_DIR "utilization_route.rpt"]
set TIMING_REPORT [file join $IMPL_DIR "timing_route.rpt"]
set DRC_REPORT    [file join $IMPL_DIR "drc_route.rpt"]


# ============================================================
# 4. 检查综合 DCP
# ============================================================

if {![file exists $SYNTH_DCP]} {

    puts ""
    puts "============================================================"
    puts "错误：找不到综合后的 DCP："
    puts ""
    puts "  $SYNTH_DCP"
    puts ""
    puts "请先运行 Vivado Synthesis。"
    puts "============================================================"
    puts ""

    exit 1
}


# ============================================================
# 5. 创建 Implementation 目录
# ============================================================

file mkdir $IMPL_DIR

cd $IMPL_DIR


# ============================================================
# 6. 显示当前配置
# ============================================================

puts ""
puts "============================================================"
puts " Vivado Implementation"
puts "============================================================"
puts ""
puts "工程根目录："
puts "  $PROJECT_ROOT"
puts ""
puts "RTL 顶层模块："
puts "  $TOP_MODULE"
puts ""
puts "输入 DCP："
puts "  $SYNTH_DCP"
puts ""
puts "输出目录："
puts "  $IMPL_DIR"
puts ""
puts "============================================================"
puts ""


# ============================================================
# 7. 打开综合后的 Design Checkpoint
# ============================================================

puts ""
puts "============================================================"
puts " 打开综合 DCP"
puts "============================================================"
puts ""

open_checkpoint $SYNTH_DCP


# ============================================================
# 8. Logic Optimization
# ============================================================

puts ""
puts "============================================================"
puts " 开始 opt_design"
puts "============================================================"
puts ""

opt_design

write_checkpoint \
    -force \
    $OPT_DCP


# ============================================================
# 9. Placement
# ============================================================

puts ""
puts "============================================================"
puts " 开始 place_design"
puts "============================================================"
puts ""

place_design

write_checkpoint \
    -force \
    $PLACE_DCP


# ============================================================
# 10. Routing
# ============================================================

puts ""
puts "============================================================"
puts " 开始 route_design"
puts "============================================================"
puts ""

route_design

write_checkpoint \
    -force \
    $ROUTE_DCP


# ============================================================
# 11. 生成资源报告
# ============================================================

report_utilization \
    -file $UTIL_REPORT


# ============================================================
# 12. 生成时序报告
# ============================================================

report_timing_summary \
    -file $TIMING_REPORT


# ============================================================
# 13. 生成 DRC 报告
# ============================================================

report_drc \
    -file $DRC_REPORT


# ============================================================
# 14. 完成
# ============================================================

puts ""
puts "============================================================"
puts " Vivado Implementation 完成"
puts ""
puts "Route Checkpoint："
puts "  $ROUTE_DCP"
puts ""
puts "资源报告："
puts "  $UTIL_REPORT"
puts ""
puts "时序报告："
puts "  $TIMING_REPORT"
puts ""
puts "DRC 报告："
puts "  $DRC_REPORT"
puts "============================================================"
puts ""

exit