v.0.3
- procedure `_callFetchData` is now a function!
  simplifies implementation of reading a data stream
- Tag stack, allowing tags to be embedded
- adjustable tag stack size
- code size and speed optimization
- improvement of tag recognition
-

v.0.2
- Enhance headers from H1 to H4
- Ability to read in data during parsing, which theoretically removes the 255 character limit per line/paragraph.
- The maximum length of content between styles and in the hyperlink tag is 255 characters.
- LF EOL conversion during parsing (CR is not recognized!)

v.0.1
Supports tags:
- *H1-H3* headers
- *Code inserts* i.e. a single "backwards" apostrophe (the one under the tilde)
- *Blocks of code*, including language definition
- *REM block* (proper name) three consecutive dashes - can be used as a multi-line comment, or a block of specific data, e.g. JSON 🙂
- *Indentation* - recognizes the TAB character, but deletes it, increasing the value of lineIndentation 🙂
- *Dot lists* - dash + space
- *Numeric lists* - number + period + space
- *Links* - [title](link)
- Two styles:
  - *Inverted* - between the asterisk characters
  - *Underline* - between the underscore characters

Features:
- Use of procedural variables to call procedures:
`_callFlushBuffer` - a call procedure called to perform a user action on the returned string. In simple terms, displaying the text.
`_callFetchLine` - a call procedure, fetching a line (paragraph) of MarkDown code into a buffer for processing.

- ~~Limit line (paragraph) length to 255 bytes!~~

- No table support (yet)

- Tags as well as styles provide information to the call procedure every word,
except for the start of the REM and CODE block.

- Each new line resets the tag and style, as long as it is not a REM or CODE block.

- Block REM, like block CODE, must start at the beginning of the line. The characters
after the tag, have the Printable style disabled, but are passed to the call procedure
in their entirety (without splitting into words), so you can parse them on your own.
The CODE block thus provides information about the language used.

- If a tag or style is not recognized correctly, it is treated as plain text and delivered
in that form along with the characters to the call procedure

- The `lineStat` variable, when bit 7 is set, returns the parseError number in the rest of the bits.
Current predefined parseError codes:
- `errLineTooLong` - While fetching a line, the line buffer has reached the end, not stating EOL.
- `errBufferEnd` - While parsing a line, the line buffer has reached the end, not asserting EOL.
When bit 7 is not set, this variable contains the status of the parsed line. i.e.
whether it is at the beginning of the line (`statLineBegin`) and whether it is at the beginning
of the word (`statWordBegin`).

- It is possible to abort the parsing.
From the `call` procedure, set the value of the `lineStat` variable to the predefined value `errBreakParsing`.
