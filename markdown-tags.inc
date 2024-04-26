procedure _flushAndRemoveCharSetStyle(nStyle:Byte);
begin
  dec(parseChar); _flushBuffer();
  removeStrChars(1);
  style:=nStyle;
end;

procedure previosChar();
begin
  dec(parseChar,tmp); ch:=parseChar^;
end;

procedure toggleStyle(nStyle:Byte);
begin
  if (lineStat and statWordBegin<>0) then
  begin
    if _processChars(processFind,ch)>1 then
    begin
      removeStrChars(1);
      style:=style xor nStyle;
    end;
  end
  else
  if (style and nStyle<>0) then
    _flushAndRemoveCharSetStyle(style xor nStyle);
end;

procedure checkBlock(nTag:Byte);
begin
  tmp:=_processChars(processCount,ch);
  if (tmp=3) then
  begin
    removeStrChars(3);
    if tag<>nTag then
      pushTag(nTag)
    else
      popTag();
    style:=style and (not stylePrintable);  // disable Printable style
    if tag=tagCode then                     // enable Fixed style for CODE block
      style:=style or styleFixed;
    ch:=#0;
  end
  else
  if (not isBlock(tag)) then
    previosChar();
end;

procedure checkListBullet();
begin
  if (lineStat and statLineBegin<>0) then
  begin
    if (_processChars(processFind,cSPACE)=1) then
    begin
      pushTag(tagListUnordered);
      _flushBuffer();
      popTag();
      pushTag(tagList);
    end;
  end;
end;

procedure checkListNumbered();
begin
  if (lineStat and statLineBegin<>0) then
  begin
    if (_processChars(processValue,#0)>0) and (ch=cOLIST) then
    begin
      if _processChars(processFind,cSpace)=1 then
      begin
        pushTag(tagListOrdered);
        _flushBuffer();
        popTag();
        pushTag(tagList);
      end;
    end;
  end;
end;

procedure checkHeader();
begin
  if (lineStat and statLineBegin<>0) then
  begin
    tmp:=_processChars(processCount,cHEADER);
    if (tmp>0) and (tmp<=4) and (ch=cSPACE) then
    begin
      removeStrChars(tmp+1);
      pushTag(tagH1+tmp-1);
    end;
  end;
end;

procedure checkLinkAddress();
begin
  if ch=cOLADDR then
  begin
    if (tag=tagLinkDescription) or (tag=tagImageDescription) then
    begin
      if (_processChars(processFind,cCLADDR)>0) then
      begin
        removeStrChars(1);
        popTag();
        pushTag(tagLinkDestination);
      end;
    end;
  end
  else
  if tag=tagLinkDestination then
  begin
    _flushAndRemoveCharSetStyle(style or stylePrintable);
    popTag();
  end;
end;

procedure checkLinkDescription();
begin
  if ch=cOLDESC then
  begin
    if tag<>tagLinkDescription then
    begin
      if (_processChars(processFind,cCLDESC)>0) then
      begin
        if (_processChars(processFind,cOLADDR)=1) and (_processChars(processFind,cCLADDR)>0) then
        begin
          removeStrChars(1);
          pushTag(tagLinkDescription);
        end;
      end;
    end;
  end
  else
  if (tag=tagLinkDescription) or (tag=tagImageDescription) then
    _flushAndRemoveCharSetStyle(style and (not stylePrintable));
end;

procedure checkImage();
begin
  if (lineStat and statWordBegin<>0) then
  begin
    tmp:=_processChars(processFind,cOLDESC);
    if (tmp=1) then
    begin
      checkLinkDescription();
      if tag=tagLINKDescription then
      begin
        removeStrChars(1);
        popTag();
        pushTag(tagImageDescription);
      end;
    end
    else
      previosChar();
  end;
end;

