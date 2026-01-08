import sys
import os
import subprocess

# --- Auto-Install Dependencies ---
def install_package(package):
    try:
        subprocess.check_call(
            [sys.executable, "-m", "pip", "install", package],
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL
        )
    except subprocess.CalledProcessError:
        print(f"Failed to install {package}")

# Check and install PyQt5
try:
    import PyQt5
except ImportError:
    install_package("PyQt5")
    import PyQt5

# Check and install PyPDF2 (for combining/reversing)
try:
    import PyPDF2
except ImportError:
    install_package("PyPDF2")
    import PyPDF2

# Check and install PyMuPDF (for PDF to PNG)
try:
    import fitz  # This is the module name for PyMuPDF
except ImportError:
    install_package("pymupdf")
    import fitz

from PyQt5.QtWidgets import (QApplication, QWidget, QVBoxLayout, QPushButton, 
                             QLabel, QFileDialog, QMessageBox, QDesktopWidget)
from PyQt5.QtCore import Qt

class MasterPDFTool(QWidget):
    def __init__(self):
        super().__init__()
        self.initUI()

    def initUI(self):
        layout = QVBoxLayout()
        layout.setSpacing(15)
        layout.setContentsMargins(30, 30, 30, 30)

        # Title
        title = QLabel("Master PDF Tool")
        title.setAlignment(Qt.AlignCenter)
        title.setStyleSheet("font-size: 18px; font-weight: bold; margin-bottom: 10px;")
        layout.addWidget(title)

        # Button 1: Combine PDFs
        self.btn_combine = QPushButton("Combine Multiple PDFs")
        self.btn_combine.setMinimumHeight(40)
        self.btn_combine.clicked.connect(self.combine_pdfs)
        layout.addWidget(self.btn_combine)

        # Button 2: Reverse PDF
        self.btn_reverse = QPushButton("Reverse PDF Order")
        self.btn_reverse.setMinimumHeight(40)
        self.btn_reverse.clicked.connect(self.reverse_pdf)
        layout.addWidget(self.btn_reverse)

        # Button 3: PDF to PNG
        self.btn_png = QPushButton("Convert PDF to PNGs")
        self.btn_png.setMinimumHeight(40)
        self.btn_png.clicked.connect(self.pdf_to_png)
        layout.addWidget(self.btn_png)

        self.setLayout(layout)
        self.setWindowTitle('Master PDF Tool')
        self.resize(350, 250)
        self.center()

    def center(self):
        qr = self.frameGeometry()
        cp = QDesktopWidget().availableGeometry().center()
        qr.moveCenter(cp)
        self.move(qr.topLeft())

    # --- Feature 1: Combine PDFs ---
    def combine_pdfs(self):
        files, _ = QFileDialog.getOpenFileNames(self, "Select PDFs to Merge", "", "PDF Files (*.pdf)")
        if not files:
            return

        save_path, _ = QFileDialog.getSaveFileName(self, "Save Merged PDF", "merged.pdf", "PDF Files (*.pdf)")
        if not save_path:
            return
        
        if not save_path.lower().endswith(".pdf"):
            save_path += ".pdf"

        try:
            merger = PyPDF2.PdfMerger()
            for pdf in files:
                merger.append(pdf)
            merger.write(save_path)
            merger.close()
            QMessageBox.information(self, "Success", f"Saved merged PDF to:\n{save_path}")
        except Exception as e:
            QMessageBox.critical(self, "Error", f"Failed to merge PDFs:\n{e}")

    # --- Feature 2: Reverse PDF ---
    def reverse_pdf(self):
        input_path, _ = QFileDialog.getOpenFileName(self, "Select PDF to Reverse", "", "PDF Files (*.pdf)")
        if not input_path:
            return

        save_path, _ = QFileDialog.getSaveFileName(self, "Save Reversed PDF", "reversed.pdf", "PDF Files (*.pdf)")
        if not save_path:
            return

        try:
            reader = PyPDF2.PdfReader(input_path)
            writer = PyPDF2.PdfWriter()

            # Add pages in reverse order
            for page in reversed(reader.pages):
                writer.add_page(page)

            with open(save_path, "wb") as f:
                writer.write(f)
            
            QMessageBox.information(self, "Success", f"Saved reversed PDF to:\n{save_path}")
        except Exception as e:
            QMessageBox.critical(self, "Error", f"Failed to reverse PDF:\n{e}")

    # --- Feature 3: PDF to PNG ---
    def pdf_to_png(self):
        input_path, _ = QFileDialog.getOpenFileName(self, "Select PDF to Convert", "", "PDF Files (*.pdf)")
        if not input_path:
            return
        
        # Ask for a folder to save images
        output_dir = QFileDialog.getExistingDirectory(self, "Select Output Folder")
        if not output_dir:
            return

        try:
            doc = fitz.open(input_path) # Open with PyMuPDF
            base_name = os.path.splitext(os.path.basename(input_path))[0]
            
            count = 0
            for i, page in enumerate(doc):
                pix = page.get_pixmap()
                output_file = os.path.join(output_dir, f"{base_name}_page_{i+1}.png")
                pix.save(output_file)
                count += 1
            
            QMessageBox.information(self, "Success", f"Converted {count} pages to PNG in:\n{output_dir}")
        except Exception as e:
            QMessageBox.critical(self, "Error", f"Failed to convert PDF:\n{e}")

if __name__ == '__main__':
    app = QApplication(sys.argv)
    app.setQuitOnLastWindowClosed(True)
    ex = MasterPDFTool()
    ex.show()
    sys.exit(app.exec_())