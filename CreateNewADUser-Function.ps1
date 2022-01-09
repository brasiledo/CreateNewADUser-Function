  <# 
.SYNOPSIS
Powershell function that creates Active Directory user account with information entered in by the admin.

This script is intended to be used as the only way to create AD Users, 
when coupled with an additional script set up as a scheduled task, that will search ad users employee numbers against the existing list, 
disable any rogue accounts (that are not in list).  

The script will require a csv with existing AD users and employee numbers -- $PATH var

 
.DESCRIPTION
-This will create a user in Active Directory automatically with Powershell.  
-The accounts are created disabled and added to set OU -> $userOU
-Password is set to a standard password defined in this script --> $Password
-Checks and appends duplicate names
-Checks from an existing list of AD users and Employee Numbers, appends the last employee number, finally, exports (FirstName, Lastname, Username, and Employee Number) to csv

 

This powershell function accepts user inputs as parameters which allows you to mass-add users.
Additional optional Attributes:
Description
Organization
Office
OfficePhone
Title
Manager
 
i.e. importing from a csv  -- 
. .\CreateNewADUser-Function.ps1
Import-csv .\newusers.csv | % { create-newuser -firstname $_.firstname -lastname $_.lastname -organization $_.organization...}
 
.NOTES
Name: CreateNewADUser-Function.ps1
Version: 1.0
Author: Brasiledo
Date of last revision: 1/5/2022

#>

#Requires -Module ActiveDirectory

#Add in any attributes you want to; add Mandatory if required

function Create-NewUser {
[cmdletbinding()]

param (
[parameter(Mandatory=$true,position=0,ValueFromPipeLineByPropertyName,helpmessage="enter valid employee USERNAME")]
[string] $Firstname,
[parameter(Mandatory=$true,position=1,ValueFromPipeLineByPropertyName)]
[string] $Lastname,
[parameter(ValueFromPipeLineByPropertyName)]
[string] $Email,
[parameter(ValueFromPipeLineByPropertyName)]
[string] $Description,
[parameter(ValueFromPipeLineByPropertyName)]
[INT] $officePhone,
[parameter(ValueFromPipeLineByPropertyName)]
[string] $Organization,
[parameter(ValueFromPipeLineByPropertyName)]
[string] $Department,
[parameter(ValueFromPipeLineByPropertyName)]
[string] $title,
[parameter(ValueFromPipeLineByPropertyName,helpmessage="enter employee by username")]
[validatescript({try{if(get-aduser $_){$true}}catch{throw "$_ doesn't exist"}})]
[object] $manager

)

Begin {
#Edit Below
$password='P@ssword101'
$userOU='OU=Automation,DC=domain,DC=local'
$UPN=$firstname+'.'+$lastname+'@domain.local'
$path=".\users.csv"

#DO NOT edit below
$SAM=$firstname.substring(0,1)+$lastname
$name="$firstname $lastname"

#Generate New Employee Number
$import=import-csv $path | select -Last 1
foreach ($item in $import.employeenumber) {
[int32]$employeenum=$item
$employeenum++
}
#Check if user exists and append logon name 
$inc=0
$username=$sam
$UPN2=$UPN
$cn=$name
if (get-aduser -filter * | ?{$_.samAccountName -eq $sam}) {
do {
$inc++
$username=$sam + $inc  
$Upn2=$UPN + $INC
$CN=$Name+'_'+$INC 
    }Until (-not (Get-aduser -filter {Samaccountname -eq $username}))
}
}
Process {

#Create new account with info inputted
$NewUser= New-ADUser -Name $CN -displayname $name -GivenName $firstname -Surname $lastname -SamAccountName $username -userprincipalname $UPN2 -AccountPassword (ConvertTo-securestring -Asplaintext "$password" -force) -ChangePasswordAtLogon $true -employeeNumber $employeenum -Path $userOU
set-aduser $username -ChangePasswordAtLogon $true 

#Captures only invoked optional parameters [removes mandatory Firstname,Lastname] and applies to user
switch(@($psboundparameters.KEYS)){
    {$_ -in @("firstname","lastname")}{

$psboundparameters.remove($_) | out-null

}

}

#Export info to user CSV (Firstname,Lastname,Username,Employeenumber)
set-aduser $username @PSBoundParameters
$newline="{0},{1},{2},{3}" -f $firstname,$Lastname,$username,$employeenum
$newline | Add-Content -Path $path
}
}
