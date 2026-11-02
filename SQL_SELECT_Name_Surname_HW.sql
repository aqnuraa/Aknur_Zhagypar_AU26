/*
Homework tasks: TASK 1

The marketing team needs a list of animation movies between
2017 and 2019 to promote family-friendly content in an
upcoming season in stores.

Show all animation movies released during this period
with rate more than 1, sorted alphabetically.
*/

-- CTE METHOD

WITH animation_movies AS (
    SELECT
        f.film_id,
        f.title,
        f.release_year,
        f.rental_rate
    FROM public.film AS f
    INNER JOIN public.film_category AS fc
        ON f.film_id = fc.film_id
    INNER JOIN public.category AS c
        ON fc.category_id = c.category_id
    WHERE c.name = 'Animation'
      AND f.release_year BETWEEN 2017 AND 2019
      AND f.rental_rate > 1
)
SELECT
    title,
    release_year,
    rental_rate
FROM animation_movies
ORDER BY title ASC;

-- Subquery Method

SELECT
    f.title,
    f.release_year,
    f.rental_rate
FROM public.film AS f
WHERE f.release_year BETWEEN 2017 AND 2019
  AND f.rental_rate > 1
  AND f.film_id IN (
      SELECT fc.film_id
      FROM public.film_category AS fc
      INNER JOIN public.category AS c
          ON fc.category_id = c.category_id
      WHERE c.name = 'Animation'
  )
ORDER BY f.title ASC;

-- Direct JOIN

SELECT
    f.title,
    f.release_year,
    f.rental_rate
FROM public.film AS f
INNER JOIN public.film_category AS fc
    ON f.film_id = fc.film_id
INNER JOIN public.category AS c
    ON fc.category_id = c.category_id
WHERE c.name = 'Animation'
  AND f.release_year BETWEEN 2017 AND 2019
  AND f.rental_rate > 1
ORDER BY f.title ASC;

/* I would choose Direct JOIN method since it is the simplest way to retrieve the information from the given tables */


/*
TASK 2

The finance department requires a report on store performance
to assess profitability and plan resource allocation for stores
after March 2017 (since April).

Calculate the revenue earned by each rental store
(include columns: address and address2 – as one column, revenue).
*/

-- CTE approach

WITH store_revenue AS (
    SELECT
        i.store_id,
        COALESCE(SUM(p.amount), 0) AS revenue
    FROM public.inventory AS i
    LEFT JOIN public.rental AS r
        ON i.inventory_id = r.inventory_id
    LEFT JOIN public.payment AS p
        ON r.rental_id = p.rental_id
       AND p.payment_date >= DATE '2017-04-01'
    GROUP BY i.store_id
)
SELECT
    CONCAT_WS(' ', a.address, a.address2) AS address,
    COALESCE(sr.revenue, 0) AS revenue
FROM public.store AS s
INNER JOIN public.address AS a
    ON s.address_id = a.address_id
LEFT JOIN store_revenue AS sr
    ON s.store_id = sr.store_id
ORDER BY address ASC;


-- Subquery approach

SELECT
    CONCAT_WS(' ', a.address, a.address2) AS address,
    COALESCE(sr.revenue, 0) AS revenue
FROM public.store AS s
INNER JOIN public.address AS a
    ON s.address_id = a.address_id
LEFT JOIN (
    SELECT
        i.store_id,
        SUM(p.amount) AS revenue
    FROM public.inventory AS i
    LEFT JOIN public.rental AS r
        ON i.inventory_id = r.inventory_id
    LEFT JOIN public.payment AS p
        ON r.rental_id = p.rental_id
       AND p.payment_date >= DATE '2017-04-01'
    GROUP BY i.store_id
) AS sr
    ON s.store_id = sr.store_id
ORDER BY address ASC;



-- Direct JOIN approach

SELECT
    CONCAT_WS(' ', a.address, a.address2) AS address,
    COALESCE(SUM(p.amount), 0) AS revenue
FROM public.store AS s
INNER JOIN public.address AS a
    ON s.address_id = a.address_id
LEFT JOIN public.inventory AS i
    ON s.store_id = i.store_id
LEFT JOIN public.rental AS r
    ON i.inventory_id = r.inventory_id
LEFT JOIN public.payment AS p
    ON r.rental_id = p.rental_id
   AND p.payment_date >= DATE '2017-04-01'
GROUP BY
    s.store_id,
    a.address,
    a.address2
ORDER BY address ASC;


-- My preference: I'd choose the direct JOIN for this relatively small report. It clearly shows how the store connects to its payments. 
-- The CTE or derived-table approach can be preferable if the revenue calculation is reused in a larger reporting query.



/* TASK 3
The marketing department in our stores aims to identify the
most successful actors since 2015 to boost customer interest
in their films.

Show top-5 actors by number of movies (released since 2015)
they took part in (columns: first_name, last_name,
number_of_movies, sorted by number_of_movies in descending order).
*/



-- CTE Approach
WITH actor_movie_counts AS (
    SELECT
        a.actor_id,
        a.first_name,
        a.last_name,
        COUNT(DISTINCT f.film_id) AS number_of_movies
    FROM public.actor AS a
    INNER JOIN public.film_actor AS fa
        ON a.actor_id = fa.actor_id
    INNER JOIN public.film AS f
        ON fa.film_id = f.film_id
    WHERE f.release_year >= 2015
    GROUP BY
        a.actor_id,
        a.first_name,
        a.last_name
)
SELECT
    first_name,
    last_name,
    number_of_movies
FROM actor_movie_counts
ORDER BY number_of_movies DESC, last_name ASC, first_name ASC
LIMIT 5;

-- Subquery approach

SELECT
    a.first_name,
    a.last_name,
    (
        SELECT COUNT(DISTINCT f.film_id)
        FROM public.film_actor AS fa
        INNER JOIN public.film AS f
            ON fa.film_id = f.film_id
        WHERE fa.actor_id = a.actor_id
          AND f.release_year >= 2015
    ) AS number_of_movies
FROM public.actor AS a
WHERE EXISTS (
    SELECT 1
    FROM public.film_actor AS fa
    INNER JOIN public.film AS f
        ON fa.film_id = f.film_id
    WHERE fa.actor_id = a.actor_id
      AND f.release_year >= 2015
)
ORDER BY number_of_movies DESC, a.last_name ASC, a.first_name ASC
LIMIT 5;


-- JOIN metod

SELECT
    a.first_name,
    a.last_name,
    COUNT(DISTINCT f.film_id) AS number_of_movies
FROM public.actor AS a
INNER JOIN public.film_actor AS fa
    ON a.actor_id = fa.actor_id
INNER JOIN public.film AS f
    ON fa.film_id = f.film_id
WHERE f.release_year >= 2015
GROUP BY
    a.actor_id,
    a.first_name,
    a.last_name
ORDER BY
    number_of_movies DESC,
    a.last_name ASC,
    a.first_name ASC
LIMIT 5;

/* In this task CTE seems like a good option, it clearly separates aggregation from final ranking */





/* TASK 4 
 
The marketing team needs to track the production trends of
Drama, Travel, and Documentary films to inform genre-specific
marketing strategies.

Show number of Drama, Travel, Documentary per year
(include columns: release_year, number_of_drama_movies,
number_of_travel_movies, number_of_documentary_movies),
sorted by release year in descending order.

Dealing with NULL values is encouraged.
*/


-- CTE method

WITH yearly_genres AS (
    SELECT
        f.release_year,
        COUNT(DISTINCT f.film_id)
            FILTER (WHERE c.name = 'Drama') AS number_of_drama_movies,
        COUNT(DISTINCT f.film_id)
            FILTER (WHERE c.name = 'Travel') AS number_of_travel_movies,
        COUNT(DISTINCT f.film_id)
            FILTER (WHERE c.name = 'Documentary') AS number_of_documentary_movies
    FROM public.film AS f
    LEFT JOIN public.film_category AS fc
        ON f.film_id = fc.film_id
    LEFT JOIN public.category AS c
        ON fc.category_id = c.category_id
       AND c.name IN ('Drama', 'Travel', 'Documentary')
    GROUP BY f.release_year
)
SELECT
    COALESCE(release_year::TEXT, 'Unknown') AS release_year,
    number_of_drama_movies,
    number_of_travel_movies,
    number_of_documentary_movies
FROM yearly_genres
ORDER BY release_year DESC;



-- Subquery


SELECT
    COALESCE(years.release_year::TEXT, 'Unknown') AS release_year,

    (
        SELECT COUNT(DISTINCT f.film_id)
        FROM public.film AS f
        INNER JOIN public.film_category AS fc
            ON f.film_id = fc.film_id
        INNER JOIN public.category AS c
            ON fc.category_id = c.category_id
        WHERE f.release_year IS NOT DISTINCT FROM years.release_year
          AND c.name = 'Drama'
    ) AS number_of_drama_movies,
    
    
    (
        SELECT COUNT(DISTINCT f.film_id)
        FROM public.film AS f
        INNER JOIN public.film_category AS fc
            ON f.film_id = fc.film_id
        INNER JOIN public.category AS c
            ON fc.category_id = c.category_id
        WHERE f.release_year IS NOT DISTINCT FROM years.release_year
          AND c.name = 'Travel'
    ) AS number_of_travel_movies,

    (
        SELECT COUNT(DISTINCT f.film_id)
        FROM public.film AS f
        INNER JOIN public.film_category AS fc
            ON fc.film_id = f.film_id
        INNER JOIN public.category AS c
            ON c.category_id = fc.category_id
        WHERE f.release_year IS NOT DISTINCT FROM years.release_year
          AND c.name = 'Documentary'
    ) AS number_of_documentary_movies

FROM (
    SELECT DISTINCT release_year
    FROM public.film
) AS years

ORDER BY years.release_year DESC NULLS LAST;



-- DIRECT JOIN

SELECT
    COALESCE(f.release_year::TEXT, 'Unknown') AS release_year,

    COUNT(DISTINCT CASE
        WHEN c.name = 'Drama' THEN f.film_id
    END) AS number_of_drama_movies,

    COUNT(DISTINCT CASE
        WHEN c.name = 'Travel' THEN f.film_id
    END) AS number_of_travel_movies,

    COUNT(DISTINCT CASE
        WHEN c.name = 'Documentary' THEN f.film_id
    END) AS number_of_documentary_movies

FROM public.film AS f

LEFT JOIN public.film_category AS fc
    ON f.film_id = fc.film_id

LEFT JOIN public.category AS c
    ON fc.category_id = c.category_id
   AND c.name IN ('Drama', 'Travel', 'Documentary')

GROUP BY f.release_year

ORDER BY f.release_year DESC NULLS LAST;

/* It is better for me to choose Join method, DIRECT JOIN, since it is easy to read, and
 calculates all three genre counts in one grouped query. */




-- PART 2: Task 1. Top three employees by revenue in 2017

-- CTE Approach

WITH employee_revenue AS (
    -- Calculate total revenue generated by each employee in 2017.
    SELECT
        p.staff_id,
        SUM(p.amount) AS total_revenue
    FROM your_schema.payment AS p
    WHERE p.payment_date >= DATE '2017-01-01'
      AND p.payment_date < DATE '2018-01-01'
    GROUP BY p.staff_id
),
last_employee_store AS (
    -- Identify the store associated with each employee's latest
    -- payment in 2017. payment_id resolves equal timestamps.
    SELECT DISTINCT ON (p.staff_id)
        p.staff_id,
        i.store_id
    FROM your_schema.payment AS p
    INNER JOIN your_schema.rental AS r
        ON p.rental_id = r.rental_id
    INNER JOIN your_schema.inventory AS i
        ON r.inventory_id = i.inventory_id
    WHERE p.payment_date >= DATE '2017-01-01'
      AND p.payment_date < DATE '2018-01-01'
    ORDER BY
        p.staff_id,
        p.payment_date DESC,
        p.payment_id DESC
)
SELECT
    s.first_name,
    s.last_name,
    les.store_id,
    er.total_revenue
FROM employee_revenue AS er
INNER JOIN your_schema.staff AS s
    ON er.staff_id = s.staff_id
INNER JOIN last_employee_store AS les
    ON er.staff_id = les.staff_id
ORDER BY er.total_revenue DESC
LIMIT 3;


-- Subquery method

/*
The HR department aims to reward top-performing employees in 2017
with bonuses to recognize their contribution to stores revenue.

Show which three employees generated the most revenue in 2017?

Assumptions:
- Staff could work in several stores in a year.
  Please indicate which store the staff worked in (the last one).
- If staff processed the payment then he works in the same store.
- Take into account only payment_date.
*/

SELECT
    s.first_name,
    s.last_name,

    (
        SELECT i.store_id
        FROM your_schema.payment AS p2
        INNER JOIN your_schema.rental AS r2
            ON p2.rental_id = r2.rental_id
        INNER JOIN your_schema.inventory AS i
            ON r2.inventory_id = i.inventory_id
        WHERE p2.staff_id = s.staff_id
          AND p2.payment_date >= DATE '2017-01-01'
          AND p2.payment_date < DATE '2018-01-01'
        ORDER BY
            p2.payment_date DESC,
            p2.payment_id DESC
        LIMIT 1
    ) AS store_id,

    (
        SELECT SUM(p.amount)
        FROM your_schema.payment AS p
        WHERE p.staff_id = s.staff_id
          AND p.payment_date >= DATE '2017-01-01'
          AND p.payment_date < DATE '2018-01-01'
    ) AS total_revenue

FROM your_schema.staff AS s
WHERE EXISTS (
    SELECT 1
    FROM your_schema.payment AS p
    WHERE p.staff_id = s.staff_id
      AND p.payment_date >= DATE '2017-01-01'
      AND p.payment_date < DATE '2018-01-01'
)
ORDER BY total_revenue DESC
LIMIT 3;


-- DIRECT JOIN Method

/*
The HR department aims to reward top-performing employees in 2017
with bonuses to recognize their contribution to stores revenue.

Show which three employees generated the most revenue in 2017?

Assumptions:
- Staff could work in several stores in a year.
  Please indicate which store the staff worked in (the last one).
- If staff processed the payment then he works in the same store.
- Take into account only payment_date.
*/

SELECT
    s.first_name,
    s.last_name,
    last_store.store_id,
    SUM(p.amount) AS total_revenue

FROM your_schema.staff AS s

INNER JOIN your_schema.payment AS p
    ON s.staff_id = p.staff_id

INNER JOIN your_schema.rental AS r
    ON p.rental_id = r.rental_id

INNER JOIN your_schema.inventory AS i
    ON r.inventory_id = i.inventory_id

-- Identify the last store associated with each employee's payments.
INNER JOIN (
    SELECT DISTINCT ON (p2.staff_id)
        p2.staff_id,
        i2.store_id
    FROM your_schema.payment AS p2
    INNER JOIN your_schema.rental AS r2
        ON p2.rental_id = r2.rental_id
    INNER JOIN your_schema.inventory AS i2
        ON r2.inventory_id = i2.inventory_id
    WHERE p2.payment_date >= DATE '2017-01-01'
      AND p2.payment_date < DATE '2018-01-01'
    ORDER BY
        p2.staff_id,
        p2.payment_date DESC,
        p2.payment_id DESC
) AS last_store
    ON s.staff_id = last_store.staff_id

WHERE p.payment_date >= DATE '2017-01-01'
  AND p.payment_date < DATE '2018-01-01'

GROUP BY
    s.staff_id,
    s.first_name,
    s.last_name,
    last_store.store_id

ORDER BY total_revenue DESC
LIMIT 3;


-- PART 2: TASK 2 - Five most-rented movies and their expected audience age groups

-- CTE Approach
/*
The management team wants to identify the most popular movies
and their target audience age groups to optimize marketing efforts.

Show which 5 movies were rented more than others (number of rentals),
and what's the expected age of the audience for these movies?

To determine expected age please use the Motion Picture Association
film rating system.
*/

WITH movie_rentals AS (
    -- Calculate the total number of rentals for each movie.
    SELECT
        f.film_id,
        f.title,
        f.rating,
        COUNT(r.rental_id) AS number_of_rentals
    FROM your_schema.film AS f
    INNER JOIN your_schema.inventory AS i
        ON f.film_id = i.film_id
    INNER JOIN your_schema.rental AS r
        ON i.inventory_id = r.inventory_id
    GROUP BY
        f.film_id,
        f.title,
        f.rating
),
top_movies AS (
    -- Select the five most-rented movies.
    SELECT
        film_id,
        title,
        rating,
        number_of_rentals
    FROM movie_rentals
    ORDER BY
        number_of_rentals DESC,
        title ASC
    LIMIT 5
)
SELECT
    title,
    rating,
    number_of_rentals,
    CASE
        WHEN rating = 'G'
            THEN 'All ages'
        WHEN rating = 'PG'
            THEN 'Parental guidance suggested'
        WHEN rating = 'PG-13'
            THEN '13+ (parental caution)'
        WHEN rating = 'R'
            THEN 'Under 17 requires accompanying adult'
        WHEN rating = 'NC-17'
            THEN '18+ (no one 17 and under admitted)'
        ELSE 'Rating not specified'
    END AS expected_audience_age
FROM top_movies
ORDER BY
    number_of_rentals DESC,
    title ASC;

-- Subquery approach

SELECT
    f.title,
    f.rating,

    (
        SELECT COUNT(r.rental_id)
        FROM your_schema.inventory AS i
        INNER JOIN your_schema.rental AS r
            ON i.inventory_id = r.inventory_id
        WHERE i.film_id = f.film_id
    ) AS number_of_rentals,

    CASE
        WHEN f.rating = 'G'
            THEN 'All ages'
        WHEN f.rating = 'PG'
            THEN 'Parental guidance suggested'
        WHEN f.rating = 'PG-13'
            THEN '13+ (parental caution)'
        WHEN f.rating = 'R'
            THEN 'Under 17 requires accompanying adult'
        WHEN f.rating = 'NC-17'
            THEN '18+ (no one 17 and under admitted)'
        ELSE 'Rating not specified'
    END AS expected_audience_age

FROM your_schema.film AS f

WHERE EXISTS (
    SELECT 1
    FROM your_schema.inventory AS i
    INNER JOIN your_schema.rental AS r
        ON i.inventory_id = r.inventory_id
    WHERE i.film_id = f.film_id
)

ORDER BY
    number_of_rentals DESC,
    f.title ASC

LIMIT 5;


-- JOIN method

SELECT
    f.title,
    f.rating,
    COUNT(r.rental_id) AS number_of_rentals,

    CASE
        WHEN f.rating = 'G'
            THEN 'All ages'
        WHEN f.rating = 'PG'
            THEN 'Parental guidance suggested'
        WHEN f.rating = 'PG-13'
            THEN '13+ (parental caution)'
        WHEN f.rating = 'R'
            THEN 'Under 17 requires accompanying adult'
        WHEN f.rating = 'NC-17'
            THEN '18+ (no one 17 and under admitted)'
        ELSE 'Rating not specified'
    END AS expected_audience_age

FROM your_schema.film AS f

INNER JOIN your_schema.inventory AS i
    ON f.film_id = i.film_id

INNER JOIN your_schema.rental AS r
    ON i.inventory_id = r.inventory_id

GROUP BY
    f.film_id,
    f.title,
    f.rating

ORDER BY
    number_of_rentals DESC,
    f.title ASC

LIMIT 5;


-- Part 3. Which actors/actresses didn't act for a longer period of time than the others? 

-- CTE Method

/*
V1: Calculate the number of years between each actor's
latest movie release year and the current calendar year.
Rank actors by the length of their inactivity period.
*/

WITH actor_last_movie AS (
    SELECT
        a.actor_id,
        a.first_name,
        a.last_name,
        MAX(f.release_year) AS latest_release_year
    FROM your_schema.actor AS a
    INNER JOIN your_schema.film_actor AS fa
        ON a.actor_id = fa.actor_id
    INNER JOIN your_schema.film AS f
        ON fa.film_id = f.film_id
    WHERE f.release_year IS NOT NULL
    GROUP BY
        a.actor_id,
        a.first_name,
        a.last_name
)

SELECT
    actor_id,
    first_name,
    last_name,
    latest_release_year,
    EXTRACT(YEAR FROM CURRENT_DATE)::INT - latest_release_year
        AS inactivity_years
FROM actor_last_movie
ORDER BY
    inactivity_years DESC,
    last_name ASC,
    first_name ASC;


-- Subquery method

/*
V1: Calculate the number of years between each actor's
latest movie release year and the current calendar year.
Rank actors by the length of their inactivity period.
*/

SELECT
    a.actor_id,
    a.first_name,
    a.last_name,

    (
        SELECT MAX(f.release_year)
        FROM your_schema.film_actor AS fa
        INNER JOIN your_schema.film AS f
            ON fa.film_id = f.film_id
        WHERE fa.actor_id = a.actor_id
          AND f.release_year IS NOT NULL
    ) AS latest_release_year,

    EXTRACT(YEAR FROM CURRENT_DATE)::INT -
    (
        SELECT MAX(f.release_year)
        FROM your_schema.film_actor AS fa
        INNER JOIN your_schema.film AS f
            ON fa.film_id = f.film_id
        WHERE fa.actor_id = a.actor_id
          AND f.release_year IS NOT NULL
    ) AS inactivity_years

FROM your_schema.actor AS a
WHERE EXISTS (
    SELECT 1
    FROM your_schema.film_actor AS fa
    INNER JOIN your_schema.film AS f
        ON fa.film_id = f.film_id
    WHERE fa.actor_id = a.actor_id
      AND f.release_year IS NOT NULL
)
ORDER BY
    inactivity_years DESC,
    a.last_name ASC,
    a.first_name ASC;


-- JOIN method

/*
V1: Calculate the number of years between each actor's
latest movie release year and the current calendar year.
Rank actors by the length of their inactivity period.
*/

SELECT
    a.actor_id,
    a.first_name,
    a.last_name,
    MAX(f.release_year) AS latest_release_year,

    EXTRACT(YEAR FROM CURRENT_DATE)::INT -
        MAX(f.release_year) AS inactivity_years

FROM your_schema.actor AS a
INNER JOIN your_schema.film_actor AS fa
    ON a.actor_id = fa.actor_id
INNER JOIN your_schema.film AS f
    ON fa.film_id = f.film_id

WHERE f.release_year IS NOT NULL

GROUP BY
    a.actor_id,
    a.first_name,
    a.last_name

ORDER BY
    inactivity_years DESC,
    a.last_name ASC,
    a.first_name ASC;

-- I would choose CTE. It calculates the latest release year once, 
-- makes the logic easy to understand, and keeps the final calculation  given separate.
