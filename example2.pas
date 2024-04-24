uses Crt, CIO, MarkDown;

procedure readLineFromFile();
var
  blockLen:Byte;

begin
  blockLen:=255-parseStrLen;
  if (blockLen>0) then
    if (parseStrLen+blockLen<256) then
    begin
      bget(1,parseChar,blockLen);
      blockLen:=peek($358); // #1 - result read bytes
      if blockLen=0 then lineStat:=errBreakParsing;
      inc(parseStrLen,blockLen);
    end;
end;

procedure printMD();

  procedure inversString(S:PString);
  var
    i:byte;

  begin
    for i:=1 to length(s) do
      s[i]:=char(byte(s[i]) or $80);
  end;

begin
  if style and stylePrint=0 then exit;
  if (style and styleInvers<>0) or
     (tag and tagLink<>0) then inversString(parseStr);
  write(parseStr);
end;

procedure parseMD();
begin
  _callFlushBuffer:=@printMD;
  _callFetchLine:=@readLineFromFile;
  parseTag();
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
    writeLn('IO Error #',IOResult);
  cls(1);
  writeLn('Press any key...');
  ReadKey;
end.