/*
Data Cleaning dengan SQL Queries
*/

-- Mengambil semua data
SELECT *
FROM HousingData_Project.dbo.NashvilleHousing;

-- Menstandardisasi Format Tanggal
SELECT saleDateConverted, CONVERT(Date,SaleDate)
FROM HousingData_Project.dbo.NashvilleHousing;

-- Menggunakan ALTER TABLE untuk membuat kolom baru
ALTER TABLE NashvilleHousing
ADD SaleDateConverted Date;

UPDATE NashvilleHousing
SET SaleDateConverted = CONVERT(Date,SaleDate);

-- Mengisi data Alamat Properti NULL dengan referensi ParcelID yang sama
SELECT *
FROM HousingData_Project.dbo.NashvilleHousing
ORDER BY ParcelID;

SELECT a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress, ISNULL(a.PropertyAddress,b.PropertyAddress)
FROM HousingData_Project.dbo.NashvilleHousing a
JOIN HousingData_Project.dbo.NashvilleHousing b
	ON a.ParcelID = b.ParcelID
	AND a.[UniqueID] <> b.[UniqueID]
WHERE a.PropertyAddress IS NULL;

UPDATE a
SET PropertyAddress = ISNULL(a.PropertyAddress,b.PropertyAddress)
FROM HousingData_Project.dbo.NashvilleHousing a
JOIN HousingData_Project.dbo.NashvilleHousing b
	ON a.ParcelID = b.ParcelID
	AND a.[UniqueID] <> b.[UniqueID]
WHERE a.PropertyAddress IS NULL;

-- Memisahkan Alamat untuk membuat data lebih berguna (Alamat, Kota, Negara)
-- Menggunakan SUBSTRING
SELECT PropertyAddress
FROM HousingData_Project.dbo.NashvilleHousing;

SELECT 
SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) - 1) AS Address,
SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) + 1, LEN(PropertyAddress)) AS CityState
FROM HousingData_Project.dbo.NashvilleHousing;

-----------------------------------------------------

ALTER TABLE NashvilleHousing
ADD PropertySplitAddress NVARCHAR(255);

ALTER TABLE NashvilleHousing
ADD PropertySplitCity NVARCHAR(255);

UPDATE NashvilleHousing
SET PropertySplitAddress = SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) - 1);

UPDATE NashvilleHousing
SET PropertySplitCity = SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) + 1, LEN(PropertyAddress));

SELECT *
FROM HousingData_Project.dbo.NashvilleHousing;

-- Mengubah 'Y' dan 'N' menjadi 'Yes' dan 'No' pada kolom "Sold as Vacant"
SELECT DISTINCT(SoldAsVacant), COUNT(SoldAsVacant)
FROM HousingData_Project.dbo.NashvilleHousing
GROUP BY SoldAsVacant
ORDER BY 2;

SELECT SoldAsVacant,
CASE 
	WHEN SoldAsVacant = 'Y' THEN 'Yes'
	WHEN SoldAsVacant = 'N' THEN 'No'
	ELSE SoldAsVacant
END AS SoldStatus
FROM HousingData_Project.dbo.NashvilleHousing;

UPDATE NashvilleHousing
SET SoldAsVacant = CASE 
	WHEN SoldAsVacant = 'Y' THEN 'Yes'
	WHEN SoldAsVacant = 'N' THEN 'No'
	ELSE SoldAsVacant
END;

-- Menghapus Data Duplikat menggunakan CTE dan fungsi ROW_NUMBER()
WITH RowNumCTE AS(
Select *,
	ROW_NUMBER() OVER (
	PARTITION BY ParcelID,
				 PropertyAddress,
				 SalePrice,
				 SaleDate,
				 LegalReference
				 ORDER BY
					UniqueID
					) AS row_num

From HousingData_Project.dbo.NashvilleHousing
--order by ParcelID
)
Select *
From RowNumCTE
Where row_num > 1
Order by PropertyAddress

Select *
From HousingData_Project.dbo.NashvilleHousing

-- Menghapus Kolom yang Tidak Digunakan
ALTER TABLE HousingData_Project.dbo.NashvilleHousing
DROP COLUMN OwnerAddress, TaxDistrict, PropertyAddress, SaleDate;

