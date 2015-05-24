#charset "us-ascii"
#include <tadsgen.h>

/* ------------------------------------------------------------------------ */
/*
 *  Miscellaneous functions
 *  -----------------------
 *  
 *  This is just a small collection of odd functions I've put together
 *  for various projects.
 *  Well, three projects.
 *
 *  All code converted to T3-code by yours truly.
 * 
 *  -- Søren J. Løvborg
 */

/* ------------------------------------------------------------------------ */
/*
 *  Fast integer square-root.
 *  Always rounds the result down. (sqrt(8) == 2.)
 *  Tested for values of x up to 256.
 *  No error-checking. (For negative x or x > 256.)
 *
 *  (Add rounding by calculating an extra bit? Hmm...)
 *
 */

function integerSquareRoot(x)
{
    local guess = 0x80;
    local bit = 0x80;
    
    for (local i = 8; i; i--)
    {
        local sq = guess * guess;
        if (x < sq) guess &= ~bit; // Clear this bit.
        bit >>= 1; // bit = bit/2
        guess |= bit; // Set the following bit.
    };
    return guess;
}

/* ------------------------------------------------------------------------ */
/*
 *  Decoding a Unix timestamp
 *
 *  Takes a Unix timestamp (number of seconds since January 1st, 1970)
 *  and returns [year, month, day, dayofweek, hour, minute, second].
 *  
 *  Can be used to decode, for instance, the "timer" returned by getTime().
 */

#define isLeapYear(year) ((year) % 4 == 0 && ((year) % 100 != 0 || (year) % 400 == 0))

function unpackTimestamp(stamp)
{
    local second = stamp % 60; stamp /= 60;
    local minute = stamp % 60; stamp /= 60;
    local hour   = stamp % 24; stamp /= 24;

    stamp += 1969*365 + 492 - 19 + 4; // days since "1 Jan, year 1"

    // Convert days since 1 Jan, year 1 to year/yearday
    local year = 400*(stamp/146097) + 1;
    local day = stamp % 146097;
    if (day == 146096) { year += 399; day = 365; } // Last year of 400 is long
    else
    {
        year += 100*(day/36524);
        day %= 36524;
        year += 4*(day/1461);
        day %= 1461;
        if (day == 1460) { year += 3; day = 365; } // Last year out of 4 is long
        else
        {
            year += day/365;
            day %= 365;
        }
    }

    if (!isLeapYear(year) && day >= 59) day++; // Skip non-existent Feb 29
    if (day >= 60) day++; // Skip non-existent Feb 30

    local month = ((day % 214)/61)*2 + ((day % 214) % 61)/31 + 1;
    if (day > 213) month += 7;
    day = ((day % 214) % 61) % 31 + 1;
    
    local dayofweek = (stamp + 1) % 7; // Day of week, 0==Sun
    return [year, month, day, dayofweek, hour, minute, second];
}

/*
 *  A simple function for finding the day of the week given a date.
 *  (Written by Tomohiko Sakamoto and taken from the C FAQ.)
 *  Takes a year (1752 or later), a month (1-12) and a day (1-31),
 *  and returns the weekday as an integer (0/Sun - 6/Sat).
 */
function dayofweek(y, m, d)
{
    if (m < 3) y--;
    return (y + y/4 - y/100 + y/400 + [0, 3, 2, 5, 0, 3, 5, 1, 4, 6, 2, 4][m] + d) % 7;
}

/* ------------------------------------------------------------------------ */
/*
 *  RGB to HSV conversion.
 *
 *  Takes a ColorRGB(r, g, b) value, returns a [h, s, v] list.
 *  Hue: 0-359  Sat: 0-100  Brightness: 0-100
 *  Obviously won't work for special colors (ColorStatusText etc.)
 */
 
#define ColorHSV(h, s, v) [h, s, v]

function RGBtoHSV(rgb)
{
    local r = rgb >> 16;
    local g = (rgb >> 8) & 0xFF;
    local b = rgb & 0xFF;

    local h;

    local min_ = min(r, g, b);
    local max_ = max(r, g, b);

    local delta = max_ - min_;
    
    /* Black? */
    if (max_ == 0) return ColorHSV(0, 0, 0);

    /* Grayscale? */
    if (delta == 0) h = 0;
    else
    {
        if (r == max_)       h = 0   + (g - b)*40/delta;  // yellow - magenta
        else if (g == max_)  h = 120  + (b - r)*40/delta; // cyan - yellow
        else /* b == max_ */ h = 240 + (r - g)*40/delta;  // magenta - cyan

        if (h < 0) h += 360;
    }
    
    return ColorHSV(h, delta * 100 / max_, max_*100/255);
}


/* ------------------------------------------------------------------------ */
/*
 *  Point in Polygon check.
 *
 *  http://geometryalgorithms.com/Archive/algorithm_0103/algorithm_0103.htm
 *
 *  Copyright 2001, softSurfer (www.softsurfer.com)
 *  This code may be freely used and modified for any purpose
 *  providing that this copyright notice is included with it.
 *  SoftSurfer makes no warranty for this code, and cannot be held
 *  liable for any real or imagined damage resulting from its use.
 *  Users of this code must verify correctness for their application.
*/

/*
 *  isLeft(): tests if a point is Left|On|Right of an infinite line.
 *
 *  Input:  three points P0 (x0, y0), P1 (x1, y1), and P2 (x2, y2)
 *  Return: >0 for P2 left of the line through P0 and P1
 *          =0 for P2 on the line
 *          <0 for P2 right of the line
 */

#define isLeft(x0, y0, x1, y1, x2, y2) \
    ((x1 - x0) * (y2 - y0) - (x2 - x0) * (y1 - y0))


/*
 *  pointInPoly: Winding number test for a point in a polygon.
 *
 *  Input:  P (px, py) = a point,
 *          V[] = vertex points of a polygon V[n+1] with V[n]=V[0],
 *                where n is the number of points.
 *                The coords are given in the form [x0, y0, x1, y1, ...]
 *
 *  Return: =0      if P is outside the polygon.
 *          =1, =-1 if P is inside the polygon.
 *          >1, <-1 if P is inside an area of the polygon where it overlaps itself.
 */
 
function pointInPoly(px, py, poly)
{
    local wn = 0;  // The winding number counter.

    // Loop through all edges of the polygon.
    for (local i = 1; i < poly.length() - 2; i += 2)
    {
        // The edge from V[i] to V[i+1].
        
        if (poly[i + 1] <= py) // V[i].y < P.y
        {
            if (poly[i + 3] > py)     // V[i + 1].y > P.y: An upward crossing.
                if (isLeft(poly[i], poly[i + 1],
                           poly[i + 2], poly[i + 3],
                           px, py) > 0) wn++; // P is left of edge. Have a valid up intersect.
        }
        else
        {
            // V[i].y >= P.y

            if (poly[i + 3] <= py)    // V[i+1].y <= P.y: A downward crossing.
                if (isLeft(poly[i], poly[i + 1],
                           poly[i + 2], poly[i + 3],
                           px, py) < 0) wn--; // P is right of edge. Have a valid down intersect.
        }
    }
    return wn;
}
