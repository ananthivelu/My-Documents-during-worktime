/*Assignment (2B)*/
/*1.1. Insert a row to ‘Employees’ table with following values:
• LastName → Davolio
• FirstName → Nancy
• Title → Sales Representative
• TitleOfCourtesy → Ms.
• BirthDate → 1948-12-08
• HireDate → 1992-05-01 
• Address → 507 - 20th Ave. E. Apt. 2A
• City → Seattle
• Region → WA
• PostalCode → 98122
• Country → USA
• HomePhone → (206) 555-9857
• Extension → 5467
• Notes → Education includes a BA in psychology from Colorado State University in 
1970. She also completed "The Art of the Cold Call." Nancy is a member of Toastmasters 
International.
• ReportsTo → 2
• PhotoPath → http://accweb/emmployees/davolio.bmp*/

CREATE TABLE Employees
INSERT INTO Employees(LastName,FirstName,Title,TitleOfCourtesy,BirthDate,HireDate,Address,City,Region,PostalCode,Country,HomePhone,Extension,Notes,ReportsTo,PhotoPath)
Values('Davolio', 'Nancy', 'Sales Representative', 'Ms.', '1948-12-08', '1992-05-01', '507 - 20th Ave. E. Apt. 2A', 'Seattle', 'WA', '98122', 'USA', '(206) 555-9857', '5467', 'Education includes a BA in psychology from Colorado State University in
1970. She also completed "The Art of the Cold Call." Nancy is a member of Toastmasters
International.', '2', 'http://accweb/emmployees/davolio.bmp');

/*2.2. Insert the data into ‘Customers’ table 
• CustomerID → ALFKI
• CompanyName → Alfreds Futterkiste
• ContactName → Maria Anders
• ContactTitle → Sales Representative
• Address → Obere Str. 57
• City → Berlin
• PostalCode → 12209
• Country → Germany
• Phone → 030-0074321
• Fax → 030-0076545 */

INSERT INTO customers(CustomerID,CompanyName,ContactName,ContactTitle,Address,City,PostalCode,Country,Phone,Fax) 
VALUES('ALFKI', 'Alfreds Futterkiste', 'Maria Anders', 'Sales Representative', 'Obere Str. 57', 'Berlin', '12209', 'Germany', '030-0074321', '030-0076545');
/*3. Inserting multiple rows. Insert the below data into ‘Employees’ table.
LastName FirstName Title TitleOf
courtesy
BirthDate HireDate City
Fuller Andrew Vice President, Sales Dr. 2030-01-01 1992-08-14 Tacoma
Leverling Janet Sales Representative Ms. 1963-08-30 1992-04-01 Kirkland
Peacock Margaret Sales Representative Mrs. 1937-09-19 1993-05-03 Redmond
Buchan Steven Sales Manager Mr. 1955-03-04 1993-10-17 London
Suyama Michael Sales Representative Mr. 1963-07-02 1993-10-17 LondonKing Robert Sales Representative Mr. 1960-05-29 1994-01-02 London
Dodsworth Laura Inside Sales Coordinator Ms. 1958-01-09 1994-03-05 Seattle
Callahan Anne Sales Representative Ms. 1966-01-27 1994-11-15 London
In record 1, birth date is greater than today’s date. Mention the error you receive, then update the 
birthdate to ‘1952-02-19’ and try re-load
*/

UPDATE employees SET BirthDate = '1952-02-19' WHERE EmployeeID = 1;

/*4. Insert one new customer in Customers table with below info
• CustomerID → BONAP
• CompanyName → Bon app'
• ContactName → Laurence Lebihan
• ContactTitle → Owner
• Address → 12, rue des Bouchers
• City → Marseille
• PostalCode → 13008
• Country → France
• Phone →91.24.45.4
• Fax → 91.24.45.41*/

INSERT INTO customers(CustomerID,CompanyName,ContactName,ContactTitle,Address,City,PostalCode,Country,Phone,Fax) VALUES('BONAP', 'Bon app', 'Laurence Lebihan', 'Owner', '12, rue des Bouchers', 'Marseille', '13008', 'France', '91.24.45.4', '91.24.45.41');

/*5. Get the distinct [Contact Title] from ‘Customers’ table*/

SELECT DISTINCT Contact_Title
FROM Customers;

/*6. Get the total number of Employees under each title. (Using GroupBy)*/

SELECT Title , COUNT(*) "Total number of Employees" FROM employees GROUP BY Title;

/*7.Get the list of customers reached more than 15 orders from ‘Orders’ Table (Using Group By,
Having)*/


SELECT CustomerID,COUNT (EmployeeID) "Orders"
FROM Orders GROUP BY CustomerID
HAVING COUNT (CustomerID)>15;

/*8.Oops!! We inserted the incorrect name in ‘Employees’ table where the LastName is 
‘Buchan’. Name must be updated to ‘Buchanan’ using transaction. (Using Begin Tran, 
Commit)*/

select * from employees;
BEGIN
UPDATE employees SET LastName='Buchanan' WHERE FirstName='Steven';
COMMIT;
END;

/*9 Show the details of orders of each customer so far. (Using joins)
Tables: Orders, Customers */

SELECT Orders.OrderId,customers.ContactName FROM Orders
INNER JOIN customers ON
Orders.CustomerID=customers.CustomerId;


/*10.Get the details of all customers those who didn’t place any orders so far. (Using leftjoin)*/

SELECT customers.ContactName FROM customers
LEFT JOIN Orders ON customers.CustomerID=Orders.CustomerID
WHERE Orders.CustomerID IS NULL;

/*11.Get the Product details (from Products Table) of each order (from Order Details Tables) using joins. */

SELECT * FROM Order_Details;
(INSERT INTO Order_Details(OrderID,ProductID,UnitPrice,Quantity,Discount)
VALUES ('10248', '1', 18.00, '3', '25');
INSERT INTO Order_Details(OrderID,ProductID,UnitPrice,Quantity,Discount)
VALUES ('10249', '2', 19.00, '3', '35');
INSERT INTO Order_Details(OrderID,ProductID,UnitPrice,Quantity,Discount)
VALUES ('10250', '3', 10.00, '3', '15');
INSERT INTO Order_Details(OrderID,ProductID,UnitPrice,Quantity,Discount)
VALUES ('10251', '4', 22.00, '3', '25');
INSERT INTO Order_Details(OrderID,ProductID,UnitPrice,Quantity,Discount)
VALUES ('10252', '5', 21.35, '3', '25'));

SELECT Order_Details.OrderID,products.ProductID,products.ProductName,products.SupplierID,products.CategoryID,products.QuantityPerUnit,products.UnitPrice,products.UnitsInStock,products.UnitsOnOrder,products.ReorderLevel,products.Discontinued,Order_Details.Quantity,Order_Details.Discount
FROM Products  
INNER JOIN Order_Details  
ON Products.productID = Order_Details.productID;                

/*12.Delete the record from ‘Customers’ table who didn’t place any order.*/
 DELETE FROM customers WHERE CustomerID NOT IN
(SELECT Orders.CustomerID from Orders) 