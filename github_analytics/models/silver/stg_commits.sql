{{ config(
    materialized='view'
) }}

with source as (

    select *
    from {{ source('bronze', 'raw_commits') }}

),

cleaned as (

    select
        repo_full_name as repo_id,
        sha as commit_sha,
        coalesce(author_login, 'Unknown') as author_login,
        cast(author_date as timestamp) as author_date,
        dayofweek(cast(author_date as timestamp)) as day_of_week,
        hour(cast(author_date as timestamp)) as hour_of_day,
        committer_login,
        cast(committer_date as timestamp) as committer_date,
        left(message, 200) as message

    from source
    where sha is not null

)

select *
from cleaned