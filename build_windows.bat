@echo off
setlocal
cd /d "%~dp0"

echo ===================================================
echo   Master PDF Tool - Auto-Update Builder (Windows)
echo ===================================================

REM --- CONFIGURATION ---
set "UPDATE_URL=https://raw.githubusercontent.com/cad3n123/pdf_tools/main/MasterPDFTool_Offline.html"
set "VERSION=1.0"
set "OUTFILE=MasterPDFTool_Offline.html"
set "PWS=%temp%\build_smart_tool.ps1"

echo 1. Generating PowerShell Builder...

REM --- Writing PowerShell script line-by-line ---
if exist "%PWS%" del "%PWS%"

echo $ErrorActionPreference = "Stop" >> "%PWS%"
echo $url = "%UPDATE_URL%" >> "%PWS%"
echo $ver = "%VERSION%" >> "%PWS%"

echo Write-Host "2. Downloading libraries..." >> "%PWS%"
REM We use -UseBasicParsing for compatibility and .Content to get the text
echo $libs = @{ >> "%PWS%"
echo     "pdflib" = (Invoke-WebRequest "https://unpkg.com/pdf-lib@1.17.1/dist/pdf-lib.min.js" -UseBasicParsing).Content; >> "%PWS%"
echo     "downloadjs" = (Invoke-WebRequest "https://unpkg.com/downloadjs@1.4.7/download.min.js" -UseBasicParsing).Content; >> "%PWS%"
echo     "jszip" = (Invoke-WebRequest "https://cdnjs.cloudflare.com/ajax/libs/jszip/3.10.1/jszip.min.js" -UseBasicParsing).Content; >> "%PWS%"
echo     "pdfjs" = (Invoke-WebRequest "https://cdnjs.cloudflare.com/ajax/libs/pdf.js/2.16.105/pdf.min.js" -UseBasicParsing).Content; >> "%PWS%"
echo     "worker" = (Invoke-WebRequest "https://cdnjs.cloudflare.com/ajax/libs/pdf.js/2.16.105/pdf.worker.min.js" -UseBasicParsing).Content >> "%PWS%"
echo } >> "%PWS%"

echo Write-Host "3. Encoding Worker..." >> "%PWS%"
echo $workerBytes = [System.Text.Encoding]::UTF8.GetBytes($libs["worker"]) >> "%PWS%"
echo $workerB64 = [Convert]::ToBase64String($workerBytes) >> "%PWS%"

echo Write-Host "4. Creating Smart HTML..." >> "%PWS%"
REM Start the double-quoted Here-String for variable expansion
echo $html = @" >> "%PWS%"
echo ^<!DOCTYPE html^> >> "%PWS%"
echo ^<html lang="en"^> >> "%PWS%"
echo ^<head^> >> "%PWS%"
echo     ^<meta charset="UTF-8"^> >> "%PWS%"
echo     ^<meta name="viewport" content="width=device-width, initial-scale=1.0"^> >> "%PWS%"
echo     ^<title^>Master PDF Tool (Smart)^</title^> >> "%PWS%"
echo     ^<style^> >> "%PWS%"
echo         body { font-family: sans-serif; margin: 0; overflow: hidden; background: #f8fafc; } >> "%PWS%"
echo         #loader-ui { position: fixed; top: 0; left: 0; width: 100%%; height: 100%%; background: #fff; z-index: 9999; display: flex; flex-direction: column; justify-content: center; align-items: center; transition: opacity 0.5s; } >> "%PWS%"
echo         .spinner { width: 50px; height: 50px; border: 5px solid #e2e8f0; border-top: 5px solid #2563eb; border-radius: 50%%; animation: spin 1s linear infinite; margin-bottom: 20px; } >> "%PWS%"
echo         @keyframes spin { 0%% { transform: rotate(0deg); } 100%% { transform: rotate(360deg); } } >> "%PWS%"
echo         #status-text { font-size: 1.2rem; color: #333; font-weight: 500; } >> "%PWS%"
echo         #progress-bar { width: 300px; height: 6px; background: #e2e8f0; border-radius: 3px; margin-top: 15px; overflow: hidden; } >> "%PWS%"
echo         #progress-fill { height: 100%%; width: 0%%; background: #2563eb; transition: width 0.3s; } >> "%PWS%"
echo     ^</style^> >> "%PWS%"
echo     ^<script^> >> "%PWS%"
echo         const CURRENT_VERSION = "$ver"; >> "%PWS%"
echo         const UPDATE_URL = "$url"; >> "%PWS%"
echo         const WORKER_B64 = "$workerB64"; >> "%PWS%"
REM Here we inject the libraries. We replace backticks with escaped backticks, and $ with escaped $ to prevent JS errors.
REM In PowerShell @" string, we use double backticks to produce a literal backtick.
echo         const LIB_PDFLIB = ``$($libs["pdflib"].Replace('``', '\``').Replace('$', '\$'))``; >> "%PWS%"
echo         const LIB_DL = ``$($libs["downloadjs"].Replace('``', '\``').Replace('$', '\$'))``; >> "%PWS%"
echo         const LIB_ZIP = ``$($libs["jszip"].Replace('``', '\``').Replace('$', '\$'))``; >> "%PWS%"
echo         const LIB_PDFJS = ``$($libs["pdfjs"].Replace('``', '\``').Replace('$', '\$'))``; >> "%PWS%"
echo     ^</script^> >> "%PWS%"
echo ^</head^> >> "%PWS%"
echo ^<body^> >> "%PWS%"
echo     ^<div id="loader-ui"^> >> "%PWS%"
echo         ^<div class="spinner"^>^</div^> >> "%PWS%"
echo         ^<div id="status-text"^>Checking for updates...^</div^> >> "%PWS%"
echo         ^<div id="progress-bar"^>^<div id="progress-fill"^>^</div^>^</div^> >> "%PWS%"
echo     ^</div^> >> "%PWS%"
echo     ^<script^> >> "%PWS%"
echo     (async function() { >> "%PWS%"
echo         const ui = document.getElementById('loader-ui'); >> "%PWS%"
echo         const txt = document.getElementById('status-text'); >> "%PWS%"
echo         const bar = document.getElementById('progress-fill'); >> "%PWS%"
echo         function launchApp(isUpdate) { >> "%PWS%"
echo             txt.innerText = isUpdate ? "Update found! Launching..." : "Offline mode. Launching..."; >> "%PWS%"
echo             bar.style.width = "100%%"; >> "%PWS%"
echo             setTimeout(() =^> { >> "%PWS%"
echo                 ui.style.opacity = '0'; >> "%PWS%"
echo                 setTimeout(() =^> ui.remove(), 500); >> "%PWS%"
echo                 injectApp(); >> "%PWS%"
echo             }, 500); >> "%PWS%"
echo         } >> "%PWS%"
echo         if (!UPDATE_URL.includes("YOUR_USERNAME")) { >> "%PWS%"
echo             try { >> "%PWS%"
echo                 const controller = new AbortController(); >> "%PWS%"
echo                 const timeoutId = setTimeout(() =^> controller.abort(), 5000); >> "%PWS%"
echo                 txt.innerText = "Checking repository..."; >> "%PWS%"
echo                 bar.style.width = "30%%"; >> "%PWS%"
echo                 const response = await fetch(UPDATE_URL + '?t=' + Date.now(), { signal: controller.signal }); >> "%PWS%"
echo                 clearTimeout(timeoutId); >> "%PWS%"
echo                 if (response.ok) { >> "%PWS%"
echo                     const remoteHtml = await response.text(); >> "%PWS%"
echo                     const match = remoteHtml.match(/const CURRENT_VERSION = "([^"]+)"/); >> "%PWS%"
echo                     const remoteVer = match ? match[1] : "0.0"; >> "%PWS%"
echo                     if (remoteVer ^> CURRENT_VERSION) { >> "%PWS%"
echo                         txt.innerText = "New version (" + remoteVer + ") found! Downloading..."; >> "%PWS%"
echo                         bar.style.width = "80%%"; >> "%PWS%"
echo                         document.open(); >> "%PWS%"
echo                         document.write(remoteHtml); >> "%PWS%"
echo                         document.close(); >> "%PWS%"
echo                         return; >> "%PWS%"
echo                     } >> "%PWS%"
echo                 } >> "%PWS%"
echo             } catch (e) { console.log("Offline or check failed", e); } >> "%PWS%"
echo         } >> "%PWS%"
echo         launchApp(false); >> "%PWS%"
echo         function injectApp() { >> "%PWS%"
echo             const style = document.createElement('style'); >> "%PWS%"
REM Injecting CSS using a standard double-quoted string to avoid backtick issues
echo             style.innerHTML = ":root { --primary: #2563eb; --bg: #f8fafc; --card: #ffffff; } body { overflow: auto; font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; background: var(--bg); display: flex; justify-content: center; min-height: 100vh; margin: 0; padding: 20px; color: #333; } .container { background: var(--card); width: 100%%; max-width: 600px; border-radius: 12px; box-shadow: 0 4px 6px -1px rgba(0,0,0,0.1); overflow: hidden; } .tabs { display: flex; background: #e2e8f0; } .tab { flex: 1; padding: 15px; text-align: center; cursor: pointer; font-weight: 600; color: #64748b; transition: 0.2s; border: none; background: none; outline: none; } .tab.active { background: var(--card); color: var(--primary); border-top: 3px solid var(--primary); } .content { padding: 30px; display: none; } .content.active { display: block; } h2 { margin-top: 0; } p { color: #666; font-size: 0.9em; margin-bottom: 20px; } .drop-zone { border: 2px dashed #cbd5e1; border-radius: 8px; padding: 40px 20px; text-align: center; margin-bottom: 20px; transition: 0.2s; cursor: pointer; } .drop-zone:hover { border-color: var(--primary); background: #eff6ff; } .btn { background: var(--primary); color: white; border: none; padding: 12px 24px; border-radius: 6px; font-size: 16px; cursor: pointer; width: 100%%; font-weight: 600; transition: 0.2s; } .btn:hover { background: #1d4ed8; } .status { margin-top: 15px; text-align: center; font-size: 0.9em; min-height: 20px; } .error { color: #dc2626; } .success { color: #16a34a; }"; >> "%PWS%"
echo             document.head.appendChild(style); >> "%PWS%"
echo             const s1 = document.createElement('script'); s1.textContent = LIB_PDFLIB; document.head.appendChild(s1); >> "%PWS%"
echo             const s2 = document.createElement('script'); s2.textContent = LIB_DL; document.head.appendChild(s2); >> "%PWS%"
echo             const s3 = document.createElement('script'); s3.textContent = LIB_ZIP; document.head.appendChild(s3); >> "%PWS%"
echo             const s4 = document.createElement('script'); s4.textContent = LIB_PDFJS; document.head.appendChild(s4); >> "%PWS%"
echo             const workerBlob = new Blob([atob(WORKER_B64)], { type: 'text/javascript' }); >> "%PWS%"
echo             pdfjsLib.GlobalWorkerOptions.workerSrc = URL.createObjectURL(workerBlob); >> "%PWS%"
REM We escape the inner HTML string with carets for Batch, but using simple quotes inside JS simplifies things
echo             document.body.innerHTML = ^`^<div class="container"^> ^<div class="tabs"^> ^<button class="tab active" onclick="switchTab('combine')"^>Combine PDFs^</button^> ^<button class="tab" onclick="switchTab('reverse')"^>Reverse PDF^</button^> ^<button class="tab" onclick="switchTab('png')"^>PDF to PNG^</button^> ^</div^> ^<div id="combine" class="content active"^> ^<h2^>Combine Multiple PDFs^</h2^> ^<p^>Select multiple files. They will be merged in the order selected.^</p^> ^<div class="drop-zone" onclick="document.getElementById('mergeInput').click()"^> ^<span id="mergeLabel"^>Click to select PDFs^</span^> ^<input type="file" id="mergeInput" multiple accept="application/pdf" style="display:none" onchange="updateLabel('mergeInput', 'mergeLabel')"^> ^</div^> ^<button class="btn" onclick="mergePDFs()"^>Download Merged PDF^</button^> ^<div id="mergeStatus" class="status"^>^</div^> ^</div^> ^<div id="reverse" class="content"^> ^<h2^>Reverse PDF Order^</h2^> ^<p^>Select a single PDF to reverse its page order.^</p^> ^<div class="drop-zone" onclick="document.getElementById('reverseInput').click()"^> ^<span id="reverseLabel"^>Click to select PDF^</span^> ^<input type="file" id="reverseInput" accept="application/pdf" style="display:none" onchange="updateLabel('reverseInput', 'reverseLabel')"^> ^</div^> ^<button class="btn" onclick="reversePDF()"^>Download Reversed PDF^</button^> ^<div id="reverseStatus" class="status"^>^</div^> ^</div^> ^<div id="png" class="content"^> ^<h2^>Convert PDF to PNGs^</h2^> ^<p^>Converts all pages to images and downloads them as a ZIP.^</p^> ^<div class="drop-zone" onclick="document.getElementById('pngInput').click()"^> ^<span id="pngLabel"^>Click to select PDF^</span^> ^<input type="file" id="pngInput" accept="application/pdf" style="display:none" onchange="updateLabel('pngInput', 'pngLabel')"^> ^</div^> ^<button class="btn" onclick="pdfToPng()"^>Convert ^& Download ZIP^</button^> ^<div id="pngStatus" class="status"^>^</div^> ^</div^> ^<div style="text-align:center; margin-top:10px; font-size:0.8em; color:#999;"^>v$ver^</div^> ^</div^>^`; >> "%PWS%"
echo             window.switchTab = function(id) { document.querySelectorAll('.content').forEach(el =^> el.classList.remove('active')); document.querySelectorAll('.tab').forEach(el =^> el.classList.remove('active')); document.getElementById(id).classList.add('active'); event.target.classList.add('active'); clearStatus(); }; >> "%PWS%"
echo             window.updateLabel = function(id, lbl) { const i = document.getElementById(id); const c = i.files.length; document.getElementById(lbl).innerText = c ^> 0 ? c + " file(s)" : "Click to select"; }; >> "%PWS%"
echo             window.setStatus = function(id, m, t) { const el = document.getElementById(id); el.innerText = m; el.className = 'status ' + t; }; >> "%PWS%"
echo             window.clearStatus = function() { document.querySelectorAll('.status').forEach(el =^> el.innerText = ''); }; >> "%PWS%"
echo             window.readFileAsArrayBuffer = async function(file) { return new Promise((resolve, reject) =^> { const r = new FileReader(); r.onload = () =^> resolve(r.result); r.onerror = reject; r.readAsArrayBuffer(file); }); }; >> "%PWS%"
echo             window.mergePDFs = async function() { const files = document.getElementById('mergeInput').files; if (!files.length) return setStatus('mergeStatus', 'Select files.', 'error'); setStatus('mergeStatus', 'Merging...', ''); try { const merged = await PDFLib.PDFDocument.create(); for (let file of files) { const bytes = await readFileAsArrayBuffer(file); const pdf = await PDFLib.PDFDocument.load(bytes); const pages = await merged.copyPages(pdf, pdf.getPageIndices()); pages.forEach((p) =^> merged.addPage(p)); } download(await merged.save(), "merged.pdf", "application/pdf"); setStatus('mergeStatus', 'Done!', 'success'); } catch (e) { setStatus('mergeStatus', 'Error: ' + e.message, 'error'); } }; >> "%PWS%"
echo             window.reversePDF = async function() { const file = document.getElementById('reverseInput').files[0]; if (!file) return setStatus('reverseStatus', 'Select file.', 'error'); setStatus('reverseStatus', 'Processing...', ''); try { const pdf = await PDFLib.PDFDocument.load(await readFileAsArrayBuffer(file)); const newPdf = await PDFLib.PDFDocument.create(); for (let i = pdf.getPageCount() - 1; i ^>= 0; i--) { const [p] = await newPdf.copyPages(pdf, [i]); newPdf.addPage(p); } download(await newPdf.save(), "reversed.pdf", "application/pdf"); setStatus('reverseStatus', 'Done!', 'success'); } catch (e) { setStatus('reverseStatus', 'Error: ' + e.message, 'error'); } }; >> "%PWS%"
echo             window.pdfToPng = async function() { const file = document.getElementById('pngInput').files[0]; if (!file) return setStatus('pngStatus', 'Select file.', 'error'); setStatus('pngStatus', 'Processing...', ''); try { const pdf = await pdfjsLib.getDocument(await readFileAsArrayBuffer(file)).promise; const zip = new JSZip(); for (let i = 1; i ^<= pdf.numPages; i++) { setStatus('pngStatus', 'Page ' + i + '...', ''); const page = await pdf.getPage(i); const vp = page.getViewport({ scale: 2.0 }); const cvs = document.createElement('canvas'); cvs.height = vp.height; cvs.width = vp.width; await page.render({ canvasContext: cvs.getContext('2d'), viewport: vp }).promise; zip.file('page_' + i + '.png', cvs.toDataURL('image/png').split(',')[1], {base64: true}); } setStatus('pngStatus', 'Zipping...', ''); download(await zip.generateAsync({type:"blob"}), "converted_images.zip"); setStatus('pngStatus', 'Done!', 'success'); } catch (e) { setStatus('pngStatus', 'Error: ' + e.message, 'error'); } }; >> "%PWS%"
echo         } >> "%PWS%"
echo     })(); >> "%PWS%"
echo     ^</script^> >> "%PWS%"
echo ^</body^> >> "%PWS%"
echo ^</html^> >> "%PWS%"
REM Terminate the PowerShell string and write to file. We escape the pipe character.
echo "@ ^| Out-File -Encoding utf8 "%OUTFILE%" >> "%PWS%"

echo 5. Running PowerShell Builder...
powershell -NoProfile -ExecutionPolicy Bypass -File "%PWS%"

REM --- Cleanup ---
del "%PWS%"

echo.
echo ===================================================
echo   SUCCESS! Created %OUTFILE%
echo ===================================================
pause