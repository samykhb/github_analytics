{{ config(materialized='table') }}

with repo as (
    select * from {{ ref('stg_repositories') }}
)

select
    repo_id,
    repo_name,
    owner_login,
    description,
    language,
    license_name,
    created_at,
    repo_age_days,
    stars_count,
    forks_count,
    watchers_count,
    default_branch,
    has_wiki,
    has_pages
from repo