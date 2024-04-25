procedure toggleStyle(nStyle:Byte);
begin
  if (lineStat and statWordBegin<>0) then
  begin
    if _processChars(processFind,ch)>0 then
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
    if _processChars(processCount,cCODEINS)=1 then
    begin // code insert
      if _processChars(processFind,cCODEINS)>0 then
      begin
        removeStrChars(1);
        pushTag(tagCodeInsert);
      end;
    end
  end
  else
  if (tag=tagCodeInsert) then
  begin
    dec(parseChar); _flushBuffer();
    removeStrChars(1);
    popTag();
  end;
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
    ch:=#0;
    style:=style xor stylePrintable;
  end
  else
  if (tag and tagBLOCK=0) then
  begin
    dec(parseChar,tmp); ch:=parseChar^;
  end;
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
      pushTag(tagHeader+tmp-1);
    end;
  end;
end;

procedure checkLinkAddress();
begin
  if ch=cOADDR then
  begin
    if (tag=tagLinkDescription) or (tag=tagImageDescription) then
    begin
      if (_processChars(processFind,cCADDR)>0) then
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
    dec(parseChar); _flushBuffer();
    removeStrChars(1);
    popTag();
    style:=style or stylePrintable;
  end;
end;

procedure checkLinkDescription();
begin
  if ch=cOLINK then
  begin
    if tag<>tagLinkDescription then
    begin
      if (_processChars(processFind,cCLINK)>0) then
      begin
        if (_processChars(processFind,cOADDR)=1) and (_processChars(processFind,cCADDR)>0) then
        begin
          removeStrChars(1);
          pushTag(tagLinkDescription);
        end;
      end;
    end;
  end
  else
  if (tag=tagLinkDescription) or (tag=tagImageDescription) then
  begin
    dec(parseChar); _flushBuffer();
    removeStrChars(1);
    style:=style and (not stylePrintable);
  end;
end;

procedure checkImage();
begin
  if (lineStat and statWordBegin<>0) then
  begin
    tmp:=_processChars(processFind,cOLINK);
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
    begin
      dec(parseChar,tmp); ch:=parseChar^;
    end;
  end;
end;