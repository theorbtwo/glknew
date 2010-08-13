my $c = {
    name => 'Game::Catalyst',

  # Note that this key is used both as a URI element and a filename element.  For simplicity, keep element names lacking in URI & HTML metacharacters, please.
  # The title, OTOH, can be any arbitrary string.

    games => {
        'tight-spot' => {
           vm     => 'z-code',
           location => 'ats.z8',
           title => 'A Tight Spot',
           link => 'http://ifdb.tads.org/viewgame?id=rsjzz9w60k6o6od4',
           nsfw => 0,
           desc => 'An implementation of sokoban, a box-pushing puzzle game.  Not, strictly speaking, interactive fiction, but an interesting technology demonstration.',
        },
        advent => {
            vm    => 'glulx',
            location => 'Advent.ulx',
            title => 'Adventure!',
            restore => [["line", "restore\n"]],
            link => 'http://en.wikipedia.org/wiki/Adventure_(computer_game)',
            nsfw => 0,
            desc => 'The original computer game, Adventure.  It simulates exploring a cave in Kentucky... with elves and a troll.'
          },
        'blue-lacuna' => {
            vm => 'glulx',
            location => 'blue-lacuna/BlueLacuna-r3.gblorb',
            title => 'Blue Lacuna',
            restore => [["char", "r"]],
            link => 'http://www.lacunastory.com/about.html',
            nsfw => 0,
            desc => 'Perhaps the most stressing of the <b>fiction</b> in interactive fiction of any game here, Blue Lacuna has actual characters and plot, in addition to puzzles.  The primary author of glknew.org considers this his favorite game here.',
        },
        alabaster     => {
            vm => 'glulx',
            location => 'Alabaster/Alabaster.gblorb',
            title => 'Alabaster',
            restore => [["line", "yes\n"],
                        ["char", " "],
                        ['char', ' '],
                        ["line", "restore\n"]],
            link => 'http://emshort.home.mindspring.com/Alabaster/index.html',
            nsfw => 0,
            desc => 'An interesting, and rather spooky, take on the classic tale of Snow White.  Primarily takes the form of a dialog, between Snow White, and the man sent to kill her.',
        },
        acg           => {
            vm => 'glulx',
            location => 'ACG/ACG.ulx',
            title => 'Adventurer\'s Consumer Guide',
            restore => [["line", "restore\n"]],
            link => 'http://ifdb.tads.org/viewgame?id=snk6qx8hfn3xpm0a',
            nsfw => 0,
            desc => 'A rather amusing puzzle game, in which you are sent to test a number of pieces of equipment as an author for the Adventurer\'s Consumer Guide, by being sent out with nothing else, and told to bring back a treasure.  Features lots of amusing text, and inventive puzzles.',
        },
        king          => {
            vm => 'glulx',
            location => 'The King of Shreds and Patches.gblorb',
            title => 'The King of Shreds and Patches',
            restore => [["char", "r"]],
            link => 'http://maher.filfre.net/King/',
            nsfw => 0,
            desc => 'A tale of the Cuthulu mythos, set in Black Death era London.  Features several playwrights of note.  Dark and mysterious, a good play.'
        },
        curses        => {
            vm => 'z-code',
            location => 'curses.z5',
            title => 'Curses',
            link => 'http://www.sparkynet.com/spag/c.html#curses',
            nsfw => 0,
            restore => [['char', ' '],
                        ['line', 'restore']],
            desc => 'Another funny one.  In Curses, you have escaped the preparations for a family vacation, ostensibly to get a tourist map of Paris from your attic -- which, it turns out, is quite extensive.',
        },
        zork1         => {
            vm => 'z-code',
            location => 'zork1/DATA/ZORK1.DAT',
            title => 'Zork I',
            link => 'http://en.wikipedia.org/wiki/Zork_I',
            nsfw => 0,
            desc => 'A classic of the genre, Zork is an Infocom game that was freed as a promotion for Legends of Zork, a browser-based MMORPG.  A, perhaps <b>the</b> classic treasure hunt.',
        },
        emy           => {
            vm => 'agt',
            location => 'Emy Discovers Life/DISCOVER',
            title => 'Emy Discovers Life',
            restore => [['char', ' '], ['line', "restore\n"]],
            link => 'http://www.ifwiki.org/index.php/Emy_Discovers_Life',
            nsfw => 1,
        },
        sd3           => {
            vm => 'tads2',
            location => 'sd3/SD3.gam',
            title => 'School Dreams 3: School Dreams Forever',
            restore => [['line', "foo\n"], ["line", "restore\n"]],
            link => 'http://www.ifwiki.org/index.php/School_Dreams_3:_School_Dreams_Forever',
            nsfw => 1,
        },
        earlgrey => {
            vm => 'glulx',
            location => 'earlgrey.ulx',
            title => 'Earl Grey',
            link => 'http://www.ifwiki.org/index.php/Earl_Grey',
            restore => [[line => "restore\n"]],
            nsfw => 0,
            desc => 'An odd little pun-based game.'
        },
        british_fox => {
            vm => 'taf',
            location => 'british_fox_and_the_celebrity_abductions.taf',
            title => 'British Fox and the Celebrity Abductions',
            link => 'http://www.ifwiki.org/index.php/British_Fox_and_the_Celebrity_Abductions',
            nsfw => 1,
        },
#         bearg => {
#             vm => 'z-code',
#             location => 'bearg.z5',
#             title => 'Ein Bär geht aus',
#             link => 'http://www.if-album.menear.de/pages/fantasy.html#baer',
#             nsfw => 0,
                  
#         },
#         banana => {
#             vm => 'glulx',
#             location => 'bnareplk.ulx',
#             title => 'Banana Republic [de]',
#             link => 'http://www.if-album.menear.de/pages/humor.html#bananenrepublik',
#             nsfw => 0,
#         },
#         Absturzmomente => {
#             vm => 'z-code',
#             location => 'abstmom.zblorb',
#             title => 'Absturzmomente',
#             link => 'http://ifdb.tads.org/viewgame?id=r1ayxo348ij7uk8p',
#             nsfw => 0,
#         },
    },

    interpreters => {
        glulx => 'git-1.2.6/git',
        tads2 => 'tads2/glk/newtads',
        agt => 'garglk-read-only/terps/agility/glkagil',
        # 'z-code' => '/mnt/shared/projects/games/flash-if/nitfol-0.5/newnitfol',
        'z-code' => 'garglk-read-only/terps/frotz/frotz',
        taf =>      'garglk-read-only/terps/scare/glkscare'
    },

    ## Set this in your game_catalyst_local.pl to have the system look for games in a path other than the one above "glknew/".
    game_path => '',
};

for (keys %{$c->{games}}) {
  $c->{games}{$_}{shortname} = $_;
}

return $c;
