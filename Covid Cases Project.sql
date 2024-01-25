/*
Data Exploration Project

Data Used: Covid-19 Case Data from 2020-2021
Skills Used: Joins, CTE's, Temp Tables, Aggregate Functions, Creating Views & Converting Data Types

*/



SELECT *
FROM PortfolioProject..CovidDeaths
where continent is not null
order by 3,4


-- Selecting Data to be Used

SELECT Location, date, total_cases, new_cases, deaths_total, population
FROM PortfolioProject..CovidDeaths
where continent is not null
order by 1,2


-- Looking at Total Cases vs Total Deaths
-- "DeathPercentage" shows likelihood of dying if you contract Covid in a given country (Canada was used as an example)

SELECT Location, date, total_cases, deaths_total, (deaths_total/total_cases)*100 as DeathPercentage
FROM PortfolioProject..CovidDeaths
where location like '%canada%' AND continent is not null
order by 1,2


-- Looking at Total Cases vs Population
-- "PopPercentage" shows what percentage of population got Covid

SELECT Location, date, total_cases, population, (total_cases/population)*100 as PopPercentage
FROM PortfolioProject..CovidDeaths
where location like '%canada%' AND continent is not null
order by 1,2


-- Which Countries have highest death rate compared to the population?

SELECT location, MAX(deaths_total) as TotalDeathCount
FROM PortfolioProject..CovidDeaths
where continent is not null
Group by location
order by TotalDeathCount Desc


-- Which Continents have the highesst death rate compared to the population?

SELECT location, MAX(deaths_total) as TotalDeathCount
FROM PortfolioProject..CovidDeaths
where continent is null
Group by location
order by TotalDeathCount Desc


-- Looking at case and death numbers from a global perpective

SELECT date, sum(new_cases) as total_cases, sum(deaths_new) as total_deaths, SUM(deaths_new)/SUM(new_cases)*100 as DeathPercentage
FROM PortfolioProject..CovidDeaths
where continent is not null
group by date
order by 1,2


-- Looking at the percentage of the total population that has received at least one Covid Vaccine

select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(vac.new_vaccinations) OVER (Partition by dea.location order by dea.location, dea.date) as VaccinatedRollingCount
--, (VaccinatedRollingCount/population)*100
from PortfolioProject..CovidDeaths dea
Join PortfolioProject..CovidVaccinations vac
	on dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null
order by 2,3

/*
Including "(VaccinatedRollingCount/population)*100" in select statement above does not work because 
you cannot create a new column using another column you created within the same select statement (VaccinatedRollingCount)
*/

-- Options to work around this
-- Use CTE to perform calculation on the partition by in the previous query ("VaccinatedRollingCount")

With PopvsVac (Continent, Location, Date, Population, New_Vaccinations, VaccinatedRollingCount)
as
(
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(vac.new_vaccinations) OVER (Partition by dea.location order by dea.location, dea.date) as VaccinatedRollingCount
from PortfolioProject..CovidDeaths dea
Join PortfolioProject..CovidVaccinations vac
	on dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null
--order by 2,3
)
Select *, (VaccinatedRollingCount/Population)*100 as VRCPercentage
from PopvsVac


-- Use Temp Table to perform calculation on the partition by in the previous query ("VaccinatedRollingCount")

DROP Table if exists #PercentPopulationVaccinated
Create Table #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_Vaccinations numeric,
VaccinatedRollingCount numeric
)

Insert into #PercentPopulationVaccinated
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(vac.new_vaccinations) OVER (Partition by dea.location order by dea.location, dea.date) as VaccinatedRollingCount
from PortfolioProject..CovidDeaths dea
Join PortfolioProject..CovidVaccinations vac
	on dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null
--order by 2,3

Select *, (VaccinatedRollingCount/Population)*100 as VRCPercentage
from #PercentPopulationVaccinated



-- Creating Views to store data for later visualizations

Create View PercentPopulationVaccinated as
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(vac.new_vaccinations) OVER (Partition by dea.location order by dea.location, dea.date) as VaccinatedRollingCount
from PortfolioProject..CovidDeaths dea
Join PortfolioProject..CovidVaccinations vac
	on dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null
