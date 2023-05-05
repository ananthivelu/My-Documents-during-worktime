                               ---DATABASE ASSIGNMENT - 5B---
1)Create a procedure “add_employee_details” which accepts below json as input and stored the 
data in the employee table.
--ANSWER:
CREATE PROCEDURE add_employee_details
AS
Begin
DECLARE @objects NVARCHAR(MAX);
SET @objects = N'[{
 "empId": null,
 "lastName": "Davolio",
 "firstName": "Nancy",
 "dob": "1996-09-18",
 "address": "507 -20th Ave. E. Apt. 2A",
 "city": "Seattle",
 "title": "Sales Representative",
 "titleOfCourtesy": "Ms.",
 "hireDate": "2020-09-18",
 "region": "WA",
 "postalCode": "98122",
 "country": "USA",
 "homePhone": "(206) 555-9857",
 "extension": "5467",
 "photo": "0x151C2F00020000000D000E0014002100FFFFFFFF4269746D61702049",
 "notes": "Education includes a BA in psychology from Colorado State University in 1970. She also completed The Art of the Cold Call. Nancy is a member of Toastmasters International.",
 "reporName": "Fuller",
 "photoPath": "http://accweb/emmployees/davolio.bmp"
 },
 {
 "empId": null,
 "lastName": "Gowda",
 "firstName": "NAndish",
 "dob": "1997-05-04",
 "address": "507 -20th Ave. E. Apt. 2A",
 "city": "Seattle",
 "title": "Sales Representative",
 "titleOfCourtesy": "Ms.",
 "hireDate": "2020-09-18",
 "region": "WA",
 "postalCode": "98122",
 "country": "USA",
 "homePhone": "(206) 555-9857", "extension": "5467",
 "photo": "0x151C2F00020000000D000E0014002100FFFFFFFF4269746D61702049",
 "notes": "Education includes a BA in psychology from Colorado State University in 1970. She also completed The Art of the Cold Call. Nancy is a member of Toastmasters International.",
 "reporName": "Fuller",
 "photoPath": "http://accweb/emmployees/davolio.bmp"
 }
]';
end

SELECT *
FROM OPENJSON(@objects)
  WITH (
    id INT '$.empId',
    lastName NVARCHAR(50) '$.lastName',
	firstName NVARCHAR(50) '$.firstName',
    dateOfBirth DATETIME2 '$.dob',
	address varchar(50) '$.address',
	city varchar(50) '$.city',
	title varchar(50) '$.title',
	titleOfCourtesy varchar(50) '$.titleOfCourtesy ',
	hireDate DATETIME2 '$.hireDate',
	region varchar(50) '$.region',
	postalCode int '$.postalCode',
	country varchar(40) '$.country',
	homePhone NVARCHAR(50) '$.homePhone',
	extension int '$.extension',
	photo NVARCHAR(50) '$.Photo',
	notes NVARCHAR(50) '$.notes',
	reporName varchar(50) '$.reporName',
	photoPath NVARCHAR(50) '$.photoPath'
);

--drop procedure add_employee_details
exec add_employee_details



2)Create a procedure which accepts EmployeeID as input and returns the list of Order details 
under Employee as below JSON Format.
--ANSWER:
CREATE PROCEDURE spemployee(@EmployeeID int)
AS
BEGIN
    Select lastName,firstName,birthDate,address,city,title,titleOfCourtesy,hireDate,region,postalCode,country,homePhone,extension,
	customerID as "OrderDetails.customerID",orderDate as "OrderDetails.orderDate",requiredDate as "OrderDetails.requiredDate",
	shippedDate as"OrderDetails.shippedDate",shipVia as "OrderDetails.shipVia",freight as "OrderDetails.freight",shipName as "OrderDetails.shipName",
	shipAddress as "OrderDetails.shipAddress",shipCity as "OrderDetails.shipCity",shipRegion as "OrderDetails.shipRegion",
	shipPostalCode as "OrderDetails.shipPostalCode",shipCountry as "OrderDetails.shipCountry" from employees
	inner join  Orders on Employees.EmployeeID=Orders.EmployeeID  where Employees.EmployeeID=@EmployeeID FOR JSON PATH 
END
drop procedure  spemployee

exec spemployee 5

