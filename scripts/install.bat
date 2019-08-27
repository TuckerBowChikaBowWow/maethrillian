/* 2> nul
@echo off && cls && echo Loading... && echo.
set WinDirNet=%WinDir%\Microsoft.NET\Framework
if exist "%WinDirNet%\v2.0.50727\csc.exe" set csc="%WinDirNet%\v2.0.50727\csc.exe"
if exist "%WinDirNet%\v3.5\csc.exe" set csc="%WinDirNet%\v3.5\csc.exe"
if exist "%WinDirNet%\v4.0.30319\csc.exe" set csc="%WinDirNet%\v4.0.30319\csc.exe"
if "%csc%" == "" ( echo .NET Framework not found! && echo. && pause && exit )
%csc% /nologo /out:"%~dpnx0.exe" /r:System.IO.Compression.FileSystem.dll "%~dpnx0"
if not "%ERRORLEVEL%" == "0" ( echo. && pause && exit )
cls
"%~dpnx0.exe" %*
del "%~dpnx0.exe"
exit
*/

using System;
using System.IO;
using System.Net;
using System.Net.Security;
using System.Web.Script.Serialization;
using System.Collections.Generic;
using System.IO.Compression;

class ReleaseAsset {
    public string name;
    public string browser_download_url;
}

class Release {
    public string tag_name;
    public List<ReleaseAsset> assets;
}

class Program
{
    static void Return(int exitCode) {
        Console.Write("Press any key to exit... ");
        while (Console.ReadKey().Key != ConsoleKey.Enter) {}
        Environment.Exit(exitCode);
    }

    static void Main()
    {
        ServicePointManager.SecurityProtocol = SecurityProtocolType.Tls11 | SecurityProtocolType.Tls12;

        try {
            var appData = Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData);
            var localStatePath = Path.Combine(appData, "Packages\\Microsoft.HoganThreshold_8wekyb3d8bbwe\\LocalState");
            var gtsPath = Path.Combine(localStatePath, "GTS");

            // Get the latest release
            string patchFileName;
            using (var client = new WebClient()) {
                client.Headers.Add("user-agent", "Maethrillian Installer");

                Console.WriteLine("[ RUN  ] Get latest release");
                var releaseURI = new Uri("https://api.github.com/repos/ankoh/maethrillian/releases/latest");
                var releaseResponse = client.DownloadString(releaseURI);
                var serializer = new JavaScriptSerializer();
                var releaseObject = serializer.Deserialize<Release>(releaseResponse);
                Console.WriteLine("[ OK   ] Get latest release");
                
                string patchURL = ""; 
                for (int i = 0; i < releaseObject.assets.Count; ++i) {
                    if (releaseObject.assets[i].name == "maethrillian.zip") {
                        patchURL = releaseObject.assets[i].browser_download_url;
                        break;
                    }
                }
                if (patchURL == "") {
                    Console.WriteLine("Missing patch file");
                    Return(-1);
                }
                Console.WriteLine("Tag: " + releaseObject.tag_name);
                Console.WriteLine("Patch: " + patchURL);

                Console.WriteLine("[ RUN  ] Get patch file");
                var patchURI = new Uri(patchURL);
                patchFileName = Path.GetTempFileName();
                client.DownloadFile(patchURI, patchFileName);
                Console.WriteLine("[ OK   ] Get patch file");
            }

            // Clear the local state
            Console.WriteLine("[ RUN  ] Clear local state");
            if (Directory.Exists(gtsPath)) {
                Console.WriteLine("Delete '" + gtsPath + "'? [Y/N]");
                if (Console.ReadKey().KeyChar == 'Y') {
                    Console.WriteLine();
                    Directory.Delete(gtsPath, true);
                    Console.WriteLine("[ OK   ] Clear local state");
                } else {
                    Console.WriteLine();
                    Console.WriteLine("[ STOP ] Clear local state");
                    Return(-1);
                }
            } else {
                Console.WriteLine("[ SKIP ] Clear local state");
            }

            Console.WriteLine("[ RUN  ] Extract patch");
            ZipFile.ExtractToDirectory(patchFileName, localStatePath);   
            Console.WriteLine("[ OK   ] Extract patch");

        } catch (Exception e) {
            Console.WriteLine("Error: " + e);
        }
        Return(0);
    }
}