unit MarkDown;

(*
*)

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

  tagBlock              = 5;
  tagREM                = 6;
  tagCode               = 7;
  tagLink               = 8;
  tagLinkDescription    = 9;
  tagLinkDestination    = 10;
  tagImageDescription   = 11;
  tagTableNewCell       = 12;
  tagTableNewRow        = 13;
  tagTableHeader        = 14;
  tagList               = 15;
  tagListUnordered      = 16;
  tagListOrdered        = 17;
  tagHorizRule          = 18;

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
  _callFlushBuffer:TDrawProc;
  _callFetchLine:TFetchData;

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


  parseStack:Array[0..maxParseStack] of Byte  absolute $0600;

function isLineBegin():Boolean;
function isLineEnd():Boolean;

function isBeginTag(ntag:Byte):Boolean;
function isEndTag(ntag:Byte):Boolean;
function isHeader(nTag:Byte):Boolean;
function isLink(nTag:Byte):Boolean;
function isList(nTag:Byte):Boolean;
function isBlock(nTag:Byte):Boolean;
function isStyle(nStyle:Byte):Boolean;

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

{$I 'markdown-istag.inc'}

procedure _fetchBuffer(); forward;

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
  oldPSLen,len:Byte;

begin
  oldPSLen:=parseStrLen;
  len:=byte(parseChar-@parseStr);
  parseStrLen:=len; _callFlushBuffer(); parseStrLen:=oldPSLen;
  prevTag:=tag;
  if parseStrLen=0 then exit;
  removeStrChars(len);
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
  tag:=tagNormal;
  style:=stylePrintable;
  parseChar:=@parseStr;
  lineStat:=statLineBegin+statWordBegin;

  while (parseError=0) do
  begin
    _fetchBuffer();

    // parse line
    while (parseError=0) and (parseStrLen>0) and (byte(parseChar-@parseStr)<parseStrLen) do
    begin
      inc(parseChar);
      ch:=parseChar^;
      case ch of
      // white-space characters parse
        cESC, cTAB, cCR:
          begin
            if (ch=cTAB) and (lineStat and statLineBegin<>0) then inc(lineIndentation);
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

            if isList(tag) or isHeader(tag) then
              // after List and Header tag always back to parent tag
              popTag();

            // if (tag=tagBlock) then
            //   // keep Fixed style for block (Code block)
            //   style:=style and (not styleFixed) or (style and styleFixed);

            if (tag=tagCode) then
              // only for CODE tag always set Printable
              style:=style or stylePrintable;
            // else
            //   // keep only Printable style flag status
            //   style:=style and (not stylePrintable) or (style and stylePrintable);

            // keep only BLOCK tag
            if isBlock(tag) then
              tag:=tagBlock // tag:=tag and tagBLOCK;
            else
              tag:=tagNormal;

            lineStat:=(statLineBegin+statWordBegin);
            continue;
          end;
      end;

      if (ch=cOREM) or (ch=cCREM) then checkBlock(tagREM);
      if (ch=cCODE) and (lineStat and statLineBegin<>0) then checkBlock(tagCode);

      if (not isBlock(tag)) then
      begin
        if ch=cHRULE then checkBlock(tagHorizRule);
        case ch of
          cSINVERS         : toggleStyle(styleInvers);
          cSUNDER          : toggleStyle(styleUnderline);
          cSFIXED          : toggleStyle(styleFixed);
          cHEADER          : checkHeader();
          cULIST           : checkListBullet();
          cOLIST0..cOLIST9 : checkListNumbered();
          cIMAGE           : checkImage();
          cOLDESC,cCLDESC    : checkLinkDescription();
          cOLADDR,cCLADDR    : checkLinkAddress();
        else
          lineStat:=lineStat and not (statWordBegin);
        end;
      end
      else
        lineStat:=lineStat and not (statWordBegin);
    end;
  end;
  if (parseError=0) then _flushBuffer();
end;

end.