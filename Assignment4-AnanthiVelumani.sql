/*1)a)Non-clustered primary Index – CustomerID, EmployeeID, OrderDate*/

/*Table Creation*/
CREATE TABLE Ani
(CustomerID int NOT NULL,
Company_name char(50) NOT NULL,
Contact_name char(30),
Contact_title char(30),
address char(50),
EmployeeID int NOT NULL,
OrderDate int,
CONSTRAINT Ani_pk PRIMARY KEY (CustomerID));

CREATE NONCLUSTERED INDEX IND_noncluc
ON Ani ( CustomerID, EmployeeID, OrderDate);
/*b)Clustered Index – OrderID*/
CREATE CLUSTERED INDEX IND_clucks
ON Ani (Company_name);  
/*c) Non-clustered primary index – CategoryID, SupplierID*/
CREATE NONCLUSTERED INDEX IND_products
ON Products (ProductID);  
/*d)Clustered Index – ProductID*/
CREATE CLUSTERED INDEX IND_clust
ON Products (productID); 

/*2.Alter the ‘CustOrdersOrder’ stored procedure to Call the ‘CustOrdersDetail’ stored 
procedure and pass CustomerID as input and get the order details for that customer*/

ALTER PROCEDURE CustOrdersOrder(@CustomerID INT)
RETURNS TABLE
AS
RETURN 
SELECT * FROM Orders;
GO

EXEC CustOrdersDetail;

/*3. Create a scalar valued function ’getEmployeeFullName’ to return varchar output –
Concatenate the first name and last name of the employee and return the 
concatenated value as output for the input EmployeeID*/

CREATE FUNCTION getEmployeeFullNames(@EmployeeID int)
RETURNS varchar(100)
AS
BEGIN
DECLARE @name as Varchar(100)
SELECT @name = CONCAT(firstname,lastname) from Employees
RETURN @name
END


/*4.Create a table valued function ‘getEmployeeDetails’ to get the employee details for the 
input employeeID*/

CREATE FUNCTION getEmployeeDetails(@EmployeeID INT)
    
RETURNS TABLE
AS
RETURN
    SELECT * FROM Employees; 

/*5. Alter the function ‘getEmployeeDetails’ to call the ‘getEmployeeFullName’ function and 
return the employee details with full name*/

ALTER FUNCTION getEmployeeDetails(@getEmployeeFullName varchar(50))
RETURNS TABLE
AS
RETURN 
SELECT * FROM Employees;
GO

/*6.Pass CustomerID input to the ‘CustOrdersOrder’ SPROC and share the output*/

CREATE PROCEDURE CustOrdersOrder(@CustomerID int(30))
RETURNS TABLE 
AS RETURN
SELECT * FROM Customers;
GO
EXEC CustOrdersOrder;

/*7.Pass ‘EmployeeID’ input to ‘getEmployeeDetails’ Function and share the results*/

ALTER FUNCTION getEmployeeDetails(@EmployeeID INT)
RETURNS TABLE
AS 
RETURN SELECT * FROM Employees;


/*8.Insert a record into Employees table with some sample data. This insert should be 
made under transaction (BEGIN TRAN, COMMIT/ROLLBACK)*/

BEGIN TRAN
    INSERT INTO Employees (EmployeeID,LastName,FirstName)
    values('15','Kings','Chinnu');
rollback

SET IDENTITY_INSERT Employees ON

SELECT * FROM Employees;
/*9.Update the lastName column in Employees table for one of the records using ‘Waitfor 
Delay’ and under transaction comments (Begin Tran and Rollback)
In parallel, try to retrieve the value from the Employees table in different session 
(different query window) and share the results*/

BEGIN tran
    WAITFOR DELAY '00:00:05';
    INSERT INTO Employees (EmployeeID,LastName,FirstName)
    values('15','Kings','Chinnu');
SET IDENTITY_INSERT Employees ON

/*10.Update the lastName column in Employees table for one of the records using ‘Waitfor 
Delay’ and under transaction comments (Begin Tran and Commit)
In parallel, try to retrieve the value from the Employees table in different session 
(different query window) and share the results*/

BEGIN TRAN
    WAITFOR DELAY '00:00:10';
	INSERT INTO Employees(EmployeeID,LastName,FirstName)
	values('21','Davolin','Nansii')
Commit
SET IDENTITY_INSERT Employees ON
    
        


