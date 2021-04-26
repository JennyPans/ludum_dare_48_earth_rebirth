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

local function Collision(box1, box2)
   return not ((box2.x >= box1.x + box1.w)
    or (box2.x + box2.w <= box1.x)
    or (box2.y >= box1.y + box1.h)
    or (box2.y + box2.h <= box1.y))
end

local function pointBoxCollision(x, y, box)
   return x >= box.x and x < box.x + box.w and y >= box.y and y < box.y + box.h
end

function math.angle(x1,y1, x2,y2) return math.atan2(y2-y1, x2-x1) end

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
        if sprite.type == "explosion" then sprite.toDelete = true end
    end
end

local function updateMoon(dt)
    moon.vx = moon.ax * dt
    if moon.x > SCREEN_WIDTH + 100 then moon.x = -100 end
end

local function updateBigAsteroid(asteroid, dt)
    local angle = math.angle(asteroid.x, asteroid.y, earth.x, earth.y)
    asteroid.vx = math.cos(angle) * asteroid.ax * dt
    asteroid.vy = math.sin(angle) * asteroid.ay * dt
    asteroid.hitbox.x = asteroid.x - 32
    asteroid.hitbox.y = asteroid.y - 32
end

local function newBox(x, y, w, h)
    local box = {
        x = x,
        y = y,
        w = w,
        h = h
    }
    return box
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
        animation = "",
        toDelete = false
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
    local animation = animations[earth.animation]
    earth.hitbox = newBox(earth.x - 60, earth.y - 60, animation.width * 1.2, animation.height * 1.2)
    earth.life = 10
end

local function newEarthDestroyed()
    earth_destroyed = newSprite("earth_destroyed", SCREEN_WIDTH/2, SCREEN_HEIGHT/2)
    earth_destroyed.sx = 2
    earth_destroyed.sy = 2
    startAnimation(earth_destroyed, "earth_destroyed", 20)
    earth_destroyed.ox = animations[earth_destroyed.animation].width / 2
    earth_destroyed.oy = animations[earth_destroyed.animation].height / 2
end

local function loadGameOverScreen()
    screen = "game_over"
    tweening = {time = 0, value = SCREEN_HEIGHT, distance = -SCREEN_HEIGHT, duration = 2, tween = -1}
    musics["Spacearray"]:setLooping(true)
    love.audio.stop()
    musics["Spacearray"]:play()
    newEarthDestroyed()
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
    bigAsteroid.ax = 64
    bigAsteroid.ay = 64
    table.insert(sprites, bigAsteroid)
    table.insert(asteroids, bigAsteroid)
    local animation = animations[bigAsteroid.animation]
    bigAsteroid.hitbox = newBox(bigAsteroid.x, bigAsteroid.y, animation.width, animation.height)
    return bigAsteroid
end

local function newExplosion(x, y)
    local explosion = newSprite("explosion", x, y)
    explosion.sx = 4
    explosion.sy = 4
    explosion.ox = 16
    explosion.oy = 16
    startAnimation(explosion, "explosion", 1)
    table.insert(explosions, explosion)
    return explosion
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
            if Collision(sprite.hitbox, earth.hitbox) and not sprite.toDelete then
                earth.life = earth.life - 1
                newExplosion(earth.x, earth.y)
                sprite.toDelete = true
                if earth.life <= 0 then
                    loadGameOverScreen(dt)
                end
            end
        end
        sprite.x = sprite.x + sprite.vx
        sprite.y = sprite.y + sprite.vy
        sprite.r = sprite.r + sprite.rSpeed
    end
end

local function loadTitleScreen()
    screen = "title_screen"
    tweening = {time = 0, value = SCREEN_HEIGHT, distance = -SCREEN_HEIGHT, duration = 2, tween = -1}
    musics["Spacearray"]:setLooping(true)
    musics["Spacearray"]:stop()
    musics["Spacearray"]:play()
end

local function initEarthScreen()
    screen = "earth_screen"
    musics["Spacearray"]:stop()
    mode = "attack"
    love.audio.stop()
    musics["MyVeryOwnDeadShip"]:play()
end

local function loadEarthScreen()
    initEarthScreen()
    newEarth()
    newMoon()
    asteroids = {}
    asteroidTimer = love.math.random(1, 10)
end

local function laser_attack()
    sounds["laser_attack"]:stop()
    sounds["laser_attack"]:play()
end

function love.mousepressed(x, y, button, istouch, presses )
    if screen == "earth_screen" then
        if mode == "attack" then
            if button == 1 then
                laser_attack()
                for index, asteroid in ipairs(asteroids) do
                    if pointBoxCollision(x, y, asteroid.hitbox) then
                        asteroid.toDelete = true
                        newExplosion(asteroid.x, asteroid.y)
                    end
                end
            end
        end
    end
end

local function switchAttackMode()
    if mode ~= "attack" then
        mode = "attack"
        sounds["laser_activated"]:stop()
        sounds["laser_activated"]:play()
    else
        mode = "normal" end
end

function love.keypressed(key, scancode, isrepeat)
    if screen == "title_screen" then
        if tweening.tween == 0 then
            if key == "space" then loadEarthScreen() end
        end
    elseif screen == "earth_screen" then
        if key == "v" then
            switchAttackMode()
        end
    end
    if key == "escape" then love.event.quit() end
end

local function loadAnimations()
    animations = {}
    animations["earth"] = newAnimation(images["earth"], 100, 100)
    animations["moon"] = newAnimation(images["moon"], 100, 100)
    animations["big_asteroid"] = newAnimation(images["big_asteroid"], 64, 64)
    animations["explosion"] = newAnimation(images["explosion"], 32, 32)
    animations["earth_destroyed"] = newAnimation(images["earth_destroyed"], 100, 100)
end

local function loadImages()
    images = {}
    images["title_screen"] = love.graphics.newImage("images/title_screen.png")
    images["earth"] = love.graphics.newImage("images/earth.png")
    images["moon"] = love.graphics.newImage("images/moon.png")
    images["attack_cursor"] = love.graphics.newImage("images/attack_cursor.png")
    images["normal_cursor"] = love.graphics.newImage("images/normal_cursor.png")
    images["big_asteroid"] = love.graphics.newImage("images/big_asteroid.png")
    images["cockpit"] = love.graphics.newImage("images/cockpit.png")
    images["explosion"] = love.graphics.newImage("images/explosion.png")
    images["game_over"] = love.graphics.newImage("images/game_over.png")
    images["earth_destroyed"] = love.graphics.newImage("images/earth_destroyed.png")
end

local function loadSounds()
    sounds = {}
    sounds["laser_attack"] = love.audio.newSource("sounds/laser_attack.mp3", "static")
    sounds["laser_activated"] = love.audio.newSource("sounds/laser_activated.ogg", "static")
end

local function loadMusics()
    musics = {}
    musics["Spacearray"] = love.audio.newSource("musics/Spacearray.ogg", "stream")
    musics["MyVeryOwnDeadShip"] = love.audio.newSource("musics/MyVeryOwnDeadShip.ogg", "stream")
end

local function updateTitleScreen(dt)
    if tweening.tween ~= 0 then
        if tweening.time < tweening.duration then
            tweening.time = tweening.time + dt
        end
        tweening.tween = math.floor(easeOutSine(tweening.time, tweening.value, tweening.distance, tweening.duration))
    end
end

local function updateGameOverScreen(dt)
    if tweening.tween ~= 0 then
        if tweening.time < tweening.duration then
            tweening.time = tweening.time + dt
        end
        tweening.tween = math.floor(easeOutSine(tweening.time, tweening.value, tweening.distance, tweening.duration))
    end
    updateAnimation(earth_destroyed, dt)
end

local function generateAsteroids(dt)
    asteroidTimer = asteroidTimer - dt
    if asteroidTimer <= 0 then
        asteroidTimer = love.math.random(1 , 3)
        for i = 1, love.math.random(3), 1 do
            local asteroid = newBigAsteroid(love.math.random(0, SCREEN_WIDTH), 0)
            asteroid.ax = love.math.random(42, 72)
            asteroid.ay = love.math.random(42, 72)
            asteroid.rSpeed = love.math.random(0.001, 0.005)
        end
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
    asteroids = {}
    explosions = {}
    loadTitleScreen()
end

local function deleteSprites(sprites)
    for sprite = #sprites, 1, -1 do
        if sprites[sprite].toDelete then
            table.remove(sprites, sprite)
        end
    end
end

function love.update(dt)
    if screen == "title_screen" then
        updateTitleScreen(dt)
    elseif screen == "earth_screen" then
        updateEarthScreen(dt)
    elseif screen == "game_over" then
        updateGameOverScreen(dt)
    end
    deleteSprites(sprites)
    deleteSprites(asteroids)
    deleteSprites(explosions)
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

local function gameOverScreen()
    love.graphics.setBackgroundColor(0,0,0,1)
    love.graphics.setColor(1,1,1,1)
    drawAnimation(earth_destroyed)
    for i = 1, 20, 1 do
        love.graphics.setColor(0, love.math.random(), 0, 1)
        love.graphics.points(love.math.random(SCREEN_WIDTH), love.math.random(SCREEN_HEIGHT))
    end
    love.graphics.draw(images["game_over"], 0, tweening.tween)
end

local function earthScreen()
    love.graphics.setBackgroundColor(0,0,0,1)
    love.graphics.setColor(1,1,1,1)
    drawAnimation(moon)
    drawAnimation(earth)
    for index, asteroid in ipairs(asteroids) do
        drawAnimation(asteroid)
    end
    for index, explosion in ipairs(explosions) do
        drawAnimation(explosion)
    end
    if mode == "normal" then
        love.graphics.draw(images["cockpit"], 0, 0)
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
    elseif screen == "game_over" then
        gameOverScreen()
    end
end