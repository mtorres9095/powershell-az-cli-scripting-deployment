# TODO: set variables
$studentName = "Miguel"
$rgName = 'MiguelCh9-Stu2-rg'
$vmName = 'MiguelCh9-Stu2-vm'
$vmSize = 'Standard_B2s'
$vmImage = $(az vm image list --query "[? contains(urn, 'Ubuntu')] | [0].urn" -o tsv)
$vmAdminUsername = "student"
$kvName = "Miguel-lc0821-ps-kv"
$kvSecretName = "ConnectionStrings--Default"
$kvSecretValue = "server=localhost;port=3306;database=coding_events;user=coding_events;password=launchcode"
# vmid="$(az vm show --query "identity.principalId" -o tsv)"

# TODO: provision RG
az group create -n $rgName
az configure --default group=$rgName

# TODO: provision VM

az vm create -n "$vmName" --size "$vmSize" --image "$vmImage" --admin-username "student" --admin-password "LaunchCode-@zure1" --authentication-type password --assign-identity | set-content VM.json
az configure --default vm="$vmName"

# TODO: capture the VM systemAssignedIdentity

$Vm=get-content VM.json | ConvertFrom-Json

# TODO: open vm port 443
az vm open-port --port 443

# provision KV

az keyvault create -n $kvName --enable-soft-delete false --enabled-for-deployment true


# create KV secret (database connection string)

az keyvault secret set --vault-name $kvName --description 'connection string' --name $kvSecretName --value $kvSecretValue


# set KV access-policy (using the vm ``systemAssignedIdentity``)

az keyvault set-policy --name $kvName --object-id "$Vm.identity.systemAssignedIdentity" --secret-permissions list get 

# az keyvault set-policy --name $kvName --object-id $vmid --secret permission list get 
# Old one error: az keyvault set policy (object-id expected one argument)

az vm run-command invoke --command-id RunShellScript --scripts @vm-configuration-scripts/1configure-vm.sh

az vm run-command invoke --command-id RunShellScript --scripts @vm-configuration-scripts/2configure-ssl.sh

az vm run-command invoke --command-id RunShellScript --scripts @deliver-deploy.sh


# TODO: print VM public IP address to STDOUT or save it as a file

Write-Output "$Vm.publicIpAddress"

#Write-Output "VM available at $vm_ip" -- Old one



# 101719Aug2020: Changed sinlge quaotes to variables, not all. Put quotes on vm variables, all.
# 101824Aug2020: Added comments to VM and "access policy"
# errors; 1: name id required, 3: (--name | --ids) are required
# 111018Aug2020: errors: (--name | --ids) are required (1 ea) ; az keyvault set policy (object-id expected one argument)
# more: (--name | --ids) are required (3 ea)
# 111100Aug2020: error: object-id : Changed $vmid, added -o tsv at the end Before running
# 111207Aug2020: errors: no access to RG, object Id (changed to JSON). Running again. 
#52.152.171.146
