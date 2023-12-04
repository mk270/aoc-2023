% -*- prolog -*-

% https://adventofcode.com/2023/day/2

/* To run this code interactively, one must incant the following runes
   in the REPL:

set_prolog_flag(double_quotes, chars).
use_module(library(dcg/basics)).

*/

sample_text(A) :- A =
"Game 1: 3 blue, 4 red; 1 red, 2 green, 6 blue; 2 green
Game 2: 1 blue, 2 green; 3 green, 4 blue, 1 red; 1 green, 1 blue
Game 3: 8 green, 6 blue, 20 red; 5 blue, 4 red, 13 green; 5 green, 1 red
Game 4: 1 green, 3 red, 6 blue; 3 green, 6 red; 3 green, 15 blue, 14 red
Game 5: 6 red, 1 blue, 3 green; 2 blue, 1 red, 2 green
".

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Definite Clause Grammar (DCG) to parse the input

% terminology used below:
%
%   kvp(GameID, PCs) - key value pair representing the game ID and the results
%                      on a single input line
%
%   pc(Count, Colour) - "per colour" - the tuple of the number of balls of
%                       a specific colour, and the colour, e.g. (3, red)
%
%   subset            - a list of pc()s; represents a single selection of
%                       balls of all three colours
%
%   subsets           - a list of subsets; there may be more than one per "game"

kvps([])             --> [].
kvps([kvp(S, N)|Ns]) --> game_id(S), ":", subsets(N), "\n", kvps(Ns).
game_id(G)           --> "Game ", integer(G).

% for " 3 blue, 4 red"
subset([W|WW])  --> per_colour(W), ",", subset(WW).
subset([W])     --> per_colour(W).
subsets([S|SS]) --> subset(S), ";", subsets(SS).
subsets([S])    --> subset(S).

% for " 3 blue"
per_colour(pc(Count, Colour)) --> " ", integer(Count), " ", colour(Colour).

colour(blue)  --> "blue".
colour(red)   --> "red".
colour(green) --> "green".

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% `pc_colour` is a misnomer
%
% ignoring the colour in a pc(), given a list of pc()s, what is the maximum
% number of balls in any of them?
%
% assumption: before calling this, any list of pc()s has been filtered so
% that they're all the same colour
pc_colour(PCs, Result) :-
    pc_colour(PCs, 0, Result).
pc_colour([], Acc, Result) :- Result = Acc.
pc_colour([H|T], Acc, Result) :-
    pc(Count, _) = H,
    NewAcc is max(Acc, Count),
    pc_colour(T, NewAcc, Result).

% boolean predicate: does the pc() in X match the Colour?
pc_matches_colour(Colour, X) :-
    pc(_, Col) = X,
    Colour = Col.

% given a list of lists of pc()s, what is the maximum number of balls of
% the colour Colour in any of them?
max_per_colour_per_game(PCs, Colour, Result) :-
    append(PCs, FlattenedPCs),
    include(pc_matches_colour(Colour), FlattenedPCs, PCs2),
    pc_colour(PCs2, Result).

% given a list of lists of PCs, extract the maximum number of balls of
% each colour observed, in an rgb() struct
max_colours_in_game(PCs, rgb(R,G,B)) :-
    max_per_colour_per_game(PCs, red, R),
    max_per_colour_per_game(PCs, green, G),
    max_per_colour_per_game(PCs, blue, B).

% does the first rgb() accommodate the second rgb()?
%
% this is, is each colour in the first greater than or equal to the
% corresponding colour in the second?
accommodates(rgb(R1, G1, B1), rgb(R2, G2, B2)) :-
    R1 >= R2,
    G1 >= G2,
    B1 >= B2.

% does the specific game in kvp() accommodate the RGB values?
% i.e., if there were rgb(R, G, B) balls really in the bag, is it possible
% that all the subsets in the game in the kvp() could have occurred?
game_accomodates(rgb(R, G, B), kvp(_GameID, PCs)) :-
    max_colours_in_game(PCs, GameCapacity),
    accommodates(rgb(R, G, B), GameCapacity).

accommodating_games(KVPs, rgb(R, G, B), Results) :-
    include(game_accomodates(rgb(R, G, B)), KVPs, Results).

tally_accommodating_games(KVPs, rgb(R, G, B), Result) :-
    accommodating_games(KVPs, rgb(R, G, B), RelevantGames),
    game_ids(RelevantGames, GameIDs),
    sum_ids(GameIDs, Result).

% surely there's foldl and map?
game_ids([], []).
game_ids([kvp(GameID,_)|TailKVPs], [Result|Results]) :-
    Result = GameID,
    game_ids(TailKVPs, Results).
sum_ids([], 0).
sum_ids([H|T], Tally) :-
    sum_ids(T, TTally),
    Tally is H + TTally.

tally_accommodating_games_from_string(S, rgb(R, G, B), Tally) :-
    phrase(kvps(KVPs), S),
    tally_accommodating_games(KVPs, rgb(R, G, B), Tally).


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Tests

tests() :-
    test_subsets(),
    test_pc_colour(),
    test_max_per_colour_per_game(),
    test_max_colours_in_game(),
    test_accommodates(),
    test_tally().

test_subsets() :-
    phrase(subsets(SS), " 3 blue, 4 red; 1 green"),
    SS = [[pc(3, blue), pc(4, red)], [pc(1, green)]].
    
test_pc_colour() :-
    pc_colour([pc(4,blue),pc(5,blue), pc(3,blue)], R),
    R = 5.

test_max_per_colour_per_game() :-
    PCs = [[pc(3, blue), pc(4, red)],
           [pc(1, red), pc(2, green), pc(6, blue)],
           [pc(2, green)]],
    max_per_colour_per_game(PCs, red, MaxRed),
    max_per_colour_per_game(PCs, green, MaxGreen),
    max_per_colour_per_game(PCs, blue, MaxBlue),
    MaxRed = 4,
    MaxGreen = 2,
    MaxBlue = 6.

test_max_colours_in_game() :-
    PCs = [[pc(3, blue), pc(4, red)],
           [pc(1, red), pc(2, green), pc(6, blue)],
           [pc(2, green)]],
    max_colours_in_game(PCs, rgb(4, 2, 6)).

test_accommodates() :-
    RGB0 = rgb(0,0,0),
    RGB1 = rgb(2,4,5),
    RGB2 = rgb(3,3,3),
    RGB9 = rgb(9,9,9),
    accommodates(RGB0, RGB0),
    accommodates(RGB9, RGB0),
    accommodates(RGB9, RGB2),
    accommodates(RGB9, RGB1),
    accommodates(RGB2, RGB0),
    accommodates(RGB1, RGB0),
    \+ accommodates(RGB1, RGB2),
    \+ accommodates(RGB2, RGB1).

test_game_accommodates() :-
    PCs = [[pc(3, blue), pc(4, red)],
           [pc(1, red), pc(2, green), pc(6, blue)],
           [pc(2, green)]],
    GameID = 0, %immaterial
    KVP = kvp(GameID, PCs),

    Bag0   = rgb(0,0,0),
    Bag1   = rgb(1,2,3),
    Bag2   = rgb(4,4,4),
    Bag3   = rgb(4,2,6), % exact
    BagMax = rgb(9,9,9),

    \+ game_accomodates(Bag0, KVP),
    \+ game_accomodates(Bag1, KVP),
    \+ game_accomodates(Bag2, KVP),
    game_accomodates(Bag3, KVP),
    game_accomodates(BagMax, KVP).

test_tally() :-
    sample_text(Text),
    tally_accommodating_games_from_string(Text, rgb(12,13,14), Tally),
    Tally = 8,

    input(Text2),
    tally_accommodating_games_from_string(Text2, rgb(12,13,14), Tally2),
    Tally2 = 2149.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

input(A) :-
    A =
"Game 1: 8 green; 5 green, 6 blue, 1 red; 2 green, 1 blue, 4 red; 10 green, 1 red, 2 blue; 2 blue, 3 red
Game 2: 10 blue, 12 red; 8 red; 7 green, 5 red, 7 blue
Game 3: 1 red, 15 blue, 3 green; 8 blue, 2 red, 4 green; 2 red, 5 green, 9 blue
Game 4: 8 green, 4 blue, 1 red; 3 green; 4 blue, 1 red, 12 green; 5 green, 1 red, 8 blue; 3 green, 5 blue, 1 red
Game 5: 2 green, 8 blue; 7 blue, 4 green; 7 blue; 5 blue; 5 green, 2 blue, 1 red
Game 6: 6 blue, 3 green; 18 green, 8 blue; 9 green, 4 blue; 4 blue, 2 red, 3 green
Game 7: 15 red, 12 blue, 15 green; 12 blue, 18 green; 9 blue, 11 red; 16 green, 6 blue, 18 red; 6 blue, 12 red; 14 red, 18 green, 12 blue
Game 8: 6 red, 13 blue, 3 green; 18 blue; 3 green, 8 red
Game 9: 3 blue, 4 red; 8 red, 2 blue; 4 green, 8 red, 3 blue; 6 red, 1 blue; 16 green, 2 red, 2 blue
Game 10: 3 red, 7 blue, 2 green; 1 green, 15 red, 5 blue; 1 red, 5 blue; 3 blue, 4 green
Game 11: 12 green, 3 blue; 3 red; 1 red, 6 blue, 9 green; 7 blue, 1 red, 13 green; 1 blue, 5 green, 4 red; 18 green, 3 red
Game 12: 9 green, 13 blue; 3 red, 4 blue, 4 green; 10 green, 7 red, 5 blue; 9 red, 12 blue, 3 green
Game 13: 15 red, 18 blue, 10 green; 11 red, 3 green, 4 blue; 2 green, 12 blue, 4 red
Game 14: 12 blue, 6 red; 2 blue, 7 green, 6 red; 12 blue, 7 green; 4 blue, 1 green, 4 red; 9 green, 12 blue; 3 red, 5 green, 8 blue
Game 15: 9 green, 1 blue; 14 green, 4 red, 1 blue; 1 blue, 6 green, 2 red; 7 red, 13 green, 2 blue; 4 red, 9 green; 2 green, 1 blue, 2 red
Game 16: 3 blue, 2 green, 5 red; 4 green, 3 blue, 4 red; 6 red, 5 blue, 2 green; 3 red, 11 blue; 6 green, 15 blue, 4 red
Game 17: 15 blue, 3 green, 2 red; 2 green, 2 red, 15 blue; 1 red, 1 blue, 7 green
Game 18: 2 blue, 9 red; 12 red, 1 green, 6 blue; 5 red, 5 blue, 2 green
Game 19: 3 red, 4 green, 8 blue; 10 red, 8 green, 1 blue; 13 blue, 7 green, 10 red; 6 red, 1 green, 11 blue; 9 green, 7 blue, 10 red; 7 blue, 7 red
Game 20: 8 blue, 4 green, 14 red; 4 green, 16 red, 1 blue; 10 blue, 14 red, 8 green; 4 green, 13 blue, 20 red; 5 blue, 5 green, 1 red
Game 21: 4 green, 10 blue, 5 red; 11 blue, 4 green, 1 red; 3 blue, 3 red, 2 green; 1 red, 11 blue, 6 green; 1 green, 9 blue, 5 red; 7 blue, 5 green
Game 22: 3 green, 7 blue, 6 red; 12 red, 11 blue, 2 green; 1 blue, 1 green, 15 red; 6 blue, 1 green, 8 red; 4 blue, 1 red; 2 blue, 1 green, 5 red
Game 23: 2 blue, 5 green, 13 red; 1 green, 5 blue, 16 red; 6 blue, 9 green, 9 red; 7 green, 3 blue
Game 24: 2 green; 2 red, 7 blue, 17 green; 5 red, 6 blue, 13 green; 1 green, 6 blue; 2 green, 4 red, 2 blue; 4 blue, 2 green
Game 25: 2 green, 5 blue, 9 red; 2 green, 8 red, 5 blue; 3 green, 1 red, 19 blue
Game 26: 3 green, 2 blue, 8 red; 4 red, 2 blue; 11 red, 3 green; 9 red, 3 green, 6 blue; 10 red, 1 green, 2 blue; 4 blue, 4 green, 14 red
Game 27: 1 green, 4 red, 7 blue; 13 red; 17 red
Game 28: 5 red, 17 green, 15 blue; 7 blue; 7 red, 12 green, 10 blue; 5 red, 11 blue, 3 green
Game 29: 4 blue, 9 red, 9 green; 2 green, 10 red, 2 blue; 3 red, 4 blue, 6 green; 2 green, 17 red, 1 blue; 2 red, 7 green, 1 blue
Game 30: 16 red, 5 blue, 11 green; 5 blue, 5 green, 9 red; 7 green, 1 red, 6 blue
Game 31: 3 green, 11 blue; 5 green; 8 green, 13 blue; 4 red, 10 blue, 8 green
Game 32: 11 blue, 5 green, 4 red; 7 blue; 1 red, 1 green, 7 blue; 7 red, 1 blue, 4 green
Game 33: 7 red, 3 green, 6 blue; 2 red, 16 green, 5 blue; 1 blue, 2 red, 8 green
Game 34: 1 blue, 1 red, 1 green; 9 red, 6 green; 2 blue, 8 red, 6 green; 1 blue, 12 green, 13 red
Game 35: 10 red, 9 green; 1 red, 4 blue, 4 green; 7 blue, 3 green, 4 red
Game 36: 5 red, 6 green, 4 blue; 9 green, 1 red; 12 red, 12 green, 4 blue; 3 red; 18 green, 5 red, 4 blue
Game 37: 10 green, 4 blue, 2 red; 1 red, 3 blue, 9 green; 5 blue, 4 green, 1 red; 6 green, 12 blue; 7 green, 1 red, 13 blue; 9 green, 20 blue, 2 red
Game 38: 9 blue, 20 red, 2 green; 3 blue, 6 green, 19 red; 10 green, 8 red, 2 blue; 4 blue, 4 red, 3 green
Game 39: 4 green, 2 blue, 4 red; 16 blue, 1 red, 2 green; 13 red, 2 green; 16 blue, 7 red, 3 green
Game 40: 8 blue, 2 green, 2 red; 7 blue, 2 red, 1 green; 8 green, 12 blue, 2 red; 2 red, 3 blue, 8 green
Game 41: 9 blue, 2 green; 10 blue, 3 green; 1 green, 9 blue, 3 red; 3 blue, 3 green; 12 blue, 1 red; 3 blue, 1 green, 1 red
Game 42: 1 blue, 1 green, 8 red; 1 blue, 1 red; 2 red, 1 green
Game 43: 5 red, 2 green, 8 blue; 11 blue, 10 green, 1 red; 11 blue, 7 red
Game 44: 9 red, 3 green; 9 red, 1 blue, 6 green; 14 red, 5 green; 4 red, 2 green, 1 blue
Game 45: 5 blue, 1 red, 1 green; 5 blue, 1 red; 6 blue; 10 blue, 1 green; 1 red
Game 46: 4 green, 8 blue, 13 red; 12 green, 11 blue, 12 red; 1 green, 13 red, 1 blue; 12 red, 8 green, 12 blue
Game 47: 1 green, 16 blue, 15 red; 1 blue; 18 red, 10 blue, 9 green; 17 blue, 16 red, 5 green; 2 red, 3 blue, 9 green
Game 48: 2 blue, 4 green; 7 blue, 3 red, 2 green; 17 blue, 13 red; 2 red, 1 green, 9 blue; 2 red, 14 blue
Game 49: 6 red, 2 blue, 3 green; 1 green, 4 blue, 7 red; 5 red, 8 green, 6 blue; 1 red, 9 green
Game 50: 18 red, 4 blue; 6 blue, 3 green, 13 red; 1 green, 7 red, 6 blue
Game 51: 10 blue, 1 green, 9 red; 3 green, 6 blue, 8 red; 4 red, 2 green, 12 blue
Game 52: 7 blue, 1 red, 8 green; 2 red, 9 blue, 8 green; 16 blue, 7 green; 1 red, 11 green, 8 blue; 2 red, 20 blue
Game 53: 8 green, 15 red, 4 blue; 5 green, 13 blue; 6 blue, 6 green, 15 red; 12 blue, 2 green, 2 red
Game 54: 3 green, 5 red, 1 blue; 1 blue, 6 green, 2 red; 4 green, 3 red
Game 55: 12 green, 8 red, 3 blue; 6 blue, 2 red, 7 green; 4 blue, 13 red, 11 green; 12 green, 9 blue, 7 red; 10 red, 6 blue, 3 green
Game 56: 6 red, 1 green, 2 blue; 1 red, 1 green, 3 blue; 12 red, 4 blue, 4 green; 3 green, 5 blue, 1 red; 5 blue, 3 green, 2 red; 1 green, 5 red, 7 blue
Game 57: 1 blue, 1 green, 3 red; 10 red, 6 green, 1 blue; 4 red, 4 green, 2 blue; 7 green, 2 blue, 1 red
Game 58: 5 green, 2 blue, 4 red; 2 red, 2 blue; 5 red, 3 green; 3 blue, 5 green; 6 red, 2 green, 2 blue; 7 red, 3 blue, 5 green
Game 59: 14 red, 9 green; 11 red, 2 blue, 5 green; 18 red, 2 blue, 4 green
Game 60: 16 red, 9 green, 2 blue; 8 green, 17 red; 3 blue, 5 green, 14 red
Game 61: 12 red, 17 blue, 18 green; 1 green, 1 blue; 1 blue, 4 green, 6 red
Game 62: 2 blue, 5 green, 3 red; 1 blue, 7 green, 6 red; 8 blue, 1 red; 4 blue, 5 red, 12 green; 15 blue, 3 green, 1 red
Game 63: 2 blue, 2 red, 1 green; 5 red, 10 blue, 4 green; 4 green, 5 blue, 8 red
Game 64: 2 blue, 14 green; 9 green, 5 red; 7 red, 3 blue, 10 green; 14 green, 2 blue, 5 red
Game 65: 4 green, 7 blue, 1 red; 3 red, 2 green, 7 blue; 5 blue, 2 red, 1 green; 6 blue, 2 green; 7 blue
Game 66: 9 red, 2 green, 5 blue; 5 blue; 8 blue, 5 green, 11 red; 17 blue, 3 green, 14 red; 2 green, 9 blue; 11 red, 4 blue
Game 67: 2 green, 7 red, 8 blue; 6 red, 4 green; 1 red, 3 green, 7 blue; 7 blue, 7 red, 4 green; 2 red, 1 green; 3 green, 6 red, 2 blue
Game 68: 4 red, 2 blue, 5 green; 5 blue, 8 red, 2 green; 11 red, 2 green, 4 blue; 7 red, 5 blue, 3 green
Game 69: 8 blue, 1 green, 4 red; 3 red, 11 blue, 9 green; 12 blue, 10 green; 1 red, 15 blue, 7 green
Game 70: 13 blue, 1 green, 8 red; 15 blue, 10 red; 10 blue, 17 red; 15 red, 4 green, 6 blue; 11 red, 1 blue, 2 green; 14 red, 4 green, 4 blue
Game 71: 1 red, 10 blue; 1 green, 12 blue, 2 red; 4 red, 4 green, 8 blue
Game 72: 2 green, 6 red, 1 blue; 7 red, 4 green, 4 blue; 7 red, 4 blue, 7 green; 7 green, 3 blue; 10 green, 9 blue, 8 red; 5 red, 2 green, 8 blue
Game 73: 8 blue, 2 green, 9 red; 2 green, 10 red, 6 blue; 3 blue, 6 green, 2 red
Game 74: 2 blue, 10 green, 7 red; 4 blue, 13 red, 3 green; 11 green, 3 red, 4 blue
Game 75: 14 green, 1 red, 7 blue; 15 blue, 11 green, 1 red; 11 green, 15 blue, 6 red
Game 76: 7 green, 7 red, 2 blue; 4 blue, 18 red, 9 green; 12 red, 4 blue, 1 green
Game 77: 3 blue, 1 green, 12 red; 10 green, 13 red, 7 blue; 7 green, 12 red; 6 blue, 10 red; 5 blue, 3 green, 17 red; 3 green, 5 blue, 13 red
Game 78: 11 red, 9 blue; 2 red, 7 blue; 12 red, 7 blue, 3 green; 3 green, 8 red, 9 blue; 1 green, 5 red, 6 blue
Game 79: 6 red, 12 blue; 5 red, 4 green, 11 blue; 13 blue, 2 green, 3 red
Game 80: 7 red, 6 blue; 2 green, 7 red, 6 blue; 5 blue, 6 red, 2 green; 1 green, 7 red, 2 blue; 4 green, 6 blue, 7 red; 1 green, 6 red, 10 blue
Game 81: 10 blue, 7 green, 3 red; 7 green, 3 red, 16 blue; 18 blue, 3 red, 7 green
Game 82: 7 red, 5 blue, 9 green; 7 blue, 8 green, 11 red; 1 blue, 1 green, 10 red; 5 red, 8 blue, 7 green; 6 red, 10 green, 2 blue; 3 blue, 5 green, 10 red
Game 83: 2 red, 2 green, 1 blue; 2 green, 2 red; 6 red, 1 green; 8 red, 1 blue, 1 green; 1 red, 1 green; 3 red
Game 84: 9 red, 4 green; 1 red, 13 green, 2 blue; 2 green, 15 red, 2 blue
Game 85: 2 green, 4 red; 1 blue; 2 green, 4 red, 1 blue
Game 86: 2 green, 10 red, 3 blue; 3 red, 5 blue; 3 green, 2 blue, 8 red; 1 blue, 5 red, 2 green
Game 87: 19 green, 9 blue, 7 red; 12 red, 15 green; 4 blue, 8 green; 6 green, 3 red, 11 blue; 16 green, 4 blue, 11 red; 10 red, 4 blue, 9 green
Game 88: 6 red, 2 green; 10 red, 4 green, 4 blue; 1 blue, 8 red, 12 green; 7 green, 2 blue, 12 red; 1 green, 5 blue, 16 red; 10 red, 5 blue
Game 89: 1 red, 14 blue, 1 green; 1 red, 12 blue, 8 green; 2 red, 13 blue, 11 green; 8 blue, 4 red, 16 green; 4 red, 5 blue; 6 blue, 1 red, 1 green
Game 90: 3 blue, 9 green, 5 red; 4 green, 6 red, 1 blue; 2 blue, 12 green, 5 red; 1 green, 1 blue, 3 red; 5 red, 3 green
Game 91: 8 green, 3 blue, 8 red; 8 green, 4 blue, 4 red; 5 red, 1 green
Game 92: 1 green, 9 red; 1 red, 4 blue; 9 red, 2 green; 3 red, 1 blue
Game 93: 1 red, 16 green, 5 blue; 1 red, 1 green, 4 blue; 4 blue, 6 red, 13 green
Game 94: 9 red, 9 blue, 3 green; 5 green, 11 blue, 1 red; 3 red, 6 blue
Game 95: 2 green, 4 blue; 8 green, 2 blue, 12 red; 10 red, 9 green; 4 red, 2 blue, 4 green; 8 blue, 7 green, 14 red; 1 blue, 4 red, 8 green
Game 96: 12 red, 2 blue, 8 green; 6 green, 6 red; 7 blue, 8 green, 6 red; 14 red, 8 green; 2 blue, 4 green, 10 red; 6 green, 7 blue, 7 red
Game 97: 4 green, 12 red, 2 blue; 8 blue, 3 red, 3 green; 2 blue, 2 red, 7 green; 17 blue, 1 green, 7 red; 19 blue, 1 red, 6 green; 6 green, 7 red, 9 blue
Game 98: 13 red, 15 green, 14 blue; 6 blue, 1 green; 14 blue, 12 red, 1 green
Game 99: 1 green, 11 red, 12 blue; 7 red, 20 blue, 1 green; 5 blue, 5 red; 6 blue, 4 red; 1 blue, 1 green; 6 red, 8 blue
Game 100: 2 red, 9 green, 11 blue; 13 blue, 4 red, 16 green; 8 green, 13 blue; 10 green, 1 red, 12 blue
".
