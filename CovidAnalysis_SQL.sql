select *
from covid_death_csv
where continent != ''
order by 2,3

-- Looking at total cases v/s total deaths
select location,date,total_cases,total_deaths,(CAST(total_deaths as REAL)/total_cases )*100 as DeathPercent
from covid_death_csv cdc
where location = 'United States' and continent != ''
order by total_cases desc


-- Looking at total cases v/s population
-- shows what percent of population got infected
select location,date,population ,total_cases ,(CAST(total_cases as REAL)/population)*100 as infectedPercent
from covid_death_csv cdc 
where location = 'United States' and continent != ''
order by total_cases ,infectedPercent


-- Looking at countries with highest infection rate compared to Population
select location,population,MAX(total_cases) as HighestInfected, MAX((CAST(total_cases as REAL)/population)*100) as PercentInfected
from covid_death_csv
where continent != '' -- there location is continent itself
group by location , population 
order by location,PercentInfected DESC 


-- showing the continent with the highest death count per population
select continent,MAX(CAST(total_deaths as REAL)) as TotalDeathCount
from covid_death_csv
where continent != '' --there location is a country
group by continent 
order by TotalDeathCount desc


 -- GLOBAL NUMBERS
select sum(new_cases) as total_new_cases,sum(new_deaths) as total_new_deaths,
(CAST(sum(new_deaths) as REAL))/sum(new_cases)*100 as DeathPercentage
from covid_death_csv
where continent != ''
order by 2,3


-- SET
-- Looking at total population vs vaccinations 
SELECT dea.continent ,dea.location,dea.date,dea.population ,vac.new_vaccinations,
sum(cast(vac.new_vaccinations as bigint)) over (partition by dea.location order by dea.location,dea.date) as RollingPeopleVaccinated
,(rollingPeopleVaccinated/population)*100 as Percent -- 2 calc's happening where the latter depends on the former
from covid_death_csv dea 							-- that's why we need to create a temp table first and then calculate
Join covid_vaccinations_csv vac 
	on dea.location = vac.location 
	and dea.date = vac.date 
where dea.continent != ''
order by 2,3

-- SUBSET
-- Solving using CTE ( temp result set )
With DeathvsVac(Continent,Location,Date,Population, NewVaccinations ,RollingPeopleVaccinated)
as 
(
SELECT dea.continent ,dea.location,dea.date,dea.population,cast(vac.new_vaccinations as bigint),
sum(cast(vac.new_vaccinations as bigint)) over (PARTITION by dea.location order by dea.location,dea.date) as RollingPeopleVaccinated
from covid_death_csv dea
join covid_vaccinations_csv vac
	on dea.location = vac.location 
	and dea.date = vac.date
where dea.continent  != ''
--order by 2,3
)
select *,(cast(RollingPeopleVaccinated as REAL)/Population)*100
from DeathvsVac


--SUBSET ( didn't work )
-- TEMP TABLE SOLUTION

DROP Table if exists #PercentPopulationVaccinated
Create Table #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccinations numeric,
RollingPeopleVaccinated numeric
)

Insert into #PercentPopulationVaccinated
SELECT dea.continent ,dea.location,dea.date,dea.population,vac.new_vaccinations ,
sum(cast(vac.new_vaccinations as bigint)) over (PARTITION by dea.location order by dea.location,dea.date) as RollingPeopleVaccinated
from covid_death_csv dea
join covid_vaccinations_csv vac
	on dea.location = vac.location  
	and dea.date = vac.date
where dea.continent  != ''
--order by 2,3
)
select *,(cast(RollingPeopleVaccinated as REAL)/Population)*100
from #PercentPopulationVaccinated 


-- Storing the data to use later
CREATE View PercentPopulationVaccinated as 
Select dea.continent,dea.location,dea.date,dea.population, vac.new_vaccinations ,
sum(cast(vac.new_vaccinations as bigint1)) over (PARTITION by dea.location Order By dea.location,dea.date) as RollingPeopleVaccinated
From covid_death_csv dea
join covid_vaccinations_csv vac 
	on dea.location = vac.location 
	and dea.date = vac.date 
where dea.continent != ''
--order by 2,3 


-- FINALLLY
select * from PercentPopulationVaccinated ppv 
