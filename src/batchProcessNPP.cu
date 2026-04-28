#include <iostream>
#include <string>
#include <vector>
#include <dirent.h>

#define STB_IMAGE_IMPLEMENTATION
#include "stb_image.h"

#define STB_IMAGE_WRITE_IMPLEMENTATION
#include "stb_image_write.h"

#include <cuda_runtime.h>
#include <nppi.h>

// Helper to check for CUDA errors
#define checkCudaErrors(val) check_cuda((val), #val, __FILE__, __LINE__)
void check_cuda(cudaError_t result, char const *const func, const char *const file, int const line) {
    if (result) {
        std::cerr << "CUDA error = " << static_cast<unsigned int>(result) << " at " <<
            file << ":" << line << " '" << func << "' \n";
        cudaDeviceReset();
        exit(99);
    }
}

// Helper to check for NPP errors
#define checkNppErrors(val) check_npp((val), #val, __FILE__, __LINE__)
void check_npp(NppStatus result, char const *const func, const char *const file, int const line) {
    if (result != NPP_SUCCESS) {
        std::cerr << "NPP error = " << static_cast<int>(result) << " at " <<
            file << ":" << line << " '" << func << "' \n";
        exit(99);
    }
}

void processImageNPP(const std::string& input_path, const std::string& output_path) {
    int width, height, channels;
    // Load image as 3 channels (RGB)
    unsigned char* h_src = stbi_load(input_path.c_str(), &width, &height, &channels, 3);
    
    if (!h_src) {
        std::cerr << "Failed to load image: " << input_path << std::endl;
        return;
    }

    // Allocate memory on GPU
    Npp8u *d_src, *d_dst;
    int src_pitch, dst_pitch;

    d_src = nppiMalloc_8u_C3(width, height, &src_pitch);
    d_dst = nppiMalloc_8u_C1(width, height, &dst_pitch);

    if (!d_src || !d_dst) {
        std::cerr << "Failed to allocate device memory." << std::endl;
        stbi_image_free(h_src);
        return;
    }

    // Copy image from host to device
    checkCudaErrors(cudaMemcpy2D(d_src, src_pitch, h_src, width * 3 * sizeof(Npp8u), 
                                 width * 3 * sizeof(Npp8u), height, cudaMemcpyHostToDevice));

    // Perform RGB to Grayscale conversion
    NppiSize roi = {width, height};
    checkNppErrors(nppiRGBToGray_8u_C3C1R(d_src, src_pitch, d_dst, dst_pitch, roi));

    // Allocate memory on host for the result
    unsigned char* h_dst = new unsigned char[width * height];

    // Copy the result back from device to host
    checkCudaErrors(cudaMemcpy2D(h_dst, width * sizeof(Npp8u), d_dst, dst_pitch, 
                                 width * sizeof(Npp8u), height, cudaMemcpyDeviceToHost));

    // Save the result image
    if (!stbi_write_png(output_path.c_str(), width, height, 1, h_dst, width)) {
        std::cerr << "Failed to write output image: " << output_path << std::endl;
    } else {
        std::cout << "Successfully processed: " << output_path << std::endl;
    }

    // Cleanup
    nppiFree(d_src);
    nppiFree(d_dst);
    delete[] h_dst;
    stbi_image_free(h_src);
}

int main(int argc, char** argv) {
    if (argc != 3) {
        std::cerr << "Usage: " << argv[0] << " <input_directory> <output_directory>" << std::endl;
        return 1;
    }

    std::string input_dir = argv[1];
    std::string output_dir = argv[2];

    DIR* dir;
    struct dirent* ent;
    
    // Open input directory
    if ((dir = opendir(input_dir.c_str())) != NULL) {
        while ((ent = readdir(dir)) != NULL) {
            std::string filename(ent->d_name);
            // Process only files with common image extensions (specifically testing for PNG)
            if (filename.length() > 4 && 
                (filename.substr(filename.length() - 4) == ".png" || 
                 filename.substr(filename.length() - 4) == ".jpg")) {
                
                std::string input_path = input_dir + "/" + filename;
                std::string output_path = output_dir + "/" + filename;
                
                std::cout << "Processing: " << filename << " ..." << std::endl;
                processImageNPP(input_path, output_path);
            }
        }
        closedir(dir);
    } else {
        std::cerr << "Could not open input directory: " << input_dir << std::endl;
        return EXIT_FAILURE;
    }

    std::cout << "Batch processing complete." << std::endl;
    return EXIT_SUCCESS;
}
