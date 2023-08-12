########################## DB VERSION 2 WITH ADDED DATA ################################
USE ghostKitchenV2;

#How many different types of accounting transactions are being used in the transactions table?
SELECT COUNT(DISTINCT(actID)) AS UniqueAccountingTypes
	FROM transactions;

# How many rental revenue transactions have we received?
SELECT COUNT(actID) FROM transactions WHERE actID=441500;

# Show all accounting transaction types and the total amount
SELECT name, FORMAT(SUM(amount), 2) AS Total	
	FROM accounting
		JOIN transactions USING (actID)
	GROUP BY name;

#What is the total revenue received?
SELECT FORMAT(SUM(amount),2) AS TotalRentRec
	FROM transactions
    WHERE actID=441500;

#What is the total revenue received by year?
SELECT YEAR(transDate),FORMAT(SUM(amount),2) AS TotalRentRec
	FROM transactions
    WHERE actID=441500
    GROUP BY YEAR(transDate);

# What is the total revenue by location?
SELECT name AS AccountName,locName AS Location,FORMAT(SUM(RentRec),2) AS TotalRent
	FROM (SELECT actID,name,YEAR(transDate),locID,locName,SUM(amount) AS RentRec
			FROM transactions AS t
				JOIN accounting AS a USING(actID)
				JOIN spaces AS s USING (spaceID)
				JOIN location AS l ON s.locID=l.locationID
			GROUP BY actID,name,locID,locName,YEAR(transDate)
				HAVING actID=441500) AS sq
			GROUP BY name,locName;

# What is the average revenue (montly) generated for each location?
SELECT DISTINCT(locName),AVG(amount)OVER(Partition BY locName) AS AvgMonthlyRevenue
	FROM transactions AS t
		JOIN spaces AS s USING (spaceID)
        JOIN location AS l ON s.locID=l.locationID
	WHERE actID=441500;


# What are total expenses
SELECT FORMAT(SUM(amount),2) AS TotalExpenses
	FROM transactions
	WHERE actID!=441500;
    
# What are total expenses by year
SELECT YEAR(transDate),FORMAT(SUM(amount),2) AS TotalExpenses
	FROM transactions
	WHERE actID!=441500
    GROUP BY YEAR(transDate); 
    
# What are total expenses by year and Quarter
SELECT CONCAT(YEAR(transDate)," Qtr.",QUARTER(transDate)) AS "Year & Qtr",FORMAT(SUM(amount),2) AS TotalExpenses
	FROM transactions
	WHERE actID!=441500
    GROUP BY CONCAT(YEAR(transDate)," Qtr.",QUARTER(transDate));
     

### Show total income, total expenses, and total profit (income-expenses)
SELECT FORMAT(Income,2) AS Income,FORMAT(Expenses,2) AS Expenses,FORMAT(Income-Expenses,2) AS Profit
		FROM(SELECT DISTINCT(actID),SUM(amount)OVER() AS Income FROM transactions WHERE actID=441500) AS sq1,
				(SELECT SUM(amount) AS Expenses FROM transactions WHERE actID!=441500) as sq;

### Show total income, total expenses, and total profit (income-expenses) by location for all rental properties
SELECT sq4.locName,FORMAT(TotalIncome,2) AS TotalIncome,FORMAT(TotalExpenses,2) AS TotalExpenses,FORMAT(TotalIncome-TotalExpenses,2) AS TotalProfit
FROM(
		SELECT locName,sum(income) AS Totalincome
		FROM
			(SELECT actID,locName,SUM(amount) AS income
			FROM transactions
				JOIN spaces AS s USING (spaceID)
				JOIN location AS l ON s.locID=l.locationID
			GROUP BY actID,locName
				HAVING actID=441500 AND locName!='Home') AS sq1
			GROUP BY locName) AS sq2
JOIN
		(SELECT locName,sum(expenses) As Totalexpenses
		FROM
			(SELECT actID,locName,SUM(amount) AS expenses
			FROM transactions
				JOIN spaces AS s USING (spaceID)
				JOIN location AS l ON s.locID=l.locationID
			GROUP BY actID,locName
				HAVING actID!=441500 AND locName!='Home') AS sq3 
			GROUP BY locName) AS sq4 USING (locName)
            GROUP BY locName;

# Show all expenses for the home office and the amount per category
SELECT actID AS AccountID,name AS AccountName,locName AS Location,FORMAT(SUM(amount),0) AS TotalExpenses
	FROM transactions AS t
		JOIN spaces AS s USING (spaceID)
        JOIN location AS l ON s.locID=l.locationID
        JOIN accounting USING (actID)
	GROUP BY actID,locName
		HAVING locName='Home';

# Show all customers and their total rent due per month;
SELECT renterID AS RenterID, contactName AS ContactName,locName AS Location,spaceID AS SPaceRented,size, cost, FORMAT((size*cost),2) as TotalRent
	FROM renter
		JOIN spaces AS s USING(spaceID)
        JOIN location AS l ON l.locationID=s.locID;

# Which renter(s) pays the most rent?
SELECT renterID AS RenterID, contactName AS ContactName,locName AS Location,spaceID AS SpaceRented, size,cost,FORMAT((size*cost),2) as TotalRent
	FROM renter
		JOIN spaces AS s USING(spaceID)
        JOIN location AS l ON l.locationID=s.locID
        WHERE size*cost = (SELECT MAX(totalrent) 
							FROM 
							(SELECT renterID,(size*cost) AS totalrent
							FROM renter
							JOIN spaces USING(spaceID)
							GROUP BY renterID) AS sq)
        ORDER BY cost DESC;
        
        
        

# Show all late payments, who the contact is, and where they are renting
SELECT renterID AS RenterID, contactName AS ContactName,locName AS Location,spaceID AS SpaceRented,transDate AS TransactionDate
	FROM renter
		JOIN spaces USING(spaceID)
        JOIN location AS l ON l.locationID=spaces.locID
        JOIN transactions AS ri USING(spaceID)
	WHERE DAY(transDate)>1 and actID=441500;



# Show the late payer and the number of late payments
SELECT contactname AS ContactName,COUNT(*) AS CountofLatePayments
	FROM (SELECT renterID, contactName,locName,spaceID,transDate
			FROM renter
				JOIN spaces USING(spaceID)
				JOIN location AS l ON l.locationID=spaces.locID
				JOIN transactions AS t USING(spaceID)
			WHERE DAY(transDate)>1 AND actID=441500
			GROUP BY  renterID,contactName,locName,spaceID,transDate) AS sa
	GROUP BY contactName
	ORDER BY COUNT(*) DESC;
	
# Show all renters, the average rent received per person and the average revenue across all locations
SELECT renterID AS RenterID,contactName AS ContactName,locationID AS LocationID,locName AS Location,FORMAT(AVG(amount),2) AS 'Rent Received per Renter',
	(SELECT FORMAT(AVG(amount),2)
		FROM transactions WHERE actID=441500) AS 'Avg Rental Income'
	FROM renter
		JOIN spaces USING(spaceID)
        JOIN location AS l ON l.locationID=spaces.locID
        JOIN transactions AS t USING(spaceID)
	GROUP BY renterID;

# Show all rental locations, the average rent received per location and the average revenue across all locations
SELECT actID,locationID AS LocationID,locName AS Location,FORMAT(AVG(amount),2) AS 'Location Average',
	(SELECT FORMAT(AVG(amount),2)
		FROM transactions
        WHERE actID=441500) AS 'All Property Avg Rental Income'
	FROM location 
		JOIN spaces ON location.locationID=spaces.locID
		JOIN transactions AS t USING(spaceID)
	GROUP BY actID,locationID
		HAVING actID=441500;

# What states are the vendors we do business located in? 
SELECT DISTINCT(SUBSTRING_INDEX(vendAddress,', ',-1)) AS State
	FROM vendor;

# How many vendors are located in Nevada?
SELECT COUNT(DISTINCT(vendName)) AS VendorCount
	FROM vendor
    WHERE SUBSTRING_INDEX(vendAddress,', ',-1)='NV';
    
# How many vendors are located in Utah?
SELECT COUNT(DISTINCT(vendName)) AS VendorCount
	FROM vendor
    WHERE SUBSTRING_INDEX(vendAddress,', ',-1)='UT';
  
# What states are the vendors we do business located in? 
SELECT DISTINCT(SUBSTRING_INDEX(vendAddress,', ',-1)) AS State
	FROM vendor;
    
# How many vendors are located in Colorado?
 SELECT COUNT(DISTINCT(vendName)) AS ColoradoVendorCount
	FROM vendor
    WHERE SUBSTRING_INDEX(vendAddress,', ',-1)='CO';

# How many pieces of equipment do we have in the Denver location?
SELECT COUNT(*) DenverEquipmentCount
	FROM equipment AS e
		JOIN location AS l ON e.locID=l.locationID
	WHERE locName='Denver';
    
# What Vendor are we paying the most for equipment?
SELECT vendorID AS VendorID,vendName AS VendorName,venContact AS VendorContact,FORMAT(SUM(totalCost),2) AS 'Total Cost'
	FROM vendor
		JOIN expenses USING(vendorID)
        JOIN equipment USING(expenseID)
	GROUP BY vendorID
	ORDER BY SUM(totalCost) DESC
		LIMIT 1;


# Show every space an the number of equipment items at that space
SELECT spaceID AS SpaceID, COUNT(*) AS 'Equipment Count'
	FROM spaces AS s
		JOIN equipment USING(spaceID)
	GROUP BY spaceID;

# Show the every space and the number of equipment at each space that is over the average equipment amount
SELECT spaceID AS SpaceID, COUNT(*) AS 'Equipment Count Over Average Total Cost'
	FROM (SELECT equipID,spaceID,AVG(totalCost),(SELECT AVG(totalCost) AS OveralAverage FROM equipment)
			FROM equipment
            GROUP BY equipID,spaceID
				HAVING AVG(totalCost)>(SELECT AVG(totalCost) FROM equipment)) AS sq
		GROUP BY spaceID;


######################################################################################
################  FUNCTION CREATING PROPER CASE 	################################################
DROP FUNCTION IF EXISTS proper;
DELIMITER //
CREATE FUNCTION proper( str VARCHAR(128) )
RETURNS VARCHAR(128)
DETERMINISTIC
BEGIN
DECLARE c CHAR(1);
DECLARE s VARCHAR(128);
DECLARE i INT DEFAULT 1;
DECLARE bool INT DEFAULT 1;
DECLARE punct CHAR(17) DEFAULT ' ()[]{},.-_!@;:?/';
	SET s = LCASE( str );
	WHILE i <= LENGTH( str ) DO   
    BEGIN
		SET c = SUBSTRING( s, i, 1 );
		IF LOCATE( c, punct ) > 0 THEN SET bool = 1;
		ELSEIF bool=1 THEN
	BEGIN
		IF c >= 'a' AND c <= 'z' THEN
	BEGIN
		SET s = CONCAT(LEFT(s,i-1),UCASE(c),SUBSTRING(s,i+1));
		SET bool = 0;
	END;
		ELSEIF c >= '0' AND c <= '9' THEN SET bool = 0;
	END IF;
	END;
	END IF;
		SET i = i+1;
	END;
	END WHILE;
RETURN s;
END //
DELIMITER ;


	#Test Function
SELECT proper('bobby brown');

######################################################################################
################  TRIGGER USING CREATED FUNCTION	##############################
## trigger to normalize company name and contact name to proper case. 
DROP TRIGGER IF EXISTS ProperName_Before_Insert;
DELIMITER //
CREATE TRIGGER ProperName_Before_Insert
BEFORE INSERT ON renter
FOR EACH ROW
BEGIN
	SET NEW.companyName = proper(NEW.companyName);
    SET NEW.contactname= proper(NEW.contactName);
END//
delimiter ;
DROP TRIGGER Companyname_Before_Insert;

#testing trigger
INSERT INTO renter VALUES(10,'big daddy BBQ','DON barber','donbarber@yahoo.com',9,3);
#delteing test row
DELETE FROM renter WHERE renterID=10; 


######################################################################################
################ 	PROCEDURE AND FUNCTIONS		##############################
##
/*
Due to how our DB is set up, this was much easier way to do this type of proceedure
previously discussed procedures proved to be much too complex for me to figure out and wanted to get something.  My thought is that this could be 
a lookup procedure if someone needed to contact or konw something based on the company (by entering company name) by calling the procedure, then using.
the variables in any type of query.  Two queries below are for an employee lookup, showing the various access information and the other shwoing the last payment status.
PROCEDURE - Lookup company info based on entered company name (contact name, email, location, space no, lastpayment date) from a created view.

*/
######################################################################################
########## Create view of company info and transactions ######################
## create view for company information
DROP VIEW IF EXISTS CompanyInfo;
CREATE VIEW CompanyInfo AS
SELECT companyName,contactName, email, locName,t.spaceID AS spaceRented,
	(SELECT MAX(transDate) FROM transactions WHERE actID=441500) AS LastPaymentDate,raID
	FROM phys_access AS p
		LEFT JOIN location AS l ON p.locID=l.locationID
        LEFT JOIN spaces AS s ON l.locationID=s.locID
        LEFT JOIN renter AS r USING (spaceID)
        LEFT JOIN transactions AS t USING(raID)
	GROUP BY companyName,contactName, email,locName,t.spaceID, raID;
# test view
Select * FROM CompanyInfo;

######################################################################################
################  FUNCTION Full Name		##############################
## Function to contactinate the first name and last name
DROP FUNCTION IF EXISTS FullName;
DELIMITER //
CREATE FUNCTION FullName(firstName varchar(50), lastName varchar(50))
RETURNS varchar(100)
DETERMINISTIC
BEGIN
RETURN
concat(firstname,' ',lastName);
END//
DELIMITER ;
######################################################################################
#Test Function 
SELECT firstName,lastName,FullName(firstName,lastName) AS fullname
from phys_access;


######################################################################################
################  PROCEDURE		##############################
## Procedure to lookup company info from view based on entered company name
DROP PROCEDURE IF EXISTS CompanyInfo;
delimiter //
CREATE PROCEDURE CompanyInfo (IN coName varchar(50), OUT cName varchar(50), OUT mail varchar(100),OUT lName varchar(30),lspace INT,payDate DATETIME)
	BEGIN
		SET cName=(Select DISTINCT(contactName) FROM CompanyInfo
							WHERE coName=companyName);
		SET mail=(SELECT email FROM CompanyInfo
							WHERE coName=companyName);
		SET lName=(SELECT locName FROM CompanyInfo
							WHERE coName=companyName);
		SET lspace=(SELECT spaceRented FROM CompanyInfo
							WHERE coName=companyName);
		SET payDate=(SELECT LastpaymentDate FROM CompanyInfo
							WHERE coName=companyName);
	
	END//
delimiter ;

######################################################################################
################ QUERY USING PROCEDURE AND UDF	##############################
## Using the procedure to lookup the contact for a entered company name then using the contact name from prodcedure to find the people (employees) who have access
## uses the FullName function created just below it.
CALL CompanyInfo('Vegan Grass',@cName,@mail,@lName,@lspace,@payDate);
SELECT @cName,FullName(firstName,lastName) AS EmployeeName,status AS AccessStatus,locName AS location,spaceID AS rentedSpace,createDate,deactivateDate,updateDate
	FROM phys_access AS p
		INNER JOIN location AS l ON p.locID=l.locationID
		INNER JOIN spaces AS s ON l.locationID=s.locID
		INNER JOIN renter AS r USING (spaceID)
		WHERE contactName=@cName;

######################################################################################
################ 	FUNCTION	##############################
DROP FUNCTION IF EXISTS IsPaymentLate;
#Function to show if payment received is on-time,late, or too late
delimiter //
CREATE FUNCTION IsPaymentLate(paydate datetime) 
RETURNS varchar(30)
DETERMINISTIC
BEGIN
DECLARE isLate varchar(30);
CASE
	WHEN DAY(paydate)=1 THEN SET isLate = 'On-Time';
    WHEN DAY(paydate)>3 AND DAY(paydate) <=10 THEN SET isLate='Late';
	ELSE SET islate='Too Late, Terminate Access';
    END CASE;
RETURN(isLate);
END //
delimiter ;
#Test Function
SELECT companyName,contactname,transdate,isPaymentLate(transDate) AS PayStatus
	FROM renter AS r
		JOIN transactions AS t USING(raID);
        
################  QUERY #2 USING PROCEDURE AND UDF	##############################
## Query to look up if the last payment receieved by renter is on-time,late or too late
CALL CompanyInfo('Char B Que',@cName,@mail,@lName,@lspace,@payDate);
SELECT @cName,@mail,companyName,LastPaymentDate,isPaymentLate(LastpaymentDate) AS LastPaymentStatus,raID 
	FROM CompanyInfo
    WHERE contactName=@cName;
    
################  QUERY USING PROCEDURE AND UDF	##############################
##	Query to look up the count of payment status based on called procedure
##	could use this (or parts of it) as another query as well, just remove the HAVING
SELECT raID,contactName,isPaymentLate(transDate) AS PayStatus,COUNT(isPaymentLate(transDate))AS CountOfPayStatus
	FROM (SELECT raID,transDate,contactName
			FROM transactions
				JOIN renter USING(raID)) as sq   
	GROUP BY raID,contactName,isPaymentLate(transDate)
		HAVING contactName=@cName;

### 	CREATE View on for all payment information with location	###
CREATE VIEW transactionDetails AS
	SELECT actID as AccountID,name AS ActName,transDate,amount,locName AS Location,spaceID AS SpaceRented,contactName AS Contact
		FROM transactions
			JOIN spaces USING (spaceID)
			JOIN location AS l ON l.locationID=spaces.locID
			JOIN accounting USING (actID)
			JOIN renter USING (spaceID);
## test view
Select * FROM transactionDetails;

### 	CREATE View to see renter and renter account detail	###
CREATE VIEW RenterBankDetails AS
SELECT contactName, companyName,email,locName AS Location, spaceID AS SpaceRented,bankName AS BankName, accountNum AS AccountNumber,routingNumber AS RoutingNumber
	FROM renter 
		JOIN renter_account USING(raID)
        JOIN spaces AS s USING(spaceID)
        JOIN location AS l ON s.locID=l.locationID;
## test view
SELECT * FROM RenterBankDetails;

######################################################################################
### 	CREATE INDEX on Location Name	###
CREATE INDEX locName ON location(locName);
# 	Query using INDEX on Location Name	###
## How much was spent intially to acquire each property
SELECT actID,locName,SUM(amount);
######################################################################################
### 	CREATE INDEX on Access Status	###
CREATE INDEX status on phys_access(status);
SELECT CONCAT(firstName,' ',lastName), status FROM phys_access WHERE status = 'T';

