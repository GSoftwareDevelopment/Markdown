unit MarkDown;

interface
const
  maxParseStack = 7;  // count from 0 to this value

  cTAB      = #9;   // indentation
  cLF       = #10;  // new line
  cCR       = #13;  // combine with cLF is new line
  cSPACE    = #32;
  cRETURN   = #155; // Atari new line

//                     Considered state only at...
  cESC      = '\';  // the beginning of the Word
  cHEADER   = '#';  // the beginning of the Line
  cIMAGE    = '!';  // before OLINK Tag
  cOLDESC   = '[';  // the beginning of the Word
  cCLDESC   = ']';  // the end of the Word
  cOLADDR   = '(';  // after CLINK Tag
  cCLADDR   = ')';  // the end of the CLINK Tag
  cSINVERS  = '*';  // the beginning of the Word and at the end
  cSUNDER   = '_';  // the beginning of the Word and at the end
  cSFIXED   = '`';  // the beginning of the Word (1 time)
  cOREM     = '<';  // the beginning of the Line (3 times)
  cCREM     = '>';  // the beginning of the Line (3 times)
  cCODE     = '`';  // the beginning of the Line (3 times)
  cULIST    = '-';  // the beginning of the Line
  cOLIST0   = '0';  // the beginning of the Line
  cOLIST9   = '9';  // the beginning of the Line
  cOLIST    = '.';  // the end of the first Word and if last style is NUMLISTx
  cHRULE    = '-';  // the beginning of the Line (3 times);

// tags
  tagNormal             = 0;

  tagH1                 = 1;
  tagH2                 = 2;
  tagH3                 = 3;
  tagH4                 = 4;
  tagH5                 = 5;
  tagH6                 = 6;
  tagH7                 = 7;
  tagH8                 = 8;

  tagBlock              = 9;
  tagREM                = 10;
  tagCode               = 11;
  tagLink               = 12;
  tagLinkDescription    = 13;
  tagLinkDestination    = 14;
  tagImageDescription   = 15;
  tagTableNewCell       = 16;
  tagTableNewRow        = 17;
  tagTableHeader        = 18;
  tagList               = 19;
  tagListUnordered      = 20;
  tagListOrdered        = 21;
  tagHorizRule          = 22;

  tagNull               = 255;

// styles
  stylePrintable        = %10000000;  // Printable word
  styleStyle            = %00000111;
  styleInvers           = %00000001;  // Invers video
  styleUnderline        = %00000010;  // Underline
  styleFixed            = %00000100;  // Fixed width font

// line status & parseErrors
  statEndOfLine         = %10000000;
  statLineBegin         = %01000000;
  statWordBegin         = %00100000;
  statESC               = %00010000;

// errors
  errEndOfDocument      = -128;
  errBreakParsing       = -1;
  errBufferEnd          = -2;
  errTagStackEmpty      = -3;
  errTagStackFull       = -4;

//
//
//

// call type procedure
type
  TDrawProc=procedure();
  TFetchData=function():Byte;

var

  parseStr:String                             absolute __BUFFER;  // line buffer
  parseStrLen:Byte                            absolute __BUFFER;  // line length

// work variables
  lineStat:Byte                               absolute $F0;       // line status code
  lineIndentation:Byte                        absolute $F1;       // line indent
  ch:Char                                     absolute $F2;       // work character

  prevTag:Byte                                absolute $F3;
  tag:Byte                                    absolute $F4;       // current tag code
  style:Byte                                  absolute $F5;       // current style code
  parseStackPos:Byte                          absolute $F6;
  parseError:Shortint                         absolute $F7;
  parseChar:PChar                             absolute $F8;       // pointer to current character in buffer

  _callFlushBuffer:TDrawProc                  absolute $FA;
  _callFetchLine:TFetchData                   absolute $FC;

  parseStack:Array[0..maxParseStack] of Byte  absolute $0600;

{$IFDEF UseMacro4Ises}

{$I 'markdown-ises.inc'}

{$ELSE}

function isLineBegin():Boolean;
function isLineEnd():Boolean;

function isBeginTag(ntag:Byte):Boolean;
function isEndTag(ntag:Byte):Boolean;

function isHeader(nTag:Byte):Boolean; overload;
function isLink(nTag:Byte):Boolean; overload;
function isList(nTag:Byte):Boolean; overload;
function isBlock(nTag:Byte):Boolean; overload;

function isHeader():Boolean; overload;
function isLink():Boolean; overload;
function isList():Boolean; overload;
function isBlock():Boolean; overload;

function isStyle(nStyle:Byte):Boolean;

{$ENDIF}

procedure parseTag();

implementation
const
  processCount  = 0;  // count characters
  processFind   = 1;  // find character
  processValue  = 2;  // identify value (integer)

var
  tmp:Byte;
  old:Pointer;
  bytes:Byte;

//
//
//

{$I 'markdown-ises.inc'}

procedure _fetchBuffer(); forward;
procedure _flushBuffer(); forward;

{$I 'markdown-stack.inc'}
{$I 'markdown-chars.inc'}

(*
subcall procedure for buffer fetch
*)
procedure _fetchBuffer();
begin
  old:=parseChar; inc(parseChar);
  bytes:=_callFetchLine();
  inc(parseStrLen,bytes);
  if parseError=errEndOfDocument then exit;
  parseChar:=old;
  if parseStrLen=0 then parseError:=errBufferEnd;
end;

(*
Flush the buffer - by calling the `call` procedure - to the location pointed to by the `parseChar` buffer pointer.
*)
procedure _flushBuffer();
var
  oldPSLen:Byte;

begin
  oldPSLen:=parseStrLen;
  bytes:=byte(parseChar-@parseStr);
  parseStrLen:=bytes; _callFlushBuffer(); parseStrLen:=oldPSLen;
  prevTag:=tag;
  if parseStrLen=0 then exit;
  removeStrChars(bytes);
end;

//
//
//

procedure parseTag();
var
  tmp:Byte;

{$I 'markdown-tags.inc'}

begin
  parseStrLen:=0;
  parseError:=0;
  lineIndentation:=0;
  parseStackPos:=0;
  tag:=tagNormal; prevTag:=tagNull;
  style:=stylePrintable;
  parseChar:=@parseStr;
  lineStat:=statLineBegin+statWordBegin;

  while (parseError=0) do
  begin
    _fetchBuffer();

    // parse line
    while (parseError=0) and (parseStrLen>0) and (byte(parseChar-@parseStr)<parseStrLen) do
    begin
      inc(parseChar); ch:=parseChar^;
      if lineStat and statESC<>0 then
      begin
        _flushBuffer;
        lineStat:=lineStat and (not statESC);
        continue;
      end;
      case ch of
      // white-space characters parse
        cESC, cTAB, cCR:
          begin
            if isLineBegin and (ch=cTAB) then inc(lineIndentation);
            if ch=cESC then
            begin
              _flushAndRemoveCharSetStyle(style);
              lineStat:=lineStat or statESC;
            end
            else
              removeStrChars(1);
            continue;
          end;
        cSPACE:
          begin
            _flushBuffer();
            lineStat:=lineStat and (not statLineBegin);
            lineStat:=lineStat or statWordBegin;
            continue;
          end;
        cRETURN,cLF:
          begin
            lineStat:=lineStat or statEndOfLine;
            if ch=cLF then begin ch:=cRETURN; parseChar^:=ch; end;
            _flushBuffer();

            // always clear indentation
            lineIndentation:=0;

            // after List and Header tag always back to parent tag
            if isList or isHeader then popTag();

            // only for CODE tag always set Printable
            if isTag(tagCode) then style:=style or stylePrintable;
            //   // keep only Printable style flag status
            // keep only BLOCK tag
            if isBlock then
              tag:=tagBlock // tag:=tag and tagBLOCK;
            else
              tag:=tagNormal;

            lineStat:=(statLineBegin+statWordBegin);
            continue;
          end;
      end;

      if (ch=cOREM) or (ch=cCREM) then checkBlock(tagREM);
      if (ch=cCODE) then checkBlock(tagCode);

      if (not isBlock) then
      begin
        if ch=cHRULE then checkBlock(tagHorizRule);
        case ch of
          cSINVERS         : toggleStyle(styleInvers);
          cSUNDER          : toggleStyle(styleUnderline);
          cSFIXED          : toggleStyle(styleFixed);
          cIMAGE           : checkImage();
          cOLDESC,cCLDESC  : checkLinkDescription();
          cOLADDR,cCLADDR  : checkLinkAddress();
          cHEADER          : checkHeader();
          cULIST           : checkListUnordered();
          cOLIST0..cOLIST9 : checkListOrdered();
        else
          lineStat:=lineStat and (not (statLineBegin+statWordBegin));
        end;
      end
      else
        lineStat:=lineStat and (not (statLineBegin+statWordBegin));
    end;
  end;
  if (parseError=0) then _flushBuffer();
end;

end.