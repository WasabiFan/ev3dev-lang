<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
<xsl:output method="text" version="1.0" encoding="UTF-8" indent="no"/>

<!-- XSLT source file for generation of ev3dev.lua -->

<xsl:template match="constant">
<xsl:apply-templates select="../name"/>.<xsl:value-of select="name"/> = <xsl:choose>
<xsl:when test="nil">nil
</xsl:when><xsl:when test="type = &quot;String&quot;">"<xsl:value-of select="value"/>"
</xsl:when><xsl:otherwise><xsl:value-of select="value"/>
</xsl:otherwise></xsl:choose></xsl:template>

<xsl:template match="property/constant">
<xsl:apply-templates select="../../name"/>.<xsl:apply-templates select="../name"/><xsl:value-of select="name"/> = <xsl:choose>
<xsl:when test="nil">nil
</xsl:when><xsl:when test="type = &quot;String&quot;">"<xsl:value-of select="value"/>"
</xsl:when><xsl:otherwise><xsl:value-of select="value"/>
</xsl:otherwise></xsl:choose></xsl:template>

<xsl:template match="class/name">
<xsl:choose>
  <xsl:when test="../Camel"><xsl:value-of select="../Camel"/></xsl:when>
  <xsl:otherwise><xsl:value-of select="."/></xsl:otherwise>
</xsl:choose></xsl:template>

<xsl:template match="property/name">
<xsl:choose>
  <xsl:when test="../camel"><xsl:value-of select="../camel"/></xsl:when>
  <xsl:when test="../attribute"><xsl:value-of select="../attribute"/></xsl:when>
  <xsl:when test="../lower"><xsl:value-of select="../lower"/></xsl:when>
  <xsl:otherwise><xsl:value-of select="."/></xsl:otherwise>
</xsl:choose></xsl:template>

<xsl:template match="type">
<xsl:choose>
  <xsl:when test=". = &quot;Number&quot;">Int</xsl:when>
  <xsl:when test=". = &quot;String Array&quot;">StringArray</xsl:when>
  <xsl:otherwise><xsl:value-of select="."/></xsl:otherwise>
</xsl:choose></xsl:template>

<xsl:template match="read">
function <xsl:apply-templates select="../../name"/>:<xsl:apply-templates select="../name"/>()
  return self:getAttr<xsl:apply-templates select="../type"/>("<xsl:apply-templates select="../attribute"/>")
end
</xsl:template>

<xsl:template match="write">
function <xsl:apply-templates select="../../name"/>:set<xsl:choose>
<xsl:when test="../Camel"><xsl:value-of select="../Camel"/></xsl:when>
<xsl:otherwise><xsl:value-of select="../name"/></xsl:otherwise></xsl:choose>(value)
  self:setAttr<xsl:apply-templates select="../type"/>("<xsl:apply-templates select="../attribute"/>", value)
end
</xsl:template>

<xsl:variable name="delimiter">
------------------------------------------------------------------------------
</xsl:variable>

<xsl:template match="spec">--
-- lua API to the sensors, motors, buttons, LEDs and battery of the ev3dev
-- Linux kernel for the LEGO Mindstorms EV3 hardware
--
-- Copyright (c) 2014 - Franz Detro
--
--
-- This program is free software; you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation; either version 2 of the License, or
-- (at your option) any later version.
--
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with this program; if not, write to the Free Software
-- Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
--

require 'class'

------------------------------------------------------------------------------

local sys_class   = "/sys/class/"
local sys_sound   = "/sys/devices/platform/snd-legoev3/"
local sys_power   = "/sys/class/power_supply/"

------------------------------------------------------------------------------
-- Device

Device = class()

function Device:init(sys_class_dir, pattern, match)

  if (sys_class_dir == nil) then
    error("connect needs sys_class_dir")
  end

  if (pattern == nil) then
    error("connect needs pattern")
  end

  -- check that sys_class_dir exists
  local r = io.popen("find "..sys_class.." -name '"..sys_class_dir.."'")
  local dir = r:read("*l")
  r:close()
  
  if (dir == nil) then
    return
  end

  -- lookup all pattern entries
  local devices = io.popen("find "..sys_class..sys_class_dir.." -name '"..pattern.."*'")
  for d in devices:lines() do
    self._path = d.."/"

    local success = true
    if (match ~= nil) then      
      for attr,matches in pairs(match) do
        success = false
        
        -- read attribute
        local pf = io.open(self._path..attr, "r")
        if (pf ~= nil) then
          -- read string value
          local value = pf:read("*l")
          if (value ~= nil) then
            -- check against matches
            local empty = true
            for i,entry in pairs(matches) do
              empty = false
              if (value == entry) then
                success = true
                break
              else 
               matched = false
              end
            end
            -- empty match list is success
            if (empty) then
              success = true
            end
          end
        end
        
        if not success then
          break
        end
      end
    end
    
    if (success) then
      devices:close()
      return true
    end
  end

  devices:close()

  self._path = nil
  
  return false
end

function Device:connected()
  return (self._path ~= nil)
end    

function Device:getAttrInt(name)

  if (self._path == nil) then
    error("no device connected")
  end
  
  local tf = io.open(self._path..name, "r")

  if (tf == nil) then
    error("no such attribute: "..self._path..name)
  end

  local result = tf:read("*n")
  tf:close()
  
  return result
end

function Device:setAttrInt(name, value)

  if (self._path == nil) then
    error("no device connected")
  end
  
  local tf = io.open(self._path..name, "w")

  if (tf == nil) then
    error("no such attribute: "..self._path..name)
  end

  tf:write(tostring(value))
  tf:close()
end

function Device:getAttrString(name)
  
  if (self._path == nil) then
    error("no device connected")
  end
  
  local tf = io.open(self._path..name, "r")

  if (tf == nil) then
    error("no such attribute: "..self._path..name)
  end

  local s = tf:read("*l")
  tf:close()
      
  return s
end

function Device:setAttrString(name, value)
  
  if (self._path == nil) then
    error("no device connected")
  end
  
  local tf = io.open(self._path..name, "w")

  if (tf == nil) then
    error("no such attribute: "..self._path..name)
  end
  
  tf:write(value)
  tf:close()
end

------------------------------------------------------------------------------
-- Port constants

<xsl:apply-templates select="constant"/>

<xsl:for-each select="class">
------------------------------------------------------------------------------
--
-- <xsl:value-of select="name"/>
--

<xsl:apply-templates select="name"/> = class(Device)
<xsl:if test="constant | */constant">
-- Constants
<xsl:apply-templates select="constant"/>
<xsl:apply-templates select="*/constant"/></xsl:if>
<xsl:value-of select="pre-lua"/>
<xsl:for-each select="property">
<xsl:apply-templates select="read"/>

<xsl:apply-templates select="write"/>
</xsl:for-each>
<xsl:value-of select="post-lua"/>
</xsl:for-each>
------------------------------------------------------------------------------
--Sound
Sound = class()

function Sound.beep()
  Sound.tone(1000, 100)
end

function Sound.tone(frequency, durationMS)
  local file = io.open(sys_sound.."tone", "w")
  if (file ~= nil) then 
    if (durationMS ~= nil) then
      file:write(" "..frequency.." "..durationMS)
    else
      file:write(frequency)
    end   
    file:close()
  end 
end

function Sound.play(soundfile)
  os.execute("aplay "..soundfile)
end

function Sound.speak(text)
  os.execute("espeak -a 200 --stdout \""..text.."\" | aplay")
end

function Sound.volume()
  local file = io.open(sys_sound.."volume")
  if (file ~= nil) then 
    local val = file:read("*n")
    file:close()
    return val
  end 
  
  return 50
end

function Sound.setVolume(levelInPercent)
  local file = io.open(sys_sound.."volume", "w")
  if (file ~= nil) then
    file:write(levelInPercent)
    file:close()
  end 
end

------------------------------------------------------------------------------
--RemoteControl
RemoteControl = class()

function RemoteControl:init(sensor, channel)
  if (sensor ~= nil) then
    if (sensor:type() == Sensor.EV3Infrared) then
      self._sensor = sensor
    end
  else
    self._sensor = InfraredSensor()
  end

  if (self._sensor ~= nil) then
    self._sensor:setMode(InfraredSensor.ModeIRRemote)
  end

  if (channel ~= nil) then
    self._channel = channel-1
  else
    self._channel = 0
  end
  
  self._lastValue = 0
  self._redUp     = false
  self._redDown   = false
  self._blueUp    = false
  self._blueDown  = false
  self._beacon    = false
end

function RemoteControl:connected()
  if (self._sensor ~= nil) then
    return self._sensor:connected()
  end
  
  return false
end

function RemoteControl:process()

  if (self._sensor ~= nil) then
    
    local value = self._sensor:value(self._channel)
    if (value ~= self._lastValue) then
      self:onNewValue(value)
      self._lastValue = value
      return true
    end
    
  end
  
end

function RemoteControl:onNewValue(value)

  local redUp    = false
  local redDown  = false
  local blueUp   = false
  local blueDown = false
  local beacon   = false
  
  if     (value == 1) then
    redUp = true
  elseif (value == 2) then
    redDown = true
  elseif (value == 3) then
    blueUp = true
  elseif (value == 4) then
    blueDown = true
  elseif (value == 5) then
    redUp  = true
    blueUp = true
  elseif (value == 6) then
    redUp    = true
    blueDown = true
  elseif (value == 7) then
    redDown = true
    blueUp  = true
  elseif (value == 8) then
    redDown  = true
    blueDown = true
  elseif (value == 9) then
    beacon = true
  elseif (value == 10) then
    redUp   = true
    redDown = true
  elseif (value == 11) then
    blueUp   = true
    blueDown = true
  end
  
  if (redUp ~= self._redUp) then
    self:onRedUp(redUp)
    self._redUp = redUp
  end
  if (redDown ~= self._redDown) then
    self:onRedDown(redDown)
    self._redDown = redDown
  end
  if (blueUp ~= self._blueUp) then
    self:onBlueUp(blueUp)
    self._blueUp = blueUp
  end
  if (blueDown ~= self._blueDown) then
    self:onBlueDown(blueDown)
    self._blueDown = blueDown
  end
  if (beacon ~= self._beacon) then
    self:onBeacon(beacon)
    self._beacon = beacon
  end
  
end

function RemoteControl:onRedUp(pressed)
end

function RemoteControl:onRedDown(pressed)
end
  
function RemoteControl:onBlueUp(pressed)
end

function RemoteControl:onBlueDown(pressed)
end

function RemoteControl:onBeacon(on)
end
</xsl:template>

</xsl:stylesheet>
