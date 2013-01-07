-- inspector.lua
-- GUI element for inspecting the properties of staff and clients

--Load required files and such
local entity = require("entity")
local resource = require("resource")
local event = require("event")
local sprite = require("sprite")
local transform = require("transform")
local client = require("client")
local staff = require("staff")

--Create the module
local M = {}

local info = {
  condoms = 0,
  money = 0,
  patience = 0,
  horniness = 0,
  hunger = 0,
}

--Constructor
M.new = function (state)
  --Create an entity and get the id for the new room
  local id = entity.new(state)
  entity.setOrder(id, 100)

  --Add sprite component
  entity.addComponent(id, sprite.new(
    id, {
      image = resource.get("img/arrow.png"),
      width = 24, height = 24,
      animations = {
        idle = {
          first = 0,
          last = 7,
          speed = .1
        },
      },
      playing = "idle",
      originX = 12-16,
      originY = 24-32+24,
    }
  ))
  entity.addComponent(id, transform.new(id, {roomNum = gRoomNum, floorNum = gScrollPos}))
  --Add position component
  entity.addComponent(id, transform.new(id, {roomNum = gRoomNum, floorNum = gScrollPos}))

  --Add inspector component
  inspectorUtility = entity.newComponent({
    entity = id,
    selected = 1,
    update = function (self, dt)
      local clients = client.getLeaders()
      if #clients > 0 then
        local max = #clients
        while self.selected < 1 or self.selected > max do
          if self.selected < 1 then
            max = #clients
            self.selected = max
          elseif self.selected > max then
            max = #clients
            self.selected = 1
          end
        end
        local target = clients[self.selected]
        local pos = transform.getPos(target.id)
        event.notify("entity.move", self.entity, pos)

        info.condoms = target.ai.supply
        info.money = target.ai.money / target.ai.info.maxMoney
        info.patience = target.ai.patience / 100
        info.horniness = target.ai.needs.horniness / 100
        info.hunger = math.max((100 - target.ai.needs.hunger) / 100, 0)

        event.notify("menu.info", 0, {
          inspector = info,
        })
      end
    end,
  })

  entity.addComponent(id, inspectorUtility)

  local pressed = function (key)
    if gState == STATE_PLAY then
      if key == "left" then
        inspectorUtility.selected = inspectorUtility.selected - 1
      elseif key == "right" then
        inspectorUtility.selected = inspectorUtility.selected + 1
      end
    end
  end


  local delete
  delete = function ()
    event.unsubscribe("pressed", 0, pressed)
    event.unsubscribe("delete", id, delete)
  end

  event.subscribe("pressed", 0, pressed)
  event.subscribe("delete", id, delete)
  --Function returns the rooms id
  return id
end

--Return the module
return M
