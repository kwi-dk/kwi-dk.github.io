#charset "us-ascii"

#include <adv3.h>
#include <en_us.h>

/* ------------------------------------------------------------------------ */
/*  This is a demo of how to implement an Indiana Jones style puzzle
 *  in TADS 3. More specifically, this game demonstrates the following:
 *. - Using the weight of items to implement a scale. (The Scale class.)
 *. - Using bulk to keep items from being put in a container. (The coin bag.)
 *. - Creating bag of holdings for special types of items. (The coin bag.)
 *. - Creating a simple exit that leads nowhere. (The south-exit of the cave.)
 *. - Using a special desc with a lister-object to list contents.
 *    (The Scale class.)
 *. - Using international characters in the version info. (\u00F8, below. :)
 *
 *  Feel free to grab what you want from this code.
 */

versionInfo: GameID
    name = 'Indiana Jones style puzzle'
    byline = 'by S\u00F8ren J.\ L\u00F8vborg'
    htmlByline = 'by <a href="mailto:web@kwi.dk">S\u00F8ren J.\ L\u00F8vborg</a>'
    version = '1.1a'
    authorEmail = 'S\u00F8ren J.\ L\u00F8vborg <web@kwi.dk>'
    desc = 'A demonstration of certain TADS 3 featurs.'
    htmlDesc = (desc)

    showCredit()
    {
        "Copyright 2003 by S\u00F8ren J.\ L\u00F8vborg.\n
         <A href='http://www.kwi.dk/if/'>http://www.kwi.dk/if/</A>\b";
    }
    showAbout()
    {
        "Posted on RAIF, July 2, 2003:\b
        <TABLE width=95% align=center><TR><TD>
[...] Akin to something out of Indiana Jones, you stand before a contraption that is essentially a set of scales.\b
You possess 3 gold, 3 silver, and 3 copper coins.  Each type of coin has a different weight.  You also have a coin bag.\b
On one scale sits an ornate antiquity.  The other scale is empty.\b
[By solving the puzzle], the scales balance out perfectly, and the centre of the scales open up to reveal a ruby!\b
If any other action is performed on the scales, such as the ornate antiquity being removed, or the wrong total weight of coins used, or the coins are not safely dropped on to the empty scale together, then dire consequences ensue!\b
I would really love to see this example implemented in as many IF authoring systems that are available.  I would be really interested to see the different methods employed.\b
Best regards from Robert.\b
Advanced optional footnote:  if, for instance, a \"widget\" was *exactly* the same weight as say a silver coin, then if you were to place 3 gold coins, 1 silver coin, 1 widget, and 1 copper coin in to the coin bag, the result would work perfectly.  And so on, and so forth.\b
Advanced optional footnote 2:  the cavern floor contains several \"widgets\", all weighing exactly the same as one silver coin.  However, only one widget, a silver widget, is of a suitable size to fit inside the coin bag along with the rest of the other coins - all the other widgets would be too large.
        </TABLE>";
    }
;

/* ------------------------------------------------------------------------ */
/*
 *  Our basic Scale class, used for both the left and the right scale.
 */

class Scale: Surface
    weight = 0 /* We don't want the weight of the scale to count. */
    aName = ( theName )

    /* Here's some fancy (but not required) code. */
    contentsListed = nil // We provide our own contents list.

    /* Here we customize the lister that shows our contents. */
    descContentsLister: surfaceDescContentsLister {
        showListEmpty(pov, parent) { "\^<< parent.theNameObj >> is empty. "; }
        
        showListPrefixWide(itemCount, pov, parent)
        { "On <<parent.theNameObj>> sits "; }
     
    }

    /* We are described on our own in room descriptions. */
    specialDesc() {
        descContentsLister.showList(me, self, contents, ListRecurse, 0,
                                    me.visibleInfoTable(), nil);    
    }
    /* End of fancy code. */
;    

/* ------------------------------------------------------------------------ */
/*
 *   This code stolen from the TADS 3 Sample Game.
 *   Besides declaring the three kinds of coins, it just makes
 *   everything a bit fancier. That is, the collective and the group
 *   isn't necessary for the puzzle.
 */

class Coin: Thing
    vocabWords_ = 'coin*coins'   /* singular 'coin', plural 'coins' */
    listWith = [coinGroup]

    collectiveGroup = coinCollective

    coinGroupBaseName = ''
    coinGroupName = ('one ' + coinGroupBaseName)
    countedCoinGroupName(cnt)
        { return spellIntBelow(cnt, 100) + ' ' + coinGroupBaseName; }
;

class CopperCoin: Coin 'copper -' 'copper coin'
    isEquivalent = true
    weight = 3
    coinGroupBaseName = 'copper'
;

class SilverCoin: Coin 'silver -' 'silver coin'
    isEquivalent = true
    weight = 10
    coinGroupBaseName = 'silver'
;

class GoldCoin: Coin 'gold -' 'gold coin'
    isEquivalent = true
    weight = 40
    coinGroupBaseName = 'gold'
;

coinGroup: ListGroupParen
    showGroupCountName(lst)
    {
        "<<spellIntBelowExt(lst.length(), 100, 0,
           DigitFormatGroupSep)>> coins";
    }

    /* List coins sorted by weight. */
    compareGroupItems(a, b) { return b.weight - a.weight; }

    showGroupItem(lister, obj, options, pov, info)
        { say(obj.coinGroupName); }
    showGroupItemCounted(lister, lst, options, pov, infoTab)
        { say(lst[1].countedCoinGroupName(lst.length())); }
;

coinCollective: ItemizingCollectiveGroup '*coins' 'coins';

/* * * End of fancy stuff which isn't really required * * */

/* ------------------------------------------------------------------------ */

cave: Room 'Cave'
    "The rocky stone walls of the cave surround you, the only exit
     being the tunnel you entered from, to the south.\n
     The ceiling of the cave is hidden in the darkness far above you.\b
     You stand before a contraption that is essentially a set of scales."

    south: TravelConnector {
        /*
         *  When the player wants to travel south, a TravelVia action
         *  is generated for this TravelConnector.
         */
        dobjFor(TravelVia)
        {
            check()
            {
                if (!ruby.isIn(me))
                {
                    "You can't leave now that you're so close!";
                    exit; /* Don't allow travel */
                }
            }
            action()
            {
                "Ruby in hand, you quickly make your way out of the cave.\b
                 <B>*** You have won ***</B>";
                finishGame([finishOptionUndo]);
            }
        }
    }
    
    roomAfterAction()
    {
        /*  We perform this check whenever the player does something.  */

        /*
         *  If the weight on the left scale has changed, kill the player.
         *  (Note that perforatePlayer() never returns.)
         */

        if (scale1.getWeight() != 200) perforatePlayer();
        
        /*  Okay, the player didn't touch scale1. Check scale 2.  */

        local w = scale2.getWeight();
        if (w == 0) return; /*  OK, but still didn't solve the puzzle.  */

        /*  Didn't put the correct weight on the scale.  */
        if (w != 143) perforatePlayer();
        
        /*  Puzzle solved.  */
        if (!ruby.location)
        {
            /*  The ruby hasn't appeared yet.  */
            "\b*click*\b
             The scales balance out perfectly, and the centre of
             the scales open up to reveal a ruby!";

            ruby.moveInto(self);  /*  Move the ruby into self (the cave.)  */
        }
    }
    perforatePlayer() {
        /*  The player has triggered the trap. End the game.  */
        
        "\b*click*\b
         Suddenly, hundreds of arrows shoot out from previously
         unnoticed holes in the walls.\n 
         Your perforated body falls lifeless to the cave floor.\b
         <B>*** You have died ***</B>";

        /* End the game, but allow the player to undo. */
        finishGame([finishOptionUndo]);
    }
;

/* ------------------------------------------------------------------------ */

+ Thing 'big widget*widgets' 'big widget'
    bulk = 5
    weight = 10
;

+ Thing 'small widget*widgets' 'small widget'
    weight = 10
;

+ scale1: Scale 'left scale*scales' 'left scale';

++ Thing 'ornate antiquity' 'ornate antiquity'
    /*
     *  The weight of the antiquity.  Could be any number,
     *  as long as it matches the number we check against
     *  in cave.roomAfterAction().
     */
    weight = 200
;

+ scale2: Scale 'right scale*scales' 'right scale'

    /* Show the right scale after the left one. (Fancy.) */
    specialDescOrder = 101 // The left scale defaults to 100.
;

+ me: Person
    /*
     *  If a coin can weigh 40, it seems a bit odd with an actor
     *  that weighs 10. So we change it, even though it doesn't
     *  matter.
     */
    weight = 1000
;

++ CoinBag: BagOfHolding, Container 'coin bag' 'coin bag'
    "It's a small bag for holding coins. "
    
    /*
     *   We prefer this:
     *.  You are carrying a coin bag. The coin bag contains nine coins
     *   (three gold, three silver, and three copper). 
     *
     *.  to this:
     *.  You are carrying a coin bag (which contains nine coins
     *   (three gold, three silver, and three copper)).
     */
    contentsListedSeparately = true

    weight = 0 /* We don't want the bag's weight to count. */
  
    /* We prefer to hold coins. */
    affinityFor(obj) {
        if (obj.ofKind(Coin)) return 200;
        return 50;
    }

    /*
     *  We can only fit objects with a bulk of 2 or less into this bag.
     *  All objects have a default bulk of 1.
     */
    canFitObjThruOpening(obj) {
        return obj.bulk <= 2;
    }
;

/* Put three coins of each type into the coin bag. */
+++ CopperCoin;
+++ CopperCoin;
+++ CopperCoin;
+++ SilverCoin;
+++ SilverCoin;
+++ SilverCoin;
+++ GoldCoin;
+++ GoldCoin;
+++ GoldCoin;

/*  The ruby starts outside the game world, that is, no location.  */
ruby: Thing 'ruby' 'ruby';

/* ------------------------------------------------------------------------ */

gameMain: GameMainDef
    initialPlayerChar = me

    showIntro()
    {
        "<TITLE>Indiana Jones puzzle</TITLE>
         Place 3 gold, 2 silver and 1 copper coins on to the empty scale at
         the same time.  (In order to safely place the coins on the empty
         scale at the same time, one must first place these 6 coins inside the
         coin bag.)";
    }
;
