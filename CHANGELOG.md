v.0.6
- call procedure `_callFlushBuffer` is a function, it returns to the parser an error or 0 (zero) when everything OK
- parser variable name matching:
  `parseChar` -> `parseBufPtr` - pointer to the position in the buffer.
  `ch` -> `parseLastChar` - the last parsed character.
- possibility to skip the parser initialization, by passing the `statContinueParse` flag.
- improved parsing of styles. For `FIXED` style, all characters are parsed, up to the close or end of the line
- `example2.pas` adjusted new guidelines.
  It now allows you to format your document correctly in different character modes (40/64/80 in SDX)
- finally ISes are macros

v.0.5 ( next day, and next day ;) )

- renaming the parsing routine to `parseMarkdown(setup:byte)`
- Fixing block tag support
- Fixing style parsing
- The *horizontal line* (an unmentioned tag `---` ) may have caused the internal stack to overflow, by not pulling down the value at the end of the line
- use of is'es in parser code
- ~~(test) optional use of macros for is'es, by defining the `UseMakro4Ises` directive~~
- *Escape* tag - character following the escape character, is not parsed. It passes as a printing character
- Enhance headers from H1 to H8
- Inline indentation is now interpreted for spaces as well
  Every two consecutive spaces at the beginning of a line, define one level of indentation.
  _Note! The indentations are not sent by the procedure `call`._
- removing redundant spaces - add `statRedundantSpaces` as a call parameter to the `parseMarkDown()` procedure
- `example2.pas` - document formatting with indentation for lists and moving an uncompressed word to a new line.

v.0.5

- Changing the concept of tag format - from bit to number.
- Line functions: `isLineBegin` and `isLineEnd` - indicate `True`, for the beginning and end of the line, respectively
- Style function: `isStyle` - return `True` if specified style is set
- Tag functions: `isBeginTag` and `isEndTag` - indicate `True`, for the beginning and end of the tag, respectively
- Tag grouping functions: `isHeader`, `isLink`, `isList`, `isBlock` - return `True` if the specified tag belongs to the given group
- New parser state `statEndOfLine` indicating the end of a line when calling the `call` function
- further code optimizations :)
- An extended example of `example2.pas` showing a more advanced way of presenting text

v.0.4

- REM, CODE, CODEINSERT as block tag signature
- block REM has new tag `<<<` `>>>` and no longer requires separating spaces
- new tag Image `![title](link)`

v.0.3
- procedure `_callFetchData` is now a function!
  simplifies implementation of reading a data stream
- Tag stack, allowing tags to be embedded
- adjustable tag stack size
- code size and speed optimization
- improvement of tag recognition
- block REM works on a single line
  However, after opening and by closing there must be a whitespace character.

v.0.2
- Enhance headers from H1 to H4
- Ability to read in data during parsing, which theoretically removes the 255 character limit per line/paragraph
- The maximum length of content between styles and in the hyperlink tag is 255 characters
- LF EOL conversion during parsing (CR is not recognized!)

v.0.1
Supports tags:
- *H1-H3* headers
- *Code inserts* i.e. a single "backwards" apostrophe (the one under the tilde)
- *Blocks of code*, including language definition
- *REM block* (proper name) three consecutive dashes - can be used as a multi-line comment, or a block of specific data, e.g. JSON
- *Indentation* - recognizes the TAB character, but deletes it, increasing the value of `lineIndentation`
- *Dot lists* - dash + space
- *Numeric lists* - number + period + space
- *Links* - `[title](link)`
- Two styles:
  - *Inverted* - between the asterisk characters
  - *Underline* - between the underscore characters

Features:
- Use of procedural variables to call procedures:
  `_callFlushBuffer` - a call procedure called to perform a user action on the returned string. In simple terms, displaying the text
  `_callFetchLine` - a call procedure, fetching a line (paragraph) of MarkDown code into a buffer for processing

- ~~Limit line (paragraph) length to 255 bytes!~~

- No table support (yet)

- Tags as well as styles provide information to the call procedure every word, except for the start of the REM and CODE block

- Each new line resets the tag and style, as long as it is not a REM or CODE block

- Block REM, like block CODE, must start at the beginning of the line
  The characters after the tag, have the Printable style disabled, but are passed to the call procedure~~ in their entirety (without splitting into words)~~, so you can parse them on your own.
  The CODE block thus provides information about the language used.

- If a tag or style is not recognized correctly, it is treated as plain text and delivered in that form along with the characters to the call procedure

- The `parseError` variable - when bit 7 is set, returns the parseError number in the rest of the bits.
  Current predefined `parseError` codes:

  - `errEndOfDocument`
  - `errBufferEnd`
  - `errTagStackEmpty`
  - `errTagStackFull`
  - `errBreakParsing`

- The `lineStat` - this variable contains the status of the parsed line

  - `statWordBegin` - at the beginning of the word
  - `statLineBegin` - at the beginning of the line
  - `statEndOfLine` - at the ending of the line
  - `statESC` - Is there an escape character

- It is possible to abort the parsing.
  From the `call` procedure, set the value of the `lineStat` variable to the predefined value `errBreakParsing`.
