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
