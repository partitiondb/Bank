use master;
begin
declare @sql nvarchar(max);
select @sql = coalesce(@sql,'') + 'kill ' + convert(varchar, spid) + ';'
from master..sysprocesses
where dbid in (db_id('TwoWestGate'),db_id('SunsetDB'),db_id('VeniceDB'),db_id('WilshireDB'),db_id('TwoWestGlobalDB'),db_id('TwoWestCommonDB')) and cmd = 'AWAITING COMMAND' and spid <> @@spid;
exec(@sql);
end;
go
if db_id('TwoWestGate') 	is not null drop database TwoWestGate;
if db_id('TwoWestCommonDB') is not null drop database TwoWestCommonDB;
if db_id('TwoWestGlobalDB') is not null drop database TwoWestGlobalDB;
if db_id('SunsetDB') 		is not null drop database SunsetDB;
if db_id('VeniceDB')  		is not null drop database VeniceDB;
if db_id('WilshireDB') 		is not null drop database WilshireDB;
create database TwoWestCommonDB;
create database TwoWestGlobalDB;
create database SunsetDB;
create database VeniceDB;
create database WilshireDB;
use PdbLogic;
exec Pdbinstall 'TwoWestGate',@ColumnName='BranchId';
go
use TwoWestGate;
exec PdbcreatePartition 'TwoWestGate','TwoWestCommonDB',@DatabaseTypeId=2;
exec PdbcreatePartition 'TwoWestGate','TwoWestGlobalDB',@DatabaseTypeId=3;
exec PdbcreatePartition 'TwoWestGate','SunsetDB',1;
exec PdbcreatePartition 'TwoWestGate','VeniceDB',2;
exec PdbcreatePartition 'TwoWestGate','WilshireDB',3;

create table Branches
	(	Id					PartitionDBType			not null primary key
	,	BranchNumber		nvarchar(16)			not null unique
	,	Name				nvarchar(128)			not null unique
	,	City				nvarchar(128)
	,	Address				nvarchar(128)
	,	PostalCode			nvarchar(8)
	);
	
create table Roles
	(	Id					smallint 				not null primary key
	,	Name				nvarchar(128)			not null
	,	RoleType			tinyint					not null
	,	ParentRoleId		smallint						 
	);

alter table Roles add foreign key (ParentRoleId) references Roles (Id);
	
create table Users
	(	Id					smallint identity(1,1) 	not null primary key
	,	BranchId			PartitionDBType			not null references Branches (Id)
	,	Username			nvarchar(128)			not null unique
	,	Password			nvarchar(128)			not null
	,	FirstName			nvarchar(128)			not null
	,	LastName			nvarchar(128)			not null
	,	PhoneNumber			nvarchar(64)
	,	City				nvarchar(128)
	,	Address				nvarchar(128)
	,	PostalCode			nvarchar(8)	
	,	UserStatus			tinyint
	,	RoleId				smallint				not null references Roles (Id)
	);

create table Employees
	(	Id					smallint identity(1,1) 	not null primary key
	,	BranchId			PartitionDBType			not null references Branches (Id)
	,	UserId				smallint				not null unique references Users (Id)
	,	ManagerEmployeeId	smallint				
	);

alter table Employees add foreign key (ManagerEmployeeId) references Employees (Id)

create table Customers
	(	Id					smallint identity(1,1) 	not null primary key
	,	BranchId			PartitionDBType			not null references Branches (Id)
	,	UserId				smallint				not null unique references Users (Id)
	,	NationalNumber		nvarchar(16)			not null unique
	,	Birthdate			date
	);

create table ATMs
	(	Id					smallint identity(1,1) 	not null primary key
	,	City				nvarchar(128)
	,	Address				nvarchar(128)
	,	PostalCode			nvarchar(8)
	);
	
create table Accounts
	(	Id					smallint identity(1,1) 	not null primary key
	,	BranchId			PartitionDBType			not null references Branches (Id)
	,	AccountNumber		nvarchar(32)			not null unique
	,	CustomerId			smallint				not null references Customers (Id)
	,	CreditDeposited		decimal(18,3)			not null
	,	CreditWithdrew		decimal(18,3)			not null
	);
	
create table CreditCards
	(	Id					smallint identity(1,1) 	not null primary key
	,	BranchId			PartitionDBType			not null references Branches (Id)
	,	CardNumber			nvarchar(64)			not null unique
	,	AccountId			smallint				not null references Accounts (Id)
	);

create table Deposits
	(	Id					smallint identity(1,1) 	not null primary key
	,	BranchId			PartitionDBType			not null references Branches (Id)
	,	AccountId			smallint				not null references Accounts (Id)
	,	DepositDate			smalldatetime			not null
	,	CreditDeposited		decimal(18,3)			not null
	);

create table Withdraws
	(	Id					smallint identity(1,1) 	not null primary key
	,	BranchId			PartitionDBType			not null references Branches (Id)
	,	ATMId				smallint				not null references ATMs (Id)
	,	CreditCardId		smallint				not null references CreditCards (Id)
	,	WithdrawDate		smalldatetime			not null
	,	CreditWithdrew		decimal(18,3)			not null
	);
	
insert into PdbBranches (Id,BranchNumber,Name,City,Address,PostalCode) values (1,'101','Sunset','Los Angeles, CA','Sunset Blvd','90189');
insert into PdbBranches (Id,BranchNumber,Name,City,Address,PostalCode) values (2,'102','Venice','Los Angeles, CA','Washington Blvd, Venice','90291');
insert into PdbBranches (Id,BranchNumber,Name,City,Address,PostalCode) values (3,'103','Wilshire','Los Angeles, CA','Wilshire Blvd','90025');
insert into PdbBranches (Id,BranchNumber,Name,City,Address,PostalCode) values (4,'104','Beverly','Los Angeles, CA','Beverly Blvd','90048');
insert into PdbBranches (Id,BranchNumber,Name,City,Address,PostalCode) values (5,'105','Century','Los Angeles, CA','Sepulveda Blvd','90045');
insert into PdbBranches (Id,BranchNumber,Name,City,Address,PostalCode) values (6,'106','Olympic','Los Angeles, CA','Pico Blvd','90035');
insert into PdbRoles (Id,Name,RoleType,ParentRoleId) values (1,'Manager',1,null);
insert into PdbRoles (Id,Name,RoleType,ParentRoleId) values (2,'Employee',2,1);
insert into PdbRoles (Id,Name,RoleType,ParentRoleId) values (3,'Customer',3,null);
insert into PdbUsers (BranchId,Username,Password,FirstName,LastName,PhoneNumber,City,Address,PostalCode,UserStatus,RoleId) values (1,'sophia_loren','123456','Sophia','Loren','+1234567890','Los Angeles, CA',null,'90000',1,1);
insert into PdbUsers (BranchId,Username,Password,FirstName,LastName,PhoneNumber,City,Address,PostalCode,UserStatus,RoleId) values (2,'grace_kelly','123456','Grace','Kelly','+1234567890','Los Angeles, CA',null,'90000',1,1);
insert into PdbUsers (BranchId,Username,Password,FirstName,LastName,PhoneNumber,City,Address,PostalCode,UserStatus,RoleId) values (3,'brooke_shields','123456','Brooke','Shields','+1234567890','Los Angeles, CA',null,'90000',1,1);
insert into PdbUsers (BranchId,Username,Password,FirstName,LastName,PhoneNumber,City,Address,PostalCode,UserStatus,RoleId) values (1,'claudia_schiffer','123456','Claudia','Schiffer','+1234567890','Los Angeles, CA',null,'90000',1,2);
insert into PdbUsers (BranchId,Username,Password,FirstName,LastName,PhoneNumber,City,Address,PostalCode,UserStatus,RoleId) values (2,'cindy_crawford','123456','Cindy','Crawford','+1234567890','Los Angeles, CA',null,'90000',1,2);
insert into PdbUsers (BranchId,Username,Password,FirstName,LastName,PhoneNumber,City,Address,PostalCode,UserStatus,RoleId) values (3,'naomi_campbell','123456','Naomi','Campbell','+1234567890','Los Angeles, CA',null,'90000',1,2);
insert into PdbUsers (BranchId,Username,Password,FirstName,LastName,PhoneNumber,City,Address,PostalCode,UserStatus,RoleId) values (1,'alessandra_ambrosio','123456','Alessandra','Ambrosio','+1234567890','Los Angeles, CA',null,'90000',1,2);
insert into PdbUsers (BranchId,Username,Password,FirstName,LastName,PhoneNumber,City,Address,PostalCode,UserStatus,RoleId) values (2,'tyra_banks','123456','Tyra','Banks','+1234567890','Los Angeles, CA',null,'90000',1,2);
insert into PdbUsers (BranchId,Username,Password,FirstName,LastName,PhoneNumber,City,Address,PostalCode,UserStatus,RoleId) values (3,'kate_moss','123456','Kate','Moss','+1234567890','Los Angeles, CA',null,'90000',1,2);
insert into PdbUsers (BranchId,Username,Password,FirstName,LastName,PhoneNumber,City,Address,PostalCode,UserStatus,RoleId) values (1,'heidi_klum','123456','Heidi','Klum','+1234567890','Los Angeles, CA',null,'90000',1,2);
insert into PdbUsers (BranchId,Username,Password,FirstName,LastName,PhoneNumber,City,Address,PostalCode,UserStatus,RoleId) values (2,'marisa_miller','123456','Marisa','Miller','+1234567890','Los Angeles, CA',null,'90000',1,2);
insert into PdbUsers (BranchId,Username,Password,FirstName,LastName,PhoneNumber,City,Address,PostalCode,UserStatus,RoleId) values (3,'adriana_lima','123456','Adriana','Lima','+1234567890','Los Angeles, CA',null,'90000',1,2);
insert into PdbUsers (BranchId,Username,Password,FirstName,LastName,PhoneNumber,City,Address,PostalCode,UserStatus,RoleId) values (4,'bar_refaeli','123456','Bar','Refaeli','+1234567890','Los Angeles, CA',null,'90000',1,1);
insert into PdbUsers (BranchId,Username,Password,FirstName,LastName,PhoneNumber,City,Address,PostalCode,UserStatus,RoleId) values (4,'laetita_casta','123456','Laetita','Casta','+1234567890','Los Angeles, CA',null,'90000',1,2);
insert into PdbUsers (BranchId,Username,Password,FirstName,LastName,PhoneNumber,City,Address,PostalCode,UserStatus,RoleId) values (4,'molly_sims','123456','Molly','Sims','+1234567890','Los Angeles, CA',null,'90000',1,2);
insert into PdbUsers (BranchId,Username,Password,FirstName,LastName,PhoneNumber,City,Address,PostalCode,UserStatus,RoleId) values (5,'gisele_bundchen','123456','Gisele','Bundchen','+1234567890','Los Angeles, CA',null,'90000',1,1);
insert into PdbUsers (BranchId,Username,Password,FirstName,LastName,PhoneNumber,City,Address,PostalCode,UserStatus,RoleId) values (5,'carmen_kass','123456','Carmen','Kass','+1234567890','Los Angeles, CA',null,'90000',1,2);
insert into PdbUsers (BranchId,Username,Password,FirstName,LastName,PhoneNumber,City,Address,PostalCode,UserStatus,RoleId) values (5,'milla_jovovich','123456','Milla','Jovovich','+1234567890','Los Angeles, CA',null,'90000',1,2);
insert into PdbUsers (BranchId,Username,Password,FirstName,LastName,PhoneNumber,City,Address,PostalCode,UserStatus,RoleId) values (6,'miranda_kerr','123456','Miranda','Kerr','+1234567890','Los Angeles, CA',null,'90000',1,1);
insert into PdbUsers (BranchId,Username,Password,FirstName,LastName,PhoneNumber,City,Address,PostalCode,UserStatus,RoleId) values (6,'candice_swanepoel','123456','Candice','Swanepoel','+1234567890','Los Angeles, CA',null,'90000',1,2);
insert into PdbUsers (BranchId,Username,Password,FirstName,LastName,PhoneNumber,City,Address,PostalCode,UserStatus,RoleId) values (6,'erin_heatherton','123456','Erin','Heatherton','+1234567890','Los Angeles, CA',null,'90000',1,2);
insert into PdbUsers (BranchId,Username,Password,FirstName,LastName,PhoneNumber,City,Address,PostalCode,UserStatus,RoleId) values (1,'karl_malone','123456','Karl','Malone','+1234567890','Los Angeles, CA',null,'90000',1,3);
insert into PdbUsers (BranchId,Username,Password,FirstName,LastName,PhoneNumber,City,Address,PostalCode,UserStatus,RoleId) values (2,'bob_pettit','123456','Bob','Pettit','+1234567890','Los Angeles, CA',null,'90000',1,3);
insert into PdbUsers (BranchId,Username,Password,FirstName,LastName,PhoneNumber,City,Address,PostalCode,UserStatus,RoleId) values (3,'scottie_pippen','123456','Scottie','Pippen','+1234567890','Los Angeles, CA',null,'90000',1,3);
insert into PdbUsers (BranchId,Username,Password,FirstName,LastName,PhoneNumber,City,Address,PostalCode,UserStatus,RoleId) values (1,'david_robinson','123456','David','Robinson','+1234567890','Los Angeles, CA',null,'90000',1,3);
insert into PdbUsers (BranchId,Username,Password,FirstName,LastName,PhoneNumber,City,Address,PostalCode,UserStatus,RoleId) values (2,'john_stockton','123456','John','Stockton','+1234567890','Los Angeles, CA',null,'90000',1,3);
insert into PdbUsers (BranchId,Username,Password,FirstName,LastName,PhoneNumber,City,Address,PostalCode,UserStatus,RoleId) values (3,'jerry_west','123456','Jerry','West','+1234567890','Los Angeles, CA',null,'90000',1,3);
insert into PdbUsers (BranchId,Username,Password,FirstName,LastName,PhoneNumber,City,Address,PostalCode,UserStatus,RoleId) values (1,'lenny_wilkens','123456','Lenny','Wilkens','+1234567890','Los Angeles, CA',null,'90000',1,3);
insert into PdbUsers (BranchId,Username,Password,FirstName,LastName,PhoneNumber,City,Address,PostalCode,UserStatus,RoleId) values (2,'james_worthy','123456','James','Worthy','+1234567890','Los Angeles, CA',null,'90000',1,3);
insert into PdbUsers (BranchId,Username,Password,FirstName,LastName,PhoneNumber,City,Address,PostalCode,UserStatus,RoleId) values (3,'charles_barkley','123456','Charles','Barkley','+1234567890','Los Angeles, CA',null,'90000',1,3);
insert into PdbUsers (BranchId,Username,Password,FirstName,LastName,PhoneNumber,City,Address,PostalCode,UserStatus,RoleId) values (1,'rick_barry','123456','Rick','Barry','+1234567890','Los Angeles, CA',null,'90000',1,3);
insert into PdbUsers (BranchId,Username,Password,FirstName,LastName,PhoneNumber,City,Address,PostalCode,UserStatus,RoleId) values (2,'larry_bird','123456','Larry','Bird','+1234567890','Los Angeles, CA',null,'90000',1,3);
insert into PdbUsers (BranchId,Username,Password,FirstName,LastName,PhoneNumber,City,Address,PostalCode,UserStatus,RoleId) values (3,'patrick_ewing','123456','Patrick','Ewing','+1234567890','Los Angeles, CA',null,'90000',1,3);
insert into PdbUsers (BranchId,Username,Password,FirstName,LastName,PhoneNumber,City,Address,PostalCode,UserStatus,RoleId) values (1,'walt_frazier','123456','Walt','Frazier','+1234567890','Los Angeles, CA',null,'90000',1,3);
insert into PdbUsers (BranchId,Username,Password,FirstName,LastName,PhoneNumber,City,Address,PostalCode,UserStatus,RoleId) values (2,'magic_johnson','123456','Magic','Johnson','+1234567890','Los Angeles, CA',null,'90000',1,3);
insert into PdbUsers (BranchId,Username,Password,FirstName,LastName,PhoneNumber,City,Address,PostalCode,UserStatus,RoleId) values (3,'michael_jordan','123456','Michael','Jordan','+1234567890','Los Angeles, CA',null,'90000',1,3);
insert into PdbUsers (BranchId,Username,Password,FirstName,LastName,PhoneNumber,City,Address,PostalCode,UserStatus,RoleId) values (1,'dennis_rodman','123456','Dennis','Rodman','+1234567890','Los Angeles, CA',null,'90000',1,3);
insert into PdbUsers (BranchId,Username,Password,FirstName,LastName,PhoneNumber,City,Address,PostalCode,UserStatus,RoleId) values (2,'dwyane_wade','123456','Dwyane','Wade','+1234567890','Los Angeles, CA',null,'90000',1,3);
insert into PdbUsers (BranchId,Username,Password,FirstName,LastName,PhoneNumber,City,Address,PostalCode,UserStatus,RoleId) values (3,'steve_nash','123456','Steve','Nash','+1234567890','Los Angeles, CA',null,'90000',1,3);
insert into PdbUsers (BranchId,Username,Password,FirstName,LastName,PhoneNumber,City,Address,PostalCode,UserStatus,RoleId) values (1,'david_thompson','123456','David','Thompson','+1234567890','Los Angeles, CA',null,'90000',1,3);
insert into PdbUsers (BranchId,Username,Password,FirstName,LastName,PhoneNumber,City,Address,PostalCode,UserStatus,RoleId) values (2,'sam_jones','123456','Sam','Jones','+1234567890','Los Angeles, CA',null,'90000',1,3);
insert into PdbUsers (BranchId,Username,Password,FirstName,LastName,PhoneNumber,City,Address,PostalCode,UserStatus,RoleId) values (3,'paul_pierce','123456','Paul','Pierce','+1234567890','Los Angeles, CA',null,'90000',1,3);
insert into PdbUsers (BranchId,Username,Password,FirstName,LastName,PhoneNumber,City,Address,PostalCode,UserStatus,RoleId) values (1,'chris_webber','123456','Chris','Webber','+1234567890','Los Angeles, CA',null,'90000',1,3);
insert into PdbUsers (BranchId,Username,Password,FirstName,LastName,PhoneNumber,City,Address,PostalCode,UserStatus,RoleId) values (2,'grant_hill','123456','Grant','Hill','+1234567890','Los Angeles, CA',null,'90000',1,3);
insert into PdbUsers (BranchId,Username,Password,FirstName,LastName,PhoneNumber,City,Address,PostalCode,UserStatus,RoleId) values (3,'vince_carter','123456','Vince','Carter','+1234567890','Los Angeles, CA',null,'90000',1,3);
insert into PdbUsers (BranchId,Username,Password,FirstName,LastName,PhoneNumber,City,Address,PostalCode,UserStatus,RoleId) values (1,'tim_hardaway','123456','Tim','Hardaway','+1234567890','Los Angeles, CA',null,'90000',1,3);
insert into PdbUsers (BranchId,Username,Password,FirstName,LastName,PhoneNumber,City,Address,PostalCode,UserStatus,RoleId) values (2,'chris_mullin','123456','Chris','Mullin','+1234567890','Los Angeles, CA',null,'90000',1,3);
insert into PdbUsers (BranchId,Username,Password,FirstName,LastName,PhoneNumber,City,Address,PostalCode,UserStatus,RoleId) values (3,'artis_gilmore','123456','Artis','Gilmore','+1234567890','Los Angeles, CA',null,'90000',1,3);
insert into PdbUsers (BranchId,Username,Password,FirstName,LastName,PhoneNumber,City,Address,PostalCode,UserStatus,RoleId) values (1,'bill_russell','123456','Bill','Russell','+1234567890','Los Angeles, CA',null,'90000',1,3);
insert into PdbUsers (BranchId,Username,Password,FirstName,LastName,PhoneNumber,City,Address,PostalCode,UserStatus,RoleId) values (2,'kevin_porter','123456','Kevin','Porter','+1234567890','Los Angeles, CA',null,'90000',1,3);
insert into PdbUsers (BranchId,Username,Password,FirstName,LastName,PhoneNumber,City,Address,PostalCode,UserStatus,RoleId) values (3,'guy_rodgers','123456','Guy','Rodgers','+1234567890','Los Angeles, CA',null,'90000',1,3);
insert into PdbUsers (BranchId,Username,Password,FirstName,LastName,PhoneNumber,City,Address,PostalCode,UserStatus,RoleId) values (4,'cynthia_cooper','123456','Cynthia','Cooper','+1234567890','Los Angeles, CA',null,'90000',1,3);
insert into PdbUsers (BranchId,Username,Password,FirstName,LastName,PhoneNumber,City,Address,PostalCode,UserStatus,RoleId) values (4,'lauren_jackson','123456','Lauren','Jackson','+1234567890','Los Angeles, CA',null,'90000',1,3);
insert into PdbUsers (BranchId,Username,Password,FirstName,LastName,PhoneNumber,City,Address,PostalCode,UserStatus,RoleId) values (4,'lisa_leslie','123456','Lisa','Leslie','+1234567890','Los Angeles, CA',null,'90000',1,3);
insert into PdbUsers (BranchId,Username,Password,FirstName,LastName,PhoneNumber,City,Address,PostalCode,UserStatus,RoleId) values (4,'katie_smith','123456','Katie','Smith','+1234567890','Los Angeles, CA',null,'90000',1,3);
insert into PdbUsers (BranchId,Username,Password,FirstName,LastName,PhoneNumber,City,Address,PostalCode,UserStatus,RoleId) values (4,'dawn_staley','123456','Dawn','Staley','+1234567890','Los Angeles, CA',null,'90000',1,3);
insert into PdbUsers (BranchId,Username,Password,FirstName,LastName,PhoneNumber,City,Address,PostalCode,UserStatus,RoleId) values (5,'sheryl_swoopes','123456','Sheryl','Swoopes','+1234567890','Los Angeles, CA',null,'90000',1,3);
insert into PdbUsers (BranchId,Username,Password,FirstName,LastName,PhoneNumber,City,Address,PostalCode,UserStatus,RoleId) values (5,'tina_thompson','123456','Tina','Thompson','+1234567890','Los Angeles, CA',null,'90000',1,3);
insert into PdbUsers (BranchId,Username,Password,FirstName,LastName,PhoneNumber,City,Address,PostalCode,UserStatus,RoleId) values (5,'ruthie_bolton','123456','Ruthie','Bolton','+1234567890','Los Angeles, CA',null,'90000',1,3);
insert into PdbUsers (BranchId,Username,Password,FirstName,LastName,PhoneNumber,City,Address,PostalCode,UserStatus,RoleId) values (5,'katie_douglas','123456','Katie','Douglas','+1234567890','Los Angeles, CA',null,'90000',1,3);
insert into PdbUsers (BranchId,Username,Password,FirstName,LastName,PhoneNumber,City,Address,PostalCode,UserStatus,RoleId) values (5,'cheryl_ford','123456','Cheryl','Ford','+1234567890','Los Angeles, CA',null,'90000',1,3);
insert into PdbUsers (BranchId,Username,Password,FirstName,LastName,PhoneNumber,City,Address,PostalCode,UserStatus,RoleId) values (6,'shannon_johnson','123456','Shannon','Johnson','+1234567890','Los Angeles, CA',null,'90000',1,3);
insert into PdbUsers (BranchId,Username,Password,FirstName,LastName,PhoneNumber,City,Address,PostalCode,UserStatus,RoleId) values (6,'deanna_nolan','123456','Deanna','Nolan','+1234567890','Los Angeles, CA',null,'90000',1,3);
insert into PdbUsers (BranchId,Username,Password,FirstName,LastName,PhoneNumber,City,Address,PostalCode,UserStatus,RoleId) values (6,'candace_parker','123456','Candace','Parker','+1234567890','Los Angeles, CA',null,'90000',1,3);
insert into PdbUsers (BranchId,Username,Password,FirstName,LastName,PhoneNumber,City,Address,PostalCode,UserStatus,RoleId) values (6,'penny_taylor','123456','Penny','Taylor','+1234567890','Los Angeles, CA',null,'90000',1,3);
insert into PdbUsers (BranchId,Username,Password,FirstName,LastName,PhoneNumber,City,Address,PostalCode,UserStatus,RoleId) values (6,'brittney_griner','123456','Brittney','Griner','+1234567890','Los Angeles, CA',null,'90000',1,3);
insert into PdbEmployees (BranchId,UserId,ManagerEmployeeId) values (1,(select Id from PdbUsers where BranchId=1 and Username='sophia_loren')		,(select Id from PdbEmployees where BranchId=1 and ManagerEmployeeId is null));
insert into PdbEmployees (BranchId,UserId,ManagerEmployeeId) values (2,(select Id from PdbUsers where BranchId=2 and Username='grace_kelly')		,(select Id from PdbEmployees where BranchId=2 and ManagerEmployeeId is null));
insert into PdbEmployees (BranchId,UserId,ManagerEmployeeId) values (3,(select Id from PdbUsers where BranchId=3 and Username='brooke_shields')		,(select Id from PdbEmployees where BranchId=3 and ManagerEmployeeId is null));
insert into PdbEmployees (BranchId,UserId,ManagerEmployeeId) values (1,(select Id from PdbUsers where BranchId=1 and Username='claudia_schiffer')	,(select Id from PdbEmployees where BranchId=1 and ManagerEmployeeId is null));
insert into PdbEmployees (BranchId,UserId,ManagerEmployeeId) values (2,(select Id from PdbUsers where BranchId=2 and Username='cindy_crawford')		,(select Id from PdbEmployees where BranchId=2 and ManagerEmployeeId is null));
insert into PdbEmployees (BranchId,UserId,ManagerEmployeeId) values (3,(select Id from PdbUsers where BranchId=3 and Username='naomi_campbell')		,(select Id from PdbEmployees where BranchId=3 and ManagerEmployeeId is null));
insert into PdbEmployees (BranchId,UserId,ManagerEmployeeId) values (1,(select Id from PdbUsers where BranchId=1 and Username='alessandra_ambrosio'),(select Id from PdbEmployees where BranchId=1 and ManagerEmployeeId is null));
insert into PdbEmployees (BranchId,UserId,ManagerEmployeeId) values (2,(select Id from PdbUsers where BranchId=2 and Username='tyra_banks')			,(select Id from PdbEmployees where BranchId=2 and ManagerEmployeeId is null));
insert into PdbEmployees (BranchId,UserId,ManagerEmployeeId) values (3,(select Id from PdbUsers where BranchId=3 and Username='kate_moss')			,(select Id from PdbEmployees where BranchId=3 and ManagerEmployeeId is null));
insert into PdbEmployees (BranchId,UserId,ManagerEmployeeId) values (1,(select Id from PdbUsers where BranchId=1 and Username='heidi_klum')			,(select Id from PdbEmployees where BranchId=1 and ManagerEmployeeId is null));
insert into PdbEmployees (BranchId,UserId,ManagerEmployeeId) values (2,(select Id from PdbUsers where BranchId=2 and Username='marisa_miller')		,(select Id from PdbEmployees where BranchId=2 and ManagerEmployeeId is null));
insert into PdbEmployees (BranchId,UserId,ManagerEmployeeId) values (3,(select Id from PdbUsers where BranchId=3 and Username='adriana_lima')		,(select Id from PdbEmployees where BranchId=3 and ManagerEmployeeId is null));
insert into PdbEmployees (BranchId,UserId,ManagerEmployeeId) values (4,(select Id from PdbUsers where BranchId=4 and Username='bar_refaeli')  		,(select Id from PdbEmployees where BranchId=4 and ManagerEmployeeId is null));
insert into PdbEmployees (BranchId,UserId,ManagerEmployeeId) values (4,(select Id from PdbUsers where BranchId=4 and Username='laetita_casta')  	,(select Id from PdbEmployees where BranchId=4 and ManagerEmployeeId is null));
insert into PdbEmployees (BranchId,UserId,ManagerEmployeeId) values (4,(select Id from PdbUsers where BranchId=4 and Username='molly_sims') 		,(select Id from PdbEmployees where BranchId=4 and ManagerEmployeeId is null));
insert into PdbEmployees (BranchId,UserId,ManagerEmployeeId) values (5,(select Id from PdbUsers where BranchId=5 and Username='gisele_bundchen')  	,(select Id from PdbEmployees where BranchId=5 and ManagerEmployeeId is null));
insert into PdbEmployees (BranchId,UserId,ManagerEmployeeId) values (5,(select Id from PdbUsers where BranchId=5 and Username='carmen_kass')  		,(select Id from PdbEmployees where BranchId=5 and ManagerEmployeeId is null));
insert into PdbEmployees (BranchId,UserId,ManagerEmployeeId) values (5,(select Id from PdbUsers where BranchId=5 and Username='milla_jovovich')  	,(select Id from PdbEmployees where BranchId=5 and ManagerEmployeeId is null));
insert into PdbEmployees (BranchId,UserId,ManagerEmployeeId) values (6,(select Id from PdbUsers where BranchId=6 and Username='miranda_kerr')  		,(select Id from PdbEmployees where BranchId=6 and ManagerEmployeeId is null));
insert into PdbEmployees (BranchId,UserId,ManagerEmployeeId) values (6,(select Id from PdbUsers where BranchId=6 and Username='candice_swanepoel')  ,(select Id from PdbEmployees where BranchId=6 and ManagerEmployeeId is null));
insert into PdbEmployees (BranchId,UserId,ManagerEmployeeId) values (6,(select Id from PdbUsers where BranchId=6 and Username='erin_heatherton')  	,(select Id from PdbEmployees where BranchId=6 and ManagerEmployeeId is null));
insert into PdbCustomers (BranchId,UserId,NationalNumber,Birthdate) values (1,(select Id from PdbUsers where BranchId=1 and Username='karl_malone')		,'123-456-0001',null);
insert into PdbCustomers (BranchId,UserId,NationalNumber,Birthdate) values (2,(select Id from PdbUsers where BranchId=2 and Username='bob_pettit')		,'123-456-0002',null);
insert into PdbCustomers (BranchId,UserId,NationalNumber,Birthdate) values (3,(select Id from PdbUsers where BranchId=3 and Username='scottie_pippen')	,'123-456-0003',null);
insert into PdbCustomers (BranchId,UserId,NationalNumber,Birthdate) values (1,(select Id from PdbUsers where BranchId=1 and Username='david_robinson')	,'123-456-0004',null);
insert into PdbCustomers (BranchId,UserId,NationalNumber,Birthdate) values (2,(select Id from PdbUsers where BranchId=2 and Username='john_stockton')	,'123-456-0005',null);
insert into PdbCustomers (BranchId,UserId,NationalNumber,Birthdate) values (3,(select Id from PdbUsers where BranchId=3 and Username='jerry_west')		,'123-456-0006',null);
insert into PdbCustomers (BranchId,UserId,NationalNumber,Birthdate) values (1,(select Id from PdbUsers where BranchId=1 and Username='lenny_wilkens')	,'123-456-0007',null);
insert into PdbCustomers (BranchId,UserId,NationalNumber,Birthdate) values (2,(select Id from PdbUsers where BranchId=2 and Username='james_worthy')	,'123-456-0008',null);
insert into PdbCustomers (BranchId,UserId,NationalNumber,Birthdate) values (3,(select Id from PdbUsers where BranchId=3 and Username='charles_barkley')	,'123-456-0009',null);
insert into PdbCustomers (BranchId,UserId,NationalNumber,Birthdate) values (1,(select Id from PdbUsers where BranchId=1 and Username='rick_barry')		,'123-456-0010',null);
insert into PdbCustomers (BranchId,UserId,NationalNumber,Birthdate) values (2,(select Id from PdbUsers where BranchId=2 and Username='larry_bird')		,'123-456-0011',null);
insert into PdbCustomers (BranchId,UserId,NationalNumber,Birthdate) values (3,(select Id from PdbUsers where BranchId=3 and Username='patrick_ewing')	,'123-456-0012',null);
insert into PdbCustomers (BranchId,UserId,NationalNumber,Birthdate) values (1,(select Id from PdbUsers where BranchId=1 and Username='walt_frazier')	,'123-456-0013',null);
insert into PdbCustomers (BranchId,UserId,NationalNumber,Birthdate) values (2,(select Id from PdbUsers where BranchId=2 and Username='magic_johnson')	,'123-456-0014',null);
insert into PdbCustomers (BranchId,UserId,NationalNumber,Birthdate) values (3,(select Id from PdbUsers where BranchId=3 and Username='michael_jordan')	,'123-456-0015',null);
insert into PdbCustomers (BranchId,UserId,NationalNumber,Birthdate) values (1,(select Id from PdbUsers where BranchId=1 and Username='dennis_rodman')	,'123-456-0016',null);
insert into PdbCustomers (BranchId,UserId,NationalNumber,Birthdate) values (2,(select Id from PdbUsers where BranchId=2 and Username='dwyane_wade')		,'123-456-0017',null);
insert into PdbCustomers (BranchId,UserId,NationalNumber,Birthdate) values (3,(select Id from PdbUsers where BranchId=3 and Username='steve_nash')		,'123-456-0018',null);
insert into PdbCustomers (BranchId,UserId,NationalNumber,Birthdate) values (1,(select Id from PdbUsers where BranchId=1 and Username='david_thompson')	,'123-456-0019',null);
insert into PdbCustomers (BranchId,UserId,NationalNumber,Birthdate) values (2,(select Id from PdbUsers where BranchId=2 and Username='sam_jones')		,'123-456-0020',null);
insert into PdbCustomers (BranchId,UserId,NationalNumber,Birthdate) values (3,(select Id from PdbUsers where BranchId=3 and Username='paul_pierce')		,'123-456-0021',null);
insert into PdbCustomers (BranchId,UserId,NationalNumber,Birthdate) values (1,(select Id from PdbUsers where BranchId=1 and Username='chris_webber')	,'123-456-0022',null);
insert into PdbCustomers (BranchId,UserId,NationalNumber,Birthdate) values (2,(select Id from PdbUsers where BranchId=2 and Username='grant_hill')		,'123-456-0023',null);
insert into PdbCustomers (BranchId,UserId,NationalNumber,Birthdate) values (3,(select Id from PdbUsers where BranchId=3 and Username='vince_carter')	,'123-456-0024',null);
insert into PdbCustomers (BranchId,UserId,NationalNumber,Birthdate) values (1,(select Id from PdbUsers where BranchId=1 and Username='tim_hardaway')	,'123-456-0025',null);
insert into PdbCustomers (BranchId,UserId,NationalNumber,Birthdate) values (2,(select Id from PdbUsers where BranchId=2 and Username='chris_mullin')	,'123-456-0026',null);
insert into PdbCustomers (BranchId,UserId,NationalNumber,Birthdate) values (3,(select Id from PdbUsers where BranchId=3 and Username='artis_gilmore')	,'123-456-0027',null);
insert into PdbCustomers (BranchId,UserId,NationalNumber,Birthdate) values (1,(select Id from PdbUsers where BranchId=1 and Username='bill_russell')	,'123-456-0028',null);
insert into PdbCustomers (BranchId,UserId,NationalNumber,Birthdate) values (2,(select Id from PdbUsers where BranchId=2 and Username='kevin_porter')	,'123-456-0029',null);
insert into PdbCustomers (BranchId,UserId,NationalNumber,Birthdate) values (3,(select Id from PdbUsers where BranchId=3 and Username='guy_rodgers')		,'123-456-0030',null);
insert into PdbCustomers (BranchId,UserId,NationalNumber,Birthdate) values (4,(select Id from PdbUsers where BranchId=4 and Username='cynthia_cooper')  ,'123-456-0031',null);
insert into PdbCustomers (BranchId,UserId,NationalNumber,Birthdate) values (4,(select Id from PdbUsers where BranchId=4 and Username='lauren_jackson')  ,'123-456-0032',null);
insert into PdbCustomers (BranchId,UserId,NationalNumber,Birthdate) values (4,(select Id from PdbUsers where BranchId=4 and Username='lisa_leslie')  	,'123-456-0033',null);
insert into PdbCustomers (BranchId,UserId,NationalNumber,Birthdate) values (4,(select Id from PdbUsers where BranchId=4 and Username='katie_smith')  	,'123-456-0034',null);
insert into PdbCustomers (BranchId,UserId,NationalNumber,Birthdate) values (4,(select Id from PdbUsers where BranchId=4 and Username='dawn_staley')  	,'123-456-0035',null);
insert into PdbCustomers (BranchId,UserId,NationalNumber,Birthdate) values (5,(select Id from PdbUsers where BranchId=5 and Username='sheryl_swoopes')  ,'123-456-0036',null);
insert into PdbCustomers (BranchId,UserId,NationalNumber,Birthdate) values (5,(select Id from PdbUsers where BranchId=5 and Username='tina_thompson')  	,'123-456-0037',null);
insert into PdbCustomers (BranchId,UserId,NationalNumber,Birthdate) values (5,(select Id from PdbUsers where BranchId=5 and Username='ruthie_bolton')  	,'123-456-0038',null);
insert into PdbCustomers (BranchId,UserId,NationalNumber,Birthdate) values (5,(select Id from PdbUsers where BranchId=5 and Username='katie_douglas')  	,'123-456-0039',null);
insert into PdbCustomers (BranchId,UserId,NationalNumber,Birthdate) values (5,(select Id from PdbUsers where BranchId=5 and Username='cheryl_ford')  	,'123-456-0040',null);
insert into PdbCustomers (BranchId,UserId,NationalNumber,Birthdate) values (6,(select Id from PdbUsers where BranchId=6 and Username='shannon_johnson') ,'123-456-0041',null);
insert into PdbCustomers (BranchId,UserId,NationalNumber,Birthdate) values (6,(select Id from PdbUsers where BranchId=6 and Username='deanna_nolan')  	,'123-456-0042',null);
insert into PdbCustomers (BranchId,UserId,NationalNumber,Birthdate) values (6,(select Id from PdbUsers where BranchId=6 and Username='candace_parker')  ,'123-456-0043',null);
insert into PdbCustomers (BranchId,UserId,NationalNumber,Birthdate) values (6,(select Id from PdbUsers where BranchId=6 and Username='penny_taylor')  	,'123-456-0044',null);
insert into PdbCustomers (BranchId,UserId,NationalNumber,Birthdate) values (6,(select Id from PdbUsers where BranchId=6 and Username='brittney_griner') ,'123-456-0045',null);
insert into PdbATMs (City,Address,PostalCode) values ('Los Angeles, CA','10784 Jefferson Blvd','90189');
insert into PdbATMs (City,Address,PostalCode) values ('Los Angeles, CA','15135 Sunset Blvd','90189');
insert into PdbATMs (City,Address,PostalCode) values ('Los Angeles, CA','11611 San Vicente Blvd','90189');
insert into PdbATMs (City,Address,PostalCode) values ('Los Angeles, CA','18585 Ventura Blvd','90291');
insert into PdbATMs (City,Address,PostalCode) values ('Los Angeles, CA','11310 National Blvd','90291');
insert into PdbATMs (City,Address,PostalCode) values ('Los Angeles, CA','8726 Tampa Ave','90291');
insert into PdbATMs (City,Address,PostalCode) values ('Los Angeles, CA','12401 Wilshire Blvd','90025');
insert into PdbATMs (City,Address,PostalCode) values ('Los Angeles, CA','1750 Ocean Park Blvd','90025');
insert into PdbATMs (City,Address,PostalCode) values ('Los Angeles, CA','8653 Beverly Blvd','90025');
insert into PdbATMs (City,Address,PostalCode) values ('Los Angeles, CA','8750 Sepulveda Blvd','90045');
insert into PdbATMs (City,Address,PostalCode) values ('Los Angeles, CA','10784 Jefferson Blvd','90045');
insert into PdbATMs (City,Address,PostalCode) values ('Los Angeles, CA','13405 Washington Blvd','90292');
insert into PdbATMs (City,Address,PostalCode) values ('Los Angeles, CA','10784 Jefferson Blvd','90230');
insert into PdbATMs (City,Address,PostalCode) values ('Los Angeles, CA','9618 Pico Blvd','90035');
insert into PdbATMs (City,Address,PostalCode) values ('Los Angeles, CA','5701 Eastern Ave','90040');
insert into PdbAccounts (BranchId,AccountNumber,CustomerId,CreditDeposited,CreditWithdrew) values (1,'000001',(select Id from PdbCustomers where BranchId=1 and UserId = (select Id from PdbUsers where BranchId=1 and Username='karl_malone')),10000,0);
insert into PdbAccounts (BranchId,AccountNumber,CustomerId,CreditDeposited,CreditWithdrew) values (2,'000002',(select Id from PdbCustomers where BranchId=2 and UserId = (select Id from PdbUsers where BranchId=2 and Username='bob_pettit')),10000,0);
insert into PdbAccounts (BranchId,AccountNumber,CustomerId,CreditDeposited,CreditWithdrew) values (3,'000003',(select Id from PdbCustomers where BranchId=3 and UserId = (select Id from PdbUsers where BranchId=3 and Username='scottie_pippen')),10000,0);
insert into PdbAccounts (BranchId,AccountNumber,CustomerId,CreditDeposited,CreditWithdrew) values (1,'000004',(select Id from PdbCustomers where BranchId=1 and UserId = (select Id from PdbUsers where BranchId=1 and Username='david_robinson')),10000,0);
insert into PdbAccounts (BranchId,AccountNumber,CustomerId,CreditDeposited,CreditWithdrew) values (2,'000005',(select Id from PdbCustomers where BranchId=2 and UserId = (select Id from PdbUsers where BranchId=2 and Username='john_stockton')),10000,0);
insert into PdbAccounts (BranchId,AccountNumber,CustomerId,CreditDeposited,CreditWithdrew) values (3,'000006',(select Id from PdbCustomers where BranchId=3 and UserId = (select Id from PdbUsers where BranchId=3 and Username='jerry_west')),10000,0);
insert into PdbAccounts (BranchId,AccountNumber,CustomerId,CreditDeposited,CreditWithdrew) values (1,'000007',(select Id from PdbCustomers where BranchId=1 and UserId = (select Id from PdbUsers where BranchId=1 and Username='lenny_wilkens')),10000,0);
insert into PdbAccounts (BranchId,AccountNumber,CustomerId,CreditDeposited,CreditWithdrew) values (2,'000008',(select Id from PdbCustomers where BranchId=2 and UserId = (select Id from PdbUsers where BranchId=2 and Username='james_worthy')),10000,0);
insert into PdbAccounts (BranchId,AccountNumber,CustomerId,CreditDeposited,CreditWithdrew) values (3,'000009',(select Id from PdbCustomers where BranchId=3 and UserId = (select Id from PdbUsers where BranchId=3 and Username='charles_barkley')),10000,0);
insert into PdbAccounts (BranchId,AccountNumber,CustomerId,CreditDeposited,CreditWithdrew) values (1,'000010',(select Id from PdbCustomers where BranchId=1 and UserId = (select Id from PdbUsers where BranchId=1 and Username='rick_barry')),10000,0);
insert into PdbAccounts (BranchId,AccountNumber,CustomerId,CreditDeposited,CreditWithdrew) values (2,'000011',(select Id from PdbCustomers where BranchId=2 and UserId = (select Id from PdbUsers where BranchId=2 and Username='larry_bird')),10000,0);
insert into PdbAccounts (BranchId,AccountNumber,CustomerId,CreditDeposited,CreditWithdrew) values (3,'000012',(select Id from PdbCustomers where BranchId=3 and UserId = (select Id from PdbUsers where BranchId=3 and Username='patrick_ewing')),10000,0);
insert into PdbAccounts (BranchId,AccountNumber,CustomerId,CreditDeposited,CreditWithdrew) values (1,'000013',(select Id from PdbCustomers where BranchId=1 and UserId = (select Id from PdbUsers where BranchId=1 and Username='walt_frazier')),10000,0);
insert into PdbAccounts (BranchId,AccountNumber,CustomerId,CreditDeposited,CreditWithdrew) values (2,'000014',(select Id from PdbCustomers where BranchId=2 and UserId = (select Id from PdbUsers where BranchId=2 and Username='magic_johnson')),10000,0);
insert into PdbAccounts (BranchId,AccountNumber,CustomerId,CreditDeposited,CreditWithdrew) values (3,'000015',(select Id from PdbCustomers where BranchId=3 and UserId = (select Id from PdbUsers where BranchId=3 and Username='michael_jordan')),10000,0);
insert into PdbAccounts (BranchId,AccountNumber,CustomerId,CreditDeposited,CreditWithdrew) values (1,'000016',(select Id from PdbCustomers where BranchId=1 and UserId = (select Id from PdbUsers where BranchId=1 and Username='dennis_rodman')),10000,0);
insert into PdbAccounts (BranchId,AccountNumber,CustomerId,CreditDeposited,CreditWithdrew) values (2,'000017',(select Id from PdbCustomers where BranchId=2 and UserId = (select Id from PdbUsers where BranchId=2 and Username='dwyane_wade')),10000,0);
insert into PdbAccounts (BranchId,AccountNumber,CustomerId,CreditDeposited,CreditWithdrew) values (3,'000018',(select Id from PdbCustomers where BranchId=3 and UserId = (select Id from PdbUsers where BranchId=3 and Username='steve_nash')),10000,0);
insert into PdbAccounts (BranchId,AccountNumber,CustomerId,CreditDeposited,CreditWithdrew) values (1,'000019',(select Id from PdbCustomers where BranchId=1 and UserId = (select Id from PdbUsers where BranchId=1 and Username='david_thompson')),10000,0);
insert into PdbAccounts (BranchId,AccountNumber,CustomerId,CreditDeposited,CreditWithdrew) values (2,'000020',(select Id from PdbCustomers where BranchId=2 and UserId = (select Id from PdbUsers where BranchId=2 and Username='sam_jones')),10000,0);
insert into PdbAccounts (BranchId,AccountNumber,CustomerId,CreditDeposited,CreditWithdrew) values (3,'000021',(select Id from PdbCustomers where BranchId=3 and UserId = (select Id from PdbUsers where BranchId=3 and Username='paul_pierce')),10000,0);
insert into PdbAccounts (BranchId,AccountNumber,CustomerId,CreditDeposited,CreditWithdrew) values (1,'000022',(select Id from PdbCustomers where BranchId=1 and UserId = (select Id from PdbUsers where BranchId=1 and Username='chris_webber')),10000,0);
insert into PdbAccounts (BranchId,AccountNumber,CustomerId,CreditDeposited,CreditWithdrew) values (2,'000023',(select Id from PdbCustomers where BranchId=2 and UserId = (select Id from PdbUsers where BranchId=2 and Username='grant_hill')),10000,0);
insert into PdbAccounts (BranchId,AccountNumber,CustomerId,CreditDeposited,CreditWithdrew) values (3,'000024',(select Id from PdbCustomers where BranchId=3 and UserId = (select Id from PdbUsers where BranchId=3 and Username='vince_carter')),10000,0);
insert into PdbAccounts (BranchId,AccountNumber,CustomerId,CreditDeposited,CreditWithdrew) values (1,'000025',(select Id from PdbCustomers where BranchId=1 and UserId = (select Id from PdbUsers where BranchId=1 and Username='tim_hardaway')),10000,0);
insert into PdbAccounts (BranchId,AccountNumber,CustomerId,CreditDeposited,CreditWithdrew) values (2,'000026',(select Id from PdbCustomers where BranchId=2 and UserId = (select Id from PdbUsers where BranchId=2 and Username='chris_mullin')),10000,0);
insert into PdbAccounts (BranchId,AccountNumber,CustomerId,CreditDeposited,CreditWithdrew) values (3,'000027',(select Id from PdbCustomers where BranchId=3 and UserId = (select Id from PdbUsers where BranchId=3 and Username='artis_gilmore')),10000,0);
insert into PdbAccounts (BranchId,AccountNumber,CustomerId,CreditDeposited,CreditWithdrew) values (1,'000028',(select Id from PdbCustomers where BranchId=1 and UserId = (select Id from PdbUsers where BranchId=1 and Username='bill_russell')),10000,0);
insert into PdbAccounts (BranchId,AccountNumber,CustomerId,CreditDeposited,CreditWithdrew) values (2,'000029',(select Id from PdbCustomers where BranchId=2 and UserId = (select Id from PdbUsers where BranchId=2 and Username='kevin_porter')),10000,0);
insert into PdbAccounts (BranchId,AccountNumber,CustomerId,CreditDeposited,CreditWithdrew) values (3,'000030',(select Id from PdbCustomers where BranchId=3 and UserId = (select Id from PdbUsers where BranchId=3 and Username='guy_rodgers')),10000,0);
insert into PdbAccounts (BranchId,AccountNumber,CustomerId,CreditDeposited,CreditWithdrew) values (4,'000031',(select Id from PdbCustomers where BranchId=4 and UserId = (select Id from PdbUsers where BranchId=4 and Username='cynthia_cooper')),10000,0);
insert into PdbAccounts (BranchId,AccountNumber,CustomerId,CreditDeposited,CreditWithdrew) values (4,'000032',(select Id from PdbCustomers where BranchId=4 and UserId = (select Id from PdbUsers where BranchId=4 and Username='lauren_jackson')),10000,0);
insert into PdbAccounts (BranchId,AccountNumber,CustomerId,CreditDeposited,CreditWithdrew) values (4,'000033',(select Id from PdbCustomers where BranchId=4 and UserId = (select Id from PdbUsers where BranchId=4 and Username='lisa_leslie')),10000,0);
insert into PdbAccounts (BranchId,AccountNumber,CustomerId,CreditDeposited,CreditWithdrew) values (4,'000034',(select Id from PdbCustomers where BranchId=4 and UserId = (select Id from PdbUsers where BranchId=4 and Username='katie_smith')),10000,0);
insert into PdbAccounts (BranchId,AccountNumber,CustomerId,CreditDeposited,CreditWithdrew) values (4,'000035',(select Id from PdbCustomers where BranchId=4 and UserId = (select Id from PdbUsers where BranchId=4 and Username='dawn_staley')),10000,0);
insert into PdbAccounts (BranchId,AccountNumber,CustomerId,CreditDeposited,CreditWithdrew) values (5,'000036',(select Id from PdbCustomers where BranchId=5 and UserId = (select Id from PdbUsers where BranchId=5 and Username='sheryl_swoopes')),10000,0);
insert into PdbAccounts (BranchId,AccountNumber,CustomerId,CreditDeposited,CreditWithdrew) values (5,'000037',(select Id from PdbCustomers where BranchId=5 and UserId = (select Id from PdbUsers where BranchId=5 and Username='tina_thompson')),10000,0);
insert into PdbAccounts (BranchId,AccountNumber,CustomerId,CreditDeposited,CreditWithdrew) values (5,'000038',(select Id from PdbCustomers where BranchId=5 and UserId = (select Id from PdbUsers where BranchId=5 and Username='ruthie_bolton')),10000,0);
insert into PdbAccounts (BranchId,AccountNumber,CustomerId,CreditDeposited,CreditWithdrew) values (5,'000039',(select Id from PdbCustomers where BranchId=5 and UserId = (select Id from PdbUsers where BranchId=5 and Username='katie_douglas')),10000,0);
insert into PdbAccounts (BranchId,AccountNumber,CustomerId,CreditDeposited,CreditWithdrew) values (5,'000040',(select Id from PdbCustomers where BranchId=5 and UserId = (select Id from PdbUsers where BranchId=5 and Username='cheryl_ford')),10000,0);
insert into PdbAccounts (BranchId,AccountNumber,CustomerId,CreditDeposited,CreditWithdrew) values (6,'000041',(select Id from PdbCustomers where BranchId=6 and UserId = (select Id from PdbUsers where BranchId=6 and Username='shannon_johnson')),10000,0);
insert into PdbAccounts (BranchId,AccountNumber,CustomerId,CreditDeposited,CreditWithdrew) values (6,'000042',(select Id from PdbCustomers where BranchId=6 and UserId = (select Id from PdbUsers where BranchId=6 and Username='deanna_nolan')),10000,0);
insert into PdbAccounts (BranchId,AccountNumber,CustomerId,CreditDeposited,CreditWithdrew) values (6,'000043',(select Id from PdbCustomers where BranchId=6 and UserId = (select Id from PdbUsers where BranchId=6 and Username='candace_parker')),10000,0);
insert into PdbAccounts (BranchId,AccountNumber,CustomerId,CreditDeposited,CreditWithdrew) values (6,'000044',(select Id from PdbCustomers where BranchId=6 and UserId = (select Id from PdbUsers where BranchId=6 and Username='penny_taylor')),10000,0);
insert into PdbAccounts (BranchId,AccountNumber,CustomerId,CreditDeposited,CreditWithdrew) values (6,'000045',(select Id from PdbCustomers where BranchId=6 and UserId = (select Id from PdbUsers where BranchId=6 and Username='brittney_griner')),10000,0);
insert into PdbCreditCards (BranchId,CardNumber,AccountId) select BranchId,'1234-'+AccountNumber,Id from PdbAccounts;
insert into PdbDeposits (BranchId,AccountId,DepositDate,CreditDeposited) select BranchId,Id,cast(getdate() as smalldatetime),10000 from PdbAccounts;

/*
if object_id('getATMs','P') is not null drop procedure getATMs
go 
create procedure getATMs-- 
as
begin
	select City,Address,PostalCode
	from PdbATMs ATMs
	order by Id;
end;
go

if object_id('getATMsPU','P') is not null drop procedure getATMsPU
go 
create procedure getATMsPU-- 
as
begin
	select City,Address,PostalCode
	from PdbATMs ATMs
	order by Id;
end;
go

if object_id('getATMsPE','P') is not null drop procedure getATMsPE
go 
create procedure getATMsPE-- 
as
begin
	select City,Address,PostalCode
	from PdbATMs ATMs
	order by Id;
end;
go

exec getATMs;
exec getATMsPU;
exec PdbgetATMsPU;

if object_id('getCustomerHistory','P') is not null drop procedure getCustomerHistory
go 
create procedure getCustomerHistory-- 
	(	@UserName				nvarchar(128)
	)
as
begin
	declare @BranchId			tinyint;
	declare @CustomerId 		smallint;
	declare @NationalNumber		nvarchar(16);
	declare @FirstName			nvarchar(128);
	declare @LastName			nvarchar(128);
	
	set @BranchId 		= null;
	set @CustomerId 	= null;
	set @NationalNumber = null;
	select top 1 @BranchId = Users.BranchId,@CustomerId = Customers.Id,@NationalNumber = Customers.NationalNumber,@FirstName = Users.FirstName,@LastName = Users.LastName
	from PdbCustomers 	Customers
	join PdbUsers 		Users 		on Customers.BranchId 		= Users.BranchId		and Customers.UserId = Users.Id
	where Users.Username = @UserName;

	select isnull(@NationalNumber,'') NationalNumber,isnull(@FirstName,'') FirstName,isnull(@LastName,'') LastName,isnull(sum(CreditDeposited),0) CreditDeposited,isnull(sum(CreditWithdrew),0) CreditWithdrew,isnull(sum(CreditDeposited)-sum(CreditWithdrew),0) CreditBalance
	from PdbAccounts Accounts
	where Accounts.BranchId 	= @BranchId
	  and Accounts.CustomerId 	= @CustomerId;

	select Accounts.AccountNumber,Deposits.DepositDate,Deposits.CreditDeposited
	from PdbDeposits	Deposits
	join PdbAccounts 	Accounts	on Deposits.BranchId 		= Accounts.BranchId		and Deposits.AccountId 	= Accounts.Id
	where Deposits.BranchId 	= @BranchId
	  and Accounts.CustomerId 	= @CustomerId
	order by Deposits.DepositDate desc;

	select Accounts.AccountNumber,Withdraws.WithdrawDate,Withdraws.CreditWithdrew,CreditCards.CardNumber,ATMs.Address,ATMs.City,ATMs.PostalCode
	from PdbWithdraws	Withdraws
	join PdbATMs 		ATMs		on Withdraws.BranchId 		= ATMs.BranchId 		and Withdraws.ATMId 		= ATMs.Id
	join PdbCreditCards CreditCards	on Withdraws.BranchId 		= CreditCards.BranchId 	and Withdraws.CreditCardId 	= CreditCards.Id
	join PdbAccounts 	Accounts	on CreditCards.BranchId 	= Accounts.BranchId		and CreditCards.AccountId 	= Accounts.Id
	where Withdraws.BranchId 	= @BranchId
	  and Accounts.CustomerId 	= @CustomerId
	order by Withdraws.WithdrawDate desc;
end;
go

if object_id('getCustomerHistoryPU','P') is not null drop procedure getCustomerHistoryPU
go 
create procedure getCustomerHistoryPU-- 
	(	@BranchId			tinyint
	,   @UserName			nvarchar(128)
	)
as
begin
	declare @CustomerId 		smallint;
	declare @NationalNumber		nvarchar(16);
	declare @FirstName			nvarchar(128);
	declare @LastName			nvarchar(128);

	set @CustomerId 	= null;
	set @NationalNumber = null;

	select top 1 @CustomerId = Customers.Id,@NationalNumber = Customers.NationalNumber,@FirstName = Users.FirstName,@LastName = Users.LastName
	from Customers 	
	join Users 		on Customers.UserId = Users.Id
	where Users.Username = @UserName;	

	select isnull(@NationalNumber,'') NationalNumber,isnull(@FirstName,'') FirstName,isnull(@LastName,'') LastName,isnull(sum(CreditDeposited),0) CreditDeposited,isnull(sum(CreditWithdrew),0) CreditWithdrew,isnull(sum(CreditDeposited)-sum(CreditWithdrew),0) CreditBalance
	from Accounts
	where Accounts.CustomerId = @CustomerId;

	select Accounts.AccountNumber,Deposits.DepositDate,Deposits.CreditDeposited
	from Deposits	
	join Accounts 	on Deposits.AccountId = Accounts.Id
	where Accounts.CustomerId 	= @CustomerId
	order by Deposits.DepositDate desc;

	select Accounts.AccountNumber,Withdraws.WithdrawDate,Withdraws.CreditWithdrew,CreditCards.CardNumber,ATMs.Address,ATMs.City,ATMs.PostalCode
	from Withdraws	
	join ATMs 			on Withdraws.ATMId 			= ATMs.Id
	join CreditCards	on Withdraws.CreditCardId 	= CreditCards.Id
	join Accounts 		on CreditCards.AccountId 	= Accounts.Id
	where Accounts.CustomerId = @CustomerId
	order by Withdraws.WithdrawDate desc;
end;
go

if object_id('getCustomerHistoryPU','P') is not null drop procedure getCustomerHistoryPU
go 
create procedure getCustomerHistoryPU-- 
	(	@BranchId			tinyint
	,   @UserName			nvarchar(128)
	)
as
begin
	declare @CustomerId 		smallint;
	declare @NationalNumber		nvarchar(16);
	declare @FirstName			nvarchar(128);
	declare @LastName			nvarchar(128);
	
	set @CustomerId 	= null;
	set @NationalNumber = null;
	select top 1 @CustomerId = Customers.Id,@NationalNumber = Customers.NationalNumber,@FirstName = Users.FirstName,@LastName = Users.LastName
	from PdbCustomers 	Customers
	join PdbUsers 		Users 		on Customers.BranchId 		= Users.BranchId		and Customers.UserId = Users.Id
	where Users.BranchId 	= @BranchId
	  and Users.Username	= @UserName;

	select isnull(@NationalNumber,'') NationalNumber,isnull(@FirstName,'') FirstName,isnull(@LastName,'') LastName,isnull(sum(CreditDeposited),0) CreditDeposited,isnull(sum(CreditWithdrew),0) CreditWithdrew,isnull(sum(CreditDeposited)-sum(CreditWithdrew),0) CreditBalance
	from PdbAccounts Accounts
	where Accounts.BranchId 	= @BranchId
	  and Accounts.CustomerId 	= @CustomerId;

	select Accounts.AccountNumber,Deposits.DepositDate,Deposits.CreditDeposited
	from PdbDeposits	Deposits
	join PdbAccounts 	Accounts	on Deposits.BranchId 		= Accounts.BranchId		and Deposits.AccountId 	= Accounts.Id
	where Deposits.BranchId 	= @BranchId
	  and Accounts.CustomerId 	= @CustomerId
	order by Deposits.DepositDate desc;

	select Accounts.AccountNumber,Withdraws.WithdrawDate,Withdraws.CreditWithdrew,CreditCards.CardNumber,ATMs.Address,ATMs.City,ATMs.PostalCode
	from PdbWithdraws	Withdraws
	join PdbATMs 		ATMs		on Withdraws.BranchId 		= ATMs.BranchId 		and Withdraws.ATMId 		= ATMs.Id
	join PdbCreditCards CreditCards	on Withdraws.BranchId 		= CreditCards.BranchId 	and Withdraws.CreditCardId 	= CreditCards.Id
	join PdbAccounts 	Accounts	on CreditCards.BranchId 	= Accounts.BranchId		and CreditCards.AccountId 	= Accounts.Id
	where Withdraws.BranchId 	= @BranchId
	  and Accounts.CustomerId 	= @CustomerId
	order by Withdraws.WithdrawDate desc;
end;
go

if object_id('getCardBalance','FN') is not null drop function getCardBalance
go 
create function getCardBalance-- 
	(	@UserName				nvarchar(128)
	,	@CardNumber				nvarchar(64)
	)
	returns decimal(18,3)
as
begin
	declare @CreditBalance		decimal(18,3);
	
	set @CreditBalance = 0;
	select @CreditBalance = Accounts.CreditDeposited - Accounts.CreditWithdrew
	from PdbCreditCards CreditCards
	join PdbAccounts	Accounts	on CreditCards.BranchId 	= Accounts.BranchId		and CreditCards.AccountId 	= Accounts.Id
	join PdbCustomers	Customers	on Accounts.BranchId		= Customers.BranchId	and Accounts.CustomerId		= Customers.Id
	join PdbUsers		Users		on Customers.BranchId		= Users.BranchId		and Customers.UserId		= Users.Id
	where Users.Username = @UserName
	  and CreditCards.CardNumber = @CardNumber;
	
	return @CreditBalance;
end;
go

if object_id('getCardBalancePU','FN') is not null drop function getCardBalancePU
go 
create function getCardBalancePU-- 
	(	@BranchId				tinyint
	,	@UserName				nvarchar(128)
	,	@CardNumber				nvarchar(64)
	)
	returns decimal(18,3)
as
begin
	declare @CreditBalance		decimal(18,3);
	
	set @CreditBalance = 0;
	select @CreditBalance = Accounts.CreditDeposited - Accounts.CreditWithdrew
	from CreditCards
	join Accounts		on CreditCards.AccountId 	= Accounts.Id
	join Customers		on Accounts.CustomerId		= Customers.Id
	join Users			on Customers.UserId			= Users.Id
	where Users.Username = @UserName
	  and CreditCards.CardNumber = @CardNumber;
	
	return @CreditBalance;
end;
go

if object_id('createWithdraw','P') is not null drop procedure createWithdraw
go 
create procedure createWithdraw-- 
	(	@ATMId					smallint
	,	@UserName				nvarchar(128)
	,	@CardNumber				nvarchar(64)
	,	@CreditWithdrew			decimal(18,3)
	)
as
begin
	declare @BranchId			tinyint;
	declare @AccountId			smallint;
	declare @CreditCardId		smallint;
	declare @CreditBalance		decimal(18,3);
	
	set @AccountId		= null;
	set @CreditCardId 	= null;
	set @CreditBalance 	= 0;
	select @BranchId = CreditCards.BranchId,@CreditCardId = CreditCards.Id,@AccountId = Accounts.Id,@CreditBalance = Accounts.CreditDeposited - Accounts.CreditWithdrew
	from PdbCreditCards CreditCards
	join PdbAccounts	Accounts	on CreditCards.BranchId 	= Accounts.BranchId		and CreditCards.AccountId 	= Accounts.Id
	join PdbCustomers	Customers	on Accounts.BranchId		= Customers.BranchId	and Accounts.CustomerId		= Customers.Id
	join PdbUsers		Users		on Customers.BranchId		= Users.BranchId		and Customers.UserId		= Users.Id
	where Users.Username = @UserName
	  and CreditCards.CardNumber = @CardNumber;
	
	if @CreditCardId is null
		raiserror('Cannot find Credit Card',16,1);
	else
	begin
		if isnull(@CreditBalance,0) < @CreditWithdrew
		begin
			raiserror('Withdraw ammount greater than balance',16,1);
		end
		else
		begin
			insert into PdbWithdraws (BranchId,ATMId,CreditCardId,WithdrawDate,CreditWithdrew) 
			values (@BranchId,@ATMId,@CreditCardId,cast(getdate() as smalldatetime),@CreditWithdrew);
			
			update PdbAccounts set CreditWithdrew = CreditWithdrew + @CreditWithdrew 
			where BranchId = @BranchId and Id = @AccountId;
		end;
	end;
end;
go

if object_id('createWithdrawPU','P') is not null drop procedure createWithdrawPU
go 
create procedure createWithdrawPU-- 
	(	@BranchId				tinyint
	,	@ATMId					smallint
	,	@UserName				nvarchar(128)
	,	@CardNumber				nvarchar(64)
	,	@CreditWithdrew			decimal(18,3)
	)
as
begin
	declare @AccountId			smallint;
	declare @CreditCardId		smallint;
	declare @CreditBalance		decimal(18,3);
	
	set @AccountId		= null;
	set @CreditCardId 	= null;
	set @CreditBalance 	= 0;
	select @CreditCardId = CreditCards.Id,@AccountId = Accounts.Id,@CreditBalance = Accounts.CreditDeposited - Accounts.CreditWithdrew
	from CreditCards
	join Accounts		on CreditCards.AccountId 	= Accounts.Id
	join Customers		on Accounts.CustomerId		= Customers.Id
	join Users			on Customers.UserId			= Users.Id
	where Users.Username = @UserName
	  and CreditCards.CardNumber = @CardNumber;
	
	if @CreditCardId is null
		raiserror('Cannot find Credit Card',16,1);
	else
	begin
		if isnull(@CreditBalance,0) < @CreditWithdrew
		begin
			raiserror('Withdraw ammount greater than balance',16,1);
		end
		else
		begin
			insert into Withdraws (BranchId,ATMId,CreditCardId,WithdrawDate,CreditWithdrew) 
			values (@BranchId,@ATMId,@CreditCardId,cast(getdate() as smalldatetime),@CreditWithdrew);
			
			update Accounts set CreditWithdrew = CreditWithdrew + @CreditWithdrew 
			where Id = @AccountId;
		end;
	end;
end;
go

exec getCustomerHistory 					'larry_bird';

exec getCustomerHistoryPU					2,'larry_bird';

exec PdbgetCustomerHistoryPU				2,'larry_bird';

exec SunsetDB.dbo.getCustomerHistoryPU		2,'larry_bird';
exec VeniceDB.dbo.getCustomerHistoryPU		2,'larry_bird';
exec WilshireDB.dbo.getCustomerHistoryPU	2,'larry_bird';

exec SunsetDB.dbo.PdbgetCustomerHistoryPU	2,'larry_bird';
exec VeniceDB.dbo.PdbgetCustomerHistoryPU	2,'larry_bird';
exec WilshireDB.dbo.PdbgetCustomerHistoryPU	2,'larry_bird';

select dbo.getCardBalance					('larry_bird','1234-000011');
select dbo.getCardBalancePU					(2,'larry_bird','1234-000011');
select VeniceDB.dbo.getCardBalancePU		(2,'larry_bird','1234-000011');

exec createWithdraw 	 2,'larry_bird','1234-000011',10.6;
exec PdbcreateWithdrawPU 2,2,'larry_bird','1234-000011',10.6;

*/