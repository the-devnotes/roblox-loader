-- [Script] | Lokasi: ServerScriptService
-- Test khusus HP Android: tidak perlu buka Output, hasil klik muncul di layar.
-- Paste loader + file ini ke ServerScriptService, Publish, lalu buka game di Roblox Android.

local Players = game:GetService("Players")

task.spawn(function()
	-- Tunggu loader siap (urutan Script bisa acak).
	while not shared.ClipperHub do
		task.wait(0.1)
	end

	local function tampil(player)
		if not player then return end

		local info = {} -- dipakai biar tombol bisa update label yang dibuat belakangan

		local gui, frame = shared.ClipperHub.ui(player, "Test HP - Clipper Hub", {
			{ "CEK LOGO", function()
				local logo = frame:FindFirstChild("Logo")
				if info.label then
					info.label.Text = logo and ("Logo: " .. tostring(logo.Image)) or "Logo tidak ada"
				end
			end },
			{ "CEK NAMA", function()
				local header = frame:FindFirstChild("Header")
				local sub = frame:FindFirstChild("Subtitle")
				if info.label then
					info.label.Text = "Judul: " .. tostring(header and header.Text)
						.. "\nGame: " .. tostring(sub and sub.Text)
				end
			end },
			{ "TUTUP", function()
				gui:Destroy()
			end },
		})

		-- Perbesar biar enak dibaca di layar HP.
		frame.Size = UDim2.fromScale(0.62, 0.46)

		local status = Instance.new("TextLabel", frame)
		status.Size = UDim2.new(1, -24, 0, 46)
		status.Position = UDim2.new(0, 12, 1, -54)
		status.BackgroundColor3 = Color3.fromRGB(12, 12, 18)
		status.Text = "UI jalan. Klik tombol untuk cek."
		status.TextWrapped = true
		status.Font = Enum.Font.Gotham
		status.TextSize = 13
		status.TextColor3 = Color3.fromRGB(255, 220, 140)
		Instance.new("UICorner", status).CornerRadius = UDim.new(0, 8)
		info.label = status

		-- Tandai kalau helper UI memang kepanggil.
		local sub = frame:FindFirstChild("Subtitle")
		if sub then
			sub.Text = sub.Text .. " | MODE HP"
		end
	end

	local pertama = Players:GetPlayers()[1]
	if pertama then
		tampil(pertama)
	else
		local koneksi
		koneksi = Players.PlayerAdded:Connect(function(player)
			koneksi:Disconnect()
			tampil(player)
		end)
	end
end)
