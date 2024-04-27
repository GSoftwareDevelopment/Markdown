{$IFDEF UseMacro4Ises}

{$macro on} // only for FPC compatibility

{$DEFINE isBeginTag(nTag) := ((tag=nTag) and (prevTag<>nTag))}
{$DEFINE isEndTag(nTag) := ((tag<>nTag) and (prevTag=nTag))}
{$DEFINE isTag(nTag) := (tag=nTag)}

// {$DEFINE isHeader(nTag) := ((nTag>=tagH1) and (nTag<=tagH4))}
// {$DEFINE isLink(nTag) := ((nTag>=tagLink) and (nTag<=tagImageDescription))}
// {$DEFINE isList(nTag) := ((nTag>=tagList) and (nTag<=tagListOrdered))}
// {$DEFINE isBlock(nTag) := ((nTag>=tagBlock) and (nTag<=tagCode))}

{$DEFINE isHeader := ((tag>=tagH1) and (tag<=tagH4))}
{$DEFINE isLink := ((tag>=tagLink) and (tag<=tagImageDescription))}
{$DEFINE isList := ((tag>=tagList) and (tag<=tagListOrdered))}
{$DEFINE isBlock := ((tag>=tagBlock) and (tag<=tagCode))}

{$DEFINE isStyle(nStyle) := (style and nStyle<>0)}

{$DEFINE isWordBegin := (lineStat and statWordBegin<>0)}
{$DEFINE isLineBegin := (lineStat and statLineBegin<>0)}
{$DEFINE isLineEnd := (lineStat and statEndOfLine<>0)}

{$ELSE}

function isBeginTag(ntag:Byte):Boolean;
begin
  result:=((tag=nTag) and (prevTag<>nTag));
end;

function isEndTag(ntag:Byte):Boolean;
begin
  result:=((tag<>nTag) and (prevTag=nTag));
end;

//
function isTag(nTag:Byte):Boolean;
begin
  result:=(tag=nTag);
end;

function isHeader(nTag:Byte):Boolean; overload;
begin
  result:=((nTag>=tagH1) and (nTag<=tagH4));
end;
function isHeader():Boolean; overload;
begin
  result:=((tag>=tagH1) and (tag<=tagH4));
end;

function isLink(nTag:Byte):Boolean; overload;
begin
  result:=((nTag>=tagLink) and (nTag<=tagImageDescription));
end;
function isLink():Boolean; overload;
begin
  result:=((tag>=tagLink) and (tag<=tagImageDescription));
end;

function isList(nTag:Byte):Boolean; overload;
begin
  result:=((nTag>=tagList) and (nTag<=tagListOrdered));
end;
function isList():Boolean; overload;
begin
  result:=((tag>=tagList) and (tag<=tagListOrdered));
end;

function isBlock(nTag:Byte):Boolean; overload;
begin
  result:=((nTag>=tagBlock) and (nTag<=tagCode));
end;
function isBlock():Boolean; overload;
begin
  result:=((tag>=tagBlock) and (tag<=tagCode));
end;

//

function isStyle(nStyle:Byte):Boolean;
begin
  result:=(style and nStyle<>0);
end;

//

function isWordBegin():Boolean;
begin
  result:=(lineStat and statWordBegin<>0);
end;

function isLineBegin():Boolean;
begin
  result:=(lineStat and statLineBegin<>0);
end;

function isLineEnd():Boolean;
begin
  result:=(lineStat and statEndOfLine<>0);
end;

{$ENDIF}