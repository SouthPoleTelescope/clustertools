set(HDF5_FOUND TRUE CACHE BOOL "HDF5 found")
set(HDF5_INCLUDE_DIR $ENV{SROOT}/include CACHE PATH "Path to HDF5 headers")
set(HDF5_LIBRARIES "$ENV{SROOT}/lib/libhdf5.so" "$ENV{SROOT}/lib/libhdf5_hl.so" CACHE PATH "HDF5 libraries")

