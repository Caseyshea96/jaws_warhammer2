using System;
using System.ComponentModel;
using System.IO;
using System.Runtime.InteropServices;

namespace WarhammerAccessibility {
    // Minimal wrapper around NV Access' official Controller Client API.
    public static class NvdaController {
        private const string LibraryName = "nvdaControllerClient.dll";
        private const uint LoadLibrarySearchDllLoadDir = 0x00000100;
        private const uint LoadLibrarySearchDefaultDirs = 0x00001000;
        private static IntPtr library;

        [DllImport("kernel32.dll", CharSet = CharSet.Unicode, SetLastError = true)]
        private static extern IntPtr LoadLibraryEx(string path, IntPtr file, uint flags);

        [DllImport(LibraryName)]
        private static extern int nvdaController_testIfRunning();

        [DllImport(LibraryName, CharSet = CharSet.Unicode)]
        private static extern int nvdaController_speakText(string text);

        [DllImport(LibraryName)]
        private static extern int nvdaController_cancelSpeech();

        [DllImport(LibraryName, CharSet = CharSet.Unicode)]
        private static extern int nvdaController_brailleMessage(string message);

        public static void Initialize(string path) {
            if (library != IntPtr.Zero) return;
            if (IntPtr.Size != 8) {
                throw new PlatformNotSupportedException("This diagnostic requires 64-bit Windows PowerShell.");
            }
            string fullPath = Path.GetFullPath(path);
            if (!String.Equals(Path.GetFileName(fullPath), LibraryName, StringComparison.OrdinalIgnoreCase)) {
                throw new ArgumentException("Unexpected NVDA Controller Client filename.", "path");
            }
            if (!File.Exists(fullPath)) throw new FileNotFoundException("NVDA Controller Client is missing.", fullPath);
            library = LoadLibraryEx(fullPath, IntPtr.Zero,
                LoadLibrarySearchDllLoadDir | LoadLibrarySearchDefaultDirs);
            if (library == IntPtr.Zero) throw new Win32Exception(Marshal.GetLastWin32Error());
        }

        public static int TestIfRunning() { return nvdaController_testIfRunning(); }

        public static int Speak(string text, bool interrupt) {
            if (interrupt) {
                int cancel = nvdaController_cancelSpeech();
                if (cancel != 0) return cancel;
            }
            return nvdaController_speakText(text);
        }

        public static int CancelSpeech() { return nvdaController_cancelSpeech(); }

        public static int Braille(string text) { return nvdaController_brailleMessage(text); }
    }
}
