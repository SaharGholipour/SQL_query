/*
Covid 19 Data Exploration
*/


SELECT *
FROM PortfolioProject..CovidDeaths
WHERE continent is not null
ORDER BY 3, 4


--SELECT *
--FROM PortfolioProject..CovidVaccinations
--ORDER BY 3, 4


--Select data that we are going to be using
SELECT location, date, total_cases, new_cases, total_deaths, population
FROM PortfolioProject..CovidDeaths
ORDER BY 1, 2


--Looking at total cases vs total deaths
--both total_cases & total_deaths are int type that's why the division will give an int, unless you change the data type pf one
--Shows likelihood of dying if you contract covid in your country
SELECT location, date, total_cases, total_deaths, CAST(total_deaths AS FLOAT) / total_cases * 100 AS DeathPercentage
FROM PortfolioProject..CovidDeaths
WHERE location like '%iran%'
	and continent is not null
ORDER BY 1, 2


--Looking at total cases vs population
--Shows what percentage of population got covid
SELECT location, date, population, total_cases, CAST(total_cases AS FLOAT) / population * 100 AS InfectionRate
FROM PortfolioProject..CovidDeaths
WHERE location like '%iran%'
ORDER BY 1, 2


--Looking at countries with highest infection rate compared to population
SELECT location, MAX(population), MAX(total_cases) AS HighestInfection, MAX(CAST(total_cases AS FLOAT) / population) * 100 AS CountryInfectionRate
FROM PortfolioProject..CovidDeaths
WHERE continent is not null
GROUP BY location
ORDER BY CountryInfectionRate DESC


--Showing countries with highest death count per population
SELECT location, MAX(total_deaths) AS TotalDeathCount
FROM PortfolioProject..CovidDeaths
WHERE continent is not null
GROUP BY location
ORDER BY TotalDeathCount DESC


--Let's break things down by continent
SELECT continent, MAX(total_deaths) AS TotalDeathCount
FROM PortfolioProject..CovidDeaths
WHERE continent is not null
GROUP BY continent
ORDER BY TotalDeathCount DESC


--The location will give the continent wen the continent is null, raw data issue
--When the continent is not null, the continent doesn't include the date from all countries in that continent (like North America shows the data from US only)
SELECT location, MAX(total_deaths) AS TotalDeathCount
FROM PortfolioProject..CovidDeaths
WHERE continent is null
GROUP BY location
ORDER BY TotalDeathCount DESC


--Global number
SELECT date, SUM(total_cases), SUM(total_deaths), SUM(CAST(total_deaths AS FLOAT)) / SUM(total_cases) * 100 AS GlobalDeathPercentage
FROM PortfolioProject..CovidDeaths
WHERE continent is not null
GROUP BY date
ORDER BY 1, 2


--Overal across the world
SELECT SUM(new_cases) as TotalCases, SUM(new_deaths) as TotalDeaths, SUM(CAST(new_deaths as float)) / SUM(new_cases) * 100 AS DeathPercentage
FROM PortfolioProject..CovidDeaths
WHERE continent is not null
--GROUP BY date
ORDER BY 1, 2


--Join two tables
--Looking at total population vs vaccination
--Only dea has column population,, so doesn't need to be specified
SELECT dea.continent, dea.location, dea.date, population, vac.new_vaccinations
, SUM(CONVERT(int, vac.new_vaccinations)) OVER (Partition by dea.location ORDER BY dea.date) as RollingPeopleVaccinated
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
	on dea.location = vac.location
	and dea.date = vac.date
WHERE dea.continent is not null
ORDER BY 2, 3


--Using CTE, becasue we wanna use the column we just created and use in an aggregation to create a new column
--The sequence and the number of columns after with has to be the sam as inside of with
With PopvsVac (continent, location, date, population, new_vaccinations, RollingPeopleVaccinated)
as
(
SELECT dea.continent, dea.location, dea.date, population, vac.new_vaccinations
, SUM(CONVERT(float, vac.new_vaccinations)) OVER (Partition by dea.location ORDER BY dea.date) as RollingPeopleVaccinated
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
	on dea.location = vac.location
	and dea.date = vac.date
WHERE dea.continent is not null
--You can't order it here, but you can do it outside of with
--ORDER BY 2, 3
)
SELECT *, (RollingPeopleVaccinated / population) * 100
FROM PopvsVac
--ORDER BY location, date


--Same thing as above, but this time by using TEMP table
DROP TABLE IF exists #PercentPopulationVaccinated
CREATE TABLE #PercentPopulationVaccinated
(
continent varchar(50),
location varchar(50),
Date datetime,
population numeric,
new_vaccinations numeric,
RollingPeopleVaccinated numeric
)

INSERT INTO #PercentPopulationVaccinated
SELECT dea.continent, dea.location, dea.date, population, vac.new_vaccinations
, SUM(CONVERT(float, vac.new_vaccinations)) OVER (Partition by dea.location ORDER BY dea.date) as RollingPeopleVaccinated
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
	on dea.location = vac.location
	and dea.date = vac.date
WHERE dea.continent is not null
ORDER BY 2, 3

SELECT *, (RollingPeopleVaccinated / population) * 100 
FROM #PercentPopulationVaccinated


--Creating view to store data for later visualization
CREATE VIEW PercentPopulationVaccinated as
SELECT dea.continent, dea.location, dea.date, population, vac.new_vaccinations
, SUM(CONVERT(float, vac.new_vaccinations)) OVER (Partition by dea.location ORDER BY dea.date) as RollingPeopleVaccinated
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
	on dea.location = vac.location
	and dea.date = vac.date
WHERE dea.continent is not null
--ORDER BY 2, 3

--The view is permanent
SELECT *
FROM PercentPopulationVaccinated
