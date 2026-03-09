-- Verifies that merged_prs never exceeds total_prs
-- in fact_repo_activity

select
    repo_id,
    sum(prs_merged)  as total_merged,
    sum(prs_opened)  as total_opened
from {{ ref('fact_repo_activity') }}
group by repo_id
having sum(prs_merged) > sum(prs_opened)