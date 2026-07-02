#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OPENCV_SRC="${OPENCV_SRC:-$ROOT_DIR/opencv}"
BUILD_DIR="${BUILD_DIR:-$ROOT_DIR/build-opencv}"
INSTALL_DIR="${INSTALL_DIR:-$ROOT_DIR/dist/opencv}"
JOBS="${JOBS:-$(nproc)}"
WITH_VULKAN="${WITH_VULKAN:-ON}"

# Required by:
# - PaddleOCR-ncnn-CPP: core/imgproc/imgcodecs via opencv.hpp, imread/imwrite, geometry and image ops
# - flow-test: core/imgproc via cgo pkg-config opencv4
MODULES="${MODULES:-core,imgproc,imgcodecs}"

if [[ ! -f "$OPENCV_SRC/CMakeLists.txt" ]]; then
  echo "OpenCV source not found: $OPENCV_SRC" >&2
  exit 1
fi

cmake -S "$OPENCV_SRC" -B "$BUILD_DIR" -G Ninja \
  -D CMAKE_BUILD_TYPE=Release \
  -D CMAKE_INSTALL_PREFIX="$INSTALL_DIR" \
  -D CMAKE_POSITION_INDEPENDENT_CODE=ON \
  -D BUILD_LIST="$MODULES" \
  -D BUILD_SHARED_LIBS=ON \
  -D BUILD_ZLIB=ON \
  -D BUILD_JPEG=ON \
  -D BUILD_PNG=ON \
  -D ENABLE_CCACHE=OFF \
  -D OPENCV_GENERATE_PKGCONFIG=ON \
  -D BUILD_EXAMPLES=OFF \
  -D BUILD_TESTS=OFF \
  -D BUILD_PERF_TESTS=OFF \
  -D BUILD_opencv_apps=OFF \
  -D BUILD_opencv_gapi=OFF \
  -D BUILD_JAVA=OFF \
  -D BUILD_opencv_python2=OFF \
  -D BUILD_opencv_python3=OFF \
  -D WITH_IPP=OFF \
  -D WITH_OPENCL=OFF \
  -D WITH_ADE=OFF \
  -D WITH_AVIF=OFF \
  -D WITH_OPENEXR=OFF \
  -D WITH_OPENJPEG=OFF \
  -D WITH_JASPER=OFF \
  -D WITH_TIFF=OFF \
  -D WITH_WEBP=OFF \
  -D WITH_FFMPEG=OFF \
  -D WITH_GSTREAMER=OFF \
  -D WITH_GTK=OFF \
  -D WITH_VULKAN="$WITH_VULKAN" \
  -D WITH_V4L=OFF

if [[ "$WITH_VULKAN" == "ON" ]] && ! grep -q '^HAVE_VULKAN=1$' "$BUILD_DIR/CMakeVars.txt"; then
  echo "Vulkan support is required but OpenCV did not enable it." >&2
  exit 1
fi

cmake --build "$BUILD_DIR" --parallel "$JOBS"
cmake --install "$BUILD_DIR"
