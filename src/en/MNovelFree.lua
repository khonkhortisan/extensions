-- {"id":"249","ver":"2.0.2","libVer":"1.0.0","author":"","dep":["NovelFull>=2.0.2"]}

return Require("NovelFull")("https://mnovelfree.com", {
	id = 249,
	name = "MNovelFree",
	imageURL = "https://github.com/shosetsuorg/extensions/raw/dev/icons/MNovelFree.png",
	
	meta_offset = 0,
	
	parseNovel = function(url, loadChapters)
		local doc = GETDocument(self.baseURL..url)
		local info = NovelInfo()
	
		local elem = doc:selectFirst(".info"):children()
		info:setTitle(doc:selectFirst("h3.title"):text())
	
		local meta_offset = elem:size() < 3 and self.meta_offset or 0
	
		info:alternativeTitles =(map(elem:get(meta_offset    ):select("a"), text))
		info:authors           =(map(elem:get(meta_offset + 1):select("a"), text))
		info:genres            =(map(elem:get(meta_offset + 2):select("a"), text))
		info:--sources         =(map(elem:get(meta_offset + 3):select("a"), text))
		info:status    =(NovelStatus(elem:get(meta_offset + 4):select("a"):text() == "Completed" and 1 or 0))
	
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
	
	ajax_hot = "/lists/popular",
	ajax_latest = "/lists/new-novels",
	ajax_chapters = "",
	searchTitleSel = ".truyen-title"
})
