{{ config(
materialized='view'
) }}
with source as (
select * from {{ source('bronze', 'raw_issues') }}
),
cleaned as (
    select 
        repo_full_name as repo_id,
        issue_number,
        title,
        state,
        user_login,
        cast(created_at as timestamp) as created_at,
        cast(updated_at as timestamp) as updated_at,
        cast(closed_at as timestamp) as closed_at,
        comments,
        labels,
        cast(is_pull_request as boolean) as is_pull_request,
        date_diff(
            'hour',
            cast(created_at as timestamp),
            cast(closed_at as timestamp)
        ) as time_to_close_hours
    from source
    where 
        issue_number is not null
        and is_pull_request = false
)-- IMPORTANT: keep only REAL issues
select * from cleaned