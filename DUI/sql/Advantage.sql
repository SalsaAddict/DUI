--USE [master]; IF DB_ID(N'Advantage') IS NOT NULL DROP DATABASE [Advantage]; CREATE DATABASE [Advantage]
USE [Advantage]
SET NOCOUNT ON
GO

DECLARE @SQL NVARCHAR(max)
SELECT @SQL = ISNULL(@SQL + NCHAR(13) + NCHAR(10), N'') +
	N'ALTER TABLE ' + QUOTENAME(OBJECT_NAME([parent_object_id]), N'[') +
	N' DROP CONSTRAINT ' + QUOTENAME([name], N'[')
FROM sys.foreign_keys
EXEC (@SQL)
GO

IF OBJECT_ID(N'ProgrammeRiskCode', N'U') IS NOT NULL DROP TABLE [ProgrammeRiskCode]
IF OBJECT_ID(N'ProgrammeBinderSection', N'U') IS NOT NULL DROP TABLE [ProgrammeBinderSection]
IF OBJECT_ID(N'ProgrammeBinder', N'U') IS NOT NULL DROP TABLE [ProgrammeBinder]
IF OBJECT_ID(N'Programme', N'U') IS NOT NULL DROP TABLE [Programme]
IF OBJECT_ID(N'BinderSectionUnderwriter', N'U') IS NOT NULL DROP TABLE [BinderSectionUnderwriter]
IF OBJECT_ID(N'BinderSection', N'U') IS NOT NULL DROP TABLE [BinderSection]
IF OBJECT_ID(N'BinderUnderwriter', N'U') IS NOT NULL DROP TABLE [BinderUnderwriter]
IF OBJECT_ID(N'Binder', N'U') IS NOT NULL DROP TABLE [Binder]
IF OBJECT_ID(N'RiskCode', N'U') IS NOT NULL DROP TABLE [RiskCode]
IF OBJECT_ID(N'RiskCategory', N'U') IS NOT NULL DROP TABLE [RiskCategory]
IF OBJECT_ID(N'RiskType', N'U') IS NOT NULL DROP TABLE [RiskType]
IF OBJECT_ID(N'Company', N'U') IS NOT NULL DROP TABLE [Company]
IF OBJECT_ID(N'fnCompanyIsDescendant', N'FN') IS NOT NULL DROP FUNCTION [fnCompanyIsDescendant]
IF OBJECT_ID(N'TerritoryCountry', N'U') IS NOT NULL DROP TABLE [TerritoryCountry]
IF OBJECT_ID(N'Territory', N'U') IS NOT NULL DROP TABLE [Territory]
IF OBJECT_ID(N'Country', N'U') IS NOT NULL DROP TABLE [Country]
GO

CREATE TABLE [Country] (
		[Id] NCHAR(2) NOT NULL,
		[Name] NVARCHAR(255) NOT NULL,
		CONSTRAINT [PK_Country] PRIMARY KEY NONCLUSTERED ([Id]),
		CONSTRAINT [UQ_Country_Name] UNIQUE CLUSTERED ([Name])
	)
GO

CREATE TABLE [Territory] (
		[Id] INT NOT NULL IDENTITY (1, 1),
		[Name] NVARCHAR(255) NOT NULL,
		[CountryFilter] BIT NULL,
		CONSTRAINT [PK_Territory] PRIMARY KEY NONCLUSTERED ([Id]),
		CONSTRAINT [UQ_Territory_Name] UNIQUE CLUSTERED ([Name]),
		CONSTRAINT [UQ_Territory_CountryFilter] UNIQUE ([Id], [CountryFilter])
	)
GO

CREATE TABLE [TerritoryCountry] (
		[TerritoryId] INT NOT NULL,
		[CountryFilter] BIT NOT NULL,
		[CountryId] NCHAR(2) NOT NULL,
		CONSTRAINT [PK_TerritoryCountry] PRIMARY KEY CLUSTERED ([TerritoryId], [CountryId]),
		CONSTRAINT [FK_TerritoryCountry_Territory] FOREIGN KEY ([TerritoryId], [CountryFilter])
			REFERENCES [Territory] ([Id], [CountryFilter]) ON UPDATE CASCADE,
		CONSTRAINT [FK_TerritoryCountry_Country] FOREIGN KEY ([CountryId]) REFERENCES [Country] ([Id])
	)
GO

INSERT INTO [Country] ([Id], [Name])
VALUES
	(N'GB', N'United Kingdom'),
	(N'US', N'United States'),
	(N'AU', N'Australia'),
	(N'CA', N'Canada')
GO

SET IDENTITY_INSERT [Territory] ON
INSERT INTO [Territory] ([Id], [Name], [CountryFilter])
VALUES
	(0, N'All Countries', NULL)
SET IDENTITY_INSERT [Territory] OFF
GO

CREATE TABLE [Company] (
		[Id] INT NOT NULL IDENTITY (1, 1),
		[ParentId] INT NULL,
		[DisplayName] AS [Name] + N' ' + QUOTENAME([CountryId], N'[') PERSISTED,
		[Name] NVARCHAR(255) NOT NULL,
		[Address] NVARCHAR(255) NULL,
		[CountryId] NCHAR(2) NOT NULL,
		[Telephone] NVARCHAR(50) NULL,
		[Fax] NVARCHAR(50) NULL,
		[Email] NVARCHAR(255) NULL,
		[Url] NVARCHAR(255) NULL,
		[CreatedWhen] DATETIMEOFFSET NOT NULL CONSTRAINT [DF_Company_CreatedWhen] DEFAULT (GETUTCDATE()),
		[CreatedByWhom] NVARCHAR(255) NOT NULL CONSTRAINT [DF_Company_CreatedByWhom] DEFAULT (N'System'),
		[UpdatedWhen] DATETIMEOFFSET NOT NULL CONSTRAINT [DF_Company_UpdatedWhen] DEFAULT (GETUTCDATE()),
		[UpdatedByWhom] NVARCHAR(255) NOT NULL CONSTRAINT [DF_Company_UpdatedByWhom] DEFAULT (N'System'),
		CONSTRAINT [PK_Company] PRIMARY KEY NONCLUSTERED ([Id]),
		CONSTRAINT [UQ_Company_DisplayName] UNIQUE CLUSTERED ([Name], [CountryId]),
		CONSTRAINT [FK_Company_Company] FOREIGN KEY ([ParentId]) REFERENCES [Company] ([Id]),
		CONSTRAINT [FK_Company_Country] FOREIGN KEY ([CountryId]) REFERENCES [Country] ([Id]),
		CONSTRAINT [CK_Company_UpdatedWhen] CHECK ([UpdatedWhen] >= [CreatedWhen])
	)
GO

SET IDENTITY_INSERT [Company] ON
INSERT INTO [Company] ([Id], [ParentId], [Name], [CountryId])
OUTPUT [inserted].*
VALUES
	(1, NULL, N'Advent Insurance Management Limited', N'GB'),
	(2, 1, N'Advent Insurance Management LLC', N'US'),
	(3, 1, N'Advent Insurance Management PTY', N'AU'),
	(4, 1, N'Advent Insurance Management', N'CA')
SET IDENTITY_INSERT [Company] OFF
GO

CREATE FUNCTION [fnCompanyIsDescendant](@AncestorId INT, @DescendantId INT)
RETURNS BIT
AS
BEGIN
	IF @AncestorId IS NULL OR @DescendantId IS NULL RETURN 0
	WHILE ISNULL(@DescendantId, @AncestorId) != @AncestorId
		SELECT @DescendantId = [ParentId]
		FROM [Company]
		WHERE [Id] = @DescendantId
	RETURN CASE WHEN @DescendantId IS NULL THEN 0 ELSE 1 END
END
GO

ALTER TABLE [Company] ADD
	CONSTRAINT [CK_Company_ParentId] CHECK ([dbo].[fnCompanyIsDescendant]([Id], [ParentId]) = 0)
GO

CREATE TABLE [RiskType] (
		[Type] NVARCHAR(50) NOT NULL,
		CONSTRAINT [PK_RiskType] PRIMARY KEY CLUSTERED ([Type])
	)
GO

CREATE TABLE [RiskCategory] (
		[Type] NVARCHAR(50) NOT NULL,
		[Category] NVARCHAR(50) NOT NULL,
		CONSTRAINT [PK_RiskCategory] PRIMARY KEY CLUSTERED ([Type], [Category]),
		CONSTRAINT [FK_RiskCategory_RiskType] FOREIGN KEY ([Type]) REFERENCES [RiskType] ([Type])
	)
GO

CREATE TABLE [RiskCode] (
		[Id] NVARCHAR(5),
		[Type] NVARCHAR(50) NOT NULL,
		[Category] NVARCHAR(50) NOT NULL,
		[Description] NVARCHAR(255) NOT NULL,
		[InceptionDate] DATE NOT NULL,
		[ExpiryDate] DATE NULL,
		[TerrorismCode] NVARCHAR(25) NULL,
		CONSTRAINT [PK_RiskCode] PRIMARY KEY NONCLUSTERED ([Id]),
		CONSTRAINT [UQ_RiskCode_Clustered] UNIQUE CLUSTERED ([Type], [Category], [Description], [Id]),
		CONSTRAINT [FK_RiskCode_RiskCategory] FOREIGN KEY ([Type], [Category]) REFERENCES [RiskCategory] ([Type], [Category]),
		CONSTRAINT [CK_RiskCode_ExpiryDate] CHECK ([ExpiryDate] >= [InceptionDate])
	)
GO

DECLARE @Lloyds TABLE (
		[Code] NVARCHAR(2) NOT NULL,
		[Description] NVARCHAR(255) NOT NULL,
		[InceptionDate] INT NOT NULL,
		[ExpiryDate] INT NOT NULL,
		[Category] NVARCHAR(255) NOT NULL,
		[Type] NVARCHAR(255) NOT NULL
	)

INSERT INTO @Lloyds
SELECT *
FROM (VALUES
			('1', 'AVIATION HULL AND LIAB INCL WAR EXCL WRO NO PROPOR RI', 1991, 2000, 'Airline/ General Aviation', 'Aviation'),
			('2', 'AVIATION HULL AND LIAB INCL WAR EXCL WRO NO PROPOR RI', 1991, 2000, 'Airline/ General Aviation', 'Aviation'),
			('3', 'AVIATION HULL AND LIAB INCL WAR EXCL WRO NO PROPOR RI', 1991, 2000, 'Airline/ General Aviation', 'Aviation'),
			('4', 'AVIATION HULL AND LIAB INCL WAR EXCL WRO NO PROPOR RI', 1991, 2000, 'Airline/ General Aviation', 'Aviation'),
			('5', 'AVIATION HULL AND LIAB INCL WAR EXCL WRO NO PROPOR RI', 1991, 2000, 'Airline/ General Aviation', 'Aviation'),
			('6', 'AVIATION HULL AND LIAB INCL WAR EXCL WRO NO PROPOR RI', 1991, 2000, 'Airline/ General Aviation', 'Aviation'),
			('7', 'AVIATION HULL AND LIAB INCL WAR EXCL WRO NO PROPOR RI', 1991, 2000, 'Airline/ General Aviation', 'Aviation'),
			('8', 'AVIATION HULL AND LIAB INCL WAR EXCL WRO NO PROPOR RI', 1991, 2000, 'Airline/ General Aviation', 'Aviation'),
			('9', 'AVIATION HULL AND LIAB INCL WAR EXCL WRO NO PROPOR RI', 1991, 2000, 'Airline/ General Aviation', 'Aviation'),
			('1E', 'OVERSEAS LEG TERRORISM ENERGY OFFSHORE PROPERTY', 2000, 9999, 'Terrorism', 'Property (D&F)'),
			('1T', 'OVERSEAS LEG TERRORISM ACCIDENT AND HEALTH', 2000, 9999, 'Terrorism', 'Property (D&F)'),
			('2E', 'OVERSEAS LEG TERRORISM ENERGY OFFSHORE LIABILITY', 2000, 9999, 'Terrorism', 'Property (D&F)'),
			('2T', 'OVERSEAS LEG TERRORISM AVIATION', 2000, 9999, 'Terrorism', 'Property (D&F)'),
			('3E', 'OVERSEAS LEG TERRORISM ENERGY ONSHORE PROPERTY', 2000, 9999, 'Terrorism', 'Property (D&F)'),
			('3T', 'OVERSEAS LEG TERRORISM MARINE', 2000, 9999, 'Terrorism', 'Property (D&F)'),
			('4E', 'OVERSEAS LEG TERRORISM ENERGY ONSHORE LIABILITY', 2000, 9999, 'Terrorism', 'Property (D&F)'),
			('4T', 'OVERSEAS LEG TERRORISM MISC AND PECUNIARY LOSS', 2000, 9999, 'Terrorism', 'Property (D&F)'),
			('5T', 'OVERSEAS LEG TERRORISM MOTOR', 2000, 9999, 'Terrorism', 'Property (D&F)'),
			('6T', 'OVERSEAS LEG TERRORISM PROPERTY', 2000, 9999, 'Terrorism', 'Property (D&F)'),
			('7T', 'OVERSEAS LEG TERRORISM THIRD PARTY LIABILITY', 2000, 9999, 'Terrorism', 'Property (D&F)'),
			('8T', 'OVERSEAS LEG TERRORISM TRANSPORT', 2000, 9999, 'Terrorism', 'Property (D&F)'),
			('AG', 'AGRICULTURAL CROP AND FORESTRY XOL TREATY INCL STOP LOSS', 1993, 9999, 'Agriculture & Hail', 'Property Treaty'),
			('AO', 'AVIATION PREMISES LEGAL LIABILITY NO PRODUCTS', 1991, 9999, 'Aviation Products/ Airport Liabilities', 'Aviation'),
			('AP', 'AVIATION OR AEROSPACE PRODUCTS LEGAL LIABILITY', 1991, 9999, 'Aviation Products/ Airport Liabilities', 'Aviation'),
			('AR', 'AVN WHOLE ACCT STOP LOSS AND OR AGG EXCESS OF LOSS - Risk code retired with effect from 01/01/05: use risk code "XY"', 1993, 2004, 'Aviation XL', 'Aviation'),
			('AW', 'HULLS OF AIRCRAFT WAR OR CONFISCATION NO ACV', 1991, 9999, 'Aviation War', 'Aviation'),
			('AX', 'AVIATION LIABILITY EXCESS OF LOSS - Risk code retired with effect from 01/01/05: use risk code "XY"', 1992, 2004, 'Aviation XL', 'Aviation'),
			('B', 'Vessels TLO IV LOH and Containers Excl. WRO', 1991, 9999, 'Marine Hull', 'Marine'),
			('B2', 'PHYS DAMAGE BINDER FOR PRIVATE PPTY IN USA', 2004, 9999, 'Property D&F (US binder)', 'Property (D&F)'),
			('B3', 'PHYS DAMAGE BINDER FOR COMMERCIAL PPTY IN USA', 2004, 9999, 'Property D&F (US binder)', 'Property (D&F)'),
			('B4', 'PHYS DAMAGE BINDER FOR PRIVATE PPTY EXCL USA', 2004, 9999, 'Property D&F (non-US binder)', 'Property (D&F)'),
			('B5', 'PHYS DAMAGE BINDER FOR COMMERCIAL PPTY EXCL USA', 2004, 9999, 'Property D&F (non-US binder)', 'Property (D&F)'),
			('BB', 'FIDELITY COMPUTER CRIME AND BANKERS POLICIES', 1991, 9999, 'BBB/ Crime', 'Casualty'),
			('BD', 'TERRORISM POOL RE', 1991, 9999, 'Terrorism', 'Property (D&F)'),
			('BS', 'MORTGAGE INDEMNITY UK PRIVATE - Risk code retired with effect from 01/01/05: use risk code "FM"', 1991, 2004, 'Political Risks, Credit & Financial Guarantee', 'Marine'),
			('CA', 'ENGINEERING INCL MCHY AND BOILERS CAR AND ENG AR - Risk code retired with effect from 01/01/2011: use risk codes "CB" or "CC" as appropriate', 1991, 2010, 'Engineering', 'Property (D&F)'),
			('CB', 'ENGINEERING ANNUAL RENEWABLE INCL CAR EAR MB CPE B&M EEI AND TREATY LOD', 2011, 9999, 'Engineering', 'Property (D&F)'),
			('CC', 'ENGINEERING SINGLE PROJECT NON RENEWABLE INCL CAR EAR AND TREATY RAD', 2011, 9999, 'Engineering', 'Property (D&F)'),
			('CF', 'CONTRACT FRUSTRATION IN ACCORD MKT BULLETIN 4396 DATED 07/05/2010 - From 01/01/05 also includes business previously coded "CP" ', 1991, 9999, 'Political Risks, Credit & Financial Guarantee', 'Marine'),
			('CN', 'CREDIT NON PROPORTIONAL TREATY BUSINESS - Risk code retired with effect from 01/01/05: use risk code "CR"', 1998, 2004, 'Political Risks, Credit & Financial Guarantee', 'Marine'),
			('CP', 'CONTRACT FRUSTRATION EXCLUDING WAR AND INSOLVENCY - Risk code retired with effect from 01/01/05: use risk code "CF"', 1993, 2004, 'Political Risks, Credit & Financial Guarantee', 'Marine'),
			('CR', 'CREDIT BUSINESS IN ACCORD MKT BULLETIN 4396 DATED 07/05/2010 - From 01/01/05 also includes business previously coded "CN" ', 1991, 9999, 'Political Risks, Credit & Financial Guarantee', 'Marine'),
			('CT', 'ARMOURED CARRIERS AND CASH IN TRANSIT', 1992, 9999, 'Specie', 'Marine'),
			('CX', 'SPACE RISKS LAUNCH COMMISSIONING AND TRANSPOND OP - Risk code being retired with effect from 01/01/2008: use risk code "SC"', 1992, 2007, 'Space', 'Aviation'),
			('CY', 'Cyber Security Data and Privacy Breach', 2013, 9999, 'Cyber', 'Casualty'),
			('CZ', 'CYBER SECURITY AND PROPERTY DAMAGE', 2015, 9999, 'Cyber', 'Casualty'),
			('D2', 'D AND O LIAB EXCL FINANCIAL INSTITUTIONS IN USA', 2004, 9999, 'Directors & Officers (US)', 'Casualty'),
			('D3', 'D AND O LIAB EXCL FINANCIAL INSTITUTIONS EXCL USA ', 2004, 9999, 'Directors & Officers (non-US)', 'Casualty'),
			('D4', 'D AND O LIAB FOR FINANCIAL INSTITUTIONS INCL USA', 2004, 9999, 'Financial Institutions (US)', 'Casualty'),
			('D5', 'D AND O LIAB FOR FINANCIAL INSTITUTIONS EXCL USA', 2004, 9999, 'Financial Institutions (non-US)', 'Casualty'),
			('D6', 'Employment Practices Liability Insurance (EPLI) Incl. US', 2016, 9999, 'Directors & Officers (US)', 'Casualty'),
			('D7', 'Employment Practices Liability Insurance (EPLI) Excl. US', 2016, 9999, 'Directors & Officers (non-US)', 'Casualty'),
			('D8', 'Transactional Liability insurance Incl. US', 2016, 9999, 'Directors & Officers (US)', 'Casualty'),
			('D9', 'Transactional Liability insurance Excl. US', 2016, 9999, 'Directors & Officers (non-US)', 'Casualty'),
			('DC', 'DIFFERENCE IN CONDITIONS', 1991, 9999, 'Difference in Conditions', 'Property (D&F)'),
			('DM', 'DIRECTORS AND OFFICERS LIAB FOR FINANCIAL INST. - Risk code retired with effect from 01/01/05: use risk codes "D4" or "D5" as appropriate', 2002, 2004, 'Directors & Officers', 'Casualty'),
			('DO', 'DIRECTORS AND OFFICERS LIAB EXCL FINANCIAL INST. - Risk code retired with effect from 01/01/05: use risk codes "D2" or "D3" as appropriate ', 1991, 2004, 'Directors & Officers', 'Casualty'),
			('DX', 'PERSONAL ACCIDENT AND SICKNESS AVIATION', 1992, 1994, 'Personal Accident XL', 'Accident & Health'),
			('E2', 'PROF INDTY E AND O FOR LEGAL PROFESSIONS INCL USA', 2004, 9999, 'Professional Indemnity (US)', 'Casualty'),
			('E3', 'PROF INDTY E AND O FOR LEGAL PROFESSIONS EXCL USA', 2004, 9999, 'Professional Indemnity (non-US)', 'Casualty'),
			('E4', 'PROF INDTY E AND O FOR ACCOUNTANTS INCL USA', 2004, 9999, 'Professional Indemnity (US)', 'Casualty'),
			('E5', 'PROF INDTY E AND O FOR ACCOUNTANTS EXCL USA', 2004, 9999, 'Professional Indemnity (non-US)', 'Casualty'),
			('E6', 'PROF INDTY E AND O ARCHITECTS ENGINEERS INCL USA', 2004, 9999, 'Professional Indemnity (US)', 'Casualty'),
			('E7', 'PROF INDTY E AND O ARCHITECTS AND ENGINEERS EXCL USA', 2004, 9999, 'Professional Indemnity (non-US)', 'Casualty'),
			('E8', 'MISC PROF IND E AND O INCL USA EXCL "E2" "E4" "E6" CODES', 2004, 9999, 'Professional Indemnity (US)', 'Casualty'),
			('E9', 'MISC PROF IND E AND O EXCL USA EXCL "E3" "E5" "E7" CODES', 2004, 9999, 'Professional Indemnity (non-US)', 'Casualty'),
			('EA', 'ENERGY LIABILITY ONSHORE CLAIMS MADE', 1991, 9999, 'Energy Onshore Liability', 'Energy'),
			('EB', 'ENERGY LIABILITY ONSHORE ALL OTHER', 1991, 9999, 'Energy Onshore Liability', 'Energy'),
			('EC', 'ENERGY CONSTRUCTION OFFSHORE PROP AND SEARCH PROD VSSLS EXCL WRO', 2010, 9999, 'Energy Offshore Property', 'Energy'),
			('EF', 'ENERGY ONSHORE PROPERTY', 1991, 9999, 'Energy Onshore Property', 'Energy'),
			('EG', 'ENERGY LIABILITY OFFSHORE CLAIMS MADE', 1991, 9999, 'Energy Offshore Liability', 'Energy'),
			('EH', 'ENERGY LIABILITY OFFSHORE ALL OTHER', 1991, 9999, 'Energy Offshore Liability', 'Energy'),
			('EM', 'ENERGY SEARCH PROD VSSLS AND OFFSHORE PROP GOM WIND EXCL WRO EXCL CONSTRUCTION', 2011, 9999, 'Energy Offshore Property', 'Energy'),
			('EN', 'ENERGY SEARCH PROD VSSLS AND OFFSHORE PROP EXCL GOM WIND EXCL WRO EXCL CONSTRUCTION', 2011, 9999, 'Energy Offshore Property', 'Energy'),
			('EP', 'Environmental Impairment Liability or NM Pollution Liability', 2016, 9999, 'NM General Liability (non-US direct)', 'Casualty'),
			('ET', 'ENERGY SEARCH PROD VSSLS AND OFFSHORE PROP EXCL WRO EXCL CONSTRUCTION - Risk code retired with effect from 01/01/2011: use risk codes "EM" or "EN" as appropriate ', 1991, 2010, 'Energy Offshore Property', 'Energy'),
			('EW', 'ENERGY OPERATORS XTRA EXPENSES AND CONTROL OF WELL - Risk code retired with effect from 01/01/2011: use risk codes "EY" or "EZ" as appropriate', 1991, 2010, 'Energy Offshore Property', 'Energy'),
			('EY', 'ENERGY OPERATORS XTRA EXPENSES AND CONTROL OF WELL GOM  WIND', 2011, 9999, 'Energy Offshore Property', 'Energy'),
			('EZ', 'ENERGY OPERATORS XTRA EXPENSES AND CONTROL OF WELL EXCL GOM WIND', 2011, 9999, 'Energy Offshore Property', 'Energy'),
			('F', 'FIRE AND PERILS - Risk code retired with effect from 01/01/05: use risk codes "B2" to "B5" or "P2" to "P7" as appropriate', 1991, 2004, 'Property (direct & facultative)', 'Property (D&F)'),
			('F2', 'PROF INDTY E AND O FOR FIN INSTITUTIONS INCL USA', 2004, 9999, 'Financial Institutions (US)', 'Casualty'),
			('F3', 'PROF INDTY E AND O FOR FIN INSTITUTIONS EXCL USA', 2004, 9999, 'Financial Institutions (non-US)', 'Casualty'),
			('F4', 'Technology and Telecommunications E&O Incl. US', 2016, 9999, 'Professional Indemnity (US)', 'Casualty'),
			('F5', 'Technology and Telecommunications E&O Excl. US', 2016, 9999, 'Professional Indemnity (non-US)', 'Casualty'),
			('FA', 'FINE ART', 1992, 9999, 'Fine Art', 'Marine'),
			('FC', 'COLLISION SALVAGE GENERAL AVERAGE GUARANTEES  - Risk code retired with effect from 01/01/05: use risk code "SB"', 1999, 2004, 'Cargo', 'Marine'),
			('FG', 'FINANCIAL GUARANTEE (authorised syndicates only)', 2001, 9999, 'Political Risks, Credit & Financial Guarantee', 'Marine'),
			('FM', 'MORTGAGE INDEMNITY - From 01/01/05 also includes business previously coded "BS" ', 1999, 9999, 'Political Risks, Credit & Financial Guarantee', 'Marine'),
			('FR', 'FURRIERS - Risk code retired with effect from 01/01/05: use risk code "JB"', 1992, 2004, 'Specie', 'Marine'),
			('FS', 'SURETY BOND RI WEF 31/10/01 EXCL SB COUNTRIES - Risk code retired with effect from 01/01/05: use risk code "SB"', 1999, 2004, 'Political Risks, Credit & Financial Guarantee', 'Marine'),
			('G', 'MARINE LEGAL LIAB ALL OTHER NO CARGO EXCL WRO', 1991, 9999, 'Marine Liability', 'Marine'),
			('GC', 'MARINE LEGAL LIAB CLAIMS MADE NO CARGO EXCL WRO', 1991, 9999, 'Marine Liability', 'Marine'),
			('GH', 'HOSPITALS/ INSTITUTIONAL HEALTHCARE INSURANCE RISKS IN USA', 2008, 9999, 'Medical Malpractice', 'Casualty'),
			('GM', 'MEDICAL MALPRACTICE EXCL USA ', 2008, 9999, 'Medical Malpractice', 'Casualty'),
			('GN', 'NURSING HOMES/ LONG-TERM AND ALLIED HEALTHCARE/OTHER MEDICAL MALPRACTICE RISKS IN USA', 2008, 9999, 'Medical Malpractice', 'Casualty'),
			('GP', 'MEDICAL MALPRACTICE NON MARINE - Risk code being retired with effect from 01/01/2008: use risk codes "GH" "GT" "GN" and "GM" as appropriate', 1995, 2007, 'Medical Malpractice', 'Casualty'),
			('GS', 'GENERAL SPECIE INCLUDING VAULT RISK', 1992, 9999, 'Specie', 'Marine'),
			('GT', 'MEDICAL MALPRACTICE TREATY XOL IN USA', 2008, 9999, 'Medical Malpractice', 'Casualty'),
			('GX', 'XOL MARINE LEGAL LIAB EXCL CARGO ALL OTHER EXCL WRO', 1992, 9999, 'Marine XL', 'Marine'),
			('H', 'HULLS OF AIRCRAFT EXCL SPACE OR ACV EXCL WRO - Risk code retired with effect from 01/01/05: use risk codes "H2" or "H3" as appropriate', 1991, 2004, 'Airline/ General Aviation', 'Aviation'),
			('H2', 'AIRLINE HULL', 2004, 9999, 'Airline', 'Aviation'),
			('H3', 'GENERAL AVIATION HULL', 2004, 9999, 'General Aviation', 'Aviation'),
			('HA', 'AGRICULTURAL CROP AND FORESTRY EXCL XOL TREATY AND STOP LOSS', 1991, 9999, 'Agriculture & Hail', 'Property Treaty'),
			('HP', 'UK HOUSEHOLD BUSINESS', 1993, 9999, 'Property D&F (non-US binder)', 'Property (D&F)'),
			('HX', 'XOL HULLS OF AIRCRAFT INCL SPARES AND LOU EXCL WRO - Risk code being retired with effect from 01/01/2008: use risk code "XY"', 1992, 2007, 'Aviation XL', 'Aviation'),
			('JB', 'JEWELLERS BLOCK JEWELLERY ETC INCL ROBBERY - From 01/01/05 also includes business previously coded "FR" ', 1991, 9999, 'Specie', 'Marine'),
			('K', 'PERSONAL ACCIDENT AND SICKNESS', 1991, 1994, 'Accident & Health (direct)', 'Accident & Health'),
			('KA', 'PERSONAL ACCIDENT AND HEALTH CARVE OUT', 1995, 9999, 'Accident & Health (direct)', 'Accident & Health'),
			('KC', 'PERSONAL ACCIDENT AND HEALTH CREDITOR  DISABILITY', 1995, 9999, 'Accident & Health (direct)', 'Accident & Health'),
			('KD', 'PERSONAL ACCIDENT AND SICKNESS  AVIATION', 1991, 1994, 'Accident & Health (direct)', 'Accident & Health'),
			('KG', 'Personal Accident and Health Excl. K&R, KP KS AND KT CODES', 2004, 9999, 'Accident & Health (direct)', 'Accident & Health'),
			('KK', 'PERSONAL ACCIDENT AND HEALTH - Risk code retired with effect from 01/01/05: use risk codes "KG" "KS"or "KT" as appropriate', 1995, 2004, 'Accident & Health (direct)', 'Accident & Health'),
			('KL', 'PERSONAL ACCIDENT AND HEALTH LMX - Risk code being retired with effect from 01/01/2008: use risk code "KX"', 1995, 2007, 'Personal Accident XL', 'Accident & Health'),
			('KM', 'MEDICAL EXPENSES INCL XS SPEC AND AGG SELF FUND', 1995, 9999, 'Medical Expenses', 'Accident & Health'),
			('KP', 'MARITIME EXTORTION EXCL KIDNAP AND RANSOM WRITTEN UNDER KG', 2013, 9999, 'Accident & Health (direct)', 'Accident & Health'),
			('KS', 'PA AND HEALTH INCL SPORTS DIS OTHER THAN ACC DEATH', 2004, 9999, 'Accident & Health (direct)', 'Accident & Health'),
			('KT', 'PA AND HEALTH FOR TRAVEL PACKAGE SCHEMES', 2004, 9999, 'Accident & Health (direct)', 'Accident & Health'),
			('KX', 'PERSONAL ACCIDENT AND HEALTH CATASTROPHE XL - From 01/01/08 also includes business previously coded "KL"', 1995, 9999, 'Personal Accident XL', 'Accident & Health'),
			('L', 'AIRCRAFT OPERATORS AND OWNERS LEGAL LIAB  - Risk code retired with effect from 01/01/2005: use risk codes "L2" or "L3" as appropriate', 1991, 2004, 'Airline/ General Aviation', 'Aviation'),
			('L2', 'AIRLINE LIABILITY', 2004, 9999, 'Airline', 'Aviation'),
			('L3', 'GENERAL AVIATION LIABILITY', 2004, 9999, 'General Aviation', 'Aviation'),
			('LE', 'LEGAL EXPENSES    ', 1991, 9999, 'Legal Expenses', 'Accident & Health'),
			('LJ', 'FOR USE BY LLOYDS JAPAN ONLY', 1997, 9999, 'Lloyd''s Japan', 'Property (D&F)'),
			('LX', 'AIRCRAFT OPERATORS AND OWNERS LEGAL LIAB', 1992, 1996, 'Aviation XL', 'Aviation'),
			('M2', 'UK MOTOR COMP FOR PRIVATE CAR INCL MOTORCYCLE', 2004, 9999, 'UK Motor', 'UK Motor'),
			('M3', 'UK MOTOR COMP FOR FLEET AND COMMERCIAL VEHICLE', 2004, 9999, 'UK Motor', 'UK Motor'),
			('M4', 'OTHER UK MOTOR COMP AND NON COMP EXCL "M2" AND "M3" CODES - From 01/01/08 includes business previously coded "M7"', 2004, 9999, 'UK Motor', 'UK Motor'),
			('M5', 'UK MOTOR NON COMP FOR PRIVATE CAR INCL MOTORCYCLE', 2004, 9999, 'UK Motor', 'UK Motor'),
			('M6', 'UK MOTOR NON COMP FOR FLEET AND COMM VEHICLE', 2004, 9999, 'UK Motor', 'UK Motor'),
			('M7', 'OTHER UK MOTOR NON COMP EXCL "M5" AND "M6" CODES - Risk code being retired with effect from 1/1/2008: use risk code "M4"', 2004, 2007, 'UK Motor', 'UK Motor'),
			('MA', 'UK MOTOR VEHICLE PHYSICAL DAMAGE ONLY - Risk code retired with effect from 01/01/05: use risk codes "M2" to "M4" as appropriate', 1991, 2004, 'UK Motor', 'UK Motor'),
			('MB', 'UK MOTOR VEHICLE THIRD PARTY LIABILITY', 1991, 1995, 'UK Motor', 'UK Motor'),
			('MC', 'UK MOTOR VEHICLE DAMAGE AND THIRD PARTY LIABILITY', 1991, 1995, 'UK Motor', 'UK Motor'),
			('MD', 'OVERSEAS MOTOR PHYS DAM EXCL USA CAN EU AND EEA - Risk code retired with effect from 01/01/05: use risk code "MF"', 1991, 2004, 'Overseas Motor', 'Overseas Motor'),
			('ME', 'OVERSEAS MOTOR TPL EXCL USA CAN EU AND EEA - Risk code retired with effect from 01/01/05: use risk code "MF"', 1991, 2004, 'Overseas Motor', 'Overseas Motor'),
			('MF', 'OVERSEAS MOTOR DAM AND TPL EXCL USA CAN EU AND EEA - From 01/01/05 also includes business previously coded "MD" and "ME"', 1991, 9999, 'Overseas Motor', 'Overseas Motor'),
			('MG', 'USA AND CANADA MOTOR VEHICLE PHYSICAL DAMAGE', 1991, 9999, 'Overseas Motor', 'Overseas Motor'),
			('MH', 'USA AND CANADA MOTOR VEHICLE THIRD PARTY LIABILITY', 1991, 9999, 'Overseas Motor', 'Overseas Motor'),
			('MI', 'USA AND CANADA MOTOR DAMAGE AND 3RD PARTY LIAB', 1991, 9999, 'Overseas Motor', 'Overseas Motor'),
			('MK', 'UK MOTOR VEHICLE COMPREHENSIVE - Risk code retired with effect from 01/01/2005: use risk codes "M2" to "M4" as appropriate', 1995, 2004, 'UK Motor', 'UK Motor'),
			('ML', 'UK MOTOR VEHICLE NON COMPREHENSIVE - Risk code retired with effect from 01/01/2005: use risk codes "M5" to "M7" as appropriate', 1995, 2004, 'UK Motor', 'UK Motor'),
			('MM', 'EU AND EEA MOTOR PHYSICAL DAM ONLY EXCL UK - Risk code retired with effect from 01/01/05: use risk code "MP"', 1998, 2004, 'Overseas Motor', 'Overseas Motor'),
			('MN', 'EU AND EEA THIRD PARTY LIAB ONLY EXCL UK - Risk code retired with effect from 01/01/05: use risk code "MP"', 1998, 2004, 'Overseas Motor', 'Overseas Motor'),
			('MP', 'EU AND EEA MOTOR PD AND TPL EXCL UK - From 01/01/05 also includes business previously coded "MM" and "MN"', 1998, 9999, 'Overseas Motor', 'Overseas Motor'),
			('N', 'LIVESTOCK', 1991, 9999, 'Livestock & Bloodstock', 'Property (D&F)'),
			('NA', 'NM GENERAL AND MISC LIABILITY ALL OTHER  EXCL USA - From 01/01/08 also includes business previously coded "PL"  ', 1991, 9999, 'NM General Liability (non-US direct)', 'Casualty'),
			('NB', 'BLOODSTOCK', 2001, 9999, 'Livestock & Bloodstock', 'Property (D&F)'),
			('NC', 'NM GENERAL AND MISC LIAB CLAIMS MADE EXCL USA - From 01/01/08 also includes business previously coded "PL" ', 1991, 9999, 'NM General Liability (non-US direct)', 'Casualty'),
			('NL', 'NUCLEAR LIABILITY', 1998, 9999, 'Nuclear', 'Property (D&F)'),
			('NP', 'NUCLEAR PROPERTY DAMAGE', 1998, 9999, 'Nuclear', 'Property (D&F)'),
			('NX', 'LIVESTOCK EXCESS OF LOSS', 1997, 9999, 'Livestock & Bloodstock', 'Property (D&F)'),
			('O', 'YACHTS INCL WAR EXCL WRO', 1991, 9999, 'Yacht', 'Marine'),
			('OX', 'XOL YACHTS INCL WAR EXCL WRO - Risk code retired with effect from 01/01/05: use risk code "TX"', 1992, 2004, 'Marine XL', 'Marine'),
			('P', 'MISCELLANEOUS PECUNIARY LOSS - From 01/01/05 also includes business previously coded "PE" "PP" "PS" and "PW"', 1991, 9999, 'Pecuniary', 'Accident & Health'),
			('P2', 'PHYS DAMAGE FOR PRIM LAYER PPTY IN USA EXCL BINDERS', 2004, 9999, 'Property D&F (US open market)', 'Property (D&F)'),
			('P3', 'PHYS DAMAGE FOR PRIM LAYER PPTY EXCL USA EXCL BINDERS', 2004, 9999, 'Property D&F (non-US open market)', 'Property (D&F)'),
			('P4', 'PHYS DAMAGE FOR FULL VALUE PPTY IN USA EXCL BINDERS', 2004, 9999, 'Property D&F (US open market)', 'Property (D&F)'),
			('P5', 'PHYS DAMAGE FOR FULL VALUE PPTY EXCL USA EXCL BINDERS', 2004, 9999, 'Property D&F (non-US open market)', 'Property (D&F)'),
			('P6', 'PHYS DAMAGE FOR XS LAYER PPTY IN USA EXCL BINDERS', 2004, 9999, 'Property D&F (US open market)', 'Property (D&F)'),
			('P7', 'PHYS DAMAGE FOR XS LAYER PPTY EXCL USA EXCL BINDERS', 2004, 9999, 'Property D&F (non-US open market)', 'Property (D&F)'),
			('PB', 'PRODUCT RECALL', 1999, 9999, 'Pecuniary', 'Accident & Health'),
			('PC', 'CANCELLATION AND ABANDONMENT', 1999, 9999, 'Contingency', 'Accident & Health'),
			('PD', 'ALL RISK PHYSICAL LOSS DAMAGE NO DIRECT PPNL RI - Risk code retired with effect from 01/01/2005: use risk codes "B2" to "B5" or "P2" to "P7" as appropriate', 1991, 2004, 'Property (direct & facultative)', 'Property (D&F)'),
			('PE', 'LIQUIDATED DAMAGES FORCE MAJEURE - Risk code retired with effect from 01/01/05: use risk code "P"', 1999, 2004, 'Pecuniary', 'Accident & Health'),
			('PF', 'FILM INCLUDING FILM COMPLETION BONDS  ', 1999, 9999, 'Contingency', 'Accident & Health'),
			('PG', 'OPERATIONAL POWER GENERATION TRANSMISSION AND UTILITIES EXCL CONSTRUCTION ', 2008, 9999, 'Power Generation', 'Property (D&F)'),
			('PI', 'E AND O OR PROFESSIONAL INDEM EXCL FINANCIAL INST. - Risk code retired with effect from 01/01/2005: use risk codes "E2" to "E9" as appropriate  ', 1991, 2004, 'Professional Indemnity', 'Casualty'),
			('PL', 'NM LEGAL LIABILITY FOR PROPERTY OWNERS INCL RETAIL/W''SALE OUTLETS AND ASSOCIATED MINOR PRODUCTS & COMPLETED RISKS - Risk code being retired with effect from 01/01/2008: use risk codes "NA" "NC" "UA" OR "UC" as appropriate', 1991, 2007, 'NM General Liability (non-US direct)', 'Casualty'),
			('PM', 'PROFESSIONAL INDEMNITY FOR FINANCIAL INSTITUTIONS - Risk code retired with effect from 01/01/2005: use risk codes "F2" or "F3" as appropriate  ', 2002, 2004, 'Professional Indemnity', 'Casualty'),
			('PN', 'NON APPEARANCE', 1999, 9999, 'Contingency', 'Accident & Health'),
			('PO', 'OVER REDEMPTION - Risk code retired with effect from 01/01/05: use risk code "PU"', 1999, 2004, 'Contingency', 'Accident & Health'),
			('PP', 'ESTATE PROTECTION - Risk code retired with effect from 01/01/05: use risk code "P"', 1991, 2004, 'Pecuniary', 'Accident & Health'),
			('PQ', 'ROADSIDE RESCUE     ', 2000, 9999, 'UK Motor', 'UK Motor'),
			('PR', 'POLITICAL RISK EXCL CONFISCATION VESSELS AIRCRAFT', 1991, 9999, 'Political Risks, Credit & Financial Guarantee', 'Marine'),
			('PS', 'PERSONAL STOP LOSS - Risk code retired with effect from 01/01/05: use risk code "P"', 1991, 2004, 'Pecuniary', 'Accident & Health'),
			('PU', 'MISCELLANEOUS CONTINGENCY - From 01/01/05 also includes business previously coded "PO"', 2001, 9999, 'Contingency', 'Accident & Health'),
			('PW', 'WEATHER INCLUDING PLUVIUS - Risk code retired with effect from 01/01/05: use risk code "PU"', 1999, 2004, 'Contingency', 'Accident & Health'),
			('PX', 'AVIATION OR AEROSPACE PRODUCTS LEGAL LIABILITY', 1992, 1996, 'Aviation Products/ Airport Liabilities', 'Aviation'),
			('PZ', 'PRIZE INDEMNITY INCLUDING HOLE IN ONE', 1999, 9999, 'Contingency', 'Accident & Health'),
			('Q', 'CARGO WAR AND OR CONFISCATION RISKS ONLY', 1991, 9999, 'Marine War', 'Marine'),
			('QL', 'WAR ON LAND  IRO GOODS IN TRANSIT - Risk code retired with effect from 01/01/05: use risk code "WL"', 1997, 2004, 'Terrorism', 'Property (D&F)'),
			('QX', 'XOL CARGO WAR AND OR CONFISCATION RISKS ONLY - Risk code retired with effect from 01/01/05: use risk code "WX"', 1992, 2004, 'Marine War', 'Marine'),
			('RX', 'XOL HULLS OF AIRCRAFT WAR AND OR CONFIS RISKS ONLY ', 1992, 9999, 'Aviation War', 'Aviation'),
			('SA', 'SEAFARERS ABANDONMENT (authorised syndicates only)', 2014, 9999, 'Political Risks, Credit & Financial Guarantee', 'Marine'),
			('SB', 'SURETY BOND REINSURANCE - From 01/01/05 also includes business previously coded "FC" or "FS" ', 1995, 9999, 'Political Risks, Credit & Financial Guarantee', 'Marine'),
			('SC', 'SPACE RISKS LAUNCH COMMISSIONING PERIOD AND TRANSPOND OP - From 01/01/08 also includes business previously coded "CX"', 1991, 9999, 'Space', 'Aviation'),
			('SL', 'SPACE RISK LIABILITY NO PRODUCTS LEGAL LIABILITY', 1991, 9999, 'Space', 'Aviation'),
			('SO', 'SPACE RISKS TRANSPONDER OPERATING', 1991, 9999, 'Space', 'Aviation'),
			('SR', 'AGG STOP LOSS AND XOL MARINE OUTWARD WHOLE ACCOUNT', 1991, 9999, 'Marine XL', 'Marine'),
			('SX', 'SPACE RISK LIABILITY EXCL AEROSPACE PRODUCTS', 1992, 1996, 'Space', 'Aviation'),
			('T', 'Vessels Excl. TLO IV LOH Containers Shipbuilding and WRO', 1991, 9999, 'Marine Hull', 'Marine'),
			('TC', 'COMMERCIAL RITC', 1997, 9999, 'RITC', 'Casualty'),
			('TE', 'MALICIOUS DAMAGE AND SABOTAGE - Risk code retired with effect from 01/01/2013: use risk codes "TO" "TU" "TW" or "WL"', 1991, 2012, 'Terrorism', 'Property (D&F)'),
			('TL', 'TEMPORARY LIFE AND PERMANENT HEALTH', 1991, 9999, 'Term Life', 'Life'),
			('TO', 'OVERSEAS STAND ALONE TERROR EXCL "1T" to "8T" & "1E" to "4E"', 1999, 9999, 'Terrorism', 'Property (D&F)'),
			('TR', 'ALL RISK PHYSICAL OR LOSS DAMAGE  DIRECT PPNL RI', 1991, 9999, 'Property pro rata', 'Property Treaty'),
			('TS', 'SHIPBUILDING EXCL ENERGY CONSTRUCTION', 2005, 9999, 'Marine Hull', 'Property (D&F)'),
			('TT', 'TITLE INSURANCE', 2015, 9999, 'Pecuniary', 'Accident & Health'),
			('TU', 'UK STAND ALONE TERRORISM WHICH IS NON POOL RE', 1999, 9999, 'Terrorism', 'Property (D&F)'),
			('TW', 'TERRORISM AND WAR ON LAND WHOLE ACCOUNT XOL TREATY RI INCL RI OF POOLS ', 2013, 9999, 'Terrorism', 'Property (D&F)'),
			('TX', 'XOL VESSELS SHIPBLDG ACV LOH INCL WAR EXCL WRO - From 01/01/05 also includes business previously coded "OX"', 1992, 9999, 'Marine XL', 'Marine'),
			('UA', 'NM GENERAL AND MISC LIABILITY ALL OTHER INCL USA - From 01/01/08 also includes business previously coded "PL" ', 1991, 9999, 'NM General Liability (US direct)', 'Casualty'),
			('UC', 'NM GENERAL AND MISC LIAB CLAIMS MADE INCL USA - From 01/01/08 also includes business previously coded "PL" ', 1991, 9999, 'NM General Liability (US direct)', 'Casualty'),
			('V', 'CARGO ALL RISKS INCL WAR EXCL WRO', 1991, 9999, 'Cargo', 'Marine'),
			('VL', 'LEGAL LIAB CARGO AND PROP INCL CCC OF ASSURED EXCL WRO', 1991, 9999, 'Cargo', 'Marine'),
			('VX', 'XOL Cargo Incl. War Excl. WRO', 1992, 9999, 'Marine XL', 'Marine'),
			('W', 'VESSELS WAR AND OR CONFISCATION EXCL BREACH VOYAGES', 1991, 9999, 'Marine War', 'Marine'),
			('W2', 'US WORKERS COMPENSATION - Risk code retired with effect from 01/01/2010: use risk codes "W5" or "W6" as appropriate', 2004, 2009, 'Employers Liability/ WCA (US)', 'Casualty Treaty'),
			('W3', 'UK EMPLOYERS LIABILITY', 2004, 9999, 'Employers Liability/ WCA (non-US)', 'Casualty'),
			('W4', 'INTL WORKERS COMP AND EMPLOYERS LIAB EXCL USA AND UK', 2004, 9999, 'Employers Liability/ WCA (non-US)', 'Casualty'),
			('W5', 'US WORKERS COMPENSATION PER PERSON EXPOSED', 2010, 9999, 'Employers Liability/ WCA (US)', 'Casualty Treaty'),
			('W6', 'US WORKERS COMPENSATION CATASTROPHE EXPOSED', 2010, 9999, 'Employers Liability/ WCA (US)', 'Casualty Treaty'),
			('WA', 'EXTENDED WARRANTY - From 01/01/05 also includes business previously coded "WS"', 1991, 9999, 'Extended Warranty', 'Property (D&F)'),
			('WB', 'VESSELS HULL WAR BREACH VOYAGES ONLY', 2005, 9999, 'Marine War', 'Marine'),
			('WC', 'WORKERS  COMPENSATION AND EMPLOYERS  LIABILITY - Risk code retired with effect from 01/01/2005: use risk codes "W2" to "W4" as appropriate  ', 1991, 2004, 'Employers Liability', 'Casualty'),
			('WL', 'WAR ON LAND - From 01/01/05 also includes business previously coded "QL"', 1997, 9999, 'Terrorism', 'Property (D&F)'),
			('WS', 'EXTENDED WARRANTY STOP LOSS - Risk code retired with effect from 01/01/05: use risk code "WA"', 1998, 2004, 'Extended Warranty', 'Property (D&F)'),
			('WX', 'XOL VESSELS  WAR AND OR CONFISCATION RISKS ONLY - From 01/01/05 also includes business previously coded "QX"', 1992, 9999, 'Marine War', 'Marine'),
			('X1', 'AVIATION EXCESS OF LOSS ON EXCESS OF LOSS - From 01/01/05 also includes business previously coded "XZ"', 1991, 9999, 'Aviation XL', 'Aviation'),
			('X2', 'MARINE XOL ON XOL INCL WAR', 1991, 9999, 'Marine XL', 'Marine'),
			('X3', 'NM PROP OR PECUNIARY LOSS XOL ON XOL RETROCESSION', 1991, 9999, 'Property Cat XL (Non-US)', 'Property Treaty'),
			('X4', 'NM LIABILITY EXCESS OF LOSS ON EXCESS OF LOSS - Risk code retired with effect from 01/01/05: use risk code "XL"', 1991, 2004, 'Casualty Treaty (non-US)', 'Casualty Treaty'),
			('X5', 'ENERGY ACCOUNT XOL ON XOL INCL WAR - Risk code retired with effect from 01/01/05: use risk code "XE"', 1991, 2004, 'Marine XL', 'Marine'),
			('XA', 'NM PROPERTY OR PECUNIARY LOSS WHOLE ACCOUNT XOL IN USA', 2008, 9999, 'Property Cat XL (US)', 'Property Treaty'),
			('XC', 'PER RISK EXCESS OF LOSS PROP PECUNIARY LOSS REINS', 1998, 9999, 'Property Risk XS', 'Property Treaty'),
			('XD', 'PER RISK EXCESS OF LOSS PROFESSIONAL INDEM REINS - Risk code retired with effect from 01/01/05: use risk code "XL"', 1998, 2004, 'Casualty Treaty (non-US)', 'Casualty Treaty'),
			('XE', 'ENERGY ACCOUNT XOL INCL WAR - From 01/01/05 also includes business previously coded "X5"', 1991, 9999, 'Marine XL', 'Marine'),
			('XF', 'NM LIABILITY EXCESS OF LOSS IN USA', 2010, 9999, 'Casualty Treaty (US)', 'Casualty Treaty'),
			('XG', 'NM LIABILITY EXCESS OF LOSS CLAIMS MADE OR LOSSES DISCOVERED EXCL USA ', 2010, 9999, 'Casualty Treaty (non-US)', 'Casualty Treaty'),
			('XH', 'NM LIABILITY EXCESS OF LOSS LOSSES OCCURRING EXCL USA ', 2012, 9999, 'Casualty Treaty (non-US)', 'Casualty Treaty'),
			('XJ', 'NM PROPERTY OR PECUNIARY LOSS WHOLE ACCOUNT XOL IN JAPAN ', 2008, 9999, 'Property Cat XL (Non-US)', 'Property Treaty'),
			('XL', 'NM LIABILITY EXCESS OF LOSS - Risk code retired with effect from 01/01/2010: use risk codes "XF" or "XG" as appropriate', 1991, 2009, 'Casualty Treaty (non-US)', 'Casualty Treaty'),
			('XM', 'MOTOR WHOLE ACCOUNT EXCESS OF LOSS ORIGINAL BUSINESS IN UK', 1991, 9999, 'Motor XL', 'Casualty Treaty'),
			('XN', 'MOTOR WHOLE ACCOUNT EXCESS OF LOSS ORIGINAL BUISNESS OUTSIDE UK', 2013, 9999, 'Motor XL', 'Casualty Treaty'),
			('XP', 'NM PROPERTY OR PECUNIARY LOSS WHOLE ACCOUNT XOL - Risk code being retired with effect from 01/01/2008: use risk codes "XA" "XU" "XJ" and "XR" ', 1991, 2007, 'Property Cat XL (Non-US)', 'Property Treaty'),
			('XR', 'NM PROPERTY OR PECUNIARY LOSS WHOLE ACCOUNT XOL IN REST OF WORLD ', 2008, 9999, 'Property Cat XL (Non-US)', 'Property Treaty'),
			('XT', 'MARINE WHOLE ACCOUNT XOL INCL WAR', 1991, 9999, 'Marine XL', 'Marine'),
			('XU', 'NM PROPERTY OR PECUNIARY LOSS WHOLE ACCOUNT XOL IN ALL OF EUROPE INCL UK', 2008, 9999, 'Property Cat XL (Non-US)', 'Property Treaty'),
			('XX', 'NON MARINE PROPERTY PECUNIARY LOSS LMX - Risk code retired with effect from 01/01/05: use risk codes "XC" "XP" or "X3" as appropriate', 1992, 2004, 'Property Cat XL (Non-US)', 'Property Treaty'),
			('XY', 'AVIATION WHOLE ACCOUNT XOL INCL WAR EXCL XOL ON XOL - From 01/01/05 also includes business previously coded "AR" and "AX" - From 01/01/08 also includes business previously coded "HX"', 1991, 9999, 'Aviation XL', 'Aviation'),
			('XZ', 'AVIATION XOL INCL XOL ON XOL AND WAR - Risk code retired with effect from 01/01/05: use risk code "X1"', 1991, 2004, 'Aviation XL', 'Aviation'),
			('Y1', 'AVIATION HULL AND LIAB PROPORT RI INCL WAR EXCL WRO', 1991, 2000, 'Airline/ General Aviation', 'Aviation'),
			('Y2', 'AVIATION HULL AND LIAB PROPORT RI INCL WAR EXCL WRO', 1991, 2000, 'Airline/ General Aviation', 'Aviation'),
			('Y3', 'AVIATION HULL AND LIAB PROPORT RI INCL WAR EXCL WRO', 1991, 2000, 'Airline/ General Aviation', 'Aviation'),
			('Y4', 'AVIATION HULL AND LIAB PROPORT RI INCL WAR EXCL WRO', 1991, 2000, 'Airline/ General Aviation', 'Aviation'),
			('Y5', 'AVIATION HULL AND LIAB PROPORT RI INCL WAR EXCL WRO', 1991, 2000, 'Airline/ General Aviation', 'Aviation'),
			('Y6', 'AVIATION HULL AND LIAB PROPORT RI INCL WAR EXCL WRO', 1991, 2000, 'Airline/ General Aviation', 'Aviation'),
			('Y7', 'AVIATION HULL AND LIAB PROPORT RI INCL WAR EXCL WRO', 1991, 2000, 'Airline/ General Aviation', 'Aviation'),
			('Y8', 'AVIATION HULL AND LIAB PROPORT RI INCL WAR EXCL WRO', 1991, 2000, 'Airline/ General Aviation', 'Aviation'),
			('Y9', 'AVIATION HULL AND LIAB PROPORT RI INCL WAR EXCL WRO', 1991, 2000, 'Airline/ General Aviation', 'Aviation'),
			('ZX', 'SPACE RISKS TRANSPONDER OPERATING', 1992, 1996, 'Space', 'Aviation')
		) p ([Code], [Description], [StartYear], [EndYear], [Section], [Type])

INSERT INTO [RiskType] ([Type]) SELECT DISTINCT [Type] FROM @Lloyds

INSERT INTO [RiskCategory] ([Type], [Category]) SELECT DISTINCT [Type], [Category] FROM @Lloyds

INSERT INTO [RiskCode] ([Type], [Category], [Id], [Description], [InceptionDate], [ExpiryDate])
SELECT [Type], [Category], [Code], [Description],
	CONVERT(DATE, CONVERT(NCHAR(4), [InceptionDate]) + N'-01-01'),
	CONVERT(DATE, CONVERT(NCHAR(4), NULLIF([ExpiryDate], 9999)) + N'-01-01')
FROM @Lloyds
GO

CREATE TABLE [Binder] (
		[Id] INT NOT NULL IDENTITY (1, 1),
		[UMR] NVARCHAR(255) NOT NULL,
		[AgreementNumber] NVARCHAR(255) NULL,
		[LloydsBrokerId] INT NOT NULL,
		[CoverholderId] INT NOT NULL,
		[LeadId] INT NULL,
		[SecondId] INT NULL,
		[InceptionDate] DATE NOT NULL,
		[ExpiryDate] DATE NOT NULL,
		[RisksTerritoryId] INT NOT NULL,
		[InsuredsTerritoryId] INT NOT NULL,
		[LimitsTerritoryId] INT NOT NULL,
		[CreatedWhen] DATETIMEOFFSET NOT NULL CONSTRAINT [DF_Binder_CreatedWhen] DEFAULT (GETUTCDATE()),
		[CreatedByWhom] NVARCHAR(255) NOT NULL,
		[UpdatedWhen] DATETIMEOFFSET NOT NULL CONSTRAINT [DF_Binder_UpdatedWhen] DEFAULT (GETUTCDATE()),
		[UpdatedByWhom] NVARCHAR(255) NOT NULL,
		CONSTRAINT [PK_Binder] PRIMARY KEY CLUSTERED ([Id]),
		CONSTRAINT [UQ_Binder_UMR] UNIQUE ([UMR]),
		CONSTRAINT [UQ_Binder_LeadId] UNIQUE ([Id], [LeadId]),
		CONSTRAINT [FK_Binder_Company_LloydsBrokerId] FOREIGN KEY ([LloydsBrokerId]) REFERENCES [Company] ([Id]),
		CONSTRAINT [FK_Binder_Company_CoverholderId] FOREIGN KEY ([CoverholderId]) REFERENCES [Company] ([Id]),
		CONSTRAINT [FK_Binder_Territory_RisksTerritoryId] FOREIGN KEY ([RisksTerritoryId]) REFERENCES [Territory] ([Id]),
		CONSTRAINT [FK_Binder_Territory_InsuredsTerritoryId] FOREIGN KEY ([RisksTerritoryId]) REFERENCES [Territory] ([Id]),
		CONSTRAINT [FK_Binder_Territory_LimitsTerritoryId] FOREIGN KEY ([RisksTerritoryId]) REFERENCES [Territory] ([Id]),
		CONSTRAINT [CK_Binder_ExpiryDate] CHECK ([ExpiryDate] >= [InceptionDate]),
		CONSTRAINT [CK_Binder_UpdatedWhen] CHECK ([UpdatedWhen] >= [CreatedWhen])
	)
GO

CREATE TABLE [BinderUnderwriter] (
		[BinderId] INT NOT NULL,
		[UnderwriterId] INT NOT NULL,
		CONSTRAINT [PK_BinderUnderwriter] PRIMARY KEY CLUSTERED ([BinderId], [UnderwriterId]),
		CONSTRAINT [FK_BinderUnderwriter_Binder] FOREIGN KEY ([BinderId]) REFERENCES [Binder] ([Id]),
		CONSTRAINT [FK_BinderUnderwriter_Company] FOREIGN KEY ([UnderwriterId]) REFERENCES [Company] ([Id])
	)
GO

ALTER TABLE [Binder] ADD
	CONSTRAINT [FK_Binder_BinderUnderwriter_LeadId] FOREIGN KEY ([Id], [LeadId]) REFERENCES [BinderUnderwriter] ([BinderId], [UnderwriterId]),
	CONSTRAINT [FK_Binder_BinderUnderwriter_SecondId] FOREIGN KEY ([Id], [SecondId]) REFERENCES [BinderUnderwriter] ([BinderId], [UnderwriterId])
GO

CREATE TABLE [BinderSection] (
		[BinderId] INT NOT NULL,
		[Id] INT NOT NULL IDENTITY (1, 1),
		[RiskCodeId] NVARCHAR(5) NOT NULL,
		CONSTRAINT [PK_BinderSection] PRIMARY KEY CLUSTERED ([BinderId], [Id]),
		CONSTRAINT [FK_BinderSection_Binder] FOREIGN KEY ([BinderId]) REFERENCES [Binder] ([Id]),
		CONSTRAINT [FK_BinderSection_RiskCode] FOREIGN KEY ([RiskCodeId]) REFERENCES [RiskCode] ([Id])
	)
GO

CREATE TABLE [BinderSectionUnderwriter] (
		[BinderId] INT NOT NULL,
		[SectionId] INT NOT NULL,
		[UnderwriterId] INT NOT NULL,
		[Percentage] DECIMAL(5, 4) NULL,
		CONSTRAINT [PK_BinderSectionUnderwriter] PRIMARY KEY CLUSTERED ([BinderId], [SectionId], [UnderwriterId]),
		CONSTRAINT [FK_BinderSectionUnderwriter_BinderSection] FOREIGN KEY ([BinderId], [SectionId]) REFERENCES [BinderSection] ([BinderId], [Id]),
		CONSTRAINT [FK_BinderSectionUnderwriter_BinderUnderwriter] FOREIGN KEY ([BinderId], [UnderwriterId]) REFERENCES [BinderUnderwriter] ([BinderId], [UnderwriterId])
	)
GO

CREATE TABLE [Programme] (
		[Id] INT NOT NULL IDENTITY (1, 1),
		[Name] NVARCHAR(255) NOT NULL,
		[TPAId] INT NOT NULL,
		[UnderwriterId] INT NOT NULL,
		[InceptionDate] DATE NOT NULL,
		[ExpiryDate] DATE NOT NULL,
		[BinderFilter] BIT NULL,
		[RiskCodeFilter] BIT NULL,
		[CreatedWhen] DATETIMEOFFSET NOT NULL CONSTRAINT [DF_Programme_CreatedWhen] DEFAULT (GETUTCDATE()),
		[CreatedByWhom] NVARCHAR(255) NOT NULL,
		[UpdatedWhen] DATETIMEOFFSET NOT NULL CONSTRAINT [DF_Programme_UpdatedWhen] DEFAULT (GETUTCDATE()),
		[UpdatedByWhom] NVARCHAR(255) NOT NULL,
		CONSTRAINT [PK_Programme] PRIMARY KEY NONCLUSTERED ([Id]),
		CONSTRAINT [UQ_Programme_Name] UNIQUE CLUSTERED ([TPAId], [Name]),
		CONSTRAINT [UQ_Programme_UnderwriterId] UNIQUE ([Id], [UnderwriterId]),
		CONSTRAINT [UQ_Programme_BinderFilter] UNIQUE ([Id], [BinderFilter]),
		CONSTRAINT [UQ_Programme_RiskCodeFilter] UNIQUE ([Id], [RiskCodeFilter]),
		CONSTRAINT [FK_Programme_Company_TPAId] FOREIGN KEY ([TPAId]) REFERENCES [Company] ([Id]),
		CONSTRAINT [FK_Programme_Company_UnderwriterId] FOREIGN KEY ([UnderwriterId]) REFERENCES [Company] ([Id]),
		CONSTRAINT [CK_Programme_ExpiryDate] CHECK ([ExpiryDate] >= [InceptionDate]),
		CONSTRAINT [CK_Programme_UpdatedWhen] CHECK ([UpdatedWhen] >= [CreatedWhen])
	)
GO

CREATE TABLE [ProgrammeBinder] (
		[ProgrammeId] INT NOT NULL,
		[UnderwriterId] INT NOT NULL,
		[BinderFilter] BIT NOT NULL,
		[BinderId] INT NOT NULL,
		[SectionFilter] BIT NULL,
		CONSTRAINT [PK_ProgrammeBinder] PRIMARY KEY CLUSTERED ([ProgrammeId], [BinderId]),
		CONSTRAINT [UQ_ProgrammeBinder_SectionFilter] UNIQUE ([ProgrammeId], [BinderId], [SectionFilter]),
		CONSTRAINT [FK_ProgrammeBinder_Programme_UnderwriterId] FOREIGN KEY ([ProgrammeId], [UnderwriterId]) REFERENCES [Programme] ([Id], [UnderwriterId]),
		CONSTRAINT [FK_ProgrammeBinder_Programme_BinderFilter] FOREIGN KEY ([ProgrammeId], [BinderFilter])
			REFERENCES [Programme] ([Id], [BinderFilter]) ON UPDATE CASCADE,
		CONSTRAINT [FK_ProgrammeBinder_Binder] FOREIGN KEY ([BinderId], [UnderwriterId]) REFERENCES [Binder] ([Id], [LeadId])
	)
GO

CREATE TABLE [ProgrammeBinderSection] (
		[ProgrammeId] INT NOT NULL,
		[BinderId] INT NOT NULL,
		[SectionFilter] BIT NOT NULL,
		[SectionId] INT NOT NULL,
		CONSTRAINT [PK_ProgrammeBinderSection] PRIMARY KEY CLUSTERED ([ProgrammeId], [BinderId], [SectionId]),
		CONSTRAINT [FK_ProgrammeBinderSection_ProgrammeBinder] FOREIGN KEY ([ProgrammeId], [BinderId], [SectionFilter])
			REFERENCES [ProgrammeBinder] ([ProgrammeId], [BinderId], [SectionFilter]) ON UPDATE CASCADE,
		CONSTRAINT [FK_ProgrammeBinderSection_BinderSection] FOREIGN KEY ([BinderId], [SectionId]) REFERENCES [BinderSection] ([BinderId], [Id])
	)
GO

CREATE TABLE [ProgrammeRiskCode] (
		[ProgrammeId] INT NOT NULL,
		[RiskCodeFilter] BIT NOT NULL,
		[RiskCodeId] NVARCHAR(5) NOT NULL,
		CONSTRAINT [PK_ProgrammeRiskCode] PRIMARY KEY CLUSTERED ([ProgrammeId], [RiskCodeId]),
		CONSTRAINT [FK_ProgrammeRiskCode_Programme] FOREIGN KEY ([ProgrammeId], [RiskCodeFilter])
		 REFERENCES [Programme] ([Id], [RiskCodeFilter]) ON UPDATE CASCADE,
		CONSTRAINT [FK_ProgrammeRiskCode_RiskCode] FOREIGN KEY ([RiskCodeId]) REFERENCES [RiskCode] ([Id])
	)
GO