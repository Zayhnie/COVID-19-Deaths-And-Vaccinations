use projectportfolio;

create table covid_vaccinations (iso_code text,
continent text,
location text,
dates text,
total_tests text,
new_tests text,
total_tests_per_thousand text,	
new_tests_per_thousand text,
new_tests_smoothed text,
new_tests_smoothed_per_thousand text,
positive_rate text,
tests_per_case text,
tests_units	float, total_vaccinations text,	
people_vaccinated text,
people_fully_vaccinated text,
total_boosters text,
new_vaccinations text,
new_vaccinations_smoothed text, 
total_vaccinations_per_hundred text,
people_vaccinated_per_hundred text,
people_fully_vaccinated_per_hundred	text,
total_boosters_per_hundred text,
new_vaccinations_smoothed_per_million text,	
new_people_vaccinated_smoothed text,
new_people_vaccinated_smoothed_per_hundred text,
stringency_index double,	
population_density double,
median_age double,
aged_65_older double,
aged_70_older double,	
gdp_per_capita double,
extreme_poverty	text,
cardiovasc_death_rate double,	
diabetes_prevalence	double,
female_smokers text,
male_smokers text,
handwashing_facilities double,	
hospital_beds_per_thousand double,
life_expectancy	double,
human_development_index double,	
excess_mortality_cumulative_absolute text,
excess_mortality_cumulative	text,
excess_mortality text,
excess_mortality_cumulative_per_million text);


select * from covid_vaccinations;

create table covid_deaths (iso_code text, continent text,
location text,
dates text,
population int,
total_cases int,
new_cases int,
new_cases_smoothed text,
total_deaths text,
new_deaths text,
new_deaths_smoothed text,	
total_cases_per_million double,
new_cases_per_million double,
new_cases_smoothed_per_million text,
total_deaths_per_million text,
new_deaths_per_million text,
new_deaths_smoothed_per_million text,	
reproduction_rate text,
icu_patients text,
icu_patients_per_million text,
hosp_patients text,
hosp_patients_per_million text,	
weekly_icu_admissions text,
weekly_icu_admissions_per_million text,	
weekly_hosp_admissions text,
weekly_hosp_admissions_per_million text);	

select * from covid_deaths;

-- CONVERTING DATEs FROM STRING TO DATE FORMAT 

update covid_deaths set dates = str_to_date(dates, '%m/%d/%Y %H:%i:%s');
update covid_vaccinations set dates = str_to_date(dates, '%m/%d/%Y');

update covid_vaccinations set dates= (select convert(dates, datetime)); 

 
select * 
from covid_deaths
where continent is not null
order by 3,4;

select * 
from covid_vaccinations
order by 3,4;

-- SELECT DATA THAT WE ARE GOING TO BE USING 

select location, dates, total_cases, new_cases, total_deaths, population
from covid_deaths
where continent is not null
order by 1,2;

-- Looking at Total Cases vs Total Deaths
-- shows the likelihood of dying if you contract covid in Nigeria

select location, dates, total_cases, total_deaths,(total_deaths/total_cases)*100 as DeathPercentage
from covid_deaths
where location like '%nigeria%'
and continent is not null
order by 1,2;

-- looking at the Total Cases VS Population
-- shows what percentage of population got covid in Nigeria

select location, dates, population, total_cases, (total_deaths/population)*100 as PercentPopulationInfected
from covid_deaths
where location like '%nigeria%'
order by 1,2;

-- looking at countries with Highest Infection Rates compared to Population

select location, population, max(total_cases) as HighestInfectionCount, MAX(total_cases/population)*100 as PercentagePopulationInfected
from covid_deaths
group by location, population
order by PercentagePopulationInfected desc;

-- Showing countries with Highest Death Counts per Population

select location, max(cast(total_deaths as signed)) as TotalDeathCount
from covid_deaths
where continent is not null
group by location
order by TotalDeathCount desc;

-- Showing continents with highest death count
select CONTINENT, max(cast(total_deaths as signed)) as TotalDeathCount
from covid_deaths
WHERE CONTINENT IN ('AFRICA','ASIA', 'SOUTH AMERICA','NORTH AMERICA', 'OCEANIA', 'EUROPE') AND CONTINENT IS NOT NULL
GROUP BY continent
order by TotalDeathCount ASC;


-- Global Numbers

select sum(new_cases) as TotalCases, sum(cast(new_deaths as signed)) as TotalDeaths,
sum(cast(new_deaths as signed))/sum(new_cases)*100 as DeathPercentage
from covid_deaths
where continent is not null
#group by dates
order by 1,2;


select * from covid_vaccinations;
select * from covid_deaths;
 
 
 -- Looking at total vaccinations vs population
 
select * from covid_deaths as dea
inner join covid_vaccinations as vac
on dea.location = vac.location
and dea.dates = vac.dates;


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

--- Using CTE

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



--- Temp Table

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

#checking the data type 
select data_type from information_schema.columns where table_schema = 'projectportfolio' and table_name = 'covid_deaths';

# creating views to store data for later visualizations

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
--#order by 2,3


select * from PercentPopulationVaccinated;


