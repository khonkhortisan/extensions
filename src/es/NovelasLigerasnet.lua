-- {"id":28505740,"ver":"1.0.32","libVer":"1.0.0","author":"Khonkhortisan","dep":["url>=1.0.0","CommonCSS>=1.0.0"]}

local baseURL = "https://novelasligeras.net" --WordPress site, plugins: WooCommerce, Yoast SEO, js_composer, user_verificat_front, avatar-privacy

local ORDER_BY_FILTER_EXT = { "Orden por defecto", "Relevancia", "Ordenar por popularidad", "Ordenar por calificación media", "Ordenar por los últimos", "Ordenar por precio: bajo a alto"}--, "Ordenar por id", "Ordenar por slug", "Ordenar por include" }
local ORDER_BY_FILTER_INT = {
	[0]="title" , --Orden por defecto (Listing is title, webview search is title-DESC, selecting Orden por defecto is menu_order)
	[1]="relevance", --Relevancia (webview search is title-DESC when it should be relevance)
	[2]="popularity", --Ordenar por popularidad
	[3]="rating"    , --Ordenar por calificación media
	[4]="date"      , --Ordenar por los últimos
	[5]="price"     , --Ordenar por precio: bajo a alto
	[6]="id"        , --id/slug/include are supported by WooCommerce, but not currently shown in the extension
	[7]="slug"      , --id is different from slug
	[8]="include"     --is what? https://woocommerce.github.io/woocommerce-rest-api-docs/#list-all-products
	--only some of these can be descending
}
local ORDER_BY_FILTER_KEY = 40
local ORDER_FILTER_KEY = 41

local CATEGORIAS_FILTER_INT = {
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
local CATEGORIAS_FILTER_KEY = 42

local ESTADO_FILTER_INT = {
	[0]=""   , --Cualquiera --NovelStatus.UNKNOWN
	[1]="407", --Completado --NovelStatus.COMPLETED
	[2]="16" , --En Proceso --NovelStatus.PUBLISHING
	[3]="17"   --Pausado    --            On Hold/haitus
}
local ESTADO_FILTER_KEY = 43

local TIPO_FILTER_INT = {
	[0]=""  , --Cualquier
	[1]="23", --Novela Ligera
	[2]="24"  --Novela Web
}
local TIPO_FILTER_KEY = 44

local PAIS_FILTER_INT = {
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
local PAIS_FILTER_KEY = 45

local qs = Require("url").querystring

local css = Require("CommonCSS").table

local encode = Require("url").encode
local text = function(v)
	return v:text()
end
local settings = {}

--This function was copied directly from lib/Madara.lua
---@param image_element Element An img element of which the biggest image shall be selected.
---@return string A link to the biggest image of the image_element.
local function img_src(image_element)
	-- Different extensions have the image(s) saved in different attributes. Not even uniformly for one extension.
	-- Partially this comes down to script loading the pictures. Therefore, scour for a picture in the default HTML page.

	-- Check data-srcset:
	local srcset = image_element:attr("data-srcset")
	if srcset ~= "" then
		-- Get the largest image.
		local max_size, max_url = 0, ""
		for url, size in srcset:gmatch("(http.-) (%d+)w") do
			if tonumber(size) > max_size then
				max_size = tonumber(size)
				max_url = url
			end
		end
		return max_url
	end

	-- Check data-src:
	srcset = image_element:attr("data-src")
	if srcset ~= "" then
		return srcset
	end

	-- Default to src (the most likely place to be loaded via script):
	return image_element:attr("src")
end

local function createFilterString(data)
	return "orderby=" .. encode(ORDER_BY_FILTER_INT[data[ORDER_BY_FILTER_KEY]]) .. (data[ORDER_FILTER_KEY] and "-desc" or "") ..
		(data[CATEGORIAS_FILTER_KEY]~=0 and "&ixwpst[product_cat][]="..encode(CATEGORIAS_FILTER_INT[data[CATEGORIAS_FILTER_KEY]]) or "")..
		(data[CATEGORIAS_FILTER_KEY]~=0 and "&ixwpst[pa_estado][]="  ..encode(ESTADO_FILTER_INT[data[ESTADO_FILTER_KEY]])         or "")..
		(data[CATEGORIAS_FILTER_KEY]~=0 and "&ixwpst[pa_tipo][]="    ..encode(TIPO_FILTER_INT[data[TIPO_FILTER_KEY]])             or "")..
		(data[CATEGORIAS_FILTER_KEY]~=0 and "&ixwpst[pa_pais][]="    ..encode(PAIS_FILTER_INT[data[PAIS_FILTER_KEY]])             or "")
		--other than orderby, filters in url must not be empty
end
local function createSearchString(data)
	return "https://novelasligeras.net/?s="..encode(data[QUERY]).."&post_type=product&"..createFilterString(data)
end

local function shrinkURL(url)
	return url:gsub("^.-novelasligeras%.net/?", "")
end
local function expandURL(url)
	return baseURL .. (url:sub(1, 1) == "/" and "" or "/") .. url
end

local function parseListing(doc)
	local results = doc:selectFirst(".dt-css-grid")

	return map(results:children(), function(v)
		local a = v:selectFirst(".entry-title a")
		return Novel {
			title = a:text(),
			link = a:attr("href"):match("(index.php/producto/[^/]+)/.-"),
			imageURL = img_src(v:selectFirst("img"))
		}
	end)
end

local function listing(name, inc, url)
	url = expandURL(url)
	return Listing(name, inc, function(data)
		return parseListing(GETDocument(inc and (url .. "/page/" .. data[PAGE]+1 .. "/?" .. createFilterString(data)) or url))
	end)
end

return {
	id = 28505740,
	name = "Novelas Ligeras.net",
	baseURL = baseURL,
	imageURL = "https://github.com/shosetsuorg/extensions/raw/dev/icons/NovelasLigeras.png",
	imageURL = "https://github.com/khonkhortisan/extensions/raw/novelasligeras.net/icons/NovelasLigeras.png", --TODO
	hasSearch = true,
	chapterType = ChapterType.HTML,

	listings = {
		listing("Lista de Novelas", true, "index.php/lista-de-novela-ligera-novela-web"),
		listing("Novelas Exclusivas", false, "index.php/etiqueta-novela/novela-exclusiva"),
		listing("Novelas Completados", false, "index.php/filtro/estado/completado"),
		listing("Autores Hispanos", false, "index.php/etiqueta-novela/autor-hispano")
	},

	shrinkURL = shrinkURL,
	expandURL = expandURL,

	parseNovel = function(url, loadChapters)
		local doc = GETDocument(baseURL..'/'..url.."") -- the quotes at the end matter

		local page = doc:selectFirst(".content")
		local header = page:selectFirst(".entry-summary")
		local title = header:selectFirst(".entry-title")
		local info = page:selectFirst(".woocommerce-product-details__short-description")
		local genres = header:selectFirst(".posted_in")
		local tags = header:selectFirst(".tagged_as")
		
		local text = function(v) return v:text() end
		local status  =   page:selectFirst(".woocommerce-product-attributes-item--attribute_pa_estado     td p a") and page:selectFirst(".woocommerce-product-attributes-item--attribute_pa_estado     td p a"):text() or ""
		status = NovelStatus(status == "Completado" and 1 or status == "Pausado" and 2 or status == "En Proceso" and 0 or 3)
		local novel = NovelInfo {
			imageURL = page:selectFirst(".wp-post-image"):attr("src") or page:selectFirst(".wp-post-image"):attr("srcset"):match("^([^\s]+)"),
			title = title:text(),
			authors = map(page:select(".woocommerce-product-attributes-item--attribute_pa_escritor td p a"), text),
			artists = map(page:select(".woocommerce-product-attributes-item--attribute_pa_ilustrador td p a"), text),
			status = status,
			genres = map(genres:select("a"), text),
			tags = map(tags:select("a"), text),
			description = page:selectFirst(".woocommerce-product-details__short-description"):text(),
		}
		-- '.wpb_wrapper' has left column whole chapters '.wpb_tabs_nav a' and right column chapter parts '.post-content a'
		if loadChapters then
			local i = 0
			--STRUCTURE OF CHAPTERS PAGE:
			--  R sidebar|:nth-child(2)                          List of chapters|individual chapters                                             |title without time
			--div.wpb_tab div.wpb_text_column.wpb_content_element div.wpb_wrapper                                                                p a	- 86 prologue chapter
			--div.wpb_tab div.wpb_text_column.wpb_content_element div.wpb_wrapper div.wf-cell.wf-1 article.post-format-standard div.post-content p a	- 86 other chapters
			--div.wpb_tab div.wpb_text_column.wpb_content_element div.wpb_wrapper div.wf-cell.wf-1 article.post-format-standard div.post-content   a	- A Monster Who Levels Up prologue chapter
			--div.wpb_tab div.wpb_text_column.wpb_content_element div.wpb_wrapper div.wf-cell.wf-1 article.post-format-standard div.post-content p a	- A Monster Who Levels Up other chapters
			--div.wpb_tab section.items-grid.wf-container                         div.wf-cell.wf-1 article.post-format-standard div.post-content   a	- Abyss (NH), 10 nen 
			
			--div.wpb_tab.ui-tabs-panel.wpb_ui-tabs-hide.vc_clearfix.ui-corner-bottom.ui-widget-content --right sidebar of single volume/section of chapters, including label
			--div.dt-fancy-separator.h3-size.style-thick.accent-title-color.accent-border-color         --                                                              label
			--section.items-grid.wf-container                                                           --                               section of chapters
			--div.wpb_text_column.wpb_content_element div.wpb_wrapper                                   --                               section of chapters
			novel:setChapters(AsList(map(doc:select(".wpb_tab a"), function(v) --each volume has multiple tabs, each tab has one or more a, each a is a chapter title/link/before time
				local a = v
				local a_time = a:lastElementSibling()
				i = i + 1
				return NovelChapter {
					order = i,
					title = a and a:text() or nil,
					link = (a and a:attr("href")) or nil,
					--release = (v:selectFirst("time") and (v:selectFirst("time"):attr("datetime") or v:selectFirst("time"):text())) or nil
					release = (a_time and (a_time:attr("datetime") or a_time:text())) or nil
				}
			end)))
		end

		return novel
	end,

	getPassage = function(url)
		local adblock = true
		local doc = GETDocument(url)
		if adblock then
			--block Publicidad Y-AR, Publicidad M-M4, etc.
			doc:select(".wpb_text_column .wpb_wrapper div center"):matches("^Publicidad [A-Z0-9]-[A-Z0-9][A-Z0-9]"):remove()
			--leave this image alone: "¡Ayudanos! A traducir novelas del japones ¡Suscribete! A NOVA" (86)
			--leave any other possible <center> tags alone
		end
		return pageOfElem(doc:selectFirst(".wpb_text_column .wpb_wrapper"), true, css)
	end,

	searchFilters = {
		DropdownFilter(ORDER_BY_FILTER_KEY, "Pedido de la tienda", ORDER_BY_FILTER_EXT),
		SwitchFilter(ORDER_FILTER_KEY, "Ascendiendo / Descendiendo"),
		DropdownFilter(CATEGORIAS_FILTER_KEY, "Categorías", {"Cualquier Categoría","Acción","Adulto","Artes Marciales","Aventura","Ciencia Ficción","Comedia","Deportes","Drama","Ecchi","Fantasía","Gender Bender","Harem","Histórico","Horror","Mechas (Robots Gigantes)","Misterio","Psicológico","Recuentos de la Vida","Romance","Seinen","Shojo","Shojo Ai","Shonen","Sobrenatural","Tragedia","Vida Escolar","Xuanhuan"}),
		DropdownFilter(ESTADO_FILTER_KEY, "Estado", {"Cualquiera","Completado","En Proceso","Pausado"}),
		DropdownFilter(TIPO_FILTER_KEY, "Tipo", {"Cualquiera","Novela Ligera","Novela Web"}),
		DropdownFilter(PAIS_FILTER_KEY, "País", {"Cualquiera","Argentina","Chile","China","Colombia","Corea","Ecuador","Japón","México","Nicaragua","Perú","Venezuela"})
	},

	isSearchIncrementing = false,
	search = function(data)
		return parseListing(GETDocument(createSearchString(data)))
	end,
	
	setSettings = function(s) settings = s end,
	updateSetting = function(id, value)
		settings[id] = value
	end
}
--})
