-- models/silver/stg_pull_requests.sql
{{ config (
materialized = 'view'
) }}

with source as (
select * from {{ source ( 'bronze', 'raw_pull_requests') }}
) ,

cleaned as (
SELECT 
    repo_full_name AS repo_id,
    CAST(pr_number AS INTEGER) AS pr_number,
    title,
    state,
    COALESCE(user_login, 'Unknown') AS user_login,
    CAST(created_at AS TIMESTAMP) AS created_at,
    CAST(updated_at AS TIMESTAMP) AS updated_at,
    CAST(closed_at AS TIMESTAMP) AS closed_at,
    CAST(merged_at AS TIMESTAMP) AS merged_at,
    CASE WHEN merged_at IS NULL THEN false ELSE true END AS is_merged,
    draft AS is_draft,
    CASE
        WHEN merged_at IS NOT NULL THEN DATE_DIFF('hour', CAST(created_at AS TIMESTAMP), CAST(merged_at AS TIMESTAMP))
        WHEN closed_at IS NOT NULL THEN DATE_DIFF('hour', CAST(created_at AS TIMESTAMP), CAST(closed_at AS TIMESTAMP))
        ELSE NULL
    END AS time_to_close_hours,
    comments,
    review_comments,
    labels
FROM 
    source
WHERE
    pr_number IS NOT NULL
)
select * from cleaned

