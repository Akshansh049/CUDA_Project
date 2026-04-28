import urllib.request
import zipfile
import os
import glob
from PIL import Image

def download_file(url, dest):
    req = urllib.request.Request(url, headers={'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)'})
    with urllib.request.urlopen(req) as response, open(dest, 'wb') as out_file:
        out_file.write(response.read())

def main():
    url = 'https://sipi.usc.edu/database/misc.zip'
    zip_path = 'misc.zip'
    extract_dir = 'data'
    input_dir = os.path.join('data', 'input')

    if not os.path.exists(input_dir):
        os.makedirs(input_dir)

    print("Downloading SIPI dataset...")
    if not os.path.exists(zip_path):
        try:
            download_file(url, zip_path)
        except Exception as e:
            print(f"Failed to download from USC. Error: {e}")
            print("Attempting to download a fallback dataset...")
            # Fallback to a small generic image download if USC server blocks Coursera Lab
            fallback_url = 'https://raw.githubusercontent.com/image-rs/image/master/tests/images/png/test.png'
            req = urllib.request.Request(fallback_url, headers={'User-Agent': 'Mozilla/5.0'})
            with urllib.request.urlopen(req) as response, open(os.path.join(input_dir, 'fallback_test.png'), 'wb') as out_file:
                out_file.write(response.read())
            print("Fallback dataset downloaded.")
            return
    
    print("Extracting dataset...")
    with zipfile.ZipFile(zip_path, 'r') as zip_ref:
        zip_ref.extractall(extract_dir)

    print("Converting images to PNG format...")
    # The misc.zip extracts into a 'misc' folder
    misc_folder = os.path.join(extract_dir, 'misc')
    
    if os.path.exists(misc_folder):
        tiff_files = glob.glob(os.path.join(misc_folder, '*.tiff'))
        for tiff_file in tiff_files:
            try:
                with Image.open(tiff_file) as img:
                    # Convert to RGB in case some are RGBA or other modes
                    img = img.convert('RGB')
                    base_name = os.path.splitext(os.path.basename(tiff_file))[0]
                    png_path = os.path.join(input_dir, f"{base_name}.png")
                    img.save(png_path, 'PNG')
            except Exception as e:
                print(f"Error converting {tiff_file}: {e}")
        print(f"Successfully converted {len(tiff_files)} images to {input_dir}.")
    else:
        print(f"Warning: Extracted folder {misc_folder} not found.")

if __name__ == '__main__':
    main()
