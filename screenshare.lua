local args = {...}

if not rednet.isOpen() then
 for i = 1, #peripheral.getNames() do
  local p = peripheral.getNames()[i]
  if peripheral.getType(p)=="modem" and peripheral.wrap(p).isWireless() then
   rednet.open(p)
   break
  end
 end
end

if rednet.isOpen() then
if not args[1] or args[1] == "help" then
 print(
[[olv's Screenshare
  screenshare [help]: display this text
  screenshare start: start a screenshare
  screenshare stop: stop a screenshare
  screenshare view <id>: view someone's screenshare]])
elseif args[1] == "start" then
 local oldwrite = _G.write
 _G.write = function(sText)
  rednet.broadcast(textutils.serialise({
   type = "write",
   text = sText,
   bg = term.getBackgroundColor(),
   fg = term.getTextColor()
  }),"olvScreenshare")
  return oldwrite(text)
 end
 
 local oldblit = term.blit
 term.blit = function(sText, bg, fg)
  rednet.broadcast(textutils.serialise({
   type = "blit",
   text = text,
   bg = bg,
   fg = fg
  }),"olvScreenshare")
  return oldblit(sText, bg, fg)
 end
 
 local oldclear = term.clear
 term.clear = function()
  rednet.broadcast(textutils.serialise({
   type = "clear"
  }),"olvScreenshare")
  return oldclear()
 end
 
 local oldcpos = term.setCursorPos
 term.setCursorPos = function(x, y)
  rednet.broadcast(textutils.serialise({
   type = "setCursorPos",
   x = x,
   y = y
  }),"olvScreenshare")
  return oldcpos(x, y)
 end
 
 local oldscroll = term.scroll
 term.scroll = function(n)
  rednet.broadcast(textutils.serialise({
   type = "scroll",
   n = n
  }),"olvScreenshare")
  return oldscroll(n)
 end
 _G.oSSRestore = function() _G.write = oldwrite term.blit = oldblit term.clear = oldclear term.setCursorPos = oldcpos term.scroll = oldscroll end
 print("Started screenshare as "..os.getComputerID())
elseif args[1] == "stop" then
 if _G.oSSRestore then
  _G.oSSRestore()
  print("Screenshare stopped")
 else
  print("Not currently screensharing")
 end
elseif args[1] == "view" then
 local viewid = tonumber(args[2])
 if viewid then
  local viewing = true
  local obg, ofg = term.getBackgroundColor(), term.getTextColor()
  term.clear()
  term.setCursorPos(1,1)
  parallel.waitForAll(
   function() while viewing do
    local id, msg, ptc = rednet.receive("olvScreenshare",5)
    if id then
     if msg then
      msg = textutils.unserialise(msg)
	  if msg.type == "write" then
       local bg, fg = term.getBackgroundColor(), term.getTextColor()
       term.setBackgroundColor(msg.bg) term.setTextColor(msg.fg)
       print(msg.text)
       term.setBackgroundColor(bg) term.setTextColor(fg)
	  elseif msg.type == "blit" then
	   term.blit(msg.text,msg.bg,msg.fg)
	  elseif msg.type == "clear" then
	   term.clear()
	  elseif msg.type == "setCursorPos" then
	   term.setCursorPos(msg.x,msg.y)
	  elseif msg.type == "scroll" then
	   term.scroll(msg.n)
	  end
     end
    else
     viewing = false
     term.clear()
     term.setCursorPos(1,1)
     term.setBackgroundColor(obg) term.setTextColor(ofg)
     print("Connection to "..viewid.." lost")
     break
    end
   end end,
   
   function() while viewing do
    local _, code, isHeld = os.pullEvent("key")
    if code then
     local key = keys.getName(code)
     if key == "backspace" then
      viewing = false
      term.clear()
      term.setCursorPos(1,1)
      term.setBackgroundColor(obg) term.setTextColor(ofg)
      print("Exited "..viewid.."'s screenshare")
      break
     end
    end
   end end
  )
 else
  print("Invalid ID")
 end
else
 print("Unknown command")
end
else
 print("No modems found")
end
