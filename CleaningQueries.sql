SELECT * 
FROM CleaningHouse..NashvilleHousing






-- Standardize date format
SELECT SaleDate, CONVERT(Date, SaleDate)
FROM CleaningHouse..NashvilleHousing

ALTER TABLE CleaningHouse..NashvilleHousing
ALTER COLUMN SaleDate Date

SELECT SaleDate
FROM CleaningHouse..NashvilleHousing





-- Populate Property Address Data
SELECT *
FROM CleaningHouse..NashvilleHousing
WHERE PropertyAddress is null
ORDER BY ParcelID

SELECT house1.ParcelID, house1.PropertyAddress, house2.ParcelID, house2.PropertyAddress, ISNULL(house1.PropertyAddress, house2.PropertyAddress)
FROM CleaningHouse..NashvilleHousing house1
Join CleaningHouse..NashvilleHousing house2
	ON house1.ParcelID = house2.ParcelID
	AND house1.[UniqueID ] <> house2.[UniqueID ]
WHERE house1.PropertyAddress is null

UPDATE house1
SET PropertyAddress = ISNULL(house1.PropertyAddress, house2.PropertyAddress)
FROM CleaningHouse..NashvilleHousing house1
Join CleaningHouse..NashvilleHousing house2
	ON house1.ParcelID = house2.ParcelID
	AND house1.[UniqueID ] <> house2.[UniqueID ]






-- Breaking out Address into Individual Columns (Address, City, State)
-- Property Address
SELECT PropertyAddress
FROM CleaningHouse..NashvilleHousing

SELECT SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress)-1) as Address,
SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress)+2, LEN(PropertyAddress)) as City
FROM CleaningHouse..NashvilleHousing

ALTER TABLE CleaningHouse..NashvilleHousing
ADD SplitAddress NVARCHAR(255), SplitCity NVARCHAR(255)

UPDATE CleaningHouse..NashvilleHousing
SET SplitAddress = SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress)-1), 
SplitCity = SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress)+2, LEN(PropertyAddress))

SELECT PropertyAddress, SplitAddress, SplitCity
FROM CleaningHouse..NashvilleHousing






-- Owner Address
SELECT PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3) as SplitOwnerAddress,
PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2) as SplitOwnerCity,
PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1) as SplitOwnerState
FROM CleaningHouse..NashvilleHousing

ALTER TABLE CleaningHouse..NashvilleHousing
ADD SplitOwnerAddress NVARCHAR(255), SplitOwnerCity NVARCHAR(255), SplitOwnerState NVARCHAR(255)

UPDATE CleaningHouse..NashvilleHousing
SET SplitOwnerAddress = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3), 
SplitOwnerCity = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2),
SplitOwnerState = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1)

SELECT OwnerAddress, SplitOwnerAddress, SplitOwnerCity, SplitOwnerState
FROM CleaningHouse..NashvilleHousing






-- Change Y and N to Yes and No in Sold as Vacant field
UPDATE CleaningHouse..NashvilleHousing 
SET SoldAsVacant = 
	CASE WHEN SoldAsVacant = 'Y' THEN 'Yes'
		 WHEN SoldAsVacant = 'N' THEN 'No'
		 Else SoldAsVacant
		 End

Select distinct(SoldAsVacant), COUNT(SoldAsVacant)
FROM CleaningHouse..NashvilleHousing
Group By SoldAsVacant






-- Remove Duplicates
SELECT * FROM CleaningHouse..NashvilleHousing

WITH DuplicateCheck AS(
SELECT * , 
	ROW_NUMBER() OVER (
	PARTITION BY ParcelID,
				PropertyAddress,
				SalePrice,
				SaleDate,
				LegalReference
				ORDER BY UniqueID) AS dupcheck	   
FROM CleaningHouse..NashvilleHousing
)
DELETE FROM DuplicateCheck
WHERE dupcheck >1






-- DELETE Unused Columns
ALTER TABLE CleaningHouse..NashvilleHousing
DROP COLUMN OwnerAddress, TaxDistrict, PropertyAddress

SELECT * 
FROM CleaningHouse..NashvilleHousing