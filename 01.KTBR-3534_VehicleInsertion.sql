USE SGEAS_DIFF
GO
BEGIN TRAN     

INSERT INTO Vehicle_Details 
(Program_id, year, Make, vehicle_type, is_active, effective_from, effective_to, Created_Date, Created_By, Updated_Date, Updated_By)
VALUES 
(20336,2023,'ZODIAC','BOAT','Y','2021-01-01','9999-12-31',getdate(),'IT',getdate(),'IT'),
(20336,2023,'HIGHFIELD','BOAT','Y','2021-01-01','9999-12-31',getdate(),'IT',getdate(),'IT')


-- ROLLBACK
-- 2 Rows affected