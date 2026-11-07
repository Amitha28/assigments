
-- SECTION 1: DATABASE, TABLES, DDL, DML AND CONSTRAINTS
--  Create a separate practice database and select it.
CREATE DATABASE IF NOT EXISTS sql_practice_lab;
USE sql_practice_lab;

--  Create a table with PRIMARY KEY, NOT NULL, UNIQUE, CHECK and DEFAULT.
CREATE TABLE IF NOT EXISTS students (
    student_id INT PRIMARY KEY,
    student_name VARCHAR(60) NOT NULL,
    email VARCHAR(100) UNIQUE,
    age INT CHECK (age >= 18),
    city VARCHAR(50) DEFAULT 'Buffalo',
    course VARCHAR(50)
);

--  Insert a few sample records (safe to run again).
INSERT INTO students (student_id, student_name, email, age, city)
VALUES (1, 'Alice', 'alice@example.com', 23, 'Buffalo'),
       (2, 'Bob', 'bob@example.com', 25, 'New York'),
       (3, 'Charlie', 'charlie@example.com', 22, DEFAULT)
ON DUPLICATE KEY UPDATE student_name = VALUES(student_name);

-- View all students, then select only names and cities.
SELECT * FROM students;
SELECT student_name, city FROM students;




--  Display actor first and last names.
SELECT first_name, last_name FROM sakila.actor;

--  Find different movie ratings without duplicates.
SELECT DISTINCT rating FROM sakila.film;

--  Find PG-rated movies with rental duration = 5.
SELECT title, rating, rental_duration
FROM sakila.film
WHERE rating = 'PG' AND rental_duration = 5;

-- Find films rated PG OR longer than 120 minutes.
SELECT title, rating, length
FROM sakila.film
WHERE rating = 'PG' OR length > 120;

-- Find films whose rental duration is not 4, 6 or 7.
SELECT title, rental_duration
FROM sakila.film
WHERE rental_duration NOT IN (4, 6, 7);

--  Show ten films with the highest rental rate.
SELECT title, rental_rate
FROM sakila.film
ORDER BY rental_rate DESC, title ASC
LIMIT 10;

--  Find films with missing original_language_id.
SELECT film_id, title, original_language_id
FROM sakila.film
WHERE original_language_id IS NULL;

-- SECTION 3: LIKE, NULL, BETWEEN AND AGGREGATES
--  Find cities starting with A (the % wildcard).
SELECT city FROM sakila.city WHERE city LIKE 'A%';

--  Find film titles that contain the word SUPER.
SELECT title FROM sakila.film WHERE title LIKE '%SUPER%';

--  Find first names with exactly five characters (the _ wildcard).
SELECT first_name FROM sakila.actor WHERE first_name LIKE '_____';

-- Find rentals not returned yet.
SELECT rental_id, customer_id, rental_date, return_date
FROM sakila.rental
WHERE return_date IS NULL;

--  Find rentals that started between May 26 and May 30, 2005.
SELECT rental_id, customer_id, rental_date
FROM sakila.rental
WHERE rental_date >= '2005-05-26'
  AND rental_date < '2005-05-31';

-- Compare total films, distinct film ratings and average film length.
SELECT COUNT(*) AS film_count,
       COUNT(DISTINCT rating) AS distinct_ratings,
       ROUND(AVG(length), 2) AS avg_length
FROM sakila.film;

--  Count films in each rating category.
SELECT rating, COUNT(*) AS film_count
FROM sakila.film
GROUP BY rating
ORDER BY film_count DESC;

--  Show customers with fewer than 3 unreturned rentals (but at least 1).
-- WHERE filters individual rentals; HAVING filters grouped customer counts.
SELECT customer_id, COUNT(*) AS unreturned_rentals
FROM sakila.rental
WHERE return_date IS NULL
GROUP BY customer_id
HAVING COUNT(*) < 3
ORDER BY unreturned_rentals DESC, customer_id;

-- Show customers whose total payment exceeds 100.
SELECT customer_id, ROUND(SUM(amount), 2) AS total_paid
FROM sakila.payment
GROUP BY customer_id
HAVING SUM(amount) > 100
ORDER BY total_paid DESC;

-- SECTION 4: JOIN TYPES AND TABLE RELATIONSHIPS
-- INNER JOIN: show customers and their rentals.
SELECT c.customer_id, c.first_name, r.rental_id, r.rental_date
FROM sakila.customer c
INNER JOIN sakila.rental r ON r.customer_id = c.customer_id
LIMIT 30;

-- LEFT JOIN: show all customers and their rental count, including zero.
SELECT c.customer_id, c.first_name, c.last_name,
       COUNT(r.rental_id) AS rental_count
FROM sakila.customer c
LEFT JOIN sakila.rental r ON r.customer_id = c.customer_id
GROUP BY c.customer_id, c.first_name, c.last_name
ORDER BY rental_count ASC, c.customer_id;

--  RIGHT JOIN: keep all rows from the payment table.
SELECT c.customer_id, c.first_name, p.payment_id, p.amount
FROM sakila.customer c
RIGHT JOIN sakila.payment p ON p.customer_id = c.customer_id
LIMIT 30;

-- Q FULL OUTER JOIN simulation with LEFT JOIN + RIGHT JOIN + UNION.
-- MySQL does not support FULL OUTER JOIN directly.
-- for this: Uses our own practice tables created below 

-- Q28. Create five small practice tables resembling the supplied JOIN demo.
CREATE TABLE IF NOT EXISTS demo_users (
    user_id INT PRIMARY KEY, user_name VARCHAR(50)
);
CREATE TABLE IF NOT EXISTS demo_orders (
    order_id INT PRIMARY KEY, user_id INT NULL, order_status CHAR(1),
    CONSTRAINT fk_demo_order_user FOREIGN KEY (user_id) REFERENCES demo_users(user_id)
);
CREATE TABLE IF NOT EXISTS demo_products (
    product_id INT PRIMARY KEY, order_id INT NULL, product_name VARCHAR(50),
    CONSTRAINT fk_demo_product_order FOREIGN KEY (order_id) REFERENCES demo_orders(order_id)
);
CREATE TABLE IF NOT EXISTS demo_profiles (
    user_id INT PRIMARY KEY, profile_status VARCHAR(20),
    CONSTRAINT fk_demo_profile_user FOREIGN KEY (user_id) REFERENCES demo_users(user_id)
);
CREATE TABLE IF NOT EXISTS demo_friendships (
    user_id INT, friend_id INT,
    PRIMARY KEY (user_id, friend_id),
    CONSTRAINT fk_demo_friend_user FOREIGN KEY (user_id) REFERENCES demo_users(user_id),
    CONSTRAINT fk_demo_friend_friend FOREIGN KEY (friend_id) REFERENCES demo_users(user_id)
);

INSERT IGNORE INTO demo_users VALUES
(1,'Alice'), (2,'Bob'), (3,'Charlie'), (4,'David'), (5,'Eve'), (6,'NULL_User');
INSERT IGNORE INTO demo_orders VALUES
(101,1,'A'), (102,2,'B'), (103,2,'C'), (104,3,'A'),
(105,NULL,'B'), (106,6,'C'), (108,NULL,NULL);
INSERT IGNORE INTO demo_products VALUES
(201,101,'Pen'), (202,102,'Book'), (203,103,'Bag'),
(204,106,'Laptop'), (205,NULL,NULL), (206,102,'Marker');
INSERT IGNORE INTO demo_profiles VALUES
(1,'Active'), (2,'Inactive'), (4,'Active');
INSERT IGNORE INTO demo_friendships VALUES
(1,2), (2,1), (2,3), (4,5), (5,1);

-- Practice FULL OUTER JOIN simulation using demo users and orders.
SELECT u.user_id, u.user_name, o.order_id
FROM demo_users u LEFT JOIN demo_orders o ON o.user_id = u.user_id
UNION
SELECT u.user_id, u.user_name, o.order_id
FROM demo_users u RIGHT JOIN demo_orders o ON o.user_id = u.user_id;

--  1:1 relationship: users with profiles.
SELECT u.user_id, u.user_name, p.profile_status
FROM demo_users u
INNER JOIN demo_profiles p ON p.user_id = u.user_id;

--  1:many relationship: every user and their orders (if any).
SELECT u.user_name, o.order_id, o.order_status
FROM demo_users u
LEFT JOIN demo_orders o ON o.user_id = u.user_id;

--  Many:1 relationship: each order and its matching user.
SELECT o.order_id, o.order_status, u.user_name
FROM demo_orders o
INNER JOIN demo_users u ON u.user_id = o.user_id;

--  Many:many / SELF JOIN: show each user and their friend.
SELECT u.user_name AS user_name, f.user_name AS friend_name
FROM demo_friendships fs
JOIN demo_users u ON u.user_id = fs.user_id
JOIN demo_users f ON f.user_id = fs.friend_id;

-- Find users with NO orders (LEFT JOIN + IS NULL).
SELECT u.user_id, u.user_name
FROM demo_users u
LEFT JOIN demo_orders o ON o.user_id = u.user_id
WHERE o.order_id IS NULL;

--  Find orders with NO user (includes NULL foreign keys).
SELECT o.order_id, o.user_id, o.order_status
FROM demo_orders o
LEFT JOIN demo_users u ON u.user_id = o.user_id
WHERE u.user_id IS NULL;

-- CROSS JOIN: every possible user/profile-status combination.
SELECT u.user_name, s.profile_status
FROM demo_users u
CROSS JOIN (SELECT 'Active' AS profile_status UNION ALL SELECT 'Inactive') s;

-- Multi-table JOIN: list rented film titles and customer names.
SELECT c.first_name, c.last_name, f.title, r.rental_date
FROM sakila.customer c
JOIN sakila.rental r ON r.customer_id = c.customer_id
JOIN sakila.inventory i ON i.inventory_id = r.inventory_id
JOIN sakila.film f ON f.film_id = i.film_id
LIMIT 30;

-- SECTION 5: DATE FUNCTIONS AND CASE
--  Calculate the number of days each returned film was rented.
SELECT rental_id, rental_date, return_date,
       DATEDIFF(return_date, rental_date) AS days_rented
FROM sakila.rental
WHERE return_date IS NOT NULL
LIMIT 30;

--  Extract year, month number and month name from rentals.
SELECT rental_id, rental_date,
       YEAR(rental_date) AS rental_year,
       MONTH(rental_date) AS rental_month,
       MONTHNAME(rental_date) AS month_name
FROM sakila.rental
LIMIT 30;

--  Calculate daily payment totals (group by DATE, not timestamp).
SELECT DATE(payment_date) AS pay_date, SUM(amount) AS total_paid
FROM sakila.payment
GROUP BY DATE(payment_date)
ORDER BY pay_date DESC;

--  Payments from the 2 days preceding the latest Sakila payment.
SELECT customer_id, amount, payment_date
FROM sakila.payment
WHERE payment_date >= (SELECT MAX(payment_date) - INTERVAL 2 DAY
                      FROM sakila.payment);

--  Use CASE to classify films by length.
SELECT title, length,
       CASE WHEN length < 60 THEN 'Short'
            WHEN length < 120 THEN 'Medium'
            ELSE 'Long' END AS length_category
FROM sakila.film
LIMIT 30;

-- SECTION 6: SUBQUERIES AND DERIVED TABLES
-- Find actors who appeared in at least 10 films (IN subquery).
SELECT actor_id, first_name, last_name
FROM sakila.actor
WHERE actor_id IN (
    SELECT actor_id FROM sakila.film_actor
    GROUP BY actor_id HAVING COUNT(*) >= 10
);

--  Show payments greater than the overall average amount.
SELECT payment_id, customer_id, amount
FROM sakila.payment
WHERE amount > (SELECT AVG(amount) FROM sakila.payment);

-- Correlated subquery: count films for each actor.
SELECT a.actor_id, a.first_name, a.last_name,
       (SELECT COUNT(*) FROM sakila.film_actor fa
        WHERE fa.actor_id = a.actor_id) AS film_count
FROM sakila.actor a;

--  Correlated subquery: payments above each customer's own average.
SELECT p.payment_id, p.customer_id, p.amount
FROM sakila.payment p
WHERE p.amount > (SELECT AVG(p2.amount)
                  FROM sakila.payment p2
                  WHERE p2.customer_id = p.customer_id);

-- Derived table: actors who appeared in more than 10 films.
SELECT a.actor_id, a.first_name, a.last_name, x.film_count
FROM sakila.actor a
JOIN (SELECT actor_id, COUNT(*) AS film_count
      FROM sakila.film_actor
      GROUP BY actor_id HAVING COUNT(*) > 10) x
  ON x.actor_id = a.actor_id;

-- SECTION 7: COMMON TABLE EXPRESSIONS (CTEs)
--  CTE: customers who made more than 5 payments.
WITH payment_counts AS (
    SELECT customer_id, COUNT(*) AS total_payments
    FROM sakila.payment
    GROUP BY customer_id
)
SELECT c.customer_id, c.first_name, pc.total_payments
FROM sakila.customer c
JOIN payment_counts pc ON pc.customer_id = c.customer_id
WHERE pc.total_payments > 5;

-- Multiple CTEs: total payment and latest payment for each customer.
WITH totals AS (
    SELECT customer_id, SUM(amount) AS total_amount
    FROM sakila.payment GROUP BY customer_id
), latest AS (
    SELECT customer_id, MAX(payment_date) AS last_payment_date
    FROM sakila.payment GROUP BY customer_id
)
SELECT c.customer_id, c.first_name, t.total_amount, l.last_payment_date
FROM sakila.customer c
LEFT JOIN totals t ON t.customer_id = c.customer_id
LEFT JOIN latest l ON l.customer_id = c.customer_id;

--  Recursive CTE: generate the integers 1 through 20.
WITH RECURSIVE numbers AS (
    SELECT 1 AS n
    UNION ALL
    SELECT n + 1 FROM numbers WHERE n < 20
)
SELECT n FROM numbers;

--  Recursive CTE: rental count for the last 10 days in Sakila data.
WITH RECURSIVE days AS (
    SELECT DATE(MAX(rental_date)) - INTERVAL 9 DAY AS rental_day
    FROM sakila.rental
    UNION ALL
    SELECT rental_day + INTERVAL 1 DAY FROM days
    WHERE rental_day < (SELECT DATE(MAX(rental_date)) FROM sakila.rental)
)
SELECT d.rental_day, COUNT(r.rental_id) AS rentals
FROM days d
LEFT JOIN sakila.rental r ON r.rental_date >= d.rental_day
                        AND r.rental_date < d.rental_day + INTERVAL 1 DAY
GROUP BY d.rental_day
ORDER BY d.rental_day;

-- SECTION 8: TEMPORARY TABLES AND VIEWS
-- Temporary table: five most-rented film categories.
DROP TEMPORARY TABLE IF EXISTS top_categories;
CREATE TEMPORARY TABLE top_categories AS
SELECT c.category_id, c.name AS category_name, COUNT(*) AS rental_count
FROM sakila.rental r
JOIN sakila.inventory i ON i.inventory_id = r.inventory_id
JOIN sakila.film_category fc ON fc.film_id = i.film_id
JOIN sakila.category c ON c.category_id = fc.category_id
GROUP BY c.category_id, c.name
ORDER BY rental_count DESC
LIMIT 5;
SELECT * FROM top_categories;

--  Join the temporary table back to category details.
SELECT tc.category_name, tc.rental_count, c.category_id
FROM top_categories tc
JOIN sakila.category c ON c.category_id = tc.category_id;

-- Create a VIEW of each customer's most recent rental.
CREATE OR REPLACE VIEW recent_rentals AS
SELECT customer_id, MAX(rental_date) AS last_rental_date
FROM sakila.rental
GROUP BY customer_id;
SELECT c.first_name, c.last_name, rr.last_rental_date
FROM sakila.customer c
JOIN recent_rentals rr ON rr.customer_id = c.customer_id
LIMIT 30;

-- Create a public customer view with a few selected columns.
CREATE OR REPLACE VIEW customer_public_view AS
SELECT customer_id, first_name, last_name, email
FROM sakila.customer;
SELECT * FROM customer_public_view LIMIT 20;

-- SECTION 9: STORED PROCEDURES - IN, OUT AND DYNAMIC SQL
-- Create an IN-parameter procedure for customer payments.
DROP PROCEDURE IF EXISTS GetCustomerPayments;
DELIMITER //
CREATE PROCEDURE GetCustomerPayments(IN cid INT)
BEGIN
    SELECT payment_id, customer_id, amount, payment_date
    FROM sakila.payment
    WHERE customer_id = cid;
END //
DELIMITER ;
CALL GetCustomerPayments(12);

--  Create an OUT-parameter procedure to return total paid.
DROP PROCEDURE IF EXISTS TotalPaid;
DELIMITER //
CREATE PROCEDURE TotalPaid(IN cid INT, OUT total DECIMAL(10,2))
BEGIN
    SELECT COALESCE(SUM(amount), 0) INTO total
    FROM sakila.payment WHERE customer_id = cid;
END //
DELIMITER ;
CALL TotalPaid(8, @total_paid);
SELECT @total_paid AS total_paid_by_customer_8;

-- Create an INOUT procedure to increment a number.
DROP PROCEDURE IF EXISTS IncrementCounter;
DELIMITER //
CREATE PROCEDURE IncrementCounter(INOUT counter_value INT)
BEGIN
    SET counter_value = counter_value + 1;
END //
DELIMITER ;
SET @counter = 3;
CALL IncrementCounter(@counter);
SELECT @counter AS incremented_counter;

--  Dynamic SQL: count rows in a permitted Sakila table.
-- Restrict table names to the allow-list so input cannot become arbitrary SQL.
DROP PROCEDURE IF EXISTS CountSakilaRows;
DELIMITER //
CREATE PROCEDURE CountSakilaRows(IN table_name VARCHAR(64))
BEGIN
    IF table_name NOT IN ('actor','film','customer','rental','payment') THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Table not allowed';
    END IF;
    SET @sql_text = CONCAT('SELECT COUNT(*) AS total_rows FROM sakila.`', table_name, '`');
    PREPARE stmt FROM @sql_text;
    EXECUTE stmt;
    DEALLOCATE PREPARE stmt;
END //
DELIMITER ;
CALL CountSakilaRows('actor');

