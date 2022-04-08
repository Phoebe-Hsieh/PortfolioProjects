--- Cleaning Data with SQL Queries ---


/* Data overview */

SELECT *
FROM PortfolioProject.dbo.NashvilleHousing


--------------------------------------------------------------------------------------------------------------------------

/* Standardize DATE format */

-- Change the "SaleDate" column to DATE format
-- Use CONVERT() function and "ALTER TABLE"
SELECT SaleDate, CONVERT(DATE, SaleDate)
FROM PortfolioProject.dbo.NashvilleHousing

ALTER TABLE NashvilleHousing
ALTER COLUMN SaleDate DATE


 --------------------------------------------------------------------------------------------------------------------------

/* Compute the NULL values */

-- Populate the "Property Address" column
-- Check the rows with NULL values
SELECT *
FROM PortfolioProject.dbo.NashvilleHousing
WHERE PropertyAddress IS NULL

-- Use SELF-JOIN and ISNULL() function to compute the NULL values
SELECT a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress, ISNULL(a.PropertyAddress, b.PropertyAddress)
FROM PortfolioProject.dbo.NashvilleHousing a
JOIN PortfolioProject.dbo.NashvilleHousing b
	ON a.ParcelID=b.ParcelID AND a.UniqueID <> b.UniqueID
WHERE a.PropertyAddress IS NULL

-- Update the data into table
UPDATE a
SET PropertyAddress =ISNULL(a.PropertyAddress, b.PropertyAddress)
FROM PortfolioProject.dbo.NashvilleHousing a
JOIN PortfolioProject.dbo.NashvilleHousing b
	ON a.ParcelID=b.ParcelID AND a.UniqueID <> b.UniqueID
WHERE a.PropertyAddress IS NULL


--------------------------------------------------------------------------------------------------------------------------

/* Split one column into multiple columns */

--(1) Split the "PropertyAddress" column into "Address" and "City" columns
SELECT PropertyAddress
FROM PortfolioProject.dbo.NashvilleHousing

-- Check NULL values
SELECT PropertyAddress
FROM PortfolioProject.dbo.NashvilleHousing
WHERE PropertyAddress IS NULL
ORDER BY ParcelID

-- Use SUBSTRING(), CHARINDEX(), LEN() function to split the column
SELECT
	SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress)-1) AS PropertySplitAddress,
	SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress)+1, LEN(PropertyAddress)) AS PropertySplitCity
FROM PortfolioProject.dbo.NashvilleHousing

-- Update the data into table
ALTER TABLE NashvilleHousing
ADD PropertySplitAddress NVARCHAR(255);

UPDATE NashvilleHousing
SET PropertySplitAddress = SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) -1 )

ALTER TABLE NashvilleHousing
ADD PropertySplitCity NVARCHAR(255);

UPDATE NashvilleHousing
SET PropertySplitCity = SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) + 1 , LEN(PropertyAddress))

SELECT *
FROM PortfolioProject.dbo.NashvilleHousing


--(2) Split the "OwnerAddress" column into "Address", "City", "State" columns
SELECT OwnerAddress
FROM PortfolioProject.dbo.NashvilleHousing

-- Use PARSENAME() function to split the column
SELECT
PARSENAME(REPLACE(OwnerAddress, ',',  '.'), 3) AS OwnerSplitAddress,
PARSENAME(REPLACE(OwnerAddress, ',',  '.'), 2) AS OwnerSplitCity,
PARSENAME(REPLACE(OwnerAddress, ',',  '.'), 1) AS OwnerSplitState
FROM PortfolioProject.dbo.NashvilleHousing

-- Update the data into table
ALTER TABLE NashvilleHousing
ADD OwnerSplitAddress Nvarchar(255);

UPDATE NashvilleHousing
SET OwnerSplitAddress = PARSENAME(REPLACE(OwnerAddress, ',', '.') , 3)


ALTER TABLE NashvilleHousing
ADD OwnerSplitCity Nvarchar(255);

Update NashvilleHousing
SET OwnerSplitCity = PARSENAME(REPLACE(OwnerAddress, ',', '.') , 2)


ALTER TABLE NashvilleHousing
ADD OwnerSplitState Nvarchar(255);

Update NashvilleHousing
SET OwnerSplitState = PARSENAME(REPLACE(OwnerAddress, ',', '.') , 1)


SELECT *
FROM PortfolioProject.dbo.NashvilleHousing


--------------------------------------------------------------------------------------------------------------------------

/* Creating category within one specific column */

-- Use GROUP BY statement to check #categories in the "Sold as Vacant" column
SELECT DISTINCT(SoldAsVacant), COUNT(SoldAsVacant)
FROM PortfolioProject.dbo.NashvilleHousing
GROUP BY SoldAsVacant
ORDER BY 2

-- Use CASE statement to create categories
SELECT SoldAsVacant,
	   CASE 
		   WHEN SoldAsVacant = 'Y' THEN 'Yes'
		   WHEN SoldAsVacant = 'N' THEN 'No'
		   ELSE SoldAsVacant
	   END
FROM PortfolioProject.dbo.NashvilleHousing

-- Update the data into table
UPDATE NashvilleHousing
SET SoldAsVacant = 
	   CASE 
	        WHEN SoldAsVacant = 'Y' THEN 'Yes'
		    WHEN SoldAsVacant = 'N' THEN 'No'
		    ELSE SoldAsVacant
	   END


-----------------------------------------------------------------------------------------------------------------------------------------------------------

/* Duplicates */
/* Identify Duplicates */

-- Use CTE and ROW_NUMBER() Window function to identify Duplicates
WITH RowNumCTE AS(
SELECT *,
	ROW_NUMBER() OVER (PARTITION BY ParcelID, PropertyAddress, SalePrice, SaleDate, LegalReference
					   ORDER BY UniqueID) AS row_num
FROM PortfolioProject.dbo.NashvilleHousing
)

SELECT *
FROM RowNumCTE
WHERE row_num > 1
ORDER BY PropertyAddress


/* Delete Duplicates */
WITH RowNumCTE AS(
SELECT *,
	ROW_NUMBER() OVER (PARTITION BY ParcelID, PropertyAddress, SalePrice, SaleDate, LegalReference
					   ORDER BY UniqueID) AS row_num
FROM PortfolioProject.dbo.NashvilleHousing
)

DELETE FROM RowNumCTE
WHERE row_num > 1


---------------------------------------------------------------------------------------------------------

/* Unused Columns */
/* Delete Unused Columns */

SELECT *
From PortfolioProject.dbo.NashvilleHousing

ALTER TABLE PortfolioProject.dbo.NashvilleHousing
DROP COLUMN OwnerAddress, TaxDistrict, PropertyAddress
