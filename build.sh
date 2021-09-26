#! /bin/bash
set -e
trap 'previous_command=$this_command; this_command=$BASH_COMMAND' DEBUG
trap 'echo FAILED COMMAND: $previous_command' EXIT

#-------------------------------------------------------------------------------------------
# This script will download packages for, configure, build and install a GCC cross-compiler.
# Customize the variables (INSTALL_PATH, TARGET, etc.) to your liking before running.
# If you get an error and need to resume the script from some point in the middle,
# just delete/comment the preceding lines before running it again.
#
# See: http://preshing.com/20141119/how-to-build-a-gcc-cross-compiler
#-------------------------------------------------------------------------------------------

TARGET=powerpc-eabivle
INSTALL_PATH=~/bin/cross-$TARGET
CONFIGURATION_OPTIONS="--disable-multilib --disable-threads --disable-shared"
PARALLEL_MAKE=-j`nproc`
PATCH_CMD="patch -lbsf -p1"
WGET="wget -c"

BINUTILS_VERSION=2.28
GCC_VERSION=4.9.4
GDB_VERSION=7.8.2
LINUX_KERNEL_VERSION=3.19
NEWLIB_VERSION=2.2.0
MPFR_VERSION=3.0.1
GMP_VERSION=4.3.2
MPC_VERSION=1.0.3
ISL_VERSION=0.12.2
CLOOG_VERSION=0.18.4
PYTHON_VERSION=2.7.18

export PATH=$INSTALL_PATH/bin:$PATH

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

#pcount=0
#for i in $PATCHES
#do
#  num=$(printf "%04d" $pcount)
#  ((pcount=$pcount+1))
#  filename="${i%%.*}"
#  extension="${i#*.}"
#
#  echo mv patch/$i patch/$filename.$num.$extension.patch || true
#done
#exit 0

if [ ! -f archives/.downloaded ]; then
	echo Downloading archives...
	pushd archives > /dev/null
	$WGET https://ftp.gnu.org/gnu/gcc/gcc-${GCC_VERSION}/gcc-${GCC_VERSION}.tar.bz2
	$WGET https://ftp.gnu.org/gnu/gdb/gdb-${GDB_VERSION}.tar.xz
	$WGET https://ftp.gnu.org/gnu/binutils/binutils-${BINUTILS_VERSION}.tar.bz2
	$WGET ftp://sourceware.org/pub/newlib/newlib-${NEWLIB_VERSION}.tar.gz
	$WGET https://ftp.gnu.org/gnu/gmp/gmp-${GMP_VERSION}.tar.bz2
	$WGET https://ftp.gnu.org/gnu/mpfr/mpfr-${MPFR_VERSION}.tar.bz2
	$WGET https://ftp.gnu.org/gnu/mpc/mpc-${MPC_VERSION}.tar.gz
	$WGET https://gcc.gnu.org/pub/gcc/infrastructure/isl-${ISL_VERSION}.tar.bz2
	$WGET http://www.bastoul.net/cloog/pages/download/cloog-${CLOOG_VERSION}.tar.gz
	$WGET https://www.python.org/ftp/python/${PYTHON_VERSION}/Python-${PYTHON_VERSION}.tar.xz
	touch .downloaded 
	popd
fi

pushd extracted > /dev/null
echo Clearing old archives
rm -rf *
echo Extracting archives
# Extract everything
for f in ../archives/*.tar*; do echo $f; tar xf $f; done

echo Patching
pushd gcc-${GCC_VERSION} > /dev/null
# Fix some fortran files format (patching will fail otherwise)
find gcc/testsuite/gfortran.dg -type f -exec dos2unix {} \;
for p in ../../patch/gcc.*; do echo $p; $PATCH_CMD < $p; done
popd

pushd newlib-${NEWLIB_VERSION} > /dev/null
for p in ../../patch/newlib.*; do echo $p; $PATCH_CMD -p1 < $p; done
popd

pushd binutils-${BINUTILS_VERSION} > /dev/null
for p in ../../patch/bin.*; do echo $p; $PATCH_CMD -p1 < $p; done
popd

pushd gdb-${GDB_VERSION} > /dev/null
for p in ../../patch/gdb.*; do echo $p; $PATCH_CMD -p1 < $p; done
popd

# Make symbolic links
cd gcc-${GCC_VERSION}
ln -sf `ls -1d ../mpfr-${MPFR_VERSION}` mpfr
ln -sf `ls -1d ../gmp-${GMP_VERSION}` gmp
ln -sf `ls -1d ../mpc-${MPC_VERSION}` mpc
ln -sf `ls -1d ../isl-${ISL_VERSION}` isl
ln -sf `ls -1d ../cloog-${CLOOG_VERSION}` cloog
cd ..

popd

# Step 1. Binutils
mkdir -p build-binutils
cd build-binutils
../extracted/binutils-${BINUTILS_VERSION}/configure --prefix=${INSTALL_PATH} --target=${TARGET} ${CONFIGURATION_OPTIONS}
make $PARALLEL_MAKE
make install
cd ..

# Step 3. C/C++ Compilers
mkdir -p build-gcc
cd build-gcc
NEWLIB_OPTION=--with-newlib
../extracted/gcc-${GCC_VERSION}/configure --prefix=${INSTALL_PATH} --target=${TARGET} --enable-languages=c,c++ ${CONFIGURATION_OPTIONS} ${NEWLIB_OPTION}
make $PARALLEL_MAKE all-gcc
make install-gcc
cd ..

# Steps 4-6: Newlib
mkdir -p build-newlib
cd build-newlib
../extracted/newlib-${NEWLIB_VERSION}/configure --prefix=${INSTALL_PATH} --target=${TARGET} ${CONFIGURATION_OPTIONS}
make $PARALLEL_MAKE
make install
cd ..

# Step 7. Standard C++ Library & the rest of GCC
cd build-gcc
make $PARALLEL_MAKE all
make install
cd ..

# Step 8. Python
mkdir -p build-python
cd build-python
../extracted/Python-${PYTHON_VERSION}/configure --enable-shared --prefix=${INSTALL_PATH} LDFLAGS="-Wl,--rpath=${INSTALL_PATH}/lib"
make $PARALLEL_MAKE all
make install
cd ..

# Step 9. GDB
mkdir -p build-gdb
cd build-gdb
LDFLAGS="-Wl,-rpath,${INSTALL_PATH}/lib -L${INSTALL_PATH}/lib" ../extracted/gdb-${GDB_VERSION}/configure --prefix=${INSTALL_PATH} --target=${TARGET} --with-python=${INSTALL_PATH}/bin
make $PARALLEL_MAKE all
make install
cd ..

trap - EXIT
echo 'Success!'

