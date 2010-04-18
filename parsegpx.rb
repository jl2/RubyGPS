#!/usr/bin/ruby

# gpslibxml.rb

# Copyright (c) 2010, Jeremiah LaRocco jeremiah.larocco@gmail.com

# Permission to use, copy, modify, and/or distribute this software for any
# purpose with or without fee is hereby granted, provided that the above
# copyright notice and this permission notice appear in all copies.

# THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
# WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
# MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
# ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
# WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
# ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
# OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.

require 'utmconvert'

require 'xml'
require 'ap'
require 'time'

if ARGV.size==0 then
  puts "No argument given!"
  exit
end

doc = XML::Document.file ARGV[0]

doc.root.namespaces.default_prefix='gpx'

prev = nil
cur = nil
prevTime = nil
curTime = nil

def distance(c, p)
  dx, dy, dz = c[0]-p[0], c[1]-p[1], c[2]-p[2]
  Math::sqrt(dx*dx+dy*dy+dz*dz)
end

curMax = totDist = totTime = 0

# doc.find('//gpx:trk').each would be "better" code, but it must be written
# this way to avoid a seg-fault, as described at:
# http://libxml.rubyforge.org/rdoc/classes/LibXML/XML/Document.html#M000467
trks = doc.find('//gpx:trk')
trks.each do | trk |

  # Loop through each track segment
  segs = trk.find("gpx:trkseg")
  segs.each do | tseg |

    # Reset segment data
    prev = cur = nil
    totDist = totTime = curMax = 0

    # Loop through track points
    pts = tseg.find("gpx:trkpt")
    pts.each do | tpt |

      # Find the elevation and time for the point
      cele = tpt.find("gpx:ele/text()")[0].to_s.to_f
      ctime = Time::parse(tpt.find("gpx:time/text()")[0].to_s)

      # Convert lat/long to UTM
      utm = Utmconvert::to_utm(tpt.attributes['lat'].to_f, tpt.attributes['lon'].to_f)

      # TODO: stop being retarded and make a data structure to store this correctly
      cur = [utm.x, utm.y, cele, ctime]

      # Update incremental results if there was a previous point
      if prev then

        dist = distance(cur, prev)
        speed = dist / (cur[3]-prev[3])

        curMax = speed if speed > curMax
        totDist += dist
        totTime += (cur[3]-prev[3])
      end

      # Save current to previous
      prev = cur
    end
    pts = nil

    # Display track data
    if totDist > 0 and totTime > 0
      puts "Went %.3f meters in %.3f seconds, average speed was %.3f, maximum speed was %.3f" % [totDist, totTime, totDist/totTime, curMax] 
    end

  end
  segs = nil
end
trks = nil
