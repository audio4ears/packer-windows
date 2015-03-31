:: stop 'Windows Update' service
net stop wuauserv

:: enable 'Microsoft Updates'
reg add "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update" /v EnableFeaturedSoftware /t REG_DWORD /d 1 /f

:: disable 'Recomended Updates' aka Optional Updates
reg add "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update" /v IncludeRecommendedUpdates /t REG_DWORD /d 0 /f

:: register the Microsoft Update service with Automatic Updates.
echo Set ServiceManager = CreateObject("Microsoft.Update.ServiceManager") > A:\temp.vbs
echo Set NewUpdateService = ServiceManager.AddService2("7971f918-a847-4430-9279-4a52d1efe18d",7,"") >> A:\temp.vbs
cscript A:\temp.vbs

:: start 'Windows Update' service
net start wuauserv
