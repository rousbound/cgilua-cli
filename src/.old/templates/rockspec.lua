package = "$$PROJECT_NAME$$"
version = "0.1-0"
source = {
  url = "", 
}
description = {
  summary = "$$PROJECT_NAME$$ rockspec",
}
dependencies = {
  "cgilua >= 6.0",
  "wsapi >= 1.7"
  "dado >=  2.2",
  "htk >= 3.3",
  "luasql-postgres >= 2.6.0",
}
build = {
  type = "builtin",
  modules = {},
}
