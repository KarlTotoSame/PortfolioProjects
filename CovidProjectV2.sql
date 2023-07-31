
-- We will be exploring two tables :

DESCRIBE portfolioproject.coviddeaths;-- Covid Deaths Table

DESCRIBE portfolioproject.covidvaccinations;-- Covid Vaccinations Table

-- Starting with Covid Deaths.
-- Selecting Data that will be used.

SELECT location, date, total_cases, new_cases, total_deaths, population 
FROM portfolioproject.coviddeaths
WHERE continent <> '' 
ORDER BY 1,2;

-- Looking at Total Cases vs Total Deaths -> Likelyhood of dying if you contract Covid in your country (ex:France).

SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as Death_Percentage
FROM portfolioproject.coviddeaths
WHERE continent <> '' 
-- AND location like 'France'
ORDER BY 1,2;

-- Looking at Total Cases vs Population -> What percentage of population got Covid (ex:France).

SELECT location, date, population, total_cases, (total_cases/population)*100 as Infected_Population_Percentage
FROM portfolioproject.coviddeaths
WHERE continent <> '' 
-- AND location like 'France'
ORDER BY 1,2;

-- Looking at countries with Highest Infection Rate compared to population.

SELECT location, population, MAX(total_cases) as HighestInfectionCount, MAX((total_cases)/population)*100 as Total_Infected_Population_Percentage 
FROM portfolioproject.coviddeaths
WHERE continent <> '' 
GROUP BY location,population
ORDER BY Infected_Population_Percentage DESC;

-- Looking at countries with Highest Death Count per population.

SELECT location, MAX(cast(total_deaths AS UNSIGNED)) as Total_Death_Count 
FROM portfolioproject.coviddeaths
WHERE continent <> '' 
GROUP BY location
ORDER BY Total_Death_Count DESC;

-- Breaking it down by continent.

SELECT continent,MAX(cast(total_deaths AS UNSIGNED)) as Total_Death_Count 
FROM portfolioproject.coviddeaths
WHERE continent <> '' 
GROUP BY continent
ORDER BY Total_Death_Count DESC;

-- However, the previous query does not add up the Total_Death_Count of each country for a given continent.

SELECT location, MAX(cast(total_deaths AS UNSIGNED)) as Total_Death_Count 
FROM portfolioproject.coviddeaths
WHERE continent = '' 
AND location != ('Lower middle income')
AND location != ('Upper middle income')
AND location != ('World')
AND location != ('High income')
AND location !=('Low income')
AND location !=('European Union')
GROUP BY location
ORDER BY Total_Death_Count DESC;
-- This query is correct, the TotalDeathCount of each country for a given continent is added, non-existent locations have also been removed.


-- GLOBAL NUMBERS per DAY

SELECT  date, SUM(new_cases) as Total_Global_Cases, SUM(new_deaths) as Total_Global_Deaths, SUM(new_deaths)/SUM(new_cases)*100 as Global_Death_Percentage
FROM portfolioproject.coviddeaths
WHERE continent <> '' 
GROUP BY date
ORDER BY 1,2;

-- TOTAL GLOBAL NUMBERS 

SELECT  SUM(new_cases) as Total_Global_Cases, SUM(new_deaths) as Total_Global_Deaths, SUM(new_deaths)/SUM(new_cases)*100 as Global_Death_Percentage
FROM portfolioproject.coviddeaths
WHERE continent <> '' 
ORDER BY 1,2;

-- Now we will be exploring Covid Vaccinations as well, by joining the two tables.

SELECT * FROM portfolioproject.covidvaccinations;
SELECT * FROM portfolioproject.coviddeaths;

-- Looking at Total Population vs Vaccination.

SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(CAST(vac.new_vaccinations as UNSIGNED)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) as RollingPeopleVaccinated
FROM portfolioproject.coviddeaths as dea
JOIN portfolioproject.covidvaccinations as vac
ON dea.location = vac.location 
AND dea.date = vac.date
WHERE dea.continent <> '' 
ORDER BY 2,3;

-- BY USING CTE.

With PopvsVac (Continent, Location, Date, Population, New_Vaccinations, RollingPeopleVaccinated) as 
( 
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(CAST(vac.new_vaccinations as UNSIGNED)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) as RollingPeopleVaccinated
FROM portfolioproject.coviddeaths as dea
JOIN portfolioproject.covidvaccinations as vac
ON dea.location = vac.location 
AND dea.date = vac.date
WHERE dea.continent <> '' 
)
SELECT *, (RollingPeopleVaccinated/Population)*100
FROM PopvsVac;

-- BY USING A TEMP TABLE.

DROP TABLE IF EXISTS PercentPopulationVaccinated;
CREATE TEMPORARY TABLE PercentPopulationVaccinated 
( 
continent VARCHAR(20),
location VARCHAR(100),
date DATE,
population BIGINT,
New_vaccinations VARCHAR(100),
RollingPeopleVaccinated VARCHAR(100)
);

INSERT INTO PercentPopulationVaccinated (continent, location, date, population, New_vaccinations, RollingPeopleVaccinated)
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
SUM(vac.new_vaccinations) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) as RollingPeopleVaccinated
FROM portfolioproject.coviddeaths as dea
JOIN portfolioproject.covidvaccinations as vac
ON dea.location = vac.location
AND dea.date = vac.date
WHERE dea.continent <> '';


SELECT *, (RollingPeopleVaccinated/Population)*100 as PercentRollingPeopleVaccinated
FROM PercentPopulationVaccinated;

-- Creating Views to store data for later vizualisatons.
--
CREATE VIEW portfolioproject.PercentPopulationVaccinated as 
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
SUM(vac.new_vaccinations) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) as RollingPeopleVaccinated
FROM portfolioproject.coviddeaths as dea
JOIN portfolioproject.covidvaccinations as vac
ON dea.location = vac.location
AND dea.date = vac.date
WHERE dea.continent <> '';
--
-- 
CREATE VIEW portfolioproject.CountriesInfectionRate as
SELECT location, date, population, total_cases, (total_cases/population)*100 as Infected_Population_Percentage
FROM portfolioproject.coviddeaths
WHERE continent <> '' 
ORDER BY 1,2;

SELECT location, population, MAX(total_cases) as HighestInfectionCount, MAX((total_cases)/population)*100 as Total_Infected_Population_Percentage 
FROM portfolioproject.coviddeaths
WHERE continent <> '' 
GROUP BY location,population
ORDER BY Infected_Population_Percentage DESC;
-- 
--
CREATE VIEW portfolioproject.CountriesDeathCount as 
SELECT location, MAX(cast(total_deaths AS UNSIGNED)) as Total_Death_Count 
FROM portfolioproject.coviddeaths
WHERE continent <> '' 
GROUP BY location
ORDER BY Total_Death_Count DESC;
--
CREATE VIEW portfolioproject.ContinentDeathCount as
SELECT location, MAX(cast(total_deaths AS UNSIGNED)) as Total_Death_Count 
FROM portfolioproject.coviddeaths
WHERE continent = '' 
AND location != ('Lower middle income')
AND location != ('Upper middle income')
AND location != ('World')
AND location != ('High income')
AND location !=('Low income')
AND location !=('European Union')
GROUP BY location
ORDER BY Total_Death_Count DESC;






