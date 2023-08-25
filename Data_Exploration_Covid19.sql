
--Project ini menggunakan data Coronavirus (COVID-19) Deaths dari Our World in Data
--Link : https://ourworldindata.org/covid-deaths


-- Eksplorasi data secara Umum
Select * 
from Covid19_Project..CovidDeaths
where continent is not null
order by 3,4
Select * 
from Covid19_Project..CovidVaccinations
where continent is not null
order by 3,4

--Memilih data yang akan digunakan dan memilih lokasi indonesia
Select location, date, total_cases, new_cases, total_deaths, population
from Covid19_Project..CovidDeaths
where continent is not null and location like '%indonesia%'
order by 3,4

--mengamati total kasus vs total kematian di Indonesia
Select location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as DeathPercentage
from Covid19_Project..CovidDeaths
where location like '%indonesia%' and continent is not null
order by 1,2

--mengamati total kasus vs populasi di Indonesia
Select location, date, total_cases, Population, (total_cases/Population)*100 as CasesPercentage
from Covid19_Project..CovidDeaths
where continent is not null and location like '%indonesia%'
order by 1,2

--mengamati Negara (lokasi) dengan kasus covid19 tertinggi dibandingkan dengan populasi
Select location, Population, max(total_cases) as HighestInfectionCount
, max((total_cases/Population)*100) as PercentPopulationInfected
from Covid19_Project..CovidDeaths
where continent is not null
group by location, Population
order by PercentPopulationInfected desc

--mengamati Negara (lokasi) dengan total kasus kematian tertinggi
Select location, population, max(cast(total_deaths as bigint)) as TotalDeathCount
from Covid19_Project..CovidDeaths
where continent is not null
group by location, population
order by TotalDeathCount desc

--Eksplorasi data per-benua
--benua dengan kasus kematian terbanyak
Select continent, max(cast(total_deaths as bigint)) as TotalDeathCount
from Covid19_Project..CovidDeaths
where continent is not null
group by continent
order by TotalDeathCount desc

--eksplorasi data seluruh dunia, mengamati total dan persentase kematian setiap harinya
select date, sum(new_cases) as total_cases, sum(cast(new_deaths as bigint)) as total_deaths, 
	sum(cast(new_deaths as bigint))/sum(new_cases)*100 as DeathPercentage
from Covid19_Project..CovidDeaths
where continent is not null
group by date
order by 1,2

--eksplorasi data seluruh dunia, mengamati total kasus dan kematian hingga data terakhir
select sum(new_cases) as total_cases, sum(cast(new_deaths as bigint)) as total_deaths, 
	sum(cast(new_deaths as bigint))/sum(new_cases)*100 as DeathPercentage
from Covid19_Project..CovidDeaths
where continent is not null
order by 1,2


--mengamati total populasi dibandingkan dengan yang telah divaksin
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, sum(cast(vac.new_vaccinations as bigint)) OVER (partition by dea.location)
from Covid19_Project..CovidDeaths dea
Join Covid19_Project..CovidVaccinations vac
	on dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null
order by 2,3

--mengamati total populasi dibandingkan dengan yang telah divaksin menggunakan convert
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, sum(convert(bigint, vac.new_vaccinations)) OVER (partition by dea.location order by dea.location
, dea.date) as RollingPeopleVaccinated
from Covid19_Project..CovidDeaths dea
Join Covid19_Project..CovidVaccinations vac
	on dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null
order by 2,3

--Menggunakan Common Table Expression (CTE) untuk membuat kolom VaccinatedPercentage
With PopvsVac (Continent, Location, Date, Population, New_Vaccinations, RollingPeopleVaccinated)
as
(
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
From Covid19_Project..CovidDeaths dea
Join Covid19_Project..CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null 
--order by 2,3
)
Select *, (RollingPeopleVaccinated/Population)*100 as VaccinatedPercentage
From PopvsVac



-- Menggunakan Temp Table untuk membuat kolom VaccinatedPercentage
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
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
From Covid19_Project..CovidDeaths dea
Join Covid19_Project..CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
--where dea.continent is not null 
--order by 2,3

Select *, (RollingPeopleVaccinated/Population)*100 as VaccinatedPercentage
From #PercentPopulationVaccinated 


--Membuat view untuk visualisasi
Create View PercentPopulationVaccinated as
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
From Covid19_Project..CovidDeaths dea
Join Covid19_Project..CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null 

Select *
from PercentPopulationVaccinated
