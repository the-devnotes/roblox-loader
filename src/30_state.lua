    --[[ ===================== 5. STATE & DATA ===================== ]]
    local AREAS = {
        {"Forest",         Vector3.new(597, 72, -316)},
        {"Lake",           Vector3.new(743, 72, -419)},
        {"Desert",         Vector3.new(950, 72, -311)},
        {"Jungle",         Vector3.new(1188, 71, -421)},
        {"Snow",           Vector3.new(1492, 78, -304)},
        {"Volcano",        Vector3.new(1874, 74, -415)},
        {"Abyss Ocean",    Vector3.new(2283, 77, -312)},
        {"Prehistoric",    Vector3.new(2809, 74, -417)},
        {"Cosmic",         Vector3.new(3393, 83, -312)},
        {"Royal Kingdom",  Vector3.new(4031, 83, -414)},
        {"Crystal Canyon", Vector3.new(4800, 83, -323)},
    }
    local AREA_NAMES = {}
    for i, a in ipairs(AREAS) do AREA_NAMES[i] = a[1] end

    local SORTS = {"Auto (terbaik)", "Rarity", "Value", "Progression", "Terdekat", "Berat (kg)"}
    local RARITY = {"common", "uncommon", "rare", "epic", "legendary", "mythic", "secret", "divine", "celestial", "godly", "transcendent", "cosmic", "eternal"}
    local RARITY_LABEL = {"Common", "Uncommon", "Rare", "Epic", "Legendary", "Mythic", "Secret", "Divine", "Celestial", "Godly", "Transcendent", "Cosmic", "Eternal"}
    local RARITY_NAMES = {"Semua", "Uncommon+", "Rare+", "Epic+", "Legendary+", "Mythic+", "Secret+", "Divine+", "Celestial+", "Godly+", "Transcendent+", "Cosmic+", "Eternal+"}
    local RARITY_COLOR = {
        Color3.fromRGB(168, 176, 198),
        Color3.fromRGB(112, 205, 145),
        Color3.fromRGB(104, 168, 255),
        Color3.fromRGB(190, 130, 255),
        Color3.fromRGB(255, 182, 82),
        Color3.fromRGB(255, 104, 132),
        Color3.fromRGB(255, 82, 205),
        Color3.fromRGB(120, 232, 255),
        Color3.fromRGB(255, 232, 120),
        Color3.fromRGB(255, 152, 62),
        Color3.fromRGB(255, 255, 255),
        Color3.fromRGB(190, 120, 255),
        Color3.fromRGB(255, 240, 160),
    }
    -- Dipakai HANYA untuk field rarity eksplisit / feedback claim.
    local RARITY_ALIAS = {
        basic = 1, common = 1, starter = 1, normal = 1,
        uncommon = 2,
        rare = 3,
        ["super rare"] = 4, epic = 4, ["ultra rare"] = 4,
        legendary = 5, mythical = 6, mythic = 6,
        secret = 7, hidden = 7,
        divine = 8, heavenly = 8,
        celestial = 9, exclusive = 9,
        godly = 10, ["god tier"] = 10, immortal = 10,
        transcendent = 11, transendent = 11,
        cosmic = 12, eternal = 13,
        ultimate = 13, supreme = 13, fabled = 13,
    }
    local VALUE_STEPS = {0, 1e3, 1e4, 1e5, 1e6, 1e7, 1e8, 1e9, 1e10, 1e12}
    local VALUE_NAMES = {"Semua", "1K+", "10K+", "100K+", "1M+", "10M+", "100M+", "1B+", "10B+", "1T+"}
    local PROG_STEPS = {0, 5, 10, 20, 30, 50, 75, 100, 150, 200, 300, 500}
    local PROG_NAMES = {"Semua", "5+", "10+", "20+", "30+", "50+", "75+", "100+", "150+", "200+", "300+", "500+"}

    local state = {
        steal = false, hatch = false, sell = false,
        area = 1, allAreas = false, autoArea = true,
        best = true,
        sort = 1,
        minRar = 1, minProg = 1, minVal = 1,
        galleryRar = 1,
        fallback = true, strict = false, probe = true, lite = true,
        stealDelay = 0.6, hatchDelay = 1.2, sellDelay = 1.2,
    }

    local running = true
    local ui
    local updateHome
    local galleryDirty = true
    local galleryRefresh = nil
    local gallerySig = ""
    local areaAutoRef = nil
    local lastCarry = nil
    local carryEventSeen = false
    local categoryRarity = {}
    local categoryProg = {}
    local categoryValue = {}
    local categoryWeight = {}
    local categoryChance = {}
    local categoryImage = {}
    local uidCategory = {}
    local uidArea = {}
    local assetUidHints = {} -- Uid asli dari StealTargetEvent (bukan nama model AreaEgg_)
    local probeDone = {}
    local probeAt = -1e9
    local toggleRefs = {}

