-- STEP 1:
----- CREATING  DATABASE 'Datawarehouse'

USE master;

create database Datawarehouse;

use Datawarehouse;

create schema bronze;
go
create schema silver;
go
create schema gold;

-- STEP 2:
---- TABLE CREATION 
create table bronze.crm_cust_info (
	cst_id int,
	cst_key nvarchar(50),
	cst_firstname nvarchar(50),
	cst_lastname nvarchar(50),
	cst_marital_status nvarchar(50),
	cst_gndr nvarchar(50),
	cst_create_date date
);

create table bronze.crm_prd_info(
	prd_id int ,
	prd_key nvarchar(50),
	prd_nm nvarchar(50),
	prd_cost int ,
	prd_line nvarchar(50),
	prd_start_dt  datetime ,
	prd_end_dt datetime
);

create table bronze.crm_sales_details (
	sls_ord_num nvarchar(50),
	sls_prd_key nvarchar(50),
	sls_cust_id int,
	sls_order_dt int,
	sls_ship_dt int,
	sls_due_dt int,
	sls_sales int,
	sls_quantity int ,
	sls_price int
);

create table bronze.erp_loc_a101(
	cid nvarchar(50),
	cntry nvarchar(50)
);

create table bronze.erp_cust_az12 (
	cid nvarchar(50),
	bdate date,
	gen nvarchar(50)
);



create table bronze.erp_px_cat_g1v2 (
	id          nvarchar(50),
	cat         nvarchar(50),
	subcat      nvarchar(50),
	maintenance nvarchar(50)
);


-- STEP 3:

CREATE or ALTER PROCEDURE bronze.load_bronze as
BEGIN 
	DECLARE @START_TIME DATETIME, @END_TIME DATETIME
	BEGIN TRY
		PRINT '=============================================================='
		PRINT 'LOADING BRONZE LAYER' ;
		PRINT '=============================================================='

		PRINT '--------------------------------------------------------------'
		PRINT 'LOADING CRM TABLES' ;
		PRINT '--------------------------------------------------------------'
	    
		SET @START_TIME = GETDATE();
		PRINT '>> TRUNCATTING TABLE: bronze.crm_cust_info'
		Truncate table bronze.crm_cust_info
	
		PRINT '>> INSERTING DATA INTO: bronze.crm_cust_info'
		bulk insert bronze.crm_cust_info
	
		from 'C:\Users\HP\Desktop\sql scv files\source_crm\cust_info.csv'
		with (
			firstrow = 2,
			fieldterminator = ',',
			tablock
		);
        SET @END_TIME = GETDATE();
		PRINT '>> LOAD DURATION: ' + CAST(DATEDIFF(SECOND, @START_TIME,@END_TIME) AS NVARCHAR) + ' SECONDS';
		PRINT '>> -----------------';
		
		
		SET @START_TIME = GETDATE();
		PRINT '>> TRUNCATING TABLE: bronze.crm_prd_info'
		Truncate table bronze.crm_prd_info
	
		PRINT '>> INSERTING DATA INTO: bronze.crm_prd_info'
		bulk insert bronze.crm_prd_info
		from 'C:\Users\HP\Desktop\sql scv files\source_crm\prd_info.csv'
		with (
			firstrow = 2,
			fieldterminator = ',',
			tablock
		);
		SET @END_TIME = GETDATE();
		PRINT '>> LOAD DURATION: ' + CAST(DATEDIFF(SECOND, @START_TIME,@END_TIME) AS NVARCHAR) + ' SECONDS';
		PRINT '>> -----------------';


		SET @START_TIME = GETDATE();
		PRINT '>> TRUNCATING TABLE: bronze.crm_sales_details'
		Truncate table bronze.crm_sales_details
	
		PRINT '>> INSERTING DATA INTO: bronze.crm_sales_details'
		bulk insert bronze.crm_sales_details
		from 'C:\Users\HP\Desktop\sql scv files\source_crm\sales_details.csv'
		with (
			firstrow = 2,
			fieldterminator = ',',
			tablock
		);
		SET @END_TIME = GETDATE();
		PRINT '>> LOAD DURATION: ' + CAST(DATEDIFF(SECOND, @START_TIME,@END_TIME) AS NVARCHAR) + ' SECONDS';
		PRINT '>> -----------------';


		SET @START_TIME = GETDATE();
		PRINT '>> TRUNCATING TABLE: bronze.erp_cust_az12'
		Truncate table bronze.erp_cust_az12
	
		PRINT '>> INSERTING DATA INTO: bronze.erp_cust_az12'
		bulk insert bronze.erp_cust_az12
		from 'C:\Users\HP\Desktop\sql scv files\source_erp\CUST_AZ12.csv'
		with (
			firstrow = 2,
			fieldterminator = ',',
			tablock
		);
		SET @END_TIME = GETDATE();
		PRINT '>> LOAD DURATION: ' + CAST(DATEDIFF(SECOND, @START_TIME,@END_TIME) AS NVARCHAR) + ' SECONDS';
		PRINT '>> -----------------';

		
		SET @START_TIME = GETDATE();
		PRINT '>> TRUNCATING TABLE: bronze.erp_loc_a101'
		Truncate table bronze.erp_loc_a101
	
		PRINT '>> INSERTING DATA INTO: bronze.erp_loc_a101'
		bulk insert bronze.erp_loc_a101
		from 'C:\Users\HP\Desktop\sql scv files\source_erp\LOC_A101.csv'
		with (
			firstrow = 2,
			fieldterminator = ',',
			tablock
		);
		SET @END_TIME = GETDATE();
		PRINT '>> LOAD DURATION: ' + CAST(DATEDIFF(SECOND, @START_TIME,@END_TIME) AS NVARCHAR) + ' SECONDS';
		PRINT '>> -----------------';

        SET @START_TIME = GETDATE();
		PRINT '>> TRUNCATING TABLE: bronze.erp_px_cat_g1v2'
		Truncate table bronze.erp_px_cat_g1v2
	
		PRINT '>> INSERTING DATA INTO: bronze.erp_px_cat_g1v2'
		bulk insert bronze.erp_px_cat_g1v2
		from 'C:\Users\HP\Desktop\sql scv files\source_erp\PX_CAT_G1V2.csv'
		with (
			firstrow = 2,
			fieldterminator = ',',
			tablock
		);
		SET @END_TIME = GETDATE();
		PRINT '>> LOAD DURATION: ' + CAST(DATEDIFF(SECOND, @START_TIME,@END_TIME) AS NVARCHAR) + ' SECONDS';
		PRINT '>> -----------------';

        ---- TOTAL LOADING DURATION
		
		SET @END_TIME = GETDATE();
		PRINT '=============================================================='
		PRINT 'LOADING BRONZE LAYER IS COMPLETED'
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










