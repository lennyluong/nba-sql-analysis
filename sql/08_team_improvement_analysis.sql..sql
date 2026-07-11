/*
NBA Player and Team Performance Analysis
File: 08_team_improvement_analysis.sql

Question:
Which NBA teams experienced the largest year-over-year improvements
in regular-season performance?
*/

WITH team_games AS (

    -- Convert each home-team game into one team-level record
    SELECT
        season_id,
        team_id_home AS team_id,
        team_abbreviation_home AS team_abbreviation,
        team_name_home AS team_name,
        pts_home AS points_for,
        pts_away AS points_against,
        CASE
            WHEN pts_home > pts_away THEN 1
            ELSE 0
        END AS win
    FROM nba.v_game_results
    WHERE season_type = 'Regular Season'
      AND pts_home IS NOT NULL
      AND pts_away IS NOT NULL

    UNION ALL

    -- Convert each away-team game into one team-level record
    SELECT
        season_id,
        team_id_away AS team_id,
        team_abbreviation_away AS team_abbreviation,
        team_name_away AS team_name,
        pts_away AS points_for,
        pts_home AS points_against,
        CASE
            WHEN pts_away > pts_home THEN 1
            ELSE 0
        END AS win
    FROM nba.v_game_results
    WHERE season_type = 'Regular Season'
      AND pts_home IS NOT NULL
      AND pts_away IS NOT NULL
),

team_seasons AS (
    SELECT
        season_id,
        RIGHT(season_id::TEXT, 4)::INTEGER AS season_start_year,
        team_id,
        MAX(team_abbreviation) AS team_abbreviation,
        MAX(team_name) AS team_name,
        COUNT(*) AS games_played,
        SUM(win) AS wins,
        AVG(win::NUMERIC) AS win_percentage,
        AVG(points_for - points_against)
            AS average_point_differential
    FROM team_games
    GROUP BY
        season_id,
        team_id
    HAVING COUNT(*) >= 50
),

season_comparisons AS (
    SELECT
        season_id,
        season_start_year,
        team_id,
        team_abbreviation,
        team_name,
        games_played,
        wins,
        win_percentage,
        average_point_differential,

        LAG(wins) OVER (
            PARTITION BY team_id
            ORDER BY season_start_year
        ) AS previous_wins,

        LAG(win_percentage) OVER (
            PARTITION BY team_id
            ORDER BY season_start_year
        ) AS previous_win_percentage,

        LAG(average_point_differential) OVER (
            PARTITION BY team_id
            ORDER BY season_start_year
        ) AS previous_point_differential

    FROM team_seasons
)

SELECT
    season_start_year,
    team_abbreviation,
    team_name,
    games_played,
    wins,
    previous_wins,
    wins - previous_wins AS change_in_wins,
    ROUND(win_percentage, 3) AS win_percentage,
    ROUND(previous_win_percentage, 3)
        AS previous_win_percentage,
    ROUND(
        win_percentage - previous_win_percentage,
        3
    ) AS change_in_win_percentage,
    ROUND(average_point_differential, 1)
        AS average_point_differential,
    ROUND(previous_point_differential, 1)
        AS previous_point_differential,
    ROUND(
        average_point_differential
        - previous_point_differential,
        1
    ) AS change_in_point_differential
FROM season_comparisons
WHERE previous_win_percentage IS NOT NULL
ORDER BY
    change_in_win_percentage DESC,
    change_in_point_differential DESC;