:: -- install necessary applications --

:: install 7-zip
if not exist "C:\Windows\Temp\7z938-x64.msi" (
  powershell -Command "(New-Object System.Net.WebClient).DownloadFile('http://www.7-zip.org/a/7z938-x64.msi', 'C:\Windows\Temp\7z938-x64.msi')" <NUL
)
msiexec /qb /i C:\Windows\Temp\7z938-x64.msi

:: install ultradefrag
if not exist "C:\Windows\Temp\ultradefrag.zip" (
  powershell -Command "(New-Object System.Net.WebClient).DownloadFile('http://downloads.sourceforge.net/ultradefrag/ultradefrag-portable-6.0.2.bin.amd64.zip', 'C:\Windows\Temp\ultradefrag.zip')" <NUL
)
if not exist "C:\Windows\Temp\ultradefrag-portable-6.0.2.amd64\udefrag.exe" (
  cmd /c ""C:\Program Files\7-Zip\7z.exe" x C:\Windows\Temp\ultradefrag.zip -oC:\Windows\Temp"
)

:: install sdelete
if not exist "C:\Windows\Temp\SDelete.zip" (
  powershell -Command "(New-Object System.Net.WebClient).DownloadFile('http://download.sysinternals.com/files/SDelete.zip', 'C:\Windows\Temp\SDelete.zip')" <NUL
)
if not exist "C:\Windows\Temp\sdelete.exe" (
  cmd /c ""C:\Program Files\7-Zip\7z.exe" x C:\Windows\Temp\SDelete.zip -oC:\Windows\Temp"
)
cmd /c %SystemRoot%\System32\reg.exe ADD HKCU\Software\Sysinternals\SDelete /v EulaAccepted /t REG_DWORD /d 1 /f

:: -- remove unneeded files --

:: uninstall 7-zip
msiexec /qb /x C:\Windows\Temp\7z938-x64.msi

:: remove windows update download files
net stop wuauserv
rmdir /S /Q C:\Windows\SoftwareDistribution\Download
mkdir C:\Windows\SoftwareDistribution\Download
net start wuauserv

:: -- cleanup c:\ --

:: defrag c:\
cmd /c C:\Windows\Temp\ultradefrag-portable-6.0.2.amd64\udefrag.exe --optimize --repeat C:

:: zero our deleted files on c:\
cmd /c C:\Windows\Temp\sdelete.exe -q -z C:
