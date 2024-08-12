#!/usr/bin/env cgilua.cgi
local typst = require"typst"


local pdf_bytes = typst.compile("doc.typ", {who = "Lua!"})


cgilua.contentheader("application", "pdf")

cgilua.put(pdf_bytes)
