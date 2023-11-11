Select * 
FROM CovidProject..covidDeaths
ORDER BY 3, 4

Select * 
FROM CovidProject..covidVax
ORDER BY 3, 4

-- DATA EXPLORATION FOR DEATHS

-- Cleaning data
ALTER TABLE CovidProject..covidDeaths
ALTER COLUMN total_cases float

ALTER TABLE CovidProject..covidDeaths
ALTER COLUMN total_deaths float

ALTER TABLE CovidProject..covidDeaths
DROP COLUMN F27, F28, F29, F30, F31, F32, F33, F34, F35, F36, F37, F38, F39, F40, F41, F42, F43, F44, F45, F46, F47, F48, F49 -- Empty columns

UPDATE CovidProject..covidDeaths 
SET total_cases = 0
WHERE total_cases IS NULL

UPDATE CovidProject..covidDeaths
SET total_deaths = 0
WHERE total_deaths IS NULL

-- Selecting relevant data
SELECT Location, date, total_cases, total_deaths, (total_deaths/NULLIF(total_cases, 0))*100 as DeathPercentage 
FROM CovidProject..covidDeaths
WHERE location = 'United States'
ORDER BY 1,2

-- Total Cases vs Population
SELECT Location, date, total_cases, population, (total_cases/NULLIF(population, 0))*100 as InfectionRate
FROM CovidProject..covidDeaths
WHERE location = 'United States'
ORDER BY 1,2

-- Highest Infection rates vs Population
SELECT Location, population, MAX(total_cases) as HighestInfectionCount, MAX((total_cases/NULLIF(population, 0)))*100 as InfectionRate
FROM CovidProject..covidDeaths
GROUP BY location, population
ORDER BY InfectionRate DESC

-- Highest Death count
SELECT Location, MAX(total_deaths) as HighestMortality
FROM CovidProject..covidDeaths
WHERE continent is not null
GROUP BY location
ORDER BY HighestMortality DESC

-- Highest Death count per population
SELECT Location, population, MAX(total_deaths) as HighestMortality, MAX((total_deaths/NULLIF(population, 0)))*100 as MortalityRate
FROM CovidProject..covidDeaths
WHERE continent is not null
GROUP BY location, population
ORDER BY MortalityRate DESC

-- Breakdown by Continent
SELECT location, MAX(total_deaths) as HighestMortality
FROM CovidProject..covidDeaths
WHERE continent is null AND location not like '%income'
GROUP BY location
ORDER BY HighestMortality DESC

-- Income
SELECT location, MAX(total_deaths) as HighestMortality
FROM CovidProject..covidDeaths
WHERE continent is null AND location like '%income'
GROUP BY location
ORDER BY HighestMortality DESC

-- Global numbers by date
SELECT date, SUM(new_cases) AS GlobalCases, SUM(new_deaths) AS GlobalDeaths, (SUM(new_deaths)/NULLIF(SUM(new_cases), 0))*100 as DeathPercentage 
FROM CovidProject..covidDeaths
GROUP BY date
ORDER BY 1,2

-- Global total
SELECT SUM(new_cases) AS GlobalCases, SUM(new_deaths) AS GlobalDeaths, (SUM(new_deaths)/NULLIF(SUM(new_cases), 0))*100 as DeathPercentage 
FROM CovidProject..covidDeaths

-- DATA EXPLORATION + VACCINATIONS

-- Total Population vs Vaccinations
SELECT dea.continent, dea.location, dea.date, dea.population, vax.new_vaccinations, total_vaccinations,total_vaccinations/population*100 as VaxPercentage FROM CovidProject..covidDeaths dea
JOIN CovidProject..covidVax vax
	ON dea.location = vax.location and dea.date = vax.date
WHERE new_vaccinations is not null and dea.continent is not null
ORDER BY 2, 3

-- Rolling sum
SELECT dea.continent, dea.location, dea.date, dea.population, vax.new_vaccinations, 
SUM(CAST(vax.new_vaccinations as bigint)) OVER (Partition by dea.location ORDER BY dea.location, dea.date) as CumulatedVax
FROM CovidProject..covidDeaths dea
JOIN CovidProject..covidVax vax
	ON dea.location = vax.location and dea.date = vax.date
WHERE new_vaccinations is not null and dea.continent is not null
ORDER BY 2, 3

-- CTE
WITH PopVax (Continent, Location, Date, Population, New_vaccinations, CumulatedVax)
AS
(
SELECT dea.continent, dea.location, dea.date, dea.population, vax.new_vaccinations, 
SUM(CAST(vax.new_vaccinations as bigint)) OVER (Partition by dea.location ORDER BY dea.location, dea.date) as CumulatedVax
FROM CovidProject..covidDeaths dea
JOIN CovidProject..covidVax vax
	ON dea.location = vax.location and dea.date = vax.date
WHERE new_vaccinations is not null and dea.continent is not null
)
SELECT *, (CumulatedVax/population)*100 as CumulatedPcntVax
FROM PopVax;

-- TempTable
DROP TABLE IF EXISTS #PercentPopulationVaccinated
Create Table #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccinations numeric, 
CumulatedVax numeric)

INSERT INTO #PercentPopulationVaccinated
SELECT dea.continent, dea.location, dea.date, dea.population, vax.new_vaccinations, 
SUM(CAST(vax.new_vaccinations as bigint)) OVER (Partition by dea.location ORDER BY dea.location, dea.date) as CumulatedVax
FROM CovidProject..covidDeaths dea
JOIN CovidProject..covidVax vax
	ON dea.location = vax.location and dea.date = vax.date
WHERE dea.continent is not null

SELECT *, (CumulatedVax/population)*100 as CumulatedPcntVax
FROM #PercentPopulationVaccinated
ORDER BY Location, Date

-- Creating Views for visualizations
Create View PercentPopulationVaccinated as
SELECT dea.continent, dea.location, dea.date, dea.population, vax.new_vaccinations, 
SUM(CAST(vax.new_vaccinations as bigint)) OVER (Partition by dea.location ORDER BY dea.location, dea.date) as CumulatedVax
FROM CovidProject..covidDeaths dea
JOIN CovidProject..covidVax vax
	ON dea.location = vax.location and dea.date = vax.date
WHERE dea.continent is not null

CREATE VIEW USInfectionRate as
SELECT Location, date, total_cases, population, (total_cases/NULLIF(population, 0))*100 as InfectionRate
FROM CovidProject..covidDeaths
WHERE location = 'United States'

CREATE VIEW VaccinationRate as
SELECT dea.continent, dea.location, dea.date, dea.population, vax.new_vaccinations, total_vaccinations,total_vaccinations/population*100 as VaxPercentage FROM CovidProject..covidDeaths dea
JOIN CovidProject..covidVax vax
	ON dea.location = vax.location and dea.date = vax.date
WHERE new_vaccinations is not null and dea.continent is not null

CREATE VIEW CumulativeVaccinations as
SELECT dea.continent, dea.location, dea.date, dea.population, vax.new_vaccinations, 
SUM(CAST(vax.new_vaccinations as bigint)) OVER (Partition by dea.location ORDER BY dea.location, dea.date) as CumulatedVax
FROM CovidProject..covidDeaths dea
JOIN CovidProject..covidVax vax
	ON dea.location = vax.location and dea.date = vax.date
WHERE new_vaccinations is not null and dea.continent is not null

CREATE VIEW ContinentBreakdown as
SELECT location, MAX(total_deaths) as HighestMortality
FROM CovidProject..covidDeaths
WHERE continent is null AND location not like '%income'
GROUP BY location

-- SELECT * FROM PercentPopulationVaccinated
-- SELECT * FROM USInfectionRate
-- SELECT * FROM VaccinationRate
-- SELECT * FROM CumulativeVaccinations
-- SELECT * FROM ContinentBreakdown
