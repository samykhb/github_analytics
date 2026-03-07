-- models/silver/stg_issues.sql
{{ config(
    materialized='incremental',
    unique_key=['repo_id', 'issue_number'],
    incremental_strategy='merge'
) }}

with source as (
    select * from {{ source('bronze', 'raw_issues') }}
    
    {% if is_incremental() %}
    where CAST(updated_at AS TIMESTAMP) > (select max(updated_at) from {{ this }})
    {% endif %}
),

cleaned as (
    select
        repo_full_name as repo_id,
        CAST(issue_number AS INTEGER) as issue_number,
        title,
        state,
        user_login,
        CAST(created_at AS TIMESTAMP) as created_at,
        CAST(updated_at AS TIMESTAMP) as updated_at,
        CAST(closed_at AS TIMESTAMP) as closed_at,
        CAST(is_pull_request AS BOOLEAN) as is_pull_request,
        
        CASE
            WHEN closed_at IS NOT NULL THEN DATE_DIFF('hour', CAST(created_at AS TIMESTAMP), CAST(closed_at AS TIMESTAMP))
            ELSE NULL
        END AS time_to_close_hours
    from source
    where issue_number is not null
      and CAST(is_pull_request AS BOOLEAN) = false
)

select * from cleaned