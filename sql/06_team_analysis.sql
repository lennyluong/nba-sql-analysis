/*
NBA Player and Team Performance Analysis
File: 06_team_analysis.sql

Question:
Which NBA teams performed best in each regular season?
*/

WITH team_games AS (

    -- Home-team results
    SELECT
        game_id,
        game_date,
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

    -- Away-team results
    SELECT
        game_id,
        game_date,
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
)

SELECT
    season_id,
    team_abbreviation,
    team_name,
    COUNT(*) AS games_played,
    SUM(win) AS wins,
    COUNT(*) - SUM(win) AS losses,
    ROUND(AVG(win::NUMERIC), 3) AS win_percentage,
    ROUND(AVG(points_for), 1) AS average_points_scored,
    ROUND(AVG(points_against), 1) AS average_points_allowed,
    ROUND(AVG(points_for - points_against), 1) AS average_point_differential
FROM team_games
GROUP BY
    season_id,
    team_id,
    team_abbreviation,
    team_name
HAVING COUNT(*) >= 50
ORDER BY
    season_id DESC,
    win_percentage DESC;