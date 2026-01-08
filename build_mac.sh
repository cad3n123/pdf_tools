#!/bin/bash
set -e

echo "==== Master PDF Tool Builder (macOS) ===="

# 1. Setup paths
STARTDIR="$(pwd)"
TEMPDIR="$STARTDIR/master_pdf_build_temp"
SCRIPT_NAME="master_pdf_tool.py"

if [[ ! -f "$STARTDIR/$SCRIPT_NAME" ]]; then
    echo "ERROR: $SCRIPT_NAME not found in current directory."
    echo "Please save the Python code provided into this folder as '$SCRIPT_NAME'"
    exit 1
fi

# 2. Clean up previous temp folder
if [[ -d "$TEMPDIR" ]]; then
    rm -rf "$TEMPDIR"
fi
mkdir -p "$TEMPDIR"
cp "$SCRIPT_NAME" "$TEMPDIR/"
cd "$TEMPDIR"

# 3. Find Python
PYTHON_EXEC=""
echo "Looking for Python..."
while IFS= read -r path; do
    if [[ "$path" != *"anaconda"* && "$path" != *"conda"* && "$path" != *"Cellar"* ]]; then
        PYTHON_EXEC="$path"
        break
    fi
done < <(which -a python3 || true)

if [[ -z "$PYTHON_EXEC" ]]; then
    echo "No valid python3 found. Installing with Homebrew..."
    if ! command -v brew &>/dev/null; then
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" </dev/null
    fi
    brew install python
    PYTHON_EXEC="$(which python3)"
fi

# 4. Create venv and install dependencies
echo "Creating virtual environment..."
"$PYTHON_EXEC" -m venv venv
source venv/bin/activate

echo "Installing dependencies..."
pip install --upgrade pip
# pymupdf is required for PNG conversion
pip install PyQt5 PyPDF2 pymupdf py2app

# 5. Write setup.py for py2app
cat <<EOF > setup.py
from setuptools import setup

APP = ['$SCRIPT_NAME']
OPTIONS = {
    'argv_emulation': True,
    'packages': ['PyQt5', 'PyPDF2', 'fitz'], 
    'iconfile': '' 
}

setup(
    app=APP,
    options={'py2app': OPTIONS},
    setup_requires=['py2app'],
)
EOF

# 6. Build the app
echo "Building .app..."
python setup.py py2app

# 7. Move result and clean up
mv dist/*.app "$STARTDIR"
cd "$STARTDIR"
rm -rf "$TEMPDIR"

echo
echo "==== Build Complete ===="
echo "Your app is ready at: $STARTDIR/MasterPDFTool.app"