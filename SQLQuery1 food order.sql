use master;
go
drop database if exists FoodOrder;

create database FoodOrder;

go
CREATE LOGIN [Operator] WITH PASSWORD=N'123456', DEFAULT_DATABASE=[FoodOrder]
GO
ALTER SERVER ROLE [dbcreator] ADD MEMBER [Operator]
GO

use FoodOrder;
go
CREATE USER [Operator] FOR LOGIN [Operator] WITH DEFAULT_SCHEMA = [dbo]
gO
grant select, insert , update, delete, execute
on schema:: dbo
to [Operator]
go
CREATE TABLE Customers (
    customer_id INT PRIMARY KEY,
    first_name VARCHAR(50),
    last_name VARCHAR(50),
    address VARCHAR(100),
    phone_number VARCHAR(15)
);


CREATE TABLE Orders (
    order_id INT PRIMARY KEY,
    customer_id INT,
    order_date DATE,
    total_amount DECIMAL(10, 2),
    FOREIGN KEY (customer_id) REFERENCES Customers(customer_id)
);


CREATE TABLE Order_Items (
    item_id INT ,
    order_id INT ,
    item_name VARCHAR(100),
    quantity INT,
    price DECIMAL(10, 2),
    FOREIGN KEY (order_id) REFERENCES Orders(order_id),
	Primary key (item_id,order_id)
);


CREATE TABLE Menu_Items (
    item_id INT PRIMARY KEY,
    item_name VARCHAR(100),
    price DECIMAL(10, 2)
);

go

 Insert  into Customers (customer_id, first_name, last_name, address, phone_number)
VALUES (101, 'Jamir', 'Uddin', '123 bayzid', '123-456-7890'),
(102,'Akhas','Roy','124 mongla ,potenga','123-456-7891'),
(103,'Vivek','Roy','125 Shershah,potenga','123-456-7892'),
(104,'Soyed','Miya','126 Oxegen Mor','123-456-7893'),
(105,'Kayum','Miya','127 katalli ,pote','123-456-7894')
;


INSERT INTO Orders (order_id, customer_id, order_date, total_amount)
VALUES (1, 101, '2023-06-01', 25.00),
(2,102,'2023-06-02',20.00),
(3,103,'2023-06-03',25.00),
(4,104,'2023-06-03',20.00)
;


INSERT INTO Order_Items (item_id, order_id, item_name, quantity, price)
VALUES (1, 1, 'Pizza', 2, 10.00),
       (2, 1, 'Burger', 1, 5.00),
	   (2, 2, 'Burger', 1, 5.00),
	   (2, 3, 'Burger', 1, 5.00);


INSERT INTO Menu_Items (item_id, item_name, price)
VALUES (1, 'Pizza', 10.00),
       (2, 'Burger', 5.00),
       (3, 'Fries', 2.00);

go

CREATE VIEW OrderDetails AS
SELECT o.order_id, c.first_name, c.last_name, o.order_date, o.total_amount
FROM Orders o
INNER JOIN Customers c ON o.customer_id = c.customer_id;

go

SELECT o.order_id, c.first_name, c.last_name, m.item_name, oi.quantity
FROM Orders o
INNER JOIN Customers c ON o.customer_id = c.customer_id
INNER JOIN Order_Items oi ON o.order_id = oi.order_id
INNER JOIN Menu_Items m ON oi.item_id = m.item_id;


WITH OrderTotal AS (
    SELECT order_id, SUM(quantity * price) AS total_amount
    FROM Order_Items
    GROUP BY order_id
)
SELECT o.order_id, c.first_name, c.last_name, ot.total_amount
FROM Orders o
INNER JOIN Customers c ON o.customer_id = c.customer_id
INNER JOIN OrderTotal ot ON o.order_id = ot.order_id;

go 

CREATE PROCEDURE InsertOrder
    @customer_id INT,
    @order_date DATE,
    @total_amount DECIMAL(10, 2)
AS
BEGIN
    INSERT INTO Orders (customer_id, order_date, total_amount)
    VALUES (@customer_id, @order_date, @total_amount);
END;

go

CREATE FUNCTION GetTotalQuantity
    (@customer_id INT)
RETURNS INT
AS
BEGIN
    DECLARE @total_quantity INT;
    SELECT @total_quantity = SUM(quantity)
    FROM Order_Items oi
    INNER JOIN Orders o ON oi.order_id = o.order_id
    WHERE o.customer_id = @customer_id;
    RETURN @total_quantity;
END;

go

CREATE TRIGGER UpdateOrderTotal
ON Order_Items
AFTER INSERT, UPDATE
AS
BEGIN
    UPDATE o
    SET total_amount = (SELECT SUM(quantity * price) FROM Order_Items WHERE order_id = o.order_id)
    FROM Orders o
    INNER JOIN inserted i ON o.order_id = i.order_id;
END;

go