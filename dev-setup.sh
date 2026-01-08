#!/bin/bash

set -e

echo "==========================================="
echo "   Development Environment Setup Script"
echo "==========================================="

# 1. Environment Selection
echo ""
echo "1. Select Environment Type:"
echo "----------------------------------------------------------------"
echo "   Each environment is configured as follows:"
echo ""
echo "   * minimal    : CPU Base / CLI only"
echo "                  (Minimal setup. Runs 'sleep infinity' for VSCode connection)"
echo "   * minimal-gpu: GPU Base / CLI only"
echo "                  (GPU support. Runs 'sleep infinity' for VSCode connection)"
echo "   * spyder     : CPU Base / GUI included"
echo "                  (Installs & runs Spyder IDE + Fcitx5 Japanese IME)"
echo "   * spyder-gpu : GPU Base / GUI included"
echo "                  (GPU support + Spyder IDE + Fcitx5 Japanese IME)"
echo "----------------------------------------------------------------"

PS3="Please enter your choice (1-4): "
options=("minimal" "minimal-gpu" "spyder" "spyder-gpu")
select opt in "${options[@]}"
do
    if [[ " ${options[@]} " =~ " ${opt} " ]]; then
        SELECTED_ENV=$opt
        break
    else
        echo "Invalid option. Please try again."
    fi
done
echo "-> Selected Environment: $SELECTED_ENV"

# 2. Python Version Input
echo ""
read -p "2. Enter Python Version [default: 3.12.*]: " input_python
PYTHON_VERSION=${input_python:-"3.12.*"}
echo "-> Python Version: $PYTHON_VERSION"

# 3. CPU Base Image
echo ""
read -p "3. Enter CPU Base Image [default: ubuntu:24.04]: " input_cpu_image
CPU_IMAGE=${input_cpu_image:-"ubuntu:24.04"}
echo "-> CPU Base Image: $CPU_IMAGE"

# 4. GPU Base Image
echo ""
read -p "4. Enter GPU Base Image [default: nvidia/cuda:12.9.1-cudnn-devel-ubuntu24.04]: " input_gpu_image
GPU_IMAGE=${input_gpu_image:-"nvidia/cuda:12.9.1-cudnn-devel-ubuntu24.04"}
echo "-> GPU Base Image: $GPU_IMAGE"

# 5. Deploy the development environment locally
echo ""
echo "--- Setting up directories ---"

# 5.1 git clone
if [ -d "Ubuntu" ]; then
    echo "Warning: 'Ubuntu' directory already exists. Removing it to clone fresh..."
    rm -rf Ubuntu
fi
echo "Cloning repository..."
git clone https://github.com/rentaropy/Ubuntu.git

# 5.2 mv Ubuntu/dev ./
if [ -d "dev" ]; then
    echo "Warning: 'dev' directory already exists. Please remove it first (rm -rf dev)."
    exit 1
fi
echo "Moving 'dev' directory..."
mv Ubuntu/dev ./

# 5.3 rm -rf Ubuntu
echo "Cleaning up..."
rm -rf Ubuntu

# 5.4 cd dev
echo "Entering 'dev' directory..."
cd dev

# 6. Append to the environment variable file .env
echo ""
echo "--- Configuring .env ---"
if [ -f ".env" ]; then
    if [ -n "$(tail -c 1 .env)" ]; then
        echo "" >> .env
    fi
    echo "ENVIRONMENT=$SELECTED_ENV" >> .env
    echo "Updated .env with ENVIRONMENT=$SELECTED_ENV"
else
    echo "ENVIRONMENT=$SELECTED_ENV" > .env
    echo "Created .env with ENVIRONMENT=$SELECTED_ENV"
fi

# 7. pixi.toml Configuration
echo ""
echo "--- Configuring pixi.toml ---"
PIXI_FILE="dev/workspace/pixi.toml"

if [ -f "$PIXI_FILE" ]; then
    sed -i "/\[dependencies\]/a python = \"$PYTHON_VERSION\"" "$PIXI_FILE"
    echo "Added python = \"$PYTHON_VERSION\" to $PIXI_FILE"
else
    echo "Error: $PIXI_FILE not found in $(pwd)"
    exit 1
fi

# 8. Dockerfile Configuration
echo ""
echo "--- Configuring Dockerfile ---"
DOCKERFILE="dev/Dockerfile"

if [ -f "$DOCKERFILE" ]; then
    sed -i "s|FROM .* AS base-cpu|FROM $CPU_IMAGE AS base-cpu|" "$DOCKERFILE"
    echo "Updated base-cpu image to $CPU_IMAGE"
    sed -i "s|FROM .* AS base-gpu|FROM $GPU_IMAGE AS base-gpu|" "$DOCKERFILE"
    echo "Updated base-gpu image to $GPU_IMAGE"
else
    echo "Error: $DOCKERFILE not found in $(pwd)"
    exit 1
fi

echo ""
echo "==========================================="
echo "   Setup Complete!"
echo "==========================================="
echo "Please follow the steps below to start your environment:"
echo ""

# 9. Directory navigation
echo "1. Navigate to the directory:"
echo "   cd dev/"
echo ""

# 10. Startup command
echo "2. Start the container:"
echo "   docker compose --profile dev up"
echo "   (Note: Press "d" to detach container.)"
echo ""

# 11. Termination Method (Branches based on environment)
echo "3. To Stop/Exit:"
if [[ "$SELECTED_ENV" == "spyder" || "$SELECTED_ENV" == "spyder-gpu" ]]; then
    echo "   - Simply close the Spyder GUI window."
else
    echo "   - Open a new terminal and run:"
    echo "     docker compose --profile dev down"
fi
echo ""