#!/bin/bash

export HDF5_HOME="$(brew --prefix hdf5-mpi)"
export ZLIB_HOME="$(brew --prefix zlib)"
export SDKROOT="$(xcrun --sdk macosx --show-sdk-path)"

make -C ../sources xfocus FC=mpif90 CC=gfortran \
    PFLAGS="-fPIC -ffree-line-length-none -fbacktrace -fbounds-check -Og -g -D TOPO -isysroot $SDKROOT -I$HDF5_HOME/include -I$ZLIB_HOME/include" \
    LDFLAGS="-Wl,-syslibroot,$SDKROOT -L$HDF5_HOME/lib -L$ZLIB_HOME/lib" \
    LIBS="-lhdf5_fortran -lhdf5 -lz -lm"
