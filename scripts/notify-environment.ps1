$ErrorActionPreference = 'Stop'
Add-Type -Namespace NeovimEnvironment -Name Change -MemberDefinition '[System.Runtime.InteropServices.DllImport("user32.dll", CharSet=System.Runtime.InteropServices.CharSet.Unicode)] public static extern System.IntPtr SendMessageTimeout(System.IntPtr window, uint message, System.UIntPtr wparam, string lparam, uint flags, uint timeout, out System.UIntPtr result);'
$result = [UIntPtr]::Zero
[void][NeovimEnvironment.Change]::SendMessageTimeout([IntPtr]0xffff, 0x001a, [UIntPtr]::Zero, 'Environment', 2, 1000, [ref]$result)
