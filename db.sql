-- STEP 1: DROP TABLES IF THEY EXIST
DROP TABLE IF EXISTS fact_ev_sales;
DROP TABLE IF EXISTS fact_charging_stations;
DROP TABLE IF EXISTS dim_state;
DROP TABLE IF EXISTS dim_vehicle_category;
DROP TABLE IF EXISTS staging_ev_sales;
DROP TABLE IF EXISTS staging_charging;

-- STEP 2: CREATE TABLE staging_ev_sales (
    year INT,
    month_name TEXT,
    date TEXT,
    state TEXT,
    vehicle_class TEXT,
    vehicle_category TEXT,
    vehicle_type TEXT,
    ev_sales_quantity FLOAT
);


CREATE TABLE staging_charging (
    name TEXT,
    state TEXT,
    city TEXT,
    address TEXT,
    latitude FLOAT,
    longitude FLOAT,
    type TEXT
);

-- STEP 3: CREATE DIMENSION TABLES
CREATE TABLE dim_state (
    state_id SERIAL PRIMARY KEY,
    state_name TEXT UNIQUE
);

CREATE TABLE dim_vehicle_category (
    category_id SERIAL PRIMARY KEY,
    category_name TEXT UNIQUE
);

-- STEP 4: POPULATE DIMENSIONS
INSERT INTO dim_state (state_name)
SELECT DISTINCT TRIM(UPPER(state))
FROM (
    SELECT state FROM staging_ev_sales
    UNION
    SELECT state FROM staging_charging
) AS all_states
WHERE state IS NOT NULL;

INSERT INTO dim_vehicle_category (category_name)
SELECT DISTINCT TRIM(UPPER(vehicle_category))
FROM staging_ev_sales
WHERE vehicle_category IS NOT NULL;

-- STEP 5: CREATE FACT TABLES
CREATE TABLE fact_ev_sales (
    id SERIAL PRIMARY KEY,
    year INT,
    vehicle_class TEXT,
    vehicle_category_id INT REFERENCES dim_vehicle_category(category_id),
    state_id INT REFERENCES dim_state(state_id),
    ev_sales_quantity FLOAT,
    sales_category TEXT
);

CREATE TABLE fact_charging_stations (
    id SERIAL PRIMARY KEY,
    station_name TEXT,
    city TEXT,
    address TEXT,
    state_id INT REFERENCES dim_state(state_id),
    latitude FLOAT,
    longitude FLOAT,
    charging_type TEXT
);

-- STEP 6: LOAD TRANSFORMED DATA INTO FACT TABLES

-- Insert EV sales
INSERT INTO fact_ev_sales (
    year, vehicle_class, vehicle_category_id, state_id, ev_sales_quantity, sales_category
)
SELECT 
    s.year,
    s.vehicle_class,
    (SELECT category_id FROM dim_vehicle_category WHERE category_name = TRIM(UPPER(s.vehicle_category))),
    (SELECT state_id FROM dim_state WHERE state_name = TRIM(UPPER(s.state))),
    COALESCE(s.ev_sales_quantity, 0),
    CASE 
        WHEN COALESCE(s.ev_sales_quantity, 0) < 100 THEN 'Low'
        WHEN s.ev_sales_quantity BETWEEN 100 AND 999 THEN 'Medium'
        ELSE 'High'
    END
FROM staging_ev_sales s;

-- Insert charging station data
INSERT INTO fact_charging_stations (
    station_name, city, address, state_id, latitude, longitude, charging_type
)
SELECT
    name,
    city,
    address,
    (SELECT state_id FROM dim_state WHERE state_name = TRIM(UPPER(state))),
    latitude,
    longitude,
    type
FROM staging_charging;
