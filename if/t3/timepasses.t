#charset "us-ascii"

/*
 *   Time Passess Module 1.1
 *   -----------------------
 *
 *   Makes the default "Time passess..." message aware of the textual context.
 *   This allows exchanges like this:
 *   > z
 *.  Time passes...
 *.
 *.  > z
 *.  The phone starts ringing.
 *.
 *.  >
 *
 *   Or:
 *   > z
 *   You hesitate.
 *
 *   ---
 *
 *   To use this module, prefix any such "Time passes..." substitute texts
 *   with <.time>.
 *   One or more tags may come before <.time>, but no actual text.
 *
 *   These two outputs would suppress the "Time passes..." message:
 *.  <.p><.time>The phone starts ringing.
 *.  <B><BIG><.time>BOOM!</BIG></B>
 *
 *   This would not suppress the message, because of the quotation marks:
 *.  "<.time>Hello," Bob says.
 *
 *   But this would:
 *   <Q><.time>Hello,</Q> Bob says.
 *
 *   ---
 *
 *   Please note that you should not #include this file. Instead, you should
 *   add it to the build by adding this line to your makefile (.t3m):
 *   -source TimePasses.t
 *
 *   Or, if you use Workbench, simply select Project|Add file, and
 *   select TimePasses.t in the directory you've put it in.
 *
 *   ---
 *
 *   Copyright 2003 Soren J. Lovborg.
 *  
 *   Permission is hereby granted, free of charge, to any person obtaining a
 *   copy of this software and associated documentation files (the "Software"), 
 *   to deal in the Software without restriction, including without limitation 
 *   the rights to use, copy, modify, merge, publish, distribute, sublicense,
 *   and/or sell copies of the Software, and to permit persons to whom the
 *   Software is furnished to do so, subject to the following conditions:
 *  
 *   The above copyright notice and this permission notice shall be included in
 *   all copies or substantial portions of the Software.
 *  
 *   THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 *   IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 *   FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 *   AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 *   LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
 *   FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
 *   DEALINGS IN THE SOFTWARE.
 *
 */

/* ------------------------------------------------------------------------ */
/*
 * Include the library header, define our Module ID.
 */

#include "adv3.h"

moduleTimePasses: ModuleID
    name = 'Time Passes module'
    byline = 'by S\u00F8ren J.\ L\u00F8vborg'
    htmlByline =
      'by <a href="mailto:web@kwi.dk">S\u00F8ren J.\ L\u00F8vborg</a>'
    version = '1.1'

    /* This isn't a big module, so we'll display our version last */
    listingOrder = 200
;


/* ------------------------------------------------------------------------ */
/*
 *  Modify WaitAction so we just print the special <.wait> tag.
 */

modify WaitAction
    replace execAction()
    {
        "<.wait>";
    }
;

/* ------------------------------------------------------------------------ */
/*
 *  Our output filter (this is where the real work is done.)
 */

transient waitFilter: OutputFilter, PreinitObject
    /*
     *   Install the waitFilter between the senseContext filter and the 
     *   commandSequencer filter. We need to do this after those two
     *   have been installed, i.e. after  adv3LibPreinit  have run.
     */
    execBeforeMe = [adv3LibPreinit]
    execute()
    {
        mainOutputStream.addOutputFilterBelow(self, commandSequencer);
    }

    /*
     *   The filter has two states: normal and waiting.  In the normal
     *   state, a <.wait> tag puts the filter into waiting mode;
     *   otherwise, all text is passed through unchanged, except that
     *   the two tags are removed.  In the waiting state, the <.time>
     *   tag puts the filter into normal mode; any other text triggers
     *   the insertion of the default message "Time passes...<.p>",
     *   and puts the filter in normal mode.
     */

    waitingMode = nil
    
    patOurTags = static new RexPattern(
        '<nocase><langle><dot>(wait|time)<rangle>')
    patAnyTag  = static new RexPattern(
        '<nocase><langle>(<^rangle>|".*")*<rangle>')

    /*
     *   A tag doesn't cause "Time passes..." to be inserted, only
     *   actual text. Hence, we keep tags until we know whether
     *   to display Time passes... or not.
     */
    tagText = ''

    filterText(ostr, txt)
    {
        local ret = '';
        local match;
        
        while ((match = rexMatch(patAnyTag, txt)) != nil && rexMatch(patOurTags, txt) == nil)
        {
             /*
              *   As long as there's tags at the beginning of the line,
              *   move them from txt to tagText.
              *   (With the exception of <.wait> and <.time>.)
              */
             tagText += txt.substr(1, match);
             txt = txt.substr(match + 1);         
        }

        /* scan for tags */
        while (txt != '')
        {
            local textToAdd;
            
            if ((match = rexSearch(patOurTags, txt)) != nil)
            {
                /*  
                 *    Add the text up to <.wait> / <.time> to our result
                 *    variable, then delete the text up to and including
                 *    the tag, from txt.
                 */
                textToAdd = txt.substr(1, match[1] - 1);
              
                txt = txt.substr(match[1] + match[2]);
            }
            else
            {
                textToAdd = txt;
                txt = '';
            }

            if (waitingMode && textToAdd != '')
            {
               /*
                *   There's text to add, but also a waiting
                *   "Time passes..." messsage.
                */
                ret += playerActionMessages.timePasses + '<.p>';
                waitingMode = nil;
            }

            if (match)
            {
                /*   
                 *   We can't change the waitingMode flag until now,
                 *   because it shouldn't affect how we add the
                 *   preceding text.
                 */
                if (rexGroup(1)[3] == 'wait') waitingMode = true;
                else waitingMode = nil;
            }

            /*  Add any waiting tags to our result variable.  */
            if (tagText != '')
            {
                ret += tagText;
                tagText = '';
            }

            /*  Add the text to our result variable.  */
            ret += textToAdd;
        }
        
        return ret;
    }
;
