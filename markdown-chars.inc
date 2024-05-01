(*
Moves the compactness of the buffer by the specified `count` number of bytes.
NOTE: The operation is performed from the beginning of the buffer!
      The position pointer in the buffer is set to the beginning of the buffer.
      The size of the buffer is also updated.
*)
procedure _removeChars(count:Byte);
begin
  if count=0 then exit;
  dec(parseStrLen,count);
  move(@parseStr+count+1,@parseStr+1,parseStrLen);  //
  // FillChar(@parseStr+parseStrLen+1,count,0);     // clear unused chunk of buffer
  parseBufPtr:=@parseStr;
end;

// subfunction to processing characters in buffer
// Note: It also takes care of filling up the buffer during processing
// Returns:
// 0 - if the process failed
// otherwise, returns the offset relative to the current position in the buffer
function _processChars(processType:Byte; nCh:Char):Byte;

  function conditionProcessing():Boolean;
  begin
    case processType of
      processCount: result:=(parseLastChar<>nch);
      processFind : result:=((parseLastChar=nCh) or (parseLastChar=cRETURN) or (parseLastChar=cLF));
      processValue: result:=((parseLastChar<cOLIST0) or (parseLastChar>cOLIST9));
    end;
  end;

begin
  old:=parseBufPtr; result:=parseStrLen-byte(parseBufPtr-@parseStr-1);
  while result>0 do
  begin
    repeat
      inc(parseBufPtr); dec(result); parseLastChar:=parseBufPtr^;
    until (result=0) or (conditionProcessing());

    if result=0 then
    begin
      tmp:=parseStrLen;
      dec(parseBufPtr); _fetchBuffer();
      if parseError=0 then
      begin
        // `tmp` value is set in parent function!
        inc(result,parseStrLen-tmp);
      end;
    end
    else
      exit(byte(parseBufPtr-old));

    inc(result);
  end;
end;

//

procedure _changeStyle(nStyle:Byte); inline;
begin
  style:=nStyle;
end;

procedure _nextChar(next:Byte);
begin
    inc(parseBufPtr,next); parseLastChar:=parseBufPtr^;
end;

procedure _previousChar(back:Byte);
begin
  if parseBufPtr>@parseStr then
  begin
    dec(parseBufPtr,back); parseLastChar:=parseBufPtr^;
  end;
end;

procedure _flushAndRemoveChar();
begin
  if parseBufPtr>@parseStr then
  begin
    dec(parseBufPtr);
    _flushBuffer;
    _removeChars(1);
  end;
end;
