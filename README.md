# Introduction

The repository contains a library for MAD Pascal that offers Markdown source parsing capabilities.

Read the following information and the example file.

## Supports tags

- *H1-H4* headers
- *Code* - with including language definition
- *REM block* (proper name) `<<<` … `>>>` - everything contained between these tags, has Printable style disabled.
  It can be considered like a line or comment insertion, or with a little effort, parsed as, say, JSON
- *Indentation* - recognizes the TAB character, but deletes it, increasing the value of `lineIndentation`
- *Unordered lists* - dash + space
- *Ordered lists* - number + period + space
- *Links* - `[title](link)`
- Images - `![title](link)`
- *Horizontal rule* - `---` Single horizontal line
- Two styles:
  - *Inverted* - between the asterisk `* … *` characters
  - *Underline* - between the underscore `_ … _` characters
  - Fixed - between the single "backwards" apostrophe ``` … ` `` 

## Features:

- Ability to read in data during parsing, which theoretically removes the 255 character limit per line/paragraph.
- LF EOL conversion during parsing
- Use of procedural variables to call procedures:

  `_callFlushBuffer` - a call procedure called to perform a user action on the returned string. In simple terms, displaying the text.

  `_callFetchLine` - a call function, fetching a line (paragraph) of MarkDown code into a buffer for processing.

- Tags as well as styles provide information to the call procedure every word.

- Each new line resets the tag and style, as long as it is not a REM or CODE block.

- Block REM, like block CODE, must start at the beginning of the line. The characters after the tag, have the Printable style disabled, but are passed to the call procedure, so you can parse them on your own.

  The CODE block thus provides information about the language used.

- If a tag or style is not recognized correctly, it is treated as plain text and delivered in that form along with the characters to the call procedure

- The `parseError` variable - when bit 7 is set, returns the parseError number in the rest of the bits.
Current predefined parseError codes:

- `errEndOfDocument`
- `errBufferEnd`
- `errTagStackEmpty`
- `errTagStackFull`
- `errBreakParsing`

- The `lineStat` - this variable contains the status of the parsed line.

  Whether it is at the beginning of the line (`statLineBegin`).

  Whether it is at the beginning of the word (`statWordBegin`).

- It is possible to abort the parsing.
  From the `call` function, set the value of the `parseError` variable to the predefined value `errBreakParsing`.

## Known limitation

- The maximum length of content between styles and in the hyperlink tag is 255 characters.
- no table support (yet)

# Description of the examples

## example1.pas

The file contains a sample, simple implementation of the Markdown parser.

The data is retrieved from memory (defined in an array constant)
The `getLine` procedure provides a single line of data to the parser. It also performs a simple end-of-line character conversion of type CR/LF. Returns an parseError when the line buffer is exceeded.

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
