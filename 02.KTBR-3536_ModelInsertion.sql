USE SGEAS_DIFF
GO
BEGIN TRAN

INSERT INTO ref_model VALUES
((select make_id from ref_make where make='ROYAL ENFIELD'),'CL350','CLASSIC 350',NULL,getdate(),'IT',getdate(),'IT',NULL),
((select make_id from ref_make where make='ROYAL ENFIELD'),'HIL','HIMALAYN',NULL,getdate(),'IT',getdate(),'IT',NULL),
((select make_id from ref_make where make='ROYAL ENFIELD'),'IN650','INT650',NULL,getdate(),'IT',getdate(),'IT',NULL)

--3 rows affected
--COMMIT/ROLLBACK



