{{ config(
    materialized='view'
) }}

with source as (

    select *
    from {{ source('bronze', 'raw_pull_requests') }}

),

cleaned as (

    select 
        repo_full_name as repo_id,
        cast(pr_number as integer) as pr_number,
        title,
        state,
        user_login,
        cast(created_at as timestamp) as created_at,
        cast(updated_at as timestamp) as updated_at,
        cast(closed_at as timestamp) as closed_at,
        cast(merged_at as timestamp) as merged_at,
        comments,
        review_comments,
        labels,

        case 
            when merged_at is null then false 
            else true 
        end as is_merged,

        cast(draft as boolean) as is_draft,

        date_diff(
            'hour',
            cast(created_at as timestamp),
            case
                when (merged_at is not null) <> (closed_at is not null)
                    then coalesce(
                        cast(merged_at as timestamp),
                        cast(closed_at as timestamp)
                    )
                else null
            end
        ) as time_to_close_hours

    from source
    where pr_number is not null

)

select *
from cleaned