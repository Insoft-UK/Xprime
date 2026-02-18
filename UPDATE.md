### Xprime 26.2
- **Export feature removed**: The traditional Export menu is no longer needed because the new file handling makes it redundant.

- **Improved Save workflow**: Instead of exporting to another file type (e.g., saving a PPL+ project as an HPPRGM), you can now use Save As and directly choose the file format you want. This works for all supported file types (PRGM, PPL, HPPRGM, etc.).

- **Editing and saving other file types simplified**: Files like HPNOTE can now be opened, edited, and saved as any other supported note format (NTF, NOTE, etc.) without extra steps.

- **Project naming simplified**: The project name is no longer tied to the parent folder; instead, the .xprimeproj file name determines the project name.

- **Improved build outputs**: When building code:
  - Applications now build directly to HPAPPPRGM files.
  - Regular programs (without an HPAPPDIR) build to HPPRGM.
  
These changes greatly simplify the development workflow in Xprime, especially around file management and builds — moving away from the older export-centric process to a more intuitive open/save workflow.
