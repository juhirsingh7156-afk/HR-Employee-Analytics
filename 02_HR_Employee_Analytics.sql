/*
PROJECT 2: HR EMPLOYEE ANALYTICS
Platform: Microsoft SQL Server / SSMS
Re-running rebuilds tables and sample data.
*/
IF DB_ID(N'HRAnalyticsDB') IS NULL CREATE DATABASE HRAnalyticsDB;
GO
USE HRAnalyticsDB;
GO
DROP VIEW IF EXISTS dbo.vw_EmployeeDirectory;
DROP PROCEDURE IF EXISTS dbo.usp_DepartmentHeadcount;
DROP TABLE IF EXISTS dbo.PerformanceReviews;
DROP TABLE IF EXISTS dbo.Employees;
DROP TABLE IF EXISTS dbo.Departments;
GO
CREATE TABLE dbo.Departments(
 DepartmentID INT IDENTITY(1,1) PRIMARY KEY,
 DepartmentName NVARCHAR(80) NOT NULL UNIQUE,
 DepartmentBudget DECIMAL(14,2) NOT NULL CHECK(DepartmentBudget>=0)
);
CREATE TABLE dbo.Employees(
 EmployeeID INT IDENTITY(1,1) PRIMARY KEY,
 FirstName NVARCHAR(60) NOT NULL,
 LastName NVARCHAR(60) NOT NULL,
 Email NVARCHAR(150) NOT NULL UNIQUE,
 DepartmentID INT NOT NULL REFERENCES dbo.Departments(DepartmentID),
 JobTitle NVARCHAR(100) NOT NULL,
 HireDate DATE NOT NULL,
 Salary DECIMAL(12,2) NOT NULL CHECK(Salary>=0),
 EmploymentStatus VARCHAR(20) NOT NULL CHECK(EmploymentStatus IN ('Active','On Leave','Terminated')),
 ManagerID INT NULL REFERENCES dbo.Employees(EmployeeID),
 City NVARCHAR(80) NOT NULL
);
CREATE TABLE dbo.PerformanceReviews(
 ReviewID INT IDENTITY(1,1) PRIMARY KEY,
 EmployeeID INT NOT NULL REFERENCES dbo.Employees(EmployeeID),
 ReviewDate DATE NOT NULL,
 Rating TINYINT NOT NULL CHECK(Rating BETWEEN 1 AND 5),
 ReviewerComment NVARCHAR(300) NULL
);
CREATE INDEX IX_Employees_Department_Status ON dbo.Employees(DepartmentID,EmploymentStatus);
CREATE INDEX IX_Employees_HireDate ON dbo.Employees(HireDate);
GO
INSERT dbo.Departments(DepartmentName,DepartmentBudget) VALUES
(N'Engineering',1800000),(N'Sales',900000),(N'Human Resources',450000),
(N'Finance',650000),(N'Customer Support',550000),(N'Marketing',700000);
INSERT dbo.Employees(FirstName,LastName,Email,DepartmentID,JobTitle,HireDate,Salary,EmploymentStatus,ManagerID,City) VALUES
(N'Neha',N'Kapoor','neha.kapoor@company.test',1,N'Engineering Manager','2019-03-12',1450000,'Active',NULL,N'Pune'),
(N'Arjun',N'Bose','arjun.bose@company.test',2,N'Sales Manager','2020-06-01',1250000,'Active',NULL,N'Mumbai'),
(N'Ishita',N'Reddy','ishita.reddy@company.test',3,N'HR Manager','2018-11-19',1100000,'Active',NULL,N'Bengaluru'),
(N'Karan',N'Jain','karan.jain@company.test',1,N'Data Analyst','2022-01-10',850000,'Active',1,N'Pune'),
(N'Zoya',N'Fernandes','zoya.fernandes@company.test',1,N'SQL Developer','2021-08-23',980000,'Active',1,N'Mumbai'),
(N'Dev',N'Patil','dev.patil@company.test',1,N'QA Engineer','2023-02-15',720000,'On Leave',1,N'Pune'),
(N'Riya',N'Chawla','riya.chawla@company.test',2,N'Account Executive','2022-04-04',680000,'Active',2,N'Delhi'),
(N'Om',N'Singh','om.singh@company.test',2,N'Sales Analyst','2024-01-22',610000,'Active',2,N'Mumbai'),
(N'Meera',N'Kulkarni','meera.kulkarni@company.test',3,N'HR Specialist','2021-05-17',640000,'Active',3,N'Bengaluru'),
(N'Rahul',N'Verma','rahul.verma@company.test',4,N'Financial Analyst','2020-09-08',790000,'Active',NULL,N'Delhi'),
(N'Simran',N'Gill','simran.gill@company.test',5,N'Support Lead','2019-12-02',760000,'Active',NULL,N'Mumbai'),
(N'Aditya',N'Rao','aditya.rao@company.test',5,N'Support Associate','2023-07-11',460000,'Terminated',11,N'Pune'),
(N'Tara',N'Menon','tara.menon@company.test',6,N'Marketing Specialist','2022-10-31',700000,'Active',NULL,N'Bengaluru'),
(N'Vikram',N'Shah','vikram.shah@company.test',4,N'Accountant','2024-03-18',570000,'Active',10,N'Ahmedabad'),
(N'Anil',N'Kumar','anil.kumar@company.test',1,N'Junior Developer','2025-01-06',520000,'Active',1,N'Delhi');
INSERT dbo.PerformanceReviews(EmployeeID,ReviewDate,Rating,ReviewerComment) VALUES
(1,'2025-01-15',5,N'Strong leadership'),(2,'2025-01-20',4,N'Consistently meets goals'),
(3,'2025-02-02',5,N'Excellent people management'),(4,'2025-02-10',4,N'Good analytical skills'),
(5,'2025-02-12',5,N'High-quality delivery'),(6,'2025-02-18',3,N'Meets expectations'),
(7,'2025-03-01',4,N'Good client relationships'),(8,'2025-03-04',3,N'Improving pipeline discipline'),
(9,'2025-03-09',4,N'Reliable execution'),(10,'2025-03-15',4,N'Accurate reporting'),
(11,'2025-03-18',5,N'Excellent support leadership'),(13,'2025-04-02',4,N'Effective campaigns'),
(14,'2025-04-12',3,N'Needs further development'),(15,'2025-04-20',4,N'Fast learner');
GO
CREATE VIEW dbo.vw_EmployeeDirectory AS
SELECT e.EmployeeID,CONCAT(e.FirstName,N' ',e.LastName) AS EmployeeName,e.Email,
 d.DepartmentName,e.JobTitle,e.HireDate,e.Salary,e.EmploymentStatus,e.City,
 DATEDIFF(YEAR,e.HireDate,GETDATE()) AS ApproxYearsOfService
FROM dbo.Employees e JOIN dbo.Departments d ON d.DepartmentID=e.DepartmentID;
GO
CREATE PROCEDURE dbo.usp_DepartmentHeadcount
 @IncludeTerminated BIT=0
AS
BEGIN
 SET NOCOUNT ON;
 SELECT d.DepartmentName,
        SUM(CASE WHEN e.EmploymentStatus='Active' THEN 1 ELSE 0 END) AS ActiveEmployees,
        SUM(CASE WHEN e.EmploymentStatus='On Leave' THEN 1 ELSE 0 END) AS EmployeesOnLeave,
        SUM(CASE WHEN e.EmploymentStatus='Terminated' THEN 1 ELSE 0 END) AS TerminatedEmployees,
        CAST(SUM(CASE WHEN e.EmploymentStatus='Active' THEN e.Salary ELSE 0 END) AS DECIMAL(14,2)) AS ActivePayroll
 FROM dbo.Departments d LEFT JOIN dbo.Employees e ON e.DepartmentID=d.DepartmentID
 WHERE @IncludeTerminated=1 OR e.EmploymentStatus<>'Terminated' OR e.EmployeeID IS NULL
 GROUP BY d.DepartmentName ORDER BY ActiveEmployees DESC,d.DepartmentName;
END;
GO
-- 1. Workforce KPIs
SELECT COUNT(*) AS TotalEmployees,
 SUM(CASE WHEN EmploymentStatus='Active' THEN 1 ELSE 0 END) AS ActiveEmployees,
 SUM(CASE WHEN EmploymentStatus='On Leave' THEN 1 ELSE 0 END) AS OnLeave,
 SUM(CASE WHEN EmploymentStatus='Terminated' THEN 1 ELSE 0 END) AS Terminated
FROM dbo.Employees;
-- 2. Headcount by department and status
SELECT d.DepartmentName,e.EmploymentStatus,COUNT(*) AS EmployeeCount
FROM dbo.Employees e JOIN dbo.Departments d ON d.DepartmentID=e.DepartmentID
GROUP BY d.DepartmentName,e.EmploymentStatus ORDER BY d.DepartmentName,e.EmploymentStatus;
-- 3. Salary cost and average salary by department (active staff only)
SELECT d.DepartmentName,COUNT(*) AS ActiveHeadcount,
 CAST(SUM(e.Salary) AS DECIMAL(14,2)) AS AnnualSalaryCost,
 CAST(AVG(e.Salary) AS DECIMAL(12,2)) AS AverageSalary
FROM dbo.Employees e JOIN dbo.Departments d ON d.DepartmentID=e.DepartmentID
WHERE e.EmploymentStatus='Active'
GROUP BY d.DepartmentName ORDER BY AnnualSalaryCost DESC;
-- 4. Highest-paid employees
SELECT TOP 5 EmployeeID,CONCAT(FirstName,' ',LastName) AS EmployeeName,JobTitle,Salary
FROM dbo.Employees WHERE EmploymentStatus='Active' ORDER BY Salary DESC;
-- 5. Average performance rating by department
SELECT d.DepartmentName,CAST(AVG(CAST(pr.Rating AS DECIMAL(4,2))) AS DECIMAL(4,2)) AS AverageRating,
 COUNT(pr.ReviewID) AS ReviewCount
FROM dbo.Departments d JOIN dbo.Employees e ON e.DepartmentID=d.DepartmentID
LEFT JOIN dbo.PerformanceReviews pr ON pr.EmployeeID=e.EmployeeID
GROUP BY d.DepartmentName ORDER BY AverageRating DESC;
-- 6. Employees hired by year
SELECT YEAR(HireDate) AS HireYear,COUNT(*) AS Hires
FROM dbo.Employees GROUP BY YEAR(HireDate) ORDER BY HireYear;
-- 7. Employees earning above their department's average
WITH DepartmentSalary AS (
 SELECT DepartmentID,AVG(Salary) AS AvgSalary FROM dbo.Employees
 WHERE EmploymentStatus='Active' GROUP BY DepartmentID
)
SELECT e.EmployeeID,CONCAT(e.FirstName,' ',e.LastName) AS EmployeeName,d.DepartmentName,e.Salary,
 CAST(ds.AvgSalary AS DECIMAL(12,2)) AS DepartmentAverage
FROM dbo.Employees e JOIN DepartmentSalary ds ON ds.DepartmentID=e.DepartmentID
JOIN dbo.Departments d ON d.DepartmentID=e.DepartmentID
WHERE e.EmploymentStatus='Active' AND e.Salary>ds.AvgSalary ORDER BY d.DepartmentName,e.Salary DESC;
-- 8. Tenure bands
SELECT CASE WHEN DATEDIFF(MONTH,HireDate,GETDATE())<12 THEN 'Under 1 year'
 WHEN DATEDIFF(MONTH,HireDate,GETDATE())<36 THEN '1-3 years'
 WHEN DATEDIFF(MONTH,HireDate,GETDATE())<60 THEN '3-5 years'
 ELSE '5+ years' END AS TenureBand,COUNT(*) AS Employees
FROM dbo.Employees WHERE EmploymentStatus='Active'
GROUP BY CASE WHEN DATEDIFF(MONTH,HireDate,GETDATE())<12 THEN 'Under 1 year'
 WHEN DATEDIFF(MONTH,HireDate,GETDATE())<36 THEN '1-3 years'
 WHEN DATEDIFF(MONTH,HireDate,GETDATE())<60 THEN '3-5 years' ELSE '5+ years' END;
-- 9. View and procedure examples
SELECT * FROM dbo.vw_EmployeeDirectory ORDER BY DepartmentName,EmployeeName;
EXEC dbo.usp_DepartmentHeadcount @IncludeTerminated=0;
-- 10. Data-quality checks
SELECT Email,COUNT(*) AS DuplicateCount FROM dbo.Employees GROUP BY Email HAVING COUNT(*)>1;
SELECT * FROM dbo.Employees WHERE HireDate>CAST(GETDATE() AS DATE) OR Salary<0;
GO
