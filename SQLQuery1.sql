select *
From Covid_Project..CovidDeaths


Select *
From Covid_Project..CovidDeaths
Order by 3,4

-- tanpa kontingen
Select *
From Covid_Project..CovidDeaths
where continent is not null
Order by 3,4


--Select *
--From Covid_Project..CovidVaccinations
--Order by 3,4

-- Select Data yang akan coba gunakan

Select Location, date, total_cases, new_cases, total_deaths, population
From Covid_Project..CovidDeaths
Order by 1,2

Select Location, date, total_cases, new_cases, total_deaths, population
From Covid_Project..CovidDeaths
where continent is not null
Order by 1,2

-- Mengecek dan melihat total cases vs total deaths
Select Location, date, total_cases, total_deaths, (CAST(total_deaths AS float) / CAST(total_cases AS float)) * 100 AS DeathPercentage
from Covid_Project..CovidDeaths
order by 1,2

Select Location, date, total_cases, total_deaths, (CAST(total_deaths AS float) / CAST(total_cases AS float)) * 100 AS DeathPercentage
from Covid_Project..CovidDeaths
where continent is not null
order by 1,2

-- Mengecekan berapa persen kematian di indonesia
Select Location, date, total_cases, total_deaths, (CAST(total_deaths AS float) / CAST(total_cases AS float)) * 100 AS DeathPercentage
from Covid_Project..CovidDeaths
where location like '%indonesia%'
order by 1,2

Select Location, date, total_cases, total_deaths, (CAST(total_deaths AS float) / CAST(total_cases AS float)) * 100 AS DeathPercentage
from Covid_Project..CovidDeaths
where location like '%indonesia%'
and continent is not null
order by 1,2


-- Mengecek total cases vs population
Select Location, date, population, total_cases, (CAST(total_cases AS float) / population) * 100 AS PopulationInfectedPercentage
from Covid_Project..CovidDeaths
where location like '%indonesia%'
and continent is not null
order by 1,2

-- Mengecek negara mana yang tinggi terinfeksi covid berdasarkan populasi

Select location, population, Max(total_cases) as HighestInfection, Max((CAST(total_cases as float) / population)) * 100 AS PopulationInfectionPercentage
From Covid_Project..CovidDeaths
where continent is not null
group by location, population
order by PopulationInfectionPercentage desc

-- Mengecek negara mana yang jumlah kematian tertinggi per population
Select Location, MAX(CAST(total_deaths as int)) as TotalDeath
FROM Covid_Project..CovidDeaths
where continent is not null
group by location
order by TotalDeath desc

-- Persentasi kematian yang tinggi
Select Location, Population, MAX(total_deaths) as HighestDeaths, MAX((CAST(total_deaths as int) / population)) * 100 AS PopulationDeathPercentage
FROM Covid_Project..CovidDeaths
where continent is not null
group by location, population
order by PopulationDeathPercentage desc

-- Break down by kontingen
-- Melihat kontingen benua dengan death tertinggi
Select Continent, MAX(CAST(total_deaths as int)) as TotalDeath
FROM Covid_Project..CovidDeaths
where continent is not null
group by continent
order by TotalDeath desc

-- Global number

-- Melihat per date
Select Date, SUM(new_cases) as total_cases, SUM(new_deaths) as total_deaths--, SUM(new_deaths) / SUM(new_cases) * 100 as DeathPercentage
FROM Covid_Project..CovidDeaths
where continent is not null
group by date
order by 1,2

-- total kematian dan kasus seluruh dunia

Select SUM(new_cases) as total_cases, SUM(new_deaths) as total_deaths, SUM(new_deaths) / SUM(new_cases) * 100 as DeathPercentage
FROM Covid_Project..CovidDeaths
where continent is not null
--group by date
order by 1,2



-- Melihat table death digabung dengan table vacc

Select *
FROM Covid_Project..CovidDeaths death
Join Covid_Project..CovidVaccinations vacc
	ON death.location = vacc.location
	and death.date = vacc.date

-- Melihat total populasi vs vaksinasi

Select death.continent, death.location, death.date, death.population, vacc.new_vaccinations
FROM Covid_Project..CovidDeaths death
Join Covid_Project..CovidVaccinations vacc
	ON death.location = vacc.location
	and death.date = vacc.date
where death.continent is not null
order by 2,3

-- Melihat total vaksinasi berdasarkan negara dan tanggal

Select death.continent, death.location, death.date, death.population, vacc.new_vaccinations,
SUM(Convert(bigint, vacc.new_vaccinations)) OVER (Partition by death.location ORDER BY death.location, death.date) AS CountPeopleVaccinated
FROM Covid_Project..CovidDeaths death
Join Covid_Project..CovidVaccinations vacc
	ON death.location = vacc.location
	and death.date = vacc.date
where death.continent is not null
order by 2,3

-- Menggunakan CTE (Common Table Expression) jadi membuat query terpisah dan nanti disatukan

With PopulationvsVaccination (Continent, Location, Date, Population, new_vaccinations, CountPeopleVaccinated)
as
(
Select death.continent, death.location, death.date, death.population, vacc.new_vaccinations,
SUM(Convert(bigint, vacc.new_vaccinations)) OVER (Partition by death.location ORDER BY death.location, death.date) AS CountPeopleVaccinated
FROM Covid_Project..CovidDeaths death
Join Covid_Project..CovidVaccinations vacc
	ON death.location = vacc.location
	and death.date = vacc.date
where death.continent is not null

)
Select *, (CountPeopleVaccinated / Population) * 100 As PeopleVaccinatePercentage
From PopulationvsVaccination


--Temp Table

DROP Table if exists #PercentPopulationVaccinated
Create Table #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccinations numeric,
CountPeopleVaccinated numeric,
)

INSERT INTO #PercentPopulationVaccinated
Select death.continent, death.location, death.date, death.population, vacc.new_vaccinations,
SUM(Convert(bigint, vacc.new_vaccinations)) OVER (Partition by death.location ORDER BY death.location, death.date) AS CountPeopleVaccinated
FROM Covid_Project..CovidDeaths death
Join Covid_Project..CovidVaccinations vacc
	ON death.location = vacc.location
	and death.date = vacc.date
where death.continent is not null
order by 1,2

Select *, (CountPeopleVaccinated / Population) * 100 As PeopleVaccinatePercentage
From #PercentPopulationVaccinated

-- Query for store to Tablue
Create View PercentPopulationVaccinated as
Select death.continent, death.location, death.date, death.population, vacc.new_vaccinations,
SUM(Convert(bigint, vacc.new_vaccinations)) OVER (Partition by death.location ORDER BY death.location, death.date) AS CountPeopleVaccinated
FROM Covid_Project..CovidDeaths death
Join Covid_Project..CovidVaccinations vacc
	ON death.location = vacc.location
	and death.date = vacc.date
where death.continent is not null
--order by 1,2


Select *
FROM PercentPopulationVaccinated