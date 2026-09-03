import requests
import os
import sys

# Dandi archive API URL for Dandiset 000946 (Falcon H1)
DANDI_API_BASE = "https://api.dandiarchive.org/api"
DANDISET_ID = "000946"
VERSION = "draft"
TARGET_FILE = "data/falcon_h1.nwb"

def download_sample_data():
    os.makedirs(os.path.dirname(TARGET_FILE), exist_ok=True)
    
    # 1. Fetch asset list
    print(f"Fetching asset list for Dandiset {DANDISET_ID}...")
    assets_url = f"{DANDI_API_BASE}/dandisets/{DANDISET_ID}/versions/{VERSION}/assets/"
    response = requests.get(assets_url)
    response.raise_for_status()
    
    data = response.json()
    assets = data.get('results', [])
    if not assets:
        print("No assets found in Dandiset.")
        sys.exit(1)
        
    # We'll pick the first valid NWB file we see.
    # From earlier tests, sub-BH494/sub-BH494_ecephys.nwb is about 3MB.
    asset = next((a for a in assets if a['path'].endswith('.nwb')), None)
    if not asset:
        print("No NWB file found.")
        sys.exit(1)
        
    asset_id = asset['asset_id']
    path = asset['path']
    size = asset['size']
    
    print(f"Found NWB Asset: {path} (Size: {size / 1024 / 1024:.2f} MB)")
    print(f"Asset ID: {asset_id}")
    
    # 2. Get download URL
    download_api_url = f"{assets_url}{asset_id}/download/"
    print(f"Resolving download URL...")
    # The download endpoint usually redirects to S3. requests handles redirects automatically.
    
    # 3. Download the file
    print(f"Downloading to {TARGET_FILE}...")
    with requests.get(download_api_url, stream=True) as r:
        r.raise_for_status()
        downloaded = 0
        with open(TARGET_FILE, 'wb') as f:
            for chunk in r.iter_content(chunk_size=8192):
                if chunk:
                    f.write(chunk)
                    downloaded += len(chunk)
                    # Simple progress
                    if size > 0:
                        progress = (downloaded / size) * 100
                        print(f"\rProgress: {progress:.1f}%", end="")
    print("\nDownload complete!")

if __name__ == "__main__":
    download_sample_data()
