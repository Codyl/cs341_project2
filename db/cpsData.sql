--all tables: warehouses, bins, counts, countHistory, items, itemsList, items2Bins, PendingOrders
--warehouse separate each table to kentucky and idaho

--We INSERT our warehouses for Idaho and Kentucky at the bottom
--Warehouses determine the rows used in other tables ie. bins
--**********************************TO RUN WHOLE FILE: heroku pg:psql -f db/cpsData.sql
DROP TABLE IF EXISTS warehouses cascade;
CREATE TABLE warehouses (
  warehouse_id SERIAL PRIMARY KEY,
  name varchar(100),
  max_shelf_height int,
  max_row_length int
);
ALTER TABLE warehouses ALTER COLUMN max_row_length SET DEFAULT 0;
ALTER TABLE warehouses ALTER COLUMN max_shelf_height SET DEFAULT 0;

--Bins are where items are stored in the warehouse
--We will set these at the bottom
DROP TABLE IF EXISTS bins cascade;
CREATE TABLE bins (
  bin_id serial8 PRIMARY KEY,
  name varchar(12),
  is_pick_bin boolean,
  area varchar(1) NOT NULL,
  row int NOT NULL,
  rack int NOT NULL,
  shelf_lvl int NOT NULL,
  warehouse_id int NOT NULL,
  CHECK (area = 'A' OR area = 'B'),
  CHECK (row > 0 AND row <= 15),
  CHECK (rack > 0 AND rack < 32),
  CHECK (shelf_lvl > 0 AND shelf_lvl < 8),
  CONSTRAINT fk_warehouse_id FOREIGN KEY (warehouse_id) REFERENCES warehouses (warehouse_id)
);

DROP TABLE IF EXISTS items cascade;
CREATE TABLE items (
  item_id SERIAL PRIMARY KEY,
  name varchar(8) NOT NULL UNIQUE,
  cost float NOT NULL,
  description varchar,
  case_qty int NOT NULL,
  case_lyr int NOT NULL,
  case_plt int NOT NULL
);

DROP TABLE IF EXISTS counts cascade;
CREATE TABLE counts (
  counts_id SERIAL PRIMARY KEY,
  item_id int NOT NULL,
  count_date DATE NOT NULL,
  qty_start int NOT NULL,
  qty_end int NOT NULL,
  exceedsLimit boolean NOT NULL,
  warehouse_id int NOT NULL,
  CONSTRAINT fk_item_id FOREIGN KEY (item_id) REFERENCES items (item_id),
  CONSTRAINT fk_warehouse_id FOREIGN KEY (warehouse_id) REFERENCES warehouses (warehouse_id)
);

DROP TABLE IF EXISTS countHistory cascade;
CREATE table countHistory(
  id SERIAL PRIMARY KEY,
  counts_id int NOT NULL,
  item_id int NOT NULL,
  warehouse_id int NOT NULL,
  CONSTRAINT fk_count_id FOREIGN KEY (counts_id) REFERENCES counts (counts_id),
  CONSTRAINT fk_warehouse_id FOREIGN KEY (warehouse_id) REFERENCES warehouses (warehouse_id),
  CONSTRAINT fk_item_id FOREIGN KEY (item_id) REFERENCES items (item_id)
);

DROP TABLE IF EXISTS itemBins cascade;
CREATE TABLE itemBins(
  itemsBins_id SERIAL PRIMARY KEY,
  item_id int NOT NULL,
  bin_id int NOT NULL,
  quantity int NOT NULL,
  warehouse_id int NOT NULL,
  CONSTRAINT fk_bin_id FOREIGN KEY (bin_id) REFERENCES bins (bin_id),
  CONSTRAINT fk_item_id FOREIGN KEY (item_id) REFERENCES items (item_id),
  CONSTRAINT fk_warehouse_id FOREIGN KEY (warehouse_id) REFERENCES warehouses (warehouse_id)
);
ALTER TABLE itemBins ALTER COLUMN quantity SET DEFAULT 0;

DROP TABLE IF EXISTS itemsWarehouse cascade;
CREATE TABLE itemsWarehouse(
    itemsWarehouse_id SERIAL PRIMARY KEY,
    item_id int NOT NULL,
    warehouse_id int NOT NULL,
    CONSTRAINT fk_item_id FOREIGN KEY (item_id) REFERENCES items (item_id),
    CONSTRAINT fk_warehouse_id FOREIGN KEY (warehouse_id) REFERENCES warehouses (warehouse_id)
);

DROP TABLE IF EXISTS inventory cascade;
CREATE TABLE inventory(
    inventory_id SERIAL PRIMARY KEY,
    item_id int NOT NULL,
    itemsWarehouse_id int,
    count_history_id int,
    qoh int,
    qty_avail int,
    warehouse_id int,
    CONSTRAINT fk_item_id FOREIGN KEY (item_id) REFERENCES items (item_id),
    CONSTRAINT fk_warehouse_id FOREIGN KEY (warehouse_id) REFERENCES warehouses (warehouse_id),
    CONSTRAINT fk_itemsWarehouse_id FOREIGN KEY (itemsWarehouse_id) REFERENCES itemsWarehouse (itemsWarehouse_id)
);
ALTER TABLE inventory ALTER COLUMN qoh SET DEFAULT 0;
ALTER TABLE inventory ALTER COLUMN qty_avail SET DEFAULT 0;

--Order related tables start here
DROP TABLE IF EXISTS customers cascade;
CREATE TABLE customers(
    customer_id SERIAL PRIMARY KEY,
    name varchar NOT NULL,
    email varchar NOT NULL,
    phone int,
    company varchar NOT NULL,
    str_address varchar NOT NULL,
    country varchar NOT NULL,
    state varchar NOT NULL,
    zip int NOT NULL,
    city varchar NOT NULL
);
-- Statuses: waiting, fully pulled, part pulled, combined, in truck, arrived, accepted, on hold, returned
DROP TABLE IF EXISTS orders cascade;
CREATE TABLE orders(
    order_id SERIAL PRIMARY KEY,
    customer_id int NOT NULL,
    status varchar DEFAULT 'waiting',
    priority int DEFAULT 1,
    truck varchar DEFAULT 'YRC',
    start_date DATE DEFAULT CURRENT_DATE,
    end_date DATE DEFAULT CURRENT_DATE+3,
    CONSTRAINT fk_customer_id FOREIGN KEY (customer_id) REFERENCES customers (customer_id)
);

--status codes: waiting,pulled, hold, returned
DROP TABLE IF EXISTS itemsOrders cascade;
CREATE TABLE itemsOrders(
    items_orders_id SERIAL PRIMARY KEY,
    item_id int NOT NULL,
    order_id int NOT NULL,
    status varchar DEFAULT 'waiting',
    pc_qty int NOT NULL,
    cs_qty int NOT NULL,
    plt_qty int NOT NULL,
    warehouse_id int NOT NULL,
    CONSTRAINT fk_warehouse_id FOREIGN KEY (warehouse_id) REFERENCES warehouses (warehouse_id),
    CONSTRAINT fk_item_id FOREIGN KEY (item_id) REFERENCES items (item_id),
    CONSTRAINT fk_order_id FOREIGN KEY (order_id) REFERENCES orders (order_id)
);
ALTER TABLE itemsOrders ALTER COLUMN pc_qty SET DEFAULT 0;
ALTER TABLE itemsOrders ALTER COLUMN cs_qty SET DEFAULT 0;
ALTER TABLE itemsOrders ALTER COLUMN plt_qty SET DEFAULT 0;
ALTER TABLE itemsOrders ALTER COLUMN status SET DEFAULT 'waiting';


DROP TABLE IF EXISTS userTable cascade;
CREATE TABLE userTable (
  user_id SERIAL PRIMARY KEY,
  username varchar NOT NULL,
  password_hash varchar NOT NULL,
  warehouse_id int NOT NULL,
  counts_complete int
);

INSERT INTO warehouses (name)
VALUES ('Kentucky'),('Idaho');

INSERT INTO items(name, cost, case_qty, case_lyr, case_plt)
VALUES 
('J071CL', 0.34, 400 , 4 , 16),
('G841AM', 0.91, 80  , 10, 35),
('DP600' , 0.51, 1200, 7 , 35),
('J115'  , 0.91, 40  , 4 , 16),
('G040'  , 1.50, 12  , 20, 150),
('M653BK', 0.21, 180 , 5 , 28),
('S400'  , 0.41, 1000, 7 , 35),
('J101'  , 0.95, 100 , 7 , 20),
('M654BK', 0.50, 180 , 5 , 35),
('M653WH', 0.55, 180 , 5 , 35),
('B500'  , 2.50, 40  , 2 , 16);



INSERT INTO bins (warehouse_id,is_pick_bin, area, row, rack, shelf_lvl)
VALUES 
(1,false, 'A', 1, 1, 1),
(1,false,  'A', 1, 1, 2),
(1,false, 'A', 1, 1, 3),
(1,false, 'A', 1, 2, 1),
(1,false, 'A', 1, 2, 2),
(1,false, 'A', 1, 2, 3),
(1,false, 'B', 1, 1, 1),
(2,false, 'B', 1, 2, 1),
(2,false, 'A', 2, 1, 1),
(2,false, 'A', 2, 1, 2),
(2,false, 'A', 15, 1, 2),
(2,false, 'A', 15, 1, 3),
(1,true, 'A', 3, 3, 1),
(1,true, 'A', 3, 3, 2),
(1,true, 'A', 3, 3, 3),
(1,true, 'A', 3, 1, 1),
(1,true, 'A', 3, 1, 2),
(1,true, 'A', 1, 2, 3);

UPDATE bins
SET name = concat(area, ':', row, ':', rack, ':', shelf_lvl);


--Project 2 inserts
INSERT INTO customers 
(customer_id, name, email, phone, company, str_address, country, state, zip, city)
VALUES
(1,'containerman', 'jimmy@hotmail.com', 1035559999, 'ContainerMen', '140 Man Rd', 'United States', 'Virginia', 33204, 'Manville'),
(2,'mike', 'mikebun@outlook.com', 1035551212, 'Specialty Food Containers', '403 Bloomburg Way', 'United States', 'North Dakota', 88493, 'Harrison');



INSERT INTO itemBins(item_id, bin_id, quantity, warehouse_id)
VALUES
(1,13,0,1),
(2,14,0,1),
(3,15,0,1),
(4,16,0,1),
(1,1,1000,1),
(2,2,2000,1);

INSERT INTO itemsWarehouse(item_id, warehouse_id)
SELECT item_id, warehouse_id FROM itemBins;

--Insert a row for each item in item table into each warehouse
DELETE FROM inventory;
ALTER SEQUENCE inventory_inventory_id_seq RESTART WITH 1;
INSERT INTO inventory(item_id)
SELECT item_id FROM items;
UPDATE inventory SET warehouse_id = 1;
INSERT INTO inventory(item_id)
SELECT item_id FROM items;
UPDATE inventory SET warehouse_id = 2 WHERE warehouse_id IS NULL;

--Example orders
INSERT into orders(order_id,customer_id,start_date)
VALUES
(1,1,'2020-06-28'),
(2,2,'2020-07-03'),
(3,2,'2020-07-04');
INSERT INTO itemsOrders (items_orders_id,item_id,order_id,pc_qty,cs_qty,plt_qty,warehouse_id)
VALUES
(1,1,1,0  ,4,3,1),
(2,2,1,0  ,1,0,1),
(4,3,3,100,0,4,1),
(5,1,3,0  ,15,0,1),
(6,4,3,155,0,0,1);

-- update orders set status = 'waiting';
-- update itemsorders set status = 'waiting';