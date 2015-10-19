# ----- CUSTOMIZE RUNTIME -----

# compile 32-bit dotnet assemblies
write-host "==> Compiling 32-bit dotnet assemblies";
$exe = "$env:windir\microsoft.net\framework\v4.0.30319\ngen.exe";
&$exe update /force /queue;
&$exe executequeueditems;

# compile 64-bit dotnet assemblies
if ($env:PROCESSOR_ARCHITECTURE -ieq "AMD64") {
    write-host "==> Compiling 64-bit dotnet assemblies";
    $exe = "$env:windir\microsoft.net\framework64\v4.0.30319\ngen.exe";
    &$exe update /force /queue;
    &$exe executequeueditems;
}
