-- ------------------------- PROJECT ON DIGITAL MUSIC STORE ANALYSIS------------------------- --

use music_database;
-- import all relevant tables
 -- ------------------------ SOLVE QUERY---------------------------------------------------
 
 -- Q1-> Who is the senior most employee based on job title?
 SELECT * FROM employee
 ORDER BY levels
 LIMIT 1;
 
 
 -- Q2-> Which countries have the most Invoices?
 SELECT billing_country, COUNT(invoice_id) AS C
 from invoice 
 GROUP BY billing_country
 ORDER BY C DESC;
 
 
-- Q3-> What are top 3 values of total invoice?
SELECT total
FROM invoice
ORDER BY total DESC
LIMIT 3;


/* Q4: Which city has the best customers? We would like to throw a promotional Music Festival in the city we made the most money. 
Write a query that returns one city that has the highest sum of invoice totals. 
Return both the city name & sum of all invoice totals  */
SELECT billing_city AS CITY_NAME, SUM(total) AS INVOICE_TOTAL_SUM
FROM invoice
GROUP BY billing_city
ORDER BY INVOICE_TOTAL_SUM DESC
LIMIT 1;


/* Q5: Who is the best customer? The customer who has spent the most money will be declared the best customer. 
Write a query that returns the person who has spent the most money.*/
SELECT C.customer_id, C.first_name, C.last_name, SUM(I.total) AS SPENT_MONEY
FROM customer C
INNER JOIN invoice I ON C.customer_id = I.customer_id
GROUP BY C.customer_id, C.first_name, C.last_name
ORDER BY SPENT_MONEY DESC
LIMIT 1;

-- ---------------------------------------------------------------------------------------------------------------

/* Question Set 2 - Moderate */

/* Q1: Write query to return the email, first name, last name, & Genre of all Rock Music listeners. 
Return your list ordered alphabetically by email starting with A. */
 
SELECT DISTINCT email AS EMAIL, first_name AS FIRST_NAME, last_name AS LAST_NAME, G.name as NAME
FROM customer C
JOIN invoice I on C.customer_id = I.customer_id
JOIN invoice_line IL ON I.invoice_id = IL.invoice_id
JOIN track T ON T.track_id= IL.track_id
JOIN genre G ON G.genre_id = T.genre_id
WHERE G.name LIKE "rock"
ORDER BY email;
/* ANOTHER METHOD */
SELECT DISTINCT email,first_name, last_name 
FROM customer
JOIN invoice ON customer.customer_id = invoice.customer_id
JOIN invoice_line ON invoice.invoice_id = invoice_line.invoice_id
WHERE track_id IN(
	SELECT track_id FROM track
	JOIN genre ON track.genre_id = genre.genre_id
	WHERE genre.name LIKE 'Rock'
)
ORDER BY email;

/* Q2: Let's invite the artists who have written the most rock music in our dataset. 
Write a query that returns the Artist name and total track count of the top 10 rock bands. */

/* FOR VIEWING TABLE-> */ SELECT * FROM ALBUM2;
SELECT A.name AS ARTIST_NAME, COUNT(track_id) AS TOTAL_TRACK 
FROM track T 
JOIN album2 AL ON AL.album_id = T.album_id
JOIN artist A ON A.artist_id = AL.artist_id
JOIN genre G ON T.genre_id = G.genre_id
WHERE G.name LIKE "ROCK"
GROUP BY A.name
ORDER BY TOTAL_TRACK DESC
LIMIT 10 ;


/* Q3: Return all the track names that have a song length longer than the average song length. 
Return the Name and Milliseconds for each track. Order by the song length with the longest songs listed first. */

/* TO VIEW EVER TABLE*/ SELECT * FROM TRACK;
SELECT  name , milliseconds
FROM track 
WHERE milliseconds > ( SELECT AVG(milliseconds)  FROM track)
ORDER BY milliseconds DESC;

-- -------------------------------------------------------------------------------------------------------------

/* Question Set 3 - Advance */

/* Q1: Find how much amount spent by each customer on artists? 
Write a query to return customer name, artist name and total spent */

/* Steps to Solve: First, find which artist has earned the most according to the InvoiceLines. Now use this artist to
 find which customer spent the most on this artist. For this query, you will need to use the Invoice, InvoiceLine, 
 Track, Customer, Album, and Artist tables. Note, this one is tricky because the Total spent in the Invoice table
 might not be on a single product, so you need to use the InvoiceLine table to find out how many of each product
 was purchased, and then multiply this by the price for each artist. */

/* view  any table */ SELECT * FROM artist;
/* PROCEED- CUST-> INVOICE-> INVOICE_LINE->TRACK->ALBUM->ARTIST 8*/


WITH best_selling_artist AS 
(
	SELECT artist.artist_id AS artist_id, artist.name AS artist_name, SUM(invoice_line.unit_price*invoice_line.quantity) AS total_sales
	FROM invoice_line
	JOIN track ON track.track_id = invoice_line.track_id
	JOIN album2 ON album2.album_id = track.album_id
	JOIN artist ON artist.artist_id = album2.artist_id
	GROUP BY 1,2
	ORDER BY 3 DESC
	LIMIT 1
)
SELECT c.customer_id, c.first_name, c.last_name, bsa.artist_name, SUM(il.unit_price*il.quantity) AS amount_spent
FROM invoice i
JOIN customer c ON c.customer_id = i.customer_id
JOIN invoice_line il ON il.invoice_id = i.invoice_id
JOIN track t ON t.track_id = il.track_id
JOIN album2 alb ON alb.album_id = t.album_id
JOIN best_selling_artist bsa ON bsa.artist_id = alb.artist_id
GROUP BY 1,2,3,4
ORDER BY 5 DESC;

-- so basically here we first find out hbest selling artist n thn later we find the customer who pay them

/* Q2: We want to find out the most popular music Genre for each country. We determine the most popular genre as the
 genre with the highest amount of purchases. Write a query that returns each country along with the top Genre. For
 countries where the maximum number of purchases is shared return all Genres. */

/* Steps : There are two parts in question- first most popular music genre and second need data at country level. */

-- 1. GENRE(TOP GENRE NAME)->TRACK->INVOICE_LINE->INVOICE(GROUP BY BILLING COUNTRY, n count(billing country)

WITH POPULAR_GENRE AS
(
SELECT C.country AS COUNTRY,  G.name, COUNT(IL.quantity) as PURCHASES ,
ROW_NUMBER() OVER(PARTITION BY C.country ORDER BY COUNT(IL.quantity) DESC) AS RowNo -- we use rowno to get max purchase of each country
FROM genre G 
join track T on T.genre_id= G.genre_id
JOIN invoice_line IL ON IL.track_id= T.track_id
JOIN invoice I ON I.invoice_id= IL.invoice_id
JOIN customer C ON C.customer_id= I.customer_id
group by  COUNTRY, G.name
ORDER BY 1 asc, 2 DESC
)
SELECT * FROM POPULAR_GENRE WHERE RowNo <=1;



/* Q3: Write a query that determines the customer that has spent the most on music for each country. 
Write a query that returns the country along with the top customer and how much they spent. 
For countries where the top amount spent is shared, provide all customers who spent this amount. */

/* Steps to Solve:  Similar to the above question. There are two parts in question- 
first find the most spent on music for each country and second filter the data for respective customers. */

 -- customer(country, cust_name), invoice(total)
 
 WITH TOP_CUSTOMER AS
 (
 SELECT C.country AS COUNTRY , C.first_name, C.last_name, SUM( I.total) as TOTAl,
 ROW_NUMBER() OVER (PARTITION BY C.country  ORDER BY SUM(I.total) DESC) AS rowno
 FROM customer C
 JOIN invoice I on I.customer_id= C.customer_id
 GROUP BY COUNTRY, C.first_name, C.last_name
 )
 SELECT * FROM TOP_CUSTOMER WHERE rowno<= 1 ;
 