#!/bin/bash

set -e  # Exit on any error

# Define colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${BLUE}=== Installing aitocoder.chat CLI for macOS ===${NC}"

# Get the directory where this script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
INSTALL_DIR="$HOME/.aitocoder"

# Check if environment is already installed
if [ -d "$INSTALL_DIR" ]; then
    echo -e "${BLUE}Existing installation detected at $INSTALL_DIR${NC}"
    read -p "Would you like to remove it and install fresh? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo "Removing existing installation..."
        rm -rf "$INSTALL_DIR"
    else
        echo -e "${GREEN}Keeping existing installation.${NC}"
        echo -e "${BLUE}You can run aitocoder.chat now if it's already set up.${NC}"
        exit 0
    fi
fi

# Create installation directory
echo "Creating installation directory at $INSTALL_DIR..."
mkdir -p "$INSTALL_DIR"

# Extract the packed environment
echo "Extracting environment..."
tar -xzf "$SCRIPT_DIR/aitocoder_macos.tar.gz" -C "$INSTALL_DIR"

# Run conda-unpack to fix paths
echo "Configuring environment..."

# First, fix the conda-unpack script itself
if [ -f "$INSTALL_DIR/bin/conda-unpack" ]; then
    # Fix conda-unpack shebang if it uses env python
    if grep -q "^#\!.*/env python" "$INSTALL_DIR/bin/conda-unpack"; then
        echo "  - Fixing conda-unpack shebang"
        sed -i.bak "1 s|^#\!.*/env python.*$|#\!$INSTALL_DIR/bin/python|" "$INSTALL_DIR/bin/conda-unpack"
        rm -f "$INSTALL_DIR/bin/conda-unpack.bak"
    fi
fi

# Now run conda-unpack
"$INSTALL_DIR/bin/conda-unpack"

# Fix shebang lines in Python scripts
echo "Fixing executable scripts..."
find "$INSTALL_DIR/bin" -type f -not -path "*/\.*" -perm +111 -exec grep -l "^#\!" {} \; | while read -r file; do
    if grep -q "^#\!.*/env python" "$file"; then
        echo "  - Fixing shebang in $file"
        sed -i.bak "1 s|^#\!.*/env python.*$|#\!$INSTALL_DIR/bin/python|" "$file"
        rm -f "${file}.bak"
    fi
done

# Ensure aitocoder.chat is executable in the extracted environment
if [ -f "$INSTALL_DIR/bin/aitocoder.chat" ]; then
    chmod +x "$INSTALL_DIR/bin/aitocoder.chat"
fi

# Create launcher script in user's bin directory
LAUNCHER_DIR="$HOME/.local/bin"
mkdir -p "$LAUNCHER_DIR"

cat > "$LAUNCHER_DIR/aitocoder.chat" << EOL
#!/bin/bash
# Launcher for aitocoder.chat

# Get the aitocoder installation directory
INSTALL_DIR="$HOME/.aitocoder"

# Check if the environment exists
if [ ! -d "\$INSTALL_DIR" ]; then
    echo "Error: aitocoder environment not found at \$INSTALL_DIR"
    echo "Please run the installer again."
    exit 1
fi

# Activate the conda environment
source "\$INSTALL_DIR/bin/activate"

# Run the command with all arguments passed through
exec aitocoder.chat "\$@"
EOL

# Make the launcher executable
chmod +x "$LAUNCHER_DIR/aitocoder.chat"

# Check if ~/.local/bin is in PATH
if [[ ":$PATH:" != *":$HOME/.local/bin:"* ]]; then
    echo -e "${BLUE}Adding launcher directory to PATH...${NC}"
    
    # Determine which shell configuration file to use
    SHELL_CONFIG=""
    if [ -f "$HOME/.zshrc" ]; then
        # Default shell on modern macOS is zsh
        SHELL_CONFIG="$HOME/.zshrc"
    elif [ -f "$HOME/.bash_profile" ]; then
        # macOS traditionally used .bash_profile instead of .bashrc
        SHELL_CONFIG="$HOME/.bash_profile"
    elif [ -f "$HOME/.bashrc" ]; then
        SHELL_CONFIG="$HOME/.bashrc"
    fi
    
    if [ -n "$SHELL_CONFIG" ]; then
        echo -e "\n# Added by aitocoder installer" >> "$SHELL_CONFIG"
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
