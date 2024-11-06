--1. Count the number of Movies vs TV Shows

SELECT type, COUNT(*) 
FROM netflix
GROUP BY 1


--2. Find the most common rating for movies and TV shows

SELECT type, rating, total_content
FROM	
	(SELECT type, rating,
	RANK() OVER (PARTITION BY type ORDER BY COUNT(*) DESC) AS rankings,
	COUNT(*) AS total_content
FROM netflix
GROUP BY 1,2) AS ranks
WHERE ranks.rankings = 1;


--3. List all movies released in a specific year (e.g., 2020)

SELECT *
FROM netflix
WHERE type ILIKE '%movie%'
	AND release_year = 2020




--4. Find the top 5 countries with the most content on Netflix
SELECT UNNEST(STRING_TO_ARRAY(country , ',')) AS country,
		COUNT(*) AS total_content,
		ROUND(COUNT(*)::numeric / (SELECT  COUNT(*) FROM netflix)::numeric * 100,2) AS percentage
FROM netflix
GROUP BY 1
ORDER BY 2 DESC
LIMIT 5;



--5. Identify the longest movie
SELECT * 
FROM netflix
WHERE type = 'Movie'
	AND duration = (SELECT MAX(duration) FROM netflix);



--6. Find content added in the last 5 years
SELECT *
FROM netflix
WHERE TO_DATE(date_added,'Months,DD,YYYY') <= (CURRENT_DATE - INTERVAL '5 Years')


--7. Find all the movies/TV shows by director 'Rajiv Chilaka'!

SELECT *
FROM netflix
WHERE director LIKE '%Rajiv Chilaka%'




--8. List all TV shows with more than 5 seasons   (SPLIT_PART)
SELECT *
FROM netflix
WHERE duration IN (SELECT duration FROM netflix WHERE duration > '5 Seasons' AND duration LIKE '%Seasons%')
AND type = 'TV Show';


SELECT * --SPLIT_PART(duration,' ',1) AS Season_num  
FROM netflix
WHERE type = 'TV Show' AND SPLIT_PART(duration,' ',1)::numeric > 5;



--9. Count the number of content items in each genre
SELECT *, UNNEST(STRING_TO_ARRAY(listed_in,','))  
FROM netflix

WITH genre AS 
	(SELECT *, UNNEST(STRING_TO_ARRAY(listed_in,',')) AS genre1  
FROM netflix)

SELECT DISTINCT(genre1), COUNT(show_id)
FROM genre
GROUP BY 1
ORDER BY 2 DESC; 



--10.Find each year and the average numbers of content release in India on netflix. return top 5 year with highest avg content release!

SELECT 
	EXTRACT(YEAR FROM TO_DATE(date_added,'Months,DD,YYYY')) AS Year,
	COUNT(*),
	ROUND(((COUNT(*)::NUMERIC/(SELECT COUNT(*) FROM netflix WHERE country LIKE '%India%')::NUMERIC)*100),2) AS average_content
FROM netflix 
WHERE country LIKE '%India%'
GROUP BY 1
ORDER BY 2 DESC
LIMIT 5;



--11. List all movies that are documentaries

WITH genre AS 
	(SELECT *, UNNEST(STRING_TO_ARRAY(listed_in,',')) AS genre1  
FROM netflix
WHERE type = 'Movie')

SELECT *
FROM genre
WHERE genre1 LIKE '%Documentaries%'; 



--12. Find all content without a director

SELECT *
FROM netflix
WHERE director IS NULL;

--13. Find how many movies actor 'Salman Khan' appeared in last 10 years!

SELECT *
FROM netflix
WHERE casts ILIKE '%Salman Khan%'
AND EXTRACT(YEAR FROM TO_DATE(date_added,'Months,DD,YYYY')) > (EXTRACT(YEAR FROM CURRENT_DATE)) - 10
ORDER BY EXTRACT(YEAR FROM TO_DATE(date_added,'Months,DD,YYYY')) 



--14. Find the top 10 actors who have appeared in the highest number of movies produced in India.

SELECT UNNEST(STRING_TO_ARRAY(casts,',')) AS actors,
		COUNT(show_id) AS number_of_movies,
		COUNT(*) AS all
FROM netflix
WHERE country ILIKE '%india%'
GROUP BY 1
ORDER BY 2 DESC
LIMIT 10;

--15.Categorize the content based on the presence of the keywords 'kill' and 'violence' in  the description field. Label content containing these keywords as 'Bad' and all other content as 'Good'. Count how many items fall into each category.


WITH category AS (SELECT *,
	(CASE
	WHEN description ILIKE '%Kill%' OR description ILIKE '%violence%' THEN 'Bad'
	ELSE 'good'
	END) AS case1 
FROM netflix)

SELECT case1, COUNT(*)
FROM category
GROUP BY 1

