# ---------------- paths ----------------
SOURCES := ../sources

# ---------------- compilers ----------------
CC       = gcc
FC      ?= mpif90
F90      = $(FC)
PYTHON   = python

# ---------------- macOS SDK + Homebrew ----------------
# Expect these set in your shell:
#   export SDKROOT="$(xcrun --sdk macosx --show-sdk-path)"
#   export HDF5_HOME="$(brew --prefix hdf5-mpi)"
#   export ZLIB_HOME="$(brew --prefix zlib)"
SDK_CFLAGS   = -isysroot $(SDKROOT)
SDK_LDFLAGS  = -Wl,-syslibroot,$(SDKROOT)

HDF5_INC = -I$(HDF5_HOME)/include
HDF5_LIB = -L$(HDF5_HOME)/lib -lhdf5_fortran -lhdf5
ZLIB_INC = -I$(ZLIB_HOME)/include
ZLIB_LIB = -L$(ZLIB_HOME)/lib -lz


# ---------------- compiler family detection ----------------
# If FC contains "ifort" use Intel settings, otherwise default to gfortran-style
IFORT := $(findstring ifort,$(F90))

ifeq ($(IFORT),ifort)
  # Intel
  FPP          = gfortran -E             # only for preprocessing f90wrap temps
  FPP_F90FLAGS = -x f95-cpp-input -fPIC
  F90FLAGS     = -fpscomp logicals -fPIC
  FCOMP        = intelem
  LIBS         =
else
  # gfortran/mpif90 wrappers (default)
  FPP          = $(FC) -E
  FPP_F90FLAGS = -x f95-cpp-input -fPIC $(SDK_CFLAGS) $(HDF5_INC) $(ZLIB_INC)
  F90FLAGS     = $(RFLAGS) $(SDK_CFLAGS)
  FCOMP        = $(FC)
  LIBS         =
endif

CFLAGS = -fPIC

UNAME = $(shell uname)
ifeq ($(UNAME),Darwin)
  LIBTOOL = libtool -static -o
else
  LIBTOOL = ar rcs
endif

# ---------------- project config ----------------
PYTHON_MODN = famus
KIND_MAP    = kind_map
LIB_NAME    = lib$(PYTHON_MODN).a

# ---------------- autodetect ALLFILES from ../sources ----------------
# Take every *_m.F90 in ../sources, strip suffix to get the unit name.
ALLFILES ?= $(patsubst $(SOURCES)/%_m.F90,%,$(wildcard $(SOURCES)/*_m.F90))
# Don’t wrap the main program
TMP_FILES := $(filter-out focus,$(ALLFILES))

# Lists for wrapping
LIBSRC_WRAP_SOURCES    := $(TMP_FILES)
LIBSRC_WRAP_MFILES     := $(addsuffix _m.F90,${LIBSRC_WRAP_SOURCES})
LIBSRC_WRAP_OBJECTS    := $(addsuffix _r.o,${LIBSRC_WRAP_SOURCES})
LIBSRC_WRAP_FPP_FILES  := $(addsuffix .fpp,${LIBSRC_WRAP_SOURCES})

EXTRA_OBJS := ode.o lmder1.o hybrj.o lbfgsb.o cg_descent.o simann.o

# ---------------- phony ----------------
.PHONY: all all_clean f90wrap_clean sources-build

# Default build: python module + quick import test
all: _${PYTHON_MODN}.so test

# Build the reduced object set in ../sources (produces *_r.o and ../bin/xfocus)
sources-build:
	$(MAKE) -C $(SOURCES) xfocus CC=gfortran PFLAGS="$(PFLAGS) $(CFLAGS)" ALLFILES="$(ALLFILES)"

# Clean both python side and sources side
all_clean: f90wrap_clean
	$(MAKE) -C $(SOURCES) clean ALLFILES="$(ALLFILES)"

f90wrap_clean:
	-rm -f ${LIBSRC_OBJECTS} ${LIBSRC_FPP_FILES} $(LIB_NAME) _${PYTHON_MODN}*.so \
	      *.mod *.fpp f90wrap*.f90 f90wrap*.o *.o ${PYTHON_MODN}.py
	-rm -rf ${PYTHON_MODN}_pkg
	-rm -rf src.*/ .f2py_f2cmap .libs/ __pycache__/
	-rm -f $(LIB_NAME)

# ---------------- preprocessing: *_m.F90 -> .fpp ----------------
# Use the Fortran preprocessor; NEVER try to execute an .F90
%.fpp: $(SOURCES)/%_m.F90 | sources-build
	$(FPP) $(FPP_F90FLAGS) $< -o $@

# ---------------- archive the reduced objects into a static lib ----------------
$(LIB_NAME): | sources-build
	$(LIBTOOL) $@ \
	  $(addprefix $(SOURCES)/, $(LIBSRC_WRAP_OBJECTS) $(EXTRA_OBJS))
ifeq ($(findstring libtool,$(LIBTOOL)),libtool)
	ranlib $@
endif

# ---------------- build the Python extension ----------------
_${PYTHON_MODN}.so: $(LIB_NAME) ${LIBSRC_WRAP_FPP_FILES}
	f90wrap -m ${PYTHON_MODN} ${LIBSRC_WRAP_FPP_FILES} -k ${KIND_MAP} -v
	f2py-f90wrap --f90exec=${FC} --build-dir . -c -m _${PYTHON_MODN} \
	    -L. -l$(PYTHON_MODN) -I${SOURCES} \
	    $(HDF5_INC) $(ZLIB_INC) \
	    $(HDF5_LIB) $(ZLIB_LIB) \
	    f90wrap*.f90

# ---------------- sanity test ----------------
test:
	@python -c "import famus; print('FAMUS version: {:}'.format(famus.globals.version))"
