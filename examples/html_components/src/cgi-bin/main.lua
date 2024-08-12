#!/usr/bin/env cgilua.cgi

local lhc = require"lhc"
local h = require"html"

cgilua.put(
  lhc.document{
    title = "Hello World!",
    h.DIV{
      style = "display: flex; justify-content: center",
      h.H1"Hello World!"
    }
  }
)
