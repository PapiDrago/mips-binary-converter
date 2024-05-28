# Binary converter

This program converts a binary, or decimal, or hexadecimal represented as an ASCII string in the equivalent decimal, hexadecimal, binary number by using the polynomial notation and ASCII character representation.

## Features

This converter has 4 operarting modes.
To pick the desired operating mode, it is necessary to write the binary ASCII representation of a number between 0 and 3 in the 'INPUT' memory area inside the data segment of the program.
The matching between the number and the operating mode is the following:
"0" -> Decimal to Binary 
"1" -> Binary a Decimal
"2" -> Hexadecimal a Decimal
"3" -> Decimal a Hexadecimal

The program checks invalid inputs and occurencies of carry.

## License
[MIT](LICENSE)