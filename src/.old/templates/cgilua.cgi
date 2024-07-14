#!/bin/sh

LUAROCKS_SYSCONFDIR='/etc/luarocks' exec '/usr/bin/lua5.3' -e 'package.path="/home/app/.luarocks/share/lua/5.3/?.lua;/home/app/.luarocks/share/lua/5.3/?/init.lua;"..package.path;package.cpath="/home/app/.luarocks/lib/lua/5.3/?.so;"..package.cpath;local k,l,_=pcall(require,"luarocks.loader") _=k and l.add_context("cgilua","6.0.2-0")' '/home/app/.luarocks/lib/luarocks/rocks-5.3/cgilua/6.0.2-0/bin/cgilua.cgi' "$@"  
