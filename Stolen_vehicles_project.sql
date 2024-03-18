--creating database

create database vehicle_theft_db;


use vehicle_theft_db;

-- Creating tables location,make_Details and stolen_vehicles

create table location( location_id varchar(max),region varchar(max),country varchar(max),population varchar(max),density varchar(max));


create table make_details(make_id varchar(max),make_name varchar(max),make_type varchar(max));


create table stolen_vehicles(vehicle_id varchar(max),vehicle_type varchar(max),make_id varchar(max),model_year varchar(max), vehicle_desc varchar(max), color varchar(max),
date_stolen varchar(max),location_id varchar(max));

-- Inserting data into these tables from csv file.

bulk insert location
from 'C:\Users\admin\Documents\locations.csv'
with(fieldterminator=',',rowterminator='\n',firstrow=2,maxerrors=0);

bulk insert stolen_vehicles
from 'C:\Users\admin\Documents\stolen_vehicles.csv'
with(fieldterminator=',',rowterminator='\n',firstrow=2,maxerrors=0);

bulk insert make_details
from 'C:\Users\admin\Documents\make_details.csv'
with(fieldterminator=',',rowterminator='\n',firstrow=2,maxerrors=0);

select * from make_details;
select * from location;
select * from stolen_vehicles;

-- checking the datatype of columns of above table.

select column_name,data_type from 
information_schema.columns
where table_name='stolen_vehicles';

select column_name,data_type from 
information_schema.columns
where table_name='location';

select column_name,data_type from 
information_schema.columns
where table_name='make_details';

-- as all the columns are of varchar datatype. we will now chnage the datatype of stolen_vehicle for columns like
--Vehicle_id-num
--make_id- num
--model_year=num
--date_stolen-date
-- location_id= num

alter table stolen_vehicles alter column location_id int;

alter table stolen_vehicles alter column vehicle_id int;

alter table stolen_vehicles alter column make_id int;

-- here we are unable to convert datatype of make_id to int as it contains some special character. let's check those rows.

select * from stolen_vehicles
where isnumeric(make_id)=0;

--transforming these rows so that we can convert make_id datatype to int.

update stolen_vehicles set make_id= '505'
where make_id like '%505%';

update stolen_vehicles set make_id= '623'
where make_id like '%623%';

update stolen_vehicles set make_id= '543'
where make_id like '%543%';

update stolen_vehicles set make_id= '503'
where make_id like '%503%';

-- now data is clean, we can convert the datatype to int

alter table stolen_vehicles alter column make_id int;

alter table stolen_vehicles
alter column model_year date

alter table stolen_vehicles
alter column date_stolen date

-- we are unable to convert date. We need data cleaning for this column. before that let's check values which are non-date in this column

select *from stolen_vehicles
where isdate(date_stolen)=0

-- converting these non-date values in date format

update stolen_vehicles set date_stolen= case when isdate(date_stolen)=0 then convert(varchar(50),getdate() ,120) else date_stolen end;

--now as data is clean we will change date_stolen field into date datatype

alter table stolen_vehicles
alter column date_stolen date


select * from location;

select column_name, data_type
from information_schema.columns
where table_name='Stolen_vehicles';

---- Create the data type consistency plan for location table and make_detail table
-- Location_id-- num
--Population- num
--Density- Decimal
--make_id- num

alter table location
alter column location_id int;

alter table location
alter column population int;

alter table location
alter column density decimal(10,2);

SELECT column_name,
	   data_type
FROM information_schema.columns
WHERE table_name = 'location'

alter table make_details
alter column make_id int

select *from Make_details
where ISNUMERIC(make_id)=0

--data cleaning for value which is not numeric

update make_details set make_id=518
where isnumeric(make_id)=0

select distinct make_name from make_details;


--we can see there is one value 'Aprilia' which has space in it lets trim this space.

update make_details set make_name=TRIM('  ' from make_name);

select * from make_details;
select * from location;
select * from stolen_vehicles;

select distinct(vehicle_type) from stolen_vehicles;

-- Now we are going to identify if there are any duplicates in our data.

delete from stolen_vehicles where vehicle_id in
(select vehicle_id from 
(select *, row_number() over(partition by vehicle_type,make_id,model_year,vehicle_desc,color,date_stolen,location_id order by make_id) as RN1 from stolen_vehicles)A
where RN1>1);

--deleting values where vehicle_type is null

delete from stolen_vehicles where vehicle_type is NULL;

-- Identifying vehicle_type which is stolen more often

select top 10 vehicle_type, count(vehicle_type) as 'StolenNo' from stolen_vehicles
group by vehicle_type
order by count(vehicle_type) desc;

-- from above we can see that stationwagon is stolen more followed by saloon and hatchback.

--Finding the Avg age of stolen_vehicles

with stolen_veh_avg_age as
(SELECT vehicle_type,
	   avg(DATEDIFF(YY, model_year, GETDATE())) AS age_of_veh
FROM Stolen_vehicles
GROUP BY vehicle_type)
select * from stolen_veh_avg_age
order by age_of_veh desc;


-- from the result of above query  we can conclude that Special PUrpose vehicle is the vehicle which despite being oldest, still get stolen as they are
--Cash Carrier Vehicles,Concrete carrier Trucksand,Heavy Duty machines carrier trailers etc hence theif don't care about the age of this vehicle,they care about what these
--vehicle are carrying.

-- Checking No of stolen_vehicles as per make_type.

select m.make_type,count(s.vehicle_id) as No_of_veh from make_details m
join stolen_vehicles s
on s.make_id=m.make_id
group by m.make_type;

-- From above query it is clear that maximum number of stolen cars are standard and around 4 percentage of vehciles are luxury.

--checking no of stolen vehciles in each color of car.

select color,count(vehicle_id) as No_of_veh from stolen_vehicles
group by color
order by count(vehicle_id) desc ;

-- from above query result we can see that maximum number of car stolen are of silver color and least are of pink it means most of the people in newzealand drives cars of color
--silver,black,blue etc


-- Now we are going to find out Most often stolen vehicles as per the week trends ( are they stolen on weekdays most or weekend)


with weekend_detail as (select datename(weekday,date_stolen) as day_stolen,vehicle_type,count((vehicle_type)) as No_of_veh from stolen_vehicles
where datename(weekday,date_stolen)  in ('Sunday','Saturday') group by datename(weekday,date_stolen),vehicle_type)
select * from weekend_detail
order by No_of_veh desc;

--from above results we can say that most of the cars stolen on weekends are stationwagon and least stolen are cabs,truck etc.

with weekday_detail as (select datename(weekday,date_stolen) as day_stolen, vehicle_type ,count((vehicle_type)) as No_of_veh from stolen_vehicles
where datename(weekday,date_stolen) not in ('Sunday','Saturday') group by datename(weekday,date_stolen),vehicle_type)
select * from weekday_detail
order by No_of_veh desc;

-- From the result of above query we can say that most of the cars which are stolen most on weekdays are Saloon and station wagon and maximum are stolen on Monday.


--Region wise bifurcation of no. of vehicle of particular type stolen 

select location.region,stolen_vehicles.vehicle_type,count(stolen_vehicles.vehicle_id) as No_of_stolen_vehicle from location
join stolen_vehicles
on location.location_id=stolen_vehicles.location_id
group by location.region,stolen_vehicles.vehicle_type
order by location.region ,count(stolen_vehicles.location_id) desc;

--Above query gives us result which shows that in Auckland Saloon cars are stolen more followed by stationwagon and hatchback coz auckland is a urban city with business and 
-- job opprtunities hence people drive these cars more but in bay of plenty Utility is stolen more as bay of plenty is famous for farming hence utility cars are driven more
--hence we can conclude from this that type of car which is stolen more depends on the region as well.



--- Create a comparative study of stolen _vehicles if there is any monthly trend or seasonality??

select vehicle_type,datename(month,date_stolen) as Monthly_stolen,count(vehicle_type) as No_of_veh from stolen_vehicles
group by datename(month,date_stolen),vehicle_type
order by datename(month,date_stolen),count(vehicle_type) desc ;

--from the result of above query it is concluded that vehicles are stolen from Oct to April. There is no data of stolen vehicles in months from may to september
--reason might be coz in new zealand winter season lies from may to sept, hence season is impacting on rate of no of stolen  vehicles. 
-- Also maximum number of vehicles which are stolen is in march.

---We need to write a query to calculate the stolen_veh rate for each region. The stolen vehicles
-- rate is defined as percentage as compared to the population in each regionn, Include the region name,
 --total_stolen_vehicles, stolen_rate


select l.region,l.population, count(sv.vehicle_id) as 'Total_Stolen_count' , cast(count(sv.vehicle_id) as float)/l.population *100 as 'Stolen_veh_rates'
from stolen_vehicles Sv
join location L
on sv.location_id=l.location_id
group by l.region,l.population
order by stolen_veh_rates desc;

-- From the result of above query we can conclude that stolen rate is high in Gisborn Nelson,auckland etc which comes under major and large urban areas of newzealand



--- Find out the similar Pattern or profile of Stolen vehicles as per the region

with Stolen_veh_profile As (select sv.vehicle_id,vehicle_type,model_year,vehicle_desc,color,date_stolen,l.location_id,
							l.region,l.population,l.density, m.make_id,m.make_name,m.make_type
							from Stolen_vehicles sv
							join location l
							on sv.location_id=l.location_id
							join make_details m
							on sv.make_id=m.make_id)
select region,count(vehicle_id) as 'Stl_veh_count',
				count(distinct make_name) as 'makers'
				,count(distinct color) as 'dis_color'
				, count(distinct model_year) as 'un_model_year',
				avg(cast(population as float)) as 'Scaled population',
				round(avg(cast(density as float)),2) as 'Scaled_density'
from Stolen_veh_profile
group by region
order by stl_veh_count desc;

--Writing a query to find the top3 and bottom 3 weekdays with the highest count  and lowest count, and label them 
--as Top1,Top2,Top3 and Bottom1,Bottom2,Bottom3. if there is any ties in the count then order the result together.


with tandB_ranked as
(select datename(weekday,date_stolen) as day_Stolen,count(vehicle_id) as No_of_veh,
row_number() over (order by count(vehicle_id) desc) as Ranking1,
row_number() over (order by count(vehicle_id)) as Ranking2
from stolen_vehicles
group by datename(weekday,date_stolen))
select day_stolen, No_of_veh, 
case 
when ranking1<=3 then 'top'+cast(ranking1 as varchar(5)) when ranking2<=3 then 'Bottom'+cast(Ranking2 as varchar(5)) else 'NA' 
end as Ranking
from tandB_ranked
where case 
when ranking1<=3 then 'top'+cast(ranking1 as varchar(5)) when ranking2<=3 then 'Bottom'+cast(Ranking2 as varchar(5)) else 'NA' end<>'NA'
order by 
Case 
When ranking1<=3 Then ranking1 
When ranking2 <=3 Then 2000+ ranking2
Else 500
End;












