-- {"id":28505740,"ver":"1.0.0","libVer":"1.0.0","author":"Khonkhortisan","dep":["url>=1.0.0","CommonCSS>=1.0.0"]}

local baseURL = "https://www.novelasligeras.net/"

local CATEGORIAS_INT = {
	[0] =""  , --Cualquier Categoría
	[1] ="40", --Acción
	[2] ="53", --Adulto
	[3] ="52", --Artes Marciales
	[4] ="41", --Aventura
	[5] ="59", --Ciencia Ficción
	[6] ="43", --Comedia
	[7] ="68", --Deportes
	[8] ="44", --Drama
	[9] ="45", --Ecchi
	[10]="46", --Fantasía
	[11]="47", --Gender Bender
	[12]="48", --Harem
	[13]="49", --Histórico
	[14]="50", --Horror
	[15]="54", --Mechas (Robots Gigantes)
	[16]="55", --Misterio
	[17]="56", --Psicológico
	[18]="66", --Recuentos de la Vida
	[19]="57", --Romance
	[20]="60", --Seinen
	[21]="62", --Shojo
	[22]="63", --Shojo Ai
	[23]="64", --Shonen
	[24]="69", --Sobrenatural
	[25]="70", --Tragedia
	[26]="58", --Vida Escolar
	[27]="73"  --Xuanhuan
}
local CATEGORIAS_KEY = 40

local ESTADO_INT = {
	[0]=""   , --Cualquiera
	[1]="407", --Completado
	[2]="16" , --En Proceso
	[3]="17"   --Pausado
}
local ESTADO_KEY = 41

local TIPO_INT = {
	[0]=""  , --Cualquier
	[1]="23", --Novela Ligera
	[2]="24"  --Novela Web
}
local TIPO_KEY = 42

local PAIS_INT = {
	[0] =""    , --Cualquiera
	[1] ="1865", --Argentina
	[2] ="1749", --Chile
	[3] ="20"  , --China
	[4] ="4184", --Colombia
	[5] ="22"  , --Corea
	[6] ="1792", --Ecuador
	[7] ="21"  , --Japón
	[8] ="1704", --México
	[9] ="1657", --Nicaragua
	[10]="4341", --Perú
	[11]="2524"  --Venezuela
}
local PAIS_KEY = 43

local ORDER_BY_INT = {
	[0]="relevance" , --Relevancia
	[1]="popularity", --Ordenar por popularidad
	[2]="rating"    , --Ordenar por calificación media
	[3]="date"      , --Ordenar por los últimos
	[4]="price"     , --Ordenar por precio: bajo a alto
	[5]="price-desc"  --Ordenar por precio: alto a bajo
}
local ORDER_BY_KEY = 44

local qs = Require("url").querystring

local css = Require("CommonCSS").table

local function shrinkURL(url)
	return url:gsub("^.-novelasligeras%.net/?", "")
end

local function expandURL(url)
	return baseURL .. (url:sub(1, 1) == "/" and "" or "/") .. url
end

local function parseListing(doc)
	local results = doc:selectFirst(".dt-css-grid")
	--error(results.children():selectFirst(".woo-buttons-on-img a img"):attr("src"))

	return map(results:children(), function(v)
		local a = v:selectFirst(".entry-title a")
		--error(a:attr("href"))
		return Novel {
			title = a:text(),
			link = a:attr("href"):match("/index.php/producto/([^/]+)/.-"),
			--link = a:attr("href"),
			imageURL = v:selectFirst("img"):attr("src")
			--imageURL = v:selectFirst("img"):attr("srcset"):match("^([^\s]+)") --doesn't load?
		}
	end)
end

local function listing(name, inc, url)
	url = expandURL(url)
	return Listing(name, inc, function(data)
		return parseListing(GETDocument(inc and (url.."/page/"..data[PAGE]) or url))
	end)
end

return {
	id = 28505740,
	name = "Novelas Ligeras.net",
	baseURL = baseURL,
	imageURL = "https://github.com/shosetsuorg/extensions/raw/dev/icons/NovelasLigeras.png",
	imageURL = "https://github.com/khonkhortisan/extensions/raw/novelasligeras.net/icons/NovelasLigeras.png", --TODO
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
		--local doc = GETDocument(baseURL.."/fiction/"..url.."/a")
		--local doc = GETDocument(baseURL.."/index.php/"..url.."/a")
		--local doc = GETDocument(baseURL..url)
		local doc = GETDocument(baseURL.."/index.php/producto/"..url.."")
		--error(baseURL.."/index.php/producto/"..url.."")

		local page = doc:selectFirst(".content")
		local header = page:selectFirst(".entry-summary")
		local title = header:selectFirst(".entry-title")
		local info = page:selectFirst(".woocommerce-product-details__short-description")
		local genres = header:selectFirst(".posted_in")
		local tags = header:selectFirst(".tagged_as")

		--local s = mapNotNil(tags:children(), function(v)
		--	local text = v:ownText()
		--	if text == "" or text ~= text:upper() then
		--		return
		--	end
		--	return text
		--end)[1]

		--s = s and ({
		--	ONGOING = NovelStatus.PUBLISHING,
		--	COMPLETED = NovelStatus.COMPLETED,
		--})[s] or NovelStatus.UNKNOWN

		local text = function(v) return v:text() end
		local novel = NovelInfo {
			--title = title:selectFirst("a"):text(),
			title = title:text(),
			--imageURL = header:selectFirst("img"):attr("src"),
			imageURL = page:selectFirst(".wp-post-image"):attr("src") or page:selectFirst(".wp-post-image"):attr("srcset"):match("^([^\s]+)"),
			genres = map(genres:select("a"), text),
			tags = map(tags:select("a"), text),
			description = info:selectFirst(".woocommerce-product-details__short-description"):text(),
			--tags = map(tags:select("a"), function(v)
			--	return v:text()
			--end) or tags:text(), --TODO
			--tags = tags:text(),
			authors = { page:selectFirst(".woocommerce-product-attributes-item--attribute_pa_escritor   td p a") and page:selectFirst(".woocommerce-product-attributes-item--attribute_pa_escritor   td p a"):text() or ""}, --TODO
			artists = { page:selectFirst(".woocommerce-product-attributes-item--attribute_pa_ilustrador td p a") and page:selectFirst(".woocommerce-product-attributes-item--attribute_pa_ilustrador td p a"):text() or ""}, --TODO
			--status = s
		}
-- '.wpb_wrapper' has left column whole chapters '.wpb_tabs_nav a' and right column chapter parts '.post-content a'
		if loadChapters then
			local i = 0
			novel:setChapters(AsList(map(doc:selectFirst(".wpb_wrapper"):children(), function(v)
				local a = v:selectFirst(".post-content a")
				i = i + 1
				return NovelChapter {
					order = i,
					title = a and a:text() or "", --TODO have 0 chapters when there are 0 instead of 1
					link = (a and a:attr("href")) or ""
				}
			end)))
		end

		return novel
	end,

	getPassage = function(url)
		return pageOfElem(GETDocument(expandURL(url)):selectFirst(".wpb_text_column"), true, css)
	end,

	searchFilters = {
		--NovelasLigeras using invalid  filterID {0}
		DropdownFilter(CATEGORIAS_KEY, "Categorías", {"Cualquier Categoría","Acción","Adulto","Artes Marciales","Aventura","Ciencia Ficción","Comedia","Deportes","Drama","Ecchi","Fantasía","Gender Bender","Harem","Histórico","Horror","Mechas (Robots Gigantes)","Misterio","Psicológico","Recuentos de la Vida","Romance","Seinen","Shojo","Shojo Ai","Shonen","Sobrenatural","Tragedia","Vida Escolar","Xuanhuan"}),
		DropdownFilter(ESTADO_KEY, "Estado", {"Cualquiera","Completado","En Proceso","Pausado"}),
		DropdownFilter(TIPO_KEY, "Tipo", {"Cualquiera","Novela Ligera","Novela Web"}),
		DropdownFilter(PAIS_KEY, "País", {"Cualquiera","Argentina","Chile","China","Colombia","Corea","Ecuador","Japón","México","Nicaragua","Perú","Venezuela"}),
		DropdownFilter(ORDER_BY_KEY, "Pedido de la tienda", { "Relevancia", "Ordenar por popularidad", "Ordenar por calificación media", "Ordenar por los últimos", "Ordenar por precio: bajo a alto", "Ordenar por precio: alto a bajo" })
	},

	search = function(data)
		return parseListing(GETDocument(qs({
			s = data[QUERY],
			--post_type="product",
			--title=1,
			--excerpt=1,
			--content=0,
			--categories=1,
			--attributes=1,
			--tags=1,
			--sku=0,
			--ixwps=1,
			orderby = data[ORDER_BY_KEY]
		}, baseURL .. "")+
			'&ixwpst[product_cat][]='+data[CATEGORIAS_KEY]+
			'&ixwpst[pa_estado][]='+data[ESTADO_KEY]+
			'&ixwpst[pa_tipo][]='+data[TIPO_KEY]+
			'&ixwpst[pa_pais][]='+data[PAIS_KEY]
		))
	end,
	--isSearchIncrementing = false
}
