-- models/silver/stg_commits.sql
{{ config(
    materialized='incremental',
    incremental_strategy='append'
) }}

with source as (
    select * from {{ source('bronze', 'raw_commits') }}
    
    {% if is_incremental() %}
    where CAST(author_date AS TIMESTAMP) > (select max(author_date) from {{ this }})
    {% endif %}
),

cleaned as (
    select
        sha AS commit_sha,
        repo_full_name AS repo_id,
        COALESCE(author_login, 'Unknown') AS author_login,
        CAST(author_date AS TIMESTAMP) AS author_date,
        CAST(committer_date AS TIMESTAMP) AS committer_date,
        EXTRACT(DOW FROM CAST(author_date AS TIMESTAMP)) AS day_of_week,
        EXTRACT(HOUR FROM CAST(author_date AS TIMESTAMP)) AS hour_of_day,
        LEFT(message, 200) AS message
    from source
    where sha is not null
)

select * from cleaned