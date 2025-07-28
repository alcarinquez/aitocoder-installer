# aitocoder-installer
A collection of multi-platform installer scripts for aitocoder-cli. Instruction manual included.  
Contact: Maxwell Zhou <maxwell.zhou@aitocoder.com>

# Instruction Manual

## General Packing Rules

1. Create a new conda environment on the target operating system with python 3.11  
`conda create -n aitocoder python=3.11`

2. Activate the conda environment and then install the .whl  
`conda activate aitocoder`  
`pip install aitocoder_cli-1.0.1-py3-none-any.whl`

3. Use conda pack to package the entire environment into a compressed folder  
`conda deactivate`  
`conda pack --name aitocoder --output aitocoder_linux.tar.gz`

4. (USER) Run the script according to the system version  
`./aitocoder_linux.sh` (bash)  
OR `.\aitocoder_win.bat` (powershell)

## Debian Packaging

1. Create the following folder structure

<pre>
aitocoder-deepin/
    ├── DEBIAN/
    │   └── control
    └── usr/
        ├── bin/
        │   └── intsall-aitocoder           # (wrapper script to run your .sh)
        └── share/
            └── aitocoder/
                ├── aitocoder_linux.sh      # (your installer script)
                └── aitocoder_linux.tar.gz  # (your packed conda env)
</pre>

2. Run packaging command that creates aitocoder-deepin.deb  
`dpkg-deb --build aitocoder-deepin`

3. The .deb file is ready to distribute

4. (USER) In a linux terminal, run the package installation command  
`sudo dpkg -i aitocoder-deepin.deb`

5. (USER) In a linux terminal, run the generated install script  
`install-aitocoder`
