# COVID DEATHS AND VACCINATIONS IN NIGERIA
### The datasets contains confirmed numbers of deaths and vaccinations of COVID-19 in Nigeria  
### obtained from https://ourworldindata.org
### Google drive link to datasets used
### https://drive.google.com/drive/folders/1h20fB2_mxPrW0XFWi2BrykomnpvEoJaJ?usp=sharing
---
## Skills demonstrated: 
#### Joins, CTE's, Temp Tables, Windows Functions, Aggregate Functions, Creating Views, Converting Data Types, Updating Tables
---
## GETTING STARTED WITH THE DATA EXPLORATION PROJECT.
## Log into MySQL Workbench, create a schema and name it PROJECTPORTFOLIO.
### Create two tables (covid_vaccinations and covid_deaths) with datatypes, load csv files into tables using
```mysql
  load data local infile 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/covid_vaccinations.csv'
into table covid_vaccinations
fields terminated by ','
optionally enclosed by '"'
lines terminated by '\n'
ignore 1 rows;
```
### Convert dates from string into date format
```mysql
update covid_deaths set dates = str_to_date(dates, '%m/%d/%Y %H:%i:%s');
update covid_vaccinations set dates = str_to_date(dates, '%m/%d/%Y');
```
### Update dates in covid_vaccinations to datetime format
```mysql
update covid_vaccinations set dates= (select convert(dates, datetime));
```
### Select all columns from tables
```mysql
select * 
from covid_deaths
where continent is not null
order by 3,4;

select * 
from covid_vaccinations
order by 3,4;
```
### Select data that we are going to be using
```mysql
select location, dates, total_cases, new_cases, total_deaths, population
from covid_deaths
where continent is not null
order by 1,2;
```
### Look at Total Cases vs Total Deaths
#### Shows the likelihood of dying if a person contracts COVID-19 in Nigeria
```mysql
select location, dates, total_cases, total_deaths,(total_deaths/total_cases)*100 as DeathPercentage
from covid_deaths
where location like '%nigeria%'
and continent is not null
order by 1,2;
```
### Look at the Total Cases VS Population
#### Shows the percentage of population that got infected with COVID-19 in Nigeria
```mysql
select location, dates, population, total_cases, (total_deaths/population)*100 as PercentPopulationInfected
from covid_deaths
where location like '%nigeria%'
order by 1,2;
```
### Look at countries with Highest Infection Rates compared to Population
```mysql
select location, population, max(total_cases) as HighestInfectionCount, MAX(total_cases/population)*100 as PercentagePopulationInfected
from covid_deaths
group by location, population
order by PercentagePopulationInfected desc;
```
### Shows countries with Highest Death Counts per Population
```mysql
select location, max(cast(total_deaths as signed)) as TotalDeathCount
from covid_deaths
where continent is not null
group by location
order by TotalDeathCount desc;
```
### Shows Continents with Highest Death Count
```mysql
select CONTINENT, max(cast(total_deaths as signed)) as TotalDeathCount
from covid_deaths
WHERE CONTINENT IN ('AFRICA','ASIA', 'SOUTH AMERICA','NORTH AMERICA', 'OCEANIA', 'EUROPE') AND CONTINENT IS NOT NULL
GROUP BY continent
order by TotalDeathCount ASC;
```
### Global Numbers
#### Shows Total Cases, Total Deaths and Death Percentage
```mysql
select sum(new_cases) as TotalCases, sum(cast(new_deaths as signed)) as TotalDeaths,
sum(cast(new_deaths as signed))/sum(new_cases)*100 as DeathPercentage
from covid_deaths
where continent is not null
#group by dates
order by 1,2;
```
### Compare tables to choose columns for the next query
```mysql
select * from covid_vaccinations;
select * from covid_deaths;
```
### Look at Total Vaccinations vs Population 
#### Join both tables 
 ```mysql
select * from covid_deaths as dea
inner join covid_vaccinations as vac
on dea.location = vac.location
and dea.dates = vac.dates;
```
#### Total Vacccinations vs Population For Nigeria
##### Shows percentage of Population that has recieved at least one COVID-19 Vaccine in Nigeria
###### Rolling People Vaccinated shows the daily increment in the number of population that has recieved the COVID-19 vaccine. 
```mysql
select dea.continent, dea.location, dea.dates, dea.population, vac.new_vaccinations from covid_deaths as dea
inner join covid_vaccinations as vac
on dea.location = vac.location
and dea.dates = vac.dates
WHERE dea.continent IN ('AFRICA','ASIA', 'SOUTH AMERICA','NORTH AMERICA', 'OCEANIA', 'EUROPE') 
and dea.location like '%nigeria%'
AND dea.continent IS NOT NULL
order by 1,2,3;

select dea.continent, dea.location, dea.dates, dea.population, vac.new_vaccinations,
sum(cast(vac.new_vaccinations as signed)) over (partition by dea.location order by dea.location, dea.dates)
as RollingPeopleVaccinated
#(RollingPeopleVaccinated/population)*100
from covid_deaths as dea
inner join covid_vaccinations as vac
on dea.location = vac.location
and dea.dates = vac.dates
WHERE dea.continent IN ('AFRICA','ASIA', 'SOUTH AMERICA','NORTH AMERICA', 'OCEANIA', 'EUROPE')
and dea.location like '%Nigeria%'
AND dea.continent IS NOT NULL
order by 2,3;
```

### Using CTE
#### Using CTE to perform Calculation on Partition By in previous query
```mysql
with PopvsVac(continent, location, dates, population, new_vaccinations, RollingPeopleVaccinated) as 
(
select dea.continent, dea.location, dea.dates, dea.population, vac.new_vaccinations,
sum(cast(vac.new_vaccinations as signed)) over (partition by dea.location order by dea.location, dea.dates)
as RollingPeopleVaccinated
#(RollingPeopleVaccinated/population)*100
from covid_deaths as dea
inner join covid_vaccinations as vac
on dea.location = vac.location
and dea.dates = vac.dates
WHERE dea.continent IN ('AFRICA','ASIA', 'SOUTH AMERICA','NORTH AMERICA', 'OCEANIA', 'EUROPE') 
and dea.location like '%Nigeria%'
and dea.continent IS NOT NULL
)

#select * from PopvsVac;

select *, (RollingPeopleVaccinated/Population)*100
from PopvsVac;
```
### Temp Table
#### Using Temp Table to perform Calculation on Partition By in previous query
```mysql
drop table if exists PercentPopulationVaccinated;
create table PercentPopulationVaccinated
(
continent text,
location text,
dates datetime,
population numeric,
RollingPeopleVaccinated numeric
);
insert into PercentPopulationVaccinated (select dea.continent, dea.location, dea.dates, dea.population, vac.new_vaccinations,
sum(cast(vac.new_vaccinations as signed)) over (partition by dea.location order by dea.location, dea.dates)
as RollingPeopleVaccinated
#(RollingPeopleVaccinated/population)*100
from covid_deaths as dea
inner join covid_vaccinations as vac
on dea.location = vac.location
and dea.dates = vac.dates
WHERE dea.continent IN ('AFRICA','ASIA', 'SOUTH AMERICA','NORTH AMERICA', 'OCEANIA', 'EUROPE')
and dea.location like '%Nigeria%'
AND dea.continent IS NOT NULL
#order by 2,3
);

select *, (RollingPeopleVaccinated/Population)*100
from PercentPopulationVaccinated;
```
### Checking the data type
```mysql
select data_type from information_schema.columns where table_schema = 'projectportfolio' and table_name = 'covid_deaths';
```

### Creating views to store data for later visualizations using tools like Tableau
```mysql
create view PercentPopulationVaccinated as 
select dea.continent, dea.location, dea.dates, dea.population, vac.new_vaccinations,
sum(cast(vac.new_vaccinations as signed)) over (partition by dea.location order by dea.location, dea.dates)
as RollingPeopleVaccinated
#(RollingPeopleVaccinated/population)*100
from covid_deaths as dea
inner join covid_vaccinations as vac
on dea.location = vac.location
and dea.dates = vac.dates
WHERE dea.continent IN ('AFRICA','ASIA', 'SOUTH AMERICA','NORTH AMERICA', 'OCEANIA', 'EUROPE')
and dea.location like '%Nigeria%'
AND dea.continent IS NOT NULL;
#order by 2,3

select * from PercentPopulationVaccinated;
```








