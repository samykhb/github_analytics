-- tests/assert_chronological_coherence.sql
-- Fails if any PR or issue has a closed_at timestamp before its created_at timestamp
select
    'pull_request' as entity_type,
    repo_id,
    pr_number as entity_id,
    created_at,
    closed_at
from 
    {{ ref('stg_pull_requests') }}
where 
    closed_at is not null 
    and closed_at < created_at

union all

select
    'issue' as entity_type,
    repo_id,
    issue_number as entity_id,
    created_at,
    closed_at
from 
    {{ ref('stg_issues') }}
where 
    closed_at is not null 
    and closed_at < created_at