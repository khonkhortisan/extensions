-- {"id":278,"ver":"1.0.3","libVer":"1.0.0","author":"TechnoJo4","dep":["NovelFull>=2.0.2"]}

return Require("NovelFull")("https://readnovelfull.com", {
	id = 278,
	name = "ReadNovelFull",
	imageURL = "https://github.com/shosetsuorg/extensions/raw/dev/icons/ReadNovelFull.png",
	
	alternativeTitles=(map(elem:get(meta_offset    ):select("a"), text)),
	authors          =(map(elem:get(meta_offset + 1):select("a"), text)),
	genres           =(map(elem:get(meta_offset + 2):select("a"), text)),
	--sources        =(map(elem:get(meta_offset + 3):select("a"), text)),
	status   =(NovelStatus(elem:get(meta_offset + 4):select("a"):text() == "Completed" and 1 or 0)),
	
	searchListSel = "list.list-novel.col-xs-12",
	appendURLToInfoImage = false,
})
