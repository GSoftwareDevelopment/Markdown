(*
Moves the compactness of the buffer by the specified `count` number of bytes.
NOTE: The operation is performed from the beginning of the buffer!
      The position pointer in the buffer is set to the beginning of the buffer.
      The size of the buffer is also updated.
*)
procedure removeStrChars(count:Byte);
begin
  if count=0 then exit;
  dec(parseStrLen,count);
  move(@parseStr+count+1,@parseStr+1,parseStrLen);  //
  // FillChar(@parseStr+parseStrLen+1,count,0);     // clear unused chunk of buffer
  parseChar:=@parseStr;
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
      processCount: result:=(ch<>nch);
      processFind : result:=((ch=nCh) or (ch=cRETURN) or (ch=cLF));
      processValue: result:=((ch<cOLIST0) or (ch>cOLIST9));
    end;
  end;

begin
  old:=parseChar; result:=parseStrLen-byte(parseChar-@parseStr-1);
  while result>0 do
  begin
    repeat
      inc(parseChar); dec(result); ch:=parseChar^;
    until (result=0) or (conditionProcessing());

    if result=0 then
    begin
      tmp:=parseStrLen;
      dec(parseChar); _fetchBuffer();
      if parseError=0 then
      begin
        // `tmp` value is set in parent function!
        inc(result,parseStrLen-tmp);
      end;
    end
    else
      exit(byte(parseChar-old));

    inc(result);
  end;
end;

//

procedure _flushAndRemoveCharSetStyle(nStyle:Byte);
begin
  if parseChar>@parseStr then
  begin
    dec(parseChar);
    _flushBuffer;
    removeStrChars(1);
  end;
  style:=nStyle;
end;

procedure _previousChar(back:Byte);
begin
  dec(parseChar,back); ch:=parseChar^;
end;
