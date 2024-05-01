procedure toggleStyle(nStyle:Byte);
begin
  if not isWordBegin then
  begin
    _previousChar(1);
    _flushBuffer();
    _nextChar(1);
  end;
  if isStyle(nStyle) then
  begin
    _flushAndRemoveChar;
    _changeStyle(style xor nStyle);
  end
  else
  begin
    tmp:=_processChars(processFind,parseLastChar);
    if tmp>1 then
    begin
      _removeChars(1);
      _changeStyle(style xor nStyle);
      prevTag:=tag;
    end
    else
      _previousChar(tmp);
  end;
end;

procedure checkBlock(nTag:Byte);
begin
  tmp:=_processChars(processCount,parseLastChar);
  if (tmp=3) then
  begin
    if not isWordBegin then
    begin
      _previousChar(tmp+1);
      _flushBuffer;
    end;
    _removeChars(3);
    if not isBlock then
    begin
      pushTag(nTag);
      _flushBuffer;
      _changeStyle(style and (not stylePrintable));  // disable Printable style to the end of line
    end
    else
    begin
      popTag;
      _flushBuffer;
      _changeStyle(style or stylePrintable);  // enablee Printable style
    end;

    // exception
    if isTag(tagCode) then // enable Fixed style for CODE block
      _changeStyle(style or styleFixed);

    parseLastChar:=#0;
  end
  else
  if (not isBlock) then _previousChar(tmp);
end;

procedure checkHeader();
begin
  if isLineBegin then
  begin
    tmp:=_processChars(processCount,cHEADER);
    if (tmp>0) and (tmp<=8) and (parseLastChar=cSPACE) then
    begin
      _removeChars(tmp+1);
      pushTag(tagH1+tmp-1);
    end;
  end;
end;

procedure checkList(listTag:Byte);
begin
  bytes:=_processChars(processFind,cSPACE);
  if (bytes=1) then
  begin
    pushTag(listTag);
    _flushBuffer;
    popTag;
    pushTag(tagList);
  end
  else
    inc(tmp,bytes);
end;

procedure checkListUnordered();
begin
  if isLineBegin then
  begin
    checkList(tagListUnordered);
    if islist then exit;
    _previousChar(tmp);
  end;
end;

procedure checkListOrdered();
begin
  if isLineBegin then
  begin
    tmp:=_processChars(processValue,#0);
    if (tmp>0) and (parseLastChar=cOLIST) then
    begin
      checkList(tagListOrdered);
      if islist then exit;
    end;
    _previousChar(tmp);
  end;
end;

procedure checkLinkDescription();
begin
  if not isLink then
  begin
    if parseLastChar=cOLDESC then
    begin
      if (_processChars(processFind,cCLDESC)>0) then
      begin
        if (_processChars(processFind,cOLADDR)=1) and (_processChars(processFind,cCLADDR)>0) then
        begin
          _removeChars(1);
          pushTag(tagLinkDescription);
        end;
      end;
    end;
  end
  else
  begin
    _flushAndRemoveChar;
    tag:=tagLink;
    _flushBuffer();
  end;
end;

procedure checkLinkAddress();
begin
  if isLink then
  begin
    if parseLastChar=cOLADDR then
    begin
      if (_processChars(processFind,cCLADDR)>0) then
      begin
        _removeChars(1);
        popTag();
        pushTag(tagLinkDestination);
        _changeStyle(style and (not stylePrintable));
      end;
    end
    else
    begin
      _flushAndRemoveChar;
      _changeStyle(style or stylePrintable);
      popTag();
    end;
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
        _removeChars(1);
        popTag();
        pushTag(tagImageDescription);
      end;
    end
    else
      _previousChar(tmp);
  end;
end;

