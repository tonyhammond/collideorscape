#!/home/tony/bin/perl

$Root = "/home/tony/www/cs/cgi-data/Books";

################################################################################

# The text is contained in a series of ASCII files (one per chapter or episode)
# with markup indicating part, episode, page, etc. We store the file names in
# the array @Files (a parallel array @Episodes stores the starting page numbers
# for each episode). The path is held in the variable $Prefix, while the variable 
# $Suffix records an optional file extension.

################################################################################

# This array maps shorthand argument id's onto the coresponding abbreviate
# book title identifiers.

%BookKeys = (
"0","Ulysses",    # This entry will be used as the default
"d","Dubliners",
"p","Portrait",
"u","Ulysses",
"w","Wake",
"x","Jekyll",
);

# This array records the book titles in presentation order. Book titles are 
# given in a combination of identifier and as presented. This device allows us 
# to derive some of the benefits of an associative array in a regular indexed
# array.

@Books = (
"Dubliners | Dubliners",
"Portrait  | Portrait of the Artist",
"Ulysses   | Ulysses",
"Wake      | Finnegans Wake",
"-         | -",
"Jekyll    | Dr Jekyll and Mr Hyde",
);

################################################################################

$BookKeyWake = "w";
$SiglumWake = "FW";
$BookTitleWake = "Finnegans Wake";
$PrefixWake = "$Root:JJ:Wake:";
$SuffixWake = ".txt";
$PatternDefaultWake = "riverrun";

%EpisodesWake = (
  "-1","",
  "The Giant's Howe (I-1)","Book1.1",
  "Ballad (I-2)","Book1.2",
  "Goat (I-3)","Book1.3",
  "Lion (I-4)","Book1.4",
  "Hen (I-5)","Book1.5",
  "Questions and Answers (I-6)","Book1.6",
  "Shem (I-7)","Book1.7",
  "Anna Livia Plurabelle (I-8)","Book1.8",
  "-2","",
  "The Mime of Mick, ... (II-1)","Book2.1",
  "Night Lessons (II-2)","Book2.2",
  "Scene in the Pub (II-3)","Book2.3",
  "Mamalujo (II-4)","Book2.4",
  "-3","",
  "First Watch of Shaun (III-1)","Book3.1",
  "Second Watch of Shaun (III-2)","Book3.2",
  "Third Watch of Shaun (III-3)","Book3.3",
  "Fourth Watch of Shaun (III-4)","Book3.4",
  "-4","",
  "Dawn (IV)","Book4.0",
);

%PageStartsWake = (
  "-1",-2,
  "The Giant's Howe (I-1)",3,
  "Ballad (I-2)",30,
  "Goat (I-3)",48,
  "Lion (I-4)",75,
  "Hen (I-5)",104,
  "Questions and Answers (I-6)",126,
  "Shem (I-7)",169,
  "Anna Livia Plurabelle (I-8)",196,
  "-2",-218,
  "The Mime of Mick, ... (II-1)",219,
  "Night Lessons (II-2)",260,
  "Scene in the Pub (II-3)",309,
  "Mamalujo (II-4)",383,
  "-3",-402,
  "First Watch of Shaun (III-1)",403,
  "Second Watch of Shaun (III-2)",429,
  "Third Watch of Shaun (III-3)",474,
  "Fourth Watch of Shaun (III-4)",555,
  "-4",-592,
  "Dawn (IV)",593,
);

################################################################################

$BookKeyUlysses = "u";
$SiglumUlysses = "U";
$BookTitleUlysses = "Ulysses";
$PrefixUlysses = "$Root:JJ:Ulysses:";
$SuffixUlysses = ".txt";
$PatternDefaultUlysses = "Stately";

%EpisodesUlysses = (
  "Telemachus (1)","ulys1",
  "Nestor (2)","ulys2",
  "Proteus (3)","ulys3",
  "Calypso (4)","ulys4",
  "Lotus Eaters (5)","ulys5",
  "Hades (6)","ulys6",
  "Aeolus (7)","ulys7",
  "Lestrygonians (8)","ulys8",
  "Scylla and Charybdis (9)","ulys9",
  "Wandering Rocks (10)","ulys10",
  "Sirens (11)","ulys11",
  "Cyclops (12)","ulys12",
  "Nausicca (13)","ulys13",
  "Oxen of the Sun (14)","ulys14",
  "Circe (15)","ulys15",
  "Eumaeus (16)","ulys16",
  "Ithaca (17)","ulys17",
  "Penelope (18)","ulys18",
);

# Unknown pagination
%PageStartsUlysses = (
  "-1",0,
  "Telemachus (1)",1,
  "Nestor (2)",19,
  "Proteus (3)",29,
  "-2",30,
  "Calypso (4)",41,
  "Lotus Eaters (5)",53,
  "Hades (6)",67,
  "Aeolus (7)",91,
  "Lestrygonians (8)",120,
  "Scylla and Charybdis (9)",148,
  "Wandering Rocks (10)",176,
  "Sirens (11)",206,
  "Cyclops (12)",236,
  "Nausicca (13)",280,
  "Oxen of the Sun (14)",310,
  "Circe (15)",346,
  "-3",-347,
  "Eumaeus (16)",494,
  "Ithaca (17)",536,
  "Penelope (18)",599,
);

@EpisodesUlyssesP = (
  9,30,42,57,72,88,118,150,184,218,254,290,344,380,425,533,586,659
);
@EpisodesUlyssesRH = (
  3,24,37,55,71,87,116,151,184,219,256,292,346,383,429,613,666,738
);
@EpisodesUlyssesBH = (
);

################################################################################

$BookKeyPortrait = "p";
$SiglumPortrait = "P";
$BookTitlePortrait = "Portrait of the Artist";
$PrefixPortrait = "$Root:JJ:Portrait:";
$SuffixPortrait = ".txt";
$PatternDefaultPortrait = "Once upon a time";

%EpisodesPortrait = (
  "Chapter 1","artist1",
  "Chapter 2","artist2",
  "Chapter 3","artist3",
  "Chapter 4","artist4",
  "Chapter 5","artist5",
);

%PageStartsPortrait = (
  "Chapter 1",1,
  "Chapter 2",2,
  "Chapter 3",3,
  "Chapter 4",4,
  "Chapter 5",5,
);

################################################################################

$BookKeyDubliners = "d";
$SiglumDubliners = "D";
$BookTitleDubliners = "Dubliners";
$PrefixDubliners = "$Root:JJ:Dubliners:";
$SuffixDubliners = ".txt";
$PatternDefaultDubliners = "There was no hope for him";

%EpisodesDubliners = (
  "The Sisters","dublin1",
  "An Encounter","dublin2",
  "Araby","dublin3",
  "Eveline","dublin4",
  "After The Race","dublin5",
  "Two Gallants","dublin6",
  "The Boarding House","dublin7",
  "A Little Cloud","dublin8",
  "Counterparts","dublin9",
  "Clay","dublin10",
  "A Painful Case","dublin11",
  "Ivy Day In The Committee Room","dublin12",
  "A Mother","dublin13",
  "Grace","dublin14",
  "The Dead","dublin15",
);

%PageStartsDubliners = (
  "The Sisters",1,
  "An Encounter",2,
  "Araby",3,
  "Eveline",4,
  "After The Race",5,
  "Two Gallants",6,
  "The Boarding House",7,
  "A Little Cloud",8,
  "Counterparts",9,
  "Clay",10,
  "A Painful Case",11,
  "Ivy Day In The Committee Room",12,
  "A Mother",13,
  "Grace",14,
  "The Dead",15,
);


################################################################################

$BookKeyJekyll = "x";
$SiglumJekyll = "JH";
$BookTitleJekyll = "Dr Jekyll and Mr Hyde";
$PrefixJekyll = "$Root:RLS:Jekyll:";
$SuffixJekyll = ".txt";
$PatternDefaultJekyll = "Mr Utterson the lawyer";

%EpisodesJekyll = (
  "Story of the Door","drjek1",
  "Search for Mr Hyde","drjek2",
  "Dr Jekyll was Quite at Ease","drjek3",
  "The Carew Murder Case","drjek4",
  "Incident of the Letter","drjek5",
  "Remarkable Incident of ...","drjek6",
  "Incident at the Window","drjek7",
  "The Last Night","drjek8",
  "Dr Lanyon's Narrative","drjek9",
  "Henry Jekyll's Full Statement","drjek10",
);

%PageStartsJekyll = (
  "Story of the Door",1,
  "Search for Mr Hyde",2,
  "Dr Jekyll was Quite at Ease",3,
  "The Carew Murder Case",4,
  "Incident of the Letter",5,
  "Remarkable Incident of ...",6,
  "Incident at the Window",7,
  "The Last Night",8,
  "Dr Lanyon's Narrative",9,
  "Henry Jekyll's Full Statement",10,
);


################################################################################

sub SetBook {

  local($Selection) = @_;

  eval <<EOF;

    \$Book = \$Selection;
    \$BookKey = \$BookKey$Selection;
    \$Siglum = \$Siglum$Selection;
    \$BookTitle = \$BookTitle$Selection;
    \$Prefix = \$Prefix$Selection;
    \$Suffix = \$Suffix$Selection;
    %Episodes = %Episodes$Selection;
    %PageStarts = %PageStarts$Selection;
    \$PatternDefault = \$PatternDefault$Selection;

EOF

}    

################################################################################

1;

__END__


