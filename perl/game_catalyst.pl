my $c = {
    name => 'Game::Catalyst',

  # Note that this key is used both as a URI element and a filename element.  For simplicity, keep element names lacking in URI & HTML metacharacters, please.
  # The title, OTOH, can be any arbitrary string.

    games => {
        advent => {
            vm    => 'glulx',
            location => 'Advent.ulx',
            title => 'Adventure!',
            restore => [["line", "restore\n"]],
        },
        'blue-lacuna' => {
            vm => 'glulx',
            location => 'blue-lacuna/BlueLacuna-r3.gblorb',
            title => 'Blue Lacuna',
            restore => [["char", "r"]],
        },
        alabaster     => {
            vm => 'glulx',
            location => 'Alabaster/Alabaster.gblorb',
            title => 'Alabaster',
            restore => [["line", "yes\n"],
                        ["char", " "],
                        ['char', ' '],
                        ["line", "restore\n"]],
        },
        acg           => {
            vm => 'glulx',
            location => 'ACG/ACG.ulx',
            title => 'Adventurer\'s Consumer Guide',
            restore => [["line", "restore\n"]],
        },
        king          => {
            vm => 'glulx',
            location => 'The King of Shreds and Patches.gblorb',
            title => 'The King of Shreds and Patches',
            restore => [["char", "r"]],
        },
        curses        => {
            vm => 'z-code',
            location => 'curses.z5',
            title => 'Curses',
        },
        zork1         => {
            vm => 'z-code',
            location => 'zork1/DATA/ZORK1.DAT',
            title => 'Zork I',
        },
        emy           => {
            vm => 'agt',
            location => 'Emy Discovers Life/DISCOVER',
            title => 'Emy Discovers Life',
            restore => [['char', ' '], ['line', "restore\n"]],
        },
        sd3           => {
            vm => 'tads2',
            location => 'sd3/SD3.gam',
            title => 'School Dreams 3: School Dreams Forever',
            restore => [['line', "foo\n"], ["line", "restore\n"]],
        },
        earlgrey => {
                     vm => 'glulx',
                     location => 'earlgrey.ulx',
                     title => 'Earl Grey',
                    },
        british_fox => {
                        vm => 'taf',
                        location => 'british_fox_and_the_celebrity_abductions.taf',
                        title => 'British Fox and the Celebrity Abductions',
                       },
    },

    interpreters => {
        glulx => '/mnt/shared/projects/games/flash-if/git-1.2.6/git',
        tads2 => '/mnt/shared/projects/games/flash-if/tads2/glk/newtads',
        agt => '/mnt/shared/projects/games/flash-if/garglk-read-only/terps/agility/glkagil',
        # 'z-code' => '/mnt/shared/projects/games/flash-if/nitfol-0.5/newnitfol',
        'z-code' => '/mnt/shared/projects/games/flash-if/garglk-read-only/terps/frotz/frotz',
        taf =>      '/mnt/shared/projects/games/flash-if/garglk-read-only/terps/scare/glkscare'
    },

    game_path => '/mnt/shared/projects/games/flash-if/',
};

for (keys %{$c->{games}}) {
  $c->{games}{$_}{shortname} = $_;
}

return $c;
