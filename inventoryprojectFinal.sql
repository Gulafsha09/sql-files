-- creating database inventory

create database Inventory;
use inventory;

create function ID (@A as char(1),@I as int)
returns char(5)
as
begin
	declare @ID as char(5);
	if @I<10
		set @ID=concat(@A,'000',@I)
	else if @I<100
		set @ID=concat(@A,'00',@I)
	else if @I<1000
		set @ID=concat(@A,'0',@I)
	else if @I<10000
		set @ID=concat(@A,@I)
	else
		set @ID='NA'

	return @ID
end;

drop function ID;


-- creating a table with details of supplier of products and inserting values with the help of procedure and generating Id with the help of sequence 

create sequence SSEQ
as int
start with 1
increment by 1;

drop sequence sseq;
drop table supplier;


create table supplier(
SID CHAR(5), SNAME VARCHAR(30) NOT NULL,
SADD VARCHAR (40) NOT NULL, SCITY VARCHAR (15) DEFAULT ('DELHI'),
SPHONE VARCHAR (15) UNIQUE, SEMAIL VARCHAR (40));


create procedure addsupplier @N as varchar(30),@Add as varchar(40),@C as varchar(15),@P as varchar(15),@E as varchar(40)
as
begin
	declare @SID as char(5);
	declare @I as int;
	set @I= (next value for sseq)
	set @SID=dbo.id('S',@I);
	
	insert into supplier
	values(@SID,@N,@ADD,@C,@P,@E);

	select * from supplier;
end;


addsupplier 'RAHUL ARORA', 'B302-Jay Maa Apt,Dwarka,Delhi','DELHI','9891720767','arorarahul89@gmail.com';


ALTER TABLE SUPPLIER
ALTER COLUMN SID CHAR(5) NOT NULL;

ALTER TABLE SUPPLIER
ADD CONSTRAINT pkID PRIMARY KEY (SID);


Select * from supplier;

-- creating a table for product's details

create sequence pseq
as int
start with 1
increment by 1;

create table products(
PID CHAR(5),PDESC VARCHAR(50) NOT NULL,
PRICE INT CHECK (PRICE >0),
CATEGORY VARCHAR (30) CHECK ( CATEGORY IN ('IT','HA','HC')),
SID CHAR(5));

ALTER TABLE PRODUCTS
ALTER COLUMN PID CHAR(5) NOT NULL;

ALTER TABLE PRODUCTS
ADD CONSTRAINT pkID1 PRIMARY KEY (PID);

create procedure addproducts @Desc as varchar(50),@Price as int,@Cat as varchar(30),@Sid as char(5)
as
begin
	declare @PID as char(5);
	declare @I as int;
	set @I= (next value for pseq)
	set @PID=dbo.id('P',@I);
	

	insert into products
	values(@PID,@Desc,@PRICE,@CAT,@SID);

	select * from products;
end;


addproducts 'STOVE',4000,'HA','S0007';


SELECT * FROM PRODUCTS;


alter table products
add constraint fkID foreign key (SID) REFERENCES SUPPLIER (SID);


-- creating a table for stock details

create table stock(
PID char(5),SQTY INT CHECK (SQTY>=0),
ROL INT CHECK (ROL >0), MOQ INT CHECK (MOQ>=5));



create procedure instock @PID as char(5), @Sqty as int, @Rol as int, @Moq as int
as
begin
	insert into stock
	values (@PID,@Sqty,@Rol,@Moq);

	select * from stock;
end;

instock 'P0010',50,15,10;

update stock set SQTY=2500
where PID='P0010';

alter table stock
add constraint fkID1 foreign key (PID) REFERENCES products (PID);

select * from stock;

-- creating a table for customer details

create sequence cseq
as int
start with 9
increment by 1;

drop sequence cseq;

create table customer(
CID CHAR(5) primary key, CNAME VARCHAR(30) NOT NULL,
CADD VARCHAR (40) NOT NULL, CCITY VARCHAR (15) not null,
CPHONE VARCHAR (15) not null, CEMAIL VARCHAR (40) not null,DOB date check (DOB< 'JAN 01,2000'));


select* from customer;


create procedure addcustomer @N as varchar(30), @Add as varchar(40), @C as varchar(15), @P as varchar(15), @E as varchar(40), @DB as date
as
begin
	declare @I as int;
	declare @CID as char(5);
	set @I= (next value for cseq);
	set @CID=dbo.id('C',@I);

	insert into customer
	values(@CID,@N,@Add,@C,@P,@E,@Db);

	select * from customer;
end;

drop procedure addcustomer;

addcustomer 'kush chabra','SECTOR 31,GURGAON','gurgaon','9891720821','kush@gmail.com','dec 8,1986';
-- creating a table for Order details
create sequence oseq
as int
start with 1
increment by 1;
drop sequence oseq;

create table orders(
OID CHAR(5),ODATE date, 
PID CHAR (5), CID CHAR (5),
OQTY INT CHECK (OQTY >=1));


create procedure addorders  @Pid as char(5),@Cid as char(5),@Oqty as int
as
begin
	declare @I as int;
	declare @OID as char(5);
	declare @D as date;
	set @D= CONVERT(VARCHAR(10), getdate(), 111);

	set @I=(next value for oseq)
	set @OID=dbo.id('O',@I)

	insert into orders
	values(@OID,@D,@PID,@CID,@OQTY);

	select * from orders;
end;
drop procedure addorders;
addorders 'P0007','C0003',40;



alter table ORDERS
add constraint fkID2 foreign key (CID) REFERENCES CUSTOMER (CID);

alter table ORDERS
add constraint fkID3 foreign key (PID) REFERENCES products (PID);



select * from orders;

-- creating table for details of purchase of stock from supplier.

create table purchase(PID CHAR(5),SID CHAR (5), PQTY INT, DOP date not null);

alter table purchase
add constraint fkID5 foreign key (PID) REFERENCES products (PID);

alter table purchase
add constraint fkID6 foreign key (SID) REFERENCES supplier (SID);

select * from purchase;


-- in the inventory structure generate a view bill. it should display oid,odate,cname,cadd,cphone,pdesc,price,oqty,amount

create view bill
as
	select orders.oid,odate,cname,cadd,cphone,pdesc,price,oqty,(price*oqty) as amt
	from orders
	left join customer
	on customer.cid=orders.cid
	left join products
	on orders.pid=products.pid;

drop view bill;

select * from bill;

--creating a trigger so that whenever any order is placed, if stock is available for Order quantity then stock will be updated else order will not be placed.


select * from orders;
select * from stock;
select * from purchase;
update stock set sqty=20
where pid='p0004';

create trigger Orderstockupdate
on orders
for insert
as
begin
	declare @QR as int;
	declare @QS as int;
	declare @ROL as int;
	declare @PQTY as int;
	declare @PID as char(5);
	declare @SID as char(5);
	declare @DOP as date;

	set @QR= (select OQTY from inserted);
	set @QS=(select sqty from stock where PID= (Select PID from inserted));
	set @ROL=(select rol from stock where PID=(select PID from inserted));
	set @PQTY=(select moq from stock where PID=(select PID from inserted));
	set @PID= (select pid from inserted);
	set @SID= (select SID from products where pid =(select pid from inserted));
	set @DOP =convert(VARCHAR(10), getdate(), 111);

	if (@QS>=@QR)
		begin
			update stock set SQTY= SQTY-@QR
			where pid=(select pid from inserted)
	
			print('Order accepted!!')
			if ((@QS-@QR)<@ROL)
				begin
					insert into purchase
					values(@PID,@SID,@PQTY,@DOP);

					update stock set sqty=sqty+@pqty
					where pid=(select pid from inserted);

				END;
			commit;
		end;
	else
		begin
			rollback;
			print('insufficient quantity,Order rejected')
		end;
end;

drop trigger Orderstockupdate;

addorders 'P0007','C0005',200;

-- creating a update trigger so that if there is any change in the order quantity after placing the order, 
--stock will also get updated if stock is available else order update will be rejected.
--Also whenever stock quantity becomes less than reorder level then a purchase from a supplier should be made automatically 
-- for same product and stock gets updated.

create trigger Updatedorder
on orders
for update
as
begin
	declare @OQ as int;
	declare @NQ as int;
	declare @QS as int;

	set @OQ= (select OQTY from deleted);
	set @NQ= (select OQTY from inserted);
	set @QS=(select sqty from stock where PID=(select PID from inserted));

	if (@QS>=@NQ)
		begin
			update stock set SQTY= SQTY+@OQ-@NQ
			where PID= (select PID from inserted);
			commit;
			print('order updated successfully')
		end;
	else
		begin
			rollback;
			print('Order rejected due to insufficient stock')
		end;
end;

drop trigger Updatedorder;

update orders set oqty=270
where oid='o0012';

-- creating a procedure which gives detail of all the orders placed today

select * from orders;

create procedure PlacedOrderToday
as
begin
	select * from orders
	where ODATE= convert(varchar(10),getdate(),111);
end;

PlacedOrderToday;

--Creating a procedure to get the details of products supplied by that particular supplier

select * from products;
select * from supplier;

create procedure SupplierDetail @S as char(5)
as
begin
	
	select supplier.sid,sname,scity,sphone,semail,pid,pdesc,price,category
	from supplier
	inner join products
	on supplier.sid=products.sid
	where supplier.sid = @S
end;

drop procedure SupplierDetail;

SupplierDetail 'S0001';

-- Creating a procedure to get the details of particular customer and all the orders placed by him.

select * from customer;

create procedure CustomerDetail @C as char(5)
as
begin
	
	select customer.cid,cname,ccity,cphone,pid,odate,oid,oqty
	from customer
	inner join orders
	on customer.cid=orders.cid
	where orders.cid=@C;

end;

drop procedure CustomerDetail;

CustomerDetail 'C0005';




















