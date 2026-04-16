<img src="https://github.com/Insoft-UK/PrimePlus/blob/main/assets/Icon.png" style="width: 128px" />


## PPL+ for HP Prime Programming Language
**Command Line Tool**

**PPL+** is a pre-processor that improves readability and maintainability of HP PPL code. It supports custom regex rules, can extract PPL source from **.hpprgm** and **.hpappprgm** files, and can also **compress** PPL source into a compact, optimized form for the HP Prime. PPL+ supports add-ons that enable conversion of Adafruit resources into PPL.
Using these **add-ons**, **<a href="https://github.com/Insoft-UK/PrimePlus/blob/main/assets/HP.md">Adafruit</a>** fonts and Adafruit_GFX **.h** files can be converted to PPL. In addition, the **GROB** add-on allows image files to be imported and converted as well.

**Compression** of your code results in it taking up less space, making it use less storage of your HP Prime's storage memory giving you more space for more programs.

**Reformating** your code enforce a consistent coding style throughout your project, making it easier for multiple developers to work on the same codebase. It helps maintain a uniform look and feel, which can enhance code readability. Readability: Well-formatted code is easier to read and understand.

>Support for Pascal syntax is also included. If your code contains or is written in Pascal, it will be automatically converted to PPL syntax, since PPL itself is a dialect of Pascal.

>[!IMPORTANT]
>PPL+ discontinued support for #include. It's been replaced by the Pascal-style include directives: {$I file} or {$include file}.

Download links: <a href="https://insoft.uk/action/?method=downlink&path=macos&file=pplplus-universal.pkg">macOS</a> | <a href="https://insoft.uk/action/?method=downlink&path=pc&file=pplplus-win-x86_64.zip">Windows</a> | <a href="https://insoft.uk/action/?method=downlink&path=linux&file=pplplus-linux-x86_64.zip">Linux</a>

>PPL+ for macOS is installed in /usr/local/bin. To uninstall it, run: `sudo rm /usr/local/bin/ppl+`

`Usage: ppl+ <input-file> [-o <output-file>] [-v]`

<table>
  <thead>
    <tr align="left">
      <th>Options</th>
      <th>Description</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td>-o <output-file></td><td>Specify the filename for generated code</td>
    </tr>
    <tr>
      <td>-c or --compress</td><td>Specify if the PPL code should be compressed</td>
    </tr>
    <tr>
      <td>-r or --reformat</td><td>Specify if the PPL code should be reformated</td>
    </tr>
    <tr>
      <td>-v or --verbose</td><td>Display detailed processing information</td>
    </tr>
    <tr>
      <td colspan="2"><b>Additional Commands</b></td>
    </tr>
    <tr>
      <td>--version</td><td>Displays the version information</td>
    </tr>
    <tr>
      <td>--build</td><td>Displays the build information</td>
    </tr>
    <tr>
      <td>--help</td><td>Show this help message</td>
    </tr>
  </tbody>
</table>

>[!WARNING]
PPL+ 26 (v5.x) will transition to using <a href="https://unicode-org.github.io/icu/userguide/strings/regexp.html">ICU</a>. As a result, prebuilt Windows 11 binaries will no longer be provided. Users running Windows 11 who wish to use PPL+ 26 (v5.x) will need to install ICU for Windows and compile the command line tool from source.

### Regular Expressions
**Example: Extending PPL with Switch-Case Functionality Using Regex**

This example demonstrates how to use **regex** (regular expressions) to add **switch-case** control flow to the PPL language, similar to the switch statements found in other programming languages.

```
regex >`\bswitch +([a-z_.:]+)`i LOCAL sw{$I %SCOPE%} := $1;\aCASE
regex >`\bcase +([^ ]+) +do\b`i IF sw\`{$I %SCOPE%}-1` == $1 THEN
switch X
    case 0 do
    end;
end;
```
**PPL+ Preprocessor: Switch-Case to PPL Conversion**

The PPL+ preprocessor generates valid PPL code by transforming switch-case statements into standard PPL case statements. This preprocessing step allows you to write more intuitive switch-case syntax while maintaining full compatibility with the PPL language, as the output is pure, valid PPL code.

```
LOCAL sw0 := X;
CASE
  IF sw0 == 0 THEN
  END;
END;
```

### Code Stack

A code stack provides a convenient way to store code snippets that can be retrieved and used later.

**Example: how code stack can be used for a regular expresion to bring a bit of C style to PPL**

```
regex >`\bfor *([^;]+); *([^;]+); *([^;]+) +do\b`i $1;\aWHILE $2 DO__PUSH__`\i$3;\a`
regex >`\bend;`i __POP__END;
function()
begin
    for i=0; i<2; i=i+1 do
        A := A+1;
    end;
end;
```

**PPL+ Preprocessor: PPL Converstion**

```
function()
BEGIN
  i := 0; WHILE i<2 DO
    A := A + 1;
  i := i + 1; END;
END;
```

### Assignment Style

In <b>PPL+</b>, the = operator is treated as := (assignment) by default, whereas in standard <b>PPL</b>, = is interpreted as == (equality). This behavior in PPL+ can be explicitly controlled using the directive:

```#pragma mode( assignment(:=) )```

This will inform PPL+ that PPL assignment is to be used only, allowing you to use = as equality.

When = is used for assignment, the PPL := operator is still supported; however, using := is strongly recommended.

>[!IMPORTANT]
In PPL+ by default `=` is treated as `:=` were in PPL `=` is treated as `==`

## Alias
Added support for defining aliases that include a dot (e.g., alias hp::text := HP.Text).

>[!NOTE]
The PPL+ preprocessor is subject to change but aims to maintain some level of compatibility with previous versions.
