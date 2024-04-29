set(PYTHON_LIBRARIES "$ENV{SROOT}/lib/libpython3.10.so" CACHE FILEPATH "Python library")
set(PYTHON_INCLUDE_DIR "$ENV{SROOT}/include/python3.10" CACHE PATH "Path the Python include directory")
set(PYTHON_EXECUTABLE "$ENV{SROOT}/bin/python" CACHE FILEPATH "Python interpreter")
set(PYTHON_VERSION "3.10" CACHE STRING "Python version")
set(PYTHON_FOUND TRUE CACHE BOOL "Python found")

set(PYTHON_NUMERIC_VERSION 31001)

set(NUMPY_FOUND TRUE CACHE BOOL "Numpy found successfully" FORCE)
execute_process(COMMAND ${PYTHON_EXECUTABLE} -c
    "from numpy.distutils.misc_util import get_numpy_include_dirs; print get_numpy_include_dirs()[0]"
    OUTPUT_VARIABLE NUMPY_INCLUDE_DIR
    OUTPUT_STRIP_TRAILING_WHITESPACE)
set(NUMPY_INCLUDE_DIR ${NUMPY_INCLUDE_DIR} CACHE PATH "Numpy inc directory" FORCE)

