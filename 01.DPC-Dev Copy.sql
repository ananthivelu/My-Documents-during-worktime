USE [SGEAS_DIFF]
GO
/****** Object:  StoredProcedure [dbo].[get_Rating_DPCWithoutExclusion]    Script Date: 10/6/2022 5:53:55 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

/*********************************************************************************************
** Name: [get_Rating_DPCWithoutExclusion]
** Desc: Stored Procedures to get the Dealer Product Code details, after applying the Program Product 
		Exlusions for the provided parameters. Uses the function fn_getProgramProductExclusion 
		for feching the Product Exclusions 
** Auth: Arvind 
** Date: 06/28/2021
**************************
** Change History
**************************
** CR   Date			Author          Description	
** --   --------        -------         ------------------------------------
** 1    06/08/22        svijayan        KTBRE1-934 Rates - Code fix to not consider Make for Rating for YAMAHA.
** 2    22/08/22        Ananthi         INT-191 - GetSpecific reorg
*********************************************************************************************/

ALTER     PROCEDURE [dbo].[get_Rating_DPCWithoutExclusion]
(@ai_program_Id BIGINT, @ai_dealer_ID INT, @ad_sale_date DATE, @as_vehicle_make VARCHAR(50), @as_vehicle_model VARCHAR(50),
@ai_vehicle_year INT, @as_Finance_Type VARCHAR(10), @as_Vehicle_Condition VARCHAR(20), @as_vehicle_type_category VARCHAR(30), 
@as_is_after_sale VARCHAR(5), @ad_InService_Date DATE, @ai_vehicle_table INT=0, @ai_warranty_month INT=0, 
@as_Product_Code VARCHAR(30)=NULL, @as_Product_Plan_Code NVARCHAR(10)=NULL, @as_Calling_Procedure VARCHAR(255),
@ls_vehicle_make VARCHAR(50)=NULL, @ls_vehicletype_correct INT=NULL)  ---Added the parameter @ls_vehicle_make & condition to check the Make while inserting to #dpc KTBRE1-934))
AS
BEGIN

----------------------------------------
----- Stage 0: Declaration and Initialization 
----------------------------------------
	DECLARE @as_Ecom_Prod_Category VARCHAR(20) = NULL, @as_Blank_Warranty_Month VARCHAR(1),
	@as_dealer_number varchar(10),@as_engine_make varchar(50),@as_engine_model varchar(50),
	@li_vehicle_table int,@as_engine_hp int--@ls_vehicle_make VARCHAR(50)=NULL, @ls_vehicletype_correct INT=NULL  --191
			
	SELECT @as_Blank_Warranty_Month = CASE WHEN @ai_warranty_month IS NULL THEN 'Y' ELSE 'N' END  -- #DAV-1473  
	Select @ai_dealer_id = Dealer_ID from Dealer where CMS_Dealer_Number=@as_dealer_number      -- 191

	CREATE TABLE #Program_Product_Exclusions 
	(Program_ID BIGINT, ECom_Prod_Category VARCHAR(20), Exclusion_Type VARCHAR(50), Make VARCHAR(25),Model VARCHAR(25), 
	ExcludeBrandedMake VARCHAR(25), Vehicle_Condition VARCHAR(250), Vehicle_type VARCHAR(250), Finance_Type VARCHAR(10), 
	IsAfterSale VARCHAR(15), Product_Code_ID BIGINT, Product_Plan_Code VARCHAR(20), Product_Plan_id BIGINT,  
	Product_Plan_Sku_ID BIGINT, Product_Code VARCHAR(50), Dealer_ID BIGINT, Sales_Effective_Date DATE, 
	Sales_Expiration_Date DATE, IsBlank_In_Service_Date VARCHAR(1), IsBlank_Warranty_Month VARCHAR(1))

	CREATE TABLE #dpc  
	(Product_Code_ID BIGINT, Product_Plan_SKU_ID BIGINT, Product_Plan_ID BIGINT, Product_Code NVARCHAR(30), 
	Program_ID BIGINT, Product_Plan_Code NVARCHAR(10), Dealer_ID BIGINT, VehicleMSRPFrom INT, 
	VehicleMSRPTo INT, Product_Plan_SKU NVARCHAR(50), Product_Type_Code NVARCHAR(10), Mileage BIGINT, 
	Deductible_Amount FLOAT, CMS_Coverage_code NVARCHAR(100), term_from INT, term_to INT, 
	Deductible_disappearing NCHAR(1), Term INT, BUSU NVARCHAR(10), Odometer_From BIGINT, Odometer_To BIGINT, 
	Vehicle_Age_From BIGINT, Vehicle_Age_To BIGINT, Full_Warranty_Remain_Months BIGINT,
	Full_Warranty_Remain_Days BIGINT, Full_Warranty_Remain_Miles BIGINT, Powertrain_Warranty_Remain_Months BIGINT,
	Powertrain_Warranty_Remain_Days BIGINT, Powertrain_Warranty_Remain_Miles BIGINT, finance_type VARCHAR(10),
	time_months_from BIGINT, time_months_to BIGINT, time_days_from BIGINT, Time_days_to BIGINT,
	Vehicle_Condition_id INT, Vehicle_Type NVARCHAR(20),vehicle_make VARCHAR(50),Vehicletype_correct int,
	
	Vehicle_model VARCHAR(50),Vehicle_year INT,Vehicle_Condition VARCHAR(20),Vehicle_type_category VARCHAR(30),is_after_sale VARCHAR(5),vehicle_table INT,
    warranty_month INT)

/*	----------------191-
	DECLARE @li_rate_method_id INT, @li_Product_Code_ID BIGINT, @li_Process_ID INT=0 

	IF (@as_Calling_Procedure = 'GETEVERYTHING' OR @as_Calling_Procedure = 'GETSPECIFICPRODUCT')     ---INT-191
		SELECT @li_Process_ID = 1
	ELSE IF (@as_Calling_Procedure = 'SAVE_ECONTRACT_VALIDATION')  
		SELECT @li_Process_ID = 2 

	IF (@li_Process_ID = 2)
	BEGIN
		SELECT @li_Process_ID = Product_Code_ID
		  FROM Ref_Product_Code 
		 WHERE Program_ID = @ai_program_id AND Product_Code = @as_product_code
	END 
	------191------------- */
	 --select Product_Plan_Code=@as_Product_Plan_Code, dealer_id= @ai_dealer_ID  -- INT-191

----------------------------------------
----- Stage 1: Creation of the DPC Table for processing 
----------------------------------------
	IF (UPPER(@as_Calling_Procedure) = 'GETEVERYTHING') --OR UPPER(@as_Calling_Procedure) = 'GETSPECIFICPRODUCT') --- INT-191
	BEGIN 

	 
	    --Select dpc.Product_Code_ID, ps.Product_Plan_Sku_ID, pp.product_plan_id, rpc.Product_Code, rpc.Program_ID,pp.Product_Plan_Code,dpc.dealer_id

		INSERT INTO #dpc (Product_Code_ID, Product_Plan_Sku_ID, Product_Plan_ID, Product_Code, Program_ID, Product_Plan_Code, Dealer_ID)

		SELECT dpc.Product_Code_ID, ps.Product_Plan_Sku_ID, pp.product_plan_id, rpc.Product_Code, rpc.Program_ID,pp.Product_Plan_Code,dpc.dealer_id 

		FROM dealer_product_code DPC (NOLOCK)   
		INNER JOIN dealer dlr (NOLOCK) ON dlr.Dealer_ID = dpc.Dealer_ID  
		INNER JOIN Ref_Product_Code rpc (NOLOCK) ON rpc.Product_Code_ID = dpc.Product_Code_ID  
		INNER JOIN product_plan pp (NOLOCK) ON pp.Product_Code_ID = rpc.Product_Code_ID  AND pp.Program_id = rpc.Program_ID
		INNER JOIN product_plan_sku ps (NOLOCK) ON pp.Product_Plan_ID = ps.Product_Plan_ID   
		WHERE dlr.dealer_id = @ai_dealer_id    -- 191
		AND @AD_SALE_DATE BETWEEN dpc.Effective_Sale_Date AND dpc.Expiration_Sale_Date  
		AND GETDATE() BETWEEN dpc.Effective_Business_Date AND dpc.Expiration_Business_Date
		---- 191
		AND getdate() between pp.Effective_date and pp.Expiration_Date
		  and rpc.Product_Code = @as_product_code
		AND NOT EXISTS (SELECT 1   
				FROM [Dealer_Product_Plan_Exception] dppe (NOLOCK)   
				WHERE dppe.Dealer_ID = dlr.Dealer_ID   
				AND dppe.Product_Plan_ID = pp.Product_Plan_ID 
				AND @ad_sale_date BETWEEN dppe.Effective_date and dppe.Expiration_Date) 
				AND ISNULL(@ls_vehicle_make,'') = ISNULL(@as_vehicle_make,'') -- #UQDEFECT154   --- Added the parameter @ls_vehicle_make & condition to check the Make while inserting to #dpc  KTBRE1-934 
		AND ((@ai_vehicle_table = 0 AND ISNULL(@as_vehicle_make,'') <> '' 
						AND ISNULL(@as_vehicle_model,'') <> ''AND ISNULL(@ai_vehicle_year,0) > 0) 
		OR (@ai_vehicle_table = 1 AND rpc.program_id = @ai_program_id 
		--Applied only for YAMAHA KTBRE1-934 code change starts
		AND @ls_vehicle_make is not NULL AND @as_vehicle_type_category is NOT NULL 
		AND @as_vehicle_type_category <> '' AND @ls_vehicletype_correct = 1))
		--Applied only for YAMAHA KTBRE1-934 code change ends	
	END
------   ReOrg-191
 --Get the List of Products this dealer is elibile to sell
    ELSE IF (UPPER(@as_Calling_Procedure) = 'GETSPECIFICPRODUCT')
	BEGIN 
	SELECT 'Entering into the getspecific loop'
	INSERT INTO #dpc (Product_Code_ID, Product_Plan_Sku_ID, Product_Plan_ID,Program_ID,Product_Code)
		select dpc.Product_Code_ID ,  ps.Product_Plan_Sku_ID, pp.product_plan_id ,pp.Program_id, pc.Product_Code  
		 -- into #dpc 
		  from dealer_product_code DPC 
		  inner join dealer dlr on dpc.Dealer_ID = dlr.Dealer_ID
		  inner join ref_product_code pc on pc.Product_Code_ID = dpc.Product_Code_ID
		  inner join product_plan pp on pp.Product_Code_ID = dpc.Product_Code_ID
		  inner join product_plan_sku ps on pp.Product_Plan_ID = ps.Product_Plan_ID
		  where dlr.Dealer_ID = @ai_dealer_ID
		   and @ad_sale_date between dpc.Effective_Sale_Date and dpc.Expiration_Sale_Date
		   and getdate() between dpc.Effective_Business_Date and dpc.Expiration_Business_Date
		   and getdate() between pp.Effective_date and pp.Expiration_Date
		   and pc.Product_Code = @as_product_code
		    --AND (ISNULL(@ls_vehicle_make,'') = ISNULL(@as_vehicle_make,'')-- #UQDEFECT154
		   --KTBR-2834 - Change Starts
			AND (COALESCE (@ls_vehicle_make,@as_vehicle_make,'')=ISNULL(@as_vehicle_make,'')
			--KTBR-2834 - Change Ends
			OR  ISNULL(@as_engine_make,'') <> '' )
 	    	AND ((@li_vehicle_table = 0 
			AND (ISNULL(@as_vehicle_make,'') <> '' OR ISNULL(@as_engine_make,'')<>'')
			AND (ISNULL(@as_vehicle_model,'') <> '' OR ISNULL(@as_engine_model,'')<>'')
			AND (ISNULL(@ai_vehicle_year,0) > 0) OR ISNULL(@as_engine_hp,0) >=0) -- RFD -1194
					OR (@li_vehicle_table = 1 AND pc.program_id = @ai_program_id ) ) --- This is applyed for Yamaha (#UNQ281) 

          SELECT @as_dealer_number 'Dealerbumberfrom DPC output'
    END
------- ReOrg-191

	ELSE IF (@as_Calling_Procedure='SAVE_ECONTRACT_VALIDATION')
	BEGIN 
		INSERT INTO #DPC(Product_Code_ID, Product_Plan_SKU_ID, Product_Plan_ID, Product_Code, Program_ID, Product_Plan_Code, 
		Dealer_ID, VehicleMSRPFrom, VehicleMSRPTo, Product_Plan_SKU, Product_Type_Code, Mileage, Deductible_Amount, 
		CMS_Coverage_code, term_from, term_to, Deductible_disappearing, Term, BUSU, Odometer_From, Odometer_To, 
		Vehicle_Age_From, Vehicle_Age_To, Full_Warranty_Remain_Months, Full_Warranty_Remain_Days, Full_Warranty_Remain_Miles, 
		Powertrain_Warranty_Remain_Months, Powertrain_Warranty_Remain_Days, Powertrain_Warranty_Remain_Miles, 
		finance_type, time_months_from, time_months_to, time_days_from, Time_days_to, Vehicle_Condition_id, Vehicle_Type)

		SELECT dpc.Product_Code_ID, ps.Product_Plan_Sku_ID, pp.product_plan_id, rpc.Product_Code, rpc.Program_ID,
		pp.Product_Plan_Code, dpc.dealer_id, pp.VehicleMSRPFrom, pp.VehicleMSRPTo, ps.Product_Plan_Sku, rpt.Code, ps.Mileage, 
		ps.Deductible_Amount, ps.CMS_Coverage_code, ps.term_from, ps.term_to, ps.Deductible_disappearing, ps.Term, ps.BUSU,
		sve.Odometer_From, sve.Odometer_To, sve.Vehicle_Age_From, sve.Vehicle_Age_To, sve.Full_Warranty_Remain_Months, 
		sve.Full_Warranty_Remain_Days, sve.Full_Warranty_Remain_Miles, sve.Powertrain_Warranty_Remain_Months, 
		sve.Powertrain_Warranty_Remain_Days, sve.Powertrain_Warranty_Remain_Miles, sve.finance_type, sve.time_months_from,
		sve.time_months_to, sve.time_days_from, sve.time_days_to, sve.vehicle_condition_id, sve.vehicle_type 

		FROM dealer_product_code DPC (NOLOCK) 
		INNER JOIN dealer dlr (NOLOCK) ON dpc.Dealer_ID = dlr.Dealer_ID
		LEFT OUTER JOIN Ref_Product_Code rpc (NOLOCK) ON rpc.Product_Code_ID = dpc.Product_Code_ID
		AND ((@ai_vehicle_table = 0 AND ISNULL(@as_vehicle_make,'') <> '' 
		AND ISNULL(@as_vehicle_model,'') <> '' AND ISNULL(@ai_vehicle_year,0) > 0) 
		OR (@ai_vehicle_table = 1 AND rpc.program_id = @ai_program_id ) )   
		LEFT OUTER JOIN ref_product_type rpt (NOLOCK) ON rpc.Product_Type_ID = rpt.Product_type_ID
		LEFT OUTER JOIN product_plan pp (NOLOCK) 
			ON pp.Product_Code_ID = dpc.Product_Code_ID and pp.Product_Plan_Code = @as_Product_Plan_Code AND pp.Program_id = rpc.Program_ID 
		LEFT OUTER JOIN product_plan_sku ps (NOLOCK) ON pp.Product_Plan_ID = ps.Product_Plan_ID
		LEFT OUTER JOIN Sku_VSC_Eligibility SVE (nolock) on sve.Product_Plan_Sku_ID=ps.Product_Plan_Sku_ID 
			 
		WHERE dlr.dealer_id = @ai_dealer_id 
		AND @ad_sale_date BETWEEN dpc.Effective_Sale_Date AND dpc.Expiration_Sale_Date
		AND GETDATE() BETWEEN dpc.Effective_Business_Date AND dpc.Expiration_Business_Date
		AND rpc.Product_Code = @as_product_code
		AND NOT EXISTS (SELECT 1 
				FROM [Dealer_Product_Plan_Exception] dppe (NOLOCK) 
				WHERE dppe.Dealer_ID = dlr.Dealer_ID 
				AND dppe.Product_Plan_ID = pp.Product_Plan_ID 
				AND @ad_sale_date BETWEEN DPPE.Effective_date AND DPPE.Expiration_Date) 

	END 

	CREATE INDEX IX_dpc01 ON #dpc (Program_ID, Product_Code, Product_Plan_ID, Product_Plan_SKU_ID)
----------------------------------------
----- Stage 2: Creation of Product Exclusion details  
----------------------------------------
	---- Fetch the rows on Program Product Category Exclusions --- 
	INSERT INTO #Program_Product_Exclusions
	(Program_ID, ECom_Prod_Category, Exclusion_Type, Make, Model, ExcludeBrandedMake, Vehicle_Condition, Vehicle_type, 
	Finance_Type, IsAfterSale, Product_Code_ID, Product_Plan_Code, Product_Plan_id, Product_Plan_Sku_ID, Product_Code, 
	Dealer_ID, Sales_Effective_Date, Sales_Expiration_Date, IsBlank_In_Service_Date, IsBlank_Warranty_Month)
	SELECT Program_ID, ECom_Prod_Category, Exclusion_Type, Make, Model, ExcludeBrandedMake, Vehicle_Condition, Vehicle_Type, 
	Finance_Type, IsAfterSale, Product_Code_ID, Product_Plan_Code, Product_Plan_id,  Product_Plan_Sku_ID,
	Product_Code, Dealer_ID, Sales_Effective_Date, Sales_Expiration_Date, IsBlank_In_Service_Date, IsBlank_Warranty_Month 
	FROM dbo.[fn_getProgramProductExclusion]
	(@ai_Program_id, @as_Ecom_Prod_Category, @as_vehicle_make,@as_vehicle_model, @as_Finance_Type, @as_Vehicle_Condition, 
	@as_vehicle_type_category, @as_is_after_sale, @ad_InService_Date, @ad_sale_date, @as_Blank_Warranty_Month) 

	CREATE INDEX IX_PPE01 ON #Program_Product_Exclusions (Program_ID, Product_code, Exclusion_type) 
----------------------------------------
----- Stage 3: Update the Exclusions from the #dpc table 
----------------------------------------
	--- Exclusion Type = VEHICLETYPE ---
	DELETE dpc	FROM #dpc dpc
	INNER JOIN #Program_Product_Exclusions ppe 
	ON ppe.Program_ID = dpc.Program_id AND ((ISNULL(ppe.Product_code,'*') !='*' AND ppe.Product_Code = dpc.Product_Code) OR (ISNULL(ppe.Product_code,'*') ='*'))
	WHERE ppe.Exclusion_Type = 'VEHICLETYPE' AND ppe.Vehicle_Type = @as_vehicle_type_category

	--- Exclusion Type = MAKEVEHICLETYPE ---
	DELETE dpc FROM #dpc dpc
	INNER JOIN #Program_Product_Exclusions ppe 
	ON ppe.Program_ID = dpc.Program_id AND ((ISNULL(ppe.Product_code,'*') !='*' AND ppe.Product_Code = dpc.Product_Code) OR (ISNULL(ppe.Product_code,'*') ='*'))
	INNER JOIN Program_Vehicle_Class_Mapping pvcm (NOLOCK) ON pvcm.Product_Code_ID = dpc.Product_Code_ID 
	AND pvcm.Program_ID = dpc.Program_ID AND pvcm.product_plan_id = dpc.Product_Plan_ID 
	INNER JOIN 
	(SELECT DISTINCT  rll.lookup_value_id, rll.[Value] FROM Ref_Lookup_Name rln (NOLOCK) 
	INNER JOIN Ref_Lookup_Value rll (NOLOCK) ON rll.lookup_name_id = rln.lookup_name_id WHERE rln.lookup_name = 'VEHICLE_TYPE') ref 
	ON ref.lookup_value_id = pvcm.Vehicle_Type_ID
	WHERE ppe.Exclusion_Type = 'MAKEVEHICLETYPE' AND ppe.Vehicle_Type = ref.[Value]
		AND COALESCE(@as_vehicle_Make,'*') != '*' AND @as_vehicle_make = ppe.Make

	--- Exclusion Type = BLANKINSERVICEDATE ---
	DELETE dpc FROM #dpc dpc
	INNER JOIN #Program_Product_Exclusions ppe 
	ON ppe.Program_ID = dpc.Program_id AND ppe.Product_Code = dpc.Product_Code 
	WHERE ppe.Exclusion_Type = 'BLANKINSERVICEDATE' 
	AND (COALESCE(@ad_inservice_date,NULL) = NULL OR ((COALESCE(@ad_inservice_date,'') = '') 
	AND ppe.IsBlank_In_Service_Date = 'Y'))

	--- Exclusion Type = BLANKINSERVICEDATEISAFTERSALE ---
	DELETE dpc FROM #dpc dpc
	INNER JOIN #Program_Product_Exclusions ppe 
	ON ppe.Program_ID = dpc.Program_id AND ppe.Product_Code = dpc.Product_Code 
	WHERE ppe.Exclusion_Type = 'BLANKINSERVICEDATEISAFTERSALE' 
	AND ((COALESCE(@ad_inservice_date,NULL) = NULL) OR ((COALESCE(@ad_inservice_date,'') = '') 
	AND ppe.IsBlank_In_Service_Date = 'Y'))
	AND COALESCE(@as_is_after_sale,'*') != '*' AND @as_is_after_sale = ppe.IsAfterSale

	--- Exclusion Type = VEHICLECONDITION ---
	DELETE dpc  FROM #dpc dpc
	INNER JOIN #Program_Product_Exclusions ppe 
	ON ppe.Program_ID = dpc.Program_id AND ppe.Product_Code = dpc.Product_Code 
	WHERE (ppe.Exclusion_Type = 'VEHICLECONDITION' 
		AND COALESCE(@as_Vehicle_condition, '*') != '*' AND @as_vehicle_condition = ppe.Vehicle_condition)

	--- Exclusion Type = VEHICLECONDITIONISAFTERSALE ---
	DELETE dpc  FROM #dpc dpc
	INNER JOIN #Program_Product_Exclusions ppe 
	ON ppe.Program_ID = dpc.Program_id AND ppe.Product_Code = dpc.Product_Code 
	WHERE (ppe.Exclusion_Type = 'VEHICLECONDITIONISAFTERSALE'
		AND COALESCE(@as_Vehicle_condition,'*') != '*' AND @as_vehicle_condition = ppe.Vehicle_condition
		AND (COALESCE(@as_is_after_sale,'*')) != '*' 
		AND @as_is_after_sale = ppe.IsAfterSale)

	--- Exclusion Type = MAKEVEHICLECONDITIONISAFTERSALE ---
	DELETE dpc  FROM #dpc dpc
	INNER JOIN #Program_Product_Exclusions ppe
	ON ppe.Program_ID = dpc.Program_id AND ppe.Product_Code = dpc.Product_Code 
	WHERE (ppe.Exclusion_Type = 'MAKEVEHICLECONDITIONISAFTERSALE' 
		AND COALESCE(@as_Vehicle_condition,'*') != '*' AND @as_vehicle_condition = ppe.Vehicle_condition
		AND (COALESCE(@as_is_after_sale,'*')) != '*' AND @as_is_after_sale = ppe.IsAfterSale
		AND COALESCE(@as_vehicle_Make,'*') != '*' AND @as_vehicle_make = ppe.Make)

	--- Exclusion Type = FINANCETYPE ---
	DELETE dpc  FROM #dpc dpc
	INNER JOIN #Program_Product_Exclusions ppe
	ON ppe.Program_ID = dpc.Program_id AND ppe.Product_Code = dpc.Product_Code 
	WHERE  (ppe.Exclusion_Type = 'FINANCETYPE' 
		AND COALESCE(@as_finance_Type,'*') != '*' AND @as_Finance_type = ppe.Finance_Type)

	--- Exclusion Type = FINANCETYPEVEHICLECONDITION ---
	DELETE dpc  FROM #dpc dpc
	INNER JOIN #Program_Product_Exclusions ppe
	ON ppe.Program_ID = dpc.Program_id AND ppe.Product_Code = dpc.Product_Code 
	WHERE (ppe.Exclusion_Type = 'FINANCETYPEVEHICLECONDITION' 
		AND COALESCE(@as_finance_Type,'*') != '*' AND @as_Finance_type = ppe.Finance_Type
		AND COALESCE(@as_Vehicle_condition,'*') != '*' AND @as_vehicle_condition = ppe.Vehicle_condition)

	--- Exclusion Type = FINANCETYPEISAFTERSALE ---
	DELETE dpc  FROM #dpc dpc
	INNER JOIN #Program_Product_Exclusions ppe
	ON ppe.Program_ID = dpc.Program_id AND ppe.Product_Code = dpc.Product_Code 
	WHERE  (ppe.Exclusion_Type = 'FINANCETYPEISAFTERSALE' 
		AND COALESCE(@as_finance_Type,'*') != '*' AND @as_Finance_type = ppe.Finance_Type
		AND (COALESCE(@as_is_after_sale,'*')) != '*' AND @as_is_after_sale = ppe.IsAfterSale)

	--- Exclusion Type = FINANCETYPEVEHICLECONDITIONISAFTERSALE ---
	DELETE dpc  FROM #dpc dpc
	INNER JOIN #Program_Product_Exclusions ppe
	ON ppe.Program_ID = dpc.Program_id AND ppe.Product_Code = dpc.Product_Code 
	WHERE (ppe.Exclusion_Type = 'FINANCETYPEVEHICLECONDITIONISAFTERSALE' 
		AND COALESCE(@as_finance_Type,'*') != '*' AND @as_Finance_type = ppe.Finance_Type
		AND COALESCE(@as_Vehicle_condition,'*') != '*' AND @as_vehicle_condition = ppe.Vehicle_condition
		AND (COALESCE(@as_is_after_sale,'*')) != '*' AND @as_is_after_sale = ppe.IsAfterSale)

	--- Exclusion Type = MAKE ---
	DELETE dpc  FROM #dpc dpc
	INNER JOIN #Program_Product_Exclusions ppe
	ON ppe.Program_ID = dpc.Program_id AND ppe.Product_Code = dpc.Product_Code 
	WHERE (ppe.Exclusion_Type = 'MAKE' 
		AND COALESCE(@as_vehicle_Make,'*') != '*' AND @as_vehicle_make = ppe.Make)

	--- Exclusion Type = MODEL ---
	DELETE dpc  FROM #dpc dpc
	INNER JOIN #Program_Product_Exclusions ppe
	ON ppe.Program_ID = dpc.Program_id AND ppe.Product_Code = dpc.Product_Code 
	WHERE (ppe.Exclusion_Type = 'MODEL' 
		AND COALESCE(@as_vehicle_Model,'*') != '*' AND @as_vehicle_model = ppe.Model)

	--- Exclusion Type = ISAFTERSALE ---
	DELETE dpc  FROM #dpc dpc
	INNER JOIN #Program_Product_Exclusions ppe
	ON ppe.Program_ID = dpc.Program_id AND ppe.Product_Code = dpc.Product_Code 
	WHERE (ppe.Exclusion_Type = 'ISAFTERSALE' 
		AND (COALESCE(@as_is_after_sale,'*')) != '*' AND @as_is_after_sale = ppe.IsAfterSale)

	--- Exclusion Type = EXCLUDEBRANDEDMAKEVEHICLECONDITIONISAFTERSALE ---
	DELETE dpc  FROM #dpc dpc
	INNER JOIN #Program_Product_Exclusions ppe
	ON ppe.Program_ID = dpc.Program_id AND ppe.Product_Code = dpc.Product_Code 
	WHERE (ppe.Exclusion_Type = 'EXCLUDEBRANDEDMAKEVEHICLECONDITIONISAFTERSALE' 
		AND COALESCE(@as_Vehicle_condition,'*') != '*' AND @as_vehicle_condition = ppe.Vehicle_condition
		AND (COALESCE(@as_is_after_sale,'*')) != '*' AND @as_is_after_sale = ppe.IsAfterSale
		AND COALESCE(@as_vehicle_Make,'*') != '*' AND @as_vehicle_make != ppe.ExcludeBrandedMake)

	--- Exclusion Type = EXCLUDEBRANDEDMAKEFINANCETYPEVEHICLECONDITIONISAFTERSALE 
	DELETE dpc  FROM #dpc dpc
	INNER JOIN #Program_Product_Exclusions ppe
	ON ppe.Program_ID = dpc.Program_id AND ppe.Product_Code = dpc.Product_Code 
	WHERE (ppe.Exclusion_Type = 'EXCLUDEBRANDEDMAKEFINANCETYPEVEHICLECONDITIONISAFTERSALE' 
		AND COALESCE(@as_finance_Type,'*') != '*' AND @as_Finance_type = ppe.Finance_Type
		AND COALESCE(@as_Vehicle_condition,'*') != '*' AND @as_vehicle_condition = ppe.Vehicle_condition
		AND (COALESCE(@as_is_after_sale,'*')) != '*' AND @as_is_after_sale = ppe.IsAfterSale
		AND COALESCE(@as_vehicle_Make,'*') != '*' AND @as_vehicle_make != ppe.ExcludeBrandedMake)

	--- Exclusion Type = EXCLUDEBRANDEDMAKEFINANCETYPEISAFTERSALE 
	DELETE dpc  FROM #dpc dpc
	INNER JOIN #Program_Product_Exclusions ppe
	ON ppe.Program_ID = dpc.Program_id AND ppe.Product_Code = dpc.Product_Code 
	WHERE  (ppe.Exclusion_Type = 'EXCLUDEBRANDEDMAKEFINANCETYPEISAFTERSALE' 
		AND COALESCE(@as_finance_Type,'*') != '*' AND @as_Finance_type = ppe.Finance_Type
		AND (COALESCE(@as_is_after_sale,'*')) != '*' AND @as_is_after_sale = ppe.IsAfterSale
		AND COALESCE(@as_vehicle_Make,'*') != '*' AND @as_vehicle_make != ppe.ExcludeBrandedMake)

	--- Exclusion Type = EXCLUDEBRANDEDMAKE 
	DELETE dpc  FROM #dpc dpc
	INNER JOIN #Program_Product_Exclusions ppe
	ON ppe.Program_ID = dpc.Program_id AND ppe.Product_Code = dpc.Product_Code 
	WHERE (ppe.Exclusion_Type = 'EXCLUDEBRANDEDMAKE' 
			AND COALESCE(@as_vehicle_Make,'*') != '*' AND @as_vehicle_make != ppe.ExcludeBrandedMake)

	--- Exclusion Type = BLANKWARRANTYMONTH 
	DELETE dpc  FROM #dpc dpc
	INNER JOIN #Program_Product_Exclusions ppe
	ON ppe.Program_ID = dpc.Program_id AND ppe.Product_Code = dpc.Product_Code 
	WHERE (ppe.Exclusion_Type = 'BLANKWARRANTYMONTH' 
		AND COALESCE(@as_Blank_Warranty_Month,'*') != '*' AND @as_Blank_Warranty_Month = ppe.IsBlank_Warranty_Month
		AND @ai_warranty_month IS NULL)

	--- Exclusion Type = VEHICLECONDITIONBLANKWARRANTYMONTH 
	DELETE dpc  FROM #dpc dpc
	INNER JOIN #Program_Product_Exclusions ppe
	ON ppe.Program_ID = dpc.Program_id AND ppe.Product_Code = dpc.Product_Code 
	WHERE (ppe.Exclusion_Type = 'VEHICLECONDITIONBLANKWARRANTYMONTH' 
		AND COALESCE(@as_Vehicle_condition,'*') != '*' AND @as_vehicle_condition = ppe.Vehicle_condition
		AND COALESCE(@as_Blank_Warranty_Month,'*') != '*' AND @as_Blank_Warranty_Month = ppe.IsBlank_Warranty_Month
		AND @ai_warranty_month IS NULL)

	--- Exclusion Type = VEHICLECONDITIONBLANKINSERVICEDATE 
	DELETE dpc FROM #dpc dpc
	INNER JOIN #Program_Product_Exclusions ppe
	ON ppe.Program_ID = dpc.Program_id AND ppe.Product_Code = dpc.Product_Code 
	WHERE (ppe.Exclusion_Type = 'VEHICLECONDITIONBLANKINSERVICEDATE' 
		AND COALESCE(@as_Vehicle_condition,'*') != '*' AND @as_vehicle_condition = ppe.Vehicle_condition
		AND ((COALESCE(@ad_inservice_date,NULL) = NULL) OR (COALESCE(@ad_inservice_date,'') = '' 
		AND ppe.IsBlank_In_Service_Date = 'Y')))

----------------------------------------
----- Stage 4: Insert the Non-Excluded from the #dpc into return table 
----------------------------------------
	SELECT Product_Code_ID, Product_Plan_Sku_ID, Product_Plan_ID, Product_Code, Program_ID, Product_Plan_Code, Dealer_ID,
	VehicleMSRPFrom, VehicleMSRPTo, Product_Plan_Sku, Product_Type_Code, Mileage, Deductible_Amount, CMS_Coverage_code, term_from, term_to, 
	Deductible_disappearing, Term, BUSU, Odometer_From, Odometer_To, Vehicle_Age_From, Vehicle_Age_To, Full_Warranty_Remain_Months, 
	Full_Warranty_Remain_Days, Full_Warranty_Remain_Miles, Powertrain_Warranty_Remain_Months, Powertrain_Warranty_Remain_Days, 
	Powertrain_Warranty_Remain_Miles, finance_type, time_months_from, time_months_to, time_days_from, time_days_to, vehicle_condition_id, 
	vehicle_type
	FROM #dpc (NOLOCK) WHERE 1=1

		SELECT 'DPC Count' DPCOutput, * FROM #dpc;

		SELECT @ai_dealer_ID 'After Exclusions'
 
END 
