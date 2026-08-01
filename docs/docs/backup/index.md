---
title: Backup
---

Reconnect supports full and incremental backups.

<img title="BACK.AVI" src="back.gif" srcset="back@2x.gif 2x" />

# Incremental Backups

{% include picture.html light="/images/backup@2x.png" dark="/images/backup-dark@2x.png" %}

Incremental backups can be significantly faster than full backups as they only copy modified files from your Psion. The are safe (and the default behaviour) but it is important to understand the way they work if you plan to use your Psion with other backup programs like PsiWin or FastBackup.

Reconnect uses a number of mechanisms to attempt to detect if another backup program has been used since the last complete backup. If there is any suggestion that another backup program has been used, it will perform a full backup.

> [!IMPORTANT]
>
> Although Reconnect implements mechanisms to detect when other programs have been used to back up a Psion (potentially invalidating the archive flag state), using incremental backups with other Psion backup programs unsafe and may result in data loss.

## Implementation

### Approach

In order to support fast incremental backup, Reconnect relies on the FAT file attribute. This attribute is used by both EPOC16 and EPOC32 (and other many other operating systems) to indicate that a file has been modified and needs to be backed up ('archived').

On completion of a successful backup, Reconnect clears the archive attribute for all files that have been backed up, recording that they have been archived. When performing a subsequent incremental backup, it only copies files with the archive attribute set (as a result of being modified).

To ensure Reconnect can correctly identify the files that have changed, it is important that Reconnect and EPOC are the only things that set these archive attributes. If they are cleared by another backup program, Reconnect has no way to know that a file has been modified.

### Detecting Other Backup Programs

Reconnect writes a special canary[^canary] file (`C:\System\Sync\lastbackup.txt` on EPOC32 and `M:\sync\lastback.txt` on EPOC16). This file contains the identifier of the last successful backup (e.g., `477A420D-84CC-4CCF-97FF-3837425C2F89`). It is used to lookup the last backup, and it is used to detect other backup programs.

Unlike every other file, Reconnect never clears the archive attribute of the canary file and, when performing a new incremental backup, it checks that the archive flag is still set. If the archive flag has been cleared, Reconnect performs a full backup. This guard works by assuming that any other backup program is unaware of Reconnect and, if it uses archive flags as part of its backup strategy, clear the archive flag of all files it backups up including, crucially, that of the canary.

[^canary]: A mechanism used as an early warning system. This term has its origins in early coal mining where miners would use a canary to detect odorless gas; with smaller lungs, the canary would expire quickly, giving a vital early warning.
