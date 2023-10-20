CREATE DATABASE  TouristAgency 
GO

USE TouristAgency 
GO

--ex1
CREATE TABLE Countries(
Id INT PRIMARY KEY IDENTITY(1,1),
[Name] NVARCHAR(50) NOT NULL
)

CREATE TABLE Destinations(
Id INT PRIMARY KEY IDENTITY(1,1),
[Name] NVARCHAR(50) NOT NULL,
CountryId INT NOT NULL FOREIGN KEY REFERENCES Countries(Id)
)

CREATE TABLE Rooms(
Id INT PRIMARY KEY IDENTITY(1,1),
[Type] NVARCHAR(40) NOT NULL,
Price DECIMAL(18,2)NOT NULL,
BedCount INT NOT NULL,
CHECK (BedCount > 0),
CHECK (BedCount<=10)
)

CREATE TABLE Hotels(
Id INT PRIMARY KEY IDENTITY(1,1),
[Name] NVARCHAR(50) NOT NULL,
DestinationId INT NOT NULL FOREIGN KEY REFERENCES Destinations(Id)
)

CREATE TABLE Tourists(
Id INT PRIMARY KEY IDENTITY(1,1),
[Name] NVARCHAR(80) NOT NULL,
PhoneNumber NVARCHAR(20) NOT NULL,
Email NVARCHAR(80),
CountryId INT NOT NULL FOREIGN KEY REFERENCES Countries(Id)
)

CREATE TABLE Bookings(
Id INT PRIMARY KEY IDENTITY(1,1),
ArrivalDate DateTime2 NOT NULL ,
DepartureDate DateTime2 NOT NULL ,
AdultsCount INT NOT NULL ,
CHECK (AdultsCount >=1),
CHECK (AdultsCount <=10),
ChildrenCount INT NOT NULL ,
CHECK (ChildrenCount >=0),
CHECK (ChildrenCount <= 9),
TouristId INT NOT NULL FOREIGN KEY REFERENCES Tourists(Id),
HotelId INT NOT NULL FOREIGN KEY REFERENCES Hotels(Id),
RoomId INT NOT NULL FOREIGN KEY REFERENCES Rooms(Id)
)

CREATE TABLE HotelsRooms(
HotelId INT NOT NULL FOREIGN KEY REFERENCES Hotels(Id),
RoomId INT NOT NULL FOREIGN KEY REFERENCES Rooms(Id),
PRIMARY KEY(HotelId , RoomId)
)

--ex2

INSERT INTO Tourists([Name], PhoneNumber , Email ,CountryId )
VALUES
('John Rivers',	'653-551-1555',	'john.rivers@example.com' ,6),
('Adeline Aglaé' ,'122-654-8726', 'adeline.aglae@example.com', 2),
('Sergio Ramirez', '233-465-2876',	's.ramirez@example.com' , 3),
('Johan Müller', '322-876-9826',	'j.muller@example.com',	7),
('Eden Smith', '551-874-2234', 'eden.smith@example.com', 6)

INSERT INTO Bookings(ArrivalDate, DepartureDate , AdultsCount ,ChildrenCount, TouristId,HotelId,RoomId)
VALUES
('2024-03-01',	'2024-03-11', 1,	0,	21,	3	,5)	,
('2023-12-28',	'2024-01-06', 2,	1,	22,	13	,3)	,
('2023-11-15',	'2023-11-20', 1,	2,	23,	19	,7)	,
('2023-12-05',	'2023-12-09', 4,	0,	24,	6	,4)	,
('2024-05-01',	'2024-05-07', 6,	0,	25,	14	,6)


--ex3
SELECT [DepartureDate]
 FROM Bookings
 WHERE YEAR([DepartureDate] ) = 2023 AND MONTH([DepartureDate]) = 12

SELECT *
FROM Tourists
WHERE [Name] LIKE '%MA%'

--ex
UPDATE Bookings
SET DepartureDate = DATEADD(DAY, 1, DepartureDate)
WHERE YEAR([DepartureDate] ) = 2023 AND MONTH([DepartureDate]) = 12

UPDATE Tourists
SET Email = NULL
WHERE [Name] LIKE '%MA%'

--ex 4

SELECT * 
FROM Tourists
WHERE [Name] LIKE '%Smith%'

--id is 6 , 16 , 25 
SELECT * 
FROM Bookings
WHERE TouristId = 6 OR TouristId = 16 OR TouristId =  25

--ex
DELETE  
FROM Bookings
WHERE TouristId = 6 OR TouristId = 16 OR TouristId =  25

DELETE 
FROM Tourists
WHERE [Name] LIKE '%Smith%'


--ex 5

SELECT 
FORMAT(ArrivalDate, 'yyyy-MM-dd' ) AS ArrivalDate 
,AdultsCount
,ChildrenCount
FROM Bookings b
JOIN Rooms r ON r.Id = b.RoomId
ORDER BY r.Price desc , ArrivalDate asc

--ex 6
SELECT h.Id, h.[Name] 
FROM Hotels h
JOIN HotelsRooms hr ON hr.HotelId = h.Id
JOIN Rooms r  ON r.Id = hr.RoomId
JOIN Bookings b ON b.HotelId = h.Id
WHERE r.[Type] = 'VIP Apartment'
GROUP BY h.Id , h.[Name]
ORDER BY COUNT(b.Id) DESC

--ex7 
SELECT  t.Id,t.[Name] , t.PhoneNumber
FROM Tourists t 
LEFT JOIN Bookings b ON b.TouristId = t.Id
WHERE b.TouristId IS NULL
ORDER BY t.[Name]

--ex8
SELECT TOP(10) 
h.[Name] AS HotelName
, d.[Name] AS DestinationName
, c.[Name] AS CountryName
FROM Bookings b
JOIN Hotels h ON h.Id =b.HotelId 
JOIN Destinations d ON d.Id = h.DestinationId
JOIN Countries c ON c.Id = d.CountryId
WHERE ArrivalDate < '2023-12-31' AND
HotelId % 2 != 0
ORDER BY c.[Name] asc ,b.ArrivalDate asc

--ex9

SELECT h.[Name] , r.Price
FROM Tourists t
JOIN Bookings b ON b.TouristId = t.Id
JOIN Hotels h ON h.Id = b.HotelId
JOIN Rooms r ON r.Id = b.RoomId
WHERE t.[Name] NOT LIKE '%EZ'
ORDER BY r.Price desc

--ex10 

SELECT
h.[Name],
SUM(DATEDIFF(DAY, b.ArrivalDate, b.DepartureDate)*r.Price) AS HotelRevenue
FROM Hotels h
JOIN Bookings b ON h.Id = b.HotelId 
JOIN Rooms r ON b.RoomId = r.Id
GROUP BY h.[Name]
ORDER BY HotelRevenue DESC

--ex11
CREATE FUNCTION udf_RoomsWithTourists(@name NVARCHAR(50)) 
RETURNS INT 
BEGIN 
	DECLARE @total INT = 
	(
		SELECT 
		SUM(b.AdultsCount)+
		SUM(b.ChildrenCount)
		FROM Rooms r
		JOIN Bookings b ON b.RoomId =r.Id 
		JOIN Tourists t ON   b.RoomId = t.Id
		WHERE r.[Type]=@name
	)
	RETURN @total
	
END
--ex12
CREATE PROCEDURE usp_SearchByCountry(@country NVARCHAR(50)) 
AS 
  SELECT t.[Name] 
  ,t.PhoneNumber 
  ,t.Email
  , COUNT(t.[Name]) AS CountOfBookings
  FROM Tourists t
  JOIN Countries c ON c.Id = t.CountryId
   JOIN Bookings b ON b.TouristId = t.Id 
  WHERE c.[Name] = @country
  GROUP BY t.[Name]  ,t.PhoneNumber ,t.Email
  ORDER BY t.[Name] asc , CountOfBookings desc

  EXEC usp_SearchByCountry 'Greece'