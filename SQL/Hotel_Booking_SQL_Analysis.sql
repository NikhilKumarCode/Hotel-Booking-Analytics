
-- ============================================================
-- HOTEL BOOKING ANALYTICS
-- SQL DATA ANALYSIS
-- ============================================================

-- Objective:
-- Analyze hotel bookings, cancellation patterns, customer behavior, pricing and estimated revenue
-- using SQL.
-- ============================================================

-- ============================================================
-- 1. DATA VALIDATION
-- ============================================================

-- Question 1: How many booking records are available in the cleaned dataset?
SELECT
    COUNT(*) AS total_bookings
FROM hotel_bookings_cleaned;


-- Finding:
-- The cleaned dataset contains 119,209 booking records, which matches the final dataset validated in Python.

-- Question 2: What columns and data types are available in the cleaned hotel booking dataset?

PRAGMA table_info(hotel_bookings_cleaned);

-- Finding:
-- The dataset contains 42 columns with appropriate INTEGER, REAL and TEXT types.
-- Date columns are stored as TEXT in ISO format.

-- Question 3: Are there any missing values in the key columns of the imported dataset?
SELECT
	sum(CASE WHEN hotel IS NULL THEN 1 ELSE 0 END)
		AS missing_hotel,
		
	sum(CASE WHEN arrival_date IS NULL THEN 1 ELSE 0 END)
		AS missing_arrival_date,
		
	sum(CASE WHEN adr IS NULL THEN 1 ELSE 0 END)
		AS missing_adr,
		
	sum(CASE WHEN estimated_revenue IS NULL THEN 1 ELSE 0 END)
		AS missing_estimated_revenue,
		
	sum(CASE WHEN completed_stay_revenue IS NULL THEN 1 ELSE 0 END)
		AS missing_completed_revenue
		
FROM hotel_bookings_cleaned;

-- Findings:
-- The dataset contains one missing ADR value and one missing estimated revenue value,
-- consistent with the final Python Validation.
-- No missing values were found in hotel, arrival_date or completed_stay_revenue.

-- Question 4: How many bookings were cancelled versus not cancelled, and does the SQL dataset match our Python result?
SELECT
	is_canceled,
	count(*) AS total_bookings,
	round(count(*) * 100.0/
	(SELECT count(*) FROM hotel_bookings_cleaned), 2) AS booking_percentage
FROM hotel_bookings_cleaned
GROUP BY is_canceled
ORDER By is_canceled;

-- Finding:
-- Of the 119,209 bookings, 75,010 (62.92%) were not cancelled, while 44,199 (37.08%) were cancelled.
-- These results match the Python analysis.


-- ============================================================
-- 2. BOOKING & CANCELLATION ANALYSIS
-- ============================================================

-- Question 5: What is the cancellation rate for each hotel type?
SELECT
	hotel,
	count(*) AS total_bookings,
	sum(is_canceled) AS cancelled_bookings,
	round(sum(is_canceled) * 100.0 / count(*), 2) AS cancellation_rate
FROM hotel_bookings_cleaned
GROUP BY hotel
ORDER BY cancellation_rate DESC;

-- Findings:
-- City Hotel has a higher cancellation rate (41.79%) compared to Resort Hotel (27.77%).
-- This indicates that City Hotel experiences a greater proportion of booking cancellations.

-- Question 6: How does lead time affect booking cancellation rates?
SELECT
	lead_time_category,
	count(*) AS total_bookings,
	sum(is_canceled) as cancelled_bookings,
	round(SUM(is_canceled) * 100.0 / count(*), 2) as cancellation_rate
FROM hotel_bookings_cleaned
GROUP BY lead_time_category
ORDER BY min(lead_time);

-- Finding:
-- Cancellation rates increase as booking lead time increases. Bookings made within 0–7 days have the
-- lowest cancellation rate (9.60%), while bookings made 181+ days in advance have the highest (57.01%).

-- Question 7: How does deposit type affect booking cancellation rates?
SELECT
	deposit_type,
	count(*) as total_bookings,
	sum(is_canceled) as cancelled_bookings,
	round(sum(is_canceled) * 100.0 / count(*), 2) as cancellation_rate
FROM hotel_bookings_cleaned
GROUP BY deposit_type
ORDER BY cancellation_rate DESC;

-- Finding:
-- Non Refund bookings have the highest cancellation rate (99.36%), followed by No Deposit (28.40%)
-- and Refundable bookings (22.22%).
-- The Refundable category contains only 162 bookings, so its results should be interpreted cautiously.

-- Question 8: Which market segments have the highest cancellation rates?
SELECT
	market_segment,
	count(*) as total_bookings,
	sum(is_canceled) as cancelled_bookings,
	round(sum(is_canceled) * 100.0 / count(*), 2) as cancellation_rate
FROM hotel_bookings_cleaned
GROUP BY market_segment
ORDER BY cancellation_rate DESC;

-- Finding:
-- The Groups segment has the highest cancellation rate (61.11%) among the major market segments.
-- Online TA (36.76%) and Offline TA/TO (34.33%) also have relatively high cancellation rates.
-- Undefined has a 100% cancellation rate but contains only two bookings, so it is not representative.

-- ============================================================
-- 3. SEASONAL BOOKING TRENDS
-- ============================================================

-- Question 9: Which months have the highest average number of bookings?
WITH monthly_bookings as (
	SELECT
		arrival_date_year,
		arrival_month_number,
		arrival_date_month, 
		count(*) as total_bookings
	FROM hotel_bookings_cleaned
	GROUP BY 
		arrival_date_year,
		arrival_month_number, 
		arrival_date_month)
		
SELECT
	arrival_date_month,
	round(avg(total_bookings), 2) as avg_monthly_bookings
FROM monthly_bookings
GROUP BY arrival_month_number, arrival_date_month
ORDER BY avg_monthly_bookings DESC;

-- Finding:
-- May has the highest average monthly bookings (5,890), followed by October (5,573.5) and April (5,539).
-- January has the lowest average (2,960.5).
-- Partial-year coverage should be considered when interpreting seasonal booking patterns.

-- Question 10: How do monthly booking trends differ between City Hotel and Resort Hotel?
WITH monthly_bookings as (
	SELECT
		hotel,
		arrival_date_year,
		arrival_month_number,
		arrival_date_month, 
		count(*) as total_bookings
	FROM hotel_bookings_cleaned
	GROUP BY 
		hotel,
		arrival_date_year,
		arrival_month_number, 
		arrival_date_month)
		
SELECT
	hotel,
	arrival_date_month,
	round(avg(total_bookings), 2) as avg_monthly_bookings
FROM monthly_bookings
GROUP BY hotel, arrival_month_number, arrival_date_month
ORDER BY hotel, arrival_month_number;

-- Finding:
-- City Hotel records more bookings than Resort Hotel across all months.
-- City Hotel has its highest average monthly bookings in May (4,110.5),
-- while Resort Hotel peaks in April (1,804.5).
-- January has the lowest average for both hotels.
-- Partial-year coverage should be considered when interpreting seasonal booking trends.

-- Question 11: How do cancellation rates vary by month?
SELECT
	arrival_date_month,
	count(*) as total_bookings,
	sum(is_canceled) as cancelled_bookings,
	round(sum(is_canceled) * 100.0 / count(*), 2) as cancellation_rate
FROM hotel_bookings_cleaned
GROUP BY arrival_month_number, arrival_date_month
ORDER BY cancellation_rate DESC;

-- Finding:
-- June has the highest cancellation rate (41.49%), followed by April (40.78%) and May (39.70%).
-- January has the lowest cancellation rate (30.50%).
-- These results describe the available booking records; partial-year coverage limits seasonal comparisons.

-- ============================================================
-- 4. CUSTOMER BEHAVIOR ANALYSIS
-- ============================================================

-- Question 12: Do repeated guests have lower cancellation rates than first-time guests?
SELECT
	CASE
		WHEN is_repeated_guest = 1 THEN 'Repeated Guest'
		ELSE 'First-Time Guest'
	END AS guest_type,
	
	count(*) as total_bookings,
	sum(is_canceled) as cancelled_booking,
	round(sum(is_canceled) * 100.0 / count(*), 2) as cancellation_rate
FROM hotel_bookings_cleaned
GROUP By is_repeated_guest
ORDER BY cancellation_rate DESC;

-- Finding:
-- First-time guests have a cancellation rate of 37.81%,
-- compared to 14.65% for repeated guests.
-- Repeated guests are associated with lower cancellation rates in the dataset.

-- Question 13: How do cancellation rates differ by customer type?
SELECT
	customer_type,
	count(*) as total_bookings,
	sum(is_canceled) as cancelled_bookings,
	round(sum(is_canceled) * 100.0 / count(*), 2) as cancellation_rate
FROM hotel_bookings_cleaned
GROUP BY customer_type
ORDER BY cancellation_rate DESC;

-- Finding:
-- Transient customers have the highest cancellation
-- rate (40.79%), followed by Contract (30.99%) and Transient-Party customers (25.45%).
-- Group customers have the lowest cancellation rate (10.10%), based on 574 bookings.

-- Question 14: Does changing the assigned room type relate to booking cancellations?
SELECT 
	CASE 
		WHEN room_type_changed = 1 THEN 'Room Changed'
		ELSE 'Room Not Changed'
	END as room_change_status,
	
	count(*) as total_bookings,
	sum(is_canceled) as cancelled_bookings,
	round(sum(is_canceled) * 100.0 / count(*), 2) as cancellation_rate
FROM hotel_bookings_cleaned
GROUP BY room_type_changed
ORDER BY cancellation_rate DESC;

-- Finding:
-- Bookings without a room-type change have a cancellation rate of 41.56%, compared to 5.41%
-- for bookings with a recorded room-type change.
-- This is an observed association and does not establish that room changes prevent cancellations.

-- ============================================================
-- 5. PRICING & REVENUE ANALYSIS
-- ============================================================

-- Question 15: What is the average daily rate (ADR) for each hotel type?
SELECT
	hotel,
	count(adr) as bookings_with_valid_adr,
	round(avg(adr), 2) as average_adr,
	round(min(adr), 2) as minimum_adr,
	round(max(adr), 2) as maximum_adr
FROM hotel_bookings_cleaned
GROUP BY hotel
ORDER BY average_adr DESC;

-- Finding:
-- City Hotel has a higher average ADR (105.44) compared to Resort Hotel (94.99).
-- The maximum ADR is 510 for City Hotel and 508 for Resort Hotel.
-- One missing ADR value is excluded from the City Hotel calculation.

-- Question 16: Which hotel generates the highest completed-stay revenue?
SELECT
	hotel,
	round(sum(completed_stay_revenue), 2) as total_completed_revenue,
	count(CASE WHEN reservation_status = 'Check-Out' THEN 1 END) as completed_bookings,
	round(avg(CASE WHEN reservation_status = 'Check-Out' THEN completed_stay_revenue END), 2) 
		as avg_revenue_per_completed_booking
FROM hotel_bookings_cleaned
GROUP BY hotel
ORDER BY total_completed_revenue DESC;

-- Finding:
-- City Hotel generates higher estimated completed-stay revenue (14,385,342.00) than Resort Hotel 
-- (11,601,634.03).
-- However, Resort Hotel has higher average revenue per completed booking (401.08), compared to
-- City Hotel (312.15).

-- Question 17: What is the average length of stay for each hotel type?
SELECT
	hotel,
	count(*) as completed_bookings,
	round(avg(total_nights), 2) as avg_length_of_stay,
	min(total_nights) as minimum_nights,
	max(total_nights) as maximum_nights
FROM hotel_bookings_cleaned
WHERE reservation_status = 'Check-Out' and total_nights > 0
GROUP By hotel
ORDER By avg_length_of_stay DESC;

-- Finding:
-- Resort Hotel has a longer average completed stay (4.20 nights) compared to City Hotel (2.93 nights).
-- The longest recorded stays are 69 nights at Resort Hotel and 48 nights at City Hotel.
-- Zero-night bookings are excluded from this analysis.

-- Question 18: Which distribution channels generate the highest estimated completed-stay revenue?
SELECT
	distribution_channel,
	count(case when reservation_status = 'Check-Out' then 1 end) as completed_bookings,
	round(sum(completed_stay_revenue), 2) as total_completed_revenue,
	round(sum(completed_stay_revenue) * 100.0 /
		(SELECT sum(completed_stay_revenue)
		FROM hotel_bookings_cleaned), 2) as revenue_percentage
FROM hotel_bookings_cleaned
GROUP BY distribution_channel
ORDER BY total_completed_revenue DESC;

-- Finding:
-- TA/TO generates the highest estimated completed-stay revenue (20,802,010.34), accounting for 80.05%
-- of total revenue.
-- Direct bookings contribute 16.64%, followed by Corporate bookings at 3.19%.
-- The hotel dataset is heavily reliant on TA/TO for estimated completed-stay revenue.

-- ============================================================
-- 6. ADVANCED SQL ANALYSIS
-- ============================================================

-- Question 19: Which market segments contribute the most estimated completed-stay revenue
-- within each hotel?
WITH segment_revenue as(
	SELECT
		hotel,
		market_segment,
		round(sum(completed_stay_revenue), 2) as total_revenue
	FROM hotel_bookings_cleaned
	GROUP BY hotel, market_segment)
SELECT
	hotel,
	market_segment,
	total_revenue,
	rank() OVER (PARTITION BY hotel
		ORDER BY total_revenue DESC) as revenue_rank
FROM segment_revenue
ORDER BY hotel, revenue_rank;

-- Finding:
-- Online TA generates the highest estimated completed-stay revenue for both City Hotel (8,755,281.19) and
-- Resort Hotel (4,951,857.90).
-- Offline TA/TO ranks second, followed by Direct bookings, for both hotels.
-- Resort Hotel generates more revenue from Offline TA/TO and Direct bookings than City Hotel.

-- Question 20: Which months generate the highest estimated completed-stay revenue for each hotel?
WITH segment_revenue as(
	SELECT
		hotel,
		arrival_month_number,
		arrival_date_month,
		round(sum(completed_stay_revenue), 2) as total_revenue
	FROM hotel_bookings_cleaned
	GROUP BY hotel, arrival_month_number, arrival_date_month)
SELECT
	hotel,
	arrival_date_month,
	total_revenue,
	rank() OVER (PARTITION BY hotel
		ORDER BY total_revenue DESC) as revenue_rank
FROM segment_revenue
ORDER BY hotel, revenue_rank;

-- Finding:
-- August generates the highest estimated completed-stay revenue for both City Hotel (1,976,431.85) and
-- Resort Hotel (2,939,056.61).
-- July ranks second for both hotels.
-- January generates the lowest estimated revenue for both hotels.
-- These totals are based on the available records
-- and are not adjusted for partial-year coverage.