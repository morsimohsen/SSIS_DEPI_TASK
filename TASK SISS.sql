USE Olympics;

--2- Create a new table to store the average height and weight of athletes by country.
--The table name is Athlete_Avg_Stats, and it contains country_noc, avg_height, and 
--avg_weight columns.
CREATE TABLE Athlete_Avg_Stats (
    country_noc VARCHAR(4),
    avg_height FLOAT,
    avg_weight FLOAT
);

INSERT INTO Athlete_Avg_Stats
SELECT country_noc, AVG(height) as avg_height, AVG(weight) as avg_weight

--INTO
--Athlete_Avg_Stats

FROM
	Olympic_Athlete_Bio

GROUP BY country_noc





--3- Insert a new record into the Olympics_Country table for a newly recognized country.
--The noc is ‘NEW’ and the country is ‘Newland’

INSERT INTO
	Olympics_Country
VALUES('NEW', 'Newland');



--4- Find all distinct sports from the Olympic_Results table where the number of 
--participants is greater than 20.

SELECT
	DISTINCT(sport) as dist_sports_over_20
FROM
	Olympic_Results
WHERE TRY_CAST(LEFT(result_participants, CHARINDEX(' ', result_participants)) AS INT) > 20;



--5- Classify athletes' performance in Olympic_Athlete_Event_Results as 
--'Winner', 'Runnerup', 'Finalist', or 'Participant' based on their position.
--(1 = Winner, 2 = Runner-Up, less than or equal 8 = Finalist, other is Participant)

SELECT
	top (100) *, 
	CASE
		WHEN TRY_CAST(pos AS INT) = 1 THEN 'Winner'
		WHEN TRY_CAST(pos AS INT) = 2 THEN 'Runner'
		WHEN TRY_CAST(pos AS INT)  <= 8 THEN 'Finalist'
		ELSE 'Participant'
	END AS performance
FROM
	Olympic_Athlete_Event_Results;




--	6- Retrieve the top 10 events with the most participants, ordered by the number of 
--participants in descending order.

SELECT
	event_title, TRY_CAST(LEFT(result_participants, CHARINDEX(' ', result_participants)) AS INT) as Participants, edition
FROM
	Olympic_Results

ORDER BY Participants DESC;




--7- Get the top 5 athletes who have won the most medals

SELECT 
    athlete,
    athlete_id,
    COUNT(medal) AS medal_count
FROM 
    Olympic_Athlete_Event_Results
WHERE 
    medal IS NOT NULL  -- Ensure we're only counting actual medals
GROUP BY 
    athlete,
    athlete_id
ORDER BY 
    medal_count DESC
OFFSET 0 ROWS 
FETCH NEXT 5 ROWS ONLY;  -- Get top 5 athletes





--8- Replace null values in the description column of Olympic_Athlete_Bio with 'No 
--description available'. (Use SELECT)

SELECT
	COALESCE(description, 'No description available') as description
FROM
	Olympic_Athlete_Bio;




--9- Convert the born date in Olympic_Athlete_Bio to the year only.
--Give an alias ‘birth_year’ to the new column. (Use SELECT)

SELECT
	top 100 *, YEAR(born) as birth_year

FROM
	Olympic_Athlete_Bio;




--10- Retrieve the athlete name and their country in one column.
SELECT
	top 100 *, CONCAT(name, '-From-', country) as athlete_name_country

FROM
	Olympic_Athlete_Bio;





--11- Retrieve the first three letters of the athletes' names in uppercase.
SELECT
	top 100 *, UPPER(SUBSTRING(name, 1, 3)) as athlete_intial

FROM
	Olympic_Athlete_Bio;


--12- Find the current date and time of the server as current_datetime.

SELECT
	SYSDATETIMEOFFSET() as current_datetime;



--13- Create a new table called ‘Country_Medal_Count’ with the total number of medals won 
--by each country and insert the data.

--Step 1: Create the Table
CREATE TABLE Country_Medal_Count (
    country_noc VARCHAR(4) PRIMARY KEY,
    total_medals INT
);
--Step 2: Insert Data

INSERT INTO Country_Medal_Count (country_noc, total_medals)
SELECT 
    country_noc,
    COUNT(medal) AS total_medals
FROM 
    Olympic_Athlete_Event_Results
WHERE 
    medal IS NOT NULL  -- Ensure we're only counting actual medals
GROUP BY 
    country_noc;





--14- Find the total number of medals won by each country that has won more than 10 
--medals.

SELECT
	*
FROM
	Country_Medal_Count
WHERE total_medals > 10;




--15- Rank athletes within each sport by the number of medals won.
SELECT 
    athlete,
    athlete_id,
    sport,
    COUNT(medal) AS medal_count,
    DENSE_RANK() OVER (PARTITION BY sport ORDER BY COUNT(medal) DESC) AS rank
FROM 
    Olympic_Athlete_Event_Results
WHERE 
    medal IS NOT NULL  -- Ensure we're only counting actual medals
GROUP BY 
    athlete,
    athlete_id,
    sport
ORDER BY 
    sport, rank;  -- Order by sport and then by rank


--16- Classify countries based on total medals won as 'High', 'Medium', or 'Low'.
--(more than 50 = ‘High’, between 20 and 50 = ‘Medium, other = ‘Low’).

SELECT
	*,
	CASE
		WHEN total_medals > 50 THEN 'High'
		WHEN total_medals BETWEEN 20 AND 50 THEN 'Medium'
		ELSE 'Low'

	END as top_winners_countries
		
FROM
	Country_Medal_Count;




--17- Create a stored procedure to get the medal tally for a specific country and year.
CREATE PROC GetMedalTally (
	@year INT,
	@noc NVARCHAR(4)
)
AS

BEGIN
	SET NOCOUNT ON; -- Prevents row count messages

    SELECT
        country,
        SUM(gold) AS TotalGold,
        SUM(silver) AS TotalSilver,
        SUM(bronze) AS TotalBronze,
        SUM(total) AS TotalMedals
    FROM
        Olympic_Games_Medal_Tally
    WHERE
        year = @Year AND
        country_noc = @noc
    GROUP BY
        country;

END;


EXEC GetMedalTally @Year = 1896, @noc = 'USA';






--18- Store the total number of medals won by a specific country -ex: ‘USA’- in a variable.
DECLARE @TotalMedals INT;
DECLARE @CountryNOC VARCHAR(4) = 'USA';

SELECT @TotalMedals = SUM(total)
FROM 
	Olympic_Games_Medal_Tally
WHERE 
	UPPER(country_noc) = @CountryNOC;

-- Optionally, you can print the result
PRINT 'Total medals won by ' + @CountryNOC + ': ' + CAST(@TotalMedals AS VARCHAR);




--19- Create a dynamic SQL statement to retrieve medal data for a specific sport.


DECLARE @Sport NVARCHAR(100) = 'Boxing';  -- Example sport
DECLARE @SQL NVARCHAR(MAX);

-- Build dynamic SQL statement
SET @SQL = N'SELECT *
            FROM [Olympics].[dbo].[Olympic_Athlete_Event_Results]
            WHERE sport = @Sport AND medal IS NOT NULL';

-- Execute the dynamic SQL with the sport parameter
EXEC sp_executesql @SQL, N'@Sport NVARCHAR(100)', @Sport;















--20- Check if a country has won more than 50 medals then print the country name and ‘High 
--Medal Count’, if not, print ‘Low Medal Count’ behind the country name.
SELECT 
    country_noc,
    SUM(gold + silver + bronze) AS total_medals,
    CASE 
        WHEN SUM(gold + silver + bronze) > 50 THEN country_noc + ' High Medal Count'
        ELSE country_noc + ' Low Medal Count'
    END AS medal_status
FROM Olympic_Games_Medal_Tally
GROUP BY country_noc;




--21- Loop through each athlete in a list and print their name along with their country
DECLARE @athlete_name NVARCHAR(255);
DECLARE @country NVARCHAR(255);

DECLARE athlete_cursor CURSOR FOR
SELECT name, country
FROM Olympic_Athlete_Bio;

-- Open the cursor
OPEN athlete_cursor;

FETCH NEXT FROM athlete_cursor INTO @athlete_name, @country;

-- Loop through the cursor until no more rows are returned
WHILE @@FETCH_STATUS = 0
BEGIN
    PRINT 'Athlete: ' + @athlete_name + ', Country: ' + @country;
    
    -- Fetch the next row
    FETCH NEXT FROM athlete_cursor INTO @athlete_name, @country;
END;

CLOSE athlete_cursor;

DEALLOCATE athlete_cursor;




--22- Find the athletes who have participated in more than one edition of the Olympics.
SELECT 
    athlete_id,
    COUNT(DISTINCT edition) AS edition_count
FROM 
    Olympic_Athlete_Event_Results
GROUP BY 
    athlete_id
HAVING 
    COUNT(DISTINCT edition) > 1;



SELECT 
    athlete_id,
    name
FROM 
    Olympic_Athlete_Bio a
WHERE 
    athlete_id IN (
        SELECT 
            athlete_id
        FROM 
            Olympic_Athlete_Event_Results
        WHERE 
            medal IS NOT NULL
        GROUP BY 
            athlete_id
        HAVING 
            COUNT(DISTINCT CASE 
                WHEN edition LIKE '%Winter%' THEN 'Winter'
                WHEN edition LIKE '%Summer%' THEN 'Summer'
            END) = 2
    );





--24- Create a stored procedure UpdateAthleteInfo that takes an athlete's ID, a column name, 
--and a new value as input parameters. It updates the specified column for the given 
--athlete with the new value.
CREATE PROC UpdateAthleteInfo
    @athlete_id INT,
    @column_name NVARCHAR(255),
    @new_value NVARCHAR(255)
AS
BEGIN
    DECLARE @sql NVARCHAR(MAX);

    SET @sql = N'UPDATE [Olympics].[dbo].[Olympic_Athlete_Bio] SET ' + QUOTENAME(@column_name) + ' = @value WHERE athlete_id = @id';

    -- Execute the dynamic SQL
    EXEC sp_executesql @sql, 
                       N'@value NVARCHAR(255), @id INT',
                       @value = @new_value, 
                       @id = @athlete_id;
END;

EXEC UpdateAthleteInfo @athlete_id = 89986, @column_name = 'height', @new_value = '163';
--SELECT 
--	*
--FROM
--	Olympic_Athlete_Bio
--where athlete_id = 89986



--25- Create a stored procedure GetAthletesByMedalType that takes a medal type as an input 
--parameter and dynamically generates a report of athletes who have won that type of 
--medal.

CREATE PROC GetAthletesByMedalType (
	@medal_type NVARCHAR(20)
)

AS
BEGIN
	SELECT
		edition, edition_id, athlete, athlete_id, medal
	FROM Olympic_Athlete_Event_Results
	WHERE medal = @medal_type
END;

EXEC GetAthletesByMedalType @medal_type = 'gold';




----------------------========================================================


--2- Business Reports:





--1- Analyze the Performance of Athletes Across Multiple Editions and Determine Medal 
--Trends
--Description: Create a report that shows the total number of medals won by athletes who 
--have participated in at least two editions of the Olympics. For each athlete, display their 
--name, country, the total medals won, the average position, and a classification based on
--the total number of medals as 'Exceptional', 'Outstanding', or 'Remarkable'. Include athletes' 
--participation and performance details. The total medals should order the results won, and 
--handle cases where some athletes might miss data

WITH WON_ATHLETE_MEDELS AS (

SELECT 
	DISTINCT(athlete_id),
	athlete,
	country_noc,
	AVG(TRY_CAST(pos AS INT)) OVER (PARTITION BY athlete_id) as avg_pos,
	COUNT(*) OVER (PARTITION BY athlete_id ORDER BY athlete_id) as Medal_athlete_won_n
FROM 
	Olympic_Athlete_Event_Results

WHERE
	medal IS NOT NULL
)
SELECT
	w.*,
	c.country,
	 CASE 
        WHEN Medal_athlete_won_n > 10 THEN 'Exceptional'
        WHEN Medal_athlete_won_n BETWEEN 5 AND 10 THEN 'Outstanding'
        ELSE 'Remarkable'
    END AS classification
FROM
	WON_ATHLETE_MEDELS as w
INNER JOIN
	Olympics_Country as c
	ON w.country_noc = c.noc
WHERE
	Medal_athlete_won_n > 1

ORDER BY 
    Medal_athlete_won_n DESC, avg_pos ASC;






















	WITH Medal_Winners AS (
    SELECT 
        medal.country_noc,
        medal.edition,
        SUM(medal.gold + medal.silver + medal.bronze) AS total_medals
    FROM 
        Olympic_Games_Medal_Tally medal
    JOIN 
        Olympics_Games games ON medal.edition = games.edition
    WHERE 
        games.isHeld = @OlympicType  -- Summer or Winter (dynamic input)
    GROUP BY 
        medal.country_noc, medal.edition
),
Country_Participation AS (
    SELECT 
        games.country_noc,
        COUNT(DISTINCT games.edition) AS total_editions
    FROM 
        Olympics_Games games
    WHERE 
        games.isHeld = @OlympicType  -- Summer or Winter (dynamic input)
    GROUP BY 
        games.country_noc
),
Consistent_Countries AS (
    SELECT 
        p.country_noc,
        p.total_editions,
        SUM(m.total_medals) AS total_medals,
        AVG(m.total_medals) AS avg_medals_per_edition
    FROM 
        Country_Participation p
    JOIN 
        Medal_Winners m ON p.country_noc = m.country_noc
    WHERE 
        p.total_editions = (SELECT COUNT(DISTINCT m2.edition) FROM Medal_Winners m2 WHERE m2.country_noc = p.country_noc)
    GROUP BY 
        p.country_noc, p.total_editions
)
SELECT 
    country_noc AS country,
    total_editions,
    total_medals,
    avg_medals_per_edition,
    CASE 
        WHEN avg_medals_per_edition > 5 THEN 'Highly Consistent'
        WHEN avg_medals_per_edition BETWEEN 3 AND 5 THEN 'Moderately Consistent'
        ELSE 'Inconsistent'
    END AS consistency_classification
FROM 
    Consistent_Countries
ORDER BY 
    total_medals DESC;

