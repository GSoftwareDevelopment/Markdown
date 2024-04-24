# Introduction

The repository contains a library for MAD Pascal that offers Markdown source parsing capabilities.

Read the following information and the example file.

## Supports tags

- *H1-H4* headers
- *Code inserts* i.e. a single "backwards" apostrophe (the one under the tilde)
- *Blocks of code*, including language definition
- *REM block* (proper name) three consecutive dashes - can be used as a multi-line comment, or a block of specific data, e.g. JSON 🙂
- *Indentation* - recognizes the TAB character, but deletes it, increasing the value of IndentID 🙂
- *Dot lists* - dash + space
- *Numeric lists* - number + period + space
- *Links* - [title](link)
- Two styles:
  - *Inverted* - between the asterisk characters
  - *Underline* - between the underscore characters

## Features:

- Ability to read in data during parsing, which theoretically removes the 255 character limit per line/paragraph.
- Use of procedural variables to call procedures:

  `_callFlushBuffer` - a call procedure called to perform a user action on the returned string. In simple terms, displaying the text.

  `_callFetchLine` - a call procedure, fetching a line (paragraph) of MarkDown code into a buffer for processing.

- Tags as well as styles provide information to the call procedure every word, ~~except for the start of the REM and CODE block~~.

- Each new line resets the tag and style, as long as it is not a REM or CODE block.

- Block REM, like block CODE, must start at the beginning of the line. The characters after the tag, have the Printable style disabled, but are passed to the call procedure ~~in their entirety (without splitting into words)~~, so you can parse them on your own.

  The CODE block thus provides information about the language used.

- If a tag or style is not recognized correctly, it is treated as plain text and delivered in that form along with the characters to the call procedure

- The `lineStat` variable, when bit 7 is set, returns the error number in the rest of the bits.
Current predefined error codes:

- `errLineTooLong` - While fetching a line, the line buffer has reached the end, not stating EOL.
- ~~`errBufferEnd` - While parsing a line, the line buffer has reached the end, not asserting EOL.~~

When bit 7 is not set, this variable contains the status of the parsed line. i.e. whether it is at the beginning of the line (`statLineBegin`) and whether it is at the beginning of the word (`statWordBegin`).

- It is possible to abort the parsing.
  From the `call` procedure, set the value of the `lineStat` variable to the predefined value `errBreakParsing`.

## Known limitation

- ~~Limit line (paragraph) length to 255 bytes!~~
- The maximum length of content between styles and in the hyperlink tag is 255 characters.
- no table support (yet)

# Description of the examples

## example1.pas

The file contains a sample, simple implementation of the Markdown parser.

The data is retrieved from memory (defined in an array constant)
The `getLine` procedure provides a single line of data to the parser. It also performs a simple end-of-line character conversion of type CR/LF. Returns an error when the line buffer is exceeded.

The `printMD` procedure is responsible for displaying the processed text on the screen.
It distinguishes the `Printable` style, which is used for non-printable text fragments, while allowing you to process this information.
Distinguishes the `Invers` style and hyperlinks on the screen.
Besides, it displays the rest of the text.

The `parseMD` procedure prepares the engine variables for operation.

## example2.pas

Like `example1.pas` it implements a simple Markdown document display, but the content is loaded from a file.
The call procedure named `readLineFromFile` shows an implementation of such a solution.
It uses the full size of the buffer and allows you to read in data.

As a call parameter, specify the name of the file containing the document in MD format, e.g. `example1.pas`.
```
A:>EXAMPLE2.XEX DOC.MD
```

The program works with the default station `D:`.