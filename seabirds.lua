-- seabirds
local lattice = require('lattice')
local lfos = require('lfo')
local s = require('sequins')

local lat = lattice:new()

local SIZE = 1024

function init()
  angle = 0
  heading = 0
  x = 0
  y = 0
  clock.run(function() 
    while true do
      clock.sync(1/8)
      redraw()
    end
  end)
  update_pos = lat:new_pattern{
    division = 1/32,
    action = function()
      local d_heading = -math.sin(angle)/16
      -- if d_heading > math.pi then
      --   d_heading = d_heading - 2*math.pi
      -- end
      heading = (heading + d_heading) % (2*math.pi)
      x = x + math.sin(heading)/32
      y = y + math.cos(heading)/32
      x = x % SIZE
      y = y % SIZE
   end
  }
  lat:start()
end

local heading_letters = {"N", "NNE", "NE", "ENE", "E", "ESE", "SE", "SSE", "S", "SSW", "SW", "WSW", "W", "WNW", "NW", "NNW"}

function heading_letter()
  local i = util.wrap(util.round(-16*heading/(2*math.pi), 1) + 1, 1, 16)
  return heading_letters[i]
end

function key(n, z)
  -- called when a key is pressed or released
end

function enc(n, d)
  -- called when an encoder is turned
  if n == 2 then
    angle = angle + 0.01 * d
    angle = angle % (2*math.pi)
  end
end

function centered_at(x, y, f)
  screen.translate(x, y)
  f()
  screen.translate(-x, -y)
end

function tilted(angle, f)
  screen.rotate(angle)
  f()
  screen.rotate(-angle)
end
p = true
function redraw()
  -- update screen on each change
  screen.translate(0, 0)
  screen.clear()
  local beat = clock.get_beats()

  -- change numeric value under cursor using:
  -- ctl/cmd + alt/opt + equal (+1)
  -- ctl/cmd + alt/opt + minus (-1)
  -- ctl/cmd + alt/opt + shift + equal (+10)
  -- ctl/cmd + alt/opt + shift + minus (-10)
  screen.move(0, 10)
  screen.text(heading_letter())
  centered_at(64, 32, function()
    tilted(angle, function()
      screen.aa(1)
      screen.line_width(1)

      local height = 5 - 0.5*math.abs(math.sin(math.pi*((beat+1) % 2)/2))
      for i=1,12,1 do
        local distance = i - (beat % 1)
        if distance < 2 then
          goto continue
        end
        local fov = distance
        screen.level(util.clamp(math.ceil(16 - 1.2*i), 1, 15))
        local py = util.linlin(0, 2, 0, 45, height/distance)-4
        if py < -38 or py > 38 then
          goto continue
        end
        for j=1,32,0.5 do
          local offset = (64 * heading / (2 * math.pi)) % 1   
          local side = util.linlin(1, 32, -64, 64, j + offset)
          local px = util.linlin(-8, 8, -120, 120, side/distance)
          if px < -70 or px > 70 then
            goto innercontinue
          end
          local loc_x = x + side*math.sin(heading) + distance*math.cos(heading)
          local loc_y = y + side*math.cos(heading) + distance*math.sin(heading)
          local displacement = (
            0.7*math.sin(16*2*math.pi*(loc_x/SIZE) + 2*math.pi*beat/8) + 
            1.2*math.sin(32*2*math.pi*(loc_y/SIZE) - 2*math.pi*beat/8)
          )
          local p_d_y = util.linlin(-2, 2, -45, 45, displacement/distance)
          screen.move(px, py + p_d_y)
          if p_d_y > 0 and j % 1 == 0 then
            screen.line_rel(0, -p_d_y)
          else
            screen.line_rel(0, 1)
          end
          screen.stroke()
          ::innercontinue::
        end
        ::continue::
      end
      -- screen.move(-64, -10)
      -- screen.text("h ".. heading .. " a " .. angle)
      -- screen.move(-64, 0)
      -- screen.text("x ".. x .. " y " .. y)
      p = false
    end)
  end)
  screen.update()
end