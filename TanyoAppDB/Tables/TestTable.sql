CREATE TABLE dbo.TestTable
(
    WorkflowTestTableId INT IDENTITY(1,1) NOT NULL
        CONSTRAINT PK_WorkflowTestTable PRIMARY KEY,
    TestName NVARCHAR(100) NOT NULL,
    IsActive BIT NOT NULL
        CONSTRAINT DF_WorkflowTestTable_IsActive DEFAULT (1),
    CreatedDate DATETIME2(7) NOT NULL
        CONSTRAINT DF_WorkflowTestTable_CreatedDate DEFAULT (SYSDATETIME())
);