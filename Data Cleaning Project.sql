/*

Data Cleaning Project

Data Used: Nashville Housing Sales Data

*/

Select *
From PortfolioProject.dbo.NashvilleHousing

----------------------------------------------------------------------------------------------------------------------------------
-- Standardize Date Format

Select SaleDate, SaleDateConverted, CONVERT(Date,SaleDate)
From PortfolioProject.dbo.NashvilleHousing

Update NashvilleHousing
SET SaleDate = CONVERT(Date,SaleDate)

ALTER TABLE NashvilleHousing
Add SaleDateConverted Date;

Update NashvilleHousing
SET SaleDateConverted = CONVERT(Date,SaleDate)

----------------------------------------------------------------------------------------------------------------------
-- Populate Property Address Data

Select *
From PortfolioProject.dbo.NashvilleHousing
--Where PropertyAddress is null
order by ParcelID


/*
Creates  column (updated) of correct PropertyAddresses from NH2 to be inputted into NH1, based
on Rows which NH1 and NH2 share the same ParcelID, do not share the same UniqueID, AND the PropertyAddress
field in NH1 is NULL
*/

Select NH1.ParcelID, NH1.PropertyAddress, NH2.ParcelID, NH2.PropertyAddress, ISNULL(NH1.PropertyAddress, NH2.PropertyAddress) as updated
From PortfolioProject.dbo.NashvilleHousing NH1
JOIN PortfolioProject.dbo.NashvilleHousing NH2
	on NH1.ParcelID = NH2.ParcelID
	and NH1.[UniqueID ] <> NH2.[UniqueID ]
Where NH1.PropertyAddress is null


-- Updates PropertyAddress fields in NH1 with correct values (from above query)

Update NH1
SET PropertyAddress =  ISNULL(NH1.PropertyAddress, NH2.PropertyAddress)
From PortfolioProject.dbo.NashvilleHousing NH1
JOIN PortfolioProject.dbo.NashvilleHousing NH2
	on NH1.ParcelID = NH2.ParcelID
	and NH1.[UniqueID ] <> NH2.[UniqueID ]

-----------------------------------------------------------------------------------------------------------------------------
-- Breaking out Addresses into Individual Columns (Address, City, State)

Select PropertyAddress
From PortfolioProject.dbo.NashvilleHousing
--Where PropertyAddress is null
--order by ParcelID


-- Substring #1 seperates the Address from the PropertyAddress column
-- Substring #2 seperates the City from the Property Address column

SELECT
SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) -1) as Address,
SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) + 1, LEN(PropertyAddress)) as City
From PortfolioProject.dbo.NashvilleHousing


-- adding the values of each substring to NashvilleHousing as new columns, 
-- "PropertySplitAddress" and "PropertysplitCity"

ALTER TABLE NashvilleHousing
Add PropertySplitAddress Nvarchar(255);

Update NashvilleHousing
SET PropertySplitAddress = SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) -1)

ALTER TABLE NashvilleHousing
Add PropertySplitCity Nvarchar(255);

Update NashvilleHousing
SET PropertySplitCity = SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) + 1, LEN(PropertyAddress))

-------------------------------------------------------------------------------------------------------------
-- Splitting up OwnerAddress into seperate Address, City, & State columns uing PARSENAME

Select OwnerAddress
From NashvilleHousing

Select
PARSENAME(REPLACE(OwnerAddress, ',', '.'),3), -- PARSENAME only parses based on periods, so REPLACE
PARSENAME(REPLACE(OwnerAddress, ',', '.'),2), -- is used here to change the comma delimmiters to
PARSENAME(REPLACE(OwnerAddress, ',', '.'),1)  -- periods
From NashvilleHousing


-- Updating NashvilleHousing with new split Owner address, city and state columns

ALTER TABLE NashvilleHousing
Add OwnerSplitAddress Nvarchar(255);

Update NashvilleHousing
SET OwnerSplitAddress = PARSENAME(REPLACE(OwnerAddress, ',', '.'),3)

ALTER TABLE NashvilleHousing
Add OwnerSplitCity Nvarchar(255);

Update NashvilleHousing
SET OwnerSplitCity = PARSENAME(REPLACE(OwnerAddress, ',', '.'),2)

ALTER TABLE NashvilleHousing
Add OwnerSplitState Nvarchar(255);

Update NashvilleHousing
SET OwnerSplitState = PARSENAME(REPLACE(OwnerAddress, ',', '.'),1)
----------------------------------------------------------------------------------------------------
-- Change Y and N to "Yes" and "No" in "Sold as Vacant" Field

Select Distinct(SoldAsVacant), Count(SoldAsVacant)
From PortfolioProject.dbo.NashvilleHousing
Group by SoldAsVacant
order by 2


Select SoldAsVacant
, CASE When SoldAsVacant = 'Y' Then 'Yes'
		When SoldAsVacant = 'N' Then 'No'
		ELSE SoldAsVacant
		END
From PortfolioProject.dbo.NashvilleHousing

Update NashvilleHousing
SET SoldAsVacant = CASE When SoldAsVacant = 'Y' Then 'Yes'
						When SoldAsVacant = 'N' Then 'No'
						ELSE SoldAsVacant
						END

------------------------------------------------------------------------------------------------------
--Removing Duplicate Values

WITH RowNumCTE AS (
Select *, 
	ROW_NUMBER() OVER (
	Partition by ParcelID,
				PropertyAddress,
				SalePrice,
				SaleDate,
				LegalReference
				ORDER BY
					UniqueID
					) as row_num

From PortfolioProject.dbo.NashvilleHousing
--order by ParcelID
)
Select * -- << Changed "Select *" to DELETE and removed order by to remove 104 duplicate values found usisng CTE
From RowNumCTE
Where row_num > 1
order by PropertyAddress


-----------------------------------------------------------------------------------------------------------------------------
-- Delete Unused Columns (PropertyAddress, OwnerAddress, TaxDistrict)
/*
Since PropertyAddress, OwnerAddress, and SaleDate were all split or converted into cleaner data,
those original columns are no longer needed and can be removed (TaxDistrict is not useful for this 
analysis either)
*/

Select *
From PortfolioProject.dbo.NashvilleHousing

ALTER TABLE PortfolioProject.dbo.NashvilleHousing
DROP COLUMN PropertyAddress, OwnerAddress, TaxDistrict -- << can put as many columns as wanted in DROP COLUMN argument

ALTER TABLE PortfolioProject.dbo.NashvilleHousing
DROP COLUMN SaleDate




