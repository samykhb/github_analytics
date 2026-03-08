{{ config(materialized='table') }}

with daily_commits as (
    select
        repo_id,
        CAST(author_date AS DATE) as activity_date,
        count(*) as commits_count,
        count(distinct author_login) as unique_committers
    from {{ ref('stg_commits') }}
    group by repo_id, CAST(author_date AS DATE)
),

daily_prs as (
    select
        repo_id,
        CAST(created_at AS DATE) as activity_date,
        count(*) as prs_opened,
        sum(case when is_merged = true then 1 else 0 end) as prs_merged,
        avg(time_to_close_hours) as avg_pr_close_hours
    from {{ ref('stg_pull_requests') }}
    group by repo_id, CAST(created_at AS DATE)
),

daily_issues as (
    select
        repo_id,
        cast(created_at AS DATE) as activity_date,
        count(*) as issues_opened,
        sum(case when closed_at is not null then 1 else 0 end) as issues_closed,
        avg(time_to_close_hours) as avg_issue_close_hours
    from {{ ref('stg_issues') }}
    group by repo_id, cast(created_at AS DATE)
),

all_dates_repos as (
    select repo_id, activity_date from daily_commits
    union
    select repo_id, activity_date from daily_prs
    union
    select repo_id, activity_date from daily_issues
),

joined as (
    select
        adr.repo_id,
        
        CAST(strftime(adr.activity_date, '%Y%m%d') AS INTEGER) as date_id,
        
        COALESCE(commits.commits_count, 0) as commits_count,
        COALESCE(commits.unique_committers, 0) as unique_committers,
        
        COALESCE(prs.prs_opened, 0) as prs_opened,
        COALESCE(prs.prs_merged, 0) as prs_merged,
        prs.avg_pr_close_hours,
        
        COALESCE(issues.issues_opened, 0) as issues_opened,
        COALESCE(issues.issues_closed, 0) as issues_closed,
        issues.avg_issue_close_hours
        
    from all_dates_repos as adr
    left join daily_commits as commits
        on adr.repo_id = commits.repo_id and adr.activity_date = commits.activity_date
    left join daily_prs as prs 
        on adr.repo_id = prs.repo_id and adr.activity_date = prs.activity_date
    left join daily_issues as issues 
        on adr.repo_id = issues.repo_id and adr.activity_date = issues.activity_date
)

select * from joined