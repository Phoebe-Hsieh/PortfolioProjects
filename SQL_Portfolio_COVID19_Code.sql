--- COVID-19 Deaths Analysis ---

--- Dataset source: Our World in Data (2022). Coronavirus (COVID-19) Deaths. In Our World in Data website. https://ourworldindata.org/covid-deaths

/* EDA */
/* Data Overiew*/
SELECT * FROM CovidDeaths
WHERE Continent IS NOT NULL
ORDER BY location, date

SELECT Location, date, total_cases, new_cases, total_deaths, population
FROM CovidDeaths
WHERE Continent IS NOT NULL
ORDER BY Location, date


/* Case Fatality Rate (CFR) */
/* CFR = (total # deaths/ total # confirmed cases)x100 */
/* CFR: the proportion of people who die from a specified disease among all individuals diagnosed with the disease over a certain period of time. */
/* CFR: An epidemiological measure of the deadliness or severity of an infectious disease. */
/* CFR for COVID-19: shows the likelihood of dying after getting the COVID-19 in specific country. */

--(1) CFR in Global
SELECT Location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 AS CaseFatalityRate
FROM CovidDeaths
WHERE Continent IS NOT NULL
ORDER BY Location, date

--(2) CFR in U.S.
SELECT Location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 AS CaseFatalityRate
FROM CovidDeaths
WHERE Continent IS NOT NULL AND Location LIKE '%states%'
ORDER BY Location, date


/* Mortality Rate */
/* Mortality Rate= (total # deaths/total # population)x100 */

--(1) Mortality Rate in Global
SELECT Location, date, population, total_deaths,  (total_deaths/population)*100 AS MortalityRate
FROM CovidDeaths
WHERE Continent IS NOT NULL
ORDER BY Location, date

--(2) Mortality Rate in U.S.
SELECT Location, date, population, total_deaths,  (total_deaths/population)*100 AS MortalityRate
FROM CovidDeaths
WHERE Continent IS NOT NULL AND Location LIKE '%states%'
ORDER BY Location, date


/* Prevalence */
/* Prevalence= (total # cases/total # population)X100 */
/* Prevalence OF covid-19: shows % of population got COVID-19*/

--(1) Prevalence in Global
SELECT Location, date, population, total_cases, (total_cases/population)*100 AS Prevalence
FROM CovidDeaths
WHERE Continent IS NOT NULL
ORDER BY Location, date

--(2) Prevalence in Global
SELECT Location, date, population, total_cases, (total_cases/population)*100 AS Prevalence
FROM CovidDeaths
WHERE Continent IS NOT NULL AND Location LIKE '%states%'
ORDER BY Location, date


/* Compare prevalence between countries */
-- Solution 1: Use cumulative cases till current date '2022-03-25'
SELECT Location, Population, MAX(total_cases) AS TotalCaseCount, MAX((total_cases/population))*100 AS Prevalence_country
FROM CovidDeaths
WHERE date='2022-03-25' AND Continent IS NOT NULL
GROUP BY Location, Population
ORDER BY Prevalence_country DESC

-- Solution 2: Use "maximum # cases" as the "cumulative cases till current date '2022-03-25'"
SELECT Location, Population, MAX(total_cases) AS TotalCaseCount, MAX((total_cases/population))*100 AS Prevalence_country
FROM CovidDeaths
WHERE Continent IS NOT NULL
GROUP BY Location, Population
ORDER BY Prevalence_country DESC


/* Compare Prevalence between continents */
SELECT Continent, SUM(Population) AS ContinentPopulation, SUM(total_cases) AS TotalCasesCount, (SUM(total_cases)/SUM(population))*100 AS Prevalence_continent
FROM CovidDeaths
WHERE date='2022-03-25' AND Continent IS NOT NULL
GROUP BY Continent
ORDER BY Prevalence_continent DESC


/* Compare Mortality rate between countries */
SELECT Location, Population, MAX(CAST(total_deaths AS INT)) AS TotalDeathCount, MAX((total_deaths/population))*100 AS MortalityRate_country
FROM CovidDeaths
WHERE date='2022-03-25' AND Continent IS NOT NULL
GROUP BY Location, Population
ORDER BY MortalityRate_country DESC


/* Compare Mortality rate between continents */
SELECT Continent, SUM(Population) AS ContinentPopulation, SUM(CAST(total_deaths AS INT)) AS TotalDeathCount, 
       (SUM(CAST(total_deaths AS INT))/SUM(population))*100 AS MortalityRate_continent
FROM CovidDeaths
WHERE date='2022-03-25' AND Continent IS NOT NULL
GROUP BY Continent
ORDER BY MortalityRate_continent DESC



/* Global Data Analysis */
/* CFR by Date*/
SELECT date, SUM(new_cases) AS Total_cases, SUM(CAST(new_deaths AS INT)) AS Total_deaths,
	   SUM(CAST(new_deaths AS INT)) /SUM(new_cases)*100 AS CaseFatalityRate
FROM CovidDeaths
WHERE Continent IS NOT NULL
GROUP BY date
ORDER BY date

/* Wordwide CFR*/
SELECT SUM(new_cases) AS Total_cases, SUM(CAST(new_deaths AS INT)) AS Total_deaths,
	   SUM(CAST(new_deaths AS INT)) /SUM(new_cases)*100 AS CaseFatalityRate
FROM CovidDeaths
WHERE Continent IS NOT NULL



-- COVID-19 Vaccination Analysis ---

/* EDA*/
SELECT * FROM CovidVaccinations

SELECT * 
FROM CovidDeaths dea
JOIN CovidVaccinations vac
ON dea.location=vac.location AND dea.date=vac.date


/* Vaccination Rate */
--(1) Cumulative Vaccinations in Global by date
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
	   SUM(CONVERT(BIGINT, vac.new_vaccinations)) OVER(PARTITION BY dea.location ORDER BY dea.location, dea.date) AS Cumulative_vaccinations
FROM CovidDeaths dea
JOIN CovidVaccinations vac
ON dea.location=vac.location AND dea.date=vac.date
WHERE dea.Continent IS NOT NULL 
ORDER BY dea.location, dea.date

--(2) Cumulative Vaccinations in U.S. by date
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
	   SUM(CONVERT(BIGINT, vac.new_vaccinations)) OVER(PARTITION BY dea.location ORDER BY dea.location, dea.date) AS Cumulative_vaccinations
FROM CovidDeaths dea
JOIN CovidVaccinations vac
ON dea.location=vac.location AND dea.date=vac.date
WHERE dea.Continent IS NOT NULL AND dea.location LIKE '%states%'
ORDER BY dea.location, dea.date

--Solution 1: Use CTE to calculate Vaccination Rate on previous query
WITH popvac AS
(SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
		SUM(CONVERT(BIGINT, vac.new_vaccinations)) OVER(PARTITION BY dea.location ORDER BY dea.location, dea.date) AS Cumulative_vaccinations
FROM CovidDeaths dea
JOIN CovidVaccinations vac
ON dea.location=vac.location AND dea.date=vac.date
WHERE dea.Continent IS NOT NULL)

SELECT *, (Cumulative_vaccinations/population)*100 AS VaccinationRate
FROM popvac


--Solution 2: Use TEMP TABLE to calculate Vaccination Rate on previous query
DROP Table IF EXISTS #VaccinationRate
Create Table #VaccinationRate
(
Continent NVARCHAR(255),
Location NVARCHAR(255),
Date DATETIME,
Population NUMERIC,
New_vaccinations NUMERIC,
Cumulative_vaccinations NUMERIC
)

INSERT INTO #VaccinationRate
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
	   SUM(CONVERT(BIGINT, vac.new_vaccinations)) OVER(PARTITION BY dea.location ORDER BY dea.location, dea.date) AS Cumulative_vaccinations
FROM CovidDeaths dea
JOIN CovidVaccinations vac
ON dea.location=vac.location AND dea.date=vac.date
WHERE dea.Continent IS NOT NULL

SELECT *, (Cumulative_vaccinations/population)*100 AS VaccinationRate
FROM #VaccinationRate


/* Creating View to store data for later visualization */
CREATE VIEW VaccinationRate AS
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
		SUM(CONVERT(BIGINT, vac.new_vaccinations)) OVER(PARTITION BY dea.location ORDER BY dea.location, dea.date) AS Cumulative_vaccinations
FROM CovidDeaths dea
JOIN CovidVaccinations vac
ON dea.location=vac.location AND dea.date=vac.date
WHERE dea.Continent IS NOT NULL

SELECT *
FROM VaccinationRate

