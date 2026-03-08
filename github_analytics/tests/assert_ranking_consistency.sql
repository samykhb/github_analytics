-- tests/assert_ranking_consistency.sql
-- Fails if the #1 ranked repo does not have the absolute best score
with max_score_cte as (
    select 
        max(score_global) as max_score
    from {{ ref('scoring_repositories') }}  
)

select
    s.repo_id,
    s.score_global,
    s.ranking
from 
    {{ ref('scoring_repositories') }} as s
cross join 
    max_score_cte as m
where 
    s.ranking = 1 
    and s.score_global < m.max_score