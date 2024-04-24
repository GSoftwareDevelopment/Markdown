unit MarkDown;

(*
Supports tags:
- *H1-H3* headers
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

Features:
- Use of procedural variables to call procedures:
`_callFlushBuffer` - a call procedure called to perform a user action on the returned string. In simple terms, displaying the text.
`_callFetchLine` - a call procedure, fetching a line (paragraph) of MarkDown code into a buffer for processing.

- Limit line (paragraph) length to 255 bytes!

- Tags as well as styles provide information to the call procedure every word,
except for the start of the REM and CODE block.

- Each new line resets the tag and style, as long as it is not a REM or CODE block.

- Block REM, like block CODE, must start at the beginning of the line. The characters
after the tag, have the Printable style disabled, but are passed to the call procedure
in their entirety (without splitting into words), so you can parse them on your own.
The CODE block thus provides information about the language used.

- If a tag or style is not recognized correctly, it is treated as plain text and delivered
in that form along with the characters to the call procedure

- The `lineStat` variable, when bit 7 is set, returns the error number in the rest of the bits.
Current predefined error codes:
- `errLineTooLong` - While fetching a line, the line buffer has reached the end, not stating EOL.
- `errBufferEnd` - While parsing a line, the line buffer has reached the end, not asserting EOL.
When bit 7 is not set, this variable contains the status of the parsed line. i.e.
whether it is at the beginning of the line (`statLineBegin`) and whether it is at the beginning
of the word (`statWordBegin`).

- It is possible to abort the parsing.
From the `call` procedure, set the value of the `lineStat` variable to the predefined value `errBreakParsing`.
*)

interface
const
  cTAB      = #8;   // indentation
  cLF       = #10;  // new line
  cCR       = #13;  // combine with cLF is new line
  cSPACE    = #32;
  cRETURN   = #155; // Atari new line

//                     Considered state only at...
  cESC      = '\'; // the beginning of the Word
  cHEADER   = '#'; // the beginning of the Line
  cOLINK    = '['; // the beginning of the Word
  cCLINK    = ']'; // the end of the Word
  cOADDR    = '('; // after CLINK Tag
  cCADDR    = ')'; // the end of the CLINK Tag
  cSINVERS  = '*'; // the beginning of the Word and at the end
  cSUNDER   = '_'; // the beginning of the Word and at the end
  cREM      = '-'; // the beginning of the Line (3 times)
  cCODE     = '`'; // the beginning of the Line (3 times)
  cCODEINS  = '`'; // the beginning of the Word (1 time)
  cLIST     = '-'; // the beginning of the Line
  cNUMLIST0 = '0'; // the beginning of the Line
  cNUMLIST9 = '9'; // the beginning of the Line
  cNUMLIST  = '.'; // the end of the first Word and if last style is NUMLISTx

// tags
  tagLink               = %10000000;
  tagLinkDescription    = %10000001;
  tagLinkDestination    = %10000010;

  tagCode               = %01000000;
  tagCodeInsert         = %01000001;
  tagCodeLanguage       = %01000010;

  tagREM                = %00100000;

  tagList               = %00001000;
  tagListPointed        = %00001001; // List pointed
  tagListNumbered       = %00001010; // List numbered

  tagHeader             = %00000100;
  tagH1                 = %00000101;  // Header level 1
  tagH2                 = %00000110;  // Header level 2
  tagH3                 = %00000111;  // Header level 3

// styles
  stylePrint            = %00000001;  // Printable word

  styleStyle            = %00000110;
  styleInvers           = %00000010;  // Invers video
  styleUnderline        = %00000100;  // Underline

// line status & errors
  statLineBegin         = %00000001;
  statWordBegin         = %00000010;
  statError             = %10000000;

  errLineTooLong        = statError + 1;
  errBufferEnd          = statError + 2;
  errBreakParsing       = %11111111;

//
//
//

// call type procedure
type
  TDrawProc=procedure();
  TFetchLine=procedure();

var
  parseStr:String     absolute __BUFFER;  // line buffer
  parseStrLen:Byte    absolute __BUFFER;  // line length
  _callFlushBuffer:TDrawProc;
  _callFetchLine:TFetchLine;

// work variables
  lineStat:Byte       absolute $F0;       // line status code
  indentID:Byte       absolute $F1;       // line indent
  ch:Char             absolute $F2;       // character
  curChar:PChar       absolute $F3;       // pointer to current character in MD source
  parseChar:PChar     absolute $F5;       // pointer to current character in line
  tag:Byte            absolute $F7;       // current tag code
  style:Byte          absolute $F8;       // current style code
  endPtr:Pointer;                         // pointer to the end of MD source

function parseTag():Byte;

implementation

procedure removeStrChars(count:Byte);
begin
  if count=0 then exit;
  dec(parseStrLen,count);
  move(@parseStr+count+1,@parseStr+1,parseStrLen);
  parseChar:=@parseStr;
end;

function countChars(nCh:Char):Byte;
begin
  result:=parseStrLen; ch:=parseChar^;
  while (result>0) and (ch=nCh) do
  begin
    inc(parseChar); dec(result); ch:=parseChar^;
  end;
  if result>0 then
  begin
    result:=parseStrLen-result;
  end;
end;

function findChar(nCh:char):Byte;
begin
  result:=parseStrLen;
  repeat
    inc(parseChar); dec(result);
    ch:=parseChar^;
  until (ch=nCh) or (result=0);
  if result>0 then
  begin
    result:=parseStrLen-result;
  end;
end;

function checkValInt():Byte;
begin
  result:=parseStrLen; ch:=parseChar^;
  while (result>0) and ((ch>=cNUMLIST0) and (ch<=cNUMLIST9)) do
  begin
    inc(parseChar); dec(result); ch:=parseChar^;
  end;
  if result>0 then
  begin
    result:=parseStrLen-result;
  end;
end;

//

procedure _flushBuffer();
var
  oldPSLen,len:Byte;

begin
  if parseStrLen=0 then exit;
  oldPSLen:=parseStrLen;
  len:=byte(parseChar-@parseStr);
  parseStrLen:=len;
  _callFlushBuffer();

  parseStrLen:=oldPSLen;
  removeStrChars(len);
end;

//

function parseTag():Byte;
var
  tmp:Byte;

  procedure toggleStyle(nStyle:Byte);
  begin
    if (lineStat and statWordBegin<>0) then
    begin
      if findChar(ch)>0 then
      begin
        removeStrChars(1);
        style:=style xor nStyle;
      end;
    end
    else
    if (style and nStyle<>0) then
    begin
      dec(parseChar); _flushBuffer();
      removeStrChars(1);
      style:=style xor nStyle;
    end;
  end;

  procedure checkCodeInsert();
  begin
    if (lineStat and statWordBegin<>0) then
    begin
      if countChars(cCODEINS)=1 then
      begin // code insert
        if findChar(cCODEINS)>0 then
        begin
          removeStrChars(1);
          tag:=tagCodeInsert;
        end;
      end
    end
    else
    if (tag=tagCodeInsert) then
    begin
      dec(parseChar); _flushBuffer();
      removeStrChars(1);
      tag:=0;
    end;
  end;

  procedure checkREMBlock();
  begin
    tmp:=countChars(cREM);
    if (lineStat and StatLineBegin<>0) and (tmp=3) then
    begin
      removeStrChars(3);
      if tag<>tagREM then
      begin
        tag:=tagREM; // style:=style and (not stylePrint);
      end
      else
      begin
        tag:=0; // style:=style or stylePrint;
      end;
      style:=style xor stylePrint;
      parseStrLen:=0; // rest line are ignored
    end
    else
    begin
      parseChar:=@parseStr+1; ch:=parseChar^;
    end;
  end;

  procedure checkCODEBlock();
  begin
    if (lineStat and statLineBegin<>0) then
    begin
      tmp:=countChars(cCODE);
      if (tmp=3) then // code block
      begin
        removeStrChars(3);
        if tag<>tagCode then
        begin
          tag:=tagCodeLanguage; style:=style and (not stylePrint);
          findChar(cSPACE);
          _flushBuffer();
          tag:=tagCode; style:=style or stylePrint;
        end
        else
          tag:=0;
        parseStrLen:=0; // rest line are ignored
      end
      else
      begin
        parseChar:=@parseStr+1; ch:=parseChar^;
      end;
    end;
  end;

  procedure checkListPointed();
  begin
    if (lineStat and statLineBegin<>0) then
    begin
      if (findChar(cSPACE)=1) then
      begin
        tag:=tagListPointed;
        _flushBuffer();
        tag:=tagList;
      end;
    end;
  end;

  procedure checkListNumbered();
  begin
    if (lineStat and statLineBegin<>0) then
    begin
      if (checkValInt()>0) and (ch=cNUMLIST) then
      begin
        if findChar(cSpace)=1 then
        begin
          tag:=tagListNumbered;
          _flushBuffer();
          tag:=tagList;
        end;
      end;
    end;
  end;

  procedure checkHeader();
  begin
    if (lineStat and statLineBegin<>0) then
    begin
      tmp:=countChars(cHEADER);
      if (tmp>0) and (tmp<=3) and (ch=cSPACE) then
      begin
        removeStrChars(tmp+1);
        tag:=tagHeader+tmp;
      end
      else
        tag:=0;
    end;
  end;

  procedure checkLinkAddress();
  begin
    if ch=cOADDR then
    begin
      if tag=tagLinkDescription then
      begin
        if (findChar(cCADDR)>0) then
        begin
          removeStrChars(1);
          tag:=tagLinkDestination;
        end;
      end;
    end
    else
    if tag=tagLinkDestination then
    begin
      dec(parseChar); _flushBuffer();
      removeStrChars(1);
      tag:=0; style:=style or stylePrint;
    end;
  end;

  procedure checkLinkDescription();
  begin
    if ch=cOLINK then
    begin
      if tag<>tagLinkDescription then
      begin
        if (findChar(cCLINK)>0) then
        begin
          if (findChar(cOADDR)=1) and (findChar(cCADDR)>0) then
          begin
            removeStrChars(1);
            tag:=tagLinkDescription;
          end;
        end;
      end;
    end
    else
    if tag=tagLinkDescription then
    begin
      dec(parseChar); _flushBuffer();
      removeStrChars(1); style:=style and (not stylePrint);
    end;
  end;

begin
  while (lineStat and statError=0) and (curChar<endPtr) do
  begin
    // fetch line
    _callFetchLine();

    parseChar:=@parseStr;
    lineStat:=statLineBegin+statWordBegin;
    indentID:=0;
    if (tag<>tagCode) and (tag<>tagREM) then
    begin
      tag:=0; style:=stylePrint;
    end;

    // parse line
    while (lineStat and statError=0) and (parseStrLen>0) do
    begin
      inc(parseChar);
      ch:=parseChar^;
      case ch of
      // white-space parse
        cESC, cTAB:
          begin
            if (ch=cTAB) and (lineStat and statLineBegin<>0) then inc(indentID);
            removeStrChars(1);
            continue;
          end;
        cSPACE:
          begin
            _flushBuffer();
            lineStat:=lineStat or statWordBegin;
            continue;
          end;
        cRETURN:
          begin
            _flushBuffer();
            style:=style and (stylePrint); // keep only Printable style flag status
            tag:=tag and (tagREM+tagCODE); // keep only REM tag flag status
            parseStrLen:=0;
            continue;
          end;
      end;

      if (tag<>tagCODE) then
        if (ch=cREM) then checkREMBlock();

      if (tag<>tagREM) then
        if (ch=cCODE) then checkCODEBlock();

      if (tag<>tagREM) then
      begin
        case ch of
          cSINVERS: toggleStyle(styleInvers);
          cSUNDER : toggleStyle(styleUnderline);
          cCODEINS: checkCodeInsert();
          cLIST   : checkListPointed();
          cNUMLIST0..cNUMLIST9: checkListNumbered();
          cHEADER: checkHeader();
          cOADDR,cCADDR: checkLinkAddress();
          cOLINK,cCLINK: checkLinkDescription();
        else
          lineStat:=lineStat and not (statLineBegin+statWordBegin);
        end;
      end
      else
        lineStat:=lineStat and not (statLineBegin+statWordBegin);
    end;
    if ch<>cRETURN then lineStat:=errBufferEnd;
  end;
end;

end.