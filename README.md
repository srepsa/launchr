# launchr

Tool for launching iOS apps on ARM Macs, with full control.

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
