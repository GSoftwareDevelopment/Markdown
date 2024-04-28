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
      bget(1,parseChar,result);
      result:=peek($358); // IO channel #1 - LSB of readed bytes
      if result=0 then parseError:=errEndOfDocument;
    end;
end;

procedure printMD();
var
  curX:Byte;
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
    inc(curX,cnt);
    while cnt>0 do
    begin
      write(ch); dec(cnt);
    end;
  end;

  procedure lineString();
  begin
    charString(40,#$12);
    if isHeader(prevTag) then writeLn;
  end;

  procedure newLine();
  begin
    if curX<40 then writeLn;
    curX:=0;
  end;

  procedure putIndent();
  begin
    if isList then charString(2,#32);
    charString(lineIndentation*2,#32);
  end;

  procedure print();
  var
    ch:Char;
    s:String[40];
    len:Byte;

  begin
    len:=length(parseStr);
    if len=0 then exit;
    ch:=parseStr[len];
    if (ch=cSPACE) then dec(len);
    if (byte(curX+len)>39) then
    begin
      newLine; putIndent;
    end;
    if len>0 then
    begin
      s[0]:=char(len);
      move(@parseStr+1,@s+1,len);
      write(s);
    end;
    if ch=cSPACE then begin write(cSPACE); inc(len); end;
    inc(curX,len);
  end;

  procedure putC(ch:Char);
  begin
    if (curX>39) then newLine;
    write(ch);
    inc(curX);
  end;

begin
  if keyPressed then parseError:=errBreakParsing;

  if isStyle(stylePrintable) then
  begin
    if isStyle(styleInvers) or isLink then inversString;

    if isBeginTag(tagImageDescription) then Write('img#');
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
end;

procedure parseMD();
begin
  _callFlushBuffer:=@printMD;
  _callFetchLine:=@readLineFromFile;
  prevTag:=0;
  parseMarkdown(statRedundantSpace);
  if parseError<0 then
  begin
    writeLn;
    if parseError<>errEndOfDocument then
      write(' Parse parseError: '*);
    case parseError of
      // errEndOfDocument : writeLn('End of Document');
      errBufferEnd     : writeLn('Buffer end');
      errTagStackEmpty : writeLn('Tag stack is empty');
      errTagStackFull  : writeLn('Tag stack is full');
      errBreakParsing  : writeLn('Parse is break');
    end;
  end;
end;

var
  fn:String;

begin
  poke(82,0); clrscr;
  fn:=concat('D:',paramStr(1));
  WriteLn('Read file ',fn,'...');
  opn(1,4,0,fn);
  if IOResult=1 then
    parseMD()
  else
    writeLn('IO error #',IOResult);
  cls(1);
  writeLn('Press any key...');
  ReadKey;
end.