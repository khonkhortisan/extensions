-- {"id":1,"ver":"2.0.0","libVer":"1.0.0","author":"TechnoJo4","dep":["NovelFull>=2.0.0"]}

return Require("NovelFull")("http://novelfull.com", {
	id = 1,
	name = "NovelFull",
	imageURL = "https://github.com/shosetsuorg/extensions/raw/dev/icons/NovelFull.png",
	
	meta_offset = 0,
	
	authors           =         (map(elem:get(meta_offset    ):select("a"), text)),
	alternativeTitles =         (map(elem:get(meta_offset + 1):select("a"), text)),
	genres            =         (map(elem:get(meta_offset + 2):select("a"), text)),
	--sources         =         (map(elem:get(meta_offset + 3):select("a"), text)),
	status            = (NovelStatus(elem:get(meta_offset + 4):select("a"):text() == "Completed" and 1 or 0)),
	
	ajax_hot = "/ajax-search?type=hot",
	ajax_latest = "/ajax-search?type=latest",
	ajax_chapters = "/ajax-chapter-option",
	searchListSel = "list.list-truyen.col-xs-12",
	searchTitleSel = ".truyen-title"
})
