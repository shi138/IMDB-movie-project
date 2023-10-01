
-- Segment 1: Database - Tables, Columns, Relationships
-- What are the different tables in the database and how are they connected to each other in the database?
-- The total number of the tables in the database are 6, and each of them are connected with each other by sharing the
--  same column name of the name_id and movie_id.

-- Find the total number of rows in each table of the schema.
   use imdb_project_ns;
   
   select count(*) from director_mapping;
   select count(*) from genre;
   select count(*) from movies;
   select count(*) from names;
   select count(*) from ratings;
   select count(*) from role_mapping;
   
-- Identify which columns in the movie table have null values.

select * from movies;

SET SQL_SAFE_UPDATES=0;

update movies set country=null where country='';
update movies set worlwide_gross_income=null where worlwide_gross_income='';
update movies set languages=null where languages='';
update movies set production_company=null where production_company=''; 

select 
	sum(case when id is null then 1 else 0 end) as id_null,
    sum(case when title is null then 1 else 0 end) as title_null,
    sum(case when year is null then 1 else 0 end) as year_null,
    sum(case when date_published is null then 1 else 0 end) as date_null,
    sum(case when duration is null then 1 else 0 end) as duration_null,
    sum(case when country is null then 1 else 0 end) as country_null,
    sum(case when worlwide_gross_income is null then 1 else 0 end) as income_null,
    sum(case when languages is null then 1 else 0 end) as languages_null,
    sum(case when production_company is null then 1 else 0 end) as production_null from movies;
    
 ----------------------------------------------------------------------------------------------------------------------------------------
 
 
-- Segment 2: Movie Release Trends
select * from movies;

-- Determine the total number of movies released each year and analyse the month-wise trend.
select year,  substring(date_published,3,3) as month , count(id) as total_numberofmovie
from movies 
group by year,month;

-- Calculate the number of movies produced in the USA or India in the year 2019.

select count(*) as total_numberofmovies from movies
where country in ("India","USA")
and year = 2019;


-- Segment 3: Production Statistics and Genre Analysis
-- Retrieve the unique list of genres present in the dataset.
   select * from genre;
   select distinct(genre) from genre;
   
-- Identify the genre with the highest number of movies produced overall.

select a.genre,count(b.title) as count_movie_title
from genre a
inner join movies b
on a.movie_id=b.id
group by 1
order by 2 desc
limit 1;


-- 	Determine the count of movies that belong to only one genre.
with a as 
(select m.id ,count(g.genre) from movies m left join 
genre g on m.id=g.movie_id group by 1 having count(g.genre)=1 )
select count(*) from a;


-- 	Calculate the average duration of movies in each genre.
select a.genre,avg(b.duration) as average_movie_duration
from genre a
join movies b
on a.movie_id=b.id
group by 1;

-- Find the rank of the 'thriller' genre among all genres in terms of the number of movies produced.

with ss as 
( select  g.genre , count(m.id) as movie_produced , row_number() over(order by count(id) desc) as rank_n
from movies m left join genre g on m.id=g.movie_id group by 1) 
select genre , rank_n from ss where genre="Thriller";
-------------------------------------------------------------------------------------------------------------------------------------------------------------

-- Segment 4: Ratings Analysis and Crew Members
-- 	Retrieve the minimum and maximum values in each column of the ratings table (except movie_id).
select * from ratings;

select max(avg_rating) as maximum_values, min(avg_rating) as minimum_values, 
max(total_votes) as maximum_values, min(total_votes) as minimum_values,
max(median_rating) as maximum_values, min(median_rating) as minimum_values from ratings;



-- 	Identify the top 10 movies based on average rating.
 
 select * from 
(select r.movie_id ,m.title,r.avg_rating , row_number() over (order by r.avg_rating desc ) as ran_k 
from movies m left join ratings r on r.movie_id=m.id) a where ran_k<=10;
 
 
-- 	Summarise the ratings table based on movie counts by median ratings.

select sum(a.avg_rating) as sum_of_average_rating ,sum(a.total_votes) as total_votes ,a.median_rating,count(b.id) as movie_counts
from ratings a
left join movies b
on a.movie_id=b.id
group by 3
order by 3;


-- 	Identify the production house that has produced the most number of hit movies (average rating > 8).

select production_company from
(select m.production_company , count(m.id) , row_number() over (order by count(m.id) desc) as rnk 
from movies m left join ratings r 
on m.id=r.movie_id where r.avg_rating>8 and m.production_company is not null group by 1) as b 
where rnk=1;


-- Determine the number of movies released in each genre during March 2017 in the USA with more than 1,000 votes.
select g.genre , count(m.id) as count_movie from movies m 
left join genre g on m.id=g.movie_id
left join ratings r on g.movie_id=r.movie_id
where r.total_votes>1000 and m.country="USA"
and substr(m.date_published,4,2)="03" and year="2017"
group by 1
order by 2 desc; 


-- Retrieve movies of each genre starting with the word 'The' and having an average rating > 8.
select m.id, m.title, g.genre from movies m 
left join genre g on m.id=g.movie_id
left join ratings r on r.movie_id=g.movie_id
where  m.title like "the%" and r.avg_rating>8
order by genre;
----------------------------------------------------------------------------------------------------------------------------------------------------------

-- Segment 5: Crew Analysis

-- 	Identify the columns in the names table that have null values.
select * from names;

select sum(case when id = '' then 1 else 0 end) as id_nulls,
sum(case when name = '' then 1 else 0 end) as name_nulls,
sum(case when height ='' then 1 else 0 end) as height_nulls,
sum(case when date_of_birth ='' then 1 else 0 end) as date_of_birth_nulls,
sum(case when known_for_movies = '' then 1 else 0 end) as known_for_movies_nulls
from names;



-- 	Determine the top three directors in the top three genres with movies having an average rating > 8.
select * from genre;
select * from movies;
select * from director_mapping;

with ff as
(select g.genre,d.name_id as director_id, n.name as director_name, count(m.id) as movie_count,
row_number() over (partition by g.genre order by count(m.id) desc) as ranks from movies m
left join genre g on m.id=g.movie_id
left join director_mapping d on d.movie_id=m.id
left join names n on n.id=d.name_id
where d.name_id is not null
group by genre,name_id,n.name),
 gg as
(select * from 
(select g.genre , count(m.id) as movie_count , row_number() over (order by count(m.id)desc) as rnk
from movies m left join genre g on g.movie_id=m.id
left join ratings r on g.movie_id=r.movie_id
where avg_rating>8
group by 1) l where rnk<=3)
select * from ff where genre in (select genre from gg) and ranks<=3;


-- 	Find the top two actors whose movies have a median rating >= 8.
select * from
(select n.id , n.name , count(m.id) as movie_count , row_number() over(order by count(m.id) desc) as rnk
from names n left join role_mapping r on n.id=r.name_id
left join movies m on m.id=r.movie_id
left join ratings rs on rs.movie_id=m.id
where rs.median_rating>=8 and r.category="actor"
group by 1,2) a where rnk<=2;


-- 	Identify the top three production houses based on the number of votes received by their movies.
select * from
(select m.production_company , sum(r.total_votes) as total_votes ,
row_number() over(order by sum(r.total_votes) desc) as ranks
from movies m left join ratings r on m.id=r.movie_id
group by 1) a where ranks<=3;

-- 	Rank actors based on their average ratings in Indian movies released in India.
select n.id , n.name ,avg(rs.avg_rating), row_number() over( order by avg(rs.avg_rating) desc) as rnk
from names n left join role_mapping r on n.id=r.name_id
left join movies m on m.id=r.movie_id
left join ratings rs on rs.movie_id=m.id
where m.country="India" and r.category="actor"
group by 1,2;

-- 	Identify the top five actresses in Hindi movies released in India based on their average ratings.
select * from
(select n.id , n.name ,avg(rs.avg_rating), row_number() over( order by avg(rs.avg_rating) desc) as rnk
from names n left join role_mapping r on n.id=r.name_id
left join movies m on m.id=r.movie_id
left join ratings rs on rs.movie_id=m.id
where m.country="India" and r.category="actress" and m.languages="hindi"
group by 1,2) d 
where rnk<=5;
-------------------------------------------------------------------------------------------------------------------------------------------------------------

-- Segment 6: Broader Understanding of Data

-- 1. Classify thriller movies based on average ratings into different categories.

select id, title, genre, avg_rating,
case
when avg_rating>=8 then 'superhit'
when avg_rating>=6 then 'hit'
when avg_rating<=3 then 'flop'
else 'average' end as category
from movies m
left join ratings r on m.id=r.movie_id
left join genre g on m.id=g.movie_id
where genre='Thriller';

-- 2. analyse the genre-wise running total and moving average of the average movie duration.

select id,title, genre, duration, sum(duration) over (partition by genre order by id) as running_total, 
avg(duration) over (partition by genre order by id) as moving_average
from movies join genre on id=movie_id;

-- 3. Identify the five highest-grossing movies of each year that belong to the top three genres.

with cte as (select * from (select genre,count(id) as movie_count, 
row_number() over (order by count(id) desc) as ranks from movies m
left join genre g on m.id=g.movie_id
group by genre) a where ranks<=3)
(select * from (select id, title, genre, year, concat('$',worlwide_gross_income) as worldwide_income,
row_number() over (partition by year order by worlwide_gross_income desc) as income_rank
from  movies left join genre on movie_id=id
where genre in(select genre from cte)) a where income_rank<= 5);

-- 4. Determine the top two production houses that have produced the highest number of hits among multilingual movies.

select * from (select production_company, count(id) as movie_count,
row_number() over (order by count(id) desc) as ranks
from movies left join ratings on id=movie_id
where languages like '%,%' and avg_rating>=6 and production_company is not null
group by production_company) a where ranks<=2;

-- 5.Identify the top three actresses based on the number of Super Hit movies (average rating > 8) in the drama genre.

select * from (select name_id,name as actress_name, count(m.id) as movie_count,
row_number() over (order by count(m.id) desc) as ranks
from movies m
join role_mapping r on m.id=r.movie_id
join genre g on m.id=g.movie_id
join ratings a on m.id=a.movie_id
join names n on n.id=r.name_id
where category='actress' and avg_rating>8 and genre='drama'
group by name_id,name) a where ranks<=3;


-- 6. -	Retrieve details for the top nine directors based on the number of movies, including average inter-movie duration, ratings, and more.

select * from (select n.id as director_id, n.name as director_name, count(m.id) as movie_count,
avg(duration) as average_duration, avg(avg_rating) as average_rating,
row_number() over (order by count(m.id) desc) as ranks
from movies m join ratings r on m.id=r.movie_id
join director_mapping d on d.movie_id=r.movie_id
join names n on n.id=d.name_id
group by n.id,n.name) a where ranks<=9;

-----------------------------------------------------------------------------------------------------------------------------------------------------------
-- Segment 7: Recommendations

-- Based on the analysis, provide recommendations for the types of content Bolly movies should focus on producing.

-- Based on the analysis, 
-- Top 5 genres are Drama, Others, Romance, Family and Crime based on average ratings.
-- Where as based on worldwide income, it is Adventure, Action, Drama, Comedy and Sci_Fi.
-- So, it is recommended that Bolly Movies should produce maximum movies in these genres.

-- Further, Top 10 directors are Srinivas Gundareddy, Balavalli Darshith Bhat, Abhinav Thakur, Pradeep Kalipurayath, Prince Singh, Arjun Prabhakaran, Antoneta Kastrati, Manoj K. Jha, Arsel Arumugam and Sumnash Sri Kaljai
-- Top 10 actors are Priyanka Augustin, Shilpa Mahendar, Gopi Krishna, Naveen D. Padil, Aryan Gowda. Ravi Bhat, Aloknath Pathak, Siju Wilson, Prasanth and Preetyka Chauhan
-- Top 10 actress are Sangeetha Bhat, Pranati Rai Prakash, Fatmire Sahiti, Neeraja, Leera Kaljai, Dorothée Berryman, Susan Brown, Amanda Lawrence, Bhagyashree Milind and Miao Chen

-- Further, their biggest competition are the top 10 production Houses.
-- Based on average ratings, Top 10 Production houses are Archway Pictures, A square productions, Bestwin Production, SLN Cinemas, Epiphany Entertainments, Eastpool Films, Piecewing Productions, Manikya Productions, Crossing Bridges Films and Lovely World Entertainment
-- Whereas based on gross income, they are Walt Disney Pictures, Marvel Studios, Universal Pictures, Columbia Pictures, Warner Bros., Twentieth Century Fox, Paramount Pictures, Fairview Entertainment, Beijing Dengfeng International Culture Communications Company and Bona Film Group

-- Further, the top countries based on Gross Income are USA, China, South Korea, Japan, India, France, Russia, UK, Germany and Spain.
-- Therefore, Bolly Movies should produce Movies in these countries to ensure maximum income.


-- top 5 genre based on average rating

select * from (select genre, avg(avg_rating) as average_rating,
row_number() over (order by avg(avg_rating) desc) as ranks
from movies m left join genre g on g.movie_id=m.id
left join ratings r on r.movie_id=m.id
group by genre) a where ranks<=5;

-- top 5 genre based on world_wide gross income

select * from (select genre, concat('$',sum(worlwide_gross_income)) as worldwide_gross_income,
row_number() over (order by sum(worlwide_gross_income) desc) as ranks
from movies m left join genre g on g.movie_id=m.id
left join ratings r on r.movie_id=m.id
group by genre) a where ranks<=5;

-- top 10 directors based on average ratings

select * from (select d.name_id as director_id, n.name as director_name, avg(avg_rating) as average_rating,
row_number() over (order by avg(avg_rating) desc) as ranks from movies m
left join ratings r on r.movie_id=m.id
left join director_mapping d on d.movie_id=m.id
left join names n on n.id=d.name_id
where d.name_id is not null
group by name_id,n.name) a where ranks<=10;

-- top 10 actors based on average ratings

select * from (select n.id,n.name as actor_name, avg(avg_rating) as average_rating,
row_number() over (order by avg(avg_rating) desc) as ranks
from movies m
left join ratings r on r.movie_id=m.id
left join role_mapping d on d.movie_id=m.id
left join names n on n.id=d.name_id
where d.name_id is not null
and category='actor'
group by name_id,n.name) a where ranks<=10;

-- top 10 actress based on average ratings

select * from (select n.id,n.name as actor_name, avg(avg_rating) as average_rating,
row_number() over (order by avg(avg_rating) desc) as ranks
from movies m
left join ratings r on r.movie_id=m.id
left join role_mapping d on d.movie_id=m.id
left join names n on n.id=d.name_id
where d.name_id is not null
and category='actress'
group by name_id,n.name) a where ranks<=10;

-- top 10 production houses based on average ratings

select * from (select production_company, avg(avg_rating) as average_rating,
row_number() over (order by avg(avg_rating) desc) as ranks
from movies m
left join ratings r on r.movie_id=m.id
group by production_company) a where ranks<=10;

-- top 10 production houses based on worldwide gross income

select * from (select production_company, concat('$',sum(worlwide_gross_income)) as worldwide_gross_income,
row_number() over (order by sum(worlwide_gross_income) desc) as ranks
from movies group by production_company) a where ranks<=10;

-- average duration of top 100 movies based on worldwide gross income

select avg(duration) from (select * from (select title, duration, worlwide_gross_income,
row_number() over (order by worlwide_gross_income desc) as ranks from movies) a where ranks<=100) a;


-- average duration of top 100 movies in each top genre

with cte as (select * from (select title, duration, genre, avg(avg_rating) as average_rating,
row_number() over (partition by genre order by avg(avg_rating) desc) as ranks from movies
left join ratings r on r.movie_id=id
left join genre g on g.movie_id=id
group by genre,title,duration) a where ranks<=100),
cte2 as (select * from (select genre, avg(avg_rating) as average_rating,
row_number() over (order by avg(avg_rating) desc) as ranks
from movies m left join genre g on g.movie_id=m.id
left join ratings r on r.movie_id=m.id
group by genre) a where ranks<=5)
(select genre, avg(duration) from cte where genre in (select genre from cte2)
group by genre);

-- Top 10 countries based on gross_income

select * from (select country, concat('$',sum(worlwide_gross_income)) as worldwide_gross_income,
row_number() over (order by sum(worlwide_gross_income) desc) as ranks
from movies where country not like '%,%'
group by country) a where ranks<=10;


-- Top 10 actress in each top genre based on average ratings

with cte as (select n.id,n.name as actor_name, genre, avg(avg_rating) as average_rating,
row_number() over (partition by genre order by avg(avg_rating) desc) as ranks
from movies m
left join genre g on m.id=g.movie_id
left join ratings r on r.movie_id=m.id
left join role_mapping d on d.movie_id=m.id
left join names n on n.id=d.name_id
where d.name_id is not null
and category='actress'
group by genre,name_id,n.name),
cte2 as (select * from (select genre, avg(avg_rating) as average_rating,
row_number() over (order by avg(avg_rating) desc) as ranks
from movies m left join genre g on g.movie_id=m.id
left join ratings r on r.movie_id=m.id
group by genre) a where ranks<=5)
(select * from cte where genre in (select genre from cte2) and ranks<=10);

-- Top 10 production companies for each top genre based on average ratings

with cte as (select production_company, genre, avg(avg_rating) as average_rating,
row_number() over (partition by genre order by avg(avg_rating) desc) as ranks
from movies m
left join genre g on m.id=g.movie_id
left join ratings r on r.movie_id=m.id
group by genre,production_company),
cte2 as (select * from (select genre, avg(avg_rating) as average_rating,
row_number() over (order by avg(avg_rating) desc) as ranks
from movies m left join genre g on g.movie_id=m.id
left join ratings r on r.movie_id=m.id
group by genre) a where ranks<=5)
(select * from cte where genre in (select genre from cte2) and ranks<=10);

------------------------------------------------------------------------------------------------------------------------------------------------------------------





  

