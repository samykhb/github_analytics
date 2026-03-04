-- models/silver/stg_commits.sql
{{ config (
materialized = 'view'
) }}

with source as (
select * from {{ source ( 'bronze', 'raw_commits') }}
) ,

cleaned as (
SELECT 
    repo_full_name AS repo_id,
    sha AS commit_sha,
    COALESCE(author_login, 'Unknown') AS author_login,
    CAST(author_date AS TIMESTAMP) AS author_date,
    committer_login,
    CAST(committer_date AS TIMESTAMP) AS committer_date,
    EXTRACT(DOW FROM CAST(author_date AS TIMESTAMP)) AS day_of_week,
    EXTRACT(HOUR FROM CAST(author_date AS TIMESTAMP)) AS hour_of_day,
    LEFT(message, 200) AS message
FROM 
    source
WHERE
    commit_sha IS NOT NULL    

)
select * from cleaned

