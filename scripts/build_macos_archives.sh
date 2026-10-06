#!/usr/bin/env bash
# Builds the static macOS (arm64) PCL archives vendored in gamma-slam-cpp/external/pcl/lib/mac.
# Usage: scripts/build_macos_archives.sh <gamma-slam-cpp>/external/boost/include [build-dir]
#   (or export GAMMA_BOOST_INCLUDE); CONFIGURE_ONLY=1 stops before compiling; JOBS defaults to 2.
# Output: <build-dir>/lib/libpcl_*.a -- copy them into gamma-slam-cpp external/pcl/lib/mac.
# libflann_cpp.a and liblz4.a are NOT produced here; keep the ones already vendored there.
set -euo pipefail

SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BOOST_INC="${1:-${GAMMA_BOOST_INCLUDE:-}}"
BUILD_DIR="${2:-$SRC/build-macos-1.14}"
if [ ! -f "$BOOST_INC/boost/version.hpp" ]; then
  echo "missing: '$BOOST_INC/boost/version.hpp'" >&2
  echo "usage: $0 <gamma-slam-cpp>/external/boost/include [build dir]  (or GAMMA_BOOST_INCLUDE)" >&2
  exit 2
fi
BOOST_INC="$(cd "$BOOST_INC" && pwd)"

# Default symbol visibility on purpose: hidden-visibility archives (the iOS setting) made
# flann::any::cast throw bad_any_cast inside libgamma_slam_cpp.dylib. A non-default CMAKE_CXX_FLAGS
# also keeps PCL from adding -march=native / -ffloat-store, so the archives run on any Apple Silicon Mac.
FLAGS="-fvisibility=default"
CCACHE="$(command -v ccache || true)" # empty means no compiler launcher

cmake -S "$SRC" -B "$BUILD_DIR" \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_CXX_STANDARD=14 \
  -DCMAKE_OSX_ARCHITECTURES=arm64 \
  -DCMAKE_OSX_DEPLOYMENT_TARGET=15.0 \
  -DCMAKE_C_FLAGS="$FLAGS" \
  -DCMAKE_CXX_FLAGS="$FLAGS" \
  -DCMAKE_C_COMPILER_LAUNCHER="$CCACHE" \
  -DCMAKE_CXX_COMPILER_LAUNCHER="$CCACHE" \
  -DPCL_SHARED_LIBS=OFF \
  -DBUILD_SHARED_LIBS=OFF \
  -DBoost_INCLUDE_DIRS="$BOOST_INC" \
  -DBUILD_2d=ON \
  -DBUILD_common=ON \
  -DBUILD_features=ON \
  -DBUILD_filters=ON \
  -DBUILD_geometry=ON \
  -DBUILD_io=ON \
  -DBUILD_kdtree=ON \
  -DBUILD_keypoints=ON \
  -DBUILD_ml=ON \
  -DBUILD_octree=ON \
  -DBUILD_registration=ON \
  -DBUILD_sample_consensus=ON \
  -DBUILD_search=ON \
  -DBUILD_segmentation=ON \
  -DBUILD_stereo=ON \
  -DBUILD_tracking=ON \
  -DBUILD_surface=OFF \
  -DBUILD_apps=OFF \
  -DBUILD_benchmarks=OFF \
  -DBUILD_examples=OFF \
  -DBUILD_tools=OFF \
  -DBUILD_outofcore=OFF \
  -DBUILD_people=OFF \
  -DBUILD_recognition=OFF \
  -DBUILD_simulation=OFF \
  -DBUILD_visualization=OFF \
  -DBUILD_global_tests=OFF \
  -DBUILD_tests=OFF \
  -DBUILD_CUDA=OFF \
  -DBUILD_GPU=OFF \
  -DWITH_OPENMP=OFF \
  -DWITH_QHULL=OFF \
  -DWITH_VTK=OFF \
  -DWITH_PNG=OFF \
  -DWITH_LIBUSB=OFF \
  -DWITH_OPENGL=OFF \
  -DWITH_PCAP=OFF \
  -DWITH_CUDA=OFF \
  -DWITH_QT=OFF \
  -DWITH_DOCS=OFF

if [ -n "${CONFIGURE_ONLY:-}" ]; then exit 0; fi
nice -n 19 cmake --build "$BUILD_DIR" -j"${JOBS:-2}"
echo "archives: $BUILD_DIR/lib"
