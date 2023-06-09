USE [SGEAS_DIFF]
GO
/****** Object:  StoredProcedure [dbo].[get_Rating_SurchargeDetails]    Script Date: 10/6/2022 7:08:34 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- drop procedure get_Rating_SurchargeDetails
/*********************************************************************************************
** Name: [get_Rating_SurchargeDetails]
** Desc: Stored Procedure to get all the Surcharge Information without Class details  
** Auth: Arvind 
** Date: 06/24/2021
**************************
** Change History
**************************
** CR   Date			Author          Description	
** --   --------        -------         ------------------------------------
** 1    22/08/22        Ananthi         INT-191 - GetSpecific reorg
*********************************************************************************************/
ALTER   PROCEDURE [dbo].[get_Rating_SurchargeDetails]
(@ai_program_id INT, @ad_sale_date DATE, @li_engine_aspiration_id BIGINT=NULL, @li_engine_fuel_type_id BIGINT=NULL,
@dpc DealerProductCode READONLY, @Contract_Surcharge ContractSurcharge READONLY, @as_Calling_Procedure VARCHAR(255))
AS
BEGIN
		
--------------------------------------
----- Stage 1: Declarations 
--------------------------------------
		CREATE TABLE #sc_non_class 
		(Program_ID INT, Product_Type_ID BIGINT, Product_code_ID BIGINT, VSC_Surcharge_ID BIGINT, Surcharge VARCHAR(100),
		--Model_ID BIGINT, Make_ID BIGINT, Trim_Level_ID BIGINT, Drive_Type_ID BIGINT, 
		Classing_Method VARCHAR(25))

		CREATE TABLE #sc
		(Program_ID INT, Product_Type_ID BIGINT, Product_code_ID BIGINT, VSC_Surcharge_id BIGINT, Surcharge VARCHAR(100), 
		Classing_Method VARCHAR(25))
--------------------------------------
----- Stage 2: Data Insertion for different Engine parameters  
--------------------------------------
		IF (UPPER(@as_Calling_Procedure) = 'GETEVERYTHING' OR UPPER(@as_Calling_Procedure) = 'GETSPECIFICPRODUCT')        --- INT-191
		BEGIN 
			INSERT INTO #sc_non_class 
			(Program_ID, Product_Type_id, Product_code_id, Vsc_surcharge_id, Surcharge, Classing_Method)
			SELECT DISTINCT pc.Program_ID, [pc].[product_type_id], [pc].[product_code_id], [vsc].[vsc_surcharge_id], [vsc].[name] AS [surcharge], 
			CONVERT(VARCHAR(25),'NO CLASS') classing_method   
			FROM [vsc_surcharge] AS [vsc]  (NOLOCK) 
			INNER JOIN @dpc dpc ON [vsc].Product_Code_ID = dpc.Product_Code_ID
			INNER JOIN Ref_Product_Code pc (NOLOCK) ON dpc.Product_Code_ID = pc.Product_Code_id 
			WHERE vsc.Is_Derivable_From_VIN  = 'N';
		END 
		ELSE IF (UPPER(@as_Calling_Procedure) ='SAVE_ECONTRACT_VALIDATION')
		BEGIN
			INSERT INTO #sc_non_class 
			(Program_ID, Product_Type_id, Product_code_id, Vsc_surcharge_id, Surcharge, Classing_Method)
			SELECT DISTINCT pc.Program_ID, pc.product_type_id, pc.product_code_id, vsc.vsc_surcharge_id, vsc.[name], 
			CONVERT(VARCHAR(25),'NO CLASS') classing_method 
			FROM vsc_surcharge AS vsc  (NOLOCK) 
			INNER JOIN @dpc dpc ON vsc.Product_Code_ID = dpc.Product_Code_ID 
			INNER JOIN Ref_Product_Code pc (NOLOCK) ON dpc.Product_Code_ID = pc.Product_Code_id
			INNER JOIN @Contract_Surcharge cs ON vsc.VSC_Surcharge_ID = cs.surchargeKey
			WHERE vsc.Is_Derivable_From_VIN  = 'N'
		END

		------ ENGINEASPIRATION --------
		INSERT INTO #sc_non_class
		(Program_ID, Product_Type_id, Product_code_id, Vsc_surcharge_id, Surcharge, Classing_Method)			
		SELECT DISTINCT [pvcm].[program_id], [pvcm].[product_type_id], [pvcm].[product_code_id], [vsc].[vsc_surcharge_id], 
		[vsc].[name] AS [surcharge], cm.name AS [classing_method] 
		FROM [program_vehicle_class_mapping] AS [pvcm]  (nolock) 
		INNER JOIN [program_vehicle_class] AS [pvc]  (nolock) 
			ON [pvcm].[program_vehicle_class_id] = [pvc].[program_vehicle_class_id]  
		INNER JOIN [program_classing_method] AS [pcm]  (nolock) 
			ON [pvcm].[program_classing_method_id] = [pcm].[program_classing_method_id]
		INNER JOIN [ref_classing_method] AS [cm] (nolock) 
			ON [pcm].[classing_method_id] = [cm].[classing_method_id]
		INNER JOIN [vsc_surcharge_applicable_class] AS [vsac]  (nolock) 
			ON [vsac].[program_vehicle_class_id] = [pvc].[program_vehicle_class_id]
		INNER JOIN [vsc_surcharge] AS [vsc]  (nolock) 
			ON [vsac].[vsc_surcharge_id] = [vsc].[vsc_surcharge_id]
		WHERE [pvc].[is_surcharge] = 'Y' AND [cm].[name] = 'ENGINEASPIRATION' 
		AND [pvcm].[program_id] = @ai_program_id 
		AND @ad_sale_date BETWEEN [pvcm].[effective_date] AND [pvcm].[expiration_date] 
		AND @ad_sale_date BETWEEN [pcm].[effective_date] AND [pcm].[expiration_date] 
		AND PVCM.Engine_Fuel_Type_ID IS NULL 
		AND (ISNULL([pvcm].Engine_Aspiration_Type_ID , -1) = @li_engine_aspiration_id 
			OR ISNULL([pvcm].Engine_Aspiration_Type_ID, -1) = -1); 

		----- FUELTYPEENGINEASPIRATION -----  
		INSERT INTO #sc_non_class
		SELECT DISTINCT pvcm.program_id, pvcm.product_type_id, pvcm.product_code_id, vsc.vsc_surcharge_id, 
		vsc.[name] AS surcharge, cm.[name] AS classing_method  
		FROM program_vehicle_class_mapping pvcm  (NOLOCK) 
		INNER JOIN program_vehicle_class  pvc (NOLOCK) 
			ON pvcm.program_vehicle_class_id = pvc.program_vehicle_class_id
		INNER JOIN program_classing_method  pcm (NOLOCK) 
			ON pvcm.program_classing_method_id = pcm.program_classing_method_id
		INNER JOIN ref_classing_method cm (NOLOCK) 
			ON pcm.classing_method_id = cm.classing_method_id
		INNER JOIN vsc_surcharge_applicable_class AS vsac  (NOLOCK) 
			ON vsac.program_vehicle_class_id = pvc.program_vehicle_class_id
		INNER JOIN vsc_surcharge  vsc  (NOLOCK) 
			ON vsac.vsc_surcharge_id = vsc.vsc_surcharge_id
		WHERE pvc.is_surcharge = 'Y' AND cm.[name] = 'FUELTYPEENGINEASPIRATION' 
		AND pvcm.program_id = @ai_program_id 
		AND @ad_sale_date BETWEEN pvcm.effective_date AND pvcm.expiration_date 
		AND @ad_sale_date BETWEEN pcm.effective_date AND pcm.expiration_date 
		AND (ISNULL(pvcm.Engine_Aspiration_Type_ID , -1) = @li_engine_aspiration_id  
				OR ISNULL(pvcm.Engine_Aspiration_Type_ID, -1) = -1) 
		AND (ISNULL(pvcm.engine_fuel_type_id, -1) = @li_engine_fuel_type_id 
				OR  ISNULL(pvcm.engine_fuel_type_id, -1) = -1) ;  

		------ Fueltype -----
		INSERT INTO #sc_non_class		
		SELECT DISTINCT pvcm.program_id, pvcm.product_type_id, pvcm.product_code_id, vsc.vsc_surcharge_id, 
		vsc.[name] surcharge, cm.[name] classing_method  
		FROM program_vehicle_class_mapping pvcm (NOLOCK) 
		INNER JOIN program_vehicle_class pvc  (NOLOCK) 
			ON pvcm.program_vehicle_class_id = pvc.program_vehicle_class_id
		INNER JOIN program_classing_method pcm  (NOLOCK) 
			ON pvcm.[program_classing_method_id] = pcm.program_classing_method_id
		INNER JOIN ref_classing_method  cm  (NOLOCK) 
			ON pcm.classing_method_id = cm.classing_method_id
		INNER JOIN vsc_surcharge_applicable_class  vsac (NOLOCK) 
			ON vsac.program_vehicle_class_id = pvc.program_vehicle_class_id
		INNER JOIN vsc_surcharge vsc (NOLOCK)  
			ON vsac.VSC_Surcharge_ID = vsc.vsc_surcharge_id
		WHERE pvc.is_surcharge = 'Y' AND cm.[name] = 'FUELTYPE' 
		AND pvcm.program_id = @ai_program_id 
		AND @ad_sale_date BETWEEN pvcm.effective_date AND pvcm.expiration_date 
		AND @ad_sale_date BETWEEN pcm.effective_date AND pcm.expiration_date 
		AND pvcm.Engine_Aspiration_Type_ID  is null 
		AND (ISNULL(pvcm.engine_fuel_type_id, -1) = @li_engine_fuel_type_id 
			OR ISNULL(pvcm.engine_fuel_type_id, -1) = -1);  

--------------------------------
---- Stage 3: Extract the Surcharge from the extracts into the #sc table  
---------------------------------		
		INSERT INTO #sc 
		(Program_ID, Product_Type_ID, Product_Code_ID, Vsc_Surcharge_ID, Surcharge, Classing_Method)
		SELECT DISTINCT program_id, product_type_id, product_code_id, vsc_surcharge_id, surcharge, classing_method   
		FROM [#sc_non_class] WHERE 1=1;
		
		-- Eliminate the Diesel Surcharge if Both Turbo & Diesel is added   
		DELETE sc FROM #sc sc   
		WHERE EXISTS (SELECT 1 FROM #sc sc1 
			WHERE sc1.Product_Code_id = sc.Product_Code_id   
			AND sc.surcharge = 'Diesel' AND sc1.surcharge = 'Turbo Charged & Diesel')  

		-- Eliminate the Turbo Surcharge if Both Turbo & Diesel is added   
		DELETE sc FROM #sc sc   
		WHERE EXISTS (SELECT 1 FROM #sc sc1 
				WHERE sc1.Product_Code_id = sc.Product_Code_id   
				AND sc.surcharge = 'Turbo Charged' AND sc1.surcharge = 'Turbo Charged & Diesel') 

--------------------------------
---- Stage 4: Returning the results 
---------------------------------
		SELECT Program_ID, Product_Type_id, Product_code_id, Vsc_surcharge_id, Surcharge, Classing_Method 
		FROM #sc WHERE 1=1 
		
RETURN
END
