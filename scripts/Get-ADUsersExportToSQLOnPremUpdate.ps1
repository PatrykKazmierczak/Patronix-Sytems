<#"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
       Function:                  Get-ScriptDirectory
       Purpose:                   Gets the current directory for the script
       Last Update /by:    		  23/03/2023 Massimiliano Ferrazzi

                                         PRD
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""#>
Function Get-ScriptDirectory
{
       $Invocation = (Get-Variable MyInvocation -Scope 1).Value
       [string]$path = Split-Path $Invocation.MyCommand.Path
       if (! $path.EndsWith("\"))
       {
              $path += "\"
       }
       return $path
}

########################################
$CHECK = Get-Module ActiveDirectory
IF(!$CHECK) {
	Write-Host -ForegroundColor Red `
	"Can"t find the ActiveDirectory module, please ensure it"s installed.`n"
	}
ELSE {Import-Module ActiveDirectory}

$CHECK2 = Get-Module SQLPS
IF(!$CHECK2) {
	Write-Host -ForegroundColor Red `
	"Can"t find the SQLPS module, please ensure it"s installed.`n"
	}
ELSE {Import-Module SQLPS}

##########################################
##### Fixed Variables ####################
##########################################
$logFile = "C:\scripts\AD2SQLUsers-log.txt"
$ScriptPath = Get-ScriptDirectory
# Generic variables
$Date = get-date -f dd-MM-yyyy
$Hour = get-date -f hh:mm:ss

$log = "==============================================================="  > $logFile
$Log = $env:USERNAME + " has Started the script at $Date $Hour" >> $logFile
$log = "==============================================================="  >> $logFile
$log = "Script Location = $ScriptPath at $env:COMPUTERNAME"  >> $logFile
$log = "==============================================================="  >> $logFile
<#DataBase Name:#>
$DB = "ITOA"

<#SQL Server Name:#>
$SQLSRVR = "SRV-AD-POLSKA\SQLEXPRESS01"

<#Table to Create:#>
$TABLE = "tbl.AllADUsers" #	[AD2SQL_Data_TEST].[dbo].[ADExport]

<#Table Create String ---- MIRAR AIXO, ACTUALIZAR AMB LA V 2#>

$CREATE = "CREATE TABLE $TABLE (SamAccountName varchar(150) not null PRIMARY KEY, `
	UserPrincipalName varchar(max),`
    DisplayName varchar(max),`
    givenName nvarchar (max),`
    Surname nvarchar (max),`
    Title nvarchar (max),`
    Description nvarchar(max), `
    Department nvarchar(max),`
    company nvarchar(max),`
    Office nvarchar(max),`
    Manager nvarchar(max),`
    ManagerUPN nvarchar(max),`
    StreetAddress nvarchar(max),`
    City nvarchar(max),`
    State nvarchar(max),`
    postalCode nvarchar(max),`
    CountryCode nvarchar(max),`
    Country nvarchar(max),`
    EmailAddress nvarchar(max),`
    OfficePhone nvarchar(max),`
    HomePhone nvarchar(max),`
    Mobile nvarchar(max),`
    FAX nvarchar(max),`
    EmployeeID nvarchar(max),`
    EmployeeNumber nvarchar(max),`
    HomeDirectory nvarchar(max),`
    HomeDrive nvarchar(max),`
    WhenCreated datetime,`
    WhenChanged datetime,`
    LastLogonDate datetime,`
    LastBadPasswordAttempt datetime,`
    PasswordLastSet datetime,`
    PasswordExpired nvarchar(max),`
    PasswordNeverExpires nvarchar(max),`
    Enabled nvarchar(max),`
    DistinguishedName nvarchar(max),`
    CanonicaName nvarchar(max))"

# The full-featured query
# Use the Get-ADUser cmdlet to retrieve all Active Directory users
$users = Get-ADUser -Filter * -Properties *

# Create an array to store the results
$results = @()

# Iterate over each user and retrieve the manager
foreach ($user in $users) {
    # Retrieve the DistinguishedName of the manager property from the user object
    $managerDN = $user.Manager

    # If the user has a manager, retrieve the manager object and add their name and userPrincipalName to the results array
    if ($managerDN) {
        $manager = Get-ADUser -Identity $managerDN
        $result = [PSCustomObject] @{
            UserName = $user.Name
            SamAccountName = $user.SamAccountName
            UserPrincipalName = $user.UserPrincipalName
            DisplayName = $user.DisplayName
            Name = $User.GivenName
            Surname = $user.sn
            Title = $user.title
            Description = $user.description
            Department = $user.department
            Company = $user.company
            Office = $user.Office
            ManagerName = $manager.Name
            ManagerUPN = $manager.UserPrincipalName
            streetAddress = $user.streetAddress
            City = $user.City
            State = $user.State
            PostalCode = $user.PostalCode
            CountryCode =$user.countryCode
            Country = $user.Country
            EmailAddress = $user.EmailAddress
            OfficePhone = $user.OfficePhone
            HomePhone = $user.HomePhone
            Mobile = $user.Mobile
            FAX = $user.FAX
            EmployeeID = $user.EmployeeID
            EmployeeNumber = $user.EmployeeNumber
            HomeDirectory = $user.HomeDirectory
            HomeDrive = $user.HomeDrive
            whenCreated = $user.whenCreated
            whenChanged = $user.whenChanged
            LastBadPasswordAttempt = $user.LastBadPasswordAttempt
            LastLogonDate = $user.LastLogonDate
            PasswordLastSet = $user.PasswordLastSet
            PasswordExpired = $user.PasswordExpired
            PasswordNeverExpires = $user.PasswordNeverExpires
            Enabled = $user.Enabled
            DistinguishedName = $user.DistinguishedName
            CanonicalName = $user.CanonicalName
            AccountExpirationDate = $user.AccountExpirationDate          
        }
        $results += $result
    } else {
        $result = [PSCustomObject] @{
            UserName = $user.Name
            SamAccountName = $user.SamAccountName
            UserPrincipalName = $user.UserPrincipalName
            DisplayName = $user.DisplayName
            Name = $User.GivenName
            Surname = $user.sn
            Title = $user.title
            Description = $user.description
            Department = $user.department
            Company = $user.company
            Office = $user.Office
            ManagerName = "No Manager"
            ManagerUPN = "No Manager"
            streetAddress = $user.streetAddress
            City = $user.City
            State = $user.State
            PostalCode = $user.PostalCode
            CountryCode =$user.countryCode
            Country = $user.Country
            EmailAddress = $user.EmailAddress
            OfficePhone = $user.OfficePhone
            HomePhone = $user.HomePhone
            Mobile = $user.Mobile
            FAX = $user.FAX
            EmployeeID = $user.EmployeeID
            EmployeeNumber = $user.EmployeeNumber
            HomeDirectory = $user.HomeDirectory
            HomeDrive = $user.HomeDrive
            whenCreated = $user.whenCreated
            whenChanged = $user.whenChanged
            LastBadPasswordAttempt = $user.LastBadPasswordAttempt
            LastLogonDate = $user.LastLogonDate
            PasswordLastSet = $user.PasswordLastSet
            PasswordExpired = $user.PasswordExpired
            PasswordNeverExpires = $user.PasswordNeverExpires
            Enabled = $user.Enabled
            DistinguishedName = $user.DistinguishedName
            CanonicalName = $user.CanonicalName
            AccountExpirationDate = $user.AccountExpirationDate
        }
        $results += $result
    }
}


<#Connect and cleanup the AD table
	Connection remains open for writting#>
$SQLCON = New-Object System.Data.SqlClient.SqlConnection("Data Source=$SQLSRVR; `
			Initial Catalog=$DB;Integrated Security=SSPI")
	$SQLCON.open()
		$SQL = $SQLCON.CreateCommand() 

	$SQL.CommandText ="DROP TABLE $TABLE"
#############################################
# Try and Catch error for SQL execute Command#
##############################################
    Try{
        $ErrorActionPreference = "Stop";
        $exec = $SQL.ExecuteNonQuery() > $null
    }Catch{
        $ErrorMessage = $_.Exception.Message
        Write-Output "Error : $ErrorMessage For Command " $SQL.CommandText >> $logFile

    }Finally{$ErrorActionPreference = "Continue";}	
				
		$SQL.CommandText = $CREATE
##############################################
# Try and Catch error for SQL execute Command#
##############################################
    Try{
        $ErrorActionPreference = "Stop";
        $exec = $SQL.ExecuteNonQuery() > $null
    }Catch{
        $ErrorMessage = $_.Exception.Message
        Write-Output "Error : $ErrorMessage For Command " $SQL.CommandText >> $logFile

    }Finally{$ErrorActionPreference = "Continue";}	


<#Begin loop through the ADARRAY for
	Variables and begin inserting Rows to table#>
	$X = 0
ForEach($result in $results){
	
    $1  = $Result.samAccountName
	$2  = $Result.UserPrincipalName
    $3  = $Result.DisplayName
    $4  = $Result.givenName
    $5  = $Result.Surname
    $6  = $Result.Title
    $7  = $Result.Description
    $8  = $Result.Department
    $9  = $Result.Company
    $10 = $Result.Office
    $11 = $Result.Manager
    $12 = $Result.ManagerUPN
	$13 = $Result.StreetAddress
    $14 = $Result.City 
    $15 = $Result.State
    $16 = $Result.PostalCode
    $17 = $Result.CountryCode
    $18	= $Result.Country
    $19 = $Result.EmailAddress
    $20 = $Result.OfficePhone
    $21 = $Result.HomePhone
    $22 = $Result.Mobile
    $23 = $Result.FAX
    $24 = $Result.EmployeeID
    $25 = $Result.EmployeeNumber
    $26 = $Result.HomeDirectory
    $27 = $Result.HomeDrive
    $28 = $Result.whenCreated
    $29 = $Result.whenChanged
    $30 = $Result.LastBadPasswordAttempt
    $31 = $Result.LastLogonDate
    $32 = $Result.PasswordLastSet
    $33 = $Result.PasswordExpired
    $34 = $Result.PasswordNeverExpires
    $35 = $Result.Enabled
    $36 = $Result.DistinguishedName
    $37 = $Result.CanonicalName
    
    

# removing ' from descritpion to avoid errors
if ($3 -ne $null)
{
$3 = $3.Replace("'","")
}				
#Any Table Data to be written goes here:
	$INSERT = "INSERT $TABLE VALUES ('$1','$2','$3','$4','$5','$6','$7','$8','$9','$10','$11','$12','$13','$14','$15','$16','$17','$18','$19','$20','$21','$22','$23','$24','$25','$26','$27','$28','$29','$30','$31','$32','$33','$34','$35','$36','$37')"
	$SQL.CommandText = $INSERT

##############################################
# Try and Catch error for SQL execute Command#
##############################################
    Try{
        $ErrorActionPreference = "Stop";
        $exec = $SQL.ExecuteNonQuery() > $null
    }Catch{
        $ErrorMessage = $_.Exception.Message
        Write-Output "Error : $ErrorMessage For Command " $SQL.CommandText >> $logFile

    }Finally{$ErrorActionPreference = "Continue";}		

$X = $X + 1			
}

$Res = "$X Records were written to $TABLE in database $DB"  >> $logFile
<#Cleanup variables and close connections#>
$SQLCON.Close()

###############################################################################

$PSEmailServer = "compinfainsa-com.mail.protection.outlook.com"         # mail server name
$smtpPort = 25
$emailfrom = "itoa@compinfainsa.com"   # doesn't have to be real email, just in the form name@domain.ext
$emailto = "mferrazzi@compinfainsa.com"    

# email report file
Send-MailMessage -To $emailto -From "$emailfrom" -Subject "ITOA: Loading AD Users to SRV-AD-POLSKA\SQLEXPRESS01" -Attachments $logFile