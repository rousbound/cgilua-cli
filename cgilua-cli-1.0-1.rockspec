package = "cgilua-cli"
version = "1.0-1"
source = {
    url = "https://github.com/rousbound/cgilua-cli"
}

description = {
    summary = "CGILua CLI",
    detailed = "CGILua CLI interface",
    license = "MIT",
}

dependencies = {
    "lua = 5.3",
    "luafilesystem"
}

build = {
    type = "builtin",
    modules = {
       sstring = "sstring.lua" 
    },
    install = {
        bin = {
            cgilua = "cgilua"
        }
    }
}
