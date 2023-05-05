                                               ---DB Assignment 6---

--1. Can you briefly explain what is meant by Exception in SQL?
  --ANSWER
  An Exception is defined as a runtime error that can be handled programmatically. 
  If exception not handled, it might terminate the flow of a Execution.

--2. Why do we need Exception handling?
   --ANSWER
   An exception is an run time error which disrupts the normal flow of program. 
   SQL provides us the exception block which raises the exception in program thus helping the 
   programmer to find out the fault and resolve it.

--3. How we handle exception in SQL?
--ANSWER:
    we can handle the exception in catch block.
	Handle the exception (which is occur at runtime) using try and catch statements
	syntax:
	BEGIN TRY  
    // Write statements here that may cause exception
    END TRY
    BEGIN CATCH  
    //Write statements here to handle exception
    END CATCH


--4. Will the CATCH block inside a SPROC executed always?
--ANSWER:
     Catch Block execution is not mandatory for all time in a stored procedure.
	 Whenever error arises in try block statements then only catch block will be executed.
	 There is no error in try block the catch block does not execute.
--5. What are the different types of error functions used inside CATCH block?
--ANSWER:
     ERROR_LINE() returns the line number on which the exception occurred.
     ERROR_MESSAGE() returns the complete text of the generated error message.
     ERROR_PROCEDURE() returns the name of the stored procedure or trigger where the error occurred.
     ERROR_NUMBER() returns the number of the error that occurred.
     ERROR_SEVERITY() returns the severity level of the error that occurred.
     ERROR_STATE() returns the state number of the error that occurred.

--6. What is the main concept of SQL Server Transaction? 
--ANSWER:
     The primary benefit of using transactions is data integrity. 
	 Many database uses require storing data to multiple tables, or multiple rows to the same table in order to maintain a consistent data set. 
	 Using transactions ensures that other connections to the same database see either all the updates or none of them.
	begin tran
	//sql statement
	IF @@TranCount>0  
	COMMIT TRAN 
	// Commit the transaction ,when you done the update correctly. 
	IF @@TranCount>0  
	PRINT 'Error is Occur in Transaction'
	Print Error_Message()
	ROLLBACK TRAN  
	 
--7. What is meant by the term logging in SQL world?
--ANSWER:
    Every SQL Server database has a transaction log that records 
	all transactions and the database modifications made by each transaction.
    data collections with the identified steps of actions, is called Logging.

--8. Why we need logging for every transaction?
--ANSWER:
   It is easy for retrieving the particular information from the database whenever we needed.
   The transaction log contains enough information to undo all changes made to the data file as part of any individual transaction.
--9. Do we need backup for SQL Server Transaction Logs?
--ANSWER:
   A transaction log backup allows you to backup the transaction log.  After the transaction log backup is issued, 
   the space within the transaction log can be reused for other processes.If a transaction log backup is not taken and the database is not using the 
   Simple recovery model the transaction log will continue to grow.
/*10. Modify the procedure ‘[CustOrdersDetails]’ to update the calculation of UnitPrice Value 
to ‘UnitPrice=ROUND(Od.UnitPrice, 2)/0’.
Include TRY and CATCH block in CustOrdersDetails procedure. */
--ANSWER:

CREATE/ alter PROCEDURE [dbo].[CustOrdersDetails](@UnitPrice money ) 
AS         
BEGIN  
begin try 
begin tran
	UPDATE Order_Details SET Order_Details.UnitPrice=@UnitPrice/0;
	IF @@TranCount>0  
	COMMIT TRAN 

 end try
 begin catch
	 
	IF @@TranCount>0  
	PRINT 'Error is Occur in Transaction'
	Print Error_Message()
	ROLLBACK TRAN  
end catch    
END 

exec [dbo].[CustOrdersDetails] 14.00

/*11. Create an error log table with the below mentioned columns to store the details of the 
error occurred during the ‘CustOrdersDetails’ SPROC Call
a. Log ID
b. SPROC Name
c. Error Code
d. Error Description*/

--ANSWER:
alter PROCEDURE [dbo].[CustOrdersDetails] @UnitPrice money
AS
BEGIN

begin try

	UPDATE Order_Details SET Order_Details.UnitPrice=@UnitPrice/0;
	  
	
 end try
 begin catch
	                                                                                                    
	
	INSERT INTO [ErrorLogTable]  
         (ErrorNumber,ErrorDescription,ErrorProcedure)
		   VALUES
       (
	      ERROR_NUMBER()
		 ,ERROR_MESSAGE()
	     ,ERROR_PROCEDURE()
	   )
	   
end catch    
END 
 exec [dbo].[CustOrdersDetails] 14.00
 select * from [ErrorLogTable]
 --truncate table [ErrorLogTable]