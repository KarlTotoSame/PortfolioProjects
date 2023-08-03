
-- --------------------------------------------
-- Standardize Date Format 

SELECT saledate
FROM datacleaningproject.nashvillehousingdata;

SELECT DATE_FORMAT(STR_TO_DATE(saledate, '%M %d,%Y'), '%Y-%d-%m') AS saledate
FROM datacleaningproject.nashvillehousingdata;

SET SQL_SAFE_UPDATES = 0;

UPDATE datacleaningproject.nashvillehousingdata
SET saledate=DATE_FORMAT(STR_TO_DATE(saledate, '%M %d,%Y'), '%Y-%d-%m');
 
 
-- --------------------------------------------
-- Populate Property Address data 

SELECT *
FROM datacleaningproject.nashvillehousingdata
WHERE propertyaddress = "";

SELECT *
FROM datacleaningproject.nashvillehousingdata
ORDER BY 2;

SELECT 
     a.parcelid, 
IF(TRIM(a.propertyaddress)="", b.propertyaddress, a.propertyaddress),
	 b.parcelid, 
     b.propertyaddress
FROM datacleaningproject.nashvillehousingdata as a 
JOIN datacleaningproject.nashvillehousingdata as b
ON a.parcelid = b.parcelid
AND a.uniqueid <> b.uniqueid
WHERE a.propertyaddress = "";

UPDATE datacleaningproject.nashvillehousingdata as a
JOIN datacleaningproject.nashvillehousingdata as b
ON a.parcelid = b.parcelid 
AND a.uniqueid <> b.uniqueid
SET a.propertyaddress = IF(TRIM(a.propertyaddress)="", b.propertyaddress, a.propertyaddress)
WHERE a.propertyaddress = "";


-- --------------------------------------------
-- Breaking out Address into  Individual Columns (Address, City, State)

SELECT PropertyAddress
FROM datacleaningproject.nashvillehousingdata;


SELECT
SUBSTRING_INDEX(PropertyAddress,',',+1) AS Address,
SUBSTRING_INDEX(PropertyAddress,',',-1) AS Address2
FROM datacleaningproject.nashvillehousingdata;


ALTER TABLE datacleaningproject.nashvillehousingdata
ADD  PropertySplitAddress TEXT;

UPDATE datacleaningproject.nashvillehousingdata
SET PropertySplitAddress = SUBSTRING_INDEX(PropertyAddress,',',+1);

ALTER TABLE datacleaningproject.nashvillehousingdata
ADD PropertySplitCity TEXT;

UPDATE datacleaningproject.nashvillehousingdata
SET PropertySplitCity = SUBSTRING_INDEX(PropertyAddress,',',-1);

--

SELECT OwnerAddress
FROM datacleaningproject.nashvillehousingdata;

SELECT
SUBSTRING_INDEX(OwnerAddress,',',+1) AS Address,
SUBSTRING_INDEX(SUBSTRING_INDEX(OwnerAddress, ',', 2), ',', -1) as Address2,
SUBSTRING_INDEX(OwnerAddress,',',-1) AS Address3
FROM datacleaningproject.nashvillehousingdata;

SET SQL_SAFE_UPDATES = 0;

ALTER TABLE datacleaningproject.nashvillehousingdata
ADD  OwnerSplitAddress TEXT;

UPDATE datacleaningproject.nashvillehousingdata
SET OwnerSplitAddress = SUBSTRING_INDEX(OwnerAddress,',',+1);

ALTER TABLE datacleaningproject.nashvillehousingdata
ADD OwnerSplitCity TEXT;

UPDATE datacleaningproject.nashvillehousingdata
SET OwnerSplitCity = SUBSTRING_INDEX(SUBSTRING_INDEX(OwnerAddress, ',', 2), ',', -1);

ALTER TABLE datacleaningproject.nashvillehousingdata
ADD OwnerSplitState TEXT;

UPDATE datacleaningproject.nashvillehousingdata
SET OwnerSplitState = SUBSTRING_INDEX(OwnerAddress,',',-1);

--

SELECT *
FROM datacleaningproject.nashvillehousingdata;


-- --------------------------------------------
-- Change Y and N to Yes and No in "Sold as Vacant" Field 

SELECT DISTINCT (SoldAsVacant), COUNT(SoldAsVacant)
FROM datacleaningproject.nashvillehousingdata
GROUP BY SoldAsVacant
ORDER BY 2;

SELECT SoldAsVacant,
CASE WHEN SoldAsVacant ='Y' THEN 'Yes'
     WHEN SoldAsVacant ='N' THEN 'No'
     ELSE SoldAsVacant
     END 
FROM datacleaningproject.nashvillehousingdata;

UPDATE datacleaningproject.nashvillehousingdata
SET SoldAsVacant = 
CASE WHEN SoldAsVacant ='Y' THEN 'Yes'
     WHEN SoldAsVacant ='N' THEN 'No'
     ELSE SoldAsVacant
     END ;


-- --------------------------------------------
-- Remove Duplicates 

SELECT *
FROM datacleaningproject.nashvillehousingdata;

SELECT *,
 ROW_NUMBER() OVER ( PARTITION BY ParcelID, PropertyAddress, SalePrice, SaleDate, LegalReference ORDER BY UniqueID) AS row_num
FROM datacleaningproject.nashvillehousingdata;

SELECT *
FROM (SELECT *, ROW_NUMBER () OVER (PARTITION BY ParcelID, PropertyAddress, SalePrice, SaleDate, LegalReference ORDER BY UniqueID) AS row_num
      FROM datacleaningproject.nashvillehousingdata) as duplicates
WHERE row_num > 1;


WITH RowNumCTE AS (
    SELECT *,
           ROW_NUMBER() OVER (PARTITION BY ParcelID, PropertyAddress, SalePrice, SaleDate, LegalReference ORDER BY UniqueID) AS row_num
    FROM datacleaningproject.nashvillehousingdata
)
DELETE FROM datacleaningproject.nashvillehousingdata
WHERE UniqueID IN (
    SELECT UniqueID
    FROM RowNumCTE
    WHERE row_num > 1
);


-- --------------------------------------------
-- Delete Unused Columns

SELECT *
FROM datacleaningproject.nashvillehousingdata;

ALTER TABLE datacleaningproject.nashvillehousingdata
DROP COLUMN OwnerAddress,
DROP COLUMN PropertyAddress,
DROP COLUMN TaxDistrict;


