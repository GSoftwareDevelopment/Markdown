(*
You can use macros for the `is` function.
To do this, specify the `UseMacro4Ises` directive on the command line or
define it in the `{$DEFINE UseMacro4Ises}` code.
*)

uses Crt, CIO, MarkDown;

function readLineFromFile():Byte; stdcall;
begin
  result:=255-parseStrLen;
  if (result>0) then
    if (parseStrLen+result<256) then
    begin
      bget(1,parseBufPtr,result);
      result:=peek($358); // IO channel #1 - LSB of readed bytes
      if result=0 then parseError:=errEndOfDocument;
    end;
end;

function printMD():Byte; stdcall;
var
  lastX:Byte;
  i:byte;

  procedure inversString();
  begin
    for i:=1 to length(parseStr) do
      parseStr[i]:=char(byte(parseStr[i]) or $80);
  end;

  procedure uppercaseString();
  begin
    for i:=1 to length(parseStr) do
      if (parseStr[i]>=#97) and (parseStr[i]<=#122) then
        parseStr[i]:=char(byte(parseStr[i])-32);
  end;

  procedure charString(cnt:shortint; ch:Char);
  begin
    while cnt>0 do
    begin
      write(ch); dec(cnt);
    end;
  end;

  procedure newLine();
  begin
    lastX:=whereX; writeLn;
  end;

  procedure lineString();
  begin
    if not isHeader then
      charString(screenWidth+1,#$12)
    else
    begin
      charString(lastX-1,#$0D); newLine;
    end;
  end;

  procedure putIndent();
  begin
    if isList then charString(2,#32);
    charString(lineIndentation*2,#32);
  end;

  procedure print();
  begin
    if parseStrLen=0 then exit;
    if (parseLastChar=cSPACE) then dec(parseStrLen);
    if (byte(whereX+parseStrLen)>byte(ScreenWidth)) then
    begin
      newLine; putIndent;
    end;
    if parseStrLen>0 then
    begin
      parseStr[0]:=char(parseStrLen);
      write(parseStr);
    end;
    if parseLastChar=cSPACE then begin write(cSPACE); inc(parseStrLen); end;
  end;

  procedure putC(ch:Char);
  begin
    if (whereX>=ScreenWidth) then newLine;
    write(ch);
  end;

begin
  if keyPressed then exit(errBreakParsing);

  if isStyle(stylePrintable) then
  begin
    if isStyle(styleInvers) or isLink then inversString;

    // if isBeginTag(tagImageDescription) then Write('img#');
    if isBeginTag(tagListUnordered) then
    begin
      putC(#$14); putC(#32);
    end
    else
    begin
      if isBeginTag(tagLinkDescription) then putC(#$99);
      if isHeader then uppercaseString;
      if isLineBegin and (lineIndentation>0) then putIndent;
      print;
      if isEndTag(tagLinkDescription) then putC(#$19);
      if isLineEnd then newLine;
    end;
    if (isLineEnd and isHeader) or isBeginTag(tagHorizRule) then lineString;
  end;
  result:=0;
end;

procedure parseMD();
begin
  _callFlushBuffer:=@printMD;
  _callFetchLine:=@readLineFromFile;
  parseMarkdown(statRedundantSpace);
  if parseError>-128 then
  begin
    writeLn;
    if parseError<>errEndOfDocument then
      write(' Parse error: '*);
    case parseError of
      errBreakParsing  : writeLn('Break parsing');
      errBufferEnd     : writeLn('Buffer end');
      errTagStackEmpty : writeLn('Tag stack is empty');
      errTagStackFull  : writeLn('Tag stack is full');
    end;
  end;
end;

var
  fn:String;

begin
  poke(82,0); screenWidth:=peek(83)+1;
  fn:=concat('D:',paramStr(1));
  opn(1,4,0,fn);
  if IOResult=1 then
    parseMD()
  else
    writeLn('IO error #',IOResult);
  cls(1);
  write('Press any key...');
  ReadKey; writeLn;
end.