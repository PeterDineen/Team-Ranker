%CP468

gameResult(teamA, teamB, 1, 4).
gameResult(teamA, teamC, 4, 1).
gameResult(teamB, teamC, 2, 3).
gameResult(teamB, teamD, 5, 2).
gameResult(teamC, teamD, 1, 2).
gameResult(teamD, teamE, 3, 3). % Example of a draw, if applicable.
gameResult(teamE, teamA, 2, 2).
gameResult(teamC, teamE, 7, 5).
gameResult(teamA, teamD, 1, 0).
gameResult(teamB, teamE, 3, 1).
gameResult(teamB, teamA, 6, 1).
gameResult(teamE, teamD, 1, 1).

% Team X wins
teamPoints(Team, Points) :-
    findall(3, (gameResult(Team, _, Score1, Score2), Score1 > Score2), Wins),
    findall(3, (gameResult(_, Team, Score2, Score1), Score1 > Score2), Wins2),
    findall(1, (gameResult(Team, _, Score1, Score2), Score1 = Score2), Draws),
    findall(1, (gameResult(_, Team, Score2, Score1), Score1 = Score2), Draws2),
    append([Wins, Wins2, Draws, Draws2], AllPointsFlat),
    sum_list(AllPointsFlat, Points).

teamRankingsByPoints(Rankings) :-
    findall(Team, gameResult(Team, _, _, _), Teams1),
    findall(Team, gameResult(_, Team, _, _), Teams2),
    append(Teams1, Teams2, TeamsCombined),
    sort(TeamsCombined, TeamsUnique),
    findall(Points-Team, (member(Team, TeamsUnique), teamPoints(Team, Points)), Pairs),
    sort(1, @>=, Pairs, SortedPairs),
    pairs_values(SortedPairs, Rankings).

% Calculate average goals scored by a team
averageGoalsScored(Team, Average) :-
    findall(Score1, gameResult(Team, _, Score1, _), Scores1),
    findall(Score2, gameResult(_, Team, _, Score2), Scores2),
    append(Scores1, Scores2, AllScores),
    sum_list(AllScores, TotalGoalsScored),
    length(AllScores, GamesPlayed),
    Average is TotalGoalsScored / GamesPlayed.


% Calculate average goals conceded by a team
averageGoalsConceded(Team, Average) :-
    findall(Score1, gameResult(_, Team, Score1, _), ScoresConcededAsSecondTeam),  % Goals conceded when Team is second
    findall(Score2, gameResult(Team, _, _, Score2), ScoresConcededAsFirstTeam),  % Goals conceded when Team is first
    append(ScoresConcededAsFirstTeam, ScoresConcededAsSecondTeam, AllConcededScores),
    sum_list(AllConcededScores, TotalGoalsConceded),
    length(AllConcededScores, GamesPlayed),
    Average is TotalGoalsConceded / GamesPlayed.


performanceScore(Team, Score) :-
    averageGoalsScored(Team, AvgScored),
    averageGoalsConceded(Team, AvgConceded),
    Score is AvgScored - AvgConceded.


teamRankingsByPerformance(Rankings) :-
    findall(Team, (gameResult(Team, _, _, _); gameResult(_, Team, _, _)), Teams),
    sort(Teams, UniqueTeams), % Remove duplicates to get a list of all unique teams
    findall(Score-Team, (member(Team, UniqueTeams), performanceScore(Team, Score)), ScoreTeamPairs),
    sort(1, @>=, ScoreTeamPairs, SortedScoreTeamPairs), % Sort teams by performance score in descending order
    pairs_values(SortedScoreTeamPairs, Rankings).




teamRankings(RankingsWithScoresAndRank) :-
    findall(Team, (gameResult(Team, _, _, _); gameResult(_, Team, _, _)), Teams),
    sort(Teams, UniqueTeams), % Remove duplicates to get a list of all unique teams
    findall(Score-Team, (member(Team, UniqueTeams), performanceScore(Team, Score)), ScoreTeamPairs),
    sort(1, @>=, ScoreTeamPairs, SortedScoreTeamPairs), % Sort teams by performance score in descending order
   
    % Enumerate and format the sorted list
    findall(RankFormatted, (
        nth1(Rank, SortedScoreTeamPairs, Score-Team),
        format(atom(RankFormatted), '~d. ~w (~2f)', [Rank, Team, Score])
    ), RankingsWithScoresAndRank).


teamRankByPerformance(Team, Rank) :-
    teamRankingsByPerformance(Rankings),
    nth1(Rank, Rankings, Team).

winningsOdds(Team1, Team2, Odds) :-
    performanceScore(Team1, Score1),
    performanceScore(Team2, Score2),
    PerformanceScoreDiff is abs(Score1 - Score2),
    (
        Score1 < Score2 ->
        Odds is 50 - (8 * PerformanceScoreDiff)
        ;
        Score1 >= Score2 ->
        Odds is 100 - (50 - (8 * PerformanceScoreDiff))
    ),
    format('Odds for ~w winning vs ~w: ~1f%\n', [Team1, Team2, Odds]).


predictOutcome(Team1, Team2, Winner, RoundedGoalDifferential, PerformanceScoreDifference) :-
 performanceScore(Team1, Score1),
    teamRankByPerformance(Team1, Rank1), % Get team 1's rank
    performanceScore(Team2, Score2),
    teamRankByPerformance(Team2, Rank2), % Get team 2's rank
    (Score1 > Score2 -> Winner = Team1; Winner = Team2),
    GoalDiff is abs(Score1 - Score2),
    RoundedGoalDifferential is round(GoalDiff),
    PerformanceScoreDifference = GoalDiff,
    format('Prediction: ~w (Rank: ~d, Performance Score: ~2f) vs ~w (Rank: ~d, Performance Score: ~2f) - predicted winner: ~w by ~d goals.', [Team1, Rank1, Score1, Team2, Rank2, Score2, Winner, RoundedGoalDifferential]).

estimateGoalDifferential(GoalDiff, RoundedGoalDifferential, PerformanceScoreDifference) :-
    RoundedGoalDifferential is round(GoalDiff),
    PerformanceScoreDifference = GoalDiff.

test_rankings(ExpectedRankings) :-
    teamRankingsByPoints(ActualRankings),
    ActualRankings == ExpectedRankings.

generate_all_series(Series) :-
    member(W1, [win, loss]),
    member(W2, [win, loss]),
    member(W3, [win, loss]),
    member(W4, [win, loss]),
    member(W5, [win, loss]),
    Series = [W1, W2, W3, W4, W5].

% Transforms 'win'/'loss' series into series of team names.
transform_series([], _, _, []).
transform_series([win|T], WinningTeam, LosingTeam, [WinningTeam|TransformedTail]) :-
    transform_series(T, WinningTeam, LosingTeam, TransformedTail).
transform_series([loss|T], WinningTeam, LosingTeam, [LosingTeam|TransformedTail]) :-
    transform_series(T, WinningTeam, LosingTeam, TransformedTail).

% Filters series where the WinningTeam wins exactly 3 games.
filter_winning_series(Series, WinningTeam, WinningCount) :-
    include(==(WinningTeam), Series, Wins),
    length(Wins, WinningCount).

generate_series(Series) :- generate_series_helper([], Series, 0, 0).

% Base case: When one team has 3 wins, stop.
generate_series_helper(Series, Series, 3, _).
generate_series_helper(Series, Series, _, 3).
% Recursive case: Generate next game if neither team has won 3 games yet.
generate_series_helper(CurrentSeries, FinalSeries, WinCount1, WinCount2) :-
    (WinCount1 < 3, WinCount2 < 3),
    member(NextResult, [win, loss]),
    update_counts(NextResult, WinCount1, WinCount2, NewWinCount1, NewWinCount2),
    generate_series_helper([NextResult|CurrentSeries], FinalSeries, NewWinCount1, NewWinCount2).

% Update win counts based on the result of the next game.
update_counts(win, WinCount1, WinCount2, NewWinCount1, WinCount2) :- NewWinCount1 is WinCount1 + 1.
update_counts(loss, WinCount1, WinCount2, WinCount1, NewWinCount2) :- NewWinCount2 is WinCount2 + 1.

% Main predicate adjusted for new series generation logic.
generate_and_display_series(WinningTeam, LosingTeam, WinCount) :-
    generate_series(Series),
    transform_series(Series, WinningTeam, LosingTeam, TransformedSeries),
    filter_winning_series(TransformedSeries, WinningTeam, WinCount),
    writeln(TransformedSeries),
    fail. % Continue finding all possible outcomes
generate_and_display_series(_, _, _).


generate_series_with_probability(Team1, Team2, Series, Probability) :- 
    generate_series_with_probability_helper(Team1, Team2, [], Series, 0, 0, 1, Probability).

generate_series_with_probability_helper(_, _, Series, Series, 3, _, Probability, Probability).
generate_series_with_probability_helper(_, _, Series, Series, _, 3, Probability, Probability).
generate_series_with_probability_helper(Team1, Team2, CurrentSeries, FinalSeries, WinCount1, WinCount2, CurrentProbability, FinalProbability) :-
    (WinCount1 < 3, WinCount2 < 3),
    member(NextResult, [win, loss]),
    update_counts(NextResult, WinCount1, WinCount2, NewWinCount1, NewWinCount2),
    update_probability(Team1, Team2, NextResult, CurrentProbability, NewProbability),
    generate_series_with_probability_helper(Team1, Team2, [NextResult|CurrentSeries], FinalSeries, NewWinCount1, NewWinCount2, NewProbability, FinalProbability).

generate_valid_series(Series) :-
    between(3, 5, Games),  % Series must be between 3 to 5 games.
    generate_series_helper([], Series, 0, 0, Games).

generate_series_helper(Series, Series, Win1, Win2, _) :-
    (Win1 >= 3; Win2 >= 3), !.  % Stop if either team wins 3 games.
generate_series_helper(TempSeries, FinalSeries, Win1, Win2, Games) :-
    Games > 0,
    member(Result, [win, loss]),
    update_counts(Result, Win1, Win2, NewWin1, NewWin2),
    NextGames is Games - 1,
    generate_series_helper([Result|TempSeries], FinalSeries, NewWin1, NewWin2, NextGames).



% Calculate new probability based on winning odds.
update_probability(Team1, Team2, win, CurrentProbability, NewProbability) :-
    winningsOdds(Team1, Team2, Odds),
    WinProbability is Odds / 100,
    NewProbability is CurrentProbability * WinProbability.

update_probability(Team1, Team2, loss, CurrentProbability, NewProbability) :-
    winningsOdds(Team1, Team2, Odds),
    LossProbability is 1 - Odds / 100,
    NewProbability is CurrentProbability * LossProbability.

calculate_series_probability(_, _, [], 1). % Base case: no more games, probability is 1 (100%).
calculate_series_probability(Team1, Team2, [win|Rest], Probability) :-
    winningsOdds(Team1, Team2, Odds), % Get odds for Team1 winning.
    GameProbability is Odds / 100,
    calculate_series_probability(Team1, Team2, Rest, RestProbability), % Recursive call for rest of series.
    Probability is GameProbability * RestProbability.
calculate_series_probability(Team1, Team2, [loss|Rest], Probability) :-
    winningsOdds(Team1, Team2, Odds), % Get odds for Team1 winning, but we need odds for Team2 here.
    GameProbability is 1 - (Odds / 100),
    calculate_series_probability(Team1, Team2, Rest, RestProbability), % Recursive call for rest of series.
    Probability is GameProbability * RestProbability.


determine_winner_and_game_count(Series, Winner, GameCount) :-
    include(==(teamA), Series, WinsA),
    include(==(teamB), Series, WinsB),
    length(WinsA, CountA),
    length(WinsB, CountB),
    (
        CountA > CountB -> Winner = teamA; Winner = teamB
    ),
    length(Series, GameCount).


% Adjust the main predicate to include the teams and probability calculation.
generate_and_display_valid_series_with_probability(Team1, Team2) :-
    generate_valid_series(Series),
    transform_series(Series, Team1, Team2, TransformedSeries),
    calculate_series_probability(Team1, Team2, Series, Probability),
    ProbabilityPercentage is Probability * 100,
    RoundedProbability = round(ProbabilityPercentage * 100) / 100,
    determine_winner(TransformedSeries, Winner, NumGames),
    format('~w - ~2f%. Team ~w wins in ~d games.\n', [TransformedSeries, RoundedProbability, Winner, NumGames]),
    fail.
generate_and_display_valid_series_with_probability(_, _).

% Helper to determine the winning team and the number of games.
determine_winner(Series, Winner, NumGames) :-
    length(Series, NumGames),
    last(Series, Winner).

