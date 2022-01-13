--Inspecting the CovidDeath Table
select *
from [SQL Project]..CovidDeath

--Inspecting the CovidVaccination Table
select * from [SQL Project]..CovidDeath
;

select Location
	, date
	, total_cases
	, new_cases
	, total_deaths
	, population
FROM [SQL Project]..CovidDeath
ORDER BY 1,2
;

--Calculating the DeathPercentage WRT total cases by location
select date
	, location
	, total_cases
	, total_deaths
	, population
	, (convert(int,total_deaths)/total_cases)*100 as DeathPercentage_wrt_cases
from [SQL Project]..CovidDeath
--where location like '%India'
order by 1,2
;

--Calculating Percentage of people got Covid
select date
	, location
	, total_cases
	, population
	, (total_cases/population)*100 as Perc_people_got_Covid
from [SQL Project]..CovidDeath
--where location like '%India'
order by 1,2
;

--Countries with heighest infection rate compared to population
select location
	, population
	, MAX(total_cases) as HighestInfectionCount_byContries
	, (MAX(total_cases)/population)*100 as HighestInfectionPerc_byCountries
from [SQL Project]..CovidDeath
where continent is not null
--where location like '%India'
group by location , population
order by HighestInfectionCount_byContries desc
;

--Countries with heighest death count compared to population
select location
	, max(cast(total_deaths as int)) as HighestDeathCount
	, (max(cast(total_deaths as int))/population) as HighestDeathPerc
from [SQL Project]..CovidDeath
where continent is not null
group by location , population
order by HighestDeathCount desc
;

--Continents with Highest infection rate compared to population
select continent
	, MAX(total_cases) as HighestInfectionCount_by_continent
	, (MAX(total_cases)/sum(population))*100 as HighestInfectionPerc_byContinent
from [SQL Project]..CovidDeath
where continent is not null
--where location like '%India'
group by continent
order by HighestInfectionCount_by_continent desc
;

--Continents with Highest death rate compared to population
select continent
	, MAX(CONVERT(int,total_deaths)) as HighestDeathCount_by_continent
	, (MAX(CONVERT(int,total_deaths))/sum(population))*100 as HighestDeathPerc_byContinent
from [SQL Project]..CovidDeath
--where continent is null
--where location like '%India'
group by continent
order by HighestDeathCount_by_continent desc
;

--Running Total Cases
select date	
	, new_cases
	, sum(new_cases) over (Partition by location order by location,date) as TotalRunningCase
from [SQL Project]..CovidDeath
--where location like '%India'
order by 1
;

--Joining CovidDeath and CovidVaccination table
select vac.*
from [SQL Project]..CovidDeath dea
	join [SQL Project]..CovidVacccinations vac 
	on
	dea.location = vac.location and dea.date = vac.date

--Total Population VS Vaccinated
select dea.location
	, dea.continent
	, dea.population
	, convert(int,vac.new_vaccinations) as new_vaccinations
from [SQL Project]..CovidDeath dea
	join [SQL Project]..CovidVacccinations vac 
	on
	dea.location = vac.location and dea.date = vac.date
where dea.continent is not null and dea.location like '%India'
order by 2,1
;

--Running Total Vaccination by location
select dea.location
	, dea.continent
	, dea.date
	, dea.population
	, vac.new_vaccinations  as new_vaccinations
	, sum(convert(float,vac.new_vaccinations)) 
		over (partition by dea.location order by dea.location , dea.date
		      ) as TotalVaccinated
from [SQL Project]..CovidDeath dea
	join [SQL Project]..CovidVacccinations vac 
	on
	dea.location = vac.location and dea.date = vac.date
where dea.continent is not null and dea.location like '%India'
order by 2,1
;

--USE CTE

with PopvsVac (Location, Continent, Date, Population, new_vaccinations, TotalVaccinated) 
as 
(
	select  dea.continent
		, dea.location
		, dea.date
		, dea.population
		, vac.new_vaccinations  as new_vaccinations
		, sum(convert(float,vac.new_vaccinations)) 
			over (partition by dea.location order by dea.location , dea.date
				  ) as TotalVaccinated
	from [SQL Project]..CovidDeath dea
		join [SQL Project]..CovidVacccinations vac 
		on
		dea.location = vac.location and dea.date = vac.date
	where dea.continent is not null and dea.location like '%India'
)
select * , (TotalVaccinated/population)*100 as per
from PopvsVac

--TEMP Table
Drop table if exists #PercentPopulationVaccinated
create table #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_Vaccinations numeric,
RollingPeopleVaccinated numeric
)
Insert into #PercentPopulationVaccinated
select  dea.continent
		, dea.location
		, dea.date
		, dea.population
		, vac.new_vaccinations
		, sum(convert(float,vac.new_vaccinations)) 
			over (partition by dea.location order by dea.location , dea.date
				  ) as RollingPeopleVaccinated
from [SQL Project]..CovidDeath dea
	join [SQL Project]..CovidVacccinations vac 
	on
	dea.location = vac.location and dea.date = vac.date

select * from #PercentPopulationVaccinated

--Creating View 

create view PercentPopulationVaccinated as
select  dea.continent
		, dea.location
		, dea.date
		, dea.population
		, vac.new_vaccinations
		, sum(convert(float,vac.new_vaccinations)) 
			over (partition by dea.location order by dea.location , dea.date
				  ) as RollingPeopleVaccinated
from [SQL Project]..CovidDeath dea
	join [SQL Project]..CovidVacccinations vac 
	on
	dea.location = vac.location and dea.date = vac.date
where dea.continent is not null
