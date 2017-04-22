-- Programa: Web Server com ESP8266 NodeMCU e DHT22
-- Autor: Arduino e Cia
-- Baseado no programa original de www.beerandchips.net
gpio.mode(5, gpio.INPUT,gpio.PULLUP)
gpio.mode(6, gpio.INPUT,gpio.PULLUP)

function round2(num, numDecimalPlaces)
  return tonumber(string.format("%." .. (numDecimalPlaces or 0) .. "f", num))
end

local MAX_LEVEL = 380
local MIN_LEVEL = 50
local PERCENT = 100 / (MAX_LEVEL - MIN_LEVEL)
PERCENT = round2(PERCENT,1)
print(PERCENT)
-- Define as configuracoes de rede
wifi.setmode(wifi.STATION)
wifi.sta.config("greenhouse", "senhasupersecreta")
wifi.sta.autoconnect(1)


function check_wifi()
  local ip = wifi.sta.getip()
  if(ip==nil) then
    print("Connecting...")
  else
    tmr.stop(0)
    print("Connected to AP!")
    -- Cria e roda o web server
    srv = net.createServer(net.TCP, 30)
    print("Server created on " .. wifi.sta.getip())
    srv:listen(80, function(conn)
      local highLevelSwitch = gpio.read(5)
      local lowLevelSwitch = gpio.read(6)
      local waterlevel = adc.read(0)
      local waterlevelpercent = waterlevel * PERCENT
      local n = node.heap()
      local times = timesRunned
      local time = rtctime.get()
      conn:on("receive", function(conn, request)
      print(request)

      conn:send('<html lang="en"><head><meta http-equiv="Content-Type" content="text/html; charset=UTF-8">')
      conn:send('<title>NodeMCU Water level</title> <link href="https://maxcdn.bootstrapcdn.com/bootstrap/3.3.7/css/bootstrap.min.css" rel="stylesheet"></head>')
      conn:send('<title>NodeMCU Water level</title> <link href="https://maxcdn.bootstrapcdn.com/bootstrap/3.3.7/css/bootstrap-theme.min.css" rel="stylesheet"></head>')

      conn:send('<meta http-equiv="refresh" content="5">')
      conn:send('<body>')
      conn:send('<div class="container theme-showcase" role="main"><div class="page-header"><h1>Limites</h1></div><h1>')
      --labes
      if(lowLevelSwitch == 0)then
        conn:send('<span class="label label-success">Nivel minimo</span>')
      else
        conn:send('<span class="label label-danger">Nivel minimo</span>')
      end
      if(highLevelSwitch == 1)then
        conn:send('<span class="label label-success">Nivel maximo</span>')
      else
        conn:send('<span class="label label-danger">Nivel maximo</span>')
      end

      conn:send('</h1>')
      conn:send('<div class="page-header">')

      --water level
      conn:send('<h1>Nivel de agua ('.. waterlevel ..')</h1></div>')

      conn:send('<div class="progress">')
      --progress bar
      conn:send('<div class="progress-bar" role="progressbar" aria-valuenow="'..waterlevelpercent..'" aria-valuemin="0" aria-valuemax="100" style="min-width: 2em; width:' ..waterlevelpercent..'%;">')
      conn:send(''..waterlevelpercent..'%')
      conn:send('</div>')
      conn:send('</div>Nivel Minimo detectavel: '..MIN_LEVEL..' <br>Nivel Maximo detectavel: '..MAX_LEVEL..'</div>')

      conn:send('</body></html>')
      conn:on("sent", function(conn) conn:close() end)
    end)
    end)
end
end
tmr.alarm(0,2000,1,check_wifi)
