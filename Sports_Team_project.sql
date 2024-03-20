use sqlproject;


select * from country limit 5;

select * from league limit 5;

select * from matches limit 5;

select * from team limit 5;

-- Primary key

alter table country add primary key(id);

alter table league add primary key(id);

alter table matches add primary key(match_api_id);

alter table team add primary key(team_api_id);

--- Foreign keys

alter table league add foreign key(country_id) references country(id);

alter table matches add foreign key(country_id) references country(id);

alter table matches add foreign key(league_id) references league(id);

alter table matches add foreign key(home_team_api_id) references team(team_api_id);

alter table matches add foreign key(away_team_api_id) references team(team_api_id);

-- manually adding duplicate to understand scenario and show how to tackle with duplicates if duplicates not required in the table

insert into team
values(31446,1602,874,'Ruch ChorzÃ³w','CHO');

-- getting duplicate rows using group by

select id,team_long_name,team_short_name  from
(select id,team_long_name,team_short_name,count(id)
from team
group by id,team_fifa_api_id,team_long_name,team_short_name
having count(id)>1
)a;

-- using row_number
select team_api_id,id,team_fifa_api_id,team_long_name,team_short_name,r from
(select team_api_id,id,
row_number() over (partition by id,team_fifa_api_id,team_long_name,team_short_name  ) as r,
team_fifa_api_id,team_long_name,team_short_name 
 from team)sub_part
 where r>=2;
 
 -- using self join
 
 select distinct a.* 
 from team a
 join team b
 on a.id=b.id and a.team_fifa_api_id=b.team_fifa_api_id and a.team_long_name=b.team_long_name and a.team_short_name=b.team_short_name
 where a.team_api_id<>b.team_api_id;
 
 -- deleting duplicates using any of the subquery mentioned above.
 
 
delete from team where team_api_id 
in 
(
select team_api_id from
(select team_api_id,id,
row_number() over (partition by id,team_fifa_api_id,team_long_name,team_short_name) as r,
team_fifa_api_id,team_long_name,team_short_name 
from team)sub_part
where r>=2);

SET SQL_SAFE_UPDATES=0;
 
 -- manually adding record in league table now.alter
 
 select * from league limit 5;
 
 insert into league
 values(1730,1729,'England Premier League');
  insert into league
 values('7810', '7809', 'Germany 1. Bundesliga');
 
 select id,country_id,name,r from
 (select id,country_id,name,row_number() over (partition by country_id,name) as r
 from league)a
 where r>1;
 
 select country_id,name,count(id) as cnt
 from league
 group by country_id,name
 having count(id)>1;
 
 -- deleting duplicate record
delete from league where id
in 
(
select id from
(select id,country_id,name,row_number() over (partition by country_id,name) as r
from league)a
where r>1);
 
 SET FOREIGN_KEY_CHECKS=0; -- to disable them
 SET FOREIGN_KEY_CHECKS=1; -- to re-enable them
 
 -- here we were unable to delete the duplicate coz of foreign key constraint hence we first disable fk and after deleting it enable it
 
-- changing date col dtype from text into datetime in table matches
select str_to_date(date,"%d-%m-%Y %H:%i:%s") from matches limit 5;
update matches set date=str_to_date(date,"%d-%m-%Y %H:%i:%s");
alter table matches modify column date timestamp;

SET SQL_SAFE_UPDATES=0;
-- Build a view to identify the number of goals a home team and a away team placed.
-- make sure the minimum number of goals is 2

create view goal_count_home_team
as
	select matches.id,matches.home_team_api_id,team.team_short_name,sum(matches.home_team_goal) as 'TG_Home'
    from matches
    inner join team
    on team.team_api_id=matches.home_team_api_id
    Group by matches.id,matches.home_team_api_id,team.team_short_name
    having sum(matches.home_team_goal)>1;
    
    
create view goal_count_away_team
as
	select matches.id,matches.away_team_api_id,team.team_short_name,sum(matches.away_team_goal) as 'TG_away'
    from matches
    inner join team
    on team.team_api_id=matches.away_team_api_id
    Group by matches.id,matches.away_team_api_id,team.team_short_name
    having sum(matches.away_team_goal)>1;
  
-- getting winner team 
select match_date,match_api_id,team_long_name,winning_team_api_id from
(select match_api_id,`date` as match_date,
case 
when home_team_goal > away_team_goal then home_team_api_id
when away_team_goal > home_team_goal then away_team_api_id
when home_team_goal=away_team_goal then concat(home_team_api_id,' & ',away_team_api_id)
end as winning_team_api_id
from 
matches)a
inner join team
on a.winning_team_api_id=team.team_api_id;

-- List down the different country names and different leagues happened in every country.

select league.country_id,country.name as country_name,league.name as league_name
from league
join country
on league.country_id=country.id;

-- Extract details about country,matches,league and team.
-- country,league_name,season,stage,date,home_team,away_team,goals,team names

select country.name as country_name,league.name as league_name,matches.season,
matches.stage,matches.date,matches.home_team_api_id,matches.away_team_api_id,
matches.home_team_goal,matches.away_team_goal,HT.team_long_name as home_team_name,
AT.team_long_name as away_team_name
from country
join league
on country.id=league.country_id
join matches
on matches.country_id=country.id
and
matches.league_id=league.id
left join team as HT
on 	HT.team_api_id=matches.home_team_api_id
left join team as AT
on AT.team_api_id=matches.away_team_api_id;

 -- Find the number of teams,average home team goals,average away team goals,
 -- average goal difference ,average total number of goals,
 -- sum of the goals made by both the home and away team.
 -- w.r.t country and the league
 
  select country.name as country_name,
 league.name as league_name,
 count(HT.team_api_id) as no_of_teams,
 avg(matches.home_team_goal) as avg_home_team_goals,
 avg(matches.away_team_goal) as avg_away_team_goals,
 avg(matches.home_team_goal-matches.away_team_goal) as avg_goal_diff,
 avg(matches.home_team_goal+matches.away_team_goal) as avg_tot_goals,
 sum(matches.home_team_goal+matches.away_team_goal) as sum_of_goals
 from
 country
 join
 league
 on
 country.id=league.country_id
 join
 matches
 on
 matches.country_id=country.id
 and
 matches.league_id=league.id
 left join team HT
 on
 HT.team_api_id=matches.home_team_api_id
 left join team AT
 on
 AT.team_api_id=matches.away_team_api_id
 group by country.name , league.name ;
 
 
  -- Function / stored procedures
 --  Build a procedure to know the home_team_goal_count
 -- and away team goal count for a particular team
 delimiter |
 create procedure team_goal_count(IN team_api_id int, OUT home_team_count int,OUT away_team_count int)
 begin
  select 
    sum(case when home_team_api_id=team_api_id then home_team_goal end) as home_team_count,
    sum(case when away_team_api_id=team_api_id then away_team_goal end) as away_team_count
  from matches;
  end |
  
  set @team_api_id=8583;
  
  call team_goal_count(@team_api_id,@home_team_count,@away_team_count);
  
  -- Use case 5
-- Identify league where highest goal count is taken by either a home team or an away team

select * from goal_count_home_team;
-- using view we created above

select matches.league_id, goal_count_home_team.home_team_api_id,goal_count_home_team.TG_Home
from
goal_count_home_team
join
matches
on
goal_count_home_team.home_team_api_id=matches.home_team_api_id
group by matches.league_id,goal_count_home_team.home_team_api_id,goal_count_home_team.TG_Home
order by goal_count_home_team.TG_Home desc;

-- use case 6

-- Identify the league names and the number of high score matches happened in every league.
-- Sum of home team and away team goal is > 6

with big_game as (
	select matches.league_id,matches.match_api_id,
    matches.home_team_api_id,matches.away_team_api_id,
    matches.home_team_goal+matches.away_team_goal as total_goals
    from 
    matches
    where home_team_goal+away_team_goal>=6)
select league.name,
count(big_game.match_api_id) as no_high_score_matches,
sum(total_goals) as total_goals
from
big_game
join
league
on
league.id=big_game.league_id
group by league.id;

-- use case 7
-- rows between unbounded preceding and unbounded following
-- rows between unbounded preceding and current row
-- rows between n preceding and n following
-- Find the running total for a particular team "KAA Gent" when they have played as a home_team or away team

select matches.date,
	   team.team_long_name,
       home_team_goal,
       sum(home_team_goal) over (order by matches.date rows between unbounded preceding and current row) as running_total
       from 
       matches
       join
       team 
       on
       team.team_api_id=matches.home_team_api_id
       where 
       team.team_api_id=9991;
       
select matches.date,
	   matches.away_team_api_id,
       team.team_long_name,
       matches.away_team_goal,
       sum(matches.away_team_goal) over (order by matches.date rows between unbounded preceding and current row) as running_total
       from 
       matches
       join 
       team
       on 
       matches.away_team_api_id=team.team_api_id
       where 
       team.team_api_id=9991;
       
-- use case 8
-- Rank the leagues based on the average total number of goals achieved in every league.

select league.id,
	   league.name,
       avg(matches.home_team_goal+matches.away_team_goal) as avg_goal,
       rank() over (order by avg(matches.home_team_goal+matches.away_team_goal) desc) as ranking
       from 
       league
       join
       matches
       on 
       league.id=matches.league_id
       group by
       league.id,
	   league.name;
       












 
 
    



 








