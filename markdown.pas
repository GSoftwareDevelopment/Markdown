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
  cOLINK    = '[';  // the beginning of the Word
  cCLINK    = ']';  // the end of the Word
  cOADDR    = '(';  // after CLINK Tag
  cCADDR    = ')';  // the end of the CLINK Tag
  cSINVERS  = '*';  // the beginning of the Word and at the end
  cSUNDER   = '_';  // the beginning of the Word and at the end
  cOREM     = '<';  // the beginning of the Line (3 times)
  cCREM     = '>';  // the beginning of the Line (3 times)
  cCODE     = '`';  // the beginning of the Line (3 times)
  cCODEINS  = '`';  // the beginning of the Word (1 time)
  cULIST    = '-';  // the beginning of the Line
  cOLIST0   = '0';  // the beginning of the Line
  cOLIST9   = '9';  // the beginning of the Line
  cOLIST    = '.';  // the end of the first Word and if last style is NUMLISTx
  // cHRULE    = '-';  // the beginning of the Line (3 times);

// tags
  tagLink               = %10000000;
  tagLinkDescription    = %10000001;
  tagLinkDestination    = %10000010;
  tagImageDescription   = %10000011;

  tagBlock              = %01000000;
  tagREM                = %01000001;
  tagCodeInsert         = %01000010;
  tagCodeLanguage       = %01000011;

  tagTable              = %00010000;
  tagTableNewCell       = %00010000;
  tagTableNewRow        = %00010001;
  tagTableHeader        = %00010010;

  tagList               = %00001000;
  tagListUnordered      = %00001001;
  tagListOrdered        = %00001010;

  tagHeader             = %00000100;
  tagH1                 = %00000100;  // Header level 1
  tagH2                 = %00000101;  // Header level 2
  tagH3                 = %00000110;  // Header level 3
  tagH4                 = %00000111;  // Header level 4

// styles
  stylePrintable        = %10000000;  // Printable word

  styleStyle            = %00000011;
  styleInvers           = %00000001;  // Invers video
  styleUnderline        = %00000010;  // Underline

// line status & parseErrors
  statLineBegin         = %10000000;
  statWordBegin         = %01000000;

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
  tag:Byte                                    absolute $F3;       // current tag code
  style:Byte                                  absolute $F4;       // current style code
  parseChar:PChar                             absolute $F5;       // pointer to current character in buffer

  parseStackPos:Byte                          absolute $F7;
  parseError:Shortint                         absolute $F8;

  parseStack:Array[0..maxParseStack] of Byte  absolute $0600;

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

(*
Moves the compactness of the buffer by the specified `count` number of bytes.
NOTE: The operation is performed from the beginning of the buffer!
      The position pointer in the buffer is set to the beginning of the buffer.
      The size of the buffer is also updated.
*)
procedure removeStrChars(count:Byte);
begin
  if count=0 then exit;
  dec(parseStrLen,count);
  move(@parseStr+count+1,@parseStr+1,parseStrLen);  //
  // FillChar(@parseStr+parseStrLen+1,count,0);     // clear unused chunk of buffer
  parseChar:=@parseStr;
end;

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

// subfunction to refill the contents of the buffer
// return:
//   false - if the buffer cannot be refilled
function _refillBuffer(var res:Byte):Boolean;
begin
  result:=false; // false - break;
  if res=0 then
  begin
    tmp:=parseStrLen;
    dec(parseChar); _fetchBuffer();
    if parseError=0 then
    begin
      // `tmp` value is set in parent function!
      inc(res,parseStrLen-tmp);
      result:=true; // true - buffer is refill
    end;
  end;
end;

// subfunction to processing characters in buffer
// Note: It also takes care of filling up the buffer during processing
// Returns:
// 0 - if the process failed
// otherwise, returns the offset relative to the current position in the buffer
function _processChars(processType:Byte; nCh:Char):Byte;

  function conditionProcessing():Boolean;
  begin
    case processType of
      processCount: result:=(ch<>nch);
      processFind : result:=((ch=nCh) or (ch=cRETURN) or (ch=cLF));
      processValue: result:=((ch<cOLIST0) or (ch>cOLIST9));
    end;
  end;

begin
  old:=parseChar; result:=parseStrLen-byte(parseChar-@parseStr-1);
  while result>0 do
  begin
    repeat
      inc(parseChar); dec(result); ch:=parseChar^;
    until (result=0) or (conditionProcessing());
    if not _refillBuffer(result) then
      exit(byte(parseChar-old));
    inc(result);
  end;
end;

(*
Flush the buffer - by calling the `call` procedure - to the location pointed to by the `parseChar` buffer pointer.
*)
procedure _flushBuffer();
var
  oldPSLen,len:Byte;

begin
  if parseStrLen=0 then exit;
  oldPSLen:=parseStrLen;
  len:=byte(parseChar-@parseStr);
  parseStrLen:=len; _callFlushBuffer(); parseStrLen:=oldPSLen;
  removeStrChars(len);
end;

// Stack procedures

procedure pushTag(nTag:Byte);
begin
  if parseStackPos<maxParseStack then
  begin
    parseStack[parseStackPos]:=tag;
    tag:=nTag;
    inc(parseStackPos);
  end
  else
    parseError:=errTagStackFull;
end;

procedure popTag();
begin
  if parseStackPos>0 then
  begin
    dec(parseStackPos);
    tag:=parseStack[parseStackPos];
  end
  else
    parseError:=errTagStackEmpty;
end;

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
  tag:=0;
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
      // white-space parse
        cESC, cTAB, cCR:
          begin
            if (ch=cTAB) and (lineStat and statLineBegin<>0) then inc(lineIndentation);
            removeStrChars(1);
            continue;
          end;
        cSPACE:
          begin
            _flushBuffer();
            lineStat:=lineStat or statWordBegin;
            continue;
          end;
        cRETURN,cLF:
          begin
            if ch=cLF then begin ch:=cRETURN; parseChar^:=ch; end;
            _flushBuffer();
            lineIndentation:=0;
            if (style and (not stylePrintable)<>0) or
               (tag and (tagList+tagHeader)<>0)  then popTag();
            if (tag=tagCodeLanguage) then
              style:=style or stylePrintable    // only for CODE tag always set Printable
            else
              style:=style and stylePrintable;  // keep only Printable style flag status
            tag:=tag and tagBLOCK;    // keep only BLOCK tag flag status
            lineStat:=lineStat or (statLineBegin+statWordBegin);
            continue;
          end;
      end;

      if (ch=cOREM) or (ch=cCREM) then checkBlock(tagREM);
      if (ch=cCODE) and (lineStat and statLineBegin<>0) then checkBlock(tagCodeLanguage);
      if (ch=cCODEINS) then checkCodeInsert();

      if (tag and tagBLOCK=0) then
      begin
        case ch of
          cSINVERS         : toggleStyle(styleInvers);
          cSUNDER          : toggleStyle(styleUnderline);
          cHEADER          : checkHeader();
          cULIST           : checkListBullet();
          // cHRULE           : checkHorizRule();
          cOLIST0..cOLIST9 : checkListNumbered();
          cIMAGE           : checkImage();
          cOLINK,cCLINK    : checkLinkDescription();
          cOADDR,cCADDR    : checkLinkAddress();
        else
          lineStat:=lineStat and not (statLineBegin+statWordBegin);
        end;
      end
      else
        lineStat:=lineStat and not (statLineBegin+statWordBegin);
    end;
  end;
  if (parseError=0) then _flushBuffer();
end;

end.