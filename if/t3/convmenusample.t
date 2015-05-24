#charset "us-ascii"

#include <adv3.h>
#include <en_us.h>

/* ------------------------------------------------------------------------ */
/*
 *  Define the two templates as suggsted in convmenu.t.
 */

TopicEntry template
    "menuCaption" | [menuCaptionList]
    +matchScore?
    @matchObj | [matchObj] | 'matchPattern'
    "topicResponse" | [eventList] ?;

MiscTopic template 'menuCaption' "topicResponse" | [eventList] ?;

/* ------------------------------------------------------------------------ */
/*
 *  The usual game stuff - versionInfo and gameMain objects.
 */

versionInfo: GameID
    name = 'ConvMenu Demo'
    byline = 'by S\u00F8ren J.\ L\u00F8vborg'
    htmlByline =
      'by <a href="mailto:web@kwi.dk">S\u00F8ren J.\ L\u00F8vborg</a>'
    version = '1.0'
    authorEmail = 'S\u00F8ren J.\ L\u00F8vborg <web@kwi.dk>'
    desc = 'A simple testbed for the ConvMenu module. '
    htmlDesc = (desc)

    showCredit()
    {
        "<b><< name >></b> << byline >> &endash; an interactive test!
         (How exciting!)\b
         Salesman lifted from the TADS 3 Sample Game by Mike J. Roberts.\b
         Herman Toothrot lifted from Monkey Island II by LucasArts.\b ";
    }
    showAbout()
    {
        "This game serves as a simple demonstration of the ConvMenu
         conversation menu module for TADS 3, << byline >>. ";
    }
;

gameMain: GameMainDef
    /* (Minimal.) */

    initialPlayerChar = me
;

/* ------------------------------------------------------------------------ */
/*
 *  A minimal game world.
 */

familiarPlace: Room 'A Familiar Place' 'familiar place'
    "This is indeed a familiar place.\n
     However, whatever lies behind the door to the south, is not familiar to you. Yet. "
    south = familiarPlaceDoor
;

+ me: Person;

+ familiarPlaceDoor: Door -> frontYardDoor 'door' 'door';


beach: OutdoorRoom 'Dinky Island Beach'
    "This is the picturesque beach of Dinky Island, home of the treasure of
     Big Whoop. "
    north = frontYard
;

+ Immovable 'sign' 'sign'
    "<q>Welcome to Dinky Island!</q> it reads in large types, then elaborates
     below: <q>Not Inky Island, Inky's Island, Gilligan's Island, but
     <i>Dinky</i> Island AKA the Dinky Peninsula.</q> "
    specialDesc = "A sign welcoming you to Dinky Island is here. "
;


frontYard: OutdoorRoom 'Front Yard'
    "This is a small yard in front of a modest house.  The front
    door to the house leads in to the north.  To the south is
    the beach. "

    north = frontYardDoor
    south = beach
;

+ frontYardDoor: Door 'door' 'door';

/* ------------------------------------------------------------------------ */
/*
 *  Ron, the insurance salesman.
 */

+ salesman: Person 'salesman/man/ron' 'salesman'
    isHim = true
;

++ ActorState
    isInitState = true
    specialDesc = "A youngish man in a garish suit is standing in
                   the yard near the front door. "

    takeTurn()
    {
        if (gPlayerChar.location == frontYard)
            salesman.initiateConversation(salesConv, 'sales-hello');
    }
;

++ salesConv: InConversationState
    attentionSpan = 10000
    nextState = salesWaiting
    stateDesc = "He's smiling eagerly at you. "
    specialDesc = "The salesman is standing a little too close,
                  smiling a bit too much. "
;

++ salesWaiting: ConversationReadyState
    specialDesc = "The salesman is standing in the yard. "

    inConvState = salesConv

    greetingList: ShuffledEventList {
    [
        'You tap the salesman on the shoulder.  <q>Oh, hi!</q> he says.
        <q>I\'d sure like to talk to you about life insurance.</q>
        <.convnode sales-1>'
    ]}

    enterFromConvList: ShuffledEventList {
    [
        'The salesman waves. <q>Okay, I\'ll wait here!</q> he says. ',
        '<q>Thanks for your time!</q> the salesman says. ',
        'The salesman calls after you, <q>I\'ll be here if you need me!</q> '
    ] }
    enterFromByeList: ShuffledEventList {
    [
        '<q>I have to go,</q> you say.
         <.p><q>Thanks for your time!</q> the salesman says. ',

         '<q>Thanks, but not right now,</q> you say.
         <.p><q>I\'ll be here when you\'re ready!</q> the salesman says. '
    ] }

    takeTurn()
    {
        /* re-arm for conversation only when the PC is gone */
        if (gPlayerChar.location != frontYard)
            regreet = true;

        /* greet again randomly if we're re-armed and the PC is present */
        if (regreet && gPlayerChar.location == frontYard && rand(100) < 33)
            salesman.initiateConversation(salesConv, 'sales-1');
    }

    /* flag: we're ready to re-greet the player */
    regreet = nil

    /* on activation, set the re-greet flag to nil by default */
    activateState(actor, oldState)
    {
        inherited(actor, oldState);
        regreet = nil;
    }
;

++ ConvNode 'sales-hello'
    npcGreetingMsg = "<.p>The man in the bad suit walks up to you and
                      extends his hand; by habit you shake his hand.
                      <q>Hello, friend!  My name is Ron, and I represent the
                      Acturial Life Insurance Company.</q> He releases
                      your hand after a vigorous shaking. <q>You know, a lot
                      of people I talk to don't know just how important life
                      insurance is to proper financial planning.  Let me
                      ask you this: do you have all the life insurance
                      coverage you and your family need?</q> "

    npcContinueList: EventList {
    [
        'The salesman says eagerly, <q>Really, do you have enough
        insurance?</q> ',
        
        'Ron says, <q>The sad fact is, most people <i>don\'t know</i>
        how much insurance they really need.  I\'d really like to
        tell you about our policies...</q><.convnode sales-1> '
    ]}
    limitSuggestions = true
;
+++ YesTopic 'I\'m covered.'
    "<q>I'm covered,</q> you say.
    <.p>Ron smiles and nods. <q>You know, a lot of people <i>think</i>
    they're covered. But have you really <i>read</i> your insurance
    policy?  Most insurance policies have so many exclusions and
    limitations that you just can't rely on them.  That's why
    Acturial Life created a new kind of insurance policy.  Let me
    tell you about it...</q><.convnode sales-1> "
;
+++ NoTopic 'Why, no.'
    "<q>Why, no,</q> you say.
    <.p>Ron smiles eagerly. <q>Well, then it's a good thing I was in
    your neighborhood today! Let me tell you about our policies...</q>
    <.convnode sales-1> "
;
++ ConvNode 'sales-1'
    npcGreetingMsg = "<.p>Ron walks up to you. <q>Hello again, friend!
                      It would be my pleasure to help you with your
                      insurance needs.</q> "

    npcContinueList: ShuffledEventList {
    ['The salesman looks serious for a moment. <q>Most people don\'t know
     this, but death is our number one killer,</q> he says earnestly.
     He goes back to smiling. <q>Fortunately, death is covered under
     our policy\'s loss-of-life section.</q> ',

     'Ron says, <q>You know, life insurance is a lot more interesting
     than most people think.</q> ',

     'The salesman says, <q>I\'m really glad I was in the neighborhood
     today.  Everyone needs more insurance than they think.</q> '
    ]}
;

++ AskTellTopic, StopEventList
    [ 'Okay, tell me about your policy.',
      'Tell me more about your policy.']
    @insPolicy
    [
        '<q>Okay, tell me about your policy,</q> you say.
        <.p><q>Our policy is the best in the business,</q> Ron says.
        <q>For starters, it\'s guaranteed go pay, which most policies
        aren\'t.  There\'s so much more I can tell you.</q> ',

        '<q>Tell me more about your policy,</q> you say.
        <.p><q>I could go on all day,</q> the salesman says. '
    ]
;

++ AskTellTopic, StopEventList
    ['I\'ve never heard of your company.',
     'Why would you want to keep your company a secret?',
     'What else can you tell me about your company?']

    @insCompany
    ['<q>I\'ve never heard of your company,</q> you say.
     <.p><q>Most people haven\'t,</q> Ron says. <q>We\'re the best-kept
     secret in the business.</q>',

     '<q>Why would you want to keep your company a secret?</q>
     <.p><q>One word: savings.  We save on marketing expenses, and
     pass the low cost on to you.</q> ',

     '<q>What else can you tell me about your company?</q>
     <.p><q>I\'d rather tell you about the policy.</q> ']
;

/* some topics for the salesman to talk about */
insPolicy: Topic 'life insurance policy/policies';
insCompany: Topic 'acturial life insurance company';

/* ------------------------------------------------------------------------ */
/*
 *  Herman Toothrot and his colour-koans.
 */

class ColorTopic: MenuTopic
    color = nil

    menuCaption = "<< color >>?"
    hideForLongMenu = 6

    topicResponse()
    {
        "<q><< color >>?</q> you try.
         <q><< rand('Nope', 'No', 'Nah', 'Not even close', 'Not exactly') >>.</q>
         <.convnode Koan>";
    }
;

ColorTopic template 'color';

herman: Person 'hermit/herman/toothrot' 'Herman' @beach
    isHim = true
    isProperName = true
;

/* ------------------------------------------------------------------------ */

+ ConvNode 'Koan'
    limitSuggestions = true
;
++ ColorTopic 'Brown';
++ ColorTopic 'Blue';
++ ColorTopic 'Forest Green';
++ ColorTopic 'Red';
++ ColorTopic 'Cyan';
++ ColorTopic 'Lavender';
++ ColorTopic 'Magenta';
++ ColorTopic 'Puce';
++ ColorTopic 'Aquamarine';
++ ColorTopic 'Taupe';
++ ColorTopic 'Burnt Sienna';
++ ColorTopic 'Raw Umber';
++ ColorTopic 'Sepia';
++ ColorTopic 'Mulberry';
++ ColorTopic 'Periwinkle';
++ ColorTopic 'Orchid';
++ ColorTopic 'Turquoise';
++ ColorTopic 'Peach';
++ ColorTopic 'Plum';
++ ColorTopic 'Aubergine';
++ ColorTopic 'Teal';
++ ColorTopic 'Mustard';
++ ColorTopic 'Cabernet';
++ ColorTopic 'Slate';
++ ColorTopic 'Smoke';
++ ColorTopic 'Brick';
++ ColorTopic 'Coral';
++ ColorTopic 'Chartreuse';
++ ColorTopic 'Cherry';
++ ColorTopic 'Wisteria';
++ ColorTopic 'Raspberry';
++ ColorTopic 'Vanilla';
++ ColorTopic 'Asparagus';
++ ColorTopic 'Cranberry';
++ ColorTopic 'Sangria';
++ ColorTopic 'Eggshell';
++ ColorTopic 'Driftwood';
++ ColorTopic 'Sumac';
++ ColorTopic 'Alpaca';
++ ColorTopic 'Storm Grey';
++ ColorTopic 'Evening Haze';
++ ColorTopic 'Tarragon';
++ ColorTopic 'Sachet';
++ ColorTopic 'Venetian';
++ ColorTopic 'Juniper';
++ ColorTopic 'Drizzle';
++ ColorTopic 'Sweet Potato';
++ ColorTopic 'Bayou';
++ ColorTopic 'Manilla';
++ ColorTopic 'Macintosh Grey';
++ ColorTopic 'Mange';
++ ColorTopic 'Sharkbite';
++ ColorTopic 'Sashimi Green';
++ ColorTopic 'Ebony';
++ ColorTopic 'Ivory';
++ ColorTopic 'Menthol';
++ ColorTopic 'Sahara';
++ ColorTopic 'Salmon';
++ ColorTopic 'Oxblood';
++ ColorTopic 'Khaki';
++ ColorTopic 'Fuchsia';
++ ColorTopic 'Robin\'s Egg';
++ ColorTopic 'Ash';
++ ColorTopic 'Spice';
++ ColorTopic 'Copper';
++ ColorTopic 'Weathered Pewter';
++ ColorTopic 'Vermillion';
++ ColorTopic 'Metallic Burgundy';
++ ColorTopic 'Russet';
++ ColorTopic 'Cadmium White';
++ ColorTopic 'Cerulean';
++ ColorTopic 'Thalocyanide Green';
++ ColorTopic 'Ochre';
++ ColorTopic 'Deep Purple';
++ ColorTopic 'Beryl';
++ ColorTopic 'Hot Pink';
++ ColorTopic 'Oatmeal Heather';
++ MenuTopic 'All colors?'
    "<q>All colors?</q> you finally try, exhausted.\n
     <q>Exactly!</q> Herman says with glee.\n
     <q>Now, what has this experience taught you?</q>\n
     <q>That philosophy isn't worth my time,</q> you reply.\n
     <q>I'm very impressed, it takes most people years to reach this point.
     You have learned all that you can from me. Go forth into the world with
     confidence,</q> he says, then adds, <q>I won't even charge you a
     buck.</q>
     <.reveal KoanSolved>"

    hideForLongMenu = 6
;

++ MenuTopic 'I give up'
    "<q>I give up!</q> you say.\n
     <q>Think about it some more, and come back when you have an answer,</q>
     Toothrot replies. "
    hideForLongMenu = 100
    showCount = 1000000000 /* Always show */
;

/* ------------------------------------------------------------------------ */

+ InConversationState
    specialDesc = "Herman Toothrot is standing here. "
    stateDesc = "He's awaiting your reply. "
;

++ MenuTopic 'What do you mean you\'ve been waiting for me?'
    "<q>What do you mean you've been waiting for me?</q> you ask him.\n
     <q>Our meeting comes at this, the final moment of my existence so
     far,</q> he replies sagely.
     <q>All else has been in anticipation of this event.</q> "
;

++ MenuTopic 'What are you doing here?'
    "<q>What are you doing here?</q> you wonder out loud.\n
     <q>I'm teaching philosophy here,</q> Herman replies.
     <.reveal Philosophy>"
;

++ MenuTopic 'What sort of philosophy are you teaching?'
    "<q>What sort of philosophy are you teaching?</q>\n
     <q>Neo-existentialist Cartesian Zen Taoism,</q> Herman says,
     then adds, <q>It's all the rage at cocktail parties this year.</q>"
    isActive = gRevealed('Philosophy')
;

++ MenuTopic 'Could you teach me some philosophy?'
    "<q>Could you teach me some philosophy?</q>\n
     <q>OK, here's a Zen koan for you,</q> Herman begins.\n
     <q>A what?</q> you ask.\n
     <q>A philosophical puzzle,</q> Herman continues,
     <q>If a tree falls in the forest, and no one is around to hear it...
     what color is the tree?</q>
     <.reveal Koan>
     <.convnode Koan>"
    isActive = (gRevealed('Philosophy') && !gRevealed('Koan'))
;

++ MenuTopic
    'I think I have an answer to the philosophical puzzle you posed for me.'
    "<q>I think I have an answer to the philosophical puzzle you posed for
     me,</q> you say. <.convnode Koan>"
    
    isActive = (gRevealed('Koan') && !gRevealed('KoanSolved'))
;

/* ------------------------------------------------------------------------ */

++ ConversationReadyState
    isInitState = true

    specialDesc = "Herman Toothrot is sitting here, meditating. "
    stateDesc = "He's meditating. "
;

+++ HelloTopic 'Hi, Herman'
    "<q>Hi, Herman,</q> you say.
     <q>Oh, hi,</q> he says, getting up. <q>I've been waiting for you.</q>
     <.reveal TalkedToHerman>"
    isActive = !gRevealed('TalkedToHerman')
;

+++ HelloTopic 'Herman Toothrot! What are you doing here?'
    "<q>Herman Toothrot! What are you doing here?</q> you ask.\n
     <q>Oh, hi,</q> he says, getting up. <q>I've been waiting for you.</q>
     <.reveal TalkedToHerman>"
    isActive = !gRevealed('TalkedToHerman')
;

+++ HelloTopic 'Word up, Herman'
    "<q>Word up, Herman,</q> you say. "
    isActive = gRevealed('TalkedToHerman')
;

+++ ByeTopic 'I think I have better things to do than talk to you.'
    topicResponse()
    {
    "<q>I think I have better things to do than talk to you,</q> you say,
     to which Herman replies, <q>I think you will find that the concept of
     'better things' is the frailest of illusions.</q>
     <.p>He sits down to meditate. ";
    }
;
/* ------------------------------------------------------------------------ */
