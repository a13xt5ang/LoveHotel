-- builder.lua
-- GUI element for placing a new room

--Load required files and such
local entity = require("entity")
local resource = require("resource")
local event = require("event")
local sprite = require("sprite")
local transform = require("transform")
local room = require("room")

--Create the module
local M = {}

local placer = function (id, type, pos, width, cost, t)
  local component = entity.newComponent({
    room = pos.roomNum,
    floor = pos.floorNum,
    width = width,
    cost = cost,
    x = 0,
    y = 0,
    pixelWidth = t.width,
    pixelHeight = t.height,
  })
  
  local clear = true
  local support = 0
  local occupation = 0
  local new = true

  local okay = function ()
    return (
      clear and
      (component.floor <= gTopFloor and component.floor >= gBottomFloor) and
      cost <= gMoney
    )
  end
  
  component.draw = function (self)
    if okay() then
      love.graphics.setColor(0,184,0)
    else
      love.graphics.setColor(172,16,0)
    end
    love.graphics.setLine(1, "rough")
    love.graphics.rectangle("line", self.x-.5, self.y-.5, self.pixelWidth+1, self.pixelHeight+1)
  end
    
  local updatePosition = function()
    clear = true
    support = 0
    event.notify("entity.move", id, {roomNum = component.room, floorNum = component.floor})
    
    for i = 1,component.width do
      event.notify("room.check", 0, {
        roomNum = component.room + i - 1,
        floorNum = component.floor,
        callback = function (otherId)
          clear = false
        end,
      })
      event.notify("room.check", 0, {
        roomNum = component.room + i - 1,
        floorNum = component.floor - 1,
        callback = function (otherId)
          support = support + 1
        end,
      })
    end
  end

  component.update = function (dt)
    if new then
      updatePosition()
      new = false
    end
  end
  
  local pressed = function (key)
    if gState == STATE_PLAY then
      if key == "left" then
        if component.room > 1 then
          component.room = component.room - 1
          updatePosition()
        end
      elseif key == "right" then
        if component.room+component.width <= 7 then
          component.room = component.room + 1
          updatePosition()
        end
      elseif key == "a" then
        if okay() then
          local pos = {roomNum = component.room, floorNum = component.floor}
          local roomId = room.new(STATE_PLAY, type, pos)
          gMoney = gMoney - cost
            event.notify("money.change", 0, {
            amount = -cost,
            pos = {roomNum = component.room, floorNum = component.floor},
          })
          event.notify("build", id, {id=roomId, pos=pos, type=type})
          event.notify("build", 0, {id=roomId, pos=pos, type=type})
          local snd = resource.get("snd/build.wav")
          love.audio.rewind(snd)
          love.audio.play(snd)
        else
          local snd = resource.get("snd/error.wav")
          love.audio.rewind(snd)
          love.audio.play(snd)
        end
      end
    end
  end

  local scroll = function (scrollPos)
    component.floor = scrollPos
    updatePosition()
  end

  local move = function (pos)
    component.x = pos.x
    component.y = pos.y
  end

  local function delete ()
    event.unsubscribe("pressed", 0, pressed)
    event.unsubscribe("scroll", 0, scroll)
    event.unsubscribe("sprite.move", id, move)
    event.unsubscribe("delete", id, delete)
  end
  
  event.subscribe("pressed", 0, pressed)
  event.subscribe("scroll", 0, scroll)
  event.subscribe("sprite.move", id, move)
  event.subscribe("delete", id, delete)
  
  return component
end

--Constructor
M.new = function (state, roomType, pos)
  --Create an entity and get the id for the new room
  local id = entity.new(state)
  entity.setOrder(id, 100)
  local room = resource.get("scr/rooms/" .. string.lower(roomType) .. ".lua")
  local roomWidth = room.width*32
  local roomHeight = 32
  local prefix = "img/rooms/" .. room.id .. "_"
  
  --Add sprite components
  for _,s in ipairs(room.sprites) do
    entity.addComponent(id, sprite.new(id, {
      image = resource.get(prefix .. s.name .. ".png"),
      width = roomWidth,
      height = roomHeight,
      animations = s.animations,
      playing = "closed",
    }))
  end

  --Add position component
  entity.addComponent(id, transform.new(id, pos))
  --Add placer component (including outline)
  entity.addComponent(id, placer(id, roomType, pos, room.width, room.cost, {
    width = room.width*32,
    height = 32,
  }))

  --Function returns the rooms id
  return id
end

--Return the module
return M
