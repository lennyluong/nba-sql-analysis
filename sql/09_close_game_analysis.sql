/*
NBA Player and Team Performance Analysis
File: 09_close_game_analysis.sql

Question:
Which NBA teams performed best in close regular-season games?

A close game is defined as a game decided by five points or fewer.
*/

WITH close_games AS (

    -- Home-team perspective
    SELECT
        season_id,
        RIGHT(season_id::TEXT, 4)::INTEGER AS season_start_year,
        game_id,
        team_id_home AS team_id,
        team_abbreviation_home AS team_abbreviation,
        team_name_home AS team_name,
        ABS(pts_home - pts_away) AS final_margin,
        CASE
            WHEN pts_home > pts_away THEN 1
            ELSE 0
        END AS win
    FROM nba.v_game_results
    WHERE season_type = 'Regular Season'
      AND pts_home IS NOT NULL
      AND pts_away IS NOT NULL
      AND ABS(pts_home - pts_away) <= 5

    UNION ALL

    -- Away-team perspective
    SELECT
        season_id,
        RIGHT(season_id::TEXT, 4)::INTEGER AS season_start_year,
        game_id,
        team_id_away AS team_id,
        team_abbreviation_away AS team_abbreviation,
        team_name_away AS team_name,
        ABS(pts_home - pts_away) AS final_margin,
        CASE
            WHEN pts_away > pts_home THEN 1
            ELSE 0
        END AS win
    FROM nba.v_game_results
    WHERE season_type = 'Regular Season'
      AND pts_home IS NOT NULL
      AND pts_away IS NOT NULL
      AND ABS(pts_home - pts_away) <= 5
),

team_close_game_summary AS (
    SELECT
        season_id,
        season_start_year,
        team_id,
        MAX(team_abbreviation) AS team_abbreviation,
        MAX(team_name) AS team_name,
        COUNT(*) AS close_games_played,
        SUM(win) AS close_game_wins,
        COUNT(*) - SUM(win) AS close_game_losses,
        AVG(win::NUMERIC) AS close_game_win_percentage,
        AVG(final_margin) AS average_close_game_margin
    FROM close_games
    GROUP BY
        season_id,
        season_start_year,
        team_id
    HAVING COUNT(*) >= 10
),

ranked_teams AS (
    SELECT
        *,
        RANK() OVER (
            PARTITION BY season_start_year
            ORDER BY
                close_game_win_percentage DESC,
                close_games_played DESC
        ) AS season_close_game_rank
    FROM team_close_game_summary
)

SELECT
    season_start_year,
    team_abbreviation,
    team_name,
    close_games_played,
    close_game_wins,
    close_game_losses,
    ROUND(close_game_win_percentage, 3)
        AS close_game_win_percentage,
    ROUND(average_close_game_margin, 2)
        AS average_close_game_margin,
    season_close_game_rank
FROM ranked_teams
ORDER BY
    season_start_year DESC,
    season_close_game_rank,
    team_abbreviation;