{{ config(materialized = 'table') }}

with date_spine as (
    select
        unnest( generate_series(
            current_date - interval '5 years',
            current_date,
            interval '1 day'
        ) )::date as full_date
),

enriched as (
    select
        CAST(strftime(full_date, '%Y%m%d') AS INTEGER) AS date_id,
        full_date,
        EXTRACT(YEAR FROM full_date) AS year,
        EXTRACT(MONTH FROM full_date) AS month,
        EXTRACT(WEEK FROM full_date) AS week_of_year,
        EXTRACT(DOW FROM full_date) AS day_of_week,
        strftime(full_date, '%A') AS day_name,
        strftime(full_date, '%B') AS month_name,
        EXTRACT(DOW FROM full_date) IN (0, 6) AS is_weekend,
        EXTRACT(QUARTER FROM full_date) AS quarter
        
    from date_spine
)

select * from enriched