-- {"id":36834,"ver":"1.0.0","libVer":"1.0.0","author":"Khonkhortisan","dep":["url>=1.0.0","CommonCSS>=1.0.0"]}

local baseURL = "https://novelasligeras.net/"

local CATEGORIAS_INT = { [0]="Cualquier Categoría", [40]="Acción", [53]="Adulto", [41]="Aventura", [59]="Ciencia Ficción", [44]="Drama", [46]="Fantasía", [48]="Harem", [55]="Misterio", [60]="Seinen", [70]="Tragedia" }
local CATEGORIAS_KEY = 40

local qs = Require("url").querystring

local css = Require("CommonCSS").table

local function shrinkURL(url)
	return url:gsub("^.-novelasligeras%.net/?", "")
end

local function expandURL(url)
	return baseURL .. (url:sub(1, 1) == "/" and "" or "/") .. url
end

local function parseListing(doc)
	local results = doc:selectFirst(".fiction-list")

	return map(results:children(), function(v)
		local a = v:selectFirst(".fiction-title a")
		return Novel {
			title = a:text(),
			link = a:attr("href"):match("/index.php/producto/([^/]+)/.-"),
			imageURL = v:selectFirst("a img"):attr("src")
		}
	end)
end

local function listing(name, inc, url)
	url = expandURL(url)
	return Listing(name, inc, function(data)
		return parseListing(GETDocument(inc and (url.."?page="..data[PAGE]) or url))
	end)
end

return {
	id = 36834,
	name = "NovelasLigeras (customcss)",
	baseURL = baseURL,
	imageURL = "https://github.com/shosetsuorg/extensions/raw/dev/icons/NovelasLigeras.png",
	chapterType = ChapterType.HTML,

	listings = {
		listing("Lista de Novelas", true, "index.php/lista-de-novela-ligera-novela-web"),
		listing("Novelas Exclusivas", false, "index.php/etiqueta-novela/novela-exclusiva"),
		listing("Novelas Completados", true, "index.php/filtro/estado/completado"),
		listing("Autores Hispanos", true, "index.php/etiqueta-novela/autor-hispano")
	},

	shrinkURL = shrinkURL,
	expandURL = expandURL,

	parseNovel = function(url, loadChapters)
		local doc = GETDocument(baseURL.."/fiction/"..url.."/a")

		local page = doc:selectFirst(".page-content-inner")
		local header = page:selectFirst(".fic-header")
		local title = header:selectFirst(".fic-title")
		local info = page:selectFirst(".fiction-info")
		local tags = info:selectFirst(".margin-bottom-10")

		local s = mapNotNil(tags:children(), function(v)
			local text = v:ownText()
			if text == "" or text ~= text:upper() then
				return
			end
			return text
		end)[1]

		s = s and ({
			ONGOING = NovelStatus.PUBLISHING,
			COMPLETED = NovelStatus.COMPLETED,
		})[s] or NovelStatus.UNKNOWN

		local text = function(v) return v:text() end
		local novel = NovelInfo {
			title = title:selectFirst("h1"):text(),
			imageURL = header:selectFirst("img"):attr("src"),
			description = info:selectFirst(".description .hidden-content"):text(),
			tags = map(tags:selectFirst(".tags"):select("a"), text),
			authors = { title:selectFirst("h4 a"):text() },
			status = s
		}

		if loadChapters then
			local i = 0
			novel:setChapters(AsList(map(doc:selectFirst("#chapters tbody"):children(), function(v)
				local a = v:selectFirst("a")
				i = i + 1
				return NovelChapter {
					order = i,
					title = a:text(),
					link = a:attr("href")
				}
			end)))
		end

		return novel
	end,

	getPassage = function(url)
		return pageOfElem(GETDocument(expandURL(url)):selectFirst(".chapter-content"), true, css)
	end,

	searchFilters = {
		DropdownFilter(CATEGORIAS_KEY, "Categorías", { "Cualquier Categoría", "Acción", "Adulto", "Aventura", "Ciencia Ficción", "Drama", "Fantasía", "Harem", "Misterio", "Seinen", "Tragedia" })
	}
	search = function(data)
		return parseListing(GETDocument(qs({
			s = data[QUERY],
			status = data[CATEGORIAS_KEY]
		}, baseURL .. "")))
	end,
	isSearchIncrementing = false
}
