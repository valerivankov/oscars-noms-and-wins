-- INTRODUCTION

/* The following project analyses Oscar nominees and winners between 1980 and 2020 based on 
various categories, including IMDb score, genre, rating, and company. The original datasets
are retrieved from Kaggle (https://www.kaggle.com/datasets/danielgrijalvas/movies/ 
and https://www.kaggle.com/datasets/unanimad/the-oscar-award/data). */

-- SQL DATA EXTRACTION

-- selecting the movie ratings table
SELECT * FROM movies

-- selecting the Oscar nominees table
SELECT * FROM the_oscar_award

-- modifying data type of "winner" field
ALTER TABLE the_oscar_award
ALTER COLUMN winner INT

-- creating a field "nominee" in the movie ratings table
ALTER TABLE movies
ADD nominee INT

-- setting all values in the "nominee" field to 0
UPDATE movies
SET nominee = 0

-- setting the "nominee" values of Oscar nominees to 1
UPDATE movies
SET nominee = 1
WHERE name IN (SELECT film FROM the_oscar_award)

-- renaming "name" field to "title" to avoid duplicate field names
EXEC sp_rename 'movies.name', 'title', 'COLUMN'

-- inner join of the two tables based on film title
SELECT m.*, o.category, o.name, o.winner
FROM movies AS m
INNER JOIN the_oscar_award AS o ON m.title = o.film

-- EXPLORATORY DATA ANALYSIS

-- films with highest number of nominations
SELECT film, COUNT(*) AS number_of_nominations 
FROM the_oscar_award
WHERE film IS NOT NULL
GROUP BY film, year_ceremony
ORDER BY number_of_nominations DESC

/* 'All About Eve', 'Titanic', and 'La La Land' have the most nominations (14). */

-- films with highest number of wins
SELECT film, SUM(winner) AS number_of_wins 
FROM the_oscar_award
WHERE film IS NOT NULL
GROUP BY film, year_ceremony
ORDER BY number_of_wins DESC

/* 'Ben-Hur', 'Titanic', and 'The Lord of the Rings: The Return of the King' share the most wins (11). */

-- genre distribution of nominees
SELECT genre, SUM(nominee) as total_nominations_count
FROM movies
INNER JOIN the_oscar_award ON title = film AND year = year_film
GROUP BY genre
ORDER BY total_nominations_count DESC

/* Drama, followed by biography, comedy, and action are the most nominated genres. */

-- genre distribution of winners
SELECT genre, SUM(winner) as total_wins_count
FROM movies
INNER JOIN the_oscar_award AS o ON title = o.film
GROUP BY genre
ORDER BY total_wins_count DESC

/* Drama, followed by biography, action, and comedy are the most winning genres. 
The top 4 nominated are the same as the top 4 winning genres, though actions have more wins than comedies. */

-- percentage win by genre
WITH WinCounts AS (
  SELECT genre, SUM(nominee) AS total_nominations, SUM(winner) AS total_wins
  FROM movies
  INNER JOIN the_oscar_award ON title = film AND year = year_film
  GROUP BY genre
)
SELECT w.genre, w.total_nominations, w.total_wins, 
       CAST(w.total_wins AS FLOAT) / NULLIF(w.total_nominations, 0) AS ratio
FROM WinCounts AS w
ORDER BY ratio DESC

/* Family, biography, and fantasy have the highest winning ratios while drama, action, and comedy
are further down the rank list. This is because some of these genres (e.g., family and fantasy) 
have very few nominated movies, so every win impacts the ratio a lot. */

-- rating distribution of nominees
SELECT rating, SUM(nominee) as total_nominations_count
FROM movies
INNER JOIN the_oscar_award ON title = film AND year = year_film
WHERE rating IS NOT NULL
GROUP BY rating
ORDER BY total_nominations_count DESC

/* Movies that are rated R and PG-13 have the most nominations. */

-- rating distribution of winners
SELECT rating, SUM(winner) as total_wins_count
FROM movies
INNER JOIN the_oscar_award ON title = film AND year = year_film
WHERE rating IS NOT NULL
GROUP BY rating
ORDER BY total_wins_count DESC

/* Movies that are rated R and PG-13 have the most nominations. */

-- rating percentage win by genre
WITH Combined AS (
  SELECT rating, SUM(nominee) AS total_nominations, SUM(winner) AS total_wins
  FROM movies
  INNER JOIN the_oscar_award ON title = film AND year = year_film
  WHERE rating IS NOT NULL
  GROUP BY rating
)
SELECT c.rating, c.total_nominations, c.total_wins, 
       CAST(c.total_wins AS FLOAT) / NULLIF(c.total_nominations, 0) AS ratio
FROM Combined AS c
ORDER BY ratio DESC

SELECT film, year_film, category
FROM movies JOIN the_oscar_award on title = film and year = year_film
WHERE rating = 'NC-17'

/* PG-13 has the most wins, followed closely by G, PG, and R. 
Notably there is only one NC-17 nominated movie and no winners with this rating. 
The movie in question is 'Henry & June' (1990). */

-- min, mean, and max score of nominees by year as well as total
SELECT year, MIN(score) AS 'min', AVG(score) AS 'mean', MAX(score) AS 'max' 
FROM movies 
WHERE nominee = 1
GROUP BY year
ORDER BY mean DESC

SELECT 'total' AS year, MIN(score) AS 'min', AVG(score) AS 'mean', MAX(score) AS 'max' 
FROM movies 
WHERE nominee = 1

/* 2014 had the highest average IMDb scores while 1983 had the lowest average scores. 
Overall there are not huge variances in min, mean, or max scores across years. */

-- min, mean, and max score of winners by year as well as total
WITH Combined AS (
  SELECT year, MIN(score) AS min, AVG(score) AS mean, MAX(score) AS max
  FROM movies
  INNER JOIN the_oscar_award AS o ON title = o.film
  WHERE winner = 1
  GROUP BY year
)
SELECT year, MIN(min) AS min, AVG(mean) AS mean, MAX(max) AS max
FROM Combined
GROUP BY year
ORDER BY AVG(mean) DESC

WITH Combined AS (
  SELECT MIN(score) AS min, AVG(score) AS mean, MAX(score) AS max
  FROM movies
  INNER JOIN the_oscar_award AS o ON title = o.film
  WHERE winner = 1
)
SELECT 'total' AS year, MIN(min) AS 'min', AVG(mean) AS 'mean', MAX(max) AS 'max' 
FROM Combined

/* 2003 had the highest average IMDb scores while 1985 had the lowest average scores. 
Overall there are not huge variances in min, mean, or max scores across years. 
The winning movies have overall a slightly higher mean than the nominated movies (7.47 compared to 7.13). */

-- total nominations and wins by company
WITH Combined AS (
  SELECT company, SUM(nominee) AS total_nominations, SUM(winner) AS total_wins
  FROM movies
  INNER JOIN the_oscar_award AS o ON title = o.film
  GROUP BY company
)
SELECT c.company, c.total_nominations, c.total_wins
FROM Combined AS c
ORDER BY total_nominations DESC

/* Columbia Pictures, Universal Pictures, and Warner Bros. are tied for the most nominations (235), 
followed by Paramount Pictures and Twentieth Century Fox. On the other hand, Warner Bros., Universal Pictues, 
and Paramount have the most wins, followed by Twentieth Century Fox and Walt Disney Pictures. Unsurprisingly,
the major studios dominate the Oscars both in terms of nominations and wins. */

-- FURTHER INSIGHTS

-- find the highest and lowest scoring nominated movie by genre
SELECT genre, title, year, score, category
FROM (
SELECT
	genre,
	title,
	year,
	RANK() OVER(PARTITION BY genre ORDER BY score ASC) AS lowest_scored,
	score,
	category
FROM movies JOIN the_oscar_award ON title = film  AND year = year_film
) AS l
WHERE l.lowest_scored = 1

SELECT genre, title, year, score, category
FROM (
SELECT
	genre,
	title,
	year,
	RANK() OVER(PARTITION BY genre ORDER BY score DESC) AS highest_scored,
	score,
	category
FROM movies JOIN the_oscar_award ON title = film AND year = year_film
) AS h
WHERE h.highest_scored = 1

-- find the highest and lowest scoring winning movie by genre
SELECT genre, title, year, score, category
FROM (
SELECT
	genre,
	title,
	year,
	RANK() OVER(PARTITION BY genre ORDER BY score ASC) AS lowest_scored,
	score,
	category
FROM movies JOIN the_oscar_award ON title = film AND year = year_film
WHERE winner = 1
) AS l
WHERE l.lowest_scored = 1

SELECT genre, title, year, score, category
FROM (
SELECT
	genre,
	title,
	year,
	RANK() OVER(PARTITION BY genre ORDER BY score DESC) AS highest_scored,
	score,
	category
FROM movies JOIN the_oscar_award ON title = film AND year = year_film
WHERE winner = 1
) AS h
WHERE h.highest_scored = 1

-- check if movies with higher ratings are more likely to be win Oscars

WITH st AS (
  SELECT title, year,
    CASE 
      WHEN score > 7 THEN 'high'
      WHEN score < 6 THEN 'low'
      ELSE 'medium'
    END AS score_type
  FROM movies
  JOIN the_oscar_award ON title = film AND year = year_film
),
st_counts AS (
  SELECT score_type, COUNT(*) AS nom_count 
  FROM st
  JOIN the_oscar_award ON title = film AND year = year_film
  GROUP BY score_type
),
winner_counts AS (
  SELECT score_type, COUNT(*) AS win_count
  FROM st
  JOIN the_oscar_award ON title = film AND year = year_film
  WHERE winner = 1
  GROUP BY score_type
)
SELECT st_counts.score_type, 
		nom_count,
		win_count,
       CAST(win_count AS FLOAT) / nom_count AS ratio
FROM st_counts
JOIN winner_counts ON st_counts.score_type = winner_counts.score_type
ORDER BY ratio DESC

/* As expected, with this setup, along with scenarios in which we increase the high bound to 7.5 or 
lower the lower bound to 5.5, we obtain that high-scoring movies have the highest 
nominations, wins, and nomination-to-win ratio, followed by medium-scoring movies and low-scoring movies. */
