uses Crt, MarkDown;

(*
The data is retrieved from memory (defined in an array constant)
The `getLine` procedure provides a single line of data to the parser. It also performs a simple end-of-line character conversion of type CR/LF. Returns an error when the line buffer is exceeded.

The `printMD` procedure is responsible for displaying the processed text on the screen.
It distinguishes the `Printable` style, which is used for non-printable text fragments, while allowing you to process this information.
Distinguishes the `Invers` style and hyperlinks on the screen.
Besides, it displays the rest of the text.

The `parseMD` procedure prepares the engine variables for operation.
*)

const
  MD:Array of char = '# Naglowek poziom #1'#10#13'To jest tekst [w nim link](id) i dalszy tekst.'#155#155'I kolejna linia, a w niej *tekst w inwersie* oraz _podkreslenie_.'#155'A tutaj (w nawiasie jest tekst i wstawka kodu `inner();`)'#155'- sa tez'#155'- listy punktowe'#155#155'1. a takze'#155'2. numeryczne'#155#155'---'#155'blok komentarza'#155'---'#155'```basic'#155'10 PRINT "ATARI"'#155'20 GOTO 10'#155'```'#155;

var
  curChar:PChar       absolute $F3;       // pointer to current character in MD source
  endPtr:Pointer;                         // pointer to the end of MD source

procedure getLine();
begin
  repeat
    ch:=curChar^;
    parseChar^:=ch; inc(parseChar); inc(curChar); inc(parseStrLen);
  until (parseStrLen=0) or (curChar>=endPtr) or (ch=cRETURN) or (ch=cLF) or (ch=cCR);
  if (curChar>=endPtr) then
    lineStat:=errBreakParsing
  else
  begin
    if (ch=cLF) or (ch=cCR) then
    begin
      dec(parseChar); ch:=cReturn; parseChar^:=ch; inc(parseChar);
    end;
    if (ch<>cRETURN) then
      if parseStrLen=255 then lineStat:=errLineTooLong;
    ch:=curChar^;
    if (ch=cLF) or (ch=cCR) then inc(curChar);
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

procedure parseMD(startMDPtr,endMDPtr:Pointer);
begin
  _callFlushBuffer:=@printMD;
  _callFetchLine:=@getLine;
  curChar:=startMDPtr;
  endPtr:=endMDPtr;
  lineStat:=0;
  parseTag();
end;

begin
  poke(82,0); clrscr;
  parseMD(@MD,@MD+sizeOf(MD));
  ReadKey;
end.