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
    end
    else
    begin
      dec(parseChar,tmp-1); ch:=parseChar^;
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
      end
      else
      begin
        dec(parseChar,tmp-1); ch:=parseChar^;
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
      if (tmp>0) and (tmp<=4) and (ch=cSPACE) then
      begin
        removeStrChars(tmp+1);
        tag:=tagHeader+tmp-1;
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
