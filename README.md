# launchr

Tool for launching graphical iOS and macOS apps on ARM Macs, with full control.

## Usage

```console
Usage: launchr [-platform macos|ios] [-allowinterpose yes] [-mode suspended|running] [-envfile <path_to_env_plist>] -exec <path_to_executable>
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

## A Note On AMFI
In order to run ad-hoc signed code with platform set to iOS, AMFI must be disabled (if you know a workaround, let me know!). With AMFI enabled, you'll likely get an error like the following:

```console
default	21:27:49.339550+0200	kernel	AMFI: '/Users/jim/Desktop/MobileSafari.app/MobileSafari': unsuitable CT policy 0 for this platform/device, rejecting signature.
default	21:27:49.339554+0200	kernel	AMFI: code signature validation failed.

```

Disable AMFI by adding a boot parameter (note that SIP needs to be disabled for this to be allowed):

```console
sudo nvram boot-args="amfi_get_out_of_my_way=1"
```

## Credits

* dyld patching code: Samuel Groß (Google Project Zero).
