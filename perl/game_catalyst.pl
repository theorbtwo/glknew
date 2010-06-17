{
    name => 'Game::Catalyst',

  # Note that this key is used both as a URI element and a filename element.  For simplicity, keep element names lacking in URI metacharacters, please.
  # The title, OTOH, can be any arbitrary string.

    games => {
        advent => {
            vm    => 'glulx',
            location => 'Advent.ulx',
            title => 'Adventure!',
        },
        'blue-lacuna' => {
            vm => 'glulx',
            location => 'blue-lacuna/BlueLacuna-r3.gblorb',
            title => 'Blue Lacuna',
        },
        alabaster     => {
            vm => 'glulx',
            location => 'Alabaster/Alabaster.gblorb',
            title => 'Alabaster',
        },
        acg           => {
            vm => 'glulx',
            location => 'ACG/ACG.ulx', 
            title => 'Adventurer\'s Consumer Guide',
        },
        king          => {
            vm => 'glulx',
            location => 'The King of Shreds and Patches.gblorb',
            title => 'The King of Shreds and Patches',
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
            vmm => 'agt',
            location => 'Emy Discovers Life/DISCOVER', 
            title => 'Emy Discovers Life',
        },
        sd3           => {
            vm => 'tads2',
            location => 'sd3/SD3.gam', 
            title => 'School Dreams 3: School Dreams Forever',
        },           
    },

    interpreters => {
        glulx => '/mnt/shared/projects/games/flash-if/git-1.2.6/git',
        tads2 => '/mnt/shared/projects/games/flash-if/tads2/glk/newtads',
        agt => '/mnt/shared/projects/games/flash-if/garglk-read-only/terps/agility/glkagil',
        'z-code' => '/mnt/shared/projects/games/flash-if/nitfol-0.5/newnitfol',
    },

    game_path => '/mnt/shared/projects/games/flash-if/',
}
