CREATE TEMP VIEW normalized_mock_data AS
SELECT
    id,
    NULLIF(TRIM(customer_first_name), '') AS customer_first_name,
    NULLIF(TRIM(customer_last_name), '') AS customer_last_name,
    customer_age,
    NULLIF(TRIM(customer_email), '') AS customer_email,
    NULLIF(TRIM(customer_country), '') AS customer_country,
    NULLIF(TRIM(customer_postal_code), '') AS customer_postal_code,
    NULLIF(TRIM(customer_pet_type), '') AS customer_pet_type,
    NULLIF(TRIM(customer_pet_name), '') AS customer_pet_name,
    NULLIF(TRIM(customer_pet_breed), '') AS customer_pet_breed,
    NULLIF(TRIM(seller_first_name), '') AS seller_first_name,
    NULLIF(TRIM(seller_last_name), '') AS seller_last_name,
    NULLIF(TRIM(seller_email), '') AS seller_email,
    NULLIF(TRIM(seller_country), '') AS seller_country,
    NULLIF(TRIM(seller_postal_code), '') AS seller_postal_code,
    NULLIF(TRIM(product_name), '') AS product_name,
    NULLIF(TRIM(product_category), '') AS product_category,
    product_price,
    product_quantity,
    sale_date,
    sale_customer_id,
    sale_seller_id,
    sale_product_id,
    sale_quantity,
    sale_total_price,
    NULLIF(TRIM(store_name), '') AS store_name,
    NULLIF(TRIM(store_location), '') AS store_location,
    NULLIF(TRIM(store_city), '') AS store_city,
    NULLIF(TRIM(store_state), '') AS store_state,
    NULLIF(TRIM(store_country), '') AS store_country,
    NULLIF(TRIM(store_phone), '') AS store_phone,
    NULLIF(TRIM(store_email), '') AS store_email,
    NULLIF(TRIM(pet_category), '') AS pet_category,
    product_weight,
    NULLIF(TRIM(product_color), '') AS product_color,
    NULLIF(TRIM(product_size), '') AS product_size,
    NULLIF(TRIM(product_brand), '') AS product_brand,
    NULLIF(TRIM(product_material), '') AS product_material,
    NULLIF(TRIM(product_description), '') AS product_description,
    product_rating,
    product_reviews,
    product_release_date,
    product_expiry_date,
    NULLIF(TRIM(supplier_name), '') AS supplier_name,
    NULLIF(TRIM(supplier_contact), '') AS supplier_contact,
    NULLIF(TRIM(supplier_email), '') AS supplier_email,
    NULLIF(TRIM(supplier_phone), '') AS supplier_phone,
    NULLIF(TRIM(supplier_address), '') AS supplier_address,
    NULLIF(TRIM(supplier_city), '') AS supplier_city,
    NULLIF(TRIM(supplier_country), '') AS supplier_country
FROM mock_data;

INSERT INTO dim_country (country_name)
SELECT country_name
FROM (
    SELECT customer_country AS country_name FROM normalized_mock_data
    UNION
    SELECT seller_country FROM normalized_mock_data
    UNION
    SELECT store_country FROM normalized_mock_data
    UNION
    SELECT supplier_country FROM normalized_mock_data
) countries
WHERE country_name IS NOT NULL;

INSERT INTO dim_postal_code (postal_code, country_key)
SELECT DISTINCT source.postal_code, country.country_key
FROM (
    SELECT customer_postal_code AS postal_code, customer_country AS country_name FROM normalized_mock_data
    UNION
    SELECT seller_postal_code, seller_country FROM normalized_mock_data
) source
LEFT JOIN dim_country country ON country.country_name = source.country_name
WHERE source.postal_code IS NOT NULL
   OR country.country_key IS NOT NULL;

INSERT INTO dim_location (address_line, city, state, country_key)
SELECT DISTINCT source.address_line, source.city, source.state, country.country_key
FROM (
    SELECT store_location AS address_line, store_city AS city, store_state AS state, store_country AS country_name
    FROM normalized_mock_data
    UNION
    SELECT supplier_address, supplier_city, NULL::VARCHAR(100), supplier_country
    FROM normalized_mock_data
) source
LEFT JOIN dim_country country ON country.country_name = source.country_name
WHERE source.address_line IS NOT NULL
   OR source.city IS NOT NULL
   OR source.state IS NOT NULL
   OR country.country_key IS NOT NULL;

INSERT INTO dim_pet_type (pet_type_name)
SELECT DISTINCT customer_pet_type
FROM normalized_mock_data
WHERE customer_pet_type IS NOT NULL;

INSERT INTO dim_pet_breed (pet_breed_name, pet_type_key)
SELECT DISTINCT source.customer_pet_breed, pet_type.pet_type_key
FROM normalized_mock_data source
LEFT JOIN dim_pet_type pet_type
    ON pet_type.pet_type_name = source.customer_pet_type
WHERE source.customer_pet_breed IS NOT NULL
   OR pet_type.pet_type_key IS NOT NULL;

INSERT INTO dim_pet (pet_name, pet_breed_key)
SELECT DISTINCT source.customer_pet_name, pet_breed.pet_breed_key
FROM normalized_mock_data source
LEFT JOIN dim_pet_type pet_type
    ON pet_type.pet_type_name = source.customer_pet_type
LEFT JOIN dim_pet_breed pet_breed
    ON pet_breed.pet_breed_name IS NOT DISTINCT FROM source.customer_pet_breed
   AND pet_breed.pet_type_key IS NOT DISTINCT FROM pet_type.pet_type_key
WHERE source.customer_pet_name IS NOT NULL
   OR pet_breed.pet_breed_key IS NOT NULL;

INSERT INTO dim_pet_category (pet_category_name)
SELECT DISTINCT pet_category
FROM normalized_mock_data
WHERE pet_category IS NOT NULL;

INSERT INTO dim_product_category (product_category_name)
SELECT DISTINCT product_category
FROM normalized_mock_data
WHERE product_category IS NOT NULL;

INSERT INTO dim_product_brand (product_brand_name)
SELECT DISTINCT product_brand
FROM normalized_mock_data
WHERE product_brand IS NOT NULL;

INSERT INTO dim_product_material (product_material_name)
SELECT DISTINCT product_material
FROM normalized_mock_data
WHERE product_material IS NOT NULL;

INSERT INTO dim_product_color (product_color_name)
SELECT DISTINCT product_color
FROM normalized_mock_data
WHERE product_color IS NOT NULL;

INSERT INTO dim_product_size (product_size_name)
SELECT DISTINCT product_size
FROM normalized_mock_data
WHERE product_size IS NOT NULL;

INSERT INTO dim_supplier (
    supplier_name,
    supplier_contact,
    supplier_email,
    supplier_phone,
    location_key
)
SELECT DISTINCT
    source.supplier_name,
    source.supplier_contact,
    source.supplier_email,
    source.supplier_phone,
    location.location_key
FROM normalized_mock_data source
LEFT JOIN dim_country country
    ON country.country_name = source.supplier_country
LEFT JOIN dim_location location
    ON location.address_line IS NOT DISTINCT FROM source.supplier_address
   AND location.city IS NOT DISTINCT FROM source.supplier_city
   AND location.state IS NULL
   AND location.country_key IS NOT DISTINCT FROM country.country_key
WHERE source.supplier_name IS NOT NULL
   OR source.supplier_contact IS NOT NULL
   OR source.supplier_email IS NOT NULL
   OR source.supplier_phone IS NOT NULL
   OR location.location_key IS NOT NULL;

INSERT INTO dim_product (
    source_product_id,
    product_name,
    product_category_key,
    pet_category_key,
    product_brand_key,
    product_material_key,
    product_color_key,
    product_size_key,
    supplier_key,
    product_weight,
    product_description,
    product_rating,
    product_reviews,
    product_release_date,
    product_expiry_date
)
SELECT DISTINCT
    source.sale_product_id,
    source.product_name,
    product_category.product_category_key,
    pet_category.pet_category_key,
    product_brand.product_brand_key,
    product_material.product_material_key,
    product_color.product_color_key,
    product_size.product_size_key,
    supplier.supplier_key,
    source.product_weight,
    source.product_description,
    source.product_rating,
    source.product_reviews,
    source.product_release_date,
    source.product_expiry_date
FROM normalized_mock_data source
LEFT JOIN dim_product_category product_category
    ON product_category.product_category_name = source.product_category
LEFT JOIN dim_pet_category pet_category
    ON pet_category.pet_category_name = source.pet_category
LEFT JOIN dim_product_brand product_brand
    ON product_brand.product_brand_name = source.product_brand
LEFT JOIN dim_product_material product_material
    ON product_material.product_material_name = source.product_material
LEFT JOIN dim_product_color product_color
    ON product_color.product_color_name = source.product_color
LEFT JOIN dim_product_size product_size
    ON product_size.product_size_name = source.product_size
LEFT JOIN dim_country supplier_country
    ON supplier_country.country_name = source.supplier_country
LEFT JOIN dim_location supplier_location
    ON supplier_location.address_line IS NOT DISTINCT FROM source.supplier_address
   AND supplier_location.city IS NOT DISTINCT FROM source.supplier_city
   AND supplier_location.state IS NULL
   AND supplier_location.country_key IS NOT DISTINCT FROM supplier_country.country_key
LEFT JOIN dim_supplier supplier
    ON supplier.supplier_name IS NOT DISTINCT FROM source.supplier_name
   AND supplier.supplier_contact IS NOT DISTINCT FROM source.supplier_contact
   AND supplier.supplier_email IS NOT DISTINCT FROM source.supplier_email
   AND supplier.supplier_phone IS NOT DISTINCT FROM source.supplier_phone
   AND supplier.location_key IS NOT DISTINCT FROM supplier_location.location_key;

INSERT INTO dim_customer (
    source_customer_id,
    first_name,
    last_name,
    age,
    email,
    postal_code_key,
    pet_key
)
SELECT DISTINCT
    source.sale_customer_id,
    source.customer_first_name,
    source.customer_last_name,
    source.customer_age,
    source.customer_email,
    postal_code.postal_code_key,
    pet.pet_key
FROM normalized_mock_data source
LEFT JOIN dim_country country
    ON country.country_name = source.customer_country
LEFT JOIN dim_postal_code postal_code
    ON postal_code.postal_code IS NOT DISTINCT FROM source.customer_postal_code
   AND postal_code.country_key IS NOT DISTINCT FROM country.country_key
LEFT JOIN dim_pet_type pet_type
    ON pet_type.pet_type_name = source.customer_pet_type
LEFT JOIN dim_pet_breed pet_breed
    ON pet_breed.pet_breed_name IS NOT DISTINCT FROM source.customer_pet_breed
   AND pet_breed.pet_type_key IS NOT DISTINCT FROM pet_type.pet_type_key
LEFT JOIN dim_pet pet
    ON pet.pet_name IS NOT DISTINCT FROM source.customer_pet_name
   AND pet.pet_breed_key IS NOT DISTINCT FROM pet_breed.pet_breed_key;

INSERT INTO dim_seller (
    source_seller_id,
    first_name,
    last_name,
    email,
    postal_code_key
)
SELECT DISTINCT
    source.sale_seller_id,
    source.seller_first_name,
    source.seller_last_name,
    source.seller_email,
    postal_code.postal_code_key
FROM normalized_mock_data source
LEFT JOIN dim_country country
    ON country.country_name = source.seller_country
LEFT JOIN dim_postal_code postal_code
    ON postal_code.postal_code IS NOT DISTINCT FROM source.seller_postal_code
   AND postal_code.country_key IS NOT DISTINCT FROM country.country_key;

INSERT INTO dim_store (
    store_name,
    store_phone,
    store_email,
    location_key
)
SELECT DISTINCT
    source.store_name,
    source.store_phone,
    source.store_email,
    location.location_key
FROM normalized_mock_data source
LEFT JOIN dim_country country
    ON country.country_name = source.store_country
LEFT JOIN dim_location location
    ON location.address_line IS NOT DISTINCT FROM source.store_location
   AND location.city IS NOT DISTINCT FROM source.store_city
   AND location.state IS NOT DISTINCT FROM source.store_state
   AND location.country_key IS NOT DISTINCT FROM country.country_key;

INSERT INTO dim_date (
    date_key,
    date_value,
    day_of_month,
    month_number,
    month_name,
    quarter_number,
    year_number
)
SELECT DISTINCT
    TO_CHAR(sale_date, 'YYYYMMDD')::INTEGER AS date_key,
    sale_date,
    EXTRACT(DAY FROM sale_date)::SMALLINT AS day_of_month,
    EXTRACT(MONTH FROM sale_date)::SMALLINT AS month_number,
    TRIM(TO_CHAR(sale_date, 'Month')) AS month_name,
    EXTRACT(QUARTER FROM sale_date)::SMALLINT AS quarter_number,
    EXTRACT(YEAR FROM sale_date)::SMALLINT AS year_number
FROM normalized_mock_data
WHERE sale_date IS NOT NULL;

INSERT INTO fact_sales (
    date_key,
    customer_key,
    seller_key,
    product_key,
    store_key,
    source_sale_id,
    source_customer_id,
    source_seller_id,
    source_product_id,
    sale_quantity,
    sale_total_price,
    product_price,
    product_quantity
)
SELECT
    date_dim.date_key,
    customer.customer_key,
    seller.seller_key,
    product.product_key,
    store.store_key,
    source.id,
    source.sale_customer_id,
    source.sale_seller_id,
    source.sale_product_id,
    source.sale_quantity,
    source.sale_total_price,
    source.product_price,
    source.product_quantity
FROM normalized_mock_data source
LEFT JOIN dim_date date_dim
    ON date_dim.date_value = source.sale_date
LEFT JOIN dim_country customer_country
    ON customer_country.country_name = source.customer_country
LEFT JOIN dim_postal_code customer_postal_code
    ON customer_postal_code.postal_code IS NOT DISTINCT FROM source.customer_postal_code
   AND customer_postal_code.country_key IS NOT DISTINCT FROM customer_country.country_key
LEFT JOIN dim_pet_type pet_type
    ON pet_type.pet_type_name = source.customer_pet_type
LEFT JOIN dim_pet_breed pet_breed
    ON pet_breed.pet_breed_name IS NOT DISTINCT FROM source.customer_pet_breed
   AND pet_breed.pet_type_key IS NOT DISTINCT FROM pet_type.pet_type_key
LEFT JOIN dim_pet pet
    ON pet.pet_name IS NOT DISTINCT FROM source.customer_pet_name
   AND pet.pet_breed_key IS NOT DISTINCT FROM pet_breed.pet_breed_key
LEFT JOIN dim_customer customer
    ON customer.source_customer_id IS NOT DISTINCT FROM source.sale_customer_id
   AND customer.first_name IS NOT DISTINCT FROM source.customer_first_name
   AND customer.last_name IS NOT DISTINCT FROM source.customer_last_name
   AND customer.age IS NOT DISTINCT FROM source.customer_age
   AND customer.email IS NOT DISTINCT FROM source.customer_email
   AND customer.postal_code_key IS NOT DISTINCT FROM customer_postal_code.postal_code_key
   AND customer.pet_key IS NOT DISTINCT FROM pet.pet_key
LEFT JOIN dim_country seller_country
    ON seller_country.country_name = source.seller_country
LEFT JOIN dim_postal_code seller_postal_code
    ON seller_postal_code.postal_code IS NOT DISTINCT FROM source.seller_postal_code
   AND seller_postal_code.country_key IS NOT DISTINCT FROM seller_country.country_key
LEFT JOIN dim_seller seller
    ON seller.source_seller_id IS NOT DISTINCT FROM source.sale_seller_id
   AND seller.first_name IS NOT DISTINCT FROM source.seller_first_name
   AND seller.last_name IS NOT DISTINCT FROM source.seller_last_name
   AND seller.email IS NOT DISTINCT FROM source.seller_email
   AND seller.postal_code_key IS NOT DISTINCT FROM seller_postal_code.postal_code_key
LEFT JOIN dim_country store_country
    ON store_country.country_name = source.store_country
LEFT JOIN dim_location store_location
    ON store_location.address_line IS NOT DISTINCT FROM source.store_location
   AND store_location.city IS NOT DISTINCT FROM source.store_city
   AND store_location.state IS NOT DISTINCT FROM source.store_state
   AND store_location.country_key IS NOT DISTINCT FROM store_country.country_key
LEFT JOIN dim_store store
    ON store.store_name IS NOT DISTINCT FROM source.store_name
   AND store.store_phone IS NOT DISTINCT FROM source.store_phone
   AND store.store_email IS NOT DISTINCT FROM source.store_email
   AND store.location_key IS NOT DISTINCT FROM store_location.location_key
LEFT JOIN dim_product_category product_category
    ON product_category.product_category_name = source.product_category
LEFT JOIN dim_pet_category pet_category
    ON pet_category.pet_category_name = source.pet_category
LEFT JOIN dim_product_brand product_brand
    ON product_brand.product_brand_name = source.product_brand
LEFT JOIN dim_product_material product_material
    ON product_material.product_material_name = source.product_material
LEFT JOIN dim_product_color product_color
    ON product_color.product_color_name = source.product_color
LEFT JOIN dim_product_size product_size
    ON product_size.product_size_name = source.product_size
LEFT JOIN dim_country supplier_country
    ON supplier_country.country_name = source.supplier_country
LEFT JOIN dim_location supplier_location
    ON supplier_location.address_line IS NOT DISTINCT FROM source.supplier_address
   AND supplier_location.city IS NOT DISTINCT FROM source.supplier_city
   AND supplier_location.state IS NULL
   AND supplier_location.country_key IS NOT DISTINCT FROM supplier_country.country_key
LEFT JOIN dim_supplier supplier
    ON supplier.supplier_name IS NOT DISTINCT FROM source.supplier_name
   AND supplier.supplier_contact IS NOT DISTINCT FROM source.supplier_contact
   AND supplier.supplier_email IS NOT DISTINCT FROM source.supplier_email
   AND supplier.supplier_phone IS NOT DISTINCT FROM source.supplier_phone
   AND supplier.location_key IS NOT DISTINCT FROM supplier_location.location_key
LEFT JOIN dim_product product
    ON product.source_product_id IS NOT DISTINCT FROM source.sale_product_id
   AND product.product_name IS NOT DISTINCT FROM source.product_name
   AND product.product_category_key IS NOT DISTINCT FROM product_category.product_category_key
   AND product.pet_category_key IS NOT DISTINCT FROM pet_category.pet_category_key
   AND product.product_brand_key IS NOT DISTINCT FROM product_brand.product_brand_key
   AND product.product_material_key IS NOT DISTINCT FROM product_material.product_material_key
   AND product.product_color_key IS NOT DISTINCT FROM product_color.product_color_key
   AND product.product_size_key IS NOT DISTINCT FROM product_size.product_size_key
   AND product.supplier_key IS NOT DISTINCT FROM supplier.supplier_key
   AND product.product_weight IS NOT DISTINCT FROM source.product_weight
   AND product.product_description IS NOT DISTINCT FROM source.product_description
   AND product.product_rating IS NOT DISTINCT FROM source.product_rating
   AND product.product_reviews IS NOT DISTINCT FROM source.product_reviews
   AND product.product_release_date IS NOT DISTINCT FROM source.product_release_date
   AND product.product_expiry_date IS NOT DISTINCT FROM source.product_expiry_date;

DROP VIEW normalized_mock_data;
