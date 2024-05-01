{$macro on} // only for FPC compatibility

{$DEFINE isBeginTag(tg) := ((tag=tg) and (prevTag<>tg))}
{$DEFINE isEndTag(tg) := ((tag<>tg) and (prevTag=tg))}
{$DEFINE isTag(tg) := (tag=tg)}

{$DEFINE isHeader := ((tag>=tagH1) and (tag<=tagH4))}
{$DEFINE isLink := ((tag>=tagLink) and (tag<=tagImageDescription))}
{$DEFINE isList := ((tag>=tagList) and (tag<=tagListOrdered))}
{$DEFINE isBlock := ((tag>=tagBlock) and (tag<=tagCode))}

{$DEFINE isStyle(stl) := (style and stl<>0)}

{$DEFINE isWordBegin := (lineStat and statWordBegin<>0)}
{$DEFINE isLineBegin := (lineStat and statLineBegin<>0)}
{$DEFINE isLineEnd := (lineStat and statEndOfLine<>0)}
