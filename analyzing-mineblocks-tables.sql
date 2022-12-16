-- The purchases table lists all purchases made by players while they’re playing Mineblocks.
SELECT *
FROM purchases
ORDER BY id
LIMIT 10;
 
-- The gameplays table lists the date and platform for each session a user plays.
SELECT * 
FROM gameplays
ORDER BY id
LIMIT 10;

-- Daily Revenue is simply the sum of money made per day.
SELECT 
  DATE(created_at),
  ROUND(SUM(price), 2)
FROM purchases
GROUP BY 1
ORDER BY 1;

-- Update our daily revenue query to exclude refunds.
SELECT 
  DATE(created_at),
  ROUND(SUM(price), 2) as daily_rev
FROM purchases
WHERE refunded_at IS NULL
GROUP BY 1
ORDER BY 1;

-- Calculate Daily Active Users for Mineblocks.
SELECT 
  DATE(created_at),
  COUNT(DISTINCT(user_id)) as dau
FROM gameplays
GROUP BY 1
ORDER BY 1;

-- Calculate DAU for Mineblocks per-platform.
SELECT 
  DATE(created_at),
  platform,
  COUNT(DISTINCT(user_id)) as dau
FROM gameplays
GROUP BY 1,2
ORDER BY 1,2;

-- To get Daily ARPPU (Daily Average Revenue Per Purchasing User), modify the daily revenue query from earlier to divide by the number of purchasers.
SELECT 
  DATE(created_at),
  ROUND(SUM(price) / COUNT(DISTINCT(user_id)), 2) as arppu
FROM purchases
WHERE refunded_at IS NULL 
GROUP BY 1
ORDER BY 1;

-- Use a with clause to define daily_revenue and then select from it.
WITH daily_revenue AS (
  SELECT 
    DATE(created_at) as dt,
    ROUND(SUM(price), 2) as rev
  FROM purchases
  WHERE refunded_at IS NULL
  GROUP BY 1
)
SELECT * 
FROM daily_revenue 
ORDER BY dt;

-- Building on this CTE, we can add in DAU from earlier.
WITH daily_revenue as (
  SELECT
    DATE(created_at) as dt,
    ROUND(SUM(price), 2) as rev
  FROM purchases
  WHERE refunded_at is null
  GROUP BY 1
), 

daily_players AS(
  SELECT 
    DATE(created_at) as dt,
    COUNT(DISTINCT(user_id)) as players
  FROM gameplays
  GROUP BY 1
)
SELECT *
FROM daily_players
ORDER BY dt;

-- Now that we have the revenue and DAU, join them on their dates and calculate daily ARPU (Average Revenue Per User).
SELECT 
  daily_revenue.dt,
  daily_revenue.rev / daily_players.players
FROM daily_revenue
  JOIN daily_players using(dt);

-- To calculate retention, start from a query that selects the date(created_at) as dt and user_id columns from the gameplays table.
SELECT
  DATE(created_at) AS dt,
  user_id
FROM gameplays AS g1
ORDER BY 1
LIMIT 100;

-- Now we’ll join gameplays on itself so that we can have access to all gameplays for each player, for each of their gameplays.
SELECT 
  DATE(g1.created_at) as dt,
  g1.user_id
FROM gameplays AS g1
JOIN gameplays AS g2 
  ON g1.user_id = g2.user_id
ORDER BY 1
LIMIT 100;

-- 1 Day Retention is defined as the number of players who returned the next day divided by the number of original players, per day.
SELECT 
  DATE(g1.created_at) as dt,
  g1.user_id,
  g2.user_id
FROM gameplays as g1
JOIN gameplays as g2
  ON g1.user_id = g2.user_id
  AND DATE(g1.created_at) = DATE(datetime(g2.created_at, '-1 day'))
ORDER BY 1
LIMIT 100;

-- Change the join clause to use left join and count the distinct number of users from g1 and g2 per date.
SELECT 
  DATE(g1.created_at) AS dt,
  COUNT(DISTINCT(g1.user_id)) AS total_users,
  COUNT(DISTINCT(g2.user_id)) AS retained_users
FROM gameplays as g1
LEFT JOIN gameplays as g2
  ON g1.user_id = g2.user_id
  AND DATE(g1.created_at) = DATE(datetime(g2.created_at, '-1 day'))
GROUP BY 1
ORDER BY 1
LIMIT 100;

-- Now that we have retained users as count(distinct g2.user_id) and total users as count(distinct g1.user_id), divide retained users by total users to calculate 1 day retention!
SELECT 
  DATE(g1.created_at) AS dt,
  ROUND(100 * COUNT(DISTINCT(g2.user_id)) / 
    COUNT(DISTINCT(g1.user_id)), 2) AS retention
FROM gameplays AS g1
LEFT JOIN gameplays as g2 
  ON g1.user_id = g2.user_id
  AND DATE(g1.created_at) = DATE(datetime(g2.created_at, '-1 day'))
GROUP BY 1
ORDER BY 1
LIMIT 100;
