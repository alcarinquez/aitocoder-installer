#!/bin/bash

set -e  # Exit on any error

# Define colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}=== Installing aitocoder.chat CLI for Linux ===${NC}"

# Get the directory where this script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
INSTALL_DIR="$HOME/.aitocoder"

# Create installation directory
echo "Creating installation directory at $INSTALL_DIR..."
mkdir -p "$INSTALL_DIR"

# Extract the packed environment
echo "Extracting environment..."
tar -xzf "$SCRIPT_DIR/aitocoder_linux.tar.gz" -C "$INSTALL_DIR"

# Run conda-unpack to fix paths
echo "Configuring environment..."
"$INSTALL_DIR/bin/conda-unpack"

# Create launcher script in user's bin directory
LAUNCHER_DIR="$HOME/.local/bin"
mkdir -p "$LAUNCHER_DIR"

cat > "$LAUNCHER_DIR/aitocoder.chat" << 'EOL'
#!/bin/bash
# Launcher for aitocoder.chat

# Get the aitocoder installation directory
INSTALL_DIR="$HOME/.aitocoder"

# Activate the conda environment
source "$INSTALL_DIR/bin/activate"

# Run the command with all arguments passed through
exec aitocoder.chat "$@"
EOL

# Make the launcher executable
chmod +x "$LAUNCHER_DIR/aitocoder.chat"

# Check if ~/.local/bin is in PATH
if [[ ":$PATH:" != *":$HOME/.local/bin:"* ]]; then
    echo -e "${BLUE}Adding launcher directory to PATH...${NC}"
    
    # Determine which shell configuration file to use
    SHELL_CONFIG=""
    if [ -f "$HOME/.bashrc" ]; then
        SHELL_CONFIG="$HOME/.bashrc"
    elif [ -f "$HOME/.zshrc" ]; then
        SHELL_CONFIG="$HOME/.zshrc"
    fi
    
    if [ -n "$SHELL_CONFIG" ]; then
        echo -e "\n# Added by Aitocoder installer" >> "$SHELL_CONFIG"
        echo "export PATH=\"\$HOME/.local/bin:\$PATH\"" >> "$SHELL_CONFIG"
        echo -e "${GREEN}Added $LAUNCHER_DIR to your PATH in $SHELL_CONFIG${NC}"
        echo -e "Please run: ${BLUE}source $SHELL_CONFIG${NC} to update your current terminal session."
    else
        echo -e "${BLUE}Please add this line to your shell configuration file:${NC}"
        echo "export PATH=\"\$HOME/.local/bin:\$PATH\""
    fi
fi

echo -e "${GREEN}=== Installation Complete! ===${NC}"
echo -e "You can now run: ${BLUE}aitocoder.chat${NC} from your terminal."
echo -e "If it doesn't work in your current terminal, try: ${BLUE}source $SHELL_CONFIG${NC} or open a new terminal."
