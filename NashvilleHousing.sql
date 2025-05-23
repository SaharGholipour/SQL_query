/*
Cleaning Data in SQL Queries
*/

SELECT *
FROM PortfolioProject..NashvilleHousing

--------------------------------------------------------------------------------------------------------------------------

--Standardize Date Format

SELECT SaleDate, CONVERT(datetime, SaleDate), SaleDateConverted
FROM PortfolioProject..NashvilleHousing

--Sometimes it doesn't work, you need to add a new column and copy the converted data to your new column
UPDATE NashvilleHousing
SET SaleDate = CONVERT(datetime, SaleDate)

ALTER TABLE NashvilleHousing
ADD SaleDateConverted Datetime;

UPDATE NashvilleHousing
SET SaleDateConverted = CONVERT(datetime, saleDate)

--------------------------------------------------------------------------------------------------------------------------

--Populate property address data

SELECT UniqueID, ParcelID, PropertyAddress
FROM PortfolioProject..NashvilleHousing
--WHERE PropertyAddress is null
ORDER BY ParcelID

/*
The question is why we have null in property address.
Looking at the table shows that for the same parce ID the property address is the same, and sometimes for some of thesse common parcel id's property address is null.
So, what we do, we replace the the null with the address from another same parcel id.
In another word, we populate the address for the same parcel ids.
*/

SELECT 
	a.UniqueID, a.ParcelID, a.PropertyAddress,
	b.UniqueID, b.ParcelID, b.PropertyAddress,
	ISNULL(a.PropertyAddress, b.PropertyAddress)
FROM PortfolioProject..NashvilleHousing a
JOIN PortfolioProject..NashvilleHousing b
	ON a.ParcelID = b.ParcelID
	AND a.UniqueID <> b.UniqueID
WHERE a.PropertyAddress is null


--When you use join in update, you should use the table name ailias
UPDATE a
SET PropertyAddress = ISNULL(a.PropertyAddress, b.PropertyAddress)
FROM PortfolioProject..NashvilleHousing a
JOIN PortfolioProject..NashvilleHousing b
	ON a.ParcelID = b.ParcelID
	AND a.UniqueID <> b.UniqueID
WHERE a.PropertyAddress is null

--------------------------------------------------------------------------------------------------------------------------

--Breaking out Address into individual columns (address, city, state)

SELECT *, PropertyAddress
FROM PortfolioProject..NashvilleHousing

--It takes PropertyAddress, and it starts at the very first value and it goes until the comma
--CHARINDEX(',', PropertyAddress) gives the position where the comma is. So we can say one position before comma by -1
SELECT
SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) -1) AS Address,
SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) +1, LEN(PropertyAddress)) AS Address
FROM PortfolioProject..NashvilleHousing

ALTER TABLE NashvilleHousing
ADD PropertySplitAddress varchar(100), PropertySplitCity varchar(100);

UPDATE NashvilleHousing
SET PropertySplitAddress = SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) -1),
	PropertySplitCity = SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) +1, LEN(PropertyAddress))


--Let's use another way (parsename)
SELECT OwnerAddress
FROM PortfolioProject..NashvilleHousing

--PARSENAME works with period, that's why we replace the comma with a period
--PARSENAME works backward, 1 means the very last value
SELECT
PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3),
PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2),
PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1)
FROM PortfolioProject..NashvilleHousing

ALTER TABLE NashvilleHousing
ADD OwnerSplitAddress varchar(100), OwnerSplitCity varchar(100), OwnerSplitstate varchar(100);

UPDATE NashvilleHousing
SET OwnerSplitAddress = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3),
	OwnerSplitCity = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2),
	OwnerSplitstate = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1)

--------------------------------------------------------------------------------------------------------------------------

--Change 1 and 0 to Yes and No in "Sold as Vacant"

SELECT DISTINCT(SoldAsVacant), COUNT(SoldAsVacant)
FROM PortfolioProject..NashvilleHousing
GROUP BY SoldAsVacant
ORDER BY 2


SELECT SoldAsVacant,
	CASE WHEN SoldAsVacant = 1 THEN 'YES'
		 WHEN SoldAsVacant = 0 THEN 'NO'
		 --ELSE SoldAsVacant
	END
FROM PortfolioProject..NashvilleHousing

--or
SELECT SoldAsVacant,
	CASE SoldAsVacant
		 WHEN 1 THEN 'YES'
		 WHEN 0 THEN 'NO'
		 --ELSE SoldAsVacant
	END
FROM PortfolioProject..NashvilleHousing

--The SoldAsVacant column is a bit data type, if you wanna update it with string (yes/no) you should change the column data type first
ALTER TABLE NashvilleHousing
ALTER COLUMN SoldAsVacant VARCHAR(50);

UPDATE NashvilleHousing
SET SoldAsVacant = CASE SoldAsVacant
		 WHEN 1 THEN 'YES'
		 WHEN 0 THEN 'NO'
	END

--------------------------------------------------------------------------------------------------------------------------

--Remove Duplicates

--In CTE list of column name is optional (there are some exceptions)
WITH RowNumCTE AS(
SELECT *,
	ROW_NUMBER() OVER (
	PARTITION BY parcelID,
				 PropertyAddress,
				 SalePrice,
				 SaleDate,
				 LegalReference
				 ORDER BY UniqueID) row_num
FROM PortfolioProject..NashvilleHousing
--ORDER BY ParcelID
)
DELETE
FROM RowNumCTE
WHERE row_num > 1

--------------------------------------------------------------------------------------------------------------------------

--Delete unused columns (usually for views not for actual raaw data:)

ALTER TABLE NashvilleHousing
DROP COLUMN OwnerAddress, TaxDistrict, PropertyAddress, SaleDate

ALTER TABLE NashvilleHousing
DROP COLUMN SaleDate