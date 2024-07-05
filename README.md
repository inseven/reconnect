# Reconnect

[![build](https://github.com/inseven/PsiMac/actions/workflows/build.yaml/badge.svg)](https://github.com/inseven/PsiMac/actions/workflows/build.yaml)

Psion connectivity for macOS.

<img width="1053" src="images/screenshot@2x.png">

PsiMac is an attempt to recreate the original Psion PsiMac and MacConnect functionality and UI on modern macOS. It makes use of [plptools](https://github.com/rrthomas/plptools/) for both the PLP (Psion Link Protocol) session layer (NCP) and presentation layers (file server, etc). The plan is to contribute back to plptools where appropriate during development.

The rationale behind creating a new app is that the existing approach taken by plptools, using [FUSE](https://en.wikipedia.org/wiki/Filesystem_in_Userspace) to expose the Psion files to the Mac, isn't practical (or always possible) on modern macOS. PsiMac aims to make it possible to connect a Psion to modern macOS without any development experience or additional software.

## Usage

You probably don't want to try to use Reconnect right now unless you're looking to contribute to the project—functionality is currently incredibly limited. If you're looking to connect to a Psion on macOS today, [plptools](https://github.com/rrthomas/plptools/) provides command line utilities for SIS file installation and FTP-like functionality.

## Status

- Working menu bar item showing connection status
- Simple file browser

## Development

Debugging Reconnect is a little more awkward than normal since plptools uses signals internally which are trapped by Xcode and lldb by default. Disable this automatic behavior by adding the following line to '~/.lldbinit-Xcode':

```
process handle SIGUSR1 -n true -p true -s false
```

## References

- [Psion Link Protocol](https://thoukydides.github.io/riscos-psifs/plp.html)

## License

Reconnect is licensed under the GNU General Public License (GPL) version 2 (see [LICENSE](LICENSE)). It depends on the following separately licensed third-party libraries and components:

- [Diligence](https://github.com/inseven/diligence), MIT License
- [Interact](https://github.com/inseven/interact), MIT License
- [Licensable](https://github.com/inseven/licensable), MIT License
- [plptools](https://github.com/rrthomas/plptools/), GPL-2.0 license
