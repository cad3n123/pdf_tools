#!/bin/bash
set -e

# --- CONFIGURATION ---
UPDATE_URL="https://raw.githubusercontent.com/cad3n123/pdf_tools/main/MasterPDFTool_Offline.html"
VERSION="1.0"
OUTFILE="MasterPDFTool_Offline.html"

echo "==================================================="
echo "  Master PDF Tool - Auto-Update Builder (Mac)"
echo "==================================================="

TEMP_DIR=$(mktemp -d)
echo "1. Downloading libraries..."
curl -s -L "https://unpkg.com/pdf-lib@1.17.1/dist/pdf-lib.min.js" -o "$TEMP_DIR/pdflib.js"
curl -s -L "https://unpkg.com/downloadjs@1.4.7/download.min.js" -o "$TEMP_DIR/download.js"
curl -s -L "https://cdnjs.cloudflare.com/ajax/libs/jszip/3.10.1/jszip.min.js" -o "$TEMP_DIR/jszip.js"
curl -s -L "https://cdnjs.cloudflare.com/ajax/libs/pdf.js/2.16.105/pdf.min.js" -o "$TEMP_DIR/pdf.js"
curl -s -L "https://cdnjs.cloudflare.com/ajax/libs/pdf.js/2.16.105/pdf.worker.min.js" -o "$TEMP_DIR/worker.js"

echo "2. Encoding Worker..."
WORKER_B64=$(base64 < "$TEMP_DIR/worker.js" | tr -d '\n')

# READ LIBS INTO VARIABLES FOR EMBEDDING
LIB_PDFLIB=$(cat "$TEMP_DIR/pdflib.js")
LIB_DL=$(cat "$TEMP_DIR/download.js")
LIB_ZIP=$(cat "$TEMP_DIR/jszip.js")
LIB_PDFJS=$(cat "$TEMP_DIR/pdf.js")

echo "3. Creating Smart HTML..."
cat <<EOF > "$OUTFILE"
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Master PDF Tool (Smart)</title>
    <style>
        body { font-family: sans-serif; margin: 0; overflow: hidden; background: #f8fafc; }
        #loader-ui { position: fixed; top: 0; left: 0; width: 100%; height: 100%; background: #fff; z-index: 9999; display: flex; flex-direction: column; justify-content: center; align-items: center; transition: opacity 0.5s; }
        .spinner { width: 50px; height: 50px; border: 5px solid #e2e8f0; border-top: 5px solid #2563eb; border-radius: 50%; animation: spin 1s linear infinite; margin-bottom: 20px; }
        @keyframes spin { 0% { transform: rotate(0deg); } 100% { transform: rotate(360deg); } }
        #status-text { font-size: 1.2rem; color: #333; font-weight: 500; }
        #progress-bar { width: 300px; height: 6px; background: #e2e8f0; border-radius: 3px; margin-top: 15px; overflow: hidden; }
        #progress-fill { height: 100%; width: 0%; background: #2563eb; transition: width 0.3s; }
    </style>
    <script>
        const CURRENT_VERSION = "${VERSION}";
        const UPDATE_URL = "${UPDATE_URL}";
        const WORKER_B64 = "${WORKER_B64}";
        // LIBRARIES (Backticks escaped for embedding)
        const LIB_PDFLIB = \`${LIB_PDFLIB//\`/\\`}\`;
        const LIB_DL = \`${LIB_DL//\`/\\`}\`;
        const LIB_ZIP = \`${LIB_ZIP//\`/\\`}\`;
        const LIB_PDFJS = \`${LIB_PDFJS//\`/\\`}\`;
    </script>
</head>
<body>
    <div id="loader-ui">
        <div class="spinner"></div>
        <div id="status-text">Checking for updates...</div>
        <div id="progress-bar"><div id="progress-fill"></div></div>
    </div>
    <script>
    (async function() {
        const ui = document.getElementById('loader-ui');
        const txt = document.getElementById('status-text');
        const bar = document.getElementById('progress-fill');
        
        function launchApp(isUpdate) {
            txt.innerText = isUpdate ? "Update found! Launching..." : "Offline mode. Launching...";
            bar.style.width = "100%";
            setTimeout(() => {
                ui.style.opacity = '0';
                setTimeout(() => ui.remove(), 500);
                injectApp();
            }, 500);
        }
        
        // 1. Check for Updates
        if (!UPDATE_URL.includes("YOUR_USERNAME")) {
            try {
                const controller = new AbortController();
                setTimeout(() => controller.abort(), 5000);
                txt.innerText = "Checking repository...";
                bar.style.width = "30%";
                const response = await fetch(UPDATE_URL + '?t=' + Date.now(), { signal: controller.signal });
                
                if (response.ok) {
                    const remoteHtml = await response.text();
                    const match = remoteHtml.match(/const CURRENT_VERSION = "([^"]+)"/);
                    const remoteVer = match ? match[1] : "0.0";
                    
                    if (remoteVer > CURRENT_VERSION) {
                        txt.innerText = "New version (" + remoteVer + ") found! Downloading...";
                        bar.style.width = "80%";
                        document.open();
                        document.write(remoteHtml);
                        document.close();
                        return;
                    }
                }
            } catch (e) { console.log("Offline or check failed", e); }
        }
        
        launchApp(false);
        
        function injectApp() {
            // CSS
            const style = document.createElement('style');
            style.innerHTML = \`:root { --primary: #2563eb; --bg: #f8fafc; --card: #ffffff; } body { overflow: auto; font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif; background: var(--bg); display: flex; justify-content: center; min-height: 100vh; margin: 0; padding: 20px; color: #333; } .container { background: var(--card); width: 100%; max-width: 600px; border-radius: 12px; box-shadow: 0 4px 6px -1px rgba(0,0,0,0.1); overflow: hidden; } .tabs { display: flex; background: #e2e8f0; } .tab { flex: 1; padding: 15px; text-align: center; cursor: pointer; font-weight: 600; color: #64748b; transition: 0.2s; border: none; background: none; outline: none; } .tab.active { background: var(--card); color: var(--primary); border-top: 3px solid var(--primary); } .content { padding: 30px; display: none; } .content.active { display: block; } h2 { margin-top: 0; } p { color: #666; font-size: 0.9em; margin-bottom: 20px; } .drop-zone { border: 2px dashed #cbd5e1; border-radius: 8px; padding: 40px 20px; text-align: center; margin-bottom: 20px; transition: 0.2s; cursor: pointer; } .drop-zone:hover { border-color: var(--primary); background: #eff6ff; } .btn { background: var(--primary); color: white; border: none; padding: 12px 24px; border-radius: 6px; font-size: 16px; cursor: pointer; width: 100%; font-weight: 600; transition: 0.2s; } .btn:hover { background: #1d4ed8; } .status { margin-top: 15px; text-align: center; font-size: 0.9em; min-height: 20px; } .error { color: #dc2626; } .success { color: #16a34a; }\`;
            document.head.appendChild(style);
            
            // LIBS
            [LIB_PDFLIB, LIB_DL, LIB_ZIP, LIB_PDFJS].forEach(code => {
                const s = document.createElement('script');
                s.textContent = code;
                document.head.appendChild(s);
            });
            
            // WORKER
            const workerBlob = new Blob([atob(WORKER_B64)], { type: 'text/javascript' });
            pdfjsLib.GlobalWorkerOptions.workerSrc = URL.createObjectURL(workerBlob);
            
            // UI
            document.body.innerHTML = \`<div class="container"> <div class="tabs"> <button class="tab active" onclick="switchTab('combine')">Combine PDFs</button> <button class="tab" onclick="switchTab('reverse')">Reverse PDF</button> <button class="tab" onclick="switchTab('png')">PDF to PNG</button> </div> <div id="combine" class="content active"> <h2>Combine Multiple PDFs</h2> <p>Select multiple files. They will be merged in the order selected.</p> <div class="drop-zone" onclick="document.getElementById('mergeInput').click()"> <span id="mergeLabel">Click to select PDFs</span> <input type="file" id="mergeInput" multiple accept="application/pdf" style="display:none" onchange="updateLabel('mergeInput', 'mergeLabel')"> </div> <button class="btn" onclick="mergePDFs()">Download Merged PDF</button> <div id="mergeStatus" class="status"></div> </div> <div id="reverse" class="content"> <h2>Reverse PDF Order</h2> <p>Select a single PDF to reverse its page order.</p> <div class="drop-zone" onclick="document.getElementById('reverseInput').click()"> <span id="reverseLabel">Click to select PDF</span> <input type="file" id="reverseInput" accept="application/pdf" style="display:none" onchange="updateLabel('reverseInput', 'reverseLabel')"> </div> <button class="btn" onclick="reversePDF()">Download Reversed PDF</button> <div id="reverseStatus" class="status"></div> </div> <div id="png" class="content"> <h2>Convert PDF to PNGs</h2> <p>Converts all pages to images and downloads them as a ZIP.</p> <div class="drop-zone" onclick="document.getElementById('pngInput').click()"> <span id="pngLabel">Click to select PDF</span> <input type="file" id="pngInput" accept="application/pdf" style="display:none" onchange="updateLabel('pngInput', 'pngLabel')"> </div> <button class="btn" onclick="pdfToPng()">Convert & Download ZIP</button> <div id="pngStatus" class="status"></div> </div> <div style="text-align:center; margin-top:10px; font-size:0.8em; color:#999;">v\${CURRENT_VERSION}</div> </div>\`;
            
            // LOGIC
            window.switchTab = function(id) { document.querySelectorAll('.content').forEach(el => el.classList.remove('active')); document.querySelectorAll('.tab').forEach(el => el.classList.remove('active')); document.getElementById(id).classList.add('active'); event.target.classList.add('active'); clearStatus(); };
            window.updateLabel = function(id, lbl) { const i = document.getElementById(id); const c = i.files.length; document.getElementById(lbl).innerText = c > 0 ? c + " file(s)" : "Click to select"; };
            window.setStatus = function(id, m, t) { const el = document.getElementById(id); el.innerText = m; el.className = 'status ' + t; };
            window.clearStatus = function() { document.querySelectorAll('.status').forEach(el => el.innerText = ''); };
            window.readFileAsArrayBuffer = async function(file) { return new Promise((resolve, reject) => { const r = new FileReader(); r.onload = () => resolve(r.result); r.onerror = reject; r.readAsArrayBuffer(file); }); };
            
            window.mergePDFs = async function() { const files = document.getElementById('mergeInput').files; if (!files.length) return setStatus('mergeStatus', 'Select files.', 'error'); setStatus('mergeStatus', 'Merging...', ''); try { const merged = await PDFLib.PDFDocument.create(); for (let file of files) { const bytes = await readFileAsArrayBuffer(file); const pdf = await PDFLib.PDFDocument.load(bytes); const pages = await merged.copyPages(pdf, pdf.getPageIndices()); pages.forEach((p) => merged.addPage(p)); } download(await merged.save(), "merged.pdf", "application/pdf"); setStatus('mergeStatus', 'Done!', 'success'); } catch (e) { setStatus('mergeStatus', 'Error: ' + e.message, 'error'); } };
            window.reversePDF = async function() { const file = document.getElementById('reverseInput').files[0]; if (!file) return setStatus('reverseStatus', 'Select file.', 'error'); setStatus('reverseStatus', 'Processing...', ''); try { const pdf = await PDFLib.PDFDocument.load(await readFileAsArrayBuffer(file)); const newPdf = await PDFLib.PDFDocument.create(); for (let i = pdf.getPageCount() - 1; i >= 0; i--) { const [p] = await newPdf.copyPages(pdf, [i]); newPdf.addPage(p); } download(await newPdf.save(), "reversed.pdf", "application/pdf"); setStatus('reverseStatus', 'Done!', 'success'); } catch (e) { setStatus('reverseStatus', 'Error: ' + e.message, 'error'); } };
            window.pdfToPng = async function() { const file = document.getElementById('pngInput').files[0]; if (!file) return setStatus('pngStatus', 'Select file.', 'error'); setStatus('pngStatus', 'Processing...', ''); try { const pdf = await pdfjsLib.getDocument(await readFileAsArrayBuffer(file)).promise; const zip = new JSZip(); for (let i = 1; i <= pdf.numPages; i++) { setStatus('pngStatus', 'Page ' + i + '...', ''); const page = await pdf.getPage(i); const vp = page.getViewport({ scale: 2.0 }); const cvs = document.createElement('canvas'); cvs.height = vp.height; cvs.width = vp.width; await page.render({ canvasContext: cvs.getContext('2d'), viewport: vp }).promise; zip.file('page_' + i + '.png', cvs.toDataURL('image/png').split(',')[1], {base64: true}); } setStatus('pngStatus', 'Zipping...', ''); download(await zip.generateAsync({type:"blob"}), "converted_images.zip"); setStatus('pngStatus', 'Done!', 'success'); } catch (e) { setStatus('pngStatus', 'Error: ' + e.message, 'error'); } };
        }
    })();
    </script>
</body>
</html>
EOF

rm -rf "$TEMP_DIR"
echo
echo "==================================================="
echo "  SUCCESS! Created $OUTFILE"
echo "==================================================="