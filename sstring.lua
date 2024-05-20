------------------------------------------------------------------------------
-- Funções adicionais para manipulação de strings.
-- O módulo "herda" de string, então pode ser usado em substituição a este.
--
-- Veja também
--	 <a href="http://lua-users.org/wiki/SplitJoin">SplitJoin</a>
------------------------------------------------------------------------------

local tonumber, setmetatable = tonumber, setmetatable
local string = require"string"
local gmatch, gsub = string.gmatch, string.gsub
local strbyte, strformat, strlen, strrep, strsub = string.byte, string.format, string.len, string.rep, string.sub
local table = require"sintra.table"
local tconcat, tswap = table.concat, table.swapkeyval

local M = setmetatable ({
	_COPYRIGHT = "Copyright (C) 2009-2023 PUC-Rio",
	_DESCRIPTION = "Funções de manipulação de strings",
	_VERSION = "Sintra String 1.27",
	lower2upper = {
		['ç'] = 'Ç', ['ñ'] = 'Ñ',
		['á'] = 'Á', ['é'] = 'É', ['í'] = 'Í', ['ó'] = 'Ó', ['ú'] = 'Ú', ['ý'] = 'Ý',
		['à'] = 'À', ['è'] = 'È', ['ì'] = 'Ì', ['ò'] = 'Ò', ['ù'] = 'Ù', ['ỳ'] = 'Ỳ',
		['ä'] = 'Ä', ['ë'] = 'Ë', ['ï'] = 'Ï', ['ö'] = 'Ö', ['ü'] = 'Ü', ['ÿ'] = 'Ÿ',
		['ã'] = 'Ã', ['ẽ'] = 'Ẽ', ['ĩ'] = 'Ĩ', ['õ'] = 'Õ', ['ũ'] = 'Ũ', ['ỹ'] = 'Ỹ',
		['â'] = 'Â', ['ê'] = 'Ê', ['î'] = 'Î', ['ô'] = 'Ô', ['û'] = 'Û', ['ŷ'] = 'Ŷ',
	},
}, {
	__index = string,
})
M.upper2lower = tswap (M.lower2upper)

------------------------------------------------------------------------------
-- Extrai as substrings a partir de um separador.
-- O separador pode ser definido através de um padrão de Lua.
-- Código original por Rici Lake em
-- <a href="http://lua-users.org/lists/lua-l/2006-12/msg00414.html">mensagem da lua-l</a>
-- @param s String a ser processada.
-- @param pat String com o separador.
-- @return Iterador que retorna uma substring, seguida das capturas indicadas
--	no padrão.
-- @usage for palavra in string.gsplit (frase, "%s+") do
--   print(palavra)
-- end

function M.gsplit (s, pat)
	local st, g = 1, s:gmatch("()("..pat..")")
	local function getter(self, segs, seps, sep, cap1, ...)
		st = sep and seps + #sep
		return self:sub(segs, (seps or 0) - 1), cap1 or sep, ...
	end
	local function splitter(self)
		if st then return getter(self, st, g()) end
	end
	return splitter, s
end

------------------------------------------------------------------------------
-- Aplica uma função às substrings de uma dada string, dado um separador.
-- Também toma cuidado com a presença do separador dentro de substrings entre aspas.
-- @param s String a ser processada.
-- @param f Função de processamento de cada substring (será chamada com um
--	único parâmetro, a substring, e não precisa retornar nada).
-- @param sep_ou_opt String com o separador (default = ';') ou Tabela de opções
--	(campos válidos: separator, empty_strings).
-- @usage string.asplit (frase, print, ' ')
------------------------------------------------------------------------------
function M.asplit (s, f, sep_ou_opt)
	local sep, patt
	local ts = type (sep_ou_opt)
	if ts == "table" then
		sep = sep_ou_opt.separator or ';'
		if sep_ou_opt.empty_strings then
			patt = "([^"..sep.."]*)"..sep
		else
			patt = "([^"..sep.."]+)"..sep
		end
	else
		if ts == "string" then
			sep = sep_ou_opt
		elseif ts == "nil" then
			sep = ';'
		else
			error ("Parâmetro #3 inválido: esperava uma string ou uma tabela, mas veio '"..ts.."'")
		end
		patt = "([^"..sep.."]+)"..sep
	end
	-- troca ocorrências do separador dentro de aspas (") por '\1'
	s = gsub (s, '"([^"]*)"', function (sub)
		return gsub (sub, sep, "\1") or ""
	end)
	for w in gmatch (s..sep, patt) do
		-- remove as aspas
		w = gsub (w, '^"(.*)"$', "%1")
		-- restaura o separador
		w = gsub (w, "\1", sep)
		f (w)
	end
end

------------------------------------------------------------------------------
-- Guarda todas as substrings em uma tabela.
-- @param s String a ser processada.
-- @param sep String com o separador (default = ';').
-- @param tab Tabela onde as substrings serão armazenadas (opcional).
-- @return Tabela representando um array de substrings.
-- @see asplit
-- @usage t = string.split2array (frase, ' ') --> { "palavra1", "palavra2", ... }
-- string.split2array (frase, ' ', t) -- insere na tabela dada
------------------------------------------------------------------------------
function M.split2array (s, sep, tab)
	tab = tab or {}
	M.asplit (s, function (w) tab[#tab+1] = w end, sep)
	return tab
end

------------------------------------------------------------------------------
-- Guarda todas as substrings em uma tabela.
-- @param s String a ser processada.
-- @param sep String com o separador (default = ';').
-- @param tab Tabela onde as substrings serão armazenadas (opcional).
-- @return Tabela representando um conjunto de substrings.
-- @see asplit
-- @usage t = split2record (frase, ' ') --> { palavra1 = true, palavra2 = true, ... }
------------------------------------------------------------------------------
function M.split2record (s, sep, tab)
	tab = tab or {}
	M.asplit (s, function (w) tab[w] = true end, sep)
	return tab
end

------------------------------------------------------------------------------
-- Remove os espaços do início e do fim de uma string.
-- Também reduz espaços múltiplos por um caractere único.
-- @param s String original (ou nil).
-- @return String ou nil, caso não seja fornecida nenhuma string.
-- @see notempty
-- @usage string.rmsp ("  a   b  ") == "a b"
-- @usage string.rmsp"    " == ''
------------------------------------------------------------------------------
function M.rmsp (s)
	if s == nil then return end
	s = gsub (s, "^%s*(.-)%s*$", "%1")
	s = gsub (s, "%s%s+", " ")
	return s
end

------------------------------------------------------------------------------
-- Verifica se uma string é não-vazia (descontando espaços).
-- @param s String original.
-- @return String sem espaços ou nil, caso seja uma string vazia ou nil.
-- @see rmsp
-- @usage string.notempty"b" --> "b"
-- @usage string.notempty' ' --> nil
------------------------------------------------------------------------------
function M.notempty (s)
	s = M.rmsp(s)
	if s == "" then
		return nil
	end
	return s
end

--
local preps = {
	["da"] = "da",
	["de"] = "de",
	["do"] = "do",
	["das"] = "das",
	["dos"] = "dos",
	["e"] = "e",
	["em"] = "em",
	["i"] = "I",
	["ii"] = "II",
	["iii"] = "III",
	["qci"] = "QCI",
}

------------------------------------------------------------------------------
-- "Formata" uma string, colocando as iniciais em maiúsculas e o resto em
--	minúsculas.
-- A função identifica algumas preposições e não as converte.
-- Baseada em string.upper, portanto não funciona direito com UTF-8.
-- @param s String a ser convertida.
-- @return String "formatada".
-- @usage string.capitalize"FULANO DE TAL" == "Fulano de Tal"
------------------------------------------------------------------------------
function M.capitalize (s)
	s = M.utf8lower(s) -- converte para minúsculas
	-- os '()' são para ignorar o segundo resultado da gsub()
	return (gsub (s, "([^%s%p]+)", function (w)
		return preps[w] -- preposição não é convertida
			--or (gsub (w, "^(%a)", strupper)) -- converte para maiúsculas
			--or (gsub (w, "^(\195%a)", M.utf8upper)) -- converte para maiúsculas
				--or (gsub (w, "^(%a)", M.utf8upper)) -- converte para maiúsculas
			or (w:match"^\195" and gsub (w, "^(\195.)", M.utf8upper) or gsub (w, "^(%a)", M.utf8upper))
	end))
end

------------------------------------------------------------------------------
-- Iterador real das palavras das strings, segundo seus ponteiros.
-- @param st Tabela com os arrays de palavras de cada string e seus ponteiros.
-- @return String quando a palavra for igual, ou Tabela com as duas palavras,
--	ou nil quando acabar.
------------------------------------------------------------------------------
function M.scomp (st)
	local a1, a2 = st.a1, st.a2
	local i1, i2 = st.i1, st.i2
	local w1, w2 = a1[i1], a2[i2]

	if w1 == nil and w2 == nil then
		-- fim
		return nil

	elseif w1 == nil then
		-- só restam palavras em a2
		st.i2 = i2+1
		return { '', w2 }
	elseif w2 == nil then
		-- só restam palavras em a1
		st.i1 = i1+1
		return { w1, '' }

	elseif w1 == w2 then
		-- mesma palavra
		st.i1 = i1+1
		st.i2 = i2+1
		return w1
	elseif w1 == a2[i2+1] then
		-- palavra extra em a2 => avança i2
		st.i2 = i2+1
		return { '', w2 }
	elseif w2 == a1[i1+1] then
		-- palavra extra em a1 => avança i1
		st.i1 = i1+1
		return { w1, '' }
	else
		-- palavras diferentes
		st.i1 = i1+1
		st.i2 = i2+1
		return { w1, w2 }
	end
end

------------------------------------------------------------------------------
-- Iterador que compara palavras de duas strings.
-- @param s1 String a ser comparada.
-- @param s2 String a ser comparada.
-- @param sep String com o separador de palavras da string.
-- @return Iterador que retorna uma string ou uma tabela com as duas
--	substrings diferentes.
------------------------------------------------------------------------------
function M.gcomp (s1, s2, sep)
	sep = sep or ' '
	local st = {
		a1 = M.split2array (s1, sep), i1 = 1,
		a2 = M.split2array (s2, sep), i2 = 1,
	}
	return M.scomp, st
end

--
local patterns = {
	"^(%d+)h(%d+)min$", -- formato h_min
	"^(%d+)h$", -- formato h_min
	"^(%d+)%:(%d+)$", -- formato 00:00
}

------------------------------------------------------------------------------
-- Tenta formatar uma string para o padrão "DDh MMmin".
-- @param s String a ser formatada.
-- @return String "formatada" ou nil, em caso de erro.
-- @return nil ou String com mensagem de erro.
-- @usage string.h_min "12:30" == "12h 30min"
-- @usage string.h_min "  12h   30  min  " == "12h 30min"
------------------------------------------------------------------------------
function M.h_min (s)
	s = gsub (s, "%s*", "") -- remove TODOS os espaços
	for i = 1, #patterns do
		local patt = patterns[i]
		local h, min = s:match (patt)
		if h then
			h, min = tonumber(h), tonumber(min)
			if h > 23 then
				return nil, "Hora inválida: maior que 23"
			elseif min == nil then
				return h..'h'
			elseif min > 59 then
				return nil, "Minuto inválido: maior que 59"
			else
				return strformat ("%sh %smin", h, min)
			end
		end
	end
	return nil, "Não consegui identificar o horário em ("..s..")"
end

--
local function tohex (c)
	return strformat (" %02X", strbyte (c))
end

--
local function linedump (s, w)
	return gsub (s, "%s",'.')..strrep (' ', w)..gsub (s, '(.)', tohex)..'\n'
end

------------------------------------------------------------------------------
-- Mostra a string e seus códigos em hexadecimal.
-- @param s String a ser exibida.
-- @param largura Número da largura máxima do resultado (default = 68)
-- @return String formatada para exibição.
-- @usage print(string.tohex"abc") --> abc                 61 62 63\n
------------------------------------------------------------------------------
function M.tohex (s, largura)
	largura = largura or 68
	local w = math.floor(largura/4) - 1
	local r = {}
	local max = strlen(s)
	local i, f = 1, w+1
	while i <= max do
		local ss = strsub (s, i, f)
		local len = strlen(ss)
		ss = linedump (ss, w-len+3)
		r[#r+1] = ss
		i, f = f+1, f+w+1
	end
	return tconcat (r)
end

------------------------------------------------------------------------------
-- Cria uma nova string a partir de um modelo e de uma tabela de entradas.
-- A nova string irá ser o resultado da substituição de cada nome no modelo
-- que esteja encerrado em dois cifrões, como em $$nome$$, pelo valor
-- correspondente na tabela de entradas.  Cada nome tem que ser um
-- identificador, ou seja, não pode incluir pontuação nem espaços.
-- @param s String modelo.
-- @param t Tabela de entradas.
-- @return String com as substituições aplicadas.

function M.subs (s, t)
	return (s:gsub ("%$%$([_%w]+)%$%$", t))
end

------------------------------------------------------------------------------
-- Cria função que substitui os acentos (e outros caracteres não-ASCII) por
-- letras simples.
-- @param cod String com a codificação em uso (utf8 ou iso88591).
-- @return Função que recebe uma string e retorna uma nova string sem os acentos.

function M.criaremoveacentos (cod)
	local rmacc = M["rmacc"..cod]
	if not rmacc then
		assert (cod == "utf8" or cod == "iso88591", "Sem suporte para codificação '"..cod.."'. Disponíveis: utf8 ou iso88591")
		local cd = require"iconv".new ("ASCII//TRANSLIT", cod)
		rmacc = function (s)
			local old = os.setlocale()
			os.setlocale("pt_BR."..cod)
			s = cd:iconv (s)
			os.setlocale (old)
			return s
		end
		M["rmacc"..cod] = rmacc
	end
	return rmacc
end

------------------------------------------------------------------------------
-- Cria uma nova string a partir de uma parte de outra string, respeitando
-- os caracteres UTF-8 (codepoints), independente de quantos bytes cada um
-- precisar para ser representado na string.
-- Implementação baseada na função <code>fixUTF8</code> de Paul Kulchenko
-- (<a href="http://notebook.kulchenko.com/programming/fixing-malformed-utf8-in-lua">para o ZeroBrane</a>).
-- @param s String com a string original.
-- @param i Número com o índice do primeiro caractere UTF-8 (codepoint) da
--	substring (default = 1).
-- @param j Número com o índice do último caractere UTF-8 (codepoint) da
--	substring (default = -1).
-- @return String resultante do "corte".
-- @usage string.utf8sub ("ação", 2, 3) --> "çã"

function M.utf8sub (s, i, j)
	i = i or 1
	local initial_byte, ending_byte = #s+1 -- default = fora da string
	local char_count = 1
	local p, len = 1, #s
	while p <= len do
		if i == char_count then
			initial_byte = p
		end
		if     p == s:find("[%z\1-\127]", p) then p = p + 1
		elseif p == s:find("[\194-\223][\128-\191]", p) then p = p + 2
		elseif p == s:find(       "\224[\160-\191][\128-\191]", p)
		    or p == s:find("[\225-\236][\128-\191][\128-\191]", p)
		    or p == s:find(       "\237[\128-\159][\128-\191]", p)
		    or p == s:find("[\238-\239][\128-\191][\128-\191]", p) then p = p + 3
		elseif p == s:find(       "\240[\144-\191][\128-\191][\128-\191]", p)
		    or p == s:find("[\241-\243][\128-\191][\128-\191][\128-\191]", p)
		    or p == s:find(       "\244[\128-\143][\128-\191][\128-\191]", p) then p = p + 4
		else
			-- String mal formada => corta daqui em diante!
			ending_byte = p
			break
		end
		if j == char_count then
			ending_byte = p-1
			break
		end
		char_count = char_count + 1
	end
	return s:sub (initial_byte, ending_byte)
end

------------------------------------------------------------------------------
-- Transforma a string UTF-8 em maiúsculas, inclusive com acentos.
-- @param s String original.
-- @return String resultante da operação.

function M.utf8upper (s)
	return s:gsub ('(\195.)', M.lower2upper):upper()
end

------------------------------------------------------------------------------
-- Transforma a string UTF-8 em minúsculas, inclusive com acentos.
-- @param s String original.
-- @return String resultante da operação.

function M.utf8lower (s)
	return s:gsub ('(\195.)', M.upper2lower):lower()
end

------------------------------------------------------------------------------
-- Converte uma string em Latin1 (ISO-8859-1) para UTF-8, se necessário.
-- @param s String original.
-- @return String em UTF-8.

function M.latin2utf8 (s)
	if utf8.len(s) then
		-- utf8.len() retorna nil no caso de alguma sequência de bytes inválida
		return s
	end
	local cd = require"iconv".new ("utf-8", "iso-8859-1")
	return cd:iconv (s)
end

------------------------------------------------------------------------------
return M
