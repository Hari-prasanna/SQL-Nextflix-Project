# Netflix Movies and TV Shows Data Analysis using SQL

![](https://github.com/Hari-prasanna/SQL-Nextflix-Project/blob/main/logo.png)

## Overview
This project involves a comprehensive analysis of Netflix's movies and TV shows data using SQL. The goal is to extract valuable insights and answer various business questions based on the dataset. The following README provides a detailed account of the project's objectives, business problems, solutions, findings, and conclusions.

## Objectives

- Analyze the distribution of content types (movies vs TV shows).
- Identify the most common ratings for movies and TV shows.
- List and analyze content based on release years, countries, and durations.
- Explore and categorize content based on specific criteria and keywords.

## Dataset

The data for this project is sourced from the Kaggle dataset:

- **Dataset Link:** [Movies Dataset](https://www.kaggle.com/datasets/shivamb/netflix-shows?resource=download)

## Schema

```sql
DROP TABLE IF EXISTS netflix;
CREATE TABLE netflix
(
    show_id      VARCHAR(5),
    type         VARCHAR(10),
    title        VARCHAR(250),
    director     VARCHAR(550),
    casts        VARCHAR(1050),
    country      VARCHAR(550),
    date_added   VARCHAR(55),
    release_year INT,
    rating       VARCHAR(15),
    duration     VARCHAR(15),
    listed_in    VARCHAR(250),
    description  VARCHAR(550)
);
```

## Business Problems and Solutions

### 1. Count the Number of Movies vs TV Shows

```sql
SELECT 
    type,
    COUNT(*)
FROM netflix
GROUP BY 1;
```

**Objective:** Determine the distribution of content types on Netflix.

### 2. Find the Most Common Rating for Movies and TV Shows

```sql
WITH RatingCounts AS (
    SELECT 
        type,
        rating,
        COUNT(*) AS rating_count
    FROM netflix
    GROUP BY type, rating
),
RankedRatings AS (
    SELECT 
        type,
        rating,
        rating_count,
        RANK() OVER (PARTITION BY type ORDER BY rating_count DESC) AS rank
    FROM RatingCounts
)
SELECT 
    type,
    rating AS most_frequent_rating
FROM RankedRatings
WHERE rank = 1;
```

**Objective:** User Interest and Trends Analysis

### 3. What are the top 10 most popular genres on Netflix based on the count of titles added in each genre?

```sql
SELECT 
    UNNEST(STRING_TO_ARRAY(listed_in,',')) AS genre,
    COUNT(*) AS content,
    ROUND(COUNt(*)::NUMERIC / (SELECT COUNT(*) FROM netflix)::NUMERIC * 100,2) AS Average_content_Per_genre
FROM netflix
GROUP BY 1
ORDER BY 2 DESC
LIMIT 10;

```

**Objective:** Content Release Timing and Trends

### 4. During which month(s) of the year does Netflix release the most content, and how has this trend changed over the years?

```sql
WITH monthly_count AS 
    (SELECT  
    EXTRACT(YEAR FROM TO_DATE(date_added,'Month DD, Year')) AS release_year,
    EXTRACT(MONTH FROM TO_DATE(date_added,'Month DD, Year')) AS release_Months,
    COUNT(*) AS content
FROM netflix
GROUP BY 1,2
--HAVING COUNT(*) > 100
ORDER BY 2,3 DESC) 


 SELECT * 
 FROM       
    (SELECT release_year, release_Months, content, 
            ROW_NUMBER() OVER(PARTITION BY release_year ORDER BY content DESC) AS most_content
    FROM monthly_count)
WHERE most_content = 1 AND release_year IS NOT NULL
ORDER BY content DESC;
```

**Objective:** Top Directors by Genre

### 5. Who are the top 5 most prolific directors in each genre?

```sql
WITH gen_dic AS (SELECT 
    UNNEST(STRING_TO_ARRAY(listed_in,',')) AS genre,
    UNNEST(STRING_TO_ARRAY(director,',')) AS director,
    COUNT(show_id) AS content
FROM netflix
GROUP BY 1,2)

 SELECT *       
FROM        
    (SELECT *, 
        ROW_NUMBER() OVER(PARTITION BY genre ORDER BY content DESC) AS top
    FROM gen_dic
    WHERE director IS NOT NULL AND genre IS NOT NULL)
WHERE top <= 5 
```

**Objective:** Find the movie with the longest duration.

### 6. Find Content Added in the Last 5 Years

```sql
SELECT *
FROM netflix
WHERE TO_DATE(date_added, 'Month DD, YYYY') >= CURRENT_DATE - INTERVAL '5 years';
```

**Objective:** Audience Suitability Trends

### 7. How has the distribution of content ratings (e.g., PG, R, TV-MA) changed over the years?

```sql
WITH trends AS (SELECT
     rating,
     EXTRACT(YEAR FROM TO_DATE(date_added,'Month DD, Year')) AS release_year,
     COUNT(*)
FROM netflix
WHERE rating IN ('PG', 'R', 'TV-MA') AND date_added IS NOT NULL
GROUP BY 1, 2),

overall AS 
(SELECT EXTRACT(YEAR FROM TO_DATE(date_added, 'Month DD,Year')) AS release_year,
    COUNT(*) AS total_content
FROM netflix
WHERE date_added IS NOT NULL
GROUP BY 1)

SELECT 
    t.release_year, 
    t.rating,
    t.count, 
    o.total_content, 
    ROUND(t.count::NUMERIC/o.total_content::NUMERIC * 100,2) AS percentage
FROM trends AS t
JOIN overall AS o ON t.release_year = o.release_year
GROUP BY 1,2,3,4
ORDER BY 2,1;
```

**Objective:** List all content directed by 'Rajiv Chilaka'.

### 8. List All TV Shows with More Than 5 Seasons

```sql
SELECT *
FROM netflix
WHERE type = 'TV Show'
  AND SPLIT_PART(duration, ' ', 1)::INT > 5;
```

**Objective:** International Content Growth

### 9. Which countries have seen the highest growth in Netflix content over the years?

```sql
WITH content AS (
    SELECT 
        EXTRACT(YEAR FROM TO_DATE(date_added, 'Month DD, YYYY')) AS release_year,
        TRIM(UNNEST(STRING_TO_ARRAY(country, ','))) AS countries,
        COUNT(*) AS total_content
    FROM netflix
    WHERE date_added IS NOT NULL
    GROUP BY 1, 2
)

SELECT 
    release_year,
    countries,
    total_content,
    LAG(total_content) OVER (PARTITION BY countries ORDER BY release_year) AS previous_year_content,
    ROUND(
        (total_content::NUMERIC - LAG(total_content) OVER (PARTITION BY countries ORDER BY release_year)) 
        / NULLIF(LAG(total_content) OVER (PARTITION BY countries ORDER BY release_year), 0) * 100, 
        2
    ) AS growth_percentage
FROM 
    content
WHERE 
    release_year > 2018
    AND countries IN ('France', 'Germany', 'India', 'Japan', 'Russia', 'South Korea')
ORDER BY 
    countries, release_year;
```

**Objective:** Count the number of content items in each genre.

### 10.Find each year and the average numbers of content release in India on netflix. 
return top 5 year with highest avg content release!

```sql
SELECT 
    country,
    release_year,
    COUNT(show_id) AS total_release,
    ROUND(
        COUNT(show_id)::numeric /
        (SELECT COUNT(show_id) FROM netflix WHERE country = 'India')::numeric * 100, 2
    ) AS avg_release
FROM netflix
WHERE country = 'India'
GROUP BY country, release_year
ORDER BY avg_release DESC
LIMIT 5;
```

**Objective:** Calculate and rank years by the average number of content releases by India.

### 11. List All Movies that are Documentaries

```sql
SELECT * 
FROM netflix
WHERE listed_in LIKE '%Documentaries';
```

**Objective:** Retrieve all movies classified as documentaries.

### 12. Find All Content Without a Director

```sql
SELECT * 
FROM netflix
WHERE director IS NULL;
```

**Objective:** List content that does not have a director.

### 13. Find How Many Movies Actor 'Salman Khan' Appeared in the Last 10 Years

```sql
SELECT * 
FROM netflix
WHERE casts LIKE '%Salman Khan%'
  AND release_year > EXTRACT(YEAR FROM CURRENT_DATE) - 10;
```

**Objective:** Count the number of movies featuring 'Salman Khan' in the last 10 years.

### 14. Find the Top 10 Actors Who Have Appeared in the Highest Number of Movies Produced in India

```sql
SELECT 
    UNNEST(STRING_TO_ARRAY(casts, ',')) AS actor,
    COUNT(*)
FROM netflix
WHERE country = 'India'
GROUP BY actor
ORDER BY COUNT(*) DESC
LIMIT 10;
```

**Objective:** Identify the top 10 actors with the most appearances in Indian-produced movies.

### 15. Categorize Content Based on the Presence of 'Kill' and 'Violence' Keywords

```sql
SELECT 
    category,
    COUNT(*) AS content_count
FROM (
    SELECT 
        CASE 
            WHEN description ILIKE '%kill%' OR description ILIKE '%violence%' THEN 'Bad'
            ELSE 'Good'
        END AS category
    FROM netflix
) AS categorized_content
GROUP BY category;
```

**Objective:** Categorize content as 'Bad' if it contains 'kill' or 'violence' and 'Good' otherwise. Count the number of items in each category.

## Findings and Conclusion

- **Content Distribution:** The dataset contains a diverse range of movies and TV shows with varying ratings and genres.
- **Common Ratings:** Insights into the most common ratings provide an understanding of the content's target audience.
- **Geographical Insights:** The top countries and the average content releases by India highlight regional content distribution.
- **Content Categorization:** Categorizing content based on specific keywords helps in understanding the nature of content available on Netflix.

This analysis provides a comprehensive view of Netflix's content and can help inform content strategy and decision-making.


