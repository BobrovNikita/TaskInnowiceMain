/*
use BanksTask
Create tables and references
CREATE TABLE Banks 
(
	[IdBank] INT NOT NULL IDENTITY(1,1) PRIMARY KEY,
	[Name] NVARCHAR(30) NOT NULL
);

CREATE TABLE Town
(
	[IdTown] INT NOT NULL IDENTITY(1,1) PRIMARY KEY,
	[Name] NVARCHAR(30) NOT NULL
);

CREATE TABLE SocialStatus
(
	[IdStatus] INT NOT NULL IDENTITY(1,1) PRIMARY KEY,
	[Name] NVARCHAR(30) NOT NULL
);

CREATE TABLE Branch
(
	[IdBranch] INT NOT NULL IDENTITY(1,1) PRIMARY KEY,
	[Adress] NVARCHAR(20) NOT NULL,
	[IdTown] INT NOT NULL,
	[IdBank] INT NOT NULL,

	CONSTRAINT branch_Town_FK
		FOREIGN KEY (IdTown) REFERENCES Town (IdTown),
	CONSTRAINT branch_Bank_FK
		FOREIGN KEY (IdBank) REFERENCES Banks (IdBank),
);

CREATE TABLE Client
(
	[IdClient] INT NOT NULL IDENTITY(1,1) PRIMARY KEY,
	[Surname] NVARCHAR(15) NOT NULL,
	[Name] NVARCHAR(15) NOT NULL,
	[LastName] NVARCHAR(15) NOT NULL,
	[PassportData] NVARCHAR(15) NOT NULL,
	[Balance] INT NOT NULL,
	[IdStatus] INT NOT NULL,
	[IdBranch] INT NOT NULL,

	CONSTRAINT clients_SocialStatus_FK
		FOREIGN KEY (IdStatus) REFERENCES SocialStatus (IdStatus),
	CONSTRAINT clients_Branch_FK
		FOREIGN KEY (IdBranch) REFERENCES Branch (IdBranch)

);

CREATE TABLE ClientCard
(
	[IdClientCard] INT NOT NULL IDENTITY(1,1) PRIMARY KEY,
	[Balance] INT NOT NULL,
	[IdClient] INT NOT NULL,

	CONSTRAINT clientCards_Client_FK
	FOREIGN KEY (IdClient) REFERENCES Client (IdClient)
);



Filing tables

Banks
INSERT INTO Banks VALUES(N'Belarusbank'),
					   (N'Belinvestbank'),
					   (N'Alfabank'),
					   (N'Priorbank'),
					   (N'Tinkoff');
Towns
INSERT INTO Town VALUES(N'Gomel'),
					   (N'Minsk'),
					   (N'Brest'),
					   (N'Vitebsk'),
					   (N'Grodno');
Social Status
INSERT INTO SocialStatus VALUES (N'Retiree'),
								(N'Invalid'),
								(N'Worker'),
								(N'NoWorker'),
								(N'Minor');
Branch
INSERT INTO Branch VALUES ('Golovatski', 1, 2),
				          ('Lenina', 2, 1),
						  ('Pobeda', 3, 1),
						  ('Chehova', 3, 3),
						  ('Mazyrova', 5, 4);
Client
INSERT INTO Client VALUES (N'Bobrov', N'Nikita', N'Nickolaevich', N'HB3059903', 100, 4,4),
						  (N'Piletskaya', N'Sonya', N'Alexandrovna', N'HB3352902', 200, 1,3),
						  (N'Rysiy', N'Valentin', N'Vasilievich', N'HB1254904', 50, 3,1),
						  (N'Fedorova', N'Polina', N'Vladimirovna', N'HB3203102', 150, 4,2),
						  (N'Efremov', N'Vladislav', N'Michailovich', N'HB3049902', 200, 5,1);

Client's cards
INSERT INTO ClientCard VALUES(20, 1),
							 (30, 1),
							 (50, 2),
							 (0, 5),
							 (100, 4);
							 */
--Query 1
SELECT Banks.Name
FROM Banks 
     JOIN (Town
			JOIN Branch ON Town.IdTown = Branch.IdTown) ON Banks.IdBank = Branch.IdBank
WHERE Town.Name = 'Brest';

--Qyery 2
SELECT Client.Name, Client.Surname, Client.LastName, ClientCard.Balance, Banks.Name
FROM ClientCard JOIN (Client
						JOIN (Branch
								JOIN Banks ON Branch.IdBank = Banks.IdBank) ON Client.IdBranch = Branch.IdBranch) ON ClientCard.IdClient = Client.IdClient;

--Query 3
SELECT Client.Surname, Client.Name, SUM(ClientCard.Balance) AS 'Баланс карт', 
		Client.Balance, SUM(ClientCard.Balance)-Client.Balance AS 'Разница'
FROM Client JOIN ClientCard ON Client.IdClient = ClientCard.IdClient
GROUP BY Client.Surname, Client.Name, Client.Balance
HAVING SUM(ClientCard.Balance) != Client.Balance

--Query 4
--4.1
SELECT SocialStatus.Name, COUNT(*) AS 'Количество'
FROM SocialStatus 
		JOIN (Client
				JOIN ClientCard ON ClientCard.IdClient = Client.IdClient) ON SocialStatus.IdStatus = Client.IdStatus
GROUP BY SocialStatus.Name

--4.2
SELECT SocialStatus.Name, (SELECT COUNT(*) 
									FROM ClientCard 
									WHERE ClientCard.IdClient IN 
									(
										SELECT Client.IdClient 
										FROM Client 
										WHERE Client.IdStatus = SocialStatus.IdStatus
									)
							) AS 'Количество'
FROM SocialStatus

--Query 5

CREATE PROC AddMoneyInBalance AS
BEGIN
UPDATE Client SET Balance = Balance + 10
WHERE Client.IdStatus = 4
END;
EXEC AddMoneyInBalance;

--Query 6
SELECT Client.Surname, 
		Client.Name, 
		(SUM(ClientCard.Balance)+Client.Balance) AS 'All balance',
		SUM(ClientCard.Balance) AS 'available for translation'
FROM Client JOIN ClientCard ON Client.IdClient = ClientCard.IdClient
GROUP BY Client.Name, Client.Surname, Client.Balance

--Query 7
BEGIN TRY
BEGIN TRANSACTION 

UPDATE Client SET Balance = Balance-10 WHERE Client.IdClient = 1;

UPDATE ClientCard SET Balance = Balance+10 WHERE ClientCard.IdClientCard = 1
END TRY
BEGIN CATCH 
	ROLLBACK TRANSACTION
	RETURN
END CATCH
COMMIT TRANSACTION
GO 
SELECT * FROM Client
SELECT * FROM ClientCard

--Query 8
CREATE TRIGGER ControlEnterDataInBalance
	ON Client
	AFTER INSERT, UPDATE
AS
DECLARE @ClientBalance INT
DECLARE @IdClientAccount INT
DECLARE @CardBalance INT
SELECT @ClientBalance = Balance, @IdClientAccount = IdClient FROM inserted
SELECT @CardBalance = SUM(ClientCard.Balance) FROM ClientCard WHERE ClientCard.IdClient = @IdClientAccount
IF @ClientBalance != @CardBalance
BEGIN
ROLLBACK TRANSACTION
PRINT 'Значения неверны'
END
	ELSE COMMIT

