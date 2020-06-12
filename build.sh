# nim c -d:debug -d:usePcreHeader -o:gerbil --debugger:native --threads:on main.nim
# nim c -d:release -d:usePcreHeader -o:gerbil --threads:on main.nim
nim c -d:debug -o:gerbil --debugger:native --threads:on src/gerbil.nim
