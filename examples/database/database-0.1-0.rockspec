package = "database"
version = "0.1-0"
source = {
  url = "", 
}
description = {
  summary = "database rockspec",
}
dependencies = {
  "cgilua >= 6.0",
  "wsapi >= 1.7",
  "dado >=  2.2",
  "htk >= 3.3",
  "luasql-sqlite3 >= 2.3",
}
build = {
  type = "builtin",
  modules = {},
}
