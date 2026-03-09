{{ config(materialized='table') }}

with fact as (
    select
        f.*,
        d.full_date
    from {{ ref('fact_repo_activity') }} as f
    join {{ ref('dim_date') }} as d on f.date_id = d.date_id
),

recent_activity as (
    select
        repo_id,

        sum(prs_opened)                                                                     as total_prs,
        sum(prs_merged)                                                                     as merged_prs,
        sum(issues_opened)                                                                  as total_issues,
        sum(issues_closed)                                                                  as closed_issues,

        sum(case when full_date >= current_date - interval '30 days'
                 then commits_count else 0 end)                                             as recent_commits,
        max(case when full_date >= current_date - interval '30 days'
                 then unique_committers else 0 end)                                         as recent_contributors,
        avg(case when full_date >= current_date - interval '30 days'
                 then avg_pr_close_hours else null end)                                     as recent_avg_pr_close,
        avg(case when full_date >= current_date - interval '30 days'
                 then avg_issue_close_hours else null end)                                  as recent_avg_issue_close

    from fact
    group by repo_id
),

base_metrics as (
    select
        r.repo_id,
        r.repo_name,

        r.stars_count,
        r.forks_count,
        r.watchers_count,

        a.recent_commits,
        a.recent_contributors,

        coalesce(a.recent_avg_pr_close, 999999)       as avg_pr_close,
        coalesce(a.recent_avg_issue_close, 999999)    as avg_issue_close,

        case when a.total_prs > 0
             then a.merged_prs * 1.0 / a.total_prs
             else 0 end                                 as pr_merge_ratio,
        case when a.total_issues > 0
             then a.closed_issues * 1.0 / a.total_issues
             else 0 end                                 as issue_close_ratio

    from {{ ref('dim_repository') }} as r
    left join recent_activity as a on r.repo_id = a.repo_id
),

ranked as (
    select
        repo_id,
        repo_name,

        ntile(10) over (order by stars_count asc)           as rank_stars,
        ntile(10) over (order by forks_count asc)           as rank_forks,
        ntile(10) over (order by watchers_count asc)        as rank_watchers,

        ntile(10) over (order by recent_commits asc)        as rank_commits,
        ntile(10) over (order by recent_contributors asc)   as rank_contributors,

        ntile(10) over (order by avg_pr_close desc)         as rank_pr_close,
        ntile(10) over (order by avg_issue_close desc)      as rank_issue_close,

        ntile(10) over (order by pr_merge_ratio asc)        as rank_pr_ratio,
        ntile(10) over (order by issue_close_ratio asc)     as rank_issue_ratio

    from base_metrics
),

scored as (
    select
        repo_id,
        repo_name,
        (rank_stars + rank_forks + rank_watchers)   * 100.0 / 30.0     as score_popularity,
        (rank_commits + rank_contributors)           * 100.0 / 20.0     as score_activity,
        (rank_pr_close + rank_issue_close)           * 100.0 / 20.0     as score_responsiveness,
        (rank_pr_ratio + rank_issue_ratio)           * 100.0 / 20.0     as score_community
    from ranked
)

select
    repo_id,
    repo_name,
    round(score_popularity, 2)                                          as score_popularity,
    round(score_activity, 2)                                            as score_activity,
    round(score_responsiveness, 2)                                      as score_responsiveness,
    round(score_community, 2)                                           as score_community,
    round(
        (score_popularity * 0.20) + (score_activity * 0.30) +
        (score_responsiveness * 0.30) + (score_community * 0.20), 2
    )                                                                   as score_global,
    rank() over (
        order by
            (score_popularity * 0.20) + (score_activity * 0.30) +
            (score_responsiveness * 0.30) + (score_community * 0.20) desc
    )                                                                   as ranking

from scored
order by ranking