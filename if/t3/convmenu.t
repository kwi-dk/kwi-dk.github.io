#charset "us-ascii"

/*
 *   ConvMenu Module 1.1a (rev. 04/04/26)
 *   -----------------------------------
 *   ConvMenu implements a menu interface to the conversational commands,
 *   Ask, Ask For, Tell, Show, Give, Yes and No, and special topics.
 *   It is meant to be used "on top" of the standard library's own
 *   topic handling, with TopicEntry and the like.
 *
 *   Usage is simple: Basically, all TopicEntries (except Give and Show)
 *   needs a menuCaption, which should be a either a single or a double-quoted
 *   string, or a menuCaptionList, which should be a list of single-quoted
 *   strings.
 *   YesTopic and NoTopic already have default captions of "Yes." and "No."
 *   respectively, but you can of course override these for specific entries.
 *   The new MenuTopic class can only be picked using the menu, but otherwise
 *   works like any other TopicEntry.
 *
 *   For any TopicEntries where you use a regular expression match, you'll
 *   have to override isMatchPossible or convMenuShow so the topic entry only
 *   shows up when appropriate.
 *   (When overriding convMenuShow, be sure to call inherited.)
 *
 *   Entries matching game-world objects or topic objects, and entries that
 *   already has a functional isMatchPossible, won't need any further changes.
 *
 *   One exception is when you have multiple entries matching the same object,
 *   and use matchScore to "disambiguate" between them. Here, too, you have to
 *   make sure isActive works as appropriate, as the conversation menu
 *   (by default) shows all active topics, not caring if two of them share
 *   the same matchObj.
 *
 *   Topic-suggestions are not used anywhere in this module.
 *   The reason is that the menu should generally cover all possible topics,
 *   and hence there's no reason to clutter things by adding an extra
 *   SuggestedTopic for every TopicEntry.
 *   The only exception is that  limitSuggestions  in convNodes is used
 *   to limit which entries show up in the menu.
 *   If limitSuggestions is true in the current convNode, only topic entries
 *   from that node will be shown.
 *
 *   Examples
 *   --------
 *   (Adapted from the examples in the technical article on TADS 3 NPCs.)
 *
 *   This entry will only show up if the player knows (has seen) the antenna:
 *
 *.  AskTellTopic @antenna
 *.      "<q>Have you been to the antenna?</q> you ask.
 *.       <.p><q>I climbed it once,</q> Bob says. <q>It's pretty scary
 *.       up there. Great view of the city, though.</q> "
 *.      menuCaption = "Have you been to the antenna?"
 *.  ;
 *
 *
 *   This entry can't (for obvious reasons) be shown as a menu entry:
 *
 *.  AskTellTopic '<alpha><digit>{3}'
 *.      "<q>Does the sequence <q><< gTopic.getTopicText() >></q>
 *.       mean anything to you?</q>
 *.       <.p><q>That sounds like a keypad code down at the
 *.       ferry terminal.</q> "
 *.  ;
 *
 *   Instead you'll have to use a more old-fashioned approach:
 *
 *.  AskTellTopic @noteWithNumber
 *.      "<q>Does the sequence <q>123</q> mean anything to you?</q>
 *.       <.p><q>That sounds like a keypad code down at the
 *.       ferry terminal.</q> "
 *.      menuCaption = "Does the sequence <q>123</q> mean anything to you?"
 *.  ;
 *
 *   
 *   In the technical article, you'll also find this example:
 *
 *.  AskTellTopic @lighthouse
 *.    "This is the general case..."
 *.  ;
 *.  AskTellTopic +110 @lighthouse
 *.    "This is the more specific case..."
 *.    isActive = (lighthouse.fireStarted)
 *.  ;
 *
 *   This works fine using ASK/TELL; if the second is active, it'll be
 *   chosen, otherwise the first will be chosen.
 *   Using the menu, though, both entries will be available if the second
 *   is active. You'll have to add   isActive = (!lighthouse.fireStarted)
 *   to the first for this to work. (Of course, you may want both of them
 *   to show up. In that case, there's no problem.)
 *
 *   Or you could use AltTopics - ConvMenu handles those perfectly well.
 *
 *   Tip: Use a template
 *   -------------------
 *   A template can make it a lot easier to specify a menuCaption:
 *
 *.  TopicEntry template
 *.      "menuCaption" | [menuCaptionList]
 *.      +matchScore?
 *.      @matchObj | [matchObj] | 'matchPattern'
 *.      "topicResponse" | [eventList] ?;
 *.
 *.  MiscTopic template 'menuCaption' "topicResponse" | [eventList] ?;
 *   
 *   (The MiscTopic template must specify menuCaption using single-quoted
 *   strings - otherwise the template would be ambigous. This also applies
 *   to MenuTopic as it inherites from MiscTopic.)
 *
 *.  AskTellTopic "That lighthouse..." @lighthouse
 *.    "<q>That lighthouse...</q> you say, ..."
 *.  ;
 *
 *   (The reason why this isn't included in this module is simple:
 *   Templates must be specified in every source-file it's used in.
 *   Or, more commonly, put in a header-file like adv3.h,
 *   which is then #included in every source-file.
 *
 *   I couldn't be bothered to ship an extra file containing just those two
 *   templates, so you'll have to either create a header-file yourself, or
 *   add it to adv3.h. Whichever you prefer.)
 *
 *   ---
 *
 *   Copyright 2003-04 Soren J. Lovborg.
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
 * Include the library headers, define our Module ID.
 */

#include "adv3.h"
#include "en_us.h"
#define false nil

moduleConvMenu: ModuleID
    name = 'ConvMenu module'
    byline = 'by S\u00F8ren J.\ L\u00F8vborg'
    htmlByline =
      'by <a href="http://kwi.dk/">S\u00F8ren J.\ L\u00F8vborg</a>'
    version = '1.1a'

    /* This is a medium-size module, so the module gets a medium priority */
    listingOrder = 130
;

/* ------------------------------------------------------------------------ */
/*
 *  The conversationBanner object does most of the work.
 */

conversationBanner: BannerWindow, InitObject
    /* The currently active interlocutor */
    interlocutor = nil

    /*
     *  List of currently shown topics.
     */
    shownTopics = []
    
    /*
     * The opening text of the banner window
     * (this is where you can customize the colours.)
     */
    bannerStart = "<BODY bgcolor=statusbg text=statustext>"

    /* Message shown when an invalid number is typed */
    choiceOutOfRangeMsg = 'That is not one of the options. '
    
    /*
     *  Message shown when a topic entry is invalidated between the printing
     *  of the menu and the invocation of the topic entry.
     */
    choiceNoLongerValidMsg =
        'That is no longer a valid option. Choose another. '
    
    /* Returns the current interlocutor */
    getInterlocutor()
    {
        if (interlocutor && gPlayerChar.canTalkTo(interlocutor))
            return interlocutor;

        /* See if there are any actors we can speak to. */
        local tbl = gPlayerChar.connectionTable.keysToList();
        local actor = nil;

        foreach (local obj in tbl)
        {
            /* Is this obj an NPC? */
            if (!obj.ofKind(Actor)
                || obj == gPlayerChar
                || !gPlayerChar.canTalkTo(obj)) continue;

            if (actor)
            {
                 /*
                  *  We already found another actor, i.e. the player character
                  *  can talk to two or more actors. The player will have to
                  *  explicitly choose one using TALK TO.
                  */
                interlocutor = nil;
                return nil;
            } 

            /*
             *  Note that we've found a possible interlocutor, but keep
             *  looking.
             */
            actor = obj;
        }
        interlocutor = actor;
        return actor;
    }

    /* Finds valid topics, returns list. */    
    findTopics()
    {
        local actor;
        if (!gPlayerChar || !(actor = getInterlocutor())) return [];

        local scope = gPlayerChar.scopeList;
        local topics = actor.getTopicList().subset({x: x.convMenuShow(scope)});

        /* Sort found topics by matchScore (and secondly by sourceTextOrder) */
        topics.sort(true,
            {a, b: a.adjustScore((a.matchScore << 16) - a.sourceTextOrder)
              - b.adjustScore((b.matchScore << 16) - b.sourceTextOrder)}
        );

        /*
         *  See if any of the topic entries may be hidden to keep the size of
         *  the menu down.
         */
        for (local i = topics.length(); i >= 1; i--)
        {
            if (topics.length() > topics[i].hideForLongMenu)
                topics.removeElementAt(i);
        }

        return topics;
    }

    /* Update the banner - this is called by a PromptDaemon every turn */
    update()
    {
        shownTopics = findTopics();
        local height = shownTopics.length();

        show(height);
        if (height == 0) return;
        
        /*
         *  We have to capture output, since some topic entries may use
         *  double-quoted strings to display their menu text.
         */

        local stream = setOutputStream();
        try
        {
            bannerStart();
            for (local i = 1; i <= height; i++)
            {
                "<< i >>. <A plain href=\"<< i >>\">
                 << shownTopics[i].showMenuCaption() >></A>\n";
            }
        }
        finally
        {
           outputManager.setOutputStream(stream);
        }
        sizeToContents();
    }

    /* Show the banner - override this to change the position, for instance */
    show(height)
    {
        if (height == 0) removeBanner();
        else
        {
            showBanner(nil, BannerLast, nil, BannerTypeText,
                BannerAlignBottom, height, BannerSizeAbsolute,
                BannerStyleBorder);
            clearWindow();
        }
    }

    /* During initialization, set up a prompt daemon to update the banner */
    execute()
    {
        new PromptDaemon(self, &update);
    }

    /* This gets called when the player types a number */
    chooseTopic(number)
    {
        if (number < 1 || number > shownTopics.length())
        {
            reportFailure(choiceOutOfRangeMsg);
            gAction.zeroActionTime();
            return;
        }

        local resp = shownTopics[number];
        local freshMenu = conversationBanner.findTopics();
        if (!freshMenu.indexOf(resp))
        {
            if (!gActor.canTalkTo(interlocutor))
            {
                reportFailure(&objCannotHearActorMsg, interlocutor);
            }
            else
            {
                reportFailure(choiceNoLongerValidMsg);
                gAction.zeroActionTime();
            }
            return;
        }

        gActor.noteConversation(interlocutor);

        /* 
         *   Tell the conversation manager about the responding actor.
         *   If the response doesn't explicitly set a new conversation
         *   node, then we want to leave the conversation tree entirely
         *   by default, so set the new default node to 'nil'. 
         */
        conversationManager.beginResponse(interlocutor);
            
        resp.activateViaMenu();

        conversationManager.finishResponse(interlocutor, nil);
    }
;

/* ------------------------------------------------------------------------ */
/*
 *  Some modifications to existing library classes, and a new topic entry.
 */


/*
 *  We use this class for changing menu-captions.
 *  It's synchronized with the TopicEntry's list, but calling its
 *  doScript won't advance either script.
 */
class MenuCaptionList: ExternalEventList, SyncEventList;

modify TopicDatabase
    /*
     *  Return all topic-entry objects, forming the basis for the menu.
     *  Note that we don't collect suggestedTopics, as they're not real
     *  TopicEntry objects. (And this module doesn't use suggestions.)
     *  Finally, we don't collect initiateTopics, as the player can't
     *  choose them normally.
     */

    collectAllTopics(vec)
    {
        foreach (local prop in [&askTopics, &tellTopics, &showTopics,
                    &askForTopics, &giveTopics,&miscTopics, &specialTopics])
        {
            if (self.(prop)) vec.appendAll(self.(prop));
        }
    }
;

/*
 *  Arr! There be hacks!
 *
 *  When we're in a ConversationReadyState, we want to show HelloTopics, but
 *  not ByeTopics.
 */
modify ConversationReadyState
    collectAllTopics(vec)
    {
        local v = new Vector(5);
        inherited(v);
        vec.appendAll(v.subset({t: !t.ofKind(ByeTopic)}));
    }
;

/*
 *  When we're in an InConversationState, we want to show the ByeTopics of
 *  the ConversationReadyState.
 */
modify InConversationState
    collectAllTopics(vec)
    {
        inherited(vec);
        if (!nextState) return;
        
        foreach (local prop in [&askTopics, &tellTopics, &showTopics,
                    &askForTopics, &giveTopics,&miscTopics, &specialTopics])
        {
            if (nextState.(prop))
                vec.appendAll(nextState.(prop).
                    subset({t: t.ofKind(ByeTopic)}));
        }
    }
;

modify TopicEntry
    /*
     *  The menu caption for a TopicEntry can be specified in three ways:
     *. 1) As a single or double quoted string in menuCaption.
     *. 2) As a list of single-quoted strings in menuCaptionList.
     *. 3) As a Script object in menuCaptionScript (which should usually
     *     inherit from MenuCaptionList.)
     *
     *  If the second case (list of single-quoted strings), a MenuCaptionList
     *  is created as a wrapper and placed in menuCaptionScript automatically.
     */
    menuCaption = nil
    menuCaptionList = nil
    menuCaptionScript()
    {
        if (!menuCaptionList) return nil;
        menuCaptionScript = new MenuCaptionList(menuCaptionList);
        menuCaptionScript.masterObject = self;
        return menuCaptionScript;
    }
    
    /* Print the menu-caption */
    showMenuCaption()
    {
        if (menuCaptionScript != nil)
        {
            /*
             *  Let the menuCaptionScript (which may have been created
             *  automatically from menuCaptionList) display the caption.
             */
            menuCaptionScript.doScript();
        }
        else
        {
            /*
             *  Simply print the menuCaption.
             *  Note that menuCaption may be either single or double-quoted.
             */
            say(menuCaption);
        }
    }

    /*
     *  Determine if we are to be shown in the conversation menu.
     *
     *  By default, the following must be true for us to show up:
     *
     *.  + The entry's checkIsActive returns true.
     *.  + The entry's isMatchPossible returns true.
     *.  + We provide a caption, either through menuCaption or through
     *     menuCaptionList.
     *.  + Our talkCount is less than our showCount.
     *
     *   By default, showCount returns the numner of strings in our 
     *   menuCaptionList list, or 1 if we don't have such a list.
     *   (The number of possible replies from the TopicEntry's script is
     *   assumed to be the same as the number of strings in menuCaptionList.)
     */

    showCount = (menuCaptionList ? menuCaptionList.length() : 1)
    
    convMenuShow(playerCharScopeList)
    {
        return (menuCaptionList != nil || propDefined(&menuCaption))
            && talkCount < showCount
            && checkIsActive()
            && isMatchPossible(gPlayerChar, playerCharScopeList);
    }
    
    /*
     *  If the number of items in the menu is > hideForLongMenu,
     *  we hide this item.
     *  We start at the bottom of the menu (with the lowest scoring items)
     *  removing items until the length is less than the lowest
     *  hideForLongMenu of all shown menu-items.
     *  This way, a lot of unimportant topic entries can have a smaller
     *  hideForLongMenu-value, removing them if there's not enough room,
     *  and leaving the more important items.
     *
     *  The default 16 should ensure that the menu can always be shown on a
     *  text-interpreter's limited 80x25 display, even with statusline etc.
     */
    hideForLongMenu = 16
    
    activateViaMenu()
    {
        handleTopic(gActor, nil);
    }
;

modify HelloTopic
    activateViaMenu()
    {
        inherited();
        local actor = getActor();

        if (actor.curState.inConvState)
            actor.setCurState(actor.curState.inConvState);
    }
    showCount = 1000000000 /* Always show */
;

modify ByeTopic
    activateViaMenu()
    {
        inherited();
        local actor = getActor();
        if (actor.curState.nextState)
            actor.setCurState(actor.curState.nextState);
    }
    showCount = 1000000000 /* Always show */
;

/*
 *  MenuTopic - a TopicEntry that is only accessible from the menu.
 */
 
MenuTopic: MiscTopic
    includeInList = [&miscTopics]

    /* Match nothing - We can only be picked from the menu */
    matchTopic(fromActor, obj)
    {
        return false;
    }
;

modify YesTopic menuCaption = "Yes.";
modify NoTopic  menuCaption = "No.";

modify Actor
    /*
     *  If I'm the player character, set the banner's current interlocutor
     *  to the other actor.
     */
    noteConvAction(other)
    {
        if (self == gPlayerChar)
            conversationBanner.interlocutor = other;
        inherited(other);
    }

    noAvailableTopicsMsg = 'You can\'t think of anything to say to
                            {the dobj/him} at the moment. '
    

    alreadyActiveInterlocutorMsg = '<.parser>You are already talking to
                                 {the dobj/him}. <./parser>'
                 
    dobjFor(ChooseInterlocutor)
    {
        preCond = [canTalkToObj]
        verify()
        {
            if (!gActor.isPlayerChar) reportFailure(&systemActionToNPCMsg);
            else
            {
                /* Assume the player wants to talk to some *other* NPC now. */
                if (self == conversationBanner.interlocutor)
                    logicalRank(50, '');

                /*
                 *  We do not disambiguate by checking if there are any
                 *  available conversation menu options for the actor
                 */
            }
        }
        action()
        {
            local oldInterlocutor = conversationBanner.interlocutor;
            conversationBanner.interlocutor = self;

            /*
             *  Note that we check if we have any available topics before
             *  complaining if the actor is already the active interlocutor.
             */
            if (conversationBanner.findTopics().length() == 0)
                defaultReport(noAvailableTopicsMsg);
            else if (self == oldInterlocutor)
                defaultReport(alreadyActiveInterlocutorMsg);
            else "<.p>";
        }
    }
    
    getTopicList()
    {
        local vec = new Vector(32);
        local node;

        /* add the actor's current conversation node topics */
        if ((node = curConvNode) != nil)
        {
            node.collectAllTopics(vec);

            /* 
             *   if this ConvNode is marked as limiting suggestions to
             *   those defined within the node, return what we have
             *   without adding anything from the broader context 
             */
            if (node.limitSuggestions) return vec.getUnique();
        }

        curState.collectAllTopics(vec);
        collectAllTopics(vec);

        return vec.getUnique();
    }
;

/* ------------------------------------------------------------------------ */
/*
 *  New actions: NumberCommand and ChooseInterlocutor.
 *  We also modify the library's TalkTo VerbRule.
 *
 *  NumberCommand handles any positive single number on the command line.
 *  ActualTalkTo handles 'talk to X' and 't X', leaving 'greet' etc. to
 *  the original TalkTo.
 */

DefineLiteralAction(NumberCommand)
    execAction()
    {
        conversationBanner.chooseTopic(val);
    }
    resolveNouns(issuingActor, targetActor, results)
    {
        val = numMatch.getval();
    }
    val = nil
;

VerbRule(NumberCommand) singleNumber : NumberCommandAction
    verbPhrase = 'choose/choosing (what)'
;

DefineTAction(ChooseInterlocutor);

VerbRule(ChooseInterlocutor) 't' singleDobj | 'talk' 'to' singleDobj
    : ChooseInterlocutorAction
    verbPhrase = 'talk/talking to'
    actionTime = 0
;

modify VerbRule(TalkTo) ('greet' | 'say' 'hello' 'to') singleDobj : ;

/* ------------------------------------------------------------------------ */
