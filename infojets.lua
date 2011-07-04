require('orglendar')

local scr = screen[1]
local scrgeom = scr.workarea

local font = theme.font or "sans 8"
local fg = theme.fg_normal or '#ffffff'
local bg = theme.bg_normal or '#535d6c'
local motive = theme.motive or "#CC0000"

infojets = {}

local function create_wbox(wname, wx, wy, wwidth, wheight)
   local wbox = wibox({ name = wname, bg = '#00FF0000', 
                        height = wheight , width = wwidth })
   wbox:geometry({ x = wx, y = wy })
   wbox.screen = 1
   wbox.ontop = false
   return wbox
end

local function pango(text, args)
   local font = args.font
   local foreground = args.foreground
   local weight = args.weight
   local letter_spacing = args.letter_spacing
   local result = '<span'

   if font then
      result = result .. string.format(' font = "%s"', font)
   end
   if foreground then
      result = result .. string.format(' foreground = "%s"', foreground)
   end
   if weight then
      result = result .. string.format(' weight = "%s"', weight)
   end
   if letter_spacing then
      result = result .. string.format(' letter-spacing = "%s"', letter_spacing)
   end
   return string.format(result .. '>%s</span>', text)
end

function infojets.add_clock()
   local wboxheight = 170
   local wboxwidth = 650
   local hmiddle = (scrgeom.height - wboxheight) / 2 - 50
   local clockwbox = create_wbox("hourwbox", 100, hmiddle, wboxwidth, wboxheight)

   local clockjet = widget({ type = "textbox", align = "flex" })
   clockjet.width = 335
   infojets.update_clock = 
      function()
         clockjet.text = string.format("%s%s%s",
                                      pango(os.date("%H"), { font = "Helvetica 80", foreground = "#000000"}),
                                      pango(" ", {font = "Helvetica 90"}),
                                      pango(os.date("%M"), { font = "Helvetica 80", foreground = "#FFFFFF"}))
      end

   local datejet = widget({ type = "textbox", align = "bottom" })
   infojets.update_date = 
      function()
         datejet.text = string.format("%s\n%s    %s\n%s",
                                      pango(" ", { font = "Helvetica 4" }),
                                      pango(os.date("%d"), { font = "Helvetica 31", foreground = motive}),
                                      pango(os.date("%B"), { font = "Helvetica 29", foreground = "#FFFFFF"}),                
                                      pango(os.date("%A"), { font = "Helvetica 29", foreground = "#FFFFFF"}))
      end
   
   local separator = widget({ type = "textbox", align = "flex" })
   separator.text = pango("  ", { font = "Helvetica 100" })

   clockwbox.widgets = { clockjet, datejet, layout = awful.widget.layout.horizontal.leftright }
end

function infojets.add_stats()
   local wboxheight = 170
   local wboxwidth = 700
   local ycoord = (scrgeom.height - wboxheight) / 2 + 150
   local statbox = create_wbox("statwbox", 435, ycoord, wboxwidth, wboxheight)
   
   local ramjet = widget({type = "textbox", align = "flex"})
   ramjet.width = 200
   infojets.update_ram = 
      function(used, free)
         ramjet.text = string.format("%s\n%s\n%s",
                                     pango("RAM Usage", { font = "Helvetica 14", foreground = motive}),
                                     pango("Used: "..used.."MB", { font = "Helvetica 14", foreground = "#FFFFFF"}),
                                     pango("Free: "..free.."MB", { font = "Helvetica 14", foreground = "#FFFFFF"}))
      end
   
   local cpujet = widget({type = "textbox", align = "flex"})
   cpujet.width = 200
   local cputext = string.format("%s\n%s\n%s",
                               pango("CPU Usage", { font = "Helvetica 14", foreground = motive}),
                               pango("Average: 0%", { font = "Helvetica 14", foreground = "#FFFFFF"}),
                               pango("Temp: 0°C", { font = "Helvetica 14", foreground = "#FFFFFF"}))
   infojets.update_cpu = 
      function(load)
         cputext = string.gsub(cputext, "Average: %d+", "Average: " .. load)
         cpujet.text = cputext         
      end   
   infojets.update_temp = 
      function(temp)
         cputext = string.gsub(cputext, "Temp: %d+", "Temp: " .. temp)
         cpujet.text = cputext
      end

   local weatherjet = widget({type = "textbox", align = "flex"})
   weatherjet.width = 250
   local update_weather = 
      function()
         local query = "conkyForecast --location=UPXX0016 --datatype=LT --datatype="
         local cond = io.popen(query .. "CT"):read("*line")
         local real_temp = io.popen(query .. "HT"):read("*line")
         local feel_temp = io.popen(query .. "LT"):read("*line")
         local sun_rise = io.popen(query .. "SR"):read("*line")
         local sun_set = io.popen(query .. "SS"):read("*line")
         weatherjet.text = pango(string.format("%s\n"..
                                               "%s: %s (%s)\n"..
                                               "Daytime: %s - %s",
                                               pango("Weather", { foreground = motive }),
                                               cond, real_temp, feel_temp, sun_rise, sun_set),
                                 { font = "Helvetica 14", foreground = "#FFFFFF"})
      end
   repeat_every(update_weather, 600)
   weatherjet:buttons(awful.util.table.join(
                         awful.button({ }, 1, 
                                      function ()
                                         awful.util.spawn("firefox http://www.gismeteo.ua/city/daily/4944/")
                                         awful.tag.viewonly(tags[screen][2])
                                      end)))

   statbox.widgets = { ramjet, cpujet, weatherjet, 
                       layout = awful.widget.layout.horizontal.leftright }
end

function infojets.add_procs()
   local wboxheight = 170
   local wboxwidth = 635
   local ycoord = (scrgeom.height - wboxheight) / 2 + 300
   local procbox = create_wbox("procwbox", 435, ycoord, wboxwidth, wboxheight)
   
   local handle_ps = 
      function(sort_by,tname)
         local i = 3
         local t = {}
         for line in io.popen("ps -eo comm,pcpu,pmem --sort "..sort_by.." | tail -n 3"):lines() do
            local _, _, p, c, m = string.find(line, "([^%s]+)%s+([^%s]+)%s+([^%s]+)")
            p = pop_spaces(string.sub(p,1,12),"",12)
            c = pop_spaces(c,"",5)
            t[i] = { proc = p, cpu = c, mem = m }
               i = i - 1
         end
         return pango(string.format("%s\n"..
                                              "%s\t%s\t%s\n"..
                                              "%s\t%s\t%s\n"..
                                              "%s\t%s\t%s\n",
                                           pango(tname.."\tCPU%\tMEM%", { foreground = motive }),
                                           t[1].proc, t[1].cpu, t[1].mem,
                                           t[2].proc, t[2].cpu, t[2].mem,
                                           t[3].proc, t[3].cpu, t[3].mem),
                             { font = "Helvetica 12", foreground = "#FFFFFF"})
      end
         
   local topcpujet = widget({type = "textbox", align = "flex"})
   topcpujet.width = 250
   infojets.update_topcpu =
      function()
         topcpujet.text = handle_ps("pcpu","Top CPU")
      end

   local topmemjet = widget({type = "textbox", align = "flex"})
   topmemjet.width = 250
   infojets.update_topmem =
      function()
         topmemjet.text = handle_ps("rss","Top Mem")
      end
   repeat_every(function()
                   infojets.update_topcpu()
                   infojets.update_topmem()
                end, 10)

   procbox.widgets = { topcpujet, { topmemjet, layout = awful.widget.layout.horizontal.rightleft },
                       layout = awful.widget.layout.horizontal.leftright }
end

function infojets.add_orglendar()
   orglendar.files = { "/home/unlogic/Documents/Notes/edu.org" }

   local caljet = widget({ type = "textbox", align = "flex"})
   local todojet = widget({ type = "textbox", align = "right"})
   
   local wwidth = 170
   local wheight = 160
   local wx = scrgeom.width - wwidth - 20
   local wy = 33
   
   local calbox = create_wbox("calbox", wx, wy, wwidth, wheight)
   calbox.widgets = { caljet }

   infojets.offset = 0
   infojets.update_calendar =
      function(inc_offset)
         print(inc_offset)
         infojets.offset = infojets.offset + inc_offset
         local caltext = generate_calendar(infojets.offset,"#8f8f8f",motive,"DejaVu Sans Mono 10").calendar
         caljet.text = pango(caltext, { foreground = "#FFFFFF" })
      end
   
   local todobox = create_wbox("todobox", scrgeom.width - wwidth - 20, wheight + 20, 200, 300)
   todobox.widgets = { todojet }
   
   infojets.update_todo = 
      function()
         local query = os.date("%Y-%m-%d")
            local todotext = create_string(query,motive,"DejaVu Sans Mono 10")
            todojet.text = pango(todotext, { foreground = "#FFFFFF" })
            todobox.width = todojet:extents().width
            todobox.height = todojet:extents().height
            todobox:geometry({ x = scrgeom.width - todojet:extents().width - 20, y = wheight + 20})
            infojets.update_calendar(0)
         end
   
   caljet:buttons(awful.util.table.join(
                     awful.button({ }, 2,
                                  function ()
                                     infojets.offset = 0
                                     infojets.update_calendar(0)
                                  end),
                     awful.button({ }, 4, 
                                  function ()
                                     infojets.update_calendar(-1)
                                  end),
                     awful.button({ }, 5, 
                                  function ()
                                     infojets.update_calendar(1)
                                  end)))

   repeat_every(infojets.update_todo,600)
end

infojets.add_clock()
infojets.add_stats()
infojets.add_procs()
infojets.add_orglendar()

awful.util.spawn("feh --bg-scale " .. theme.theme_dir .. "/background-large.jpg")
