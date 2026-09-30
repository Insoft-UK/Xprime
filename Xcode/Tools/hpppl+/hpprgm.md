## App Data
***"*.hpapp", "*.hpappnote", "*.hpapprgm"***: data for applications, built-in or others.
For built-in applications, *.hpappnote files are 2+ bytes long, and *.hpappprgm files are 22+ bytes long.


### User BASIC programs
**"*.hpprgm"**

There are two known types of files using the .hpprgm extension, one includes the script name in the metadata. Both versions use UTF16 (little endian byte order) for the name and the main data.

The current structures can handle files larger than 64K, but only in theory since some stuff will fail with these larger files, for example the size of the file is truncated to the modulus of 64K in the calculator and the connectivity kit will warn us about that the file it is too large.

#### Unnamed .hpprgm files

This version of the file does not includes any name, just the length of the data, and the data itself.

<table>
  <thead>
  <tr>
    <th>Byte</th><th>0</th><th>1</th><th>2</th><th>3</th><th>4</th><th>5</th><th>6</th><th>7</th><th>8</th>
    <th>9</th><th>10</th><th>11</th><th>12</th><th>13</th><th>14</th><th>15</th><th>16</th><th>17</th>
    <th>18</th><th>19</th><th>20</th>
  </tr>
  </thead>
<tbody>
  <tr>
    <td>Example</td>
    <td>0C</td>
    <td>00</td>
    <td>00</td>
    <td>00</td>
    <td>00</td>
    <td>00</td>
    <td>00</td>
    <td>00</td>
    <td>00</td>
    <td>00</td>
    <td>00</td>
    <td>00</td>
    <td>00</td>
    <td>00</td>
    <td>00</td>
    <td>00</td>
    <td>08</td>
    <td>00</td>
    <td>00</td>
    <td>00</td>
    <td>...</td>
  </tr>
  <tr>
    <td>Description</td>
    <td>Type</td>
    <td></td>
    <td></td>
    <td></td>
    <td></td>
    <td></td>
    <td></td>
    <td></td>
    <td nowrap>Name flag</td>
    <td></td>
    <td></td>
    <td></td>
    <td></td>
    <td></td>
    <td></td>
    <td></td>
    <td colspan="4">Size</td>
    <td>Data</td>
  </tr>
  <tr>
    <td>Additional</td>
    <td></td>
    <td></td>
    <td></td>
    <td></td>
    <td></td>
    <td></td>
    <td></td>
    <td></td>
    <td>Unnamed</td>
    <td></td>
    <td></td>
    <td></td>
    <td></td>
    <td></td>
    <td></td>
    <td></td>
    <td colspan="2" nowrap>64K current fw limit</td>
    <td></td>
    <td></td>
    <td></td>
  </tr>
</tbody></table>

#### Named .hpprgm files

Here, the name is appended to the header without any size descriptors (the name ends with two consecutive zero-valued bytes and after that, the data begins).

<table><thead>
  <tr>
    <th>Byte</th>
    <th>0</th>
    <th>1</th>
    <th>2</th>
    <th>3</th>
    <th>4</th>
    <th>5</th>
    <th>6</th>
    <th>7</th>
    <th>8</th>
    <th>9</th>
    <th>10</th>
    <th>11</th>
    <th>12</th>
    <th>13</th>
    <th>14</th>
    <th>15</th>
    <th>16</th>
    <th>17</th>
    <th>...</th>
    <th>...</th>
    <th>...</th>
  </tr></thead>
<tbody>
  <tr>
    <td>Example</td>
    <td>0C</td>
    <td>00</td>
    <td>00</td>
    <td>00</td>
    <td>00</td>
    <td>00</td>
    <td>00</td>
    <td>00</td>
    <td>01</td>
    <td>00</td>
    <td>00</td>
    <td>00</td>
    <td>00</td>
    <td>00</td>
    <td>00</td>
    <td>00</td>
    <td>31</td>
    <td>...</td>
    <td>00</td>
    <td>00</td>
    <td>...</td>
  </tr>
  <tr>
    <td>Description</td>
    <td>Type</td>
    <td></td>
    <td></td>
    <td></td>
    <td></td>
    <td></td>
    <td></td>
    <td></td>
    <td nowrap>Name flag</td>
    <td></td>
    <td></td>
    <td></td>
    <td></td>
    <td></td>
    <td></td>
    <td></td>
    <td nowrap>Name start</td>
    <td>Name</td>
    <td colspan="2" nowrap>Name end</td>
    <td>Data</td>
  </tr>
  <tr>
    <td>Additional</td>
    <td></td>
    <td></td>
    <td></td>
    <td></td>
    <td></td>
    <td></td>
    <td></td>
    <td></td>
    <td>Named</td>
    <td></td>
    <td></td>
    <td></td>
    <td></td>
    <td></td>
    <td></td>
    <td></td>
    <td colspan="4" nowrap>Name end with 0×00, 0×00</td>
    <td></td>
  </tr>
</tbody></table>

There is a bit of metadata at the beginning, labeled as type: ''The metadata at the beginning is about "information about exported variables/programs (so the system knows how to recognize them, and number of arguments for example, a compiled bytecode area, and the source."''<ref>Tim Wessman, Aug. 20 2013  -  http://www.omnimaga.org/index.php?topic=16826.msg304202#msg304202</ref>)
''"On poweroff, the source is saved to flash if it has been modified. The bytecode is discarded."''<ref>Tim Wessman, Aug. 20 2013  -  http://www.omnimaga.org/index.php?topic=16826.msg304202#msg304202</ref>

### Settings
***"calc.settings", "cas.settings, "settings"***: binary information about settings.

#### Structure
calc.settings contains a number of UTF-16 little-endian strings, among which some names for built-in apps, and the user input in the home screen (under a semi-internal form: strings such as "EVALLIST" and "NEG" can be seen).


### Lists
***"*.hplist": list files***: <br/> Some facts gathered over time: (**Some unknown bytes are about "flags indicating status, location in memory, or similar"**<ref>Tim Wessman, Aug. 20 2013  -  http://www.omnimaga.org/index.php?topic=16826.msg304191#msg304191</ref>)

#### Structure
* The first group appears to contain a common "header" : [01/02] 00 16 00. The first byte apparently is 01 for a calculator-generated list or 02 for a connectivity-kit generated one.
* The second group contains the number of elements in the list (only the 1st byte of the group ?), which we'll call ****'n'****.
* The next group(s) (****'n'**** different instances of this kind of group) contains some kind of timestamp as its bytes changes over time for a same, given, list.
* The next 4 group(s) (****'n'**** different instances of this kind of 4-groups) contain the element's actual data (elements in reverse order of the list) :
** The first (and second ?) subgroup contains some info about the number, like '01' on the 4th byte if positive (or zero), or 'FF' if negative
** The first 3 bytes of this subgroup are, as far as we know, not about the element itself.
** The 2nd subgroup's indicates the exponent (length of the number, minus 1). If positive, it's directly given (in hex) on the first byte (the 3 remaining right bytes being 0), and if negative, it's given by substracting from 0x100 the absolute value of the exponent (e.g. 'FD' for -3). The 3 remaining right bytes are FF.
** The 2 last subgroups contain the number, from right to left, little endian.<br/>

==== Examples ====
* {} (default/empty): a 8-byte file:          01 00 16 00  <ins>00</ins> 00 00 00
* {0} is stored as a 28-byte file:            01 00 16 00  <ins>01</ins> 00 00 00  ''18 2D 23 01''  <ins>00 00 00 '''01'''  '''00''' 00 00 00  00 00 00 00  00 00 00 ***00***</ins>
* {1} is stored as a 28-byte file:            01 00 16 00  <ins>01</ins> 00 00 00  ''38 2D 23 01''  <ins>00 00 00 '''01'''  '''00''' 00 00 00  00 00 00 00  00 00 00 ***01***</ins>
* {2} is stored as a 28-byte file:            01 00 16 00  <ins>01</ins> 00 00 00  ''58 2D 23 01''  <ins>00 00 00 '''01'''  '''00''' 00 00 00  00 00 00 00  00 00 00 ***02***</ins>
* {1337} is stored as a 28-byte file:         01 00 16 00  <ins>01</ins> 00 00 00  ''40 75 8D 01''  <ins>02 00 10 '''01'''  '''03''' 00 00 00  00 00 00 00  00 '''70 33 01'''</ins>
* {9001} is stored as a 28-byte file:         01 00 16 00  <ins>01</ins> 00 00 00  ''80 75 8D 01''  <ins>01 00 10 '''01'''  '''03''' 00 00 00  00 00 00 00  00 '''10 00 09'''</ins>
* {-9001} is stored as a 28-byte file:        01 00 16 00  <ins>01</ins> 00 00 00  ''A0 75 8D 01''  <ins>01 00 10 '''FF'''  '''03''' 00 00 00  00 00 00 00  00 '''10 00 09'''</ins>
* {-1} is stored as a 28-byte file:           01 00 16 00  <ins>01</ins> 00 00 00  ''08 2D 23 01''  <ins>00 00 00 '''FF'''  '''00''' 00 00 00  00 00 00 00  00 '''00 00 01'''</ins>
* {1.23456789012E19} [...] 28-byte:           01 00 16 01  <ins>01</ins> 00 00 00  ''D8 5B AD 01''  <ins>01 00 10 '''01'''   '''13''' 00 00 00  00 '''20 01 89  67 45 23 01'''</ins>
* {0.00123} is stored as a 28-byte file:      02 00 16 01  <ins>01</ins> 00 00 00  ''E8 60 AD 01''  <ins>01 00 10 '''01'''  '''FD FF FF FF'''  00 00 00 00  00 00 '''23 01''' </ins>
* {1,2} is stored as a 48-byte file:          01 00 16 00  <ins>02</ins> 00 00 00  ''18 2D 23 01''  ''38 2D 23 01''  <ins>00 00 00 01  00 00 00 00  00 00 00 00  00 00 00 02</ins>  <ins>00 00 00 01  00 00 00 00  00 00 00 00  00 00 00 01</ins>
* {-9001,1337,2} is [...] 68-byte file:      01 00 16 00  <ins>03</ins> 00 00 00  ''80 75 8D 01''  ''50 75 8D 01''  ''38 2D 23 01''  <ins>00 00 00 01  00 00 00 00  00 00 00 00  00 00 00 02</ins>  <ins>02 00 10 01  03 00 00 00  00 00 00 00  00 70 33 01</ins>  <ins>01 00 10 FF  03 00 00 00  00 00 00 00  00 10 00 09</ins>

### Matrices ===
***"*.hpmat"***

#### Structure ====
The "header" appears to be : 01 00 14 01
* [ [ 0 ] ] (default) is a 24-byte file:   01 00 14 01 02 00 00 00 <ins>01 00 00 00 01 00 00 00 00 00 00 00 00 00 00 ***00***</ins>
* [ [ 1 ] ] is stored as a 24-byte file:   01 00 14 01 02 00 00 00 <ins>01 00 00 00 01 00 00 00 00 00 00 00 00 00 00 ***01***</ins>


### Notes
***"*.hpnote": note (text) files***

#### Structure
The file seems to contain the text of the note as UTF-16 little endian, followed by a null byte (U+0000), followed by some formatting information starting by "CSWD110".


### Test modes
'''"testmodes.hptestmodes"''': current settings for the exam mode ?

