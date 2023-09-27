SELECT * FROM ProjectPortfolio.dbo.CovidDeaths
ORDER BY date, location;


SELECT iso_code, continent, location, MAX(total_deaths) as total_death_count
FROM ProjectPortfolio.dbo.CovidDeaths
WHERE continent IS NOT NULL AND continent = 'Oceania'
GROUP BY location, iso_code, continent
;

SELECT iso_code, continent, location, SUM(new_deaths) as total_death_count
FROM ProjectPortfolio.dbo.CovidDeaths
WHERE continent IS NOT NULL AND continent = 'Oceania'
GROUP BY location, iso_code, continent
;

SELECT iso_code, continent, location, MAX(total_deaths) as total_death_count
FROM ProjectPortfolio.dbo.CovidDeaths
WHERE location = 'Oceania'
GROUP BY location, iso_code, continent
;


--SELECT location, date, total_cases, new_cases, total_deaths, population
--FROM ProjectPortfolio.dbo.CovidDeaths
--WHERE total_cases IS NOT NULL AND iso_code NOT LIKE 'OWID%'
--ORDER BY 1,2
--;

--SELECT * FROM ProjectPortfolio.dbo.CovidDeaths;

-- Looking at total cases vs total deaths
-- derived column 'death_percentage' shows the percentage chance of dying from covid in the UK, per day
--SELECT location, date, total_cases, total_deaths, (total_deaths / total_cases)*100 as death_percentage
--FROM ProjectPortfolio.dbo.CovidDeaths
--WHERE location = 'United Kingdom'
--ORDER BY 1,2
--;

-- each countries avg death_percentage
SELECT location, ((SUM(total_deaths) / SUM(total_cases))*100) as avg_death_percentage
FROM ProjectPortfolio.dbo.CovidDeaths
GROUP BY location
ORDER BY avg_death_percentage DESC
;

-- Looking at the total cases vs population
-- shows what percentage of the population has ever had covid
SELECT location, date, population, total_cases, (total_cases / population)*100 as population_percentage
FROM ProjectPortfolio.dbo.CovidDeaths
WHERE location = 'United Kingdom'
ORDER BY 1,2
;

-- find county with the highest death count
SELECT location, MAX(total_deaths) as total_death_count
FROM ProjectPortfolio.dbo.CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location
ORDER BY total_death_count DESC;

-- find continent with the highest death count
SELECT continent, MAX(total_deaths) as total_death_count
FROM ProjectPortfolio.dbo.CovidDeaths
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY total_death_count DESC;

SELECT location, continent, MAX(total_deaths) as total_death_count
FROM ProjectPortfolio.dbo.CovidDeaths
WHERE continent = 'North America'
GROUP BY continent, location
ORDER BY total_death_count DESC;

-- each continent's total death count
SELECT iso_code, continent, location, MAX(total_deaths) as total_death_count
FROM ProjectPortfolio.dbo.CovidDeaths
WHERE continent IS NULL AND location IN ('Europe', 'Asia', 'North America', 'South America', 'Africa', 'Oceania')
GROUP BY location, iso_code, continent
ORDER BY total_death_count DESC
;

-- GLOBAL NUMBERS

-- global new cases, new deaths, and death percentage for each day
SELECT date, SUM(new_cases) AS global_new_cases, SUM(new_deaths) AS global_new_deaths, 
(NULLIF(SUM(new_deaths),0) / NULLIF(SUM(new_cases),0)) * 100 AS global_new_death_percent
FROM ProjectPortfolio.dbo.CovidDeaths
WHERE continent IS NOT NULL
GROUP BY date
ORDER BY date;

-- global total cases, total deaths, and overall death percentage
SELECT SUM(new_cases) AS global_new_cases, SUM(new_deaths) AS global_new_deaths, 
(NULLIF(SUM(new_deaths),0) / NULLIF(SUM(new_cases),0)) * 100 AS global_new_death_percent
FROM ProjectPortfolio.dbo.CovidDeaths
WHERE continent IS NOT NULL
;


--- BRINGING IN CovidVaccinations TABLE

-- Looking at total population vs vaccinations with rolling count of vaccinations administered
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(vac.new_vaccinations)
	OVER (PARTITION BY dea.location 
	ORDER BY dea.location, dea.date) as vaccinations_administered
FROM ProjectPortfolio.dbo.CovidDeaths dea
JOIN ProjectPortfolio.dbo.CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
ORDER BY dea.location, dea.date
;

-- adding rolling percentage of population vaccinated by turning the above query into a CTE
With PopVsVac (continent, location, date, population, new_vaccinations, vaccinations_administered)
as
(
	SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
	SUM(vac.new_vaccinations)
		OVER (PARTITION BY dea.location 
		ORDER BY dea.location, dea.date) as vaccinations_administered
	FROM ProjectPortfolio.dbo.CovidDeaths dea
	JOIN ProjectPortfolio.dbo.CovidVaccinations vac
		ON dea.location = vac.location
		AND dea.date = vac.date
	WHERE dea.continent IS NOT NULL
	--ORDER BY dea.location, dea.date
)

SELECT *, (vaccinations_administered / population) * 100 as percentage_of_pop_vaccinated
FROM PopVsVac
ORDER BY location, date;

-- same again but with a temp table instead ;)
DROP TABLE IF EXISTS #PopulationPercentVaccinated

CREATE TABLE #PopulationPercentVaccinated (
	continent nvarchar(255),
	location nvarchar(255),
	date datetime,
	population float,
	new_vaccinations float,
	vaccinations_administered float
)

INSERT INTO #PopulationPercentVaccinated
	SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
	SUM(vac.new_vaccinations)
		OVER (PARTITION BY dea.location 
		ORDER BY dea.location, dea.date) as vaccinations_administered
	FROM ProjectPortfolio.dbo.CovidDeaths dea
	JOIN ProjectPortfolio.dbo.CovidVaccinations vac
		ON dea.location = vac.location
		AND dea.date = vac.date
	WHERE dea.continent IS NOT NULL

SELECT * FROM #PopulationPercentVaccinated
ORDER BY 2,3;

-- Creating views for later visualisations --------------------

-- each country's avg death_percentage
USE ProjectPortfolio
GO
CREATE VIEW avg_death_percentage AS
SELECT location, ((SUM(total_deaths) / SUM(total_cases))*100) as avg_death_percentage
FROM ProjectPortfolio.dbo.CovidDeaths
GROUP BY location
GO
;

-- each country's total death count
USE ProjectPortfolio
GO
CREATE VIEW total_deaths_per_country AS
SELECT location, MAX(total_deaths) as total_death_count
FROM ProjectPortfolio.dbo.CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location
GO
;

-- each continent's total death count
USE ProjectPortfolio
GO
CREATE VIEW total_deaths_per_continent AS
SELECT location, MAX(total_deaths) as total_death_count
FROM ProjectPortfolio.dbo.CovidDeaths
WHERE continent IS NULL AND location IN ('Europe', 'Asia', 'North America', 'South America', 'Africa', 'Oceania')
GROUP BY location, iso_code, continent
GO
;

-- global new cases, new deaths, and death percentage for each day
USE ProjectPortfolio
GO
CREATE VIEW daily_global_new_cases_deaths_death_percent AS
SELECT date, SUM(new_cases) AS global_new_cases, SUM(new_deaths) AS global_new_deaths, 
(NULLIF(SUM(new_deaths),0) / NULLIF(SUM(new_cases),0)) * 100 AS global_new_death_percent
FROM ProjectPortfolio.dbo.CovidDeaths
WHERE continent IS NOT NULL
GROUP BY date
GO
;

-- daily new vaccinations, total vaccinations administered, and percent of pop vaccinated, per country, daily
USE ProjectPortfolio
GO
CREATE VIEW daily_country_vaccinations AS
With PopVsVac (continent, location, date, population, new_vaccinations, vaccinations_administered)
as
(
	SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
	SUM(vac.new_vaccinations)
		OVER (PARTITION BY dea.location 
		ORDER BY dea.location, dea.date) as vaccinations_administered
	FROM ProjectPortfolio.dbo.CovidDeaths dea
	JOIN ProjectPortfolio.dbo.CovidVaccinations vac
		ON dea.location = vac.location
		AND dea.date = vac.date
	WHERE dea.continent IS NOT NULL
	--ORDER BY dea.location, dea.date
)

SELECT *, (vaccinations_administered / population) * 100 as percentage_of_pop_vaccinated
FROM PopVsVac
GO
;


