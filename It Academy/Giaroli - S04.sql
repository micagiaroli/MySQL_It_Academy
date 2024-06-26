#Creamos base de datos
CREATE DATABASE transactionsT4;
USE transactionsT4;

#Creamos tablas
CREATE TABLE companies (
	company_id VARCHAR(8) PRIMARY KEY,
    company_name VARCHAR (255),
    phone VARCHAR (50),
    email VARCHAR (50),
    country VARCHAR (50),
    website VARCHAR (50)
    );


CREATE TABLE credit_cards (
	id VARCHAR (10) PRIMARY KEY,
    user_id VARCHAR (10),
    iban VARCHAR (50),
    pan VARCHAR (50),
    pin VARCHAR (4),
    cvv VARCHAR (3),
    track1 VARCHAR (50),
    track2 VARCHAR (50),
    expiring_date VARCHAR (10)
    );

#Creamos la tabla users_all para poder unir las tres tablas de usuarios en una sola
CREATE TABLE users_all (
	id INTEGER PRIMARY KEY,
    name VARCHAR (50),
    surname VARCHAR (50),
    phone VARCHAR (50),
    email VARCHAR (50),
    birth_date VARCHAR (50),
    country VARCHAR (50),
    city VARCHAR (50),
    postal_code VARCHAR (10),
    address VARCHAR (50)
    );
    
CREATE TABLE transactions (
	id VARCHAR (50) PRIMARY KEY,
    card_id VARCHAR (10),
    business_id VARCHAR(8),
    timestamp VARCHAR (50),
    amount DECIMAL (10,2),
    declined BOOLEAN,
    products_ids VARCHAR (50),
    user_id INT,
    lat VARCHAR (50),
    longitude VARCHAR (50),
    FOREIGN KEY (card_id) REFERENCES credit_cards(id),
    FOREIGN KEY (business_id) REFERENCES companies(company_id),
    FOREIGN KEY (user_id) REFERENCES users_all(id)
    );
    
# Insertamos los datos en users_all y en transactions utilizando la función "Table Date Import Wizard" 
### CORREGIDO: y en las tablas companies y credit_cards insertamos datos con código  
#insertamos los datos en la tabla companies sin wizard
LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/companies.csv'
INTO TABLE companies
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 ROWS
(company_id,company_name,phone,email,country,website);

#insertamos los datos en la tabla credit_cards sin wizard
LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/credit_cards.csv'
INTO TABLE credit_cards
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 ROWS
(id,user_id,iban,pan,pin,cvv,track1,track2,expiring_date);

#Corroboramos la carga de datos
SELECT * FROM companies;
SELECT * FROM credit_cards;
SELECT * FROM users_all;
SELECT * FROM transactions;

#Nivell 1
##N1. Exercici 1: subconsulta que mostri tots els usuaris amb més de 30 transaccions utilitzant almenys 2 taules.
##CORREGIDO##
SELECT u.id, u.name, u.surname, COUNT(t.id) AS cant_trans
FROM users_all AS u
JOIN transactions AS t
ON u.id = t.user_id
GROUP BY u.id, u.name, u.surname
HAVING cant_trans >= 30;
    

##N1. Exercici 2: Mostra la mitjana de la suma de transaccions per IBAN de les targetes de crèdit en la companyia Donec Ltd. utilitzant almenys 2 taules.
SELECT t.business_id, cc.iban, avg(t.amount) AS mitjana_trans
FROM transactions AS t
JOIN credit_cards AS cc
ON t.card_id=cc.id
JOIN companies AS c 
ON c.company_id = t.business_id
WHERE company_name LIKE 'Donec Ltd%' 
GROUP BY t.business_id, cc.iban;


#Nivell 2: Crea una nova taula que reflecteixi l'estat de les targetes de crèdit basat en si les últimes tres transaccions van ser declinades 
##cambiamos el nombre del campo timestamp por fecha_hora para evitar errores involutarios
SET SQL_SAFE_UPDATES = 0;
ALTER TABLE transactions CHANGE timestamp fecha_hora VARCHAR(50);
SET SQL_SAFE_UPDATES = 1;

#damos formato correcto de tipo datetime al campo fecha_hora para poder ordenar por este valor
SET SQL_SAFE_UPDATES = 0;
UPDATE transactions
SET fecha_hora = STR_TO_DATE(fecha_hora, '%d/%m/%Y %H:%i');
SET SQL_SAFE_UPDATES = 1;

DESCRIBE transactions;
ALTER TABLE transactions MODIFY fecha_hora DATETIME;
DESCRIBE transactions;

#---------------------------------------------------------------------------------

#Creamos la tabla
##CORRREGIDO: simplificamos la tabla
CREATE TABLE card_status (
WITH t1 AS (SELECT card_id,
				declined,
				ROW_NUMBER() OVER (PARTITION BY card_id ORDER BY fecha_hora DESC) AS row_num
			FROM transactions)
SELECT card_id,
       CASE
        WHEN SUM(declined) = 3 THEN 'Inactiva'
        ELSE 'Activa'
    END AS Status
FROM t1
WHERE row_num <= 3
GROUP BY card_id);

#Corroboramos la creación de la tabla
SELECT * FROM card_status;


#----------------------------PRUEBA PARA CORROBORAR QUE CASE FUNCIONA---------------------------
#Cambiaremos a declined los datos de una tarjeta para que cumpla las condiciones de rechazo y verificar CASE
DROP TABLE card_status;

#averiguamos el id de las últimas tres transacciones de la compañía con card_id CcU-2938 para cambiarlas a declined = 1
SELECT * FROM transactions
WHERE card_id LIKE '%2938'
ORDER BY fecha_hora DESC;

#Hacemos que las últimas tres transacciones sean declinadas
SET SQL_SAFE_UPDATES = 0;
UPDATE transactions
SET declined = true
WHERE id IN ('AD85A78A-8829-5746-93A0-8B7A792EBC18', 'F1A598A2-86C5-50A9-F1CE-FB1D69866C39', '55166D02-D74C-6A63-6C54-8678467649B4');

#Creamos la tabla de nuevo para corroborar que funciona correctamente:
CREATE TABLE card_status (
WITH t1 AS (SELECT card_id,
				declined,
				ROW_NUMBER() OVER (PARTITION BY card_id ORDER BY fecha_hora DESC) AS row_num
			FROM transactions)
SELECT card_id,
       CASE
        WHEN SUM(declined) = 3 THEN 'Inactiva'
        ELSE 'Activa'
    END AS Status
FROM t1
WHERE row_num <= 3
GROUP BY card_id);

#corroboramos:
SELECT * FROM card_status;

#volvemos a dejar los datos de la tabla transaccion como estaban originalmente, eliminamos
UPDATE transactions
SET declined = false 
WHERE id IN ('AD85A78A-8829-5746-93A0-8B7A792EBC18', 'F1A598A2-86C5-50A9-F1CE-FB1D69866C39', '55166D02-D74C-6A63-6C54-8678467649B4');

SET SQL_SAFE_UPDATES = 1;

#corroboramos:
SELECT * FROM card_status;

#------------------------------------------ACABADA LA COMPROBACIÓN DEL CÓDIGO CASE------------------

##N2: Exercici 1: Quantes targetes estan actives?

SELECT COUNT(distinct card_id)
FROM card_status
WHERE status = 'Activa';


##Nivell 3
## Primero creamos la tabla Products e importamos los datos con wizard
CREATE TABLE products (
	id VARCHAR(50) PRIMARY KEY,
    product_name VARCHAR(50),
    price VARCHAR(50),
    colour VARCHAR(50),
    weight VARCHAR(50),
    warehouse_id VARCHAR(50));
 
#comprobamos la creación de la tabla
SELECT * FROM products;

#Luego creamos la siguiente tabla puente para evitar la relación N-N entre las tablas Products y Transactions
CREATE TABLE products_per_transactions (
	id_transaction VARCHAR(50),
    id_product VARCHAR(50));

#Comprobamos la creación de la tabla
SELECT * FROM products_per_transactions;


#Insertamos los datos en la tabla puente a partir de campos que ya existen en la tabla Transactions
INSERT INTO products_per_transactions (id_transaction, id_product)
SELECT t.id AS id_transaction,
       SUBSTRING_INDEX(SUBSTRING_INDEX(t.products_ids, ',', numbers.n), ',', -1) AS id_product #aqui separamos cada id de producto del campo products_ids
FROM transactions t
JOIN (
    SELECT ROW_NUMBER() OVER () AS n #aqui generamos una secuencia de números para cada fila de la tabla t
    FROM transactions
    CROSS JOIN (SELECT 0 AS n UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9) AS numbers
     #aqui hacemos una cross join con una tabla de 10 filas para asegurarnos que habrá sitio para al menos 10 códigos de producto por cada transacción 
) AS numbers 
ON numbers.n <= LENGTH(t.products_ids) - LENGTH(REPLACE(t.products_ids, ',', '')) + 1; #aqui calculamos la cantidad de comas que hay en cada campo y le sumamos uno, para obtener la cantidad de productos totales por campo

#Comprobamos la inserción correcta de los datos
SELECT * FROM products_per_transactions;

#descubrimos que hay espacios en blanco en el campo, los eliminamos con TRIM
select length(id_product)
from products_per_transactions;

SET SQL_SAFE_UPDATES = 0;
UPDATE products_per_transactions
SET id_product = TRIM(id_product);
SET SQL_SAFE_UPDATES = 1;

#Ahora añadimos las FK
ALTER TABLE products_per_transactions
ADD CONSTRAINT FOREIGN KEY (id_transaction) REFERENCES transactions(id);

### Creamos un índice porque sino da error al querer crear la FK
CREATE INDEX idx_products_id ON products(id);
ALTER TABLE products_per_transactions
ADD CONSTRAINT FOREIGN KEY (id_product) REFERENCES products(id);


#N3: E1: Necessitem conèixer el nombre de vegades que s'ha venut cada producte
SELECT id_product, COUNT(distinct id_transaction) 
FROM products_per_transactions ppt
JOIN transactions t
ON ppt.id_transaction=t.id
WHERE t.declined = 0
GROUP BY id_product;


#Para que el resultado pueda salir ordenado por id de producto, cambiaremos el tipo de dato de varchar a int, pero como es FK debemos desactivarlas temporalmente
SHOW CREATE TABLE products_per_transactions;
ALTER TABLE products_per_transactions
DROP FOREIGN KEY `products_per_transactions_ibfk_3`;

ALTER TABLE products_per_transactions CHANGE id_product id_product INT;
ALTER TABLE products CHANGE id id INT;

ALTER TABLE products_per_transactions
ADD CONSTRAINT FOREIGN KEY (id_product) REFERENCES products(id);

#corremos nuevamente la consulta para obtener el listado de productos vendidos
SELECT id_product, COUNT(distinct id_transaction) 
FROM products_per_transactions ppt
JOIN transactions t
ON ppt.id_transaction=t.id
WHERE t.declined = 0
GROUP BY id_product;

#si también quisiéramos que salgan los productos que no se han vendido la consulta sería la siguiente:
SELECT p.id AS id_producto, cant_transacc
FROM products p
LEFT JOIN ( SELECT id_product, COUNT(distinct id_transaction) AS cant_transacc
			FROM products_per_transactions ppt
			JOIN transactions t
			ON ppt.id_transaction=t.id
			WHERE t.declined = 0
			GROUP BY id_product) cant_vendida
ON cant_vendida.id_product=p.id;









