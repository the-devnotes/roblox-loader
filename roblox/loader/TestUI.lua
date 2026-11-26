-- [Script] | Lokasi: ServerScriptService
-- Cara test: paste loader + file ini ke ServerScriptService, lalu tekan Play.
-- UI akan muncul otomatis memakai logo / nama hub / nama game dari loader.

local Players = game:GetService("Players")

task.spawn(function()
	-- Urutan Script di ServerScriptService bisa acak, jadi tunggu loader siap.
	while not shared.ClipperHub do
		task.wait(0.1)
	end

	local function tampilkan(player)
		if not player then return end

		local gui = shared.ClipperHub.ui(player, "Menu Test Clipper Hub", {
			{ "TOMBOL 1", function()
				print("[Test] Tombol 1 diklik")
			end },
			{ "TOMBOL 2", function()
				print("[Test] Tombol 2 diklik")
			end },
		})

		print("[Test] UI berhasil dibuat:", gui ~= nil)
	end

	local pertama = Players:GetPlayers()[1]
	if pertama then
		tampilkan(pertama)
	else
		local koneksi
		koneksi = Players.PlayerAdded:Connect(function(player)
			koneksi:Disconnect()
			tampilkan(player)
		end)
	end
end)
