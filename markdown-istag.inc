function isBeginTag(ntag:Byte):Boolean;
begin
  result:=((tag=nTag) and (prevTag<>nTag));
end;

function isEndTag(ntag:Byte):Boolean;
begin
  result:=((tag<>nTag) and (prevTag=nTag));
end;

function isHeader(nTag:Byte):Boolean;
begin
  result:=((nTag>=tagH1) and (nTag<=tagH4));
end;

function isLink(nTag:Byte):Boolean;
begin
  result:=((nTag>=tagLinkDescription) and (nTag<=tagImageDescription));
end;

function isList(nTag:Byte):Boolean;
begin
  result:=((nTag>=tagList) and (nTag<=tagListOrdered));
end;

function isBlock(nTag:Byte):Boolean;
begin
  result:=((nTag>=tagBlock) and (nTag<=tagCode));
end;

function isStyle(nStyle:Byte):Boolean;
begin
  result:=(style and nStyle<>0);
end;

function isLineBegin():Boolean;
begin
  result:=(lineStat and statLineBegin<>0);
end;

function isLineEnd():Boolean;
begin
  result:=(lineStat and statEndOfLine<>0);
end;
