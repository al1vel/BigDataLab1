DROP TABLE IF EXISTS fact_sales CASCADE;
DROP TABLE IF EXISTS dim_date CASCADE;
DROP TABLE IF EXISTS dim_store CASCADE;
DROP TABLE IF EXISTS dim_product CASCADE;
DROP TABLE IF EXISTS dim_supplier CASCADE;
DROP TABLE IF EXISTS dim_seller CASCADE;
DROP TABLE IF EXISTS dim_customer CASCADE;
DROP TABLE IF EXISTS dim_pet CASCADE;
DROP TABLE IF EXISTS dim_pet_breed CASCADE;
DROP TABLE IF EXISTS dim_pet_type CASCADE;
DROP TABLE IF EXISTS dim_postal_code CASCADE;
DROP TABLE IF EXISTS dim_location CASCADE;
DROP TABLE IF EXISTS dim_product_size CASCADE;
DROP TABLE IF EXISTS dim_product_color CASCADE;
DROP TABLE IF EXISTS dim_product_material CASCADE;
DROP TABLE IF EXISTS dim_product_brand CASCADE;
DROP TABLE IF EXISTS dim_product_category CASCADE;
DROP TABLE IF EXISTS dim_pet_category CASCADE;
DROP TABLE IF EXISTS dim_country CASCADE;

CREATE TABLE dim_country (
    country_key INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    country_name VARCHAR(100) NOT NULL UNIQUE
);

CREATE TABLE dim_postal_code (
    postal_code_key INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    postal_code VARCHAR(50),
    country_key INTEGER REFERENCES dim_country(country_key)
);

CREATE TABLE dim_location (
    location_key INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    address_line VARCHAR(255),
    city VARCHAR(100),
    state VARCHAR(100),
    country_key INTEGER REFERENCES dim_country(country_key)
);

CREATE TABLE dim_pet_type (
    pet_type_key INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    pet_type_name VARCHAR(100) NOT NULL UNIQUE
);

CREATE TABLE dim_pet_breed (
    pet_breed_key INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    pet_breed_name VARCHAR(100),
    pet_type_key INTEGER REFERENCES dim_pet_type(pet_type_key)
);

CREATE TABLE dim_pet (
    pet_key INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    pet_name VARCHAR(100),
    pet_breed_key INTEGER REFERENCES dim_pet_breed(pet_breed_key)
);

CREATE TABLE dim_pet_category (
    pet_category_key INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    pet_category_name VARCHAR(100) NOT NULL UNIQUE
);

CREATE TABLE dim_product_category (
    product_category_key INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    product_category_name VARCHAR(100) NOT NULL UNIQUE
);

CREATE TABLE dim_product_brand (
    product_brand_key INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    product_brand_name VARCHAR(100) NOT NULL UNIQUE
);

CREATE TABLE dim_product_material (
    product_material_key INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    product_material_name VARCHAR(100) NOT NULL UNIQUE
);

CREATE TABLE dim_product_color (
    product_color_key INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    product_color_name VARCHAR(100) NOT NULL UNIQUE
);

CREATE TABLE dim_product_size (
    product_size_key INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    product_size_name VARCHAR(100) NOT NULL UNIQUE
);

CREATE TABLE dim_supplier (
    supplier_key INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    supplier_name VARCHAR(255),
    supplier_contact VARCHAR(255),
    supplier_email VARCHAR(255),
    supplier_phone VARCHAR(50),
    location_key INTEGER REFERENCES dim_location(location_key)
);

CREATE TABLE dim_product (
    product_key INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    source_product_id INTEGER,
    product_name VARCHAR(255),
    product_category_key INTEGER REFERENCES dim_product_category(product_category_key),
    pet_category_key INTEGER REFERENCES dim_pet_category(pet_category_key),
    product_brand_key INTEGER REFERENCES dim_product_brand(product_brand_key),
    product_material_key INTEGER REFERENCES dim_product_material(product_material_key),
    product_color_key INTEGER REFERENCES dim_product_color(product_color_key),
    product_size_key INTEGER REFERENCES dim_product_size(product_size_key),
    supplier_key INTEGER REFERENCES dim_supplier(supplier_key),
    product_weight NUMERIC(10, 2),
    product_description TEXT,
    product_rating NUMERIC(3, 2),
    product_reviews INTEGER,
    product_release_date DATE,
    product_expiry_date DATE
);

CREATE TABLE dim_customer (
    customer_key INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    source_customer_id INTEGER,
    first_name VARCHAR(100),
    last_name VARCHAR(100),
    age INTEGER,
    email VARCHAR(255),
    postal_code_key INTEGER REFERENCES dim_postal_code(postal_code_key),
    pet_key INTEGER REFERENCES dim_pet(pet_key)
);

CREATE TABLE dim_seller (
    seller_key INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    source_seller_id INTEGER,
    first_name VARCHAR(100),
    last_name VARCHAR(100),
    email VARCHAR(255),
    postal_code_key INTEGER REFERENCES dim_postal_code(postal_code_key)
);

CREATE TABLE dim_store (
    store_key INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    store_name VARCHAR(255),
    store_phone VARCHAR(50),
    store_email VARCHAR(255),
    location_key INTEGER REFERENCES dim_location(location_key)
);

CREATE TABLE dim_date (
    date_key INTEGER PRIMARY KEY,
    date_value DATE NOT NULL UNIQUE,
    day_of_month SMALLINT NOT NULL,
    month_number SMALLINT NOT NULL,
    month_name VARCHAR(20) NOT NULL,
    quarter_number SMALLINT NOT NULL,
    year_number SMALLINT NOT NULL
);

CREATE TABLE fact_sales (
    sale_key BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    date_key INTEGER REFERENCES dim_date(date_key),
    customer_key INTEGER REFERENCES dim_customer(customer_key),
    seller_key INTEGER REFERENCES dim_seller(seller_key),
    product_key INTEGER REFERENCES dim_product(product_key),
    store_key INTEGER REFERENCES dim_store(store_key),
    source_sale_id INTEGER,
    source_customer_id INTEGER,
    source_seller_id INTEGER,
    source_product_id INTEGER,
    sale_quantity INTEGER,
    sale_total_price NUMERIC(10, 2),
    product_price NUMERIC(10, 2),
    product_quantity INTEGER
);
