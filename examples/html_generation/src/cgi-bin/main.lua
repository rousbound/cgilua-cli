#!/usr/bin/env cgilua.cgi

local h = require"html"


cgilua.put(
  h.HTML{
    h.BODY{
      h.H1"Hello world!"
    }
  }
)
