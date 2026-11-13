
-- ============================================
-- CHICKVENTURE: PIPPO'S ADVENTURE
-- STEP 28: PAUSE MENU
-- Step 27: Start Menu preserved
-- Step 26: Great Meadow Expansion preserved
-- ============================================
local Ending = require("ending")
local SCREEN_W, SCREEN_H = 200, 150
local WORLD_W = 800
local SCALE = 4

local chickX, chickY = 22, 105
local speed = 55
local cameraX = 0
local gameCanvas
local hudFont, hudSmallFont, subtitleFont, gameOverFont
local worldTimer = 0

-- MENU STATE
local gameState = "menu"
local menuTimer = 0

-- STEP 28: PAUSE STATE
local isPaused = false

local playButton = {
    x = 300,
    y = 390,
    w = 200,
    h = 65
}

local pauseButtons = {
    resume = {x=300,y=310,w=200,h=55},
    restart = {x=300,y=380,w=200,h=55},
    menu = {x=300,y=450,w=200,h=55}
}

-- AUDIO
local soundEffects = {}
local meadowMusic
local sfxVolume, musicVolume, musicMuted = 0.45, 0.22, false

local function playSound(name)
    local source = soundEffects[name]
    if source then
        local sound = source:clone()
        sound:setVolume(sfxVolume)
        sound:play()
    end
end

local function updateMusicVolume()
    if meadowMusic then
        meadowMusic:setVolume(musicMuted and 0 or musicVolume)
    end
end

-- PLAYER ANIMATION
local isWalking, animationTimer, walkFrame = false, 0, 0
local expressionTimer = 0
local blinkTimer, blinkDuration, nextBlink = 0, 0, 3
local idleTimer, lookTimer, lookOffset = 0, 0, 0

-- PHYSICS
local gravity, jumpPower = 220, -100
local velocityY, onGround, landingTimer = 0, true, 0

-- GAME STATE
local maxLives, lives = 3, 3
local gameOver, levelComplete = false, false
local invulnerableTimer, hitFlashTimer = 0, 0
local particles, score = {}, 0
local startPosition = {x = 22, y = 105}

-- CHECKPOINT
local checkpoint = {x = 400, y = 112, active = false}

-- PLATFORMS
local platforms = {
    {x=0,y=112,w=800,h=38,ground=true},
    {x=42,y=98,w=36,h=5},
    {x=100,y=84,w=36,h=5},
    {x=153,y=98,w=32,h=5},
    {x=225,y=98,w=40,h=5},
    {x=285,y=84,w=38,h=5},
    {x=345,y=98,w=38,h=5},
    {x=430,y=98,w=38,h=5},
    {x=490,y=84,w=40,h=5},
    {x=550,y=98,w=38,h=5},
    {x=620,y=98,w=38,h=5},
    {x=675,y=84,w=40,h=5},
    {x=735,y=98,w=35,h=5}
}

-- THORNS
local hazards = {
    {x=82,y=108,w=10,h=4},
    {x=127,y=80,w=7,h=4},
    {x=205,y=108,w=12,h=4},
    {x=315,y=108,w=12,h=4},
    {x=465,y=108,w=12,h=4},
    {x=525,y=80,w=8,h=4},
    {x=600,y=108,w=12,h=4},
    {x=710,y=108,w=12,h=4}
}

-- COLLECTIBLE STARS
local stars = {
    {x=60,y=88},
    {x=118,y=74},
    {x=169,y=88},
    {x=245,y=88},
    {x=304,y=74},
    {x=365,y=88},
    {x=450,y=88},
    {x=510,y=74},
    {x=570,y=88},
    {x=640,y=88},
    {x=695,y=74},
    {x=750,y=88}
}

for _, star in ipairs(stars) do
    star.collected = false
end

-- STAR GATE
local gate = {
    x=780,
    y=87,
    unlocked=false,
    animation=0
}

-- MOSSY
local mossy = {
    x=550,
    y=105,
    minX=535,
    maxX=585,
    speed=17,
    direction=1,
    animation=0
}

-- BUTTERFLIES
local butterflies = {
    {x=35,y=72,baseY=72,speed=13,phase=0,color={1,.35,.65}},
    {x=150,y=55,baseY=55,speed=17,phase=2,color={.45,.75,1}},
    {x=260,y=72,baseY=72,speed=11,phase=4,color={.75,.55,1}},
    {x=380,y=55,baseY=55,speed=14,phase=1,color={1,.55,.65}},
    {x=480,y=78,baseY=78,speed=12,phase=3,color={.45,.75,1}},
    {x=680,y=60,baseY=60,speed=15,phase=5,color={.75,.55,1}}
}

-- FLOATING LEAVES
local leaves = {
    {x=15,y=88,speed=9,phase=0,color={.45,.72,.30}},
    {x=95,y=105,speed=12,phase=2,color={.65,.78,.34}},
    {x=175,y=91,speed=8,phase=4,color={.38,.66,.32}},
    {x=260,y=80,speed=10,phase=1,color={.75,.78,.35}},
    {x=390,y=90,speed=9,phase=3,color={.45,.72,.30}},
    {x=520,y=85,speed=11,phase=5,color={.65,.78,.34}},
    {x=680,y=95,speed=8,phase=2,color={.38,.66,.32}}
}

-- FLOWERS
local flowers = {}

for x=15, WORLD_W-10, 35 do
    flowers[#flowers+1] = {
        x=x,
        y=110,
        phase=x*.1
    }
end

-- PARTICLES
local function spawnParticles(x,y,count,kind)
    for i=1,count do
        particles[#particles+1] = {
            kind=kind,
            x=x,
            y=y,
            vx=love.math.random(-45,45)/10,
            vy=love.math.random(-50,15)/10,
            life=love.math.random(35,75)/100,
            maxLife=.75,
            size=love.math.random(1,2)
        }
    end
end

local function spawnDust(x,y,n)
    spawnParticles(x,y,n,"dust")
end

local function spawnStarSparkles(x,y)
    spawnParticles(x,y,10,"sparkle")
end

local function spawnHitSparkles(x,y)
    spawnParticles(x,y,14,"hit")
end

local function spawnGateSparkles(x,y)
    spawnParticles(x,y,24,"gate")
end

local function overlaps(ax,ay,aw,ah,bx,by,bw,bh)
    return ax < bx+bw
        and ax+aw > bx
        and ay < by+bh
        and ay+ah > by
end

-- BACKGROUND
local function drawCloud(x,y)
    love.graphics.setColor(1,1,1)
    love.graphics.rectangle("fill",x+4,y+4,20,8)
    love.graphics.rectangle("fill",x+8,y,12,16)
    love.graphics.rectangle("fill",x,y+8,28,8)
end

local function drawTree(x,y)
    love.graphics.setColor(.35,.2,.12)
    love.graphics.rectangle("fill",x+9,y+16,5,17)

    love.graphics.setColor(.12,.38,.18)
    love.graphics.rectangle("fill",x+4,y+7,16,12)
    love.graphics.rectangle("fill",x+8,y,12,20)
    love.graphics.rectangle("fill",x,y+11,24,10)

    love.graphics.setColor(.25,.55,.25)
    love.graphics.rectangle("fill",x+9,y+3,5,5)
end

local function drawFlower(x,y,sway)
    local fx=x+math.floor(sway)

    love.graphics.setColor(.12,.38,.16)
    love.graphics.rectangle("fill",x,y+3,1,6)

    love.graphics.setColor(1,.55,.7)
    love.graphics.rectangle("fill",fx-2,y,2,2)
    love.graphics.rectangle("fill",fx+2,y,2,2)
    love.graphics.rectangle("fill",fx,y-2,2,2)
    love.graphics.rectangle("fill",fx,y+2,2,2)

    love.graphics.setColor(1,.9,.25)
    love.graphics.rectangle("fill",fx,y,2,2)
end

local function drawBackground()
    love.graphics.setColor(.45,.75,.92)
    love.graphics.rectangle("fill",0,0,WORLD_W,SCREEN_H)

    love.graphics.setColor(1,.88,.42)
    love.graphics.rectangle("fill",169,13,15,15)

    for x=28,WORLD_W,175 do
        drawCloud(x,30+math.sin(x)*3)
    end

    for x=116,WORLD_W,210 do
        drawCloud(x,43)
    end

    for x=-20,WORLD_W,100 do
        love.graphics.setColor(.48,.72,.48)
        love.graphics.polygon(
            "fill",
            x,100,
            x+30,65,
            x+65,100,
            x+100,120,
            x,120
        )
    end

    for x=15,WORLD_W,145 do
        drawTree(x,76)
    end

    love.graphics.setColor(.28,.62,.30)
    love.graphics.rectangle("fill",0,112,WORLD_W,38)

    for x=3,WORLD_W,7 do
        local sway=math.floor(
            math.sin(worldTimer*2+x*.17)*1.5
        )

        love.graphics.setColor(.38,.72,.34)
        love.graphics.rectangle("fill",x+sway,113,1,3)

        love.graphics.setColor(.25,.57,.28)
        love.graphics.rectangle("fill",x+sway-1,116,1,2)
    end

    love.graphics.setColor(.68,.53,.35)
    love.graphics.rectangle("fill",0,136,WORLD_W,14)

    for _,f in ipairs(flowers) do
        drawFlower(
            f.x,
            f.y,
            math.sin(worldTimer*2.5+f.phase)*1.5
        )
    end
end

local function drawLeaves()
    for _,l in ipairs(leaves) do
        local x=math.floor(l.x+math.sin(worldTimer*2+l.phase)*2)
        local y=math.floor(l.y)

        love.graphics.setColor(l.color)
        love.graphics.rectangle("fill",x,y,3,2)
        love.graphics.rectangle("fill",x+1,y-1,2,2)

        love.graphics.setColor(.25,.48,.20)
        love.graphics.rectangle("fill",x+1,y+1,2,1)
    end
end

local function drawButterfly(b)
    local wingHeight =
        math.sin(worldTimer*13+b.phase)>0 and 3 or 2

    love.graphics.setColor(b.color)

    love.graphics.rectangle(
        "fill",
        math.floor(b.x-3),
        math.floor(b.y),
        3,
        wingHeight
    )

    love.graphics.rectangle(
        "fill",
        math.floor(b.x+1),
        math.floor(b.y),
        3,
        wingHeight
    )

    love.graphics.setColor(.22,.18,.20)
    love.graphics.rectangle(
        "fill",
        math.floor(b.x),
        math.floor(b.y),
        2,
        4
    )
end

-- PLATFORMS
local function drawPlatforms()
    for _,p in ipairs(platforms) do
        if p.ground then
            love.graphics.setColor(.28,.62,.30)
        else
            love.graphics.setColor(.48,.32,.20)
        end

        love.graphics.rectangle("fill",p.x,p.y,p.w,p.h)

        if not p.ground then
            love.graphics.setColor(.40,.70,.34)
            love.graphics.rectangle("fill",p.x,p.y,p.w,2)

            love.graphics.setColor(.65,.48,.29)
            love.graphics.rectangle("fill",p.x+4,p.y+3,4,1)
            love.graphics.rectangle("fill",p.x+19,p.y+3,5,1)
        end
    end
end

-- THORNS
local function drawHazards()
    for _,h in ipairs(hazards) do
        love.graphics.setColor(.16,.30,.18,.25)
        love.graphics.rectangle("fill",h.x,h.y+3,h.w,2)

        love.graphics.setColor(.16,.43,.20)

        for x=h.x,h.x+h.w-3,3 do
            love.graphics.polygon(
                "fill",
                x,h.y+3,
                x+2,h.y,
                x+3,h.y+3
            )
        end

        love.graphics.setColor(.95,.72,.35)

        for x=h.x+1,h.x+h.w-2,3 do
            love.graphics.rectangle("fill",x+1,h.y,1,1)
        end
    end
end

-- CHECKPOINT
local function drawCheckpoint()
    love.graphics.setColor(.35,.23,.15)
    love.graphics.rectangle("fill",checkpoint.x,91,2,21)

    love.graphics.setColor(.75,.58,.32)
    love.graphics.rectangle("fill",checkpoint.x-1,90,4,2)

    if checkpoint.active then
        love.graphics.setColor(1,.82,.25)
    else
        love.graphics.setColor(.35,.75,.42)
    end

    love.graphics.polygon(
        "fill",
        checkpoint.x+2,92,
        checkpoint.x+13,95,
        checkpoint.x+2,100
    )

    love.graphics.setColor(.55,.38,.23)
    love.graphics.rectangle("fill",checkpoint.x-3,110,8,2)

    if checkpoint.active then
        love.graphics.setColor(1,.9,.35)
        love.graphics.rectangle(
            "fill",
            checkpoint.x+12,
            90+math.sin(worldTimer*5)*1.5,
            2,2
        )
    end
end

-- STAR GATE
local function drawGate()
    local pulse=math.sin(gate.animation*4)*.08

    love.graphics.setColor(.12,.25,.16,.25)
    love.graphics.ellipse("fill",gate.x,112,12,3)

    if gate.unlocked then
        love.graphics.setColor(.55,.30,.78)
        love.graphics.rectangle("fill",gate.x-8,88,16,24)

        love.graphics.setColor(1,.72+pulse,.25)
        love.graphics.rectangle("fill",gate.x-6,90,12,21)

        love.graphics.setColor(1,.94,.63)
        love.graphics.rectangle("fill",gate.x-4,93,8,15)

        love.graphics.setColor(1,.82,.30,.22)
        love.graphics.rectangle("fill",gate.x-11,86,22,28)

        for i=1,3 do
            local a=worldTimer*2+i*2.1

            love.graphics.setColor(1,.92,.45)
            love.graphics.rectangle(
                "fill",
                math.floor(gate.x+math.cos(a)*12),
                math.floor(99+math.sin(a)*12),
                2,2
            )
        end

        love.graphics.setColor(1,1,.85)
        love.graphics.rectangle("fill",gate.x-2,96,4,9)
    else
        love.graphics.setColor(.42,.28,.58)
        love.graphics.rectangle("fill",gate.x-8,88,16,24)

        love.graphics.setColor(.67,.48,.77)
        love.graphics.rectangle("fill",gate.x-6,90,12,20)

        love.graphics.setColor(.35,.24,.48)
        love.graphics.rectangle("fill",gate.x-4,94,8,16)

        love.graphics.setColor(1,.83,.35)
        love.graphics.rectangle("fill",gate.x-3,99,6,6)
        love.graphics.rectangle("fill",gate.x-2,96,4,4)

        love.graphics.setColor(.42,.28,.58)
        love.graphics.rectangle("fill",gate.x-1,98,2,3)
    end
end

-- MOSSY
local function drawMossy()
    local bob=math.floor(math.sin(mossy.animation*8))
    local x=math.floor(mossy.x-6)
    local y=math.floor(mossy.y-6+bob)

    love.graphics.setColor(.12,.28,.16,.25)
    love.graphics.ellipse("fill",mossy.x,112,5,1.5)

    love.graphics.setColor(.24,.62,.35)
    love.graphics.rectangle("fill",x+2,y+3,8,4)
    love.graphics.rectangle("fill",x+1,y+5,10,2)
    love.graphics.rectangle("fill",x+3,y+1,6,2)

    love.graphics.setColor(.43,.78,.45)
    love.graphics.rectangle("fill",x+3,y+2,5,2)
    love.graphics.rectangle("fill",x+5,y+1,2,1)

    love.graphics.setColor(.10,.16,.10)

    if mossy.direction==1 then
        love.graphics.rectangle("fill",x+7,y+4,1,2)
        love.graphics.rectangle("fill",x+10,y+4,1,2)
    else
        love.graphics.rectangle("fill",x+1,y+4,1,2)
        love.graphics.rectangle("fill",x+4,y+4,1,2)
    end

    love.graphics.setColor(.95,.55,.53)
    love.graphics.rectangle("fill",x+2,y+6,2,1)
    love.graphics.rectangle("fill",x+8,y+6,2,1)
end

-- PIPPO
local function drawPippo(x,y,walking,frame,expression,blinking,looking)
    local sprite={
        "......YYYY......",
        "....YYYYYYYY....",
        "...YYYYYYYYYY...",
        "..YYYYYYYYYYYY..",
        ".YYYYYYYYYYYYYY.",
        ".YYYYYYYYYYYYYY.",
        ".YYYYYYYYYYYYYY.",
        ".YYYYYYOOYYYYYY.",
        ".YYYYYYYYYYYYYY.",
        "..YYYYYYYYYYYY..",
        "...YYYYYYYYYY...",
        "....YYYYYYYY....",
        ".....YYYYYY....."
    }

    local colors={
        Y={1,.86,.25},
        O={1,.42,.12}
    }

    for row=1,#sprite do
        for col=1,#sprite[row] do
            local c=colors[sprite[row]:sub(col,col)]

            if c then
                love.graphics.setColor(c)
                love.graphics.rectangle(
                    "fill",
                    x+col-1,
                    y+row-1,
                    1,1
                )
            end
        end
    end

    love.graphics.setColor(.12,.10,.08)
    local shift=looking or 0

    if expression=="happy" then
        love.graphics.rectangle("fill",x+3,y+6,1,1)
        love.graphics.rectangle("fill",x+4,y+7,2,1)
        love.graphics.rectangle("fill",x+6,y+6,1,1)

        love.graphics.rectangle("fill",x+10,y+6,1,1)
        love.graphics.rectangle("fill",x+11,y+7,2,1)
        love.graphics.rectangle("fill",x+13,y+6,1,1)
    elseif blinking then
        love.graphics.rectangle("fill",x+4,y+6,3,1)
        love.graphics.rectangle("fill",x+11,y+6,3,1)
    else
        love.graphics.rectangle("fill",x+4+shift,y+5,1,2)
        love.graphics.rectangle("fill",x+11+shift,y+5,1,2)
    end

    love.graphics.setColor(1,.42,.12)

    if not onGround then
        love.graphics.rectangle("fill",x+4,y+12,3,1)
        love.graphics.rectangle("fill",x+10,y+12,3,1)
    elseif not walking then
        love.graphics.rectangle("fill",x+5,y+13,2,1)
        love.graphics.rectangle("fill",x+10,y+13,2,1)
        love.graphics.rectangle("fill",x+4,y+14,2,1)
        love.graphics.rectangle("fill",x+10,y+14,2,1)
    elseif frame==0 then
        love.graphics.rectangle("fill",x+3,y+13,3,1)
        love.graphics.rectangle("fill",x+11,y+13,3,1)
        love.graphics.rectangle("fill",x+4,y+14,2,1)
        love.graphics.rectangle("fill",x+11,y+14,2,1)
    else
        love.graphics.rectangle("fill",x+6,y+13,3,1)
        love.graphics.rectangle("fill",x+9,y+13,3,1)
        love.graphics.rectangle("fill",x+6,y+14,2,1)
        love.graphics.rectangle("fill",x+9,y+14,2,1)
    end
end

-- STARS
local function drawStar(x,y)
    love.graphics.setColor(1,.75,.1)
    love.graphics.rectangle("fill",x-1,y-4,3,9)
    love.graphics.rectangle("fill",x-4,y-1,9,3)

    love.graphics.setColor(1,.95,.45)
    love.graphics.rectangle("fill",x,y-2,1,5)
    love.graphics.rectangle("fill",x-2,y,5,1)
end

-- HEARTS
local function drawHeart(x,y,filled)
    if filled then
        love.graphics.setColor(1,.30,.42)
    else
        love.graphics.setColor(.42,.40,.43)
    end

    love.graphics.rectangle("fill",x+2,y,4,2)
    love.graphics.rectangle("fill",x+10,y,4,2)
    love.graphics.rectangle("fill",x,y+2,16,5)
    love.graphics.rectangle("fill",x+2,y+7,12,2)
    love.graphics.rectangle("fill",x+4,y+9,8,2)
    love.graphics.rectangle("fill",x+6,y+11,4,2)

    if filled then
        love.graphics.setColor(1,.72,.76)
        love.graphics.rectangle("fill",x+3,y+2,3,2)
    end
end

local function drawParticles()
    for _,p in ipairs(particles) do
        local fade=math.max(0,p.life/p.maxLife)

        if p.kind=="dust" then
            love.graphics.setColor(.78,.69,.52,fade*.8)
        elseif p.kind=="hit" then
            love.graphics.setColor(1,.55,.35,fade)
        elseif p.kind=="gate" then
            love.graphics.setColor(.95,.85,.35,fade)
        else
            love.graphics.setColor(1,.82,.22,fade)
        end

        love.graphics.rectangle(
            "fill",
            math.floor(p.x),
            math.floor(p.y),
            p.size+1,
            p.size
        )
    end
end

-- CHECKPOINT ACTIVATION
local function activateCheckpoint()
    if checkpoint.active then return end

    checkpoint.active=true
    spawnStarSparkles(checkpoint.x+5,95)
    expressionTimer=1.2
    playSound("checkpoint")
end

-- RESPAWN
local function respawn()
    if checkpoint.active then
        chickX=checkpoint.x-4
        chickY=checkpoint.y-7
    else
        chickX=startPosition.x
        chickY=startPosition.y
    end

    velocityY=0
    onGround=true

    cameraX=math.max(
        0,
        math.min(WORLD_W-SCREEN_W,chickX-SCREEN_W/2)
    )
end

-- PLAYER HIT
local function hitHazard()
    if invulnerableTimer>0 or gameOver or levelComplete then
        return
    end

    lives=lives-1
    spawnHitSparkles(chickX,chickY+3)
    playSound("hit")

    respawn()

    landingTimer=0
    hitFlashTimer=.5

    if lives<=0 then
        lives=0
        gameOver=true
        invulnerableTimer=0
    else
        invulnerableTimer=1.4
        spawnDust(chickX,chickY+7,8)
    end
end

-- RESTART
local function restartGame()
    chickX,chickY=startPosition.x,startPosition.y
    cameraX=0
    velocityY,onGround=0,true

    lives,score=maxLives,0
    gameOver,levelComplete=false,false

    invulnerableTimer,hitFlashTimer,landingTimer=0,0,0
    expressionTimer=0

    blinkTimer,blinkDuration,nextBlink=0,0,3
    idleTimer,lookTimer,lookOffset=0,0,0
    animationTimer,walkFrame=0,0

    particles={}

    for _,s in ipairs(stars) do
        s.collected=false
    end

    checkpoint.active=false

    mossy.x=550
    mossy.direction=1
    mossy.animation=0

    local butterflyStarts={35,150,260,380,480,680}

    for i,b in ipairs(butterflies) do
        b.x=butterflyStarts[i]
    end

    local leafStarts={15,95,175,260,390,520,680}

    for i,l in ipairs(leaves) do
        l.x=leafStarts[i]
    end

    gate.unlocked=false
    gate.animation=0
end

-- =====================================
-- STEP 27: START MENU DRAWING
-- =====================================

local function drawStartMenu()
    love.graphics.setColor(.55,.82,.94)
    love.graphics.rectangle("fill",0,0,800,600)

    -- Sun
    love.graphics.setColor(1,.88,.43)
    love.graphics.circle("fill",680,110,48)

    -- Clouds
    love.graphics.setColor(1,1,1)
    love.graphics.circle("fill",130,115,25)
    love.graphics.circle("fill",160,105,32)
    love.graphics.circle("fill",195,118,23)

    love.graphics.circle("fill",480,165,20)
    love.graphics.circle("fill",510,155,27)
    love.graphics.circle("fill",540,166,20)

    -- Hills
    love.graphics.setColor(.49,.73,.48)
    love.graphics.ellipse("fill",150,420,280,150)
    love.graphics.ellipse("fill",650,420,330,170)

    -- Meadow
    love.graphics.setColor(.34,.67,.34)
    love.graphics.rectangle("fill",0,440,800,160)

    -- Grass
    love.graphics.setColor(.25,.55,.28)

    for x=10,800,25 do
        love.graphics.rectangle("fill",x,445,3,12)
    end

    -- Flowers
    for x=35,780,65 do
        local y=475+math.sin(menuTimer*2+x)*3

        love.graphics.setColor(.15,.43,.19)
        love.graphics.rectangle("fill",x,y,3,18)

        love.graphics.setColor(1,.65,.78)
        love.graphics.circle("fill",x,y,7)

        love.graphics.setColor(1,.88,.35)
        love.graphics.circle("fill",x,y,3)
    end

    -- Pippo shadow
    local bob=math.sin(menuTimer*3)*5

    love.graphics.setColor(.16,.35,.18,.25)
    love.graphics.ellipse("fill",400,430,48,10)

    -- Pippo
    love.graphics.setColor(1,.86,.25)
    love.graphics.ellipse("fill",400,385+bob,39,43)

    -- Wings
    love.graphics.setColor(1,.76,.19)
    love.graphics.ellipse("fill",365,390+bob,12,20)
    love.graphics.ellipse("fill",435,390+bob,12,20)

    -- Eyes
    love.graphics.setColor(.12,.10,.08)
    love.graphics.circle("fill",386,378+bob,4)
    love.graphics.circle("fill",414,378+bob,4)

    -- Beak
    love.graphics.setColor(1,.42,.12)
    love.graphics.polygon(
        "fill",
        395,390+bob,
        405,390+bob,
        400,397+bob
    )

    -- Title
    love.graphics.setFont(gameOverFont)
    love.graphics.setColor(.10,.25,.23)
    love.graphics.printf("CHICKVENTURE",0,65,800,"center")

    love.graphics.setFont(subtitleFont)
    love.graphics.setColor(1,1,.90)
    love.graphics.printf(
        "PIPPO'S ADVENTURE",
        0,112,800,"center"
    )

    -- Play button hover detection
    local mx,my=love.mouse.getPosition()

    local hovering =
        mx>=playButton.x and mx<=playButton.x+playButton.w
        and my>=playButton.y and my<=playButton.y+playButton.h

    if hovering then
        love.graphics.setColor(.95,.75,.32)
    else
        love.graphics.setColor(.91,.65,.25)
    end

    love.graphics.rectangle(
        "fill",
        playButton.x,
        playButton.y,
        playButton.w,
        playButton.h,
        15,15
    )

    love.graphics.setColor(1,.92,.65)
    love.graphics.setLineWidth(4)

    love.graphics.rectangle(
        "line",
        playButton.x,
        playButton.y,
        playButton.w,
        playButton.h,
        15,15
    )

    love.graphics.setFont(hudFont)
    love.graphics.setColor(1,1,1)

    love.graphics.printf(
        "PLAY",
        playButton.x,
        playButton.y+17,
        playButton.w,
        "center"
    )

    love.graphics.setFont(hudSmallFont)
    love.graphics.setColor(.12,.27,.22)

    love.graphics.printf(
        "A little adventure is waiting...",
        0,555,800,"center"
    )
end

-- STORY SCREEN
local function drawStoryScreen()
    love.graphics.setColor(.08,.16,.20,.94)
    love.graphics.rectangle("fill",70,120,660,360,18,18)

    love.graphics.setColor(1,.85,.35)
    love.graphics.setFont(gameOverFont)

    love.graphics.printf(
        "THE STARHEART",
        90,160,620,"center"
    )

    love.graphics.setFont(subtitleFont)
    love.graphics.setColor(1,.95,.82)

    love.graphics.printf(
        "Once upon a time, a magical light",
        110,245,580,"center"
    )

    love.graphics.printf(
        "kept the meadow bright and beautiful.",
        110,275,580,"center"
    )

    love.graphics.printf(
        "But one night, the Starheart shattered...",
        110,320,580,"center"
    )

    love.graphics.setColor(1,.82,.35)

    love.graphics.printf(
        "Pippo must find the scattered stars!",
        110,365,580,"center"
    )

    love.graphics.setColor(1,1,1)
    love.graphics.setFont(hudFont)

    love.graphics.printf(
        "PRESS ENTER TO BEGIN",
        110,420,580,"center"
    )
end

-- =====================================
-- STEP 28: PAUSE MENU DRAWING
-- =====================================

local function drawPauseButton(button,label)
    local mx,my=love.mouse.getPosition()

    local hovering =
        mx>=button.x and mx<=button.x+button.w
        and my>=button.y and my<=button.y+button.h

    if hovering then
        love.graphics.setColor(.95,.77,.39)
    else
        love.graphics.setColor(.83,.66,.36)
    end

    love.graphics.rectangle(
        "fill",
        button.x,
        button.y,
        button.w,
        button.h,
        12,12
    )

    love.graphics.setColor(1,.91,.65)
    love.graphics.setLineWidth(3)

    love.graphics.rectangle(
        "line",
        button.x,
        button.y,
        button.w,
        button.h,
        12,12
    )

    love.graphics.setFont(hudFont)
    love.graphics.setColor(.12,.22,.20)

    love.graphics.printf(
        label,
        button.x,
        button.y+15,
        button.w,
        "center"
    )
end

local function drawPauseMenu()
    -- Darken the frozen game
    love.graphics.setColor(.04,.10,.13,.72)
    love.graphics.rectangle("fill",0,0,800,600)

    -- Pause panel
    love.graphics.setColor(.10,.23,.25,.98)
    love.graphics.rectangle("fill",220,145,360,390,20,20)

    love.graphics.setColor(.47,.73,.66)
    love.graphics.setLineWidth(4)
    love.graphics.rectangle("line",220,145,360,390,20,20)

    -- Little decorative stars
    love.graphics.setColor(1,.83,.35)
    love.graphics.circle("fill",270,190,5)
    love.graphics.circle("fill",530,190,5)
    love.graphics.circle("fill",285,255,3)
    love.graphics.circle("fill",515,255,3)

    -- Title
    love.graphics.setFont(gameOverFont)
    love.graphics.setColor(1,.88,.48)

    love.graphics.printf(
        "PAUSED",
        240,180,320,"center"
    )

    love.graphics.setFont(subtitleFont)
    love.graphics.setColor(1,.94,.82)

    love.graphics.printf(
        "Take a little break, Pippo!",
        240,245,320,"center"
    )

    -- Buttons
    drawPauseButton(pauseButtons.resume,"RESUME")
    drawPauseButton(pauseButtons.restart,"RESTART")
    drawPauseButton(pauseButtons.menu,"MAIN MENU")

    love.graphics.setFont(hudSmallFont)
    love.graphics.setColor(.82,.90,.82)

    love.graphics.printf(
        "Press ESC or P to resume",
        240,515,320,"center"
    )
end

-- LOAD
function love.load()
    love.window.setTitle("Chickventure - Pippo's Adventure")
    love.window.setMode(800,600,{resizable=false})

    gameCanvas=love.graphics.newCanvas(SCREEN_W,SCREEN_H)
    gameCanvas:setFilter("nearest","nearest")

    -- HUD FONTS
    hudFont=love.graphics.newFont(18)
    hudSmallFont=love.graphics.newFont(13)
    subtitleFont=love.graphics.newFont(16)
    gameOverFont=love.graphics.newFont(32)

    nextBlink=love.math.random(2,4)

    soundEffects.jump=love.audio.newSource(
        "assets/sounds/jump.wav","static"
    )

    soundEffects.star=love.audio.newSource(
        "assets/sounds/star.wav","static"
    )

    soundEffects.hit=love.audio.newSource(
        "assets/sounds/hit.wav","static"
    )

    soundEffects.checkpoint=love.audio.newSource(
        "assets/sounds/checkpoint.wav","static"
    )

    soundEffects.gate=love.audio.newSource(
        "assets/sounds/gate.wav","static"
    )

    soundEffects.victory=love.audio.newSource(
        "assets/sounds/victory.wav","static"
    )

    meadowMusic=love.audio.newSource(
        "assets/music/meadow.wav","stream"
    )

    meadowMusic:setLooping(true)
    updateMusicVolume()
    meadowMusic:play()
end

-- KEY PRESSED
function love.keypressed(key)
        -- STEP 30: ENDING CONTROLS
    if gameState == "ending" then
        if key == "return" or key == "space" then
            restartGame()
            gameState = "playing"
            isPaused = false
        elseif key == "escape" then
            gameState = "menu"
            menuTimer = 0
        end
        return
    end

    -- START MENU
    if gameState=="menu" then
        if key=="return" or key=="space" then
            gameState="story"
        end
        return
    end

    -- STORY SCREEN
    if gameState=="story" then
        if key=="return" or key=="space" then
            gameState="playing"
        end
        return
    end

    -- STEP 28: PAUSE / RESUME
    if gameState=="playing"
        and not gameOver
        and not levelComplete
        and (key=="escape" or key=="p") then

        isPaused=not isPaused
        return
    end

    -- Ignore other controls while paused
    if isPaused then
        return
    end

    if key=="m" then
        musicMuted=not musicMuted
        updateMusicVolume()
        return
    end

    if key=="+" or key=="=" or key=="kp+" then
        musicVolume=math.min(1,musicVolume+.05)
        updateMusicVolume()
        return
    end

    if key=="-" or key=="kp-" then
        musicVolume=math.max(0,musicVolume-.05)
        updateMusicVolume()
        return
    end

    if gameOver or levelComplete then
        if key=="r" or key=="return" then
            restartGame()
        end
        return
    end

    if (key=="space" or key=="w" or key=="up") and onGround then
        playSound("jump")
        onGround=false
        velocityY=jumpPower
        spawnDust(chickX,chickY+7,7)
    end
end


-- =====================================
-- STEP 30: SMALLER UPDATE FUNCTIONS
-- =====================================

-- UPDATE TIMERS
local function updateTimers(dt)
    worldTimer = worldTimer + dt
    gate.animation = gate.animation + dt

    invulnerableTimer = math.max(0, invulnerableTimer - dt)
    hitFlashTimer = math.max(0, hitFlashTimer - dt)
end


-- PIPPO MOVEMENT AND PHYSICS
local function updateMovement(dt)

    isWalking = false

    if love.keyboard.isDown("right", "d") then
        chickX = chickX + speed * dt
        isWalking = true
    end

    if love.keyboard.isDown("left", "a") then
        chickX = chickX - speed * dt
        isWalking = true
    end

    chickX = math.max(9, math.min(WORLD_W - 9, chickX))

    -- WALKING ANIMATION
    if isWalking and onGround then
        animationTimer = animationTimer + dt

        if animationTimer >= .16 then
            animationTimer = animationTimer - .16
            walkFrame = 1 - walkFrame
        end
    else
        animationTimer = 0
        walkFrame = 0
    end

    -- IDLE LOOK
    if not isWalking and onGround then
        idleTimer = idleTimer + dt

        if lookTimer > 0 then
            lookTimer = lookTimer - dt

            if lookTimer <= 0 then
                lookOffset = 0
                idleTimer = 0
            end
        elseif idleTimer >= 3.5 then
            lookOffset = love.math.random(0, 1)
            lookTimer = .65
        end
    else
        idleTimer = 0
        lookTimer = 0
        lookOffset = 0
    end

    -- GRAVITY AND PLATFORM COLLISION
    local previousBottom = chickY + 7

    velocityY = velocityY + gravity * dt
    chickY = chickY + velocityY * dt

    local currentBottom = chickY + 7
    onGround = false

    if velocityY >= 0 then
        for _, p in ipairs(platforms) do
            local horizontal =
                chickX + 6 > p.x and chickX - 6 < p.x + p.w

            if horizontal
                and previousBottom <= p.y
                and currentBottom >= p.y then

                chickY = p.y - 7
                velocityY = 0
                onGround = true
                landingTimer = .12
                break
            end
        end
    end

    -- FALL RECOVERY
    if chickY > 155 then
        respawn()
    end

    -- CAMERA FOLLOW
    local targetCameraX = math.max(
        0,
        math.min(WORLD_W - SCREEN_W, chickX - SCREEN_W / 2)
    )

    cameraX = cameraX + (targetCameraX - cameraX) * math.min(1, dt * 6)
end


-- ENEMIES, HAZARDS AND ENVIRONMENT
local function updateWorld(dt)

    -- MOSSY MOVEMENT
    mossy.animation = mossy.animation + dt
    mossy.x = mossy.x + mossy.speed * mossy.direction * dt

    if mossy.x >= mossy.maxX then
        mossy.x = mossy.maxX
        mossy.direction = -1
    elseif mossy.x <= mossy.minX then
        mossy.x = mossy.minX
        mossy.direction = 1
    end

    -- CHECKPOINT
    if not checkpoint.active then
        if overlaps(
            chickX - 6, chickY - 7, 12, 14,
            checkpoint.x - 2, 91, 16, 21
        ) then
            activateCheckpoint()
        end
    end

    -- THORN COLLISION
    if invulnerableTimer <= 0 then
        for _, h in ipairs(hazards) do
            if overlaps(
                chickX - 6, chickY - 7, 12, 14,
                h.x, h.y, h.w, h.h
            ) then
                hitHazard()
                break
            end
        end
    end

    -- MOSSY COLLISION
    if invulnerableTimer <= 0 and not gameOver then
        if overlaps(
            chickX - 6, chickY - 7, 12, 14,
            mossy.x - 5, mossy.y - 6, 10, 7
        ) then
            hitHazard()
        end
    end

    -- BUTTERFLIES
    for _, b in ipairs(butterflies) do
        b.x = b.x + b.speed * dt
        b.y = b.baseY + math.sin(worldTimer * 2 + b.phase) * 3

        if b.x > WORLD_W + 10 then
            b.x = -10
        end
    end

    -- LEAVES
    for _, l in ipairs(leaves) do
        l.x = l.x + l.speed * dt
        l.y = l.y + math.sin(worldTimer * 2 + l.phase) * dt * 2

        if l.x > WORLD_W + 5 then
            l.x = -5
            l.y = love.math.random(75, 108)
        end
    end

    -- PARTICLES
    for i = #particles, 1, -1 do
        local p = particles[i]
        p.life = p.life - dt

        if p.life <= 0 then
            table.remove(particles, i)
        else
            p.x = p.x + p.vx * dt
            p.y = p.y + p.vy * dt
            p.vy = p.vy + 18 * dt
        end
    end
end


-- PIPPO EXPRESSIONS, STARS AND STAR GATE
local function updateEffectsAndStars(dt)

    -- LANDING BOUNCE
    if landingTimer > 0 then
        landingTimer = math.max(0, landingTimer - dt)
    end

    -- HAPPY EXPRESSION
    if expressionTimer > 0 then
        expressionTimer = math.max(0, expressionTimer - dt)
    end

    -- BLINKING
    if blinkDuration > 0 then
        blinkDuration = math.max(0, blinkDuration - dt)
    else
        blinkTimer = blinkTimer + dt

        if blinkTimer >= nextBlink then
            blinkDuration = .13
            blinkTimer = 0
            nextBlink = love.math.random(2, 4)
        end
    end

    -- COLLECT STARS
    for _, s in ipairs(stars) do
        if not s.collected then
            local dx = chickX - s.x
            local dy = chickY - s.y

            if math.sqrt(dx * dx + dy * dy) < 10 then
                s.collected = true
                score = score + 1
                expressionTimer = 1.2
                spawnStarSparkles(s.x, s.y)
                playSound("star")
            end
        end
    end

    -- UNLOCK GATE
    if score == #stars and not gate.unlocked then
        gate.unlocked = true
        spawnGateSparkles(gate.x, 100)
        playSound("gate")
    end

    -- GATE COLLISION
    if gate.unlocked then
        if overlaps(
            chickX - 6, chickY - 7, 12, 14,
            gate.x - 7, gate.y, 14, 25
        ) then

            gameState = "ending"
            levelComplete = false

            Ending.start()
            spawnGateSparkles(gate.x, 100)
            playSound("victory")

            return true
        end
    end

    return false
end

-- UPDATE
function love.update(dt)

    -- STEP 30: UPDATE ENDING
    if gameState == "ending" then
        Ending.update(dt)
        return
    end

    -- MENU AND STORY TIMER
    if gameState ~= "playing" then
        menuTimer = menuTimer + dt
        return
    end

    -- FREEZE EVERYTHING WHILE PAUSED
    if isPaused or gameOver or levelComplete then
        return
    end

    -- UPDATE GAME SYSTEMS
    updateTimers(dt)
    updateMovement(dt)
    updateWorld(dt)

    -- CHECK IF PIPPO ENTERED THE STAR GATE
    if updateEffectsAndStars(dt) then
        return
    end
end
-- =====================================
-- DRAW
-- =====================================

function love.draw()

        -- STEP 30: DRAW ENDING
    if gameState == "ending" then
        Ending.draw()
        return
    end

    -- START MENU
    if gameState=="menu" then
        drawStartMenu()
        return
    end

    -- STORY SCREEN
    if gameState=="story" then
        drawStartMenu()

        love.graphics.setColor(.08,.16,.20,.94)
        love.graphics.rectangle("fill",70,120,660,360,18,18)

        love.graphics.setColor(1,.85,.35)
        love.graphics.setFont(gameOverFont)
        love.graphics.printf(
            "THE STARHEART",
            90,160,620,"center"
        )

        love.graphics.setFont(subtitleFont)
        love.graphics.setColor(1,.95,.82)

        love.graphics.printf(
            "Once upon a time, a magical light",
            110,245,580,"center"
        )

        love.graphics.printf(
            "kept the meadow bright and beautiful.",
            110,275,580,"center"
        )

        love.graphics.printf(
            "But one night, the Starheart shattered...",
            110,320,580,"center"
        )

        love.graphics.setColor(1,.82,.35)
        love.graphics.printf(
            "Pippo must find the scattered stars!",
            110,365,580,"center"
        )

        love.graphics.setColor(1,1,1)
        love.graphics.setFont(hudFont)
        love.graphics.printf(
            "PRESS ENTER TO BEGIN",
            110,420,580,"center"
        )

        return
    end

    love.graphics.setCanvas(gameCanvas)
    love.graphics.clear(.45,.75,.92)

    -- WORLD CAMERA
    love.graphics.push()
    love.graphics.translate(-math.floor(cameraX),0)

    drawBackground()
    drawLeaves()

    for _,b in ipairs(butterflies) do
        drawButterfly(b)
    end

    drawPlatforms()
    drawHazards()
    drawCheckpoint()

    -- STARS
    for _,s in ipairs(stars) do
        if not s.collected then
            drawStar(
                s.x,
                s.y+math.sin(worldTimer*3+s.x)
            )
        end
    end

    drawGate()
    drawMossy()

    -- PIPPO SHADOW
    local jumpHeight=math.max(0,112-(chickY+7))
    local shadowWidth=math.max(4,10-jumpHeight*.07)
    local shadowAlpha=math.max(.10,.32-jumpHeight*.008)

    love.graphics.setColor(.16,.30,.18,shadowAlpha)
    love.graphics.ellipse(
        "fill",
        chickX,
        112,
        shadowWidth,
        2
    )

    drawParticles()

    -- PIPPO BOUNCE
    local bounce=0

    if isWalking and walkFrame==1 and onGround then
        bounce=-1
    end

    if landingTimer>0 then
        bounce=bounce+1
    end

    local expression="normal"

    if expressionTimer>0 or score==#stars then
        expression="happy"
    end

    local showPippo=true

    if invulnerableTimer>0 then
        showPippo=math.floor(worldTimer*12)%2==0
    end

    if showPippo and not gameOver and not levelComplete then
        drawPippo(
            math.floor(chickX-8),
            math.floor(chickY-8+bounce),
            isWalking,
            walkFrame,
            expression,
            blinkDuration>0,
            lookOffset
        )
    end

    love.graphics.pop()
    love.graphics.setCanvas()

    -- DRAW PIXEL WORLD AT 4X
    love.graphics.setColor(1,1,1)
    love.graphics.draw(gameCanvas,0,0,0,SCALE,SCALE)

    -- HIGH RESOLUTION HUD

    -- TOP PANEL
    love.graphics.setColor(.08,.20,.22,.94)
    love.graphics.rectangle("fill",12,12,776,58,8,8)

    love.graphics.setColor(.45,.75,.78)
    love.graphics.setLineWidth(2)
    love.graphics.rectangle("line",12,12,776,58,8,8)

    -- TITLE
    love.graphics.setFont(hudFont)
    love.graphics.setColor(1,.94,.72)
    love.graphics.print("CHICKVENTURE",28,22)

    -- STAR COUNTER
    love.graphics.setColor(1,.83,.25)
    love.graphics.print("STAR  "..score.."/"..#stars,390,22)

    -- CHECKPOINT
    if checkpoint.active then
        love.graphics.setFont(hudSmallFont)
        love.graphics.setColor(.65,1,.65)
        love.graphics.print("CHECKPOINT ACTIVATED",28,46)
    end

    -- HEARTS
    for i=1,maxLives do
        local x=690+(i-1)*27
        local y=28

        if i<=lives then
            love.graphics.setColor(1,.25,.40)
        else
            love.graphics.setColor(.35,.35,.38)
        end

        love.graphics.rectangle("fill",x+4,y,6,5)
        love.graphics.rectangle("fill",x+14,y,6,5)
        love.graphics.rectangle("fill",x,y+5,24,7)
        love.graphics.rectangle("fill",x+3,y+12,18,5)
        love.graphics.rectangle("fill",x+7,y+17,10,4)
        love.graphics.rectangle("fill",x+10,y+21,4,3)
    end

    -- BOTTOM PANEL
    love.graphics.setColor(.08,.20,.22,.90)
    love.graphics.rectangle("fill",12,526,776,62,8,8)

    love.graphics.setFont(hudSmallFont)

    local hint

    if gate.unlocked then
        hint="STAR GATE OPEN!  REACH IT!"
    else
        hint="EXPLORE THE MEADOW AND FIND THE STARS"
    end

    love.graphics.setColor(1,.91,.55)
    love.graphics.printf(hint,22,536,756,"center")

    love.graphics.setColor(1,.94,.82)
    love.graphics.printf(
        "A / D  MOVE     SPACE  JUMP     P / ESC  PAUSE     M  MUSIC: "
        ..(musicMuted and "OFF" or "ON"),
        22,559,756,"center"
    )

    -- VICTORY OVERLAY
    if levelComplete then
        love.graphics.setColor(.08,.12,.16,.78)
        love.graphics.rectangle("fill",0,0,800,600)

        love.graphics.setColor(.15,.30,.32)
        love.graphics.rectangle("fill",150,160,500,280,16,16)

        love.graphics.setFont(gameOverFont)
        love.graphics.setColor(1,.86,.35)
        love.graphics.printf("LEVEL COMPLETE!",150,205,500,"center")

        love.graphics.setFont(subtitleFont)
        love.graphics.setColor(1,.95,.82)
        love.graphics.printf("Pippo found the Star Gate!",150,270,500,"center")

        love.graphics.setColor(1,.82,.35)
        love.graphics.printf("ALL STARS COLLECTED",150,315,500,"center")

        love.graphics.setColor(1,1,1)
        love.graphics.printf("PRESS R TO PLAY AGAIN",150,370,500,"center")
    end

    -- GAME OVER OVERLAY
    if gameOver then
        love.graphics.setColor(.08,.12,.16,.78)
        love.graphics.rectangle("fill",0,0,800,600)

        love.graphics.setColor(.15,.30,.32)
        love.graphics.rectangle("fill",170,185,460,230,16,16)

        love.graphics.setFont(gameOverFont)
        love.graphics.setColor(1,.55,.55)
        love.graphics.printf("GAME OVER",170,220,460,"center")

        love.graphics.setFont(subtitleFont)
        love.graphics.setColor(1,.94,.78)
        love.graphics.printf("Poor Pippo! Let's try again.",170,280,460,"center")

        love.graphics.setColor(1,.85,.35)
        love.graphics.printf("PRESS R TO RESTART",170,345,460,"center")

        love.graphics.setColor(1,1,1)
        love.graphics.printf("or press ENTER",170,375,460,"center")
    end

    -- STEP 28: PAUSE OVERLAY
    -- Drawn last so it appears above the game.
    if isPaused then
        drawPauseMenu()
    end
end

-- =====================================
-- MOUSE CLICK: MENU AND PAUSE BUTTONS
-- =====================================

local function isInsideButton(x,y,button)
    return x>=button.x
        and x<=button.x+button.w
        and y>=button.y
        and y<=button.y+button.h
end

function love.mousepressed(x,y,button)
    if button~=1 then return end

    -- START MENU PLAY BUTTON
    if gameState=="menu" then
        if isInsideButton(x,y,playButton) then
            gameState="story"
        end
        return
    end

    -- STEP 28: PAUSE MENU BUTTONS
    if gameState=="playing" and isPaused then

        -- RESUME
        if isInsideButton(x,y,pauseButtons.resume) then
            isPaused=false
            return
        end

        -- RESTART
        if isInsideButton(x,y,pauseButtons.restart) then
            restartGame()
            isPaused=false
            gameState="playing"
            return
        end

        -- MAIN MENU
        if isInsideButton(x,y,pauseButtons.menu) then
            isPaused=false
            gameState="menu"
            menuTimer=0
            return
        end
    end
end
