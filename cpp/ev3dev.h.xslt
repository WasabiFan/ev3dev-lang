<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
<xsl:output method="text" version="1.0" encoding="UTF-8" indent="no"/>

<!-- XSLT source file for generation of ev3dev.h -->

<xsl:template match="constant">  const std::string <xsl:apply-templates select="name"/> { "<xsl:value-of select="value"/>" };
</xsl:template>

<xsl:template match="name">
<xsl:choose>
  <xsl:when test="../lower"><xsl:value-of select="../lower"/></xsl:when>
  <xsl:otherwise><xsl:value-of select="../attribute"/></xsl:otherwise>
</xsl:choose></xsl:template>

<xsl:template match="type">
<xsl:choose>
  <xsl:when test=". = &quot;Number&quot;">int</xsl:when>
  <xsl:when test=". = &quot;String&quot;">std::string</xsl:when>
  <xsl:when test=". = &quot;String Array&quot;">std::set&lt;std::string&gt;</xsl:when>
  <xsl:otherwise><xsl:value-of select="."/></xsl:otherwise>
</xsl:choose></xsl:template>

<xsl:template match="property/constant">  static const std::string <xsl:apply-templates select="../name"/>_<xsl:apply-templates select="name"/> { "<xsl:value-of select="value"/>" };
</xsl:template>

<xsl:template match="read">
  <xsl:apply-templates select="../type"/>_<xsl:apply-templates select="../name"/>() const { return get_attr_<xsl:apply-templates select="../type"/>("<xsl:apply-templates select="../attribute"/>"); }
</xsl:template>

<xsl:template match="write">
void set_<xsl:apply-templates select="../name"/>(<xsl:apply-templates select="../type"/> value) { set_attr_<xsl:apply-templates select="../type"/>("<xsl:apply-templates select="../attribute"/>", value); }
</xsl:template>

<xsl:variable name="delimiter">
------------------------------------------------------------------------------
</xsl:variable>

<xsl:template match="spec">/*
 * C++ API to the sensors, motors, buttons, LEDs and battery of the ev3dev
 * Linux kernel for the LEGO Mindstorms EV3 hardware
 *
 * Copyright (c) 2014 - Franz Detro
 *
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
 *
 * Modification:
 *  Add new button management for ev3dev Release 02.00.00 (ev3dev-jessie-2014-07-12) - Christophe Chaudelet
 *
 */

#pragma once

//-----------------------------------------------------------------------------

#include &lt;map&gt;
#include &lt;set&gt;
#include &lt;string&gt;
#include &lt;functional&gt;

//-----------------------------------------------------------------------------

namespace ev3dev {

//-----------------------------------------------------------------------------
  
typedef std::string         device_type;
typedef std::string         port_type;
typedef std::string         mode_type;
typedef std::set&lt;mode_type&gt; mode_set;
typedef std::string         address_type;

//-----------------------------------------------------------------------------

const port_type INPUT_AUTO;          //!&lt; Automatic input selection
const port_type INPUT_1  { "in1" };  //!&lt; Sensor port 1
const port_type INPUT_2  { "in2" };  //!&lt; Sensor port 2
const port_type INPUT_3  { "in3" };  //!&lt; Sensor port 3
const port_type INPUT_4  { "in4" };  //!&lt; Sensor port 4
 
const port_type OUTPUT_AUTO;         //!&lt; Automatic output selection
const port_type OUTPUT_A { "outA" }; //!&lt; Motor port A
const port_type OUTPUT_B { "outB" }; //!&lt; Motor port B
const port_type OUTPUT_C { "outC" }; //!&lt; Motor port C
const port_type OUTPUT_D { "outD" }; //!&lt; Motor port D

//-----------------------------------------------------------------------------

class device
{
public:
  bool connect(const std::string &amp;dir,
               const std::string &amp;pattern,
               const std::map&lt;std::string,
                              std::set&lt;std::string&gt;&gt; match) noexcept;
  inline bool connected() const { return !_path.empty(); }

  int         device_index() const;
  
  int         get_attr_int   (const std::string &amp;name) const;
  void        set_attr_int   (const std::string &amp;name,
                              int value);
  std::string get_attr_string(const std::string &amp;name) const;
  void        set_attr_string(const std::string &amp;name,
                              const std::string &amp;value);

  std::string get_attr_line  (const std::string &amp;name) const;
  mode_set    get_attr_set   (const std::string &amp;name,
                              std::string *pCur = nullptr) const;
  
  std::string get_attr_from_set(const std::string &amp;name) const;
  
protected:
  std::string _path;
  mutable int _device_index = -1;
};

<xsl:apply-templates select="constant"/>

<xsl:for-each select="class">
//-----------------------------------------------------------------------------

class <xsl:apply-templates select="name"/> : protected device
{
public:
<xsl:if test="constant | */constant">
<xsl:apply-templates select="constant"/>
<xsl:apply-templates select="*/constant"/></xsl:if>

  using device::connected;
  using device::device_index;

<xsl:for-each select="property">
<xsl:apply-templates select="read"/>

<xsl:apply-templates select="write"/>
</xsl:for-each>
};

</xsl:for-each>
//-----------------------------------------------------------------------------

class button
{
public:
  button(int bit);
  ~button()
  {
    delete _buf;
  }
  
  bool pressed() const;
  
  static button back;
  static button left;
  static button right;
  static button up;
  static button down;
  static button enter;

private:
  int _bit;
  int _fd;
  int _bits_per_long;
  unsigned long *_buf;
  unsigned long _buf_size;

};

//-----------------------------------------------------------------------------

class sound
{
public:
  static void beep();
  static void tone(unsigned frequency, unsigned ms);
  
  static void play (const std::string &amp;soundfile, bool bSynchronous = false);
  static void speak(const std::string &amp;text, bool bSynchronous = false);
  
  static unsigned volume();
  static void set_volume(unsigned);
};

//-----------------------------------------------------------------------------

class lcd
{
public:
  lcd();
  ~lcd();

  bool available() const { return _fb != nullptr; }

  uint32_t resolution_x()   const { return _xres; }
  uint32_t resolution_y()   const { return _yres; }
  uint32_t bits_per_pixel() const { return _bpp; }

  uint32_t frame_buffer_size() const { return _fbsize; }
  uint32_t line_length()       const { return _llength; }
  
  unsigned char *frame_buffer() { return _fb; }
  
  void fill(unsigned char pixel);
  
protected:
  void init();
  void deinit();
  
private:
  unsigned char *_fb;
  uint32_t _fbsize;
  uint32_t _llength;
  uint32_t _xres;
  uint32_t _yres;
  uint32_t _bpp;
};

//-----------------------------------------------------------------------------

class remote_control
{
public:
  remote_control(unsigned channel = 1);
  remote_control(infrared_sensor&amp;, unsigned channel = 1);
  virtual ~remote_control();
  
  inline bool   connected() const { return _sensor-&gt;connected(); }
  inline unsigned channel() const { return _channel+1; }

  bool process();

  std::function&lt;void (bool)&gt; on_red_up;
  std::function&lt;void (bool)&gt; on_red_down;
  std::function&lt;void (bool)&gt; on_blue_up;
  std::function&lt;void (bool)&gt; on_blue_down;
  std::function&lt;void (bool)&gt; on_beacon;
  
protected:
  virtual void on_value_changed(int value);
  
  enum
  {
    red_up    = (1 &lt;&lt; 0),
    red_down  = (1 &lt;&lt; 1),
    blue_up   = (1 &lt;&lt; 2),
    blue_down = (1 &lt;&lt; 3),
    beacon    = (1 &lt;&lt; 4),
  };
  
protected:
  infrared_sensor *_sensor = nullptr;
  bool             _owns_sensor = false;
  unsigned         _channel = 0;
  int              _value = 0;
  int              _state = 0;
};

//-----------------------------------------------------------------------------

} // namespace ev3dev

//-----------------------------------------------------------------------------
</xsl:template>

</xsl:stylesheet>
