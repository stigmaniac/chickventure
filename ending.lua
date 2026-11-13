
-- =========================================
-- CHICKVENTURE: PIPPO'S ADVENTURE
-- STEP 30: STAR GUARDIAN AWAKENING
-- =========================================

local Ending = {}

local timer = 0
local particles = {}
local stars = {}
local finished = false
local endingTitleFont = nil
local endingHeadingFont = nil
local endingBodyFont = nil

local W, H = 200, 150

local function random(min, max)
    return love.math.random(min, max)
end

local function star(x, y, size, rotation)
    rotation = rotation or 0
    local points = {}

    for i = 1, 10 do
        local angle = (i - 1) * math.pi / 5 - math.pi / 2 + rotation
        local radius = (i % 2 == 1) and size or size * 0.43

        table.insert(points, x + math.cos(angle) * radius)
        table.insert(points, y + math.sin(angle) * radius)
    end

    love.graphics.polygon("fill", points)
end

local function spawnParticle(x, y)
    table.insert(particles, {
        x = x,
        y = y,
        vx = random(-20, 20) / 20,
        vy = random(-30, -8) / 20,
        life = random(15, 35) / 10,
        maxLife = 3.5,
        size = random(1, 2)
    })
end

function Ending.start()
    timer = 0
    particles = {}
    stars = {}
    finished = false

    for i = 1, 20 do
        stars[i] = {
            angle = i * math.pi * 2 / 20,
            radius = random(15, 38),
            size = random(1, 3)
        }
    end
end

function Ending.update(dt)
    if finished then return end

    timer = timer + dt

    if random(1, 2) == 1 then
        spawnParticle(random(5, 195), random(30, 140))
    end

    if timer > 6 and random(1, 2) == 1 then
        spawnParticle(random(75, 125), random(65, 110))
    end

    for i = #particles, 1, -1 do
        local p = particles[i]

        p.x = p.x + p.vx * 12 * dt
        p.y = p.y + p.vy * 12 * dt
        p.life = p.life - dt

        if p.life <= 0 then
            table.remove(particles, i)
        end
    end

    if timer > 18 then
        finished = true
    end
end

-- =========================================
-- BACKGROUND DETAILS
-- =========================================

local function drawCloud(x, y, size)
    love.graphics.setColor(1, 1, 1, 0.75)
    love.graphics.circle("fill", x, y, size * 0.55)
    love.graphics.circle("fill", x + size * 0.65, y - size * 0.25, size * 0.7)
    love.graphics.circle("fill", x + size * 1.3, y, size * 0.55)
end

local function drawTree(x, y, size)
    love.graphics.setColor(0.43, 0.29, 0.20)
    love.graphics.rectangle("fill", x - 2 * size, y, 4 * size, 15 * size)

    love.graphics.setColor(0.19, 0.49, 0.30)
    love.graphics.circle("fill", x, y - 7 * size, 10 * size)
    love.graphics.circle("fill", x - 7 * size, y - 2 * size, 7 * size)
    love.graphics.circle("fill", x + 7 * size, y - 2 * size, 7 * size)

    love.graphics.setColor(0.31, 0.65, 0.36)
    love.graphics.circle("fill", x - 3 * size, y - 9 * size, 4 * size)
end

local function drawFlower(x, y, size, color)
    love.graphics.setColor(0.20, 0.48, 0.23)
    love.graphics.setLineWidth(1)
    love.graphics.line(x, y, x, y + 5 * size)

    love.graphics.setColor(color)

    for i = 0, 3 do
        local a = i * math.pi / 2
        love.graphics.circle(
            "fill",
            x + math.cos(a) * 2 * size,
            y + math.sin(a) * 2 * size,
            2 * size
        )
    end

    love.graphics.setColor(1, 0.85, 0.30)
    love.graphics.circle("fill", x, y, 1.5 * size)
end

local function drawMeadow(bloom)
    love.graphics.setColor(0.48, 0.76, 0.64)
    love.graphics.circle("fill", 20, 93, 35)
    love.graphics.circle("fill", 75, 92, 31)
    love.graphics.circle("fill", 180, 92, 38)

    -- Mountains
    love.graphics.setColor(0.65, 0.78, 0.79)
    love.graphics.polygon("fill", 112, 100, 137, 57, 164, 100)
    love.graphics.polygon("fill", 142, 100, 172, 65, 199, 100)

    love.graphics.setColor(1, 0.96, 0.85)
    love.graphics.polygon("fill",
        129, 71, 137, 57, 146, 72, 139, 69, 136, 75
    )
    love.graphics.polygon("fill",
        163, 76, 172, 65, 181, 77, 173, 74, 170, 80
    )

    -- Grass
    love.graphics.setColor(0.31, 0.67, 0.37)
    love.graphics.rectangle("fill", 0, 101, W, 49)

    love.graphics.setColor(0.40, 0.76, 0.40)
    love.graphics.ellipse("fill", 35, 104, 48, 9)
    love.graphics.ellipse("fill", 150, 104, 58, 10)

    -- Trees
    drawTree(13, 101, 0.8)
    drawTree(35, 100, 0.65)
    drawTree(185, 100, 0.9)
    drawTree(165, 101, 0.65)

    -- Flowers
    local count = math.floor(5 + bloom * 24)

    local colors = {
        {1, 0.65, 0.78},
        {1, 0.87, 0.40},
        {0.80, 0.75, 1},
        {1, 0.95, 0.85}
    }

    for i = 1, count do
        local x = (i * 37) % 198 + 1
        local y = 110 + (i * 13) % 35

        drawFlower(x, y, 0.65, colors[(i % 4) + 1])
    end

    -- Grass details
    love.graphics.setColor(0.20, 0.53, 0.28)

    for i = 1, 45 do
        local x = (i * 29) % 200
        local y = 105 + (i * 17) % 43

        love.graphics.line(x, y, x - 2, y - 4)
        love.graphics.line(x, y, x + 2, y - 5)
    end
end

-- =========================================
-- PIPPO
-- =========================================

local function drawPippo(x, y, armored)
    local bounce = math.sin(timer * 6) * 1.2
    y = y + bounce

    love.graphics.setColor(0.16, 0.42, 0.24, 0.35)
    love.graphics.ellipse("fill", x, y + 12, 11, 3)

    love.graphics.setColor(1, 0.85, 0.36)
    love.graphics.ellipse("fill", x, y, 10, 11)

    love.graphics.setColor(1, 0.88, 0.46)
    love.graphics.circle("fill", x, y - 9, 8)

    love.graphics.setColor(1, 0.52, 0.15)
    love.graphics.ellipse("fill", x - 4, y + 10, 3, 1.5)
    love.graphics.ellipse("fill", x + 4, y + 10, 3, 1.5)

    local wing = math.sin(timer * 8) * 2

    love.graphics.setColor(1, 0.73, 0.28)
    love.graphics.ellipse("fill", x - 10, y - 1 - wing, 3, 5)
    love.graphics.ellipse("fill", x + 10, y - 1 - wing, 3, 5)

    love.graphics.setColor(0.13, 0.13, 0.13)
    love.graphics.circle("fill", x - 3, y - 10, 1)
    love.graphics.circle("fill", x + 3, y - 10, 1)

    love.graphics.setColor(1, 0.55, 0.18)
    love.graphics.polygon("fill",
        x - 2, y - 7,
        x + 2, y - 7,
        x, y - 4
    )

    love.graphics.setColor(1, 0.56, 0.58, 0.8)
    love.graphics.circle("fill", x - 5, y - 7, 1.5)
    love.graphics.circle("fill", x + 5, y - 7, 1.5)

    if armored then
        -- Shoulder guards
        love.graphics.setColor(1, 0.69, 0.17)
        love.graphics.circle("fill", x - 9, y - 2, 3)
        love.graphics.circle("fill", x + 9, y - 2, 3)

        -- Wing-shaped armor
        love.graphics.setColor(1, 0.85, 0.38)

        love.graphics.polygon("fill",
            x - 11, y - 5,
            x - 16, y - 10,
            x - 14, y - 2,
            x - 10, y + 1
        )

        love.graphics.polygon("fill",
            x + 11, y - 5,
            x + 16, y - 10,
            x + 14, y - 2,
            x + 10, y + 1
        )

        -- Chestplate
        love.graphics.setColor(0.91, 0.58, 0.12)
        love.graphics.rectangle("fill", x - 6, y - 2, 12, 8)

        love.graphics.setColor(1, 0.84, 0.33)
        love.graphics.rectangle("fill", x - 5, y - 2, 10, 6)

        -- Star emblem
        love.graphics.setColor(1, 0.98, 0.78)
        star(x, y + 1, 3)

        -- Helmet
        love.graphics.setColor(0.89, 0.56, 0.12)
        love.graphics.arc("fill", "open", x, y - 9, 8, math.pi, math.pi * 2)

        love.graphics.setColor(1, 0.82, 0.29)
        love.graphics.arc("fill", "open", x, y - 9, 7, math.pi, math.pi * 2)
        love.graphics.rectangle("fill", x - 8, y - 11, 16, 2)

        -- Helmet star
        love.graphics.setColor(1, 0.98, 0.65)
        star(x, y - 17, 3)
    end
end

-- =========================================
-- STARHEART
-- =========================================

local function drawStarheart()
    local x, y = 100, 35
    local pulse = 1 + math.sin(timer * 3) * 0.12

    if timer > 1 then
        for i = 1, 12 do
            local a = i * math.pi / 6 + timer * 0.15

            local x1 = x + math.cos(a) * 18 * pulse
            local y1 = y + math.sin(a) * 18 * pulse
            local x2 = x + math.cos(a) * 35 * pulse
            local y2 = y + math.sin(a) * 35 * pulse

            love.graphics.setColor(1, 0.89, 0.42, 0.22)
            love.graphics.setLineWidth(1)
            love.graphics.line(x1, y1, x2, y2)
        end
    end

    love.graphics.setColor(1, 0.83, 0.25, 0.10)
    love.graphics.circle("fill", x, y, 29 * pulse)

    love.graphics.setColor(1, 0.88, 0.35, 0.20)
    love.graphics.circle("fill", x, y, 22 * pulse)

    love.graphics.setColor(1, 0.94, 0.57, 0.35)
    love.graphics.circle("fill", x, y, 15 * pulse)

    love.graphics.setColor(1, 0.95, 0.54)
    star(x, y, 12 * pulse, timer * 0.12)

    love.graphics.setColor(1, 1, 0.88)
    star(x, y, 6 * pulse, -timer * 0.12)

    for _, s in ipairs(stars) do
        local a = s.angle + timer * 0.6
        local sx = x + math.cos(a) * s.radius
        local sy = y + math.sin(a) * s.radius * 0.55

        love.graphics.setColor(1, 0.84, 0.31)
        star(sx, sy, s.size, timer)
    end
end

-- =========================================
-- BUTTERFLIES
-- =========================================

local function drawButterfly(x, y, color)
    local flap = math.sin(timer * 12) * 2

    love.graphics.setColor(color)
    love.graphics.ellipse("fill", x - 2, y, 2, 2 + flap)
    love.graphics.ellipse("fill", x + 2, y, 2, 2 + flap)

    love.graphics.setColor(0.22, 0.25, 0.20)
    love.graphics.line(x, y - 2, x, y + 3)
end

-- =========================================
-- MAIN DRAW
-- =========================================

function Ending.draw()
    local width, height = love.graphics.getDimensions()
    local scaleX = width / W
    local scaleY = height / H

    love.graphics.push()
    love.graphics.scale(scaleX, scaleY)

    local bloom = math.min(1, math.max(0, (timer - 2) / 5))
    local armor = timer > 7

    -- Sky
    love.graphics.setColor(0.38, 0.70, 0.79)
    love.graphics.rectangle("fill", 0, 0, W, H)

    love.graphics.setColor(1, 0.88, 0.50, 0.12)
    love.graphics.circle("fill", 100, 45, 65)

    -- Clouds
    drawCloud(15, 20, 8)
    drawCloud(150, 18, 7)
    drawCloud(75, 12, 5)

    -- Meadow
    drawMeadow(bloom)

    -- Starheart
    drawStarheart()

    -- Butterflies
    if timer > 4 then
        drawButterfly(30 + math.sin(timer * 1.4) * 5, 82, {1, 0.76, 0.40})
        drawButterfly(165 + math.sin(timer * 1.2) * 5, 78, {1, 0.72, 0.85})
        drawButterfly(65 + math.sin(timer) * 4, 95, {0.85, 0.82, 1})
    end

    -- Armor magic
    if timer > 5 and timer < 9 then
        local alpha = math.min(1, (timer - 5) / 2)

        love.graphics.setColor(1, 0.89, 0.40, alpha * 0.28)
        love.graphics.circle("fill", 100, 94, 18 + math.sin(timer * 8) * 3)

        love.graphics.setColor(1, 0.94, 0.59, alpha)
        star(100, 77, 7 + math.sin(timer * 5) * 2)
    end

    -- Pippo
    local pippoY = 112

    if timer > 5 and timer < 8 then
        pippoY = 112 - math.max(0, math.sin((timer - 5) / 3 * math.pi)) * 8
    end

    drawPippo(100, pippoY, armor)

    -- Sparkles
    for _, p in ipairs(particles) do
        local alpha = math.max(0, p.life / p.maxLife)

        love.graphics.setColor(1, 0.94, 0.60, alpha)
        love.graphics.circle("fill", p.x, p.y, p.size)
    end

    -- Keep the message panel aligned with the pixel-art scene.
    if timer > 10 then
        love.graphics.setColor(0.10, 0.31, 0.23, 0.90)
        love.graphics.rectangle("fill", 20, 57, 160, 47)

        love.graphics.setColor(1, 0.88, 0.40)
        love.graphics.rectangle("line", 21, 58, 158, 45)
    end

    love.graphics.pop()

    -- Draw all text AFTER the scene scale has been removed.
    -- This renders letters at the actual window resolution instead of
    -- rasterizing tiny 6px letters and enlarging them with the pixel scene.
    love.graphics.push()
    love.graphics.origin()

    -- Create these fonts once, not every frame.
    if not endingTitleFont then
        endingTitleFont = love.graphics.newFont(24)
        endingHeadingFont = love.graphics.newFont(22)
        endingBodyFont = love.graphics.newFont(18)
    end

    local function screenText(text, logicalX, logicalY, logicalWidth, font, color)
        love.graphics.setFont(font)
        love.graphics.setColor(color)
        love.graphics.printf(
            text,
            logicalX * scaleX,
            logicalY * scaleY,
            logicalWidth * scaleX,
            "center"
        )
    end

    -- Main title
    screenText(
        "STARHEART RESTORED",
        2, 5, 196,
        endingTitleFont,
        {1, 0.96, 0.68, 1}
    )

    -- Transformation message
    if timer > 5 and timer < 10 then
        screenText(
            "A new power awakens...",
            5, 65, 190,
            endingBodyFont,
            {1, 0.98, 0.75, 1}
        )
    end

    -- Final message
    if timer > 10 then
        screenText(
            "STAR GUARDIAN PIPPO",
            23, 63, 154,
            endingHeadingFont,
            {1, 0.96, 0.72, 1}
        )

        screenText(
            "The Starheart shines once more...",
            23, 74, 154,
            endingBodyFont,
            {1, 1, 1, 1}
        )

        screenText(
            "But a new adventure awaits!",
            23, 84, 154,
            endingBodyFont,
            {1, 0.88, 0.43, 1}
        )

        screenText(
            "TO BE CONTINUED...",
            0, 132, 200,
            endingBodyFont,
            {1, 0.96, 0.72, 1}
        )
    end

    love.graphics.pop()
end

function Ending.isFinished()
    return finished
end

return Ending
    