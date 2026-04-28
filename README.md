# CUDA at Scale for the Enterprise - Course Project

## Overview
This project implements a high-performance batch image processing pipeline using NVIDIA Performance Primitives (NPP). It is designed to run efficiently on GPU hardware, reading hundreds of images, applying an RGB-to-Grayscale conversion using NPP (`nppiRGBToGray_8u_C3C1R`), and saving the results.

This project uses the USC Viterbi SIPI Image Database (Misc Volume) as its dataset. 

## Code Organization

`bin/`
This folder holds the compiled `batchProcessNPP` executable.

`data/`
Contains the dataset. `data/input` stores the raw downloaded PNG images, and `data/output` stores the processed grayscale images.

`include/`
Contains standard lightweight image I/O headers (`stb_image.h` and `stb_image_write.h`) to read and write images without requiring complex external library installations (like FreeImage or libtiff) which might be unavailable or complex to set up in the Coursera Lab environment.

`src/`
Contains the source code (`batchProcessNPP.cu`).

`run.sh`
The primary execution script. It automatically prepares the dataset, compiles the CUDA program, and runs the batch processing.

`Makefile`
Build script that compiles the source code using `nvcc` and links against the CUDA and NPP libraries.

## Execution in Coursera Lab

To run the full pipeline (download data, build, and process):

```bash
cd CUDA_Project
chmod +x run.sh
./run.sh
```

Alternatively, you can run the steps manually:
```bash
# Build project
make

# Execute batch processing
./bin/batchProcessNPP data/input data/output
```
