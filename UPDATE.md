### Xprime 26.2
There have been some significant changes to Xprime in the upcoming 26.2 release. One of the biggest changes is the removal of Export. With the new way files are opened and saved in 26.2, exporting is no longer needed. For example, if you had a project written in PPL+ and wanted to save an HPPRGM version somewhere on disk, you previously had to use Export → Quick as HPPRGM. In the upcoming release, you can simply use Save As and choose the file type.

This doesn’t just apply to PRGM, PRGM+, and PPL files — you can also open an HPNOTE file, edit it, and save it as NTF, NOTE, HPNOTE, etc. This workflow has been significantly simplified.

You can now also easily change the project name. It’s no longer based on the parent folder; instead, whatever you name the .xprimeproj file becomes your project name.

There have also been several build improvements. If you’re writing an application, the build option now produces an HPAPPPRGM file. If it’s a regular program (no HPAPPDIR folder), it builds an HPPRGM file.
