-- seabirds
local lattice = require('lattice')

local lat = lattice:new()

function init()
  -- DO set global variables here
  -- press the init buttons to reset variables
  angle = 0
  heading = 0
  clock.run(function() 
    while true do
      clock.sleep(1/15)
      redraw()
    end
  end)
  update_pos = lat:new_pattern{
   division = 1/32,
   action = function()
     heading = (heading - angle/16) % (2*math.pi)
   end,
  }
  lat:start()
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
  centered_at(64, 32, function()
    tilted(angle, function()
    
      screen.aa(1)
      screen.line_width(1)
      -- horizontal
      screen.level(2)
      screen.move(-80, 0)
      screen.line(80, 0)
      screen.move(-80, 1)
      screen.line(80, 1)      
      screen.stroke()
      for i=1,8,1 do
        screen.level(2*i)
        screen.move(-80, util.linexp(1, 8, 4, 45, i + (beat % 1)*2)-4)
        screen.line(80,  util.linexp(1, 8, 4, 45, i + (beat % 1)*2)-4)
        screen.stroke()
      end
      -- vertical
      for i=1,8,1 do
        local offset = (64 * heading / (2 * math.pi)) % 1
        local px = util.linlin(1, 8, -120, 120, i + offset)
        screen.move(px, 40)
        screen.line(px/2, 0)
        screen.stroke()
      end
    end)
  end)
  screen.update()
end