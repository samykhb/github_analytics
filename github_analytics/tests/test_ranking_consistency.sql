-- Verifies that no two repos share the same ranking
-- and that the repo ranked #1 has the highest score_global

with ranking_check as (
    select
        ranking,
        count(*) as cnt
    from {{ ref('scoring_repositories') }}
    group by ranking
    having count(*) > 1
),

top_rank_check as (
    select repo_id
    from {{ ref('scoring_repositories') }}
    where score_global < (
        select max(score_global)
        from {{ ref('scoring_repositories') }}
    )
    and ranking = 1
)

select * from ranking_check
union all
select null, null from top_rank_check
where exists (select 1 from top_rank_check)