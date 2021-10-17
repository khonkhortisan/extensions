-- {"id":278,"ver":"2.0.2","libVer":"1.0.0","author":"TechnoJo4","dep":["NovelFull>=2.0.2"]}

return Require("NovelFull")("https://readnovelfull.com", {
	id = 278,
	name = "ReadNovelFull",
	imageURL = "https://github.com/shosetsuorg/extensions/raw/dev/icons/ReadNovelFull.png",
	
	parseNovel = function(url, loadChapters)
		local doc = GETDocument(self.baseURL..url)
		local info = NovelInfo()
	
		local elem = doc:selectFirst(".info"):children()
		info:setTitle(doc:selectFirst("h3.title"):text())
	
		local meta_offset = elem:size() < 3 and self.meta_offset or 0
	
		info:alternativeTitles=(map(elem:get(meta_offset    ):select("a"), text))
		info:authors          =(map(elem:get(meta_offset + 1):select("a"), text))
		info:genres           =(map(elem:get(meta_offset + 2):select("a"), text))
		--info:sources        =(map(elem:get(meta_offset + 3):select("a"), text))
		info:status   =(NovelStatus(elem:get(meta_offset + 4):select("a"):text() == "Completed" and 1 or 0))
	
		info:setImageURL((self.appendURLToInfoImage and self.baseURL or "") .. doc:selectFirst("div.book img"):attr("src"))
		info:setDescription(table.concat(map(doc:select("div.desc-text p"), text), "\n"))
	
		if loadChapters then
			local id = doc:selectFirst("div[data-novel-id]"):attr("data-novel-id")
			local i = 0
			info:setChapters(AsList(map(
					GETDocument(qs({ novelId = id,currentChapterId = "" }, self.ajax_base .. self.ajax_chapters)):selectFirst("select"):children(),
					function(v)
						local chap = NovelChapter()
						chap:setLink(self.shrinkURL(v:attr("value")))
						chap:setTitle(v:text())
						chap:setOrder(i)
						i = i + 1
						return chap
					end)))
		end
	
		return info
	end,
	
	searchListSel = "list.list-novel.col-xs-12",
	appendURLToInfoImage = false,
})
