{{ config(materialized='view') }}

with source as (
    select *
    from {{ source('bronze', 'raw_repositories') }}
),

cleaned as (
    select
        full_name as repo_id,
        name as repo_name,
        owner_login,
        description,
        language,
        date_diff('day', cast(created_at as timestamp), current_date()) as repo_age_days,
        cast(created_at as timestamp) as created_at,
        cast(updated_at as timestamp) as updated_at,
        cast(pushed_at as timestamp) as pushed_at,
        cast(stargazers_count as integer) as stars_count,
        cast(watchers_count as integer) as watchers_count,
        cast(forks_count as integer) as forks_count,
        cast(open_issues_count as integer) as open_issues_count,
        size,
        default_branch,
        has_wiki,
        has_pages,
        archived,
        disabled,
        license_name,
        topics,
        network_count,
        cast(subscribers_count as integer) as subscribers_count,
        snapshot_date,
        coalesce(description, 'No description') as description_clean,
        coalesce(language, 'Unknown') as language_clean
    from source
    where archived != 'True'
)

select *
from cleaned