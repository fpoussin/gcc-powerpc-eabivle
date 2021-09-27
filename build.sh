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
# See: http://preshing.com/20141119/how-to-a-gcc-cross-compiler
#-------------------------------------------------------------------------------------------

TARGET=powerpc-eabivle
INSTALL_PATH=~/bin/gcc-$TARGET
PARALLEL_MAKE=-j`nproc`
PATCH_CMD="patch -lbsf -p1"
WGET="wget -c"

GCC_VERSION=4.9.4
GCC_OPTIONS="--with-cpu=e200z0 --enable-languages=c,c++ --disable-shared --disable-threads --with-newlib --with-headers=yes --enable-cloog-backend=isl"
MPFR_VERSION=4.1.0
GMP_VERSION=6.2.1
MPC_VERSION=1.2.1
ISL_VERSION=0.18
CLOOG_VERSION=0.18.4
PPL_VERSION=1.2
LIBICONV_VERSION=1.16

GDB_VERSION=7.8.2
PYTHON_VERSION=2.7.18

BINUTILS_VERSION=2.28
BINUTILS_OPTIONS="--enable-poison-system-directories --disable-nls"

NEWLIB_VERSION=2.2.0
NEWLIB_OPTIONS="--enable-newlib-io-long-long --enable-newlib-register-fini --disable-newlib-multithread --disable-newlib-supplied-syscalls"

export PATH=$INSTALL_PATH/bin:$PATH

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
	$WGET https://www.bugseng.com/products/ppl/download/ftp/releases/${PPL_VERSION}/ppl-${PPL_VERSION}.tar.xz
	$WGET https://ftp.gnu.org/gnu/libiconv/libiconv-${LIBICONV_VERSION}.tar.gz
	touch .downloaded 
	popd
else
	echo Skipping downloads
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
for p in ../../patch/gcc.*; do echo $p; ${PATCH_CMD} < $p; done
popd

pushd newlib-${NEWLIB_VERSION} > /dev/null
for p in ../../patch/newlib.*; do echo $p; ${PATCH_CMD} -p1 < $p; done
popd

pushd binutils-${BINUTILS_VERSION} > /dev/null
for p in ../../patch/bin.*; do echo $p; ${PATCH_CMD} -p1 < $p; done
popd

pushd gdb-${GDB_VERSION} > /dev/null
for p in ../../patch/gdb.*; do echo $p; ${PATCH_CMD} -p1 < $p; done
popd

# Make symbolic links
pushd gcc-${GCC_VERSION} > /dev/null
ln -sf `ls -1d ../mpfr-${MPFR_VERSION}` mpfr
ln -sf `ls -1d ../gmp-${GMP_VERSION}` gmp
ln -sf `ls -1d ../mpc-${MPC_VERSION}` mpc
ln -sf `ls -1d ../isl-${ISL_VERSION}` isl
ln -sf `ls -1d ../cloog-${CLOOG_VERSION}` cloog
ln -sf `ls -1d ../ppl-${PPL_VERSION}` ppl
ln -sf `ls -1d ../libiconv-${LIBICONV_VERSION}` libiconv
popd

popd # extracted

pushd build > /dev/null
echo Cleanup build directories
rm -rf *

# Step 1. Binutils
mkdir -p binutils
pushd binutils > /dev/null
../../extracted/binutils-${BINUTILS_VERSION}/configure --prefix=${INSTALL_PATH} --target=${TARGET} ${BINUTILS_OPTIONS}
make $PARALLEL_MAKE
make install
popd

# Step 3. C/C++ Compilers
mkdir -p gcc
pushd gcc > /dev/null
../../extracted/gcc-${GCC_VERSION}/configure --prefix=${INSTALL_PATH} --target=${TARGET} ${GCC_OPTIONS}
make $PARALLEL_MAKE all-gcc
make install-gcc
popd

# Steps 4-6: Newlib
mkdir -p newlib
pushd newlib > /dev/null
../../extracted/newlib-${NEWLIB_VERSION}/configure --prefix=${INSTALL_PATH} --target=${TARGET} ${NEWLIB_OPTIONS}
make $PARALLEL_MAKE
make install
popd

# Step 7. Standard C++ Library & the rest of GCC
pushd gcc > /dev/null
make $PARALLEL_MAKE all
make install
popd

# Step 8. Python
mkdir -p python
pushd python > /dev/null
../../extracted/Python-${PYTHON_VERSION}/configure --enable-shared --prefix=${INSTALL_PATH} LDFLAGS="-Wl,--rpath=${INSTALL_PATH}/lib"
make $PARALLEL_MAKE all
make install
popd

# Step 9. GDB
mkdir -p gdb
pushd gdb > /dev/null
LDFLAGS="-Wl,-rpath,${INSTALL_PATH}/lib -L${INSTALL_PATH}/lib" ../../extracted/gdb-${GDB_VERSION}/configure --prefix=${INSTALL_PATH} --target=${TARGET} --with-python=${INSTALL_PATH}/bin
make $PARALLEL_MAKE all
make install
popd

popd # build dir

trap - EXIT
echo 'Success!'
