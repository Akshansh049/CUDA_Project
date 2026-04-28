#!/bin/bash

echo "Starting CUDA Batch Image Processing Pipeline..."

# 1. Prepare Dataset
echo "Step 1: Installing dependencies, downloading, and preparing dataset..."
python3 -m pip install Pillow
python3 setup_dataset.py

# 2. Build the CUDA executable
echo "Step 2: Compiling CUDA source code..."
make clean
make

# 3. Create output directory if it doesn't exist
mkdir -p data/output

# 4. Run the executable
echo "Step 3: Running batch processing..."
./bin/batchProcessNPP data/input data/output

echo "Pipeline finished!"
