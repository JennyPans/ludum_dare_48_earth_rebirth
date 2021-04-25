--[[
 _               _                  ______                   ___  _____
| |             | |                 |  _  \                 /   ||  _  |
| |    _   _  __| |_   _ _ __ ___   | | | |__ _ _ __ ___   / /| | \ V /
| |   | | | |/ _` | | | | '_ ` _ \  | | | / _` | '__/ _ \ / /_| | / _ \
| |___| |_| | (_| | |_| | | | | | | | |/ / (_| | | |  __/ \___  || |_| |
\_____/\__,_|\__,_|\__,_|_| |_| |_| |___/ \__,_|_|  \___|     |_/\_____/
     _____           _   _      ______     _     _      _   _
    |  ___|         | | | |     | ___ \   | |   (_)    | | | |
    | |__  __ _ _ __| |_| |__   | |_/ /___| |__  _ _ __| |_| |__
    |  __|/ _` | '__| __| '_ \  |    // _ \ '_ \| | '__| __| '_ \
    | |__| (_| | |  | |_| | | | | |\ \  __/ |_) | | |  | |_| | | |
    \____/\__,_|_|   \__|_| |_| \_| \_\___|_.__/|_|_|   \__|_| |_|

    2021-04-21
    by Fliflifly
]]--

io.stdout:setvbuf("no")

require("constants")

local function easeOutSine(t, b, c, d)
	return c * math.sin(t/d * (math.pi/2)) + b
end

local function newAnimation(image, width, height)
    local animation = {}
    animation.spriteSheet = image
    animation.quads = {}
    animation.width = width
    animation.height = height

    for y = 0, image:getHeight() - height, height do
        for x = 0, image:getWidth() - width, width do
            table.insert(animation.quads, love.graphics.newQuad(x, y, width, height, image:getDimensions()))
        end
    end

    return animation
end

local function startAnimation(sprite, animation, duration)
    if animation ~= sprite.animation then
        sprite.animation = animation
        sprite.currentTimeAnimation = 0
        sprite.animationDuration = duration
    end
end

local function updateAnimation(sprite, dt)
    sprite.currentTimeAnimation = sprite.currentTimeAnimation + dt
    if sprite.currentTimeAnimation >= sprite.animationDuration then
        sprite.currentTimeAnimation = sprite.currentTimeAnimation - sprite.animationDuration
    end
end

local function updateMoon(dt)
    moon.vx = moon.ax * dt
    if moon.x > SCREEN_WIDTH + 100 then moon.x = -100 end
end

local function updateBigAsteroid(asteroid, dt)
    asteroid.vx = asteroid.ax * dt
    asteroid.vy = asteroid.ay * dt
end

local function updateSprites(dt)
    for index, sprite in ipairs(sprites) do
        sprite.vx = 0
        sprite.vy = 0
        updateAnimation(sprite, dt)
        if sprite.type == "moon" then
            updateMoon(dt)
        elseif sprite.type == "big_asteroid" then
            updateBigAsteroid(sprite, dt)
        end
        sprite.x = sprite.x + sprite.vx
        sprite.y = sprite.y + sprite.vy
        sprite.r = sprite.r + sprite.rSpeed
    end
end

local function newSprite(type, x, y)
    local sprite = {
        type = type,
        x = x,
        y = y,
        vx = 0,
        vy = 0,
        sx = 1,
        sy = 1,
        ox = 0,
        oy = 0,
        r = 0,
        rSpeed = 0,
        animation = ""
    }
    table.insert(sprites, sprite)
    return sprite
end

local function newEarth()
    earth = newSprite("earth", SCREEN_WIDTH/2, SCREEN_HEIGHT/2)
    earth.sx = 2
    earth.sy = 2
    startAnimation(earth, "earth", 20)
    earth.ox = animations[earth.animation].width / 2
    earth.oy = animations[earth.animation].height / 2
end

local function newMoon()
    moon = newSprite("moon", SCREEN_WIDTH/2, SCREEN_HEIGHT/2)
    startAnimation(moon, "moon", 10)
    moon.ax = 20
    moon.sx = 0.5
    moon.sy = 0.5
    moon.ox = animations[moon.animation].width / 2
    moon.oy = animations[moon.animation].height / 2
end

local function newBigAsteroid(x, y)
    local bigAsteroid = newSprite("big_asteroid", x, y)
    startAnimation(bigAsteroid, "big_asteroid", 1)
    bigAsteroid.ox = 32
    bigAsteroid.oy = 32
    bigAsteroid.ax = 2
    bigAsteroid.ay = 2
    table.insert(sprites, bigAsteroid)
    table.insert(asteroids, bigAsteroid)
    return bigAsteroid
end

local function loadTitleScreen()
    screen = "title_screen"
    tweening = {time = 0, value = SCREEN_HEIGHT, distance = -SCREEN_HEIGHT, duration = 2, tween = -1}
    musics["Spacearray"]:setLooping(true)
    musics["Spacearray"]:stop()
    musics["Spacearray"]:play()
end

local function loadEarthScreen()
    screen = "earth_screen"
    musics["Spacearray"]:stop()
    mode = "normal"
    newEarth()
    newMoon()
    asteroids = {}
    asteroidTimer = love.math.random(1, 10)
end

function love.keypressed(key, scancode, isrepeat)
    if screen == "title_screen" then
        if tweening.tween == 0 then
            if key == "space" then loadEarthScreen() end
        end
    elseif screen == "earth_screen" then
        if key == "v" then
            if mode ~= "attack" then mode = "attack" else mode = "normal" end
        end
    end
    if key == "escape" then love.event.quit() end
end

local function loadAnimations()
    animations = {}
    animations["earth"] = newAnimation(images["earth"], 100, 100)
    animations["moon"] = newAnimation(images["moon"], 100, 100)
    animations["big_asteroid"] = newAnimation(images["big_asteroid"], 64, 64)
end

local function loadImages()
    images = {}
    images["title_screen"] = love.graphics.newImage("images/title_screen.png")
    images["earth"] = love.graphics.newImage("images/earth.png")
    images["moon"] = love.graphics.newImage("images/moon.png")
    images["attack_cursor"] = love.graphics.newImage("images/attack_cursor.png")
    images["normal_cursor"] = love.graphics.newImage("images/normal_cursor.png")
    images["big_asteroid"] = love.graphics.newImage("images/big_asteroid.png")
end

local function loadSounds()
end

local function loadMusics()
    musics = {}
    musics["Spacearray"] = love.audio.newSource("musics/Spacearray.ogg", "stream")
end

local function updateTitleScreen(dt)
    if tweening.tween ~= 0 then
        if tweening.time < tweening.duration then
            tweening.time = tweening.time + dt
        end
        tweening.tween = math.floor(easeOutSine(tweening.time, tweening.value, tweening.distance, tweening.duration))
    end
end

local function generateAsteroids(dt)
    asteroidTimer = asteroidTimer - dt
    if asteroidTimer <= 0 then
        asteroidTimer = love.math.random(1 , 10)
        local asteroid = newBigAsteroid(love.math.random(0, SCREEN_WIDTH), 0)
        asteroid.rSpeed = love.math.random(0.05, 0.1)
    end
end

local function updateEarthScreen(dt)
    generateAsteroids(dt)
    updateSprites(dt)
end

function love.load()
    love.graphics.setDefaultFilter("nearest", "nearest")
    love.mouse.setGrabbed(true)
    love.mouse.setVisible(false)
    loadImages()
    loadSounds()
    loadMusics()
    loadAnimations()
    sprites = {}
    loadTitleScreen()
end

function love.update(dt)
    if screen == "title_screen" then
        updateTitleScreen(dt)
    elseif screen == "earth_screen" then
        updateEarthScreen(dt)
    end
end

local function titleScreen()
    love.graphics.setBackgroundColor(0,0,0,1)
    for i = 1, 20, 1 do
        love.graphics.setColor(0, love.math.random(), 0, 1)
        love.graphics.points(love.math.random(SCREEN_WIDTH), love.math.random(SCREEN_HEIGHT))
    end
    love.graphics.draw(images["title_screen"], 0, tweening.tween)
end

local function drawAnimation(sprite)
    if sprite.animation ~= "" then
        local animation = animations[sprite.animation]
        local spriteNum = math.floor(sprite.currentTimeAnimation / sprite.animationDuration * #animation.quads) + 1
        love.graphics.draw(animation.spriteSheet, animation.quads[spriteNum], sprite.x, sprite.y, sprite.r, sprite.sx, sprite.sy, sprite.ox, sprite.oy)
    end
end

local function earthScreen()
    love.graphics.setBackgroundColor(0,0,0,1)
    love.graphics.setColor(1,1,1,1)
    drawAnimation(moon)
    drawAnimation(earth)
    for index, asteroid in ipairs(asteroids) do
        drawAnimation(asteroid)
    end
    if mode == "normal" then
        love.graphics.draw(images["normal_cursor"], love.mouse.getX(), love.mouse.getY(), 0, 2, 2)
    elseif mode == "attack" then
        love.graphics.draw(images["attack_cursor"], love.mouse.getX(), love.mouse.getY(), 0, 2, 2, 8, 8)
    end
end

function love.draw()
    if screen == "title_screen" then
        titleScreen()
    elseif screen == "earth_screen" then
        earthScreen()
    end
end