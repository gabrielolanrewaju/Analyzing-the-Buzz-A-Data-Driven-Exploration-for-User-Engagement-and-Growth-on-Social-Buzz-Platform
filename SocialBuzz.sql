CREATE DATABASE SocialBuzz;
USE SocialBuzz;

/* To clean this dataset

- removing rows that have values which are missing,
- changing the data type of some values within a column, and
- removing columns which are not relevant to this analysis */

-- STARTING WITH THE ReactionTypes  --

SELECT * 
FROM ReactionTypes;

EXEC sp_rename 'ReactionTypes.[Column 0]', 'Index', 'COLUMN';
EXEC sp_rename 'ReactionTypes.[Type]', 'Reaction_type', 'COLUMN';

-- All CLEAN --

-- Next, the Reactions --

SELECT *
FROM Reactions;

--First I have to rename the columns
EXEC sp_rename 'Reactions.[Content ID]', 'Content_ID', 'COLUMN';
EXEC sp_rename 'Reactions.[Column 0]', 'Index', 'COLUMN';
EXEC sp_rename 'Reactions.[User ID]', 'User_ID', 'COLUMN';
EXEC sp_rename 'Reactions.[Type]', 'Reaction_type', 'COLUMN';

-- DROPPING COLUMNS THAT IS NOT NEEDED FOR THIS TASK--

ALTER TABLE Reactions
DROP COLUMN User_ID;


-- Checking for null values

SELECT *
FROM Reactions
WHERE Reaction_type = '' OR Reaction_type IS NULL;

-- Dropping Null Values
DELETE FROM Reactions
WHERE Reaction_type = '' OR Reaction_type IS NULL;


WITH RDuplicateCTE AS (
    SELECT 
        Content_ID, Reaction_type, Datetime, [Index],
        ROW_NUMBER() OVER (PARTITION BY Content_ID, Reaction_type, Datetime, [Index]
		ORDER BY (SELECT NULL)) AS RowNum
    FROM Reactions
)
DELETE FROM RDuplicateCTE WHERE RowNum > 1;



-- ALL CLEAN --


-- NEXT, CONTENT

SELECT *
FROM Content;

--First I have to rename the columns
EXEC sp_rename 'Content.[Content ID]', 'Content_ID', 'COLUMN';
EXEC sp_rename 'Content.[Column 0]', 'Index', 'COLUMN';
EXEC sp_rename 'Content.[User ID]', 'User_ID', 'COLUMN';
EXEC sp_rename 'Content.[Type]', 'Content_type', 'COLUMN';

-- DROPPING COLUMNS THAT IS NOT NEEDED FOR THIS TASK--

ALTER TABLE Content
DROP COLUMN User_ID;

-- CHECKING FOR NULL VALUES

SELECT *
FROM Content
WHERE Category = '' OR Category IS NULL;


-- CHECKING FOR DUPLICTATES --
WITH DuplicateCTE AS (
    SELECT 
        Content_ID, Content_type, Category, [Index],
        ROW_NUMBER() OVER (PARTITION BY Content_ID, Content_type, Category, [Index]
		ORDER BY (SELECT NULL)) AS RowNum
    FROM Content
)
DELETE FROM DuplicateCTE WHERE RowNum > 1;


-- ALL CLEAN NO NULL VALUES


-- JOINING ALL TABLES TOGETHER --

SELECT
    R.*,
    C.Content_type, C.Category, 
    RT.Sentiment, RT.Score
FROM
    Reactions R
JOIN
    Content C ON R.Content_ID = C.Content_ID
JOIN
    ReactionTypes RT ON R.Reaction_type = RT.Reaction_type;


	SELECT
    R.*,
    C.Content_type, C.Category, 
    RT.Sentiment, RT.Score
INTO SB_Merged
FROM
    Reactions R
JOIN
    Content C ON R.Content_ID = C.Content_ID
JOIN
    ReactionTypes RT ON R.Reaction_type = RT.Reaction_type;


SELECT * 
FROM SB_Merged;

	-- Replace values in Category that have (") with () 
UPDATE SB_Merged
SET Category = REPLACE(Category, '"', '');


	-- TO FIND TOP 5 CATEGORIES --

SELECT TOP 5
    Category,
    SUM(Score) AS TotalScore  
FROM
    SB_Merged  
GROUP BY
    Category
ORDER BY
    TotalScore DESC;


	-- CORRECTING ERRORS WITH THE DATATYPE --
sp_help 'SB_Merged';

-- Convert Datetime column to datetime datatype
ALTER TABLE SB_Merged
ALTER COLUMN [Datetime] datetime;

-- Convert Score column to integer datatype
ALTER TABLE SB_Merged
ALTER COLUMN Score INT;



