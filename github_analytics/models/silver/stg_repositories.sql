-- models/silver/stg_repositories.sql
{{ config (
materialized = 'view'
) }}

with source as (
    select * from {{ source ('bronze', 'raw_repositories') }}
    -- pb quand je faisais dbt test avec les nouvelles tables incrementales : 
    -- on garde uniquement la ligne la plus récente pour chaque dépôt
    QUALIFY ROW_NUMBER() OVER (PARTITION BY full_name ORDER BY snapshot_date DESC) = 1
),

cleaned as (
SELECT 
    full_name AS repo_id,
    name AS repo_name,
    owner_login,
    COALESCE(description, 'No description') AS description,
    COALESCE(language, 'Unknown') AS language,
    CAST(created_at AS TIMESTAMP) AS created_at,
    CAST(updated_at AS TIMESTAMP) AS updated_at,
    CAST(pushed_at AS TIMESTAMP) AS pushed_at,
    CAST(stargazers_count AS INTEGER) AS stars_count,
    CAST(watchers_count AS INTEGER) AS watchers_count,
    CAST(forks_count AS INTEGER) AS forks_count,
    CAST(open_issues_count AS INTEGER) AS open_issues_count,
    CAST(size AS INTEGER) AS size,
    default_branch,
    has_wiki,
    has_pages,
    archived,
    disabled,
    license_name,
    CAST(network_count AS INTEGER) AS network_count,
    CAST(subscribers_count AS INTEGER) AS subscribers_count,
    CAST(snapshot_date AS TIMESTAMP) AS snapshot_date,
    DATE_DIFF('day', CAST(created_at AS TIMESTAMP), CURRENT_DATE) AS repo_age_days
FROM
    source
WHERE
    archived = false
    

)
select * from cleaned


