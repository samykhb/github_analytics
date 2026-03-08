{{ config(materialized='table') }}

with fact as (
    select f.*, d.full_date
    from {{ ref('fact_repo_activity') }} as f
    join {{ ref('dim_date') }} as d on f.date_id = d.date_id
),

recent_activity as (
    select
        repo_id,
        
        sum(prs_opened) as total_prs,
        sum(prs_merged) as merged_prs,
        sum(issues_opened) as total_issues,
        sum(issues_closed) as closed_issues,

            sum(case when full_date >= current_date - interval '30 days' then commits_count else 0 end) as recent_commits,
        sum(case when full_date >= current_date - interval '30 days' then unique_committers else 0 end) as recent_contributors,
        avg(case when full_date >= current_date - interval '30 days' then avg_pr_close_hours else null end) as recent_avg_pr_close,
        avg(case when full_date >= current_date - interval '30 days' then avg_issue_close_hours else null end) as recent_avg_issue_close
        
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

        -- On gère les repositories inactifs avec un COALESCE très grand pour les pénaliser
        COALESCE(a.recent_avg_pr_close, 10000000) as avg_pr_close,
        COALESCE(a.recent_avg_issue_close, 10000000) as avg_issue_close,

        case when a.total_prs > 0 then a.merged_prs * 1.0 / a.total_prs else 0 end as pr_merge_ratio,
        case when a.total_issues > 0 then a.closed_issues * 1.0 / a.total_issues else 0 end as issue_close_ratio

    from {{ ref('dim_repository') }} r
    left join recent_activity a on r.repo_id = a.repo_id
),


ranked as (
    select
        repo_id,
        repo_name,
        
        -- Popularité
        NTILE(10) OVER (ORDER BY stars_count ASC) as rank_stars,
        NTILE(10) OVER (ORDER BY forks_count ASC) as rank_forks,
        NTILE(10) OVER (ORDER BY watchers_count ASC) as rank_watchers,

        -- Activité
        NTILE(10) OVER (ORDER BY recent_commits ASC) as rank_commits,
        NTILE(10) OVER (ORDER BY recent_contributors ASC) as rank_contributors,

        -- Réactivité
        NTILE(10) OVER (ORDER BY avg_pr_close DESC) as rank_pr_close,
        NTILE(10) OVER (ORDER BY avg_issue_close DESC) as rank_issue_close,

        -- Communauté
        NTILE(10) OVER (ORDER BY pr_merge_ratio ASC) as rank_pr_ratio,
        NTILE(10) OVER (ORDER BY issue_close_ratio ASC) as rank_issue_ratio
        
    from base_metrics
),

scored as (
    select
        repo_id,
        repo_name,
        (rank_stars + rank_forks + rank_watchers) * 100.0 / 30.0 as score_popularity,
        (rank_commits + rank_contributors) * 100.0 / 20.0 as score_activity,
        (rank_pr_close + rank_issue_close) * 100.0 / 20.0 as score_responsiveness,
        (rank_pr_ratio + rank_issue_ratio) * 100.0 / 20.0 as score_community
    from ranked
)

select
    repo_id,
    repo_name,
    score_popularity,
    score_activity,
    score_responsiveness,
    score_community,
    
    (score_popularity * 0.20) + (score_activity * 0.30) + 
    (score_responsiveness * 0.30) + (score_community * 0.20) as score_global,
    
    RANK() OVER (
        ORDER BY (score_popularity * 0.20) + (score_activity * 0.30) + 
                 (score_responsiveness * 0.30) + (score_community * 0.20) DESC
    ) as ranking
    
from scored
ORDER BY ranking