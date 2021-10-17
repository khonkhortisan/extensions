return Require("NovelFull")("https://mnovelfree.com", {
	id = 249,
	name = "MNovelFree",
	imageURL = "https://github.com/shosetsuorg/extensions/raw/dev/icons/MNovelFree.png",
	
	meta_offset = 0,
	
	alternativeTitles =         (map(elem:get(meta_offset    ):select("a"), text)),
	authors           =         (map(elem:get(meta_offset + 1):select("a"), text)),
	genres            =         (map(elem:get(meta_offset + 2):select("a"), text)),
	--sources         =         (map(elem:get(meta_offset + 3):select("a"), text)),
	status            = (NovelStatus(elem:get(meta_offset + 4):select("a"):text() == "Completed" and 1 or 0)),
	
	ajax_hot = "/lists/popular",
	ajax_latest = "/lists/new-novels",
	ajax_chapters = "",
	searchTitleSel = ".truyen-title"
})
