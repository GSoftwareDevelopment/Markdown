// Stack procedures

procedure pushTag(nTag:Byte);
begin
  if parseStackPos<maxParseStack then
  begin
    parseStack[parseStackPos]:=tag;
    tag:=nTag;
    inc(parseStackPos);
  end
  else
    parseError:=errTagStackFull;
end;

procedure popTag();
begin
  if parseStackPos>0 then
  begin
    dec(parseStackPos);
    tag:=parseStack[parseStackPos];
  end
  else
    parseError:=errTagStackEmpty;
end;
