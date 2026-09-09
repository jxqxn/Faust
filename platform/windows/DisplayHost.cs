// Windows adapter for Unity Screen.resolutions / Screen.SetResolution.
// Gameplay contract: SettingDropDownController 0x5aa0b0; GameApplication
// SetResolution 0x43f700 / SetFullScreen 0x43eea0. No authored mode table.
// Built with the installed .NET Framework compiler; no downloads/packages.
using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.IO;
using System.IO.Pipes;
using System.Runtime.InteropServices;
using System.Threading;
using System.Web.Script.Serialization;

public static class DisplayHost {
    [StructLayout(LayoutKind.Explicit, CharSet=CharSet.Unicode, Size=220)]
    public struct Mode {
        [FieldOffset(68)] public ushort size;
        [FieldOffset(72)] public uint fields;
        [FieldOffset(76)] public int x;
        [FieldOffset(80)] public int y;
        [FieldOffset(168)] public uint bits;
        [FieldOffset(172)] public uint width;
        [FieldOffset(176)] public uint height;
        [FieldOffset(180)] public uint flags;
        [FieldOffset(184)] public uint frequency;
    }
    [StructLayout(LayoutKind.Sequential, CharSet=CharSet.Unicode)]
    public struct MonitorInfo {
        public uint size;
        public int left, top, right, bottom, workLeft, workTop, workRight, workBottom;
        public uint flags;
        [MarshalAs(UnmanagedType.ByValTStr, SizeConst=32)] public string device;
    }
    [DllImport("user32.dll", CharSet=CharSet.Unicode)]
    static extern bool EnumDisplaySettingsEx(string device, int index, ref Mode mode, uint flags);
    [DllImport("user32.dll", CharSet=CharSet.Unicode)]
    static extern int ChangeDisplaySettingsEx(string device, ref Mode mode, IntPtr hwnd, uint flags, IntPtr extra);
    [DllImport("user32.dll")] static extern IntPtr MonitorFromWindow(IntPtr hwnd, uint flags);
    [DllImport("user32.dll", CharSet=CharSet.Unicode)] static extern bool GetMonitorInfo(IntPtr monitor, ref MonitorInfo info);
    [DllImport("user32.dll")] static extern bool SetProcessDPIAware();
    static readonly JavaScriptSerializer Json = new JavaScriptSerializer();
    static readonly Dictionary<string, Mode> Originals = new Dictionary<string, Mode>();
    static readonly object Gate = new object();

    static Mode Current(string device) {
        Mode mode = new Mode(); mode.size = 220;
        if (!EnumDisplaySettingsEx(device, -1, ref mode, 0)) throw new Exception("Cannot read current display mode.");
        return mode;
    }
    static string Device(long window) {
        MonitorInfo info = new MonitorInfo(); info.size = (uint)Marshal.SizeOf(info);
        if (!GetMonitorInfo(MonitorFromWindow(new IntPtr(window), 2), ref info)) throw new Exception("Cannot locate game monitor.");
        return info.device;
    }
    static object Query(long window) {
        string device = Device(window);
        Mode current = Current(device);
        List<Mode> modes = new List<Mode>();
        for (int i = 0; ; ++i) {
            Mode mode = new Mode(); mode.size = 220;
            if (!EnumDisplaySettingsEx(device, i, ref mode, 0)) break;
            modes.Add(mode);
        }
        modes.Sort(delegate(Mode a, Mode b) { int width = b.width.CompareTo(a.width); return width != 0 ? width : b.height.CompareTo(a.height); });
        List<string> sizes = new List<string>();
        foreach (Mode mode in modes) {
            string text = mode.width + "x" + mode.height;
            if (!sizes.Contains(text)) sizes.Add(text);
        }
        return new { ok=true, device=device, width=current.width, height=current.height, modes=sizes };
    }
    static bool RestoreAll() {
        lock (Gate) {
            List<string> restored = new List<string>();
            foreach (KeyValuePair<string, Mode> pair in Originals) {
                Mode original = pair.Value;
                if (ChangeDisplaySettingsEx(pair.Key, ref original, IntPtr.Zero, 0, IntPtr.Zero) == 0)
                    restored.Add(pair.Key);
            }
            foreach (string device in restored) Originals.Remove(device);
            return Originals.Count == 0;
        }
    }
    static object Apply(string[] args) {
        long window = long.Parse(args[1]);
        string device = Device(window);
        if (args[0] == "restore") {
            if (!RestoreAll()) return new { ok=false, error="Cannot restore the previous desktop mode" };
            return Query(window);
        }
        uint width = uint.Parse(args[2]), height = uint.Parse(args[3]);
        Mode before = Current(device);
        if (before.width == width && before.height == height) return Query(window);
        // Keep existing orientation/bit depth; let Windows select a compatible
        // refresh rate. Never persist to the registry (no CDS_UPDATEREGISTRY).
        Mode desired = before;
        desired.width = width; desired.height = height;
        desired.fields = 0x80000 | 0x100000;
        int result = ChangeDisplaySettingsEx(device, ref desired, IntPtr.Zero, 2, IntPtr.Zero); // CDS_TEST
        if (result != 0) return new { ok=false, error="Unsupported display mode", code=result };
        lock (Gate) {
            if (!Originals.ContainsKey(device)) Originals.Add(device, before);
            result = ChangeDisplaySettingsEx(device, ref desired, IntPtr.Zero, 4, IntPtr.Zero); // CDS_FULLSCREEN
            if (result != 0) return new { ok=false, error="Display mode change failed", code=result };
        }
        Mode actual = Current(device);
        if (actual.width != width || actual.height != height) {
            RestoreAll();
            return new { ok=false, error="Driver did not apply requested display size" };
        }
        return Query(window);
    }
    static string PipeName(int owner) { return "Faust.Display." + owner; }
    static void Serve(int owner) {
        Process parent = Process.GetProcessById(owner);
        Thread watcher = new Thread(delegate() {
            parent.WaitForExit();
            for (int i = 0; i < 5 && !RestoreAll(); ++i) Thread.Sleep(100);
            Environment.Exit(0);
        });
        watcher.IsBackground = true; watcher.Start();
        try {
            while (true) {
                using (NamedPipeServerStream pipe = new NamedPipeServerStream(PipeName(owner), PipeDirection.InOut, 1)) {
                    pipe.WaitForConnection();
                    StreamReader reader = new StreamReader(pipe);
                    StreamWriter writer = new StreamWriter(pipe); writer.AutoFlush = true;
                    try {
                        string[] request = reader.ReadLine().Split('|');
                        writer.WriteLine(Json.Serialize(Apply(request)));
                    } catch (Exception error) {
                        writer.WriteLine(Json.Serialize(new { ok=false, error=error.Message }));
                    }
                }
            }
        } finally { RestoreAll(); }
    }
    static object Send(int owner, string[] args) {
        NamedPipeClientStream pipe = new NamedPipeClientStream(".", PipeName(owner), PipeDirection.InOut);
        // Godot starts the server separately with OS.create_process so it
        // cannot inherit this short-lived request's captured output handles.
        pipe.Connect(5000);
        using (pipe) {
            StreamWriter writer = new StreamWriter(pipe); writer.AutoFlush = true;
            StreamReader reader = new StreamReader(pipe);
            writer.WriteLine(string.Join("|", args));
            return Json.DeserializeObject(reader.ReadLine());
        }
    }
    public static int Main(string[] args) {
        SetProcessDPIAware();
        try {
            if (args[0] == "serve") { Serve(int.Parse(args[1])); return 0; }
            object result;
            if (args[0] == "query") result = Query(long.Parse(args[1]));
            else {
                int owner = int.Parse(args[1]);
                List<string> command = new List<string>(); command.Add(args[0]);
                for (int i = 2; i < args.Length; ++i) command.Add(args[i]);
                result = Send(owner, command.ToArray());
            }
            Console.WriteLine(Json.Serialize(result)); return 0;
        } catch (Exception error) { Console.WriteLine(Json.Serialize(new { ok=false, error=error.Message })); return 1; }
    }
}
