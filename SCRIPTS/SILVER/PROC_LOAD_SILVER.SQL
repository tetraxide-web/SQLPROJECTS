  /*
  =======================================================================
  STORED PROCEDURE: LOAD SILVER LAYER (BRONZE-> SILVER)
  =======================================================================
  SCRIPT PURPOSE
      THIS STORED PROCEDURE  PERFORMS THE ETL (EXTRACT, TRANSFORM, LOAD) PROCESSS
      TO POPULATE THE 'SILVER' SCHEMA TABLES FROPM THE 'BRONZE' SCHEMA. 
      ACTIONS PERFORMED
        -TRUNCATE THE SILVER TABLES .
        -INSERTS TRANSFORMED AND CLEANED DATA CFROM BRONZE INTO SILVERS TABLES.
  
  PARAMETERS:
    NONE.
    THIS STORED PROCEDURE DOESNT ACCEPT ANY PARAMETERS OR RETURN ANY VALUES.
  
  USAGE EXAMPLES:
     EXEC SILVER.LOAD_SILVER;
  =========================================================================================
  /*



CREATE or alter  PROCEDURE SILVER.LOAD_SILVER AS
BEGIN 
  	DECLARE @START_TIME DATETIME, @END_TIME DATETIME, @BATCH_START_TIME DATETIME, @BATCH_END_TIME DATETIME;
  	BEGIN TRY
	SET @BATCH_START_TIME = GETDATE();
  		PRINT '=============================================================='
  		PRINT 'LOADING SILVER LAYER' ;
  		PRINT '=============================================================='
  
  		PRINT '--------------------------------------------------------------'
  		PRINT 'LOADING CRM TABLES' ;
  		PRINT '--------------------------------------------------------------'


----  LOADING silver.crm_cust_info  done
SET @START_TIME = GETDATE();
print' >> TRUNCATING TABLE :  silver.crm_cust_info';
TRUNCATE TABLE  silver.crm_cust_info;
PRINT '>> Inserting Data into: silver.crm_cust_info';
Insert into silver.crm_cust_info(
    cst_id ,
	cst_key ,
	cst_firstname ,
	cst_lastname ,
	cst_marital_status ,
	cst_gndr ,
	cst_create_date 
)
select
    cst_id,
	cst_key,
	TRIM(cst_firstname) AS cst_firstname,
	TRIM(cst_lastname) AS cst_lastname,
	CASE 
	   WHEN UPPER(TRIM(cst_marital_status)) ='S' THEN 'Single'
	   WHEN UPPER(TRIM(cst_marital_status)) ='M' THEN 'Married'
	   ELSE 'N/A'
	END AS cst_marital_status,
	CASE 
	   WHEN UPPER(TRIM(cst_gndr)) ='F' THEN 'Female'
	   WHEN UPPER(TRIM(cst_gndr)) ='M' THEN 'Male'
	   ELSE 'N/A'
	END AS cst_gndr,
	cst_create_date
from(
    select
	*,
	  ROW_NUMBER() OVER (PARTITION BY cst_id order by cst_create_date desc) as flag_last
	  from bronze.crm_cust_info
	  where cst_id is not null 
	)t

	where flag_last = 1;
	
	SET @END_TIME = GETDATE();
	PRINT '>> LAOD DURATION: ' + CAST(DATEDIFF(SECOND,@START_TIME,@END_TIME) AS NVARCHAR) + 'SECONDS';
	PRINT '>> ----------';
 
 ---------  crmprdinfo   done
SET @START_TIME = GETDATE();
print' >> TRUNCATING TABLE : silver.crm_prd_info';
TRUNCATE TABLE  silver.crm_prd_info;
PRINT '>> Inserting Data into: silver.crm_prd_info';
Insert into silver.crm_prd_info (
	prd_id,
	prd_key,
	cat_id,
	prd_nm,
	prd_cost,
	prd_line,
	prd_start_dt,
	prd_end_dt 
)
select
    prd_id ,
	REPLACE(SUBSTRING(prd_key, 1, 5), '-', '_') AS cat_id, --	EXTRACT CATEGORY ID
	SUBSTRING(prd_key,7 , len(prd_key)) AS prd_key,        --   EXTRACT PRODUCT KEY
	prd_nm ,
	ISNULL (prd_cost, 0) as prd_cost,
	case  upper(trim(prd_line))
	     when 'M' then 'MOUNTAIN'
	     when 'R' then 'ROAD'
	     when 'S' then 'OTHER SALES'
	     when 'T' then 'TOURING'
		 ELSE 'N/A'
	END AS PRD_LINE,   -- MAP PRODUCT LINE CODES TO DESCRIPTIVE VALUES
	CAST(prd_start_dt AS DATE) AS prd_start_dt,
	CAST(
	     lead(prd_start_dt) over ( partition by prd_key order by prd_start_dt) -1  AS DATE
	)AS prd_end_dt  -- CALCULATE END DATE AS ONE DAY BEFORE THE NEXT START DATE  
from bronze.crm_prd_info;
SET @END_TIME = GETDATE();
PRINT '>> LAOD DURATION: ' + CAST(DATEDIFF(SECOND,@START_TIME,@END_TIME) AS NVARCHAR) + 'SECONDS';
PRINT '>> ----------';
 
 
 
 -----------sales details done
SET @START_TIME = GETDATE();
print' >> TRUNCATING TABLE : silver.crm_sales_details';
TRUNCATE TABLE  silver.crm_sales_details;
PRINT '>> Inserting Data into: silver.crm_sales_details';
Insert into silver.crm_sales_details (
    sls_ord_num,
	sls_prd_key,
	sls_cust_id ,
	sls_order_dt,
	sls_ship_dt ,
	sls_due_dt,
	sls_sales ,  
	sls_quantity,
	sls_price
 ) 
  select
  sls_ord_num,
  sls_prd_key,
  sls_cust_id,
  CASE WHEN sls_order_dt = 0 OR LEN(sls_order_dt) !=8 THEN NULL
       ELSE CAST( CAST(sls_order_dt AS varchar) AS DATE )
  END AS sls_order_dt, 
  
  CASE WHEN sls_ship_dt = 0 OR LEN(sls_ship_dt) !=8 THEN NULL
       ELSE CAST( CAST(sls_ship_dt AS varchar) AS DATE )
  END AS sls_ship_dt, 
  
  CASE WHEN sls_due_dt = 0 OR LEN(sls_due_dt) !=8 THEN NULL
     ELSE CAST( CAST(sls_due_dt AS varchar) AS DATE )
  END AS sls_due_dt, 
  
  case when sls_sales is null or sls_sales <=0 or sls_sales != sls_quantity * ABS(sls_price)
          then sls_quantity * ABS(sls_price)
  else sls_sales
END AS sls_sales,
sls_quantity,
CASE WHEN sls_price is null or sls_price <=0 
     then sls_sales/nullif(sls_quantity,0)
   else sls_price
end as sls_price
from bronze.crm_sales_details

SET @END_TIME = GETDATE();
PRINT '>> LAOD DURATION: ' + CAST(DATEDIFF(SECOND,@START_TIME,@END_TIME) AS NVARCHAR) + 'SECONDS';
PRINT '>> ----------';

------LOADING ERPaziz done
SET @START_TIME = GETDATE();
print' >> TRUNCATING TABLE :  silver.erp_cust_az12';
TRUNCATE TABLE  silver.erp_cust_az12;
PRINT '>> Inserting Data into:silver.erp_cust_az12';
Insert silver.erp_cust_az12(
cid,
bdate,
gen
)
select
	CASE
	    WHEN CID LIKE 'NAS%' THEN SUBSTRING(CID, 4, LEN(CID))
	     ELSE CID
	END as CID,
	
	case when bdate > getdate() then null
	     else bdate
	end as bdate,
	
	case 
	     when UPPER(TRIM(gen)) IN ('F', 'FEMALE')  then 'Female'
         when UPPER(TRIM(gen)) IN ('M', 'MALE')  then 'Male'
	 else 'n/a'
End as gen 
from bronze.erp_cust_az12;
SET @END_TIME = GETDATE();
PRINT '>> LAOD DURATION: ' + CAST(DATEDIFF(SECOND,@START_TIME,@END_TIME) AS NVARCHAR) + 'SECONDS';
PRINT '>> ----------';


--------- a101 done

SET @START_TIME = GETDATE();
print' >> TRUNCATING TABLE :  silver.erp_loc_a101';
TRUNCATE TABLE  silver.erp_loc_a101;
PRINT '>> Inserting Data into:silver.erp_loc_a101';
Insert silver.erp_loc_a101
(
cid,
cntry
)
select
    replace(cid, '-', '') as cid,
	case when TRIM(CNTRY) = 'DE' THEN 'GERMANY'
	     when TRIM(CNTRY) IN ('US', 'USA')  THEN 'United States'
		 when TRIM(CNTRY) = '' or cntry is null THEN 'n/a'
		 else TRIM(cntry)
end as 	cntry 
from bronze.erp_loc_a101
SET @END_TIME = GETDATE();
PRINT '>> LAOD DURATION: ' + CAST(DATEDIFF(SECOND,@START_TIME,@END_TIME) AS NVARCHAR) + 'SECONDS';
PRINT '>> ----------';


-------------------g1v2  done
SET @START_TIME = GETDATE();
print' >> TRUNCATING TABLE :  silver.erp_px_cat_g1v2';
TRUNCATE TABLE  silver.erp_px_cat_g1v2;
PRINT '>> Inserting Data into: silver.erp_px_cat_g1v2'
Insert into silver.erp_px_cat_g1v2
(
id,
cat,
subcat,
maintenance
)
select 	
	id ,
	cat ,
	subcat  ,
	maintenance 
	from bronze.erp_px_cat_g1v2
SET @END_TIME = GETDATE();
PRINT '>> LAOD DURATION: ' + CAST(DATEDIFF(SECOND,@START_TIME,@END_TIME) AS NVARCHAR) + 'SECONDS';
PRINT '>> ----------';


  		
  		SET @END_TIME = GETDATE();
  		PRINT '=============================================================='
  		PRINT 'LOADING SILVER LAYER IS COMPLETED'
  		PRINT ' - TOTAL LOAD DURATION: ' + CAST(DATEDIFF(SECOND, @START_TIME,@END_TIME) AS NVARCHAR) + ' SECONDS';
  		PRINT '=============================================================='
  
  		END TRY
  		BEGIN CATCH
  		PRINT '=============================================================='
  		PRINT 'ERROR OCCURED DURING LOADING BRONZE LAYER' 
  		PRINT 'ERROR MESSAGE' + ERROR_MESSAGE();
  		PRINT 'ERROR MESSAGE' + CAST(ERROR_NUMBER() AS NVARCHAR);
  		PRINT 'ERROR MESSAGE' + CAST(ERROR_STATE() AS NVARCHAR);
  		PRINT '=============================================================='
  		END CATCH

END











