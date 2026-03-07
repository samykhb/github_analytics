-- tests/assert_scoring_completeness.sql
-- Fails if a repository exists in the dimension but is missing from the final scoring table
select
    d.repo_id,
    d.repo_name
from 
    {{ ref('dim_repository') }} as d
left join 
    {{ ref('scoring_repositories') }} as s
on d.repo_id = s.repo_id
where 
    s.repo_id is null