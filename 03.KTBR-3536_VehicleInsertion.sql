USE SGEAS_DIFF
GO
BEGIN TRAN     

INSERT INTO Vehicle_Details 
(Program_id, year, Make, model, vehicle_type, is_active, effective_from, effective_to, Created_Date, Created_By, Updated_Date, Updated_By)
VALUES 
(20336,0,'ROYAL ENFIELD','CLASSIC 350','MOTORCYCLE','Y','2021-01-01','9999-12-31',getdate(),'IT',getdate(),'IT'),
(20336,0,'ROYAL ENFIELD','HIMALAYN','MOTORCYCLE','Y','2021-01-01','9999-12-31',getdate(),'IT',getdate(),'IT'),
(20336,0,'ROYAL ENFIELD','METEOR','MOTORCYCLE','Y','2021-01-01','9999-12-31',getdate(),'IT',getdate(),'IT'),
(20336,0,'ROYAL ENFIELD','INT650','MOTORCYCLE','Y','2021-01-01','9999-12-31',getdate(),'IT',getdate(),'IT'),
(20336,0,'ROYAL ENFIELD','CONTINENTAL GT','MOTORCYCLE','Y','2021-01-01','9999-12-31',getdate(),'IT',getdate(),'IT')

-- ROLLBACK
-- 5 Rows affected