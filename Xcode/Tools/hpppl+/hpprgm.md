### User BASIC programs
**"*.hpprgm"**</br>
There are two known types of files using the .hpprgm extension, one includes the script name in the metadata. Both versions use UTF16 (little endian byte order) for the name and the main data.

**Unamed .hpprgm files**
This version of the file does not includes any name, just the length of the data, and the data itself.

|Byte       |00  |01|02|03|04|05|06|07|08       |09|10|11|12|13|14|15|16  |17|18|19|20  |
|:------    |:---|:-|:-|:-|:-|:-|:-|:-|:--------|:-|:-|:-|:-|:-|:-|:-|:---|:-|:-|:-|:---|
|Example    |0C  |00|00|00|00|00|00|00|00       |00|00|00|00|00|00|00|08  |00|00|00|--  |
|Description|Type|  |  |  |  |  |  |  |Name Flag|  |  |  |  |  |  |  |Size|00|00|00|Data|
|Additional |    |  |  |  |  |  |  |  |Unnamed  |  |  |  |  |  |  |  |64K

**Named .hpprgm files**
Here, the name is appended to the header without any size descriptors (the name ends with two consecutive zero-valued bytes and after that, the data begins).

|Byte       |00  |01|02|03|04|05|06|07|08       |09|10|11|12|13|14|15|16        |17  |.. |..|..  |
|:------    |:---|:-|:-|:-|:-|:-|:-|:-|:--------|:-|:-|:-|:-|:-|:-|:-|:---------|:---|:--|:-|:---|
|Example    |0C  |00|00|00|00|00|00|00|01       |00|00|00|00|00|00|00|31        |....|00 |00|... |
|Description|Type|  |  |  |  |  |  |  |Name Flag|  |  |  |  |  |  |  |Name Start|Name|End|Data|
|Additional |    |  |  |  |  |  |  |  |Named    |  |  |  |  |  |  |  |Name end with 0×00, 0×00
