--  Assignment 1 --
-- Tablename - Account (Account number, CustomerName, Balance) --
-- Create 2 triggers one for every withdrawal and one for every deposit --
-- Create a procedure which lists the sum of all withdrawals in one column and all deposits in one column for a particular hour --

-- use your database--
use my_sql;

-- Account table creation --
create table Account (Account_No int primary key auto_increment, Customer_Name varchar(30) not null, Balance numeric(10,2));

-- Account_update table creation --
create table Account_udpate ( Acc_up_id int primary key auto_increment,
Account_No int not null ,
Customer_Name varchar(30) not null,
changed_at timestamp,
Before_bal numeric(10,2) not null,
After_bal numeric(10,2) not null,
Trans_type varchar(10) not null,
Trans_amt numeric(10,2) not null);

-- inserting the value inot Account table --
insert into Account(Customer_Name, Balance ) values('Gowrav',10000);

-- trigger for after_Account_update (debit) update on Account --
delimiter $$
create trigger after_Account_update_debit after update on Account for each row
begin
if(new.Balance<old.Balance) then
	insert into Account_udpate(Account_No , Customer_Name , changed_at , Before_bal , After_bal, Trans_type, Trans_amt ) 
	values(old.Account_No, old.Customer_Name, now(), old.Balance , new.Balance, 'Debit',-(old.Balance-new.Balance));
end IF;
end $$

-- trigger for after_Account_update (credit) update on Account --
delimiter $$
create trigger after_Account_update_credit after update on Account for each row
begin
if(new.Balance>old.Balance) then
	insert into Account_udpate(Account_No , Customer_Name , changed_at , Before_bal , After_bal, Trans_type, Trans_amt) 
	values(old.Account_No, old.Customer_Name, now(), old.Balance , new.Balance, 'Credit',+(new.Balance-old.Balance));
end IF;
end $$

-- update statemnt Account table --
update Account set Balance = (Balance-5000) where Account_No = 1;
update Account set Balance = (Balance+10000) where Account_No = 1;

-- dropping the both the triggers --
drop trigger after_Account_update_debit;
drop trigger after_Account_update_credit;

-- CREATE PROCEDURE Hourly_Sum -- 
DELIMITER //
CREATE PROCEDURE Hourly_Sum (IN Acc_No INT, OUT WD_Total numeric(10,2), OUT DP_Total numeric(10,2))
BEGIN
    SELECT sum(Trans_amt) INTO WD_Total FROM my_sql.Account_udpate
	WHERE Trans_type = 'Debit' AND Account_No = Acc_No AND changed_at >= Date_sub(now(),interval 1 hour);
    
    SELECT sum(Trans_amt) INTO DP_Total FROM my_sql.Account_udpate
	WHERE Trans_type = 'Credit' AND Account_No = Acc_No AND changed_at >= Date_sub(now(),interval 1 hour);
END //

-- DROP THE PROCEDURE --
DROP PROCEDURE Hourly_Sum;

-- CALLING THE PROCEDURE --
CALL Hourly_Sum(1, @WD_Total, @DP_Total);

-- DISPLAYING THE CALLED PROCEDURE --
SELECT @WD_Total, @DP_Total;

-- CREAETING EVENT One_Hr_Event TO CALL PROCEDURE Hourly_Sum --
CREATE EVENT One_Hr_Event
    ON SCHEDULE EVERY 1 minute
    DO
      CALL Hourly_Sum(1, @WD_Total, @DP_Total);
	SELECT @WD_Total, @DP_Total;
    
-- DROP THR EVENT One_Hr_Event --
DROP EVENT One_Hr_Event;
