# PsiMac

Psion connectivity for macOS.

PsiMac is an attempt to recreate the original Psion PsiMac and MacConnect functionality and UI on modern macOS. It currently makes use of [plptools](https://github.com/rrthomas/plptools/) for the PLP (Psion Link Protocol) session layer (NCP) and reimplements the presentation layer. The plan is to contribute back to plptools where appropriate during development.

The rationale behind creating a new app is that the existing approach taken by plptools, using [FUSE](https://en.wikipedia.org/wiki/Filesystem_in_Userspace) to expose the Psion files to the Mac, isn't practical (or always possible) on modern macOS. PsiMac aims to make it possible to connect a Psion to modern macOS without any development experience or additional software.

## Usage

You probably don't want to try to use PsiMac right now unless you're looking to contribute to the project—functionality is currently incredibly limited. If you're looking to connect to a Psion on macOS today, [plptools](https://github.com/rrthomas/plptools/) provides command line utilities for SIS file installation and FTP-like functionality.

## Status

At this early stage of development, progress can be tracked by seeing which server messages are supported (currently very few). As messages are checked off this list we can start adding higher-level user-facing functionality.

### Remote Command Services

- [ ] NCP_QUERY_SUPPORT
- [ ] NCP_EXEC_PROGRAM
- [ ] NCP_QUERY_DRIVE
- [ ] NCP_STOP_PROGRAM
- [ ] NCP_PROG_RUNNING
- [ ] NCP_FORMAT_OPEN
- [ ] NCP_FORMAT_READ
- [ ] NCP_GET_UNIQUE_ID
- [ ] NCP_GET_OWNER_INFO
- [x] NCP_GET_MACHINE_TYPE
- [ ] NCP_GET_CMD_LINE
- [ ] NCP_STOP_FILE
- [x] NCP_GET_MACHINE_INFO
- [ ] NCP_CLOSE_HANDLE
- [ ] NCP_REG_OPEN_ITER
- [ ] NCP_REG_READ_ITER
- [ ] NCP_REG_WRITE
- [ ] NCP_REG_READ
- [ ] NCP_REG_DELETE
- [ ] NCP_SET_TIME
- [ ] NCP_CONFIG_OPEN
- [ ] NCP_CONFIG_READ
- [ ] NCP_CONFIG_WRITE
- [ ] NCP_QUERY_OPEN
- [ ] NCP_QUERY_READ
- [ ] NCP_QUERY_OPEN

### Remote File Services

#### SIBO

- [ ] RFSV16_FOPEN
- [ ] RFSV16_FCLOSE
- [ ] RFSV16_FREAD
- [ ] RFSV16_FDIRREAD
- [ ] RFSV16_FDEVICEREAD
- [ ] RFSV16_FWRITE
- [ ] RFSV16_FSEEK
- [ ] RFSV16_FFLUSH
- [ ] RFSV16_FSETEOF
- [ ] RFSV16_RENAME
- [ ] RFSV16_DELETE
- [ ] RFSV16_FINFO
- [ ] RFSV16_SFSTAT
- [ ] RFSV16_PARSE
- [ ] RFSV16_MKDIR
- [ ] RFSV16_OPENUNIQUE
- [ ] RFSV16_STATUSDEVICE
- [ ] RFSV16_PATHTEST
- [ ] RFSV16_STATUSSYSTEM
- [ ] RFSV16_CHANGEDIR
- [ ] RFSV16_SFDATE

#### EPOC

- [ ] RFSV32_CLOSE_HANDLE
- [ ] RFSV32_OPEN_DIR
- [ ] RFSV32_READ_DIR
- [x] RFSV32_GET_DRIVE_LIST
- [ ] RFSV32_VOLUME
- [ ] RFSV32_SET_VOLUME_LABEL
- [ ] RFSV32_OPEN_FILE
- [ ] RFSV32_TEMP_FILE
- [ ] RFSV32_READ_FILE
- [ ] RFSV32_WRITE_FILE
- [ ] RFSV32_SEEK_FILE
- [ ] RFSV32_DELETE
- [ ] RFSV32_REMOTE_ENTRY
- [ ] RFSV32_FLUSH
- [ ] RFSV32_SET_SIZE
- [ ] RFSV32_RENAME
- [ ] RFSV32_MK_DIR_ALL
- [ ] RFSV32_RM_DIR
- [ ] RFSV32_SET_ATT
- [ ] RFSV32_ATT
- [ ] RFSV32_SET_MODIFIED
- [ ] RFSV32_MODIFIED
- [ ] RFSV32_SET_SESSION_PATH
- [ ] RFSV32_SESSION_PATH
- [ ] RFSV32_READ_WRITE_FILE
- [ ] RFSV32_CREATE_FILE
- [ ] RFSV32_REPLACE_FILE
- [ ] RFSV32_PATH_TEST
- [ ] RFSV32_LOCK
- [ ] RFSV32_UNLOCK
- [ ] RFSV32_OPEN_DIR_UID
- [ ] RFSV32_DRIVE_NAME
- [ ] RFSV32_SET_DRIVE_NAME
- [ ] RFSV32_REPLACE

### Clipboard

- [ ] RCLIP_INIT
- [ ] RCLIP_LISTEN
- [ ] RCLIP_NOTIFY

### Printer

- [ ] WPRT_LEVEL
- [ ] WPRT_DATA
- [ ] WPRT_CANCEL
- [ ] WPRT_STOP
- [ ] WPRT_START
- [ ] WPRT_END
- [ ] WPRT_SET_DRAW_MODE
- [ ] WPRT_SET_CLIPPING_RECT
- [ ] WPRT_CANCEL_CLIPPING_RECT
- [ ] WPRT_PRIMITIVE_06
- [ ] WPRT_USE_FONT
- [ ] WPRT_DISCARD_FONT
- [ ] WPRT_SET_UNDERLINE_STYLE
- [ ] WPRT_SET_STRIKETHROUGH_STYLE
- [ ] WPRT_LINE_FEED
- [ ] WPRT_CARRIAGE_RETURN
- [ ] WPRT_SET_PEN_COLOUR
- [ ] WPRT_SET_PEN_STYLE
- [ ] WPRT_SET_PEN_SIZE
- [ ] WPRT_SET_BRUSH_COLOUR
- [ ] WPRT_SET_BRUSH_STYLE
- [ ] WPRT_PRIMITIVE_17
- [ ] WPRT_DRAW_LINE
- [ ] WPRT_PRIMITIVE_1B
- [ ] WPRT_DRAW_ELLIPSE
- [ ] WPRT_DRAW_RECT
- [ ] WPRT_DRAW_POLYGON
- [ ] WPRT_DRAW_BITMAP_RECT
- [ ] WPRT_DRAW_BITMAP_SRC
- [ ] WPRT_DRAW_TEXT
- [ ] WPRT_DRAW_TEXT_JUSTIFIED

## References

- [Psion Link Protocol](https://thoukydides.github.io/riscos-psifs/plp.html)

## License

PsiMac is licensed under the GNU General Public License (GPL) version 2 (see [LICENSE](LICENSE)). It depends on the following separately licensed third-party libraries and components:

- [DataStream](https://github.com/jbmorley/DataStream), MIT License
- [Diligence](https://github.com/inseven/diligence), MIT License
