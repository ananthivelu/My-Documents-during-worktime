USE [SGEAS_DIFF]
GO
/****** Object:  StoredProcedure [dbo].[get_Rating_PriceParameter]    Script Date: 10/6/2022 5:55:52 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- drop procedure get_Rating_PriceParameter
/*********************************************************************************************
** Name: [get_Rating_PriceParameter]
** Desc: Function to get the qualified Price Parameters, qualifying for the Vehicle Class details on different Rate Methods
**			This function calls the fn_getProgramVehicleClass for fetching the Vehicle Classing 
** Auth: Arvind 
** Date: 06/18/2021
**************************
** Change History
**************************
** CR   Date			Author          Description	
** --   --------        -------         ------------------------------------
** 1    22/08/22        Ananthi         INT-191 - GetSpecific reorg
*********************************************************************************************/

ALTER     PROCEDURE [dbo].[get_Rating_PriceParameter]
(@as_vin VARCHAR(17), @ai_program_id INTEGER, @as_surcharge NVARCHAR(1), @as_excluded NVARCHAR(1), @as_product_type VARCHAR(40) NULL, 
@as_product_code VARCHAR(50), @as_product_plan VARCHAR(20), @as_dealer_number VARCHAR(8), @ad_sale_date DATE, @ad_inservice_date DATE, 
@ai_odometer INTEGER, @ai_vehicle_year INTEGER, @as_vehicle_make VARCHAR(40), @as_vehicle_model VARCHAR(40), 
@as_vehicle_trim VARCHAR(40), @as_vehicle_condition VARCHAR(5),@lb_is_after_sale VARCHAR(5),@as_vehicle_type VARCHAR(60), 
@as_finance_amount MONEY, @ai_engine_displacement INTEGER, @dpc DealerProductCode READONLY, @vehicle_class VehicleClass READONLY,
@as_Calling_Process VARCHAR(255), @ai_product_code_id BIGINT)
AS
BEGIN
------------------------------------------------
----- Stage 0: Declaration 
------------------------------------------------
	DECLARE @li_rate_method_id INT, @li_Product_Code_ID BIGINT, @li_Process_ID INT=0 

	CREATE TABLE #price_parameter 
	(Product_Plan_SKU_Price_Parameter_ID BIGINT, Make VARCHAR(40), Vehicle_Class VARCHAR(40), Vehicle_Type VARCHAR(60),  
	Finance_Amount_From MONEY, Finance_Amount_To MONEY, MSRP_From MONEY, MSRP_To MONEY, Vehicle_Selling_Price_From MONEY,
	Vehicle_Price_To MONEY, Gross_Cap_Cost_From MONEY, Gross_Cap_Cost_To MONEY, Product_Plan_ID BIGINT, 
	Product_Code_ID BIGINT, Product_Type_ID BIGINT, Rating_Method VARCHAR(35), VSC_Surcharge_ID BIGINT)

------------------------------------------------
----- Stage 1: Collection of Vehicle Class details for the input into the Table variable and removal of Exclusions  
------------------------------------------------
	IF (@as_Calling_Process = 'GETEVERYTHING')
		SELECT @li_Process_ID = 1
	ELSE IF (@as_Calling_Process = 'SAVE_ECONTRACT_VALIDATION' OR @as_Calling_Process = 'GETSPECIFICPRODUCT')   ---INT-191
		SELECT @li_Process_ID = 2 

	IF (@li_Process_ID = 2)
	BEGIN
		SELECT @li_Process_ID = Product_Code_ID
		  FROM Ref_Product_Code 
		 WHERE Program_ID = @ai_program_id AND Product_Code = @as_product_code
	END 

------------------------------------------------
----- Stage 2: Fetching all the Price Parameters, for the qualifying Rate Method of the inputs of Vehicle  
------------------------------------------------
	-- Program Vehicle Class Mapping (Make & VEHICLE TYPE ) & Product Plan SKU Price Parameter (VEHICLE CLASS & ODOMETER) 
	----- VCLASS ODOM  -------------
	INSERT INTO #price_parameter 
	(Product_plan_sku_price_parameter_id, Make, Vehicle_Class, Vehicle_type, Finance_Amount_From, Finance_Amount_To, 
	Product_Plan_ID, Product_Code_ID, Product_Type_id, Rating_method, VSC_Surcharge_ID) 
	SELECT DISTINCT [ppspp].[Product_plan_sku_price_parameter_id], vc.Make, vc.ClassCode AS [vehicle_class], 
	vc.[Vehicle_type] AS [vehicle_type], CONVERT(MONEY,NULL) finance_amount_from, CONVERT(MONEY,NULL) [finance_amount_to], 
	vc.[product_plan_id], vc.[product_code_id], vc.[product_type_id], rrm.[Name] AS [Rating_method], 
	CASE @li_Process_ID WHEN 2 THEN ppspp.VSC_Surcharge_ID ELSE NULL END 
	FROM @VEHICLE_CLASS AS vc
	INNER JOIN [Product_plan_sku_price_parameter] AS [ppspp] (NOLOCK) 
		ON [ppspp].[vehicle_class_id] = vc.program_vehicle_class_id    
	INNER JOIN [ref_rate_method] AS [rrm] (NOLOCK) ON [rrm].[rate_method_id] = [ppspp].[rate_method_id]
	WHERE [rrm].[name] = 'VCLASS ODOM' AND ISNULL(vc.is_surcharge, 'N') = 'N' 
	AND ISNULL(vc.[is_excluded], 'N') = 'N' AND @ai_odometer BETWEEN [ppspp].[odometer_from] AND [ppspp].[odometer_to]
	AND (@li_Process_ID = 1 OR (@li_Process_ID = 2 AND vc.Product_Code_ID = @ai_product_code_id)); 

	-- Program Vehicle Class Mapping (Make & MODEL)   & Product Plan SKU Price Parameter (VEHICLE CLASS & ODOMETER)
	----  VCLASS TERM --------------
	INSERT INTO #price_parameter  
	(Product_plan_sku_price_parameter_id, Make, Vehicle_Class, Vehicle_type, Finance_Amount_From, Finance_Amount_To, 
	Product_Plan_ID, Product_Code_ID, Product_Type_id, Rating_method, VSC_Surcharge_ID) 
	SELECT DISTINCT ppspp.Product_Plan_SKU_Price_Parameter_ID, VC.Make, VC.ClassCode AS [vehicle_class], 
	VC.Vehicle_type, convert(money,null) [finance_amount_from], convert(money,null) [finance_amount_to], 
	vc.[product_plan_id], vc.[product_code_id], vc.[product_type_id], rrm.name AS [Rating_method], 
	CASE @li_Process_ID WHEN 2 THEN ppspp.VSC_Surcharge_ID ELSE NULL END 
	FROM @VEHICLE_CLASS VC 
	INNER JOIN ref_rate_method rrm (NOLOCK) ON [rrm].[name] = 'VCLASS TERM'  
	INNER JOIN Product_plan_sku_price_parameter ppspp (NOLOCK)   
	on rrm.rate_method_id = ppspp.rate_method_id AND ppspp.Vehicle_Class_id = VC.program_vehicle_class_id 
	WHERE ISNULL(VC.[is_surcharge], 'N') = 'N' AND ISNULL(VC.is_excluded, 'N') = 'N'  
	AND (@li_Process_ID = 1 OR (@li_Process_ID = 2 AND vc.Product_Code_ID = @ai_product_code_id)); 
			
	---- VCLASS TERM ODOM ------------
	INSERT INTO #price_parameter
	(Product_plan_sku_price_parameter_id, Make, Vehicle_Class, Vehicle_type, Finance_Amount_From, Finance_Amount_To, 
	Product_Plan_ID, Product_Code_ID, Product_Type_id, Rating_method, VSC_Surcharge_ID)   
	SELECT DISTINCT ppspp.[Product_plan_sku_price_parameter_id], VC.Make, VC.ClassCode, VC.Vehicle_type,  
	convert(money,null) finance_amount_from, convert(money,null) finance_amount_to, 
	VC.product_plan_id, vc.[product_code_id], vc.[product_type_id], rrm.name AS [Rating_method], 
	CASE @li_Process_ID WHEN 2 THEN ppspp.VSC_Surcharge_ID ELSE NULL END 
	FROM @VEHICLE_CLASS AS VC    
	INNER JOIN [ref_rate_method] AS [rrm] (NOLOCK) ON [rrm].[name] = 'VCLASS TERM ODOM'  
	Inner join [Product_plan_sku_price_parameter] AS [ppspp] (NOLOCK)   
	ON [rrm].[rate_method_id] = [ppspp].[rate_method_id] AND [ppspp].[Vehicle_Class_id] = vc.[program_vehicle_class_id]   
	WHERE @ai_odometer BETWEEN [ppspp].[odometer_from] AND [ppspp].[odometer_to] AND   
	ISNULL(vc.[is_surcharge], 'N') = 'N' AND ISNULL(vc.[is_excluded], 'N') = 'N' 
	AND (@li_Process_ID = 1 OR (@li_Process_ID = 2 AND vc.Product_Code_ID = @ai_product_code_id)); 
	
	---- VCLASS ODOM MAKE ------------
	INSERT INTO #price_parameter  
	(Product_plan_sku_price_parameter_id, Make, Vehicle_Class, Vehicle_type, Finance_Amount_From, Finance_Amount_To, 
	Product_Plan_ID, Product_Code_ID, Product_Type_id, Rating_method, VSC_Surcharge_ID) 
	SELECT DISTINCT ppspp.Product_plan_sku_price_parameter_id, VC.Make, VC.ClassCode AS vehicle_class, 
	VC.Vehicle_type AS vehicle_type, Convert(money,null) [finance_amount_from], convert(money,null) [finance_amount_to],
	VC.product_plan_id, VC.product_code_id, vc.[product_type_id], [rrm].[name] AS [Rating_method], 
	CASE @li_Process_ID WHEN 2 THEN ppspp.VSC_Surcharge_ID ELSE NULL END
	FROM @VEHICLE_CLASS AS VC
	INNER JOIN [ref_rate_method] AS [rrm] (NOLOCK) ON [rrm].[name] = 'VCLASS ODOM MAKE'  
	Inner join [Product_plan_sku_price_parameter] AS [ppspp] (nolock)   
	ON [rrm].[rate_method_id] = [ppspp].[rate_method_id] AND [ppspp].[Vehicle_Class_id] = vc.[program_vehicle_class_id]   
	WHERE @ai_odometer BETWEEN [ppspp].[odometer_from] AND [ppspp].[odometer_to] AND [ppspp].[make_id] = vc.[make_id]  
	AND ISNULL(vc.[is_surcharge], 'N') = 'N' AND ISNULL(vc.[is_excluded], 'N') = 'N'  
	AND (@li_Process_ID = 1 OR (@li_Process_ID = 2 AND vc.Product_Code_ID = @ai_product_code_id)); 

	------- TERM ODOM -------------
	SELECT @li_rate_method_id = rate_method_id FROM Ref_Rate_Method (NOLOCK) WHERE [NAME] = 'TERM ODOM'; 
	
	INSERT INTO #price_parameter  
	(Product_plan_sku_price_parameter_id, Make, Vehicle_Class, Vehicle_type, Finance_Amount_From, Finance_Amount_To, 
	Product_Plan_ID, Product_Code_ID, Product_Type_id, Rating_method, VSC_Surcharge_ID) 
	SELECT DISTINCT [ppspp].[Product_plan_sku_price_parameter_id], null [Make], null AS [vehicle_class], null AS [vehicle_type],  
	convert(money,null) [finance_amount_from], convert(money,null) [finance_amount_to], 
	null [product_plan_id], null [product_code_id], null [product_type_id], 'TERM ODOM' AS [Rating_method], 
	CASE @li_Process_ID WHEN 2 THEN ppspp.VSC_Surcharge_ID ELSE NULL END  
	FROM [Product_plan_sku_price_parameter] AS [ppspp]   
	WHERE ppspp.Rate_Method_id = @li_rate_method_id  
	AND @ai_odometer BETWEEN [ppspp].[odometer_from] AND [ppspp].[odometer_to]
	AND [ppspp].[odometer_from] IS NOT NULL AND [ppspp].[odometer_to] IS NOT NULL;  

	----- TERM  -------------
	SELECT @li_rate_method_id = rate_method_id FROM Ref_Rate_Method (NOLOCK) WHERE [NAME] = 'TERM' 
	
	INSERT INTO #price_parameter  
	(Product_plan_sku_price_parameter_id, Make, Vehicle_Class, Vehicle_type, Finance_Amount_From, Finance_Amount_To, 
	Product_Plan_ID, Product_Code_ID, Product_Type_id, Rating_method, VSC_Surcharge_ID) 
	SELECT DISTINCT [PPSPP].[PRODUCT_PLAN_SKU_PRICE_PARAMETER_ID], NULL [MAKE], NULL AS [VEHICLE_CLASS], NULL AS [VEHICLE_TYPE],  
	CONVERT(MONEY,NULL) [finance_amount_from], CONVERT(MONEY,NULL) [finance_amount_to], 
	NULL [product_plan_id], null [product_code_id], NULL [product_type_id], 'TERM' AS [Rating_method], 
	CASE @li_Process_ID WHEN 2 THEN ppspp.VSC_Surcharge_ID ELSE NULL END
	FROM [Product_plan_sku_price_parameter] AS [ppspp]   
	WHERE ppspp.Rate_Method_id = @li_rate_method_id  

	------ TERM FINAMT --------
	SELECT @li_rate_method_id = rate_method_id FROM Ref_Rate_Method WHERE [NAME] = 'TERM FINAMT' 
	
	INSERT INTO #price_parameter 
	(Product_plan_sku_price_parameter_id, Make, Vehicle_Class, Vehicle_type, Finance_Amount_From, Finance_Amount_To, 
	Product_Plan_ID, Product_Code_ID, Product_Type_id, Rating_method, VSC_Surcharge_ID)   
	SELECT DISTINCT [ppspp].[Product_plan_sku_price_parameter_id], NULL [Make], NULL AS [vehicle_class], NULL AS [vehicle_type],  
	CONVERT(MONEY, [finance_amount_from]), CONVERT(MONEY,[finance_amount_to]), 
	NULL [product_plan_id], NULL [product_code_id], NULL [product_type_id], 'TERM FINAMT' AS [Rating_method], 
	CASE @li_Process_ID WHEN 2 THEN ppspp.VSC_Surcharge_ID ELSE NULL END 
	FROM [Product_plan_sku_price_parameter] AS [ppspp]   
	Where ppspp.Rate_Method_id = @li_rate_method_id 
	AND ISNULL(@as_finance_amount,0) BETWEEN ppspp.Finance_amount_from AND ppspp.Finance_amount_to
	AND ppspp.Finance_amount_from IS NOT NULL AND ppspp.Finance_amount_to IS NOT NULL;

	------ VCLASS TERM ENGDISP 
	SELECT @li_rate_method_id = rate_method_id FROM Ref_Rate_Method (NOLOCK) WHERE [NAME] = 'VCLASS TERM ENGDISP'  

	INSERT INTO #price_parameter 
	(Product_plan_sku_price_parameter_id, Make, Vehicle_Class, Vehicle_type, Finance_Amount_From, Finance_Amount_To, 
	Product_Plan_ID, Product_Code_ID, Product_Type_id, Rating_method, VSC_Surcharge_ID)   
	SELECT DISTINCT   
	ppspp.Product_plan_sku_price_parameter_id, NULL [Make], vc.ClassCode  AS [vehicle_class], NULL AS [vehicle_type],  
	CONVERT(MONEY, [finance_amount_from]), CONVERT(MONEY,[finance_amount_to]), 
	vc.product_plan_id, vc.Product_Code_ID, vc.product_type_id, [rrm].[name] AS [Rating_method], 
	CASE @li_Process_ID WHEN 2 THEN ppspp.VSC_Surcharge_ID ELSE NULL END
	FROM @VEHICLE_CLASS AS vc   
	INNER JOIN [ref_rate_method] AS [rrm]  (NOLOCK) 
		ON [rrm].[name] = 'VCLASS TERM ENGDISP'  
	INNER join [Product_plan_SKU_price_parameter] AS [ppspp] (NOLOCK)   
		ON [ppspp].[rate_method_id] = [rrm].[rate_method_id] AND [ppspp].[Vehicle_Class_id] = vc.[program_vehicle_class_id]  
	WHERE ISNULL(vc.[is_excluded], 'N') = 'N' 
	AND ISNULL(@ai_engine_displacement,0) BETWEEN ppspp.[EngineDisplacement From] and ppspp.[EngineDisplacement To]
	AND ppspp.[EngineDisplacement From] IS NOT NULL AND ppspp.[EngineDisplacement To] IS NOT NULL
	AND (@li_Process_ID = 1 OR (@li_Process_ID = 2 AND ISNULL(vc.[is_surcharge], 'N') = 'N')); 

------------------------------------------------
----- Stage 3: Identifying the Duplicates on the Vehicle Classing   
------------------------------------------------

	CREATE TABLE #duplicate_Class 
	(Product_Plan_ID BIGINT, Product_Code_ID BIGINT, Product_Type_ID BIGINT, Vehicle_Class VARCHAR(30))

	INSERT INTO #duplicate_Class
	SELECT [product_plan_id], [product_code_id], [product_Type_id], MAX([vehicle_class]) AS [vehicle_class]  
	FROM #price_parameter (NOLOCK) 
	GROUP BY [product_plan_id], [product_code_id], [product_Type_id]  
	HAVING COUNT(DISTINCT [vehicle_class]) > 1;    
    
  -- Delete Duplicate class keeping the TOp class                              
	DELETE pp
	FROM #price_parameter pp
	INNER JOIN #duplicate_Class dc  
	ON ISNULL(pp.[product_plan_id],-1)=ISNULL(dc.[product_plan_id],-1) AND ISNULL(pp.[Product_Code_ID],-1)=ISNULL(dc.[Product_Code_ID],-1) 
	AND ISNULL(pp.[Product_Type_ID],-1)=ISNULL(dc.[Product_Type_ID],-1) AND pp.[vehicle_class] < dc.[vehicle_class]
	WHERE 1=1;  

------------------------------------------------
----- Stage 4: Final push on the output table  
------------------------------------------------
	SELECT Product_plan_sku_price_parameter_id, Make, Vehicle_Class, Vehicle_type, Finance_Amount_From, Finance_Amount_To,
	MSRP_From, MSRP_To, Vehicle_Selling_Price_From, Vehicle_Price_To, Gross_Cap_Cost_From, Gross_Cap_Cost_To, 
	Product_Plan_ID, Product_Code_ID, Product_Type_id, Rating_method, VSC_Surcharge_ID 
	FROM #price_parameter WHERE 1=1

RETURN

END
