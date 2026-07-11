/*
NBA Player and Team Performance Analysis
File: 07_draft_analysis.sql

Question:
How do NBA combine measurements differ across draft ranges?
*/

WITH drafted_prospects AS (
    SELECT
        d.season,
        d.person_id,
        d.player_name,
        d.overall_pick,
        d.round_number,
        d.team_abbreviation,
        c.position,
        c.height_w_shoes,
        c.weight,
        c.wingspan,
        c.body_fat_pct,
        c.standing_vertical_leap,
        c.max_vertical_leap,
        c.lane_agility_time,
        c.three_quarter_sprint,
        CASE
            WHEN d.overall_pick BETWEEN 1 AND 14
                THEN 'Lottery Picks'
            WHEN d.overall_pick BETWEEN 15 AND 30
                THEN 'Late First Round'
            WHEN d.overall_pick BETWEEN 31 AND 60
                THEN 'Second Round'
            ELSE 'Other Picks'
        END AS draft_tier
    FROM nba.draft_history d
    INNER JOIN nba.draft_combine_stats c
        ON d.person_id = c.player_id
       AND d.season = c.season
    WHERE d.overall_pick IS NOT NULL
)

SELECT
    draft_tier,
    COUNT(*) AS players,
    ROUND(AVG(overall_pick), 1) AS average_pick,
    ROUND(AVG(height_w_shoes), 2) AS average_height_inches,
    ROUND(AVG(weight), 1) AS average_weight_pounds,
    ROUND(AVG(wingspan), 2) AS average_wingspan_inches,
    ROUND(AVG(body_fat_pct), 2) AS average_body_fat_pct,
    ROUND(AVG(standing_vertical_leap), 2)
        AS average_standing_vertical,
    ROUND(AVG(max_vertical_leap), 2)
        AS average_max_vertical,
    ROUND(AVG(lane_agility_time), 2)
        AS average_lane_agility_time,
    ROUND(AVG(three_quarter_sprint), 2)
        AS average_three_quarter_sprint
FROM drafted_prospects
GROUP BY draft_tier
ORDER BY
    CASE draft_tier
        WHEN 'Lottery Picks' THEN 1
        WHEN 'Late First Round' THEN 2
        WHEN 'Second Round' THEN 3
        ELSE 4
    END;