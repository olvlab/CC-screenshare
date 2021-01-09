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
 _G.oSSRestore = function() _G.write = oldwrite end
 _G.write = function(text)
  rednet.broadcast(textutils.serialise({
   line = text,
   bg = term.getBackgroundColor(),
   fg = term.getTextColor()
  }),"olvScreenshare")
  return oldwrite(text)
 end
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
      local bg, fg = term.getBackgroundColor(), term.getTextColor()
      term.setBackgroundColor(msg.bg) term.setTextColor(msg.fg)
      print(msg.line)
      term.setBackgroundColor(bg) term.setTextColor(fg)
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
