#!/bin/bash

export HDF5_HOME="$(brew --prefix hdf5-mpi)"
export ZLIB_HOME="$(brew --prefix zlib)"
export SDKROOT="$(xcrun --sdk macosx --show-sdk-path)"

make FC=mpif90