uses Crt, CIO, MarkDown;

function readLineFromFile():Byte; stdcall;
begin
  result:=255-parseStrLen;
  if (result>0) then
    if (parseStrLen+result<256) then
    begin
      bget(1,parseChar,result);
      result:=peek($358); // #1 - LSB of readed bytes
      if result=0 then parseError:=errEndOfDocument;
      // inc(parseStrLen,blockLen);
    end;
end;

procedure printMD();

  procedure inversString();
  var
    i:byte;

  begin
    for i:=1 to length(parseStr) do
      parseStr[i]:=char(byte(parseStr[i]) or $80);
  end;

  procedure uppercaseString();
  var
    i:byte;

  begin
    for i:=1 to length(parseStr) do
      if (parseStr[i]>=#97) and (parseStr[i]<=#122) then
        parseStr[i]:=char(byte(parseStr[i])-32);
  end;

begin
  if keyPressed then parseError:=errBreakParsing;
  if style and stylePrintable=0 then exit;
  if (style and styleInvers<>0) or
     (tag and tagLink<>0) then inversString();
  if (tag and tagHeader<>0) then uppercaseString();
  write(parseStr);
end;

procedure parseMD();
begin
  _callFlushBuffer:=@printMD;
  _callFetchLine:=@readLineFromFile;
  parseTag();
  if parseError<0 then
  begin
    writeLn;
    if parseError<>errEndOfDocument then
      write(' Parse parseError: '*);
    case parseError of
      errEndOfDocument : writeLn('End of Document');
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
    writeLn('IO parseError #',IOResult);
  cls(1);
  writeLn('Press any key...');
  ReadKey;
end.