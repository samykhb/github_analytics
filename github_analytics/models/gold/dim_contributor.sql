{{ config(materialized='table') }}

with commits as (
    select
        author_login  as login,
        repo_id,
        author_date   as activity_date
    from {{ ref('stg_commits') }}
),

pr as (
    select
        user_login  as login,
        repo_id,
        created_at  as activity_date
    from {{ ref('stg_pull_requests') }}
),

all_activities as (
    select * from commits
    union all
    select * from pr
),

agg as (
    select
        login                       as contributor_id,
        min(activity_date)          as first_contribution_at,
        count(distinct repo_id)     as repos_contributed_to,
        count(*)                    as total_activities
    from all_activities
    where login is not null
      and login != 'Unknown'
    group by login
)

select * from agg