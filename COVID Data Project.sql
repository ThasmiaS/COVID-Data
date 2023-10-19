SELECT * FROM CovidVax.deaths
WHERE continent is not null
order by 3,4

SELECT location, date , total_cases, total_deaths, population
FROM CovidVax.deaths 
order by 1,2

-- Use total deaths / total cases to find the percentage of those that died

SELECT location, date , total_cases, total_deaths, (total_deaths / total_cases)*100 as DeathPercentage
FROM CovidVax.deaths 
WHERE continent is not null
and location = 'United States'
order by 1,2

-- total cases vs population -> what percentage of population got covid
SELECT location, date , total_cases, population, (total_cases / population)*100 as CasesPercentage
FROM CovidVax.deaths 
WHERE location = 'United States'
and continent is not null
order by 1,2

-- countries w/ highest infection rate compared to population
SELECT location, MAX(total_cases) as MaxTotalCases, population, MAX((total_cases / population))*100 as HighestPercentInfected
FROM CovidVax.deaths 
WHERE continent is not null -- when continent = 'is not null', the corresponding location gives distinct data
GROUP BY location, population
order by HighestPercentInfected desc

-- countries w/ highest death rate compared to population by continent
-- when continent = "is null", the location is the continent -- data is more accurate here
/* SELECT location, MAX(cast(total_deaths as signed)) as HighestDeathCount
FROM CovidVax.deaths
WHERE continent is null 
GROUP BY location
order by HighestDeathCount desc */ 

-- highest death count by continent -- not accurate but using this for visuals
SELECT continent, MAX(cast(total_deaths as signed)) as HighestDeathCount
FROM CovidVax.deaths
WHERE continent is not null 
GROUP BY continent
order by HighestDeathCount desc
 
-- GLOBAL 
-- Gives total death % each day
SELECT date , SUM(new_cases) as total_cases_daily, SUM(new_deaths) as total_deaths_daily, (SUM(new_deaths)/SUM(new_cases))*100 as Global_Death_Percentage
FROM CovidVax.deaths 
WHERE continent is not null
GROUP BY date
order by 1,2
-- all time death %
SELECT SUM(new_cases) as total_cases_daily, SUM(new_deaths) as total_deaths_daily, (SUM(new_deaths)/SUM(new_cases))*100 as Global_Death_Percentage
FROM CovidVax.deaths 
WHERE continent is not null
order by 1,2

-- Total population vs Vaccinations -- how many people vaccinated in world
-- USE CTE; make a temp table that can be added on/altered to later
WITH PopVsVax (continent, location, date, population, new_vaccinations, Rolling_vaccinations)
as
(
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
SUM(vac.new_vaccinations) OVER (PARTITION BY dea.location -- want vax count to sum daily until location changes
	ORDER BY dea.location, dea.date) as Rolling_vaccinations -- so sums up in daily order for the next day
FROM CovidVax.deaths dea -- alias
JOIN CovidVax.vax vac
	ON dea.location = vac.location 
    and dea.date = vac.date -- matches the location & date columns to join
WHERE dea.continent is not null -- gives info for distinct location
order by 2,3
)
SELECT *, (Rolling_vaccinations/population) *100 as rolling_vaccination_percentage -- add this to temp table
FROM PopVsVax

-- TEMP TABLE

DROP TABLE IF EXISTS PercentPopVaxed -- if i want to make changes, replacing the existing table with the changed one
CREATE TABLE PercentPopVaxed (
continent varchar(255),
location varchar(255),
date datetime, 
population int,
new_vaccinations int, 
Rolling_vaccinations int
); -- creates this temp table

INSERT INTO PercentPopVaxed -- inserts this data from other tables to this temp table
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
SUM(vac.new_vaccinations) OVER (PARTITION BY dea.location -- want vax count to sum daily until location changes
	ORDER BY dea.location, dea.date) as Rolling_vaccinations -- so sums up in daily order for the next day
FROM CovidVax.deaths dea -- alias
JOIN CovidVax.vax vac
	ON dea.location = vac.location 
    and dea.date = vac.date -- matches the location & date columns to join
WHERE dea.continent is not null -- gives info for distinct location
order by 2,3

SELECT *, (Rolling_vaccinations/population) *100 as rolling_vaccination_percentage -- add this to temp table
FROM PercentPopVaxed -- inserts this as well

-- Creating view a to store data for tableau or other visualization

CREATE VIEW PercentPopulationVaxed as
WITH PopVsVax (continent, location, date, population, new_vaccinations, Rolling_vaccinations)
as
(
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
SUM(vac.new_vaccinations) OVER (PARTITION BY dea.location -- want vax count to sum daily until location changes
	ORDER BY dea.location, dea.date) as Rolling_vaccinations -- so sums up in daily order for the next day
FROM CovidVax.deaths dea -- alias
JOIN CovidVax.vax vac
	ON dea.location = vac.location 
    and dea.date = vac.date -- matches the location & date columns to join
WHERE dea.continent is not null -- gives info for distinct location
order by 2,3
)
SELECT *, (Rolling_vaccinations/population) *100 as rolling_vaccination_percentage -- add this to temp table
FROM PopVsVax