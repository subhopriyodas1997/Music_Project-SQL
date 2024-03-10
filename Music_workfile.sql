/* 1. Who is the senior-most employee based on job title? */

SELECT first_name, levels
FROM employee
ORDER BY levels DESC
LIMIT 1;


/* 2. Which countries have the most invoices? */

SELECT billing_country, COUNT(billing_country)
FROM invoice
GROUP BY billing_country
ORDER BY COUNT(billing_country) DESC
LIMIT 10;


/* 3. Write a query that returns one city that has the highest sum of invoice totals.
      Return both the city name and sum of all invoice totals.
	  We would like to throw a promotional music festival in the city we made the most money
*/

SELECT billing_city, SUM(total) AS s
FROM invoice
GROUP BY billing_city
ORDER BY s DESC
LIMIT 1;


/* 4. Write a query that returns the person who has spent the most money? */

SELECT customer.customer_id, customer.first_name, customer.last_name, SUM(invoice.total) AS s
FROM customer
JOIN invoice
ON customer.customer_id = invoice.customer_id
GROUP BY customer.customer_id
ORDER BY s DESC
LIMIT 1;


/* 5. Write a query to return the email, first name, last name and genre
      of all rock music listeners.
	  Return list in alphabetical order by email from a-z.
*/

SELECT customer.email, customer.first_name, customer.last_name, genre.name
FROM customer

JOIN invoice
ON customer.customer_id = invoice.customer_id
JOIN invoice_line
ON invoice.invoice_id = invoice_line.invoice_id
JOIN track
ON invoice_line.track_id = track.track_id
JOIN genre
on track.genre_id = genre.genre_id
WHERE genre.name LIKE '%Rock%'
ORDER BY customer.email ASC;


/* 6. Write a query that returns,
      - Artist Name
	  - Total Track Count
	  Of the top 10 "rock" bands.
*/

SELECT artist.name, COUNT(track.track_id) as total
FROM artist

JOIN album
ON artist.artist_id = album.artist_id
JOIN track
ON album.album_id = track.album_id
JOIN genre
ON track.genre_id = genre.genre_id

WHERE genre.name LIKE '%Rock%'
GROUP BY artist.name
ORDER BY total DESC
LIMIT 10;



/* 7. Return "track names" that have,
      - Song length > Average Song Length
	  
	  Return for each track,
	  - Name
	  - Milliseconds
	  
	  Arrange from longest tracks to shorter ones.
*/

SELECT track.name, track.milliseconds
FROM track
GROUP BY track.name, track.milliseconds
HAVING track.milliseconds > (SELECT AVG(track.milliseconds) 
							 AS avg_track_length 
							 FROM track)
ORDER BY track.milliseconds DESC;


/* 8. Find how much amount each customer spent on artists?
      Return,
	  - Customer Email
	  - Artist Name
	  - Total Spent
*/

SELECT 
    customer.email,
    artist.name,
    SUM(invoice_line.quantity * invoice_line.unit_price) AS total_spent
FROM 
    customer
JOIN 
    invoice ON customer.customer_id = invoice.customer_id
JOIN 
    invoice_line ON invoice.invoice_id = invoice_line.invoice_id
JOIN 
    track ON invoice_line.track_id = track.track_id
JOIN 
    album ON track.album_id = album.album_id
JOIN 
    artist ON album.artist_id = artist.artist_id
GROUP BY 
    customer.email,
    artist.name
ORDER BY 
    total_spent DESC;


/* 9. Find how much amount was spent by each customer on artists?
      Write a query to return,
	  - customer name
	  - artist name
	  - total spent
*/

WITH best_sell_artist AS (
    SELECT 
        album.artist_id AS artist_id, 
        artist.name AS artist_name, 
        SUM(invoice_line.quantity * invoice_line.unit_price) AS total_sales
    FROM 
        invoice_line
    
	JOIN track ON invoice_line.track_id = track.track_id
    JOIN album ON track.album_id = album.album_id
    JOIN artist ON album.artist_id = artist.artist_id
    
	GROUP BY album.artist_id, artist.name
    ORDER BY total_sales DESC
    LIMIT 1
)

SELECT 
    c.customer_id,
    c.first_name,
    c.last_name,
    bsa.artist_name,
    SUM(il.quantity * il.unit_price) AS amount_spent
FROM 
    invoice i

JOIN customer c ON i.customer_id = c.customer_id
JOIN invoice_line il ON i.invoice_id = il.invoice_id
JOIN track t ON il.track_id = t.track_id
JOIN album alb ON t.album_id = alb.album_id
JOIN best_sell_artist bsa ON alb.artist_id = bsa.artist_id

GROUP BY c.customer_id, c.first_name, c.last_name, bsa.artist_name
ORDER BY amount_spent DESC;


/* 10. We find the most popular music genre for each country.
       We determine the most popular genre as the genre with the highest amount of purchases.
	   Write a query to return,
	  - each country with top genre
	  
	  For countries where maximum number of purchases is shared, return all genres. 	 
*/

WITH popular_genre AS (
         SELECT 
	           COUNT(invoice_line.quantity) AS purchases,
	           customer.country,
	           genre.name,
	           genre.genre_id,
	           ROW_NUMBER() OVER(PARTITION BY customer.country ORDER BY COUNT(invoice_line.quantity) DESC) as row_no
	     FROM invoice_line
	    
	     JOIN invoice ON invoice_line.invoice_id = invoice.invoice_id
	     JOIN customer ON invoice.customer_id = customer.customer_id
	     JOIN track ON invoice_line.track_id = track.track_id
	     JOIN genre ON track.genre_id = genre.genre_id
	 
	     GROUP BY 2,3,4
	     ORDER BY 2 ASC, 1 DESC	    
)
 
SELECT * FROM popular_genre
WHERE row_no <= 1;


/* 11. Write a query that determines the customer that has spent the most on music for each country.
       Write a query that return,
	   - Country
	   - Top Customer
	   - How much the top customer spent?
	   
	   For countries where the top amount spent is shared, 
	   Provide all customers who spent this amount. 
*/


WITH RECURSIVE 
          customer_with_country AS (
               SELECT
	                 customer.customer_id,
	                 first_name,
	                 last_name,
	                 billing_country,
	                 SUM(total) AS total_spend
	           
	           FROM invoice 
	           JOIN customer ON invoice.customer_id = customer.customer_id
	
	           GROUP BY 1,2,3,4
	           ORDER BY 1,2 DESC	            
           ),
		   
		   country_max_spend AS(
		       SELECT 
			         billing_country,
			         MAX(total_spend) AS max_spend
			   
			   FROM customer_with_country
			    
			   GROUP BY billing_country
		   )
		   
SELECT 
      cc.billing_country,
	  cc.total_spend,
	  cc.first_name,
	  cc.last_name,
	  cc.customer_id
	  
FROM customer_with_country cc
JOIN country_max_spend ms ON cc.billing_country = ms.billing_country

WHERE cc.total_spend = ms.max_spend
ORDER BY 1;






