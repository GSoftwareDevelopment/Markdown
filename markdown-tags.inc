procedure toggleStyle(nStyle:Byte);
begin
  if isWordBegin then
  begin
    if _processChars(processFind,ch)>1 then
    begin
      removeStrChars(1);
      style:=style xor nStyle;
    end;
  end
  else
  if isStyle(nStyle) then
    _flushAndRemoveCharSetStyle(style xor nStyle);
end;

procedure checkBlock(nTag:Byte);
begin
  if isLineBegin then
  begin
    tmp:=_processChars(processCount,ch);
    if (tmp=3) then
    begin
      removeStrChars(3);
      if not isBlock then
      begin
        pushTag(nTag);
        style:=style and (not stylePrintable);  // disable Printable style to the end of line
      end
      else
      begin
        popTag;
        style:=style or stylePrintable;  // enablee Printable style
      end;
      _flushBuffer;

      // exception
      if isTag(tagCode) then                     // enable Fixed style for CODE block
        style:=style or styleFixed;

      ch:=#0;
    end
    else
    if (not isBlock) then _previousChar(tmp);
  end;
end;

procedure checkHeader();
begin
  if isLineBegin then
  begin
    tmp:=_processChars(processCount,cHEADER);
    if (tmp>0) and (tmp<=8) and (ch=cSPACE) then
    begin
      removeStrChars(tmp+1);
      pushTag(tagH1+tmp-1);
    end;
  end;
end;

procedure checkListUnordered();
begin
  if isLineBegin then
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

procedure checkListOrdered();
begin
  if isLineBegin then
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

procedure checkLinkAddress();
begin
  if isLink then
  begin
    if ch=cOLADDR then
    begin
      if (_processChars(processFind,cCLADDR)>0) then
      begin
        removeStrChars(1);
        popTag();
        pushTag(tagLinkDestination);
        style:=style and (not stylePrintable);
      end;
    end
    else
    begin
      _flushAndRemoveCharSetStyle(style or stylePrintable);
      popTag();
    end;
  end;
end;

procedure checkLinkDescription();
begin
  if not isLink then
  begin
    if ch=cOLDESC then
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
  begin
    _flushAndRemoveCharSetStyle(style);
    tag:=tagLink;
    _flushBuffer();
  end;
end;

procedure checkImage();
begin
  if isWordBegin then
  begin
    tmp:=_processChars(processFind,cOLDESC);
    if (tmp=1) then
    begin
      checkLinkDescription();
      if isLink then
      begin
        removeStrChars(1);
        popTag();
        pushTag(tagImageDescription);
      end;
    end
    else
      _previousChar(tmp);
  end;
end;

