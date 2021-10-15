-- {"id":28505740,"ver":"1.0.0","libVer":"1.0.0","author":"Khonkhortisan","dep":["url>=1.0.0","CommonCSS>=1.0.0"]}

local baseURL = "https://novelasligeras.net/"

local CATEGORIAS_INT = { 
	[0]="",   --Cualquier Categoría
	[1]="40", --Acción
	[2]="53", --Adulto
	[3]="41", --Aventura
	[4]="59", --Ciencia Ficción
	[5]="44", --Drama
	[6]="46", --Fantasía
	[7]="48", --Harem
	[8]="55", --Misterio
	[9]="60", --Seinen
	[10]="70" --Tragedia
}
local CATEGORIAS_KEY = 40

local ORDER_BY_INT = { 
	[0]="relevance",  --Relevancia
	[1]="popularity", --Ordenar por popularidad
	[2]="rating",     --Ordenar por calificación media
	[3]="date",       --Ordenar por los últimos
	[4]="price",      --Ordenar por precio: bajo a alto
	[5]="price-desc"  --Ordenar por precio: alto a bajo
}
local ORDER_BY_KEY = 41

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
	id = 28505740,
	name = "Novelas Ligeras",
	baseURL = baseURL,
	imageURL = "https://github.com/shosetsuorg/extensions/raw/dev/icons/NovelasLigeras.png",
	imageURL = "https://github.com/khonkhortisan/extensions/raw/novelasligeras.net/icons/NovelasLigeras.png",
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
		local doc = GETDocument(baseURL.."/index.php/"..url.."/a")

		local page = doc:selectFirst(".content")
		local header = page:selectFirst(".fic-header")
		local title = header:selectFirst(".entry-title")
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
			description = info:selectFirst(".woocommerce-product-details__short-description"):text(),
			tags = map(tags:selectFirst(".product_meta"):select("a"), text),
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
		--NovelasLigeras using invalid  filterID {0}
		DropdownFilter(CATEGORIAS_KEY, "Categorías", { "Cualquier Categoría", "Acción", "Adulto", "Aventura", "Ciencia Ficción", "Drama", "Fantasía", "Harem", "Misterio", "Seinen", "Tragedia" }),
		DropdownFilter(ORDER_BY_KEY, "Pedido de la tienda", { "Relevancia", "Ordenar por popularidad", "Ordenar por calificación media", "Ordenar por los últimos", "Ordenar por precio: bajo a alto", "Ordenar por precio: alto a bajo" })
	},

	search = function(data)
		return parseListing(GETDocument(qs({
			s = data[QUERY],
			status = data[CATEGORIAS_KEY],
			orderby = data[ORDER_BY_KEY]
		}, baseURL .. "")))
	end,
	isSearchIncrementing = false
}
