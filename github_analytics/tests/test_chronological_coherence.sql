-- Verifies that closed_at is always after created_at
-- in stg_pull_requests and stg_issues

select 'pull_request' as source, pr_number as id, created_at, closed_at
from {{ ref('stg_pull_requests') }}
where closed_at is not null
  and closed_at < created_at

union all

select 'issue' as source, issue_number as id, created_at, closed_at
from {{ ref('stg_issues') }}
where closed_at is not null
  and closed_at < created_at