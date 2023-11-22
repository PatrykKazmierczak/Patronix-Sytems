<#"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
       Function:                Get-ScriptDirectory
       Purpose:                 Gets the current directory for the script
       Last Update /by:    		23/03/2023 Massimiliano Ferrazzi
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
	"Can"t find the ActiveDirectory module, please insure it"s installed.`n"
	}
ELSE {Import-Module ActiveDirectory}

$CHECK2 = Get-Module SQLPS
IF(!$CHECK2) {
	Write-Host -ForegroundColor Red `
	"Can"t find the SQLPS module, please insure it"s installed.`n"
	}
ELSE {Import-Module SQLPS}

##########################################
##### Fixed Variables ####################
##########################################
$logFile = "C:\scripts\AD2SQLComputers-log.txt"
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
$TABLE = "tbl.AllADComputers" #	[AD2SQL_Data_TEST].[dbo].[ADExport]

<#Table Create String ---- MIRAR AIXO, ACTUALIZAR AMB LA V 2#>

$CREATE = "CREATE TABLE $TABLE (ComputerName varchar(150) not null PRIMARY KEY,`
	FQDN nvarchar(max),`
	Description nvarchar(max),`
	Enabled varchar(max),`
	OS nvarchar(max),`
	ServicePack nvarchar(max),`
	OS_Version varchar(max),`
	userAccountControl nvarchar(max),`
	PasswordLastSet datetime,`
	whenCreated datetime,`
	whenChanged datetime,`
	LastLogonTimestampDT nvarchar(max),`
	Owner nvarchar(max),`
	CanonicalName nvarchar(max),`
	DistinguishedName nvarchar(max))"

# The full-featured query
$ADObjects = Get-ADComputer -Filter * -Properties * |

    Select-Object Name, DNSHostName, Description, Enabled, OperatingSystem, `
        OperatingSystemServicePack, OperatingSystemVersion, Location, userAccountControl, PasswordLastSet, `
        whenCreated, whenChanged, `
        @{name="LastLogonTimestampDT";`
            Expression={[datetime]::FromFileTimeUTC($_.LastLogonTimestamp)}}, 
            ManagedBy,`
        @{name="Owner";`
            Expression={$_.nTSecurityDescriptor.Owner}}, `
        CanonicalName, DistinguishedName

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
ForEach($OBJECT in $ADObjects){
	
	$1  = $OBJECT.Name
	$2  = $OBJECT.DNSHostName
    $3  = $OBJECT.Description
    $4  = $OBJECT.Enabled
    $5  = $OBJECT.OperatingSystem
    $6  = $OBJECT.OperatingSystemServicePack
    $7  = $OBJECT.OperatingSystemVersi
    $8  = $OBJECT.userAccountControl
    $9  = $OBJECT.PasswordLastSet
    $10 = $OBJECT.whenCreated
    $11 = $OBJECT.whenChanged
    $12 = $OBJECT.LastLogonTimestampDT 
    $13 = $OBJECT.Owner
    $14 = $OBJECT.CanonicalName
    $15 = $OBJECT.DistinguishedName
    

# removing ' from descritpion to avoid errors
if ($3 -ne $null)
{
$3 = $3.Replace("'","")
}				
#Any Table Data to be written goes here:
	$INSERT = "INSERT $TABLE VALUES ('$1','$2','$3','$4','$5','$6','$7','$8','$9','$10','$11','$12','$13','$14','$15')"
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
Send-MailMessage -To $emailto -From "$emailfrom" -Subject "ITOA: Loading AD Computers to SRV-AD-POLSKA\SQLEXPRESS01" -Attachments $logFile

