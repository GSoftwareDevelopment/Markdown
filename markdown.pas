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

  tagTable              = %00010000;
  tagTableNewCell       = %00010000;
  tagTableNewRow        = %00010001;
  tagTableHeader        = %00010010;

  tagList               = %00001000;
  tagListBullet         = %00001001; // List bullet
  tagListNumbered       = %00001010; // List numbered

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
var
  old:Pointer;
  bytes:Byte;

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
    dec(parseChar); _fetchBuffer();
    if parseError=0 then
    begin
      // `tmp` value is set in parent function!
      inc(res,parseStrLen-tmp); tmp:=parseStrLen;
      result:=true; // true - buffer is refill
    end;
  end
  else
  begin
    res:=parseStrLen-res;
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
      processValue: result:=((ch<cNUMLIST0) or (ch>cNUMLIST9));
    end;
  end;

begin
  tmp:=parseStrLen; result:=parseStrLen-byte(parseChar-@parseStr-1);
  while result>0 do
  begin
    repeat
      inc(parseChar); dec(result); ch:=parseChar^;
    until (result=0) or (conditionProcessing());
    if not _refillBuffer(result) then break;
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
        cESC, cTAB:
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
            if (tag and tagCODE<>0) then
              style:=style or stylePrintable      // only for CODE tag always set Printable
            else
              style:=style and stylePrintable;  // keep only Printable style flag status
            tag:=tag and (tagREM+tagCODE);    // keep only REM tag flag status
            lineStat:=lineStat or (statLineBegin+statWordBegin);
            continue;
          end;
      end;

      if (tag<>tagCODE) then
        if (ch=cREM) then checkREMBlock();

      if (tag<>tagREM) then
      begin
        if (ch=cCODE) then checkCODEBlock();
        if (ch=cCODEINS) then checkCodeInsert();
      end;

      if (tag and (tagREM + tagCODE)=0) then
      begin
        case ch of
          cSINVERS            : toggleStyle(styleInvers);
          cSUNDER             : toggleStyle(styleUnderline);
          cLIST               : checkListBullet();
          cNUMLIST0..cNUMLIST9: checkListNumbered();
          cHEADER             : checkHeader();
          cOADDR,cCADDR       : checkLinkAddress();
          cOLINK,cCLINK       : checkLinkDescription();
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