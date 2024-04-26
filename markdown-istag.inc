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
