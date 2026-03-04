-- models/silver/stg_issues.sql
{{ config (
materialized = 'view'
) }}

with source as (
select * from {{ source ( 'bronze', 'raw_issues') }}
) ,

cleaned as (
SELECT 
    repo_full_name AS repo_id,
    issue_number,
    title,
    state,
    user_login,
    CAST(created_at AS TIMESTAMP) AS created_at,
    CAST(updated_at AS TIMESTAMP) AS updated_at,
    CAST(closed_at AS TIMESTAMP) AS closed_at,
    CASE
        WHEN closed_at IS NOT NULL THEN DATE_DIFF('hour', CAST(created_at AS TIMESTAMP), CAST(closed_at AS TIMESTAMP))
        ELSE NULL
    END AS time_to_close_hours,
    comments,
    labels,
    CAST(is_pull_request AS BOOLEAN) AS is_pull_request
FROM 
    source
WHERE
    issue_number IS NOT NULL
)
select * from cleaned
where is_pull_request = false

