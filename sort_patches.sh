#!/bin/sh

PATCHES="localedef.fix_glibc_2.20 localedef.fix_2.15_CDE \
	 libtirpc.remove-nis-2.patch \
	 libelf.install_pdf gettext.fix_testcase \
	 bin.2-28-aeabi-common \
	 bin.2-28-vle-common \
	 bin.2-28-spe2-common \
	 bin.2-28-aeabi-binutils \
	 bin.2-28-vle-binutils \
	 bin.2-28-spe2-binutils \
	 bin.2-28-plt \
	 bin.2-28-booke2vle-binutils \
	 bin.2-28-vleHyp \
	 bin.2-28-efs2 \
	 gcc.aeabi-49x gcc.fix_regalloc_for_482 \
	 gcc.rm_slow_tests-47 gcc.fix_mingw32 \
	 gcc.rm_slow_tests-494 \
	 gcc.e6500-FSF-49x gcc.no_power_builtins-48 \
	 gcc.ld_unaligned-460 gcc.local_unaligned_altivec gcc.soft_float-470 \
	 gcc.case_values-48 gcc.fix_pr63854_pass_manager \
	 gcc.builtin_isel-49x gcc.builtin_isel_doc \
	 gcc.experimental_move \
	 gcc.widen_types-49x \
	 gcc.extelim-v4-49x \
	 gcc.extelim_vrp_kugan-v1-49x \
	 gcc.e5500_mfocr \
	 gcc.opt-array-offset-49x \
	 gcc.load_on_store_bypass-48x \
	 gcc.fix_constvector \
	 gcc.fix_pr63908_unwind_info \
	 gcc.have-pre-modify-disp-support-49x \
	 gcc.fix_ENGR00298583_dwarf-vector-reg_49x \
	 gcc.fix_MTWX51605-memset-array-init_48 \
	 gcc.fix_altivec_constant_alignment-v2 \
	 gcc.fix_altivec_reload_gs8 \
	 gcc.fix_postfix_gimplifier \
	 gcc.fix_adjust_address_cost \
	 gcc.fix_adjust_sched_loopinv_cost \
	 gcc.fix_e5500_mulli_pipeline \
	 gcc.fix_e500mc_addi_pipeline \
	 gcc.fix_ENGR00292364_debug_frame \
	 gcc.fix_ENGR00215936_49x \
	 gcc.enable_soft_multilib-49x gcc.fix_49x-doc \
	 gcc.fix_emulation_spec_48 gcc.create_maeabi \
	 gcc.rm_e500v2_loops_48 \
	 gcc.fix_e5500-e6500-aeabi-multi-lib \
	 gcc.fix_ivopts \
	 gcc.sysroot_spec_only_linux \
	 gcc.fix_extelim_gcc_6x \
	 gcc.debug_md \
	 gcc.optimize_static_vars \
	 gcc.poison_dirs \
	 gcc.vle_494 \
	 gcc.vle_LSP_49x \
	 gcc.easy_on_slow_tests \
	 gcc.more_dejagnu_parallelization \
	 gcc.fix_isel_49x \
	 gcc.fix_trap_49x \
	 gcc.rm_slow_tests_vle \
	 gcc.vle_spe2 \
	 gcc.vle_short_double \
	 glibc.undefined_static glibc.readv_proto \
	 glibc.add-option-groups-support \
	 glibc.rtld_debug_option_group glibc.use-option-groups \
	 glibc.fix_sqrt2 glibc.fix_sqrt_finite glibc.fix_slow_ieee754_sqrt \
	 glibc.fsl-ppc-no-fsqrt \
	 glibc.fix_prof glibc.fsl-crosszic \
	 glibc.fix_MTWX51911-enable_8xx \
	 glibc.e500v2_lib_support \
	 glibc.fsl-mcpy-e500mc-e5500-e6500-patch \
	 glibc.fsl-largemcpy-e500mc-e5500-e6500-patch \
	 glibc.fsl-e500mc-e5500-mset-patch \
	 glibc.fsl-mset-e6500-patch \
	 glibc.fsl-mcmp-e6500-patch \
	 glibc.fsl-stcmp-e5500-patch \
	 glibc.fsl-strchr-e500mc-e5500-patch \
	 glibc.fsl-strcpy-e500mc-e5500-patch \
	 glibc.fsl-strlen-e500mc-e5500-patch \
	 glibc.fsl-strrchr-e500mc-e5500-patch \
	 glibc.testsuite_remove-blocking-test \
	 gdb.7-8-2_fix-fallthrough \
	 newlib.basic_aeabi-2.0 newlib.aeabi \
	 newlib.fsl-mcpy-e500mc-e5500-e6500-patch \
	 newlib.fsl-largemcpy-e500mc-e5500-e6500-patch \
	 newlib.fix_html_doc newlib.fix_pdf_doc newlib.fix_pdf_doc2 \
	 newlib.vle-2.2"

pcount=0
for i in $PATCHES
do
 num=$(printf "%04d" $pcount)
 ((pcount=$pcount+1))
 filename="${i%%.*}"
 extension="${i#*.}"

 echo mv patch/$i patch/$filename.$num.$extension.patch || true
done
