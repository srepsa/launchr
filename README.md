# launchr

Tool for launching graphical iOS and macOS apps on ARM Macs, with full control.

## Usage

```console
launchr [-platform macos|ios] [-mode suspended|running] [-envfile <path_to_env_plist>] -exec <path_to_executable>
```

Example `env.plist`:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
	<dict>
	<key>DYLD_INSERT_LIBRARIES</key>
	<string>hax.dylib</string>
	</dict>
</plist>
```

## A Note On SIP
In order to run ad-hoc signed code with platform set to iOS, SIP must be disabled (if you know a workaround, let me know!) With SIP enabled, you'll likely get an error like the following:

```console
default	21:27:49.339157+0200	kernel	Using iOS Platform policy
default	21:27:49.339545+0200	kernel	AMFI: '/Users/jim/Desktop/MobileSafari.app/MobileSafari' is adhoc signed.
default	21:27:49.339550+0200	kernel	AMFI: '/Users/jim/Desktop/MobileSafari.app/MobileSafari': unsuitable CT policy 0 for this platform/device, rejecting signature.
default	21:27:49.339554+0200	kernel	AMFI: code signature validation failed.
default	21:27:49.339610+0200	kernel	proc 3827: load code signature error 4 for file "MobileSafari"
default	21:27:49.340117+0200	kernel	AMFI: hook..execve() killing pid 3827: Attempt to execute completely unsigned code (must be at least ad-hoc signed).

```
