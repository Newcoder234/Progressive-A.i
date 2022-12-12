@echo off

param (
    [string] $resourceGroupName,
    [string] $tagId, 
    [string] $deploymentId
)

$projectTags = New-Object 'System.Collections.Generic.Dictionary[String,String]'
$projectTags.Add($tagId, $deploymentId)

function UpdateLoop
{
    param( [int]$maxIterations, $resource )

    $success = $false
    $iterator = 1

    while( ($success -eq $false) -and ($iterator -le $maxIterations))
    {
        try 
        {
            if($resource.type -eq "Microsoft.MachineLearningServices/workspaces")
            {
                Set-AzResource -ResourceId $resource.Id -Tag $resource.Tags -ApiVersion 2019-06-01 -Force
            }
            else
            {
                Set-AzResource -ResourceId $resource.Id -Tag $resource.Tags -Force
            }

            $success = $true
            break
        }
        catch 
        {
            Write-Host("Failed to write resource update - ")
            Write-Host($_.Exception.Message)
            Start-Sleep -Seconds 5
        }
    }

    if($success -eq $false)
    {
        throw "Failed to update resources"
    }
}


function Update-GroupResources 
{
    param( [string]$resGroup, $tags )
    Write-Host("*************** Updating resources in " + $resGroup)
    $resources = Get-AzResource -ResourceGroupName $resGroup 
    $resources | ForEach-Object {
        if($_.Tags -eq $null)
        {
            $_.Tags = $projectTags
        }
        else {
            $rsrc = $_
            $tags.Keys | Foreach {
                $rsrc.Tags[$_] = $tags[$_] 
            }
        }
    }
    $resources | ForEach-Object {
        Write-Host("*************** Updating resource " + $_.Id)
        UpdateLoop -maxIterations 3 -resource $_
    }
}


Write-Host("RG - " + $resourceGroupName)
Write-Host("TAG - " + $tagId)
Write-Host("VAL - " + $deploymentId)

Update-GroupResources -resGroup $resourceGroupName -tags $projectTags

$clusterResources = Get-AzResource -ResourceType "Microsoft.ContainerService/managedClusters" -ResourceGroupName $resourceGroupName -ExpandProperties
foreach($cluster in $clusterResources)
{
    Update-GroupResources -resGroup $cluster.Properties.nodeResourceGroup -tags $projectTags
}
#!/usr/bin/python3

import argparse
from azure.keyvault import KeyVaultClient
from azure.common.client_factory import get_client_from_cli_profile
from dotenv import load_dotenv
import os

def set_secret(kv_endpoint, secret_name, secret_value):
    client = get_client_from_cli_profile(KeyVaultClient)

    client.set_secret(kv_endpoint, secret_name, secret_value)
    return "Successfully created secret: {secret_name} in keyvault: {kv_endpoint}".format(
        secret_name=secret_name, kv_endpoint=kv_endpoint)    

def parse_args():
    parser = argparse.ArgumentParser()

    parser.add_argument('-n', '--secretName', required=True,
                        help="The name of the secret")

    return parser.parse_args()


if __name__ == "__main__":

    load_dotenv(override=True)
    
    # hard coded for now
    kv_endpoint = "https://t3scriptkeyvault.vault.azure.net/"
    args = parse_args()
    key = os.getenv("storage_conn_string")
    print(key)
    message = set_secret(kv_endpoint, args.secretName, key)

    print(message)

#!/usr/bin/python

import azureml.core
from azureml.core import Workspace
from dotenv import set_key, get_key, find_dotenv
from pathlib import Path
from AIHelpers.utilities import get_auth

import sys, getopt

def main(argv):  
  try:
     opts, args = getopt.getopt(argv,"hs:rg:wn:wr:dsn:cn:an:ak:drg:",
      ["subscription_id=","resource_group=","workspace_name=", "workspace_region=","blob_datastore_name=","container_name=","account_name=","account_key=","datastore_rg="])
  except getopt.GetoptError:
     print 'aml_creation.py -s <subscription_id> -rg <resource_group> -wn <workspace_name> -wr <workspace_region>'
     sys.exit(2)
  for opt, arg in opts:
     if opt == '-h':
        print 'aml_creation.py -s <subscription_id> -rg <resource_group> -wn <workspace_name> -wr <workspace_region>'
        sys.exit()
     elif opt in ("-s", "--subscription_id"):
        subscription_id = arg
     elif opt in ("-rg", "--resource_group"):
        resource_group = arg
     elif opt in ("-wn", "--workspace_name"):
        workspace_name = arg
     elif opt in ("-wr", "--workspace_region"):
        workspace_region = arg
     elif opt in ("-dsn", "--blob_datastore_name"):
        workspace_region = arg
     elif opt in ("-cn", "--container_name"):
        workspace_region = arg
     elif opt in ("-an", "--account_name"):
        workspace_region = arg
     elif opt in ("-ak", "--account_key"):
        workspace_region = arg
     elif opt in ("-drg", "--datastore_rg"):
        workspace_region = arg
        
    env_path = find_dotenv()
    if env_path == "":
        Path(".env").touch()
        env_path = find_dotenv()

    ws = Workspace.create(
      name=workspace_name,
      subscription_id=subscription_id,
      resource_group=resource_group,
      location=workspace_region,
      create_resource_group=True,
      auth=get_auth(env_path),
      exist_ok=True,
    )
    blob_datastore = Datastore.register_azure_blob_container(workspace=ws, 
                                                         datastore_name=blob_datastore_name, 
                                                         container_name=container_name, 
                                                         account_name=account_name,
                                                         account_key=account_key,
                                                         resource_group=datastore_rg)

if __name__ == "__main__":
  print("AML SDK Version:", azureml.core.VERSION)
  main(sys.argv[1:])
#!/usr/bin/python

import azureml.core
from azureml.core import Workspace
from dotenv import set_key, get_key, find_dotenv
from pathlib import Path
from AIHelpers.utilities import get_auth

import sys, getopt

def main(argv):  
  try:
     opts, args = getopt.getopt(argv,"hs:rg:wn:wr:",["subscription_id=","resource_group=","workspace_name=", "workspace_region="])
  except getopt.GetoptError:
     print 'aml_creation.py -s <subscription_id> -rg <resource_group> -wn <workspace_name> -wr <workspace_region>'
     sys.exit(2)
  for opt, arg in opts:
     if opt == '-h':
        print 'aml_creation.py -s <subscription_id> -rg <resource_group> -wn <workspace_name> -wr <workspace_region>'
        sys.exit()
     elif opt in ("-s", "--subscription_id"):
        subscription_id = arg
     elif opt in ("-rg", "--resource_group"):
        resource_group = arg
     elif opt in ("-wn", "--workspace_name"):
        workspace_name = arg
     elif opt in ("-wr", "--workspace_region"):
        workspace_region = arg
        
    env_path = find_dotenv()
    if env_path == "":
        Path(".env").touch()
        env_path = find_dotenv()

    ws = Workspace.create(
      name=workspace_name,
      subscription_id=subscription_id,
      resource_group=resource_group,
      location=workspace_region,
      create_resource_group=True,
      auth=get_auth(env_path),
      exist_ok=True,
    )

if __name__ == "__main__":
  print("AML SDK Version:", azureml.core.VERSION)
  main(sys.argv[1:])
  
  # Azure resources
  subscription_id = "{{cookiecutter.subscription_id}}"
  resource_group = "{{cookiecutter.resource_group}}"  
  workspace_name = "{{cookiecutter.workspace_name}}"  
  workspace_region = "{{cookiecutter.workspace_region}}"

parameters:
  Agent: Hosted Ubuntu 1604
  Demands: "python3"
  stageName: 'defaultStageName'
  jobDisplayName: 'defaultDisplayName'
  jobTimeoutInMinutes: 180
  TridentWorkloadTypeShort: #
  DeployLocation: #
  TestPostfix: # "" | "-release" | "-preview"
  Deploy_Location_Short: #
  DefaultWorkingDirectory: #
  Template: #
  aksimagename: 'myimage'
  ProjectLocation: #
  PythonPath: #
  cluster_name: #
  flighting_release: false
  flighting_preview: false
  doCleanup: True
  sub_vars: ../vars/agce_devops_sub_vars.yml
  workload_vars: #
  sp_appid: #
  sp_password: #

stages:
- stage: ${{parameters.stageName}}
  dependsOn: []    
  jobs:
  - job: deploy_notebook_steps
    displayName: ${{parameters.jobDisplayName}}

    pool:
      name: ${{parameters.Agent}}
      demands: ${{parameters.Demands}}
    container: "rocker/tidyverse:latest"

    timeoutInMinutes: ${{parameters.jobTimeoutInMinutes}}
  
    workspace:
      clean: all
  
    variables:
    - template: ${{parameters.sub_vars}}
    - template: ${{parameters.workload_vars}}
  
    steps:
    - template: ../steps/deploy_container_steps_v2.yml
      parameters:
        template: ${{variables.Template}}
        azureSubscription: ${{variables.azureSubscription}}
        azure_subscription: ${{variables.azure_subscription}}
        azureresourcegroup: ${{variables.TridentWorkloadTypeShort}}-${{variables.DeployLocation}}${{parameters.TestPostfix}}
        workspacename: ${{variables.TridentWorkloadTypeShort}}-${{variables.DeployLocation}}
        azureregion: ${{variables.DeployLocation}}
        aksimagename: ${{parameters.aksimagename}}
        aks_name: ${{variables.TridentWorkloadTypeShort}}${{parameters.TestPostfix}}
        location: ${{variables.ProjectLocation}}
        python_path: ${{parameters.DefaultWorkingDirectory}}${{variables.PythonPath}}
        cluster_name: ${{variables.TridentWorkloadTypeShort}}${{parameters.TestPostfix}}
        flighting_release: ${{parameters.flighting_release}}
        flighting_preview: ${{parameters.flighting_preview}}
        sp_appid: ${{parameters.sp_appid}}
        sp_password: ${{parameters.sp_password}}
        doCleanup: ${{parameters.doCleanup}}
parameters:
  Agent: Hosted Ubuntu 1604
  stageName: 'defaultStageName'
  jobDisplayName: 'defaultDisplayName'
  jobTimeoutInMinutes: 180
  TridentWorkloadTypeShort: #
  DeployLocation: #
  TestPostfix: # "" | "-release" | "-preview"
  Deploy_Location_Short: #
  DefaultWorkingDirectory: #
  Template: #
  azureSubscription: #
  azure_subscription: #
  aksimagename: #
  ProjectLocation: #
  PythonPath: #
  cluster_name: #
  flighting_release: false
  flighting_preview: false
  doCleanup: False

stages:
- stage: ${{parameters.stageName}}
  dependsOn: []    
  jobs:
  - job: deploy_notebook_steps
    displayName: ${{parameters.jobDisplayName}}

    pool:
      name: ${{parameters.Agent}}
  
    timeoutInMinutes: ${{parameters.jobTimeoutInMinutes}}
  
    workspace:
      clean: all
  
    variables:
      AIResourceGroupName: ${{parameters.TridentWorkloadTypeShort}}-${{parameters.DeployLocation}}${{parameters.TestPostfix}}
      aks_name: ${{parameters.TridentWorkloadTypeShort}}${{parameters.TestPostfix}}
      cluster_name: ${{parameters.TridentWorkloadTypeShort}}${{parameters.TestPostfix}}
      python_path: ${{parameters.DefaultWorkingDirectory}}${{parameters.PythonPath}}
  
    steps:
    - template: ../steps/deploy_notebook_steps.yml
      parameters:
        template: ${{parameters.Template}}
        azureSubscription: ${{parameters.azureSubscription}}
        azure_subscription: ${{parameters.azure_subscription}}
        azureresourcegroup: ${{variables.AIResourceGroupName}}
        workspacename: ${{parameters.TridentWorkloadTypeShort}}-${{parameters.DeployLocation}}
        azureregion: ${{parameters.DeployLocation}}
        aksimagename: ${{parameters.aksimagename}}
        aks_name: ${{variables.aks_name}}
        location: ${{parameters.ProjectLocation}}
        python_path: ${{variables.python_path}}
        cluster_name: ${{variables.cluster_name}}
        flighting_release: ${{parameters.flighting_release}}
        flighting_preview: ${{parameters.flighting_preview}}
        doCleanup: ${{parameters.doCleanup}}

parameters:
  Agent: Hosted Ubuntu 1604
  Demands: "python3"
  stageName: 'defaultStageName'
  jobDisplayName: 'defaultDisplayName'
  jobTimeoutInMinutes: 180
  TridentWorkloadTypeShort: #
  DeployLocation: #
  TestPostfix: # "" | "-release" | "-preview"
  Deploy_Location_Short: #
  DefaultWorkingDirectory: #
  Template: #
  aksimagename: 'myimage'
  ProjectLocation: #
  PythonPath: #
  cluster_name: #
  flighting_release: false
  flighting_preview: false
  flighting_master: false
  doCleanup: True
  sub_vars: ../vars/agce_devops_sub_vars.yml
  workload_vars: #
  sql_server_name: "x"
  sql_database_name: "x"
  sql_username: "x"
  sql_password: "x"
  data_prep: true
  train: true
  post_cleanup: true
  container_name: "x"
  account_name: "x"
  account_key: "x"
  datastore_rg: "x"

stages:
- stage: ${{parameters.stageName}}
  dependsOn: []    
  jobs:
  - job: deploy_notebook_steps
    displayName: ${{parameters.jobDisplayName}}

    pool:
      name: ${{parameters.Agent}}
      demands: ${{parameters.Demands}}
    
    timeoutInMinutes: ${{parameters.jobTimeoutInMinutes}}
    
    continueOnError: ${{or(or(eq(parameters.flighting_release,'true'), eq(parameters.flighting_preview,'true')), eq(parameters.flighting_master,'true'))}}
  
    workspace:
      clean: all
  
    variables:
    - template: ${{parameters.sub_vars}}
    - template: ${{parameters.workload_vars}}
  
    steps:
    - template: ../steps/deploy_notebook_steps_v2.yml
      parameters:
        template: ${{variables.Template}}
        azureSubscription: ${{variables.azureSubscription}}
        azure_subscription: ${{variables.azure_subscription}}
        azureresourcegroup: ${{variables.TridentWorkloadTypeShort}}-${{variables.DeployLocation}}${{parameters.TestPostfix}}
        workspacename: ${{variables.TridentWorkloadTypeShort}}-${{variables.DeployLocation}}
        azureregion: ${{variables.DeployLocation}}
        aksimagename: ${{parameters.aksimagename}}
        aks_name: ${{variables.TridentWorkloadTypeShort}}${{parameters.TestPostfix}}
        location: ${{variables.ProjectLocation}}
        python_path: ${{parameters.DefaultWorkingDirectory}}${{variables.PythonPath}}
        cluster_name: ${{variables.TridentWorkloadTypeShort}}${{parameters.TestPostfix}}
        flighting_release: ${{parameters.flighting_release}}
        flighting_preview: ${{parameters.flighting_preview}}
        flighting_master: ${{parameters.flighting_master}}        
        doCleanup: ${{parameters.doCleanup}}
        sql_server_name: ${{parameters.sql_server_name}}
        sql_database_name: ${{parameters.sql_database_name}}
        sql_username: ${{parameters.sql_username}}
        sql_password: ${{parameters.sql_password}}
        data_prep: ${{parameters.data_prep}}
        train: ${{parameters.train}}
        post_cleanup: ${{parameters.post_cleanup}}
        container_name: ${{parameters.container_name}}
        account_name: ${{parameters.account_name}}
        account_key: ${{parameters.account_key}}
        datastore_rg: ${{parameters.datastore_rg}}
parameters:
  Agent: Hosted Ubuntu 1604
  Demands: "python3"
  stageName: 'defaultStageName'
  jobDisplayName: 'defaultDisplayName'
  jobTimeoutInMinutes: 180
  TridentWorkloadTypeShort: #
  DeployLocation: #
  TestPostfix: # "" | "-release" | "-preview"
  Deploy_Location_Short: #
  DefaultWorkingDirectory: #
  Template: #
  aksimagename: 'myimage'  
  aks_name: "akscluster"
  aks_service_name: "aksservice"
  ProjectLocation: #
  PythonPath: #
  cluster_name: #
  flighting_release: false
  flighting_preview: false
  flighting_master: false
  doCleanup: True
  sub_vars: ../vars/agce_devops_sub_vars.yml
  workload_vars: #
  sql_server_name: "x"
  sql_database_name: "x"
  sql_username: "x"
  sql_password: "x"
  data_prep: true
  train: true
  post_cleanup: true
  container_name: "x"
  account_name: "x"
  account_key: "x"
  datastore_rg: "x"
  conda: #

stages:
- stage: ${{parameters.stageName}}
  dependsOn: []    
  jobs:
  - job: deploy_notebook_steps
    displayName: ${{parameters.jobDisplayName}}

    pool:
      name: ${{parameters.Agent}}
      demands: ${{parameters.Demands}}
    
    timeoutInMinutes: ${{parameters.jobTimeoutInMinutes}}
    
    continueOnError: ${{or(or(eq(parameters.flighting_release,'true'), eq(parameters.flighting_preview,'true')), eq(parameters.flighting_master,'true'))}}
  
    workspace:
      clean: all
  
    variables:
    - template: ${{parameters.sub_vars}}
  
    steps:
    - template: ../steps/deploy_notebook_steps_v5.yml
      parameters:
        template: ${{parameters.Template}}
        azureSubscription: ${{variables.azureSubscription}}
        azure_subscription: ${{variables.azure_subscription}}
        azureresourcegroup: ${{parameters.TridentWorkloadTypeShort}}-${{parameters.DeployLocation}}${{parameters.TestPostfix}}
        workspacename: ${{parameters.TridentWorkloadTypeShort}}-${{parameters.DeployLocation}}
        azureregion: ${{parameters.DeployLocation}}
        aksimagename: ${{parameters.aksimagename}}
        aks_service_name: ${{parameters.aks_service_name}}
        aks_name: ${{parameters.aks_name}}
        location: ${{parameters.ProjectLocation}}
        python_path: ${{parameters.DefaultWorkingDirectory}}${{parameters.PythonPath}}
        cluster_name: ${{parameters.TridentWorkloadTypeShort}}${{parameters.TestPostfix}}
        flighting_release: ${{parameters.flighting_release}}
        flighting_preview: ${{parameters.flighting_preview}}
        flighting_master: ${{parameters.flighting_master}}        
        doCleanup: ${{parameters.doCleanup}}
        sql_server_name: ${{parameters.sql_server_name}}
        sql_database_name: ${{parameters.sql_database_name}}
        sql_username: ${{parameters.sql_username}}
        sql_password: ${{parameters.sql_password}}
        data_prep: ${{parameters.data_prep}}
        train: ${{parameters.train}}
        post_cleanup: ${{parameters.post_cleanup}}
        container_name: ${{parameters.container_name}}
        account_name: ${{parameters.account_name}}
        account_key: ${{parameters.account_key}}
        datastore_rg: ${{parameters.datastore_rg}}
        conda: ${{parameters.conda}}
# Python package
# Create and test a Python package on multiple Python versions.
# Add steps that analyze code, save the dist with the build record, publish to a PyPI-compatible index, and more:
# https://docs.microsoft.com/azure/devops/pipelines/languages/python

trigger:
- master

pool:
  vmImage: 'ubuntu-latest'
strategy:
  matrix:
    Python37:
      python.version: '3.7'

steps:
- task: UsePythonVersion@0
  inputs:
    versionSpec: '$(python.version)'
  displayName: 'Use Python $(python.version)'

- script: |
    python -m pip install --upgrade pip
    pip install setuptools wheel twine
  displayName: 'Install dependencies'

- task: TwineAuthenticate@1
  inputs:
    artifactFeed: <>
- script: |
    python setup.py sdist bdist_wheel

    twine upload -r <> --config-file $(PYPIRC_PATH) dist/*

parameters:
  Agent: Hosted Ubuntu 1604
  Demands: "python3"
  stageName: 'defaultStageName'
  jobDisplayName: 'defaultDisplayName'
  jobTimeoutInMinutes: 15
  DefaultWorkingDirectory: #
  pypi_artifactFeeds: #
  pypi_pythonDownloadServiceConnections: #
  module: src
  candidate: #
  dependsOn: []
  environment: #
  before: #

stages:
- stage: ${{parameters.stageName}}
  dependsOn: ${{parameters.dependsOn}}
  jobs:
  - deployment: package_and_publish
    environment:  ${{parameters.environment}} 
    pool:
      name: $(Agent_Name)
    strategy:
      runOnce:
        deploy:
          steps:
          - checkout: self
          - task: UsePythonVersion@0
            displayName: 'Use Python 3.7'
            inputs:
              versionSpec: 3.7
          - script: |
              pip install --upgrade pip
            displayName: 'Update Pip'
          - script: |
              pip install wheel twine keyring artifacts-keyring
            displayName: 'Install dependencies'
          - task: TwineAuthenticate@1
            inputs:
              artifactFeed: $(repo)/$(candidate)
            displayName: 'Twine Authenticate'
          - script: |                        
              python setup.py sdist bdist_wheel
            displayName: 'Build wheel'
            env:
              VERSION: $(Build.BuildNumber)
          - script: |
              python -m twine upload -r $(candidate) --config-file $(PYPIRC_PATH) dist/*.whl --verbose
            displayName: 'Upload wheel'

  - deployment: Integration_Testing
    environment:  ${{parameters.environment}}
    dependsOn: package_and_publish
    timeoutInMinutes: 15 # how long to run the job before automatically cancelling
    pool:
      name: $(Agent_Name)
    strategy:
      runOnce:
        deploy:
          steps:
            - checkout: self
            - task: UsePythonVersion@0
              displayName: 'Use Python 3.7'
              inputs:
                versionSpec: 3.7            
            - task: PipAuthenticate@1
              inputs:
                artifactFeeds: $(pypi_artifactFeeds)
                pythonDownloadServiceConnections: $(pypi_pythonDownloadServiceConnections)
                onlyAddExtraIndex: true
            - script: |
                pip install --upgrade pip
              displayName: 'Update Pip'
            - script: |
                pip install pytest pytest-azurepipelines pytest-nunit pytest-cov keyring artifacts-keyring commondatamodel-objectmodel databricks-connect==6.4.* 
              displayName: 'Install dependencies'
              continueOnError: true
            # allow user to run global before
            - ${{ if parameters.before }}:
              - ${{ parameters.before }}
            - script: |
                pip install $(module)
                pytest tests/integration --durations 0 --junitxml=junit/test-results.xml --cov=$(module) --cov-report=xml
              displayName: 'pytest'
              continueOnError: true
            - task: PublishTestResults@2
              condition: succeededOrFailed()
              inputs:
                testResultsFiles: '**/test-*.xml'
                testRunTitle: 'Publish test results for Python $(python.version)'
            - task: PublishCodeCoverageResults@1
              inputs:
                codeCoverageTool: Cobertura
                summaryFileLocation: '$(System.DefaultWorkingDirectory)/**/coverage.xml'

# Deploy Python Development Stage
#
# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License.
#
# Job: Run Unit Tests and Static Code Analysis
#
# Step 1: Install Python Version 3.7
# Step 2: Authenticate with Private Pypi
# Step 3: Update Pip
# Step 4: Install Tox
# Step 5: Use Tox to run tests from tox.ini
# Step 6: Run PyLint for Static Code Anlaysis and Linting
# Step 8: Publish Test Results to Azure DevOps
# Step 9: Publish Code Coverage Results to Azure DevOps
#
# Author: dciborow@microsoft.com

parameters:
  Agent: Hosted Ubuntu 1604
  Demands: "python3"
  stageName: 'defaultStageName'
  jobDisplayName: 'defaultDisplayName'
  jobTimeoutInMinutes: 180
  DefaultWorkingDirectory: #
  pypi_artifactFeeds: #
  pypi_pythonDownloadServiceConnections: #
  module: src

stages:
- stage: ${{parameters.stageName}}
  dependsOn: []    
  jobs:
  - job: Development
    displayName: ${{parameters.jobDisplayName}}

    pool:
      name: ${{parameters.Agent}}
      demands: ${{parameters.Demands}}
 
    timeoutInMinutes: ${{parameters.jobTimeoutInMinutes}}
 
    workspace:
      clean: all

    steps:
    - task: UsePythonVersion@0
      displayName: 'Use Python 3.7'
      inputs:
        versionSpec: 3.7
    - task: PipAuthenticate@1
      inputs:
        artifactFeeds: $(pypi_artifactFeeds)
        pythonDownloadServiceConnections: ${{parameters.pypi_pythonDownloadServiceConnections}}
        onlyAddExtraIndex: true
    - script: |
        pip install --upgrade pip
      displayName: 'Update Pip'
    - script: |
        pip install tox
      displayName: 'Install Tox'
    - script: |
        tox -e py
      displayName: "Run Tox"
      env:
        VERSION: $(Build.BuildNumber)
    - script: |
        pip install pylint junit-xml pylint-junit
        pylint ./${{parameters.module}}
        pylint --output-format=junit ./${{parameters.module}} >> test-pylint-results.xml
      displayName: PyLint
      continueOnError: true
    - task: ComponentGovernanceComponentDetection@0
      inputs:
        scanType: 'LogOnly'
        verbosity: 'Verbose'
        alertWarningLevel: 'High'
        failOnAlert: false
    - task: PublishTestResults@2
      condition: succeededOrFailed()
      inputs:
        testResultsFiles: '**/test-*.xml'
        testRunTitle: 'Publish test results for Python 3.7'
    - task: PublishCodeCoverageResults@1
      inputs:
        codeCoverageTool: Cobertura
        summaryFileLocation: '$(System.DefaultWorkingDirectory)/**/coverage.xml'

# Deploy Python Development Stage
#
# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License.
#
# Job: Run Unit Tests and Static Code Analysis
#
# Step 1: Install Python Version 3.7
# Step 2: Authenticate with Private Pypi
# Step 3: Update Pip
# Step 4: Install Tox
# Step 5: Use Tox to run tests from tox.ini
# Step 6: Run PyLint for Static Code Anlaysis and Linting
# Step 8: Publish Test Results to Azure DevOps
# Step 9: Publish Code Coverage Results to Azure DevOps
#
# Author: dciborow@microsoft.com

parameters:
  Agent: Hosted Ubuntu 1604
  Demands: "python3"
  stageName: 'defaultStageName'
  jobDisplayName: 'defaultDisplayName'
  jobTimeoutInMinutes: 180
  DefaultWorkingDirectory: #
  pypi_artifactFeeds: #
  pypi_pythonDownloadServiceConnections: #
  module: src

stages:
- stage: ${{parameters.stageName}}
  dependsOn: []    
  jobs:
  - job: Development
    displayName: ${{parameters.jobDisplayName}}

    pool:
      name: ${{parameters.Agent}}
      demands: ${{parameters.Demands}}
 
    timeoutInMinutes: ${{parameters.jobTimeoutInMinutes}}
 
    workspace:
      clean: all

    steps:
    - task: UsePythonVersion@0
      displayName: 'Use Python 3.7'
      inputs:
        versionSpec: 3.7
    - task: PipAuthenticate@1
      inputs:
        artifactFeeds: $(pypi_artifactFeeds)
        pythonDownloadServiceConnections: ${{parameters.pypi_pythonDownloadServiceConnections}}
        onlyAddExtraIndex: true
    - script: |
        pip install --upgrade pip
      displayName: 'Update Pip'
    - script: |
        pip install tox
      displayName: 'Install Tox'
    - script: |
        tox -e py
      displayName: "Run Tox"
      env:
        VERSION: $(Build.BuildNumber)
    - script: |
        pip install pylint junit-xml pylint-junit
        pylint ./${{parameters.module}}
        pylint --output-format=junit ./${{parameters.module}} >> test-pylint-results.xml
      displayName: PyLint
      continueOnError: true
    - task: ComponentGovernanceComponentDetection@0
      inputs:
        scanType: 'LogOnly'
        verbosity: 'Verbose'
        alertWarningLevel: 'High'
        failOnAlert: false
    - task: PublishTestResults@2
      condition: succeededOrFailed()
      inputs:
        testResultsFiles: '**/test-*.xml'
        testRunTitle: 'Publish test results for Python 3.7'
    - task: PublishCodeCoverageResults@1
      inputs:
        codeCoverageTool: Cobertura
        summaryFileLocation: '$(System.DefaultWorkingDirectory)/**/coverage.xml'

parameters:
  azureSubscription: ''
  azure_subscription: ''
  location: submodules/DeployMLModelPipelines
  azureresourcegroup: dcibhpdl
  workspacename: dcibhpwsdl
  azureregion: westus2
  aksimagename: dcibhpaksdl
  aks_name: dcibhpaksdl
  aks_service_name: dcibhpaksdlapi
  conda: batchscoringdl_aml
  doCleanup: true
  python_path: "$(System.DefaultWorkingDirectory)/submodules/DeployMLModelPipelines"
  cluster_name: "x"
  acr_name: "x"
  flighting_release: false
  flighting_preview: false
  flighting_master: false

steps:
- template: config_conda.yml
  parameters:
    conda_location: ${{parameters.python_path}}
    azureSubscription: ${{parameters.azureSubscription}}
    conda: ${{parameters.conda}}
    flighting_release: ${{parameters.flighting_release}}
    flighting_preview: ${{parameters.flighting_preview}}
    flighting_master: ${{parameters.flighting_master}}

- template: azpapermill.yml
  parameters:
    notebook: 02_setup_aml.ipynb
    location: ${{parameters.location}}
    azureSubscription: ${{parameters.azureSubscription}}
    conda: ${{parameters.conda}}
    azure_subscription: ${{parameters.azure_subscription}}
    azureresourcegroup: ${{parameters.azureresourcegroup}}
    workspacename: ${{parameters.workspacename}}
    azureregion: ${{parameters.azureregion}}
    storage_account_name: ${{parameters.workspacename}}store

- template: azpapermill.yml
  parameters:
    notebook: 03_develop_pipeline.ipynb
    location: ${{parameters.location}}
    azureSubscription: ${{parameters.azureSubscription}}
    conda: ${{parameters.conda}}
    num_epochs: 1
    timeoutInMinutes: 240
    
- template: azpapermill.yml
  parameters:
    notebook: 04_deploy_logic_apps.ipynb
    location: ${{parameters.location}}
    azureSubscription: ${{parameters.azureSubscription}}
    conda: ${{parameters.conda}}
    image_name: 'torchdet' 
    acr_resource_group: ${{parameters.azureresourcegroup}}
    acr_location: ${{parameters.azureregion}}

- template: cleanuptask.yml
  parameters:
    azureSubscription: ${{parameters.azureSubscription}}
    conda: ${{parameters.conda}}
    azureresourcegroup: ${{parameters.azureresourcegroup}}
    doCleanup: ${{parameters.doCleanup}}

parameters:
  azureSubscription: ''
  azure_subscription: ''
  location: submodules/DeployMLModelPipelines
  azureresourcegroup: dcibhpdl
  workspacename: dcibhpwsdl
  azureregion: westus2
  aksimagename: dcibhpaksdl
  aks_name: dcibhpaksdl
  aks_service_name: dcibhpaksdlapi
  conda: TorchDetectAML
  doCleanup: true
  python_path: "$(System.DefaultWorkingDirectory)/submodules/DeployMLModelPipelines"
  cluster_name: "dltraincomp"
  acr_name: "aidltrainacr"
  flighting_release: false
  flighting_preview: false

steps:
- template: config_conda.yml
  parameters:
    conda_location: ${{parameters.location}}
    azureSubscription: ${{parameters.azureSubscription}}
    conda: ${{parameters.conda}}
    flighting_release: ${{parameters.flighting_release}}
    flighting_preview: ${{parameters.flighting_preview}}

- bash: |
    cd  ${{parameters.location}}
    wget https://bostondata.blob.core.windows.net/builddata/Data.zip
    unzip Data.zip
    mv ./Data/JPEGImages ./scripts/
    mv ./Data/Annotations ./scripts/

- template: azpapermill.yml
  parameters:
    notebook: 00_AMLConfiguration.ipynb
    location: ${{parameters.location}}
    azureSubscription: ${{parameters.azureSubscription}}
    conda: ${{parameters.conda}}
    azure_subscription: ${{parameters.azure_subscription}}
    azureresourcegroup: ${{parameters.azureresourcegroup}}
    workspacename: ${{parameters.workspacename}}
    azureregion: ${{parameters.azureregion}}
    acr_name: ${{parameters.acr_name}}

- template: azpapermill.yml
  parameters:
    notebook: 01_PrepareTrainingScript.ipynb
    location: ${{parameters.location}}
    azureSubscription: ${{parameters.azureSubscription}}
    conda: ${{parameters.conda}}
    azure_subscription: ${{parameters.azure_subscription}}
    azureresourcegroup: ${{parameters.azureresourcegroup}}
    workspacename: ${{parameters.workspacename}}
    azureregion: ${{parameters.azureregion}}
    
- template: azpapermill.yml
  parameters:
    notebook: 03_BuildDockerImage.ipynb
    location: ${{parameters.location}}
    azureSubscription: ${{parameters.azureSubscription}}
    conda: ${{parameters.conda}}
    image_name: 'torchdet' 
    acr_resource_group: ${{parameters.azureresourcegroup}}
    acr_location: ${{parameters.azureregion}}
    acr_name: ${{parameters.workspacename}}acr
    
- template: azpapermill.yml
  parameters:
    notebook: 04_TuneHyperparameters.ipynb
    location: ${{parameters.location}}
    azureSubscription: ${{parameters.azureSubscription}}
    conda: ${{parameters.conda}}  
    num_epochs: 1
    max_total_runs: 2
    cluster_name: dltraincomp
    azureresourcegroup: ${{parameters.azureresourcegroup}}

- template: cleanuptask.yml
  parameters:
    azureSubscription: ${{parameters.azureSubscription}}
    conda: deployment_aml
    azureresourcegroup: ${{parameters.azureresourcegroup}}
    doCleanup: ${{parameters.doCleanup}}

parameters:
  azureSubscription: ''
  azure_subscription: ''
  location: submodules/DeployMLModelPipelines
  azureresourcegroup: dcibhpdl
  workspacename: dcibhpwsdl
  azureregion: westus2
  aksimagename: dcibhpaksdl
  aks_name: dcibhpaksdl
  aks_service_name: dcibhpaksdlapi
  conda: batchscoringdl_aml
  doCleanup: true
  python_path: "$(System.DefaultWorkingDirectory)/submodules/DeployMLModelPipelines"
  cluster_name: "x"
  acr_name: "x"
  storage_account_name: aidlbatchstore
  flighting_release: false
  flighting_preview: false

steps:
- template: config_conda.yml
  parameters:
    conda_location: ${{parameters.python_path}}
    azureSubscription: ${{parameters.azureSubscription}}
    conda: ${{parameters.conda}}
    flighting_release: ${{parameters.flighting_release}}
    flighting_preview: ${{parameters.flighting_preview}}

- template: azpapermill.yml
  parameters:
    notebook: 000_Setup_GeophysicsTutorial_FWI_Azure_devito.ipynb
    location: ${{parameters.location}}
    azureSubscription: ${{parameters.azureSubscription}}
    conda: ${{parameters.conda}}
    azure_subscription: ${{parameters.azure_subscription}}
    azureresourcegroup: ${{parameters.azureresourcegroup}}
    workspacename: ${{parameters.workspacename}}
    azureregion: ${{parameters.azureregion}}
    storage_account_name: ${{parameters.storage_account_name}}

- template: azpapermill.yml
  parameters:
    notebook: 010_CreateExperimentationDockerImage_GeophysicsTutorial_FWI_Azure_devito.ipynb
    location: ${{parameters.location}}
    azureSubscription: ${{parameters.azureSubscription}}
    conda: ${{parameters.conda}}
    azure_subscription: ${{parameters.azure_subscription}}
    azureresourcegroup: ${{parameters.azureresourcegroup}}
    workspacename: ${{parameters.workspacename}}
    azureregion: ${{parameters.azureregion}}
    storage_account_name: ${{parameters.storage_account_name}}

- template: azpapermill.yml
  parameters:
    notebook: 020_UseAzureMLEstimatorForExperimentation_GeophysicsTutorial_FWI_Azure_devito.ipynb
    location: ${{parameters.location}}
    azureSubscription: ${{parameters.azureSubscription}}
    conda: ${{parameters.conda}}
    azure_subscription: ${{parameters.azure_subscription}}
    azureresourcegroup: ${{parameters.azureresourcegroup}}
    workspacename: ${{parameters.workspacename}}
    azureregion: ${{parameters.azureregion}}
    storage_account_name: ${{parameters.storage_account_name}}



parameters:
  azureSubscription: ''
  azure_subscription: ''
  location: submodules/DeployMLModelKubernetes/{{cookiecutter.project_name}}
  azureresourcegroup: dciborowhp
  workspacename: dciborowhpws
  azureregion: westus2
  aksimagename: dciborowhpaks
  aks_name: dciborowhpaks
  aks_service_name: myimage
  conda: MLAKSDeployAML
  doCleanup: true
  python_path: "$(System.DefaultWorkingDirectory)/submodules/DeployMLModelKubernetes/{{cookiecutter.project_name}}"
  flighting_release: false
  flighting_preview: false
  flighting_master: false

steps:
- template: config_conda.yml
  parameters:
    conda_location: ${{parameters.location}}
    azureSubscription: ${{parameters.azureSubscription}}
    conda: ${{parameters.conda}}
    flighting_release: ${{parameters.flighting_release}}
    flighting_preview: ${{parameters.flighting_preview}}
    flighting_master: ${{parameters.flighting_master}}

- template: azpapermill.yml
  parameters:
    notebook:  00_AMLConfiguration.ipynb
    location: ${{parameters.location}}
    azureSubscription: ${{parameters.azureSubscription}}
    conda: ${{parameters.conda}}
    azure_subscription: ${{parameters.azure_subscription}}
    azureresourcegroup: ${{parameters.azureresourcegroup}}
    workspacename: ${{parameters.workspacename}}
    azureregion: ${{parameters.azureregion}}
    aksimagename: ${{parameters.aksimagename}}

- template: azpapermill.yml
  parameters:
    notebook: 01_DataPrep.ipynb
    location: ${{parameters.location}}
    azureSubscription: ${{parameters.azureSubscription}}
    conda: ${{parameters.conda}}

- bash: |
    mkdir -p ${{parameters.location}}/iotedge/data_folder
    mkdir -p ${{parameters.location}}/aks/data_folder
    cd ${{parameters.location}}
    cp data_folder/*.tsv iotedge/data_folder
    cp data_folder/*.tsv aks/data_folder
  displayName: 'Copying data'

- template: azpapermill.yml
  parameters:
    notebook: 02_TrainOnLocal.ipynb
    location: ${{parameters.location}}
    azureSubscription: ${{parameters.azureSubscription}}
    conda: ${{parameters.conda}}

- template: azpapermill.yml
  parameters:
    notebook: 03_DevelopScoringScript.ipynb
    location: ${{parameters.location}}
    azureSubscription: ${{parameters.azureSubscription}}
    conda: ${{parameters.conda}}

- template: azpapermill.yml
  parameters:
    notebook: 04_CreateImage.ipynb
    location: ${{parameters.location}}
    azureSubscription: ${{parameters.azureSubscription}}
    conda: ${{parameters.conda}}

- template: azpapermill.yml
  parameters:
    notebook: 05_DeployOnAKS.ipynb
    location: ${{parameters.location}}/aks
    azureSubscription: ${{parameters.azureSubscription}}
    conda: ${{parameters.conda}}
    aks_name: ${{parameters.aks_name}}
    azureregion: ${{parameters.azureregion}}
    aks_service_name: ${{parameters.aks_service_name}}
    aksimagename: ${{parameters.aksimagename}}
    python_path: ${{parameters.python_path}}

- template: cleanuptask.yml
  parameters:
    azureSubscription: ${{parameters.azureSubscription}}
    conda: ${{parameters.conda}}
    azureresourcegroup: ${{parameters.azureresourcegroup}}
    doCleanup: ${{parameters.doCleanup}}


parameters:
  azureSubscription: ''
  azure_subscription: ''
  location: submodules/DeployMLModelPipelines
  azureresourcegroup: dcibhpdl
  workspacename: dcibhpwsdl
  azureregion: westus2
  aksimagename: dcibhpaksdl
  aks_name: dcibhpaksdl
  aks_service_name: dcibhpaksdlapi
  conda: amlmm
  doCleanup: true
  python_path: "$(System.DefaultWorkingDirectory)/submodules/DeployMLModelPipelines"
  flighting_release: false
  flighting_preview: false
  flighting_master: false

steps:
- template: config_conda.yml
  parameters:
    conda_location: ${{parameters.location}}
    azureSubscription: ${{parameters.azureSubscription}}
    conda: ${{parameters.conda}}
    flighting_release: ${{parameters.flighting_release}}
    flighting_preview: ${{parameters.flighting_preview}}
    flighting_master: ${{parameters.flighting_master}}

- template: azpapermill.yml
  parameters:
    notebook: 00_AMLConfiguration.ipynb
    location: ${{parameters.location}}
    azureSubscription: ${{parameters.azureSubscription}}
    conda: ${{parameters.conda}}
    azure_subscription: ${{parameters.azure_subscription}}
    azureresourcegroup: ${{parameters.azureresourcegroup}}
    workspacename: ${{parameters.workspacename}}
    azureregion: ${{parameters.azureregion}}

- template: azpapermill.yml
  parameters:
    notebook: 01_DataPrep.ipynb
    location: ${{parameters.location}}
    azureSubscription: ${{parameters.azureSubscription}}
    conda: ${{parameters.conda}}
    azure_subscription: ${{parameters.azure_subscription}}
    azureresourcegroup: ${{parameters.azureresourcegroup}}
    workspacename: ${{parameters.workspacename}}
    azureregion: ${{parameters.azureregion}}

- template: azpapermill.yml
  parameters:
    notebook: 02_create_pipeline.ipynb
    location: ${{parameters.location}}
    azureSubscription: ${{parameters.azureSubscription}}
    conda: ${{parameters.conda}}

- template: cleanuptask.yml
  parameters:
    azureSubscription: ${{parameters.azureSubscription}}
    conda: deployment_aml
    azureresourcegroup: ${{parameters.azureresourcegroup}}
    doCleanup: ${{parameters.doCleanup}}

parameters:
  azureSubscription: 'x'
  azure_subscription: 'x'
  location: '.'
  azureresourcegroup: 'x'
  workspacename: 'x'
  azureregion: westus2
  aksimagename: 'x'
  aks_name: 'x'
  aks_service_name: 'x'
  conda: 'MLHyperparameterTuning'
  doCleanup: true
  python_path: 'x'
  max_total_runs: 1
  flighting_release: false
  flighting_preview: false
  flighting_master: false

steps:
- template: config_conda.yml
  parameters:
    conda_location: ${{parameters.location}}
    azureSubscription: ${{parameters.azureSubscription}}
    conda: ${{parameters.conda}}
    flighting_release: ${{parameters.flighting_release}}
    flighting_preview: ${{parameters.flighting_preview}}
    flighting_master: ${{parameters.flighting_master}}

- template: azpapermill.yml
  parameters:
    notebook: 00_Data_Prep.ipynb
    conda: ${{parameters.conda}}
    azureSubscription: ${{parameters.azureSubscription}}
    location: ${{parameters.location}}

- template: azpapermill.yml
  parameters:
    notebook: 01_Training_Script.ipynb
    conda: ${{parameters.conda}}
    azureSubscription: ${{parameters.azureSubscription}}
    location: ${{parameters.location}}

- template: azpapermill.yml
  parameters:
    notebook: 02_Testing_Script.ipynb
    conda: ${{parameters.conda}}
    azureSubscription: ${{parameters.azureSubscription}}
    location: ${{parameters.location}}

- template: azpapermill.yml
  parameters:
    notebook: 03_Run_Locally.ipynb
    conda: ${{parameters.conda}}
    location: ${{parameters.location}}
    azureSubscription: ${{parameters.azureSubscription}}
    azure_subscription: ${{parameters.azure_subscription}}
    azureresourcegroup: ${{parameters.azureresourcegroup}}
    workspacename: ${{parameters.workspacename}}
    azureregion: ${{parameters.azureregion}}

- template: azpapermill.yml
  parameters:
    notebook:  04_Hyperparameter_Random_Search.ipynb
    conda: ${{parameters.conda}}
    location: ${{parameters.location}}
    azureSubscription: ${{parameters.azureSubscription}}
    max_total_runs: ${{parameters.max_total_runs}}
  
- template: azpapermill.yml
  parameters:
    notebook: 07_Train_With_AML_Pipeline.ipynb
    conda: ${{parameters.conda}}
    location: ${{parameters.location}}
    azureSubscription: ${{parameters.azureSubscription}}
    max_total_runs: ${{parameters.max_total_runs}}

- template: cleanuptask.yml
  parameters:
    azureSubscription: ${{parameters.azureSubscription}}
    conda: deployment_aml
    location: ${{parameters.location}}
    azureresourcegroup: ${{parameters.azureresourcegroup}}
    doCleanup: ${{parameters.doCleanup}}


parameters:
  azureSubscription: ''
  azure_subscription: ''
  location: practices/recommendations/
  azureresourcegroup: dciborowreco
  workspacename: dciborowrecows
  azureregion: westus2
  aksimagename: dciborowrecoaks
  aks_name: dciborowrecoaks
  aks_service_name: myimage
  conda: nightly_reco_pyspark
  doCleanup: true

steps:
- task: AzureCLI@1
  inputs:
    azureSubscription: ${{parameters.azureSubscription}}
    scriptLocation: inlineScript
    inlineScript: |
      echo "##vso[task.prependpath]$CONDA/bin"

- task: AzureCLI@1
  inputs:
    azureSubscription: ${{parameters.azureSubscription}}
    scriptLocation: inlineScript
    inlineScript: |
      cd practices/recommenders
      python ./scripts/generate_conda_file.py --pyspark --name nightly_reco_pyspark
      conda env create --quiet -f nightly_reco_pyspark.yaml 2> log

- task: AzureCLI@1
  inputs:
    azureSubscription: ${{parameters.azureSubscription}}
    scriptLocation: inlineScript
    inlineScript: |
      cd practices/recommenders
      source activate nightly_reco_pyspark
      unset SPARK_HOME
      pytest tests/harness -m "harness and spark and not gpu" --junitxml=reports/test-harness.xml

# AI Architecture Template TODO: update tile
#
# A Github Service Connection must also be created with the name "AIArchitecturesAndPractices-GitHub"
# https://docs.microsoft.com/en-us/azure/devops/pipelines/process/demands?view=azure-devops&tabs=yaml
#
# An Agent_Name Variable must be creating in the Azure DevOps UI.
# https://docs.microsoft.com/en-us/azure/devops/pipelines/process/variables?view=azure-devops&tabs=yaml%2Cbatch#secret-variables
#
# This must point to an Agent Pool, with a Self-Hosted Linux VM with a Docker.
# https://docs.microsoft.com/en-us/azure/devops/pipelines/agents/v2-linux?view=azure-devops

parameters:
  azureSubscription: ''
  azure_subscription: ''
  azureresourcegroup: ''
  workspacename: ''
  azureregion: westus2
  aksimagename: ''
  aks_name: ''
  aks_service_name: myimage
  conda: ai-architecture-template
  doCleanup: true
  flighting_release: false
  flighting_preview: false
  flighting_master: false
  fresh_install: false

steps:
- template: config_conda.yml
  parameters:
    conda_location: .
    azureSubscription: ${{parameters.azureSubscription}}
    conda: ${{parameters.conda}}
    flighting_release: ${{parameters.flighting_release}}
    flighting_preview: ${{parameters.flighting_preview}}
    flighting_master: ${{parameters.flighting_master}}
    fresh_install: ${{parameters.fresh_install}}

- template: pytest_steps.yml
  parameters:
    azureSubscription: ${{parameters.azureSubscription}}
    azure_subscription: ${{parameters.azure_subscription}}
    azureresourcegroup: ${{parameters.azureresourcegroup}}    
    workspacename: aiarchtemplate
    conda: ${{parameters.conda}}
    azureregion: ${{parameters.azureregion}}

- template: cleanuptask.yml
  parameters:
    azureSubscription: ${{parameters.azureSubscription}}
    azure_subscription: ${{parameters.azure_subscription}}
    conda: ${{parameters.conda}}
    azureresourcegroup: ${{parameters.azureresourcegroup}}
    doCleanup: ${{parameters.doCleanup}}



parameters:
  azureSubscription: ''
  azure_subscription: ''
  location: submodules/DeployMLModelKubernetes/{{cookiecutter.project_name}}
  azureresourcegroup: dciborowhp
  workspacename: dciborowhpws
  azureregion: westus2
  aksimagename: dciborowhpaks
  aks_name: dciborowhpaks
  aks_service_name: myimage
  conda: az-ml-realtime-score
  doCleanup: true
  python_path: "$(System.DefaultWorkingDirectory)/submodules/DeployMLModelKubernetes/{{cookiecutter.project_name}}"
  flighting_release: false
  flighting_preview: false
  flighting_master: false
  update_conda_package: false

steps:
- template: config_conda.yml
  parameters:   
    conda: az-ml-realtime-score
    azureSubscription: ${{parameters.azureSubscription}}    
    flighting_release: ${{parameters.flighting_release}}
    flighting_preview: ${{parameters.flighting_preview}}
    flighting_master: ${{parameters.flighting_master}}
    update_conda_package: ${{parameters.update_conda_package}}    

- template: pytest_steps.yml
  parameters:
    azureSubscription: ${{parameters.azureSubscription}}
    azure_subscription: ${{parameters.azure_subscription}}
    azureresourcegroup: ${{parameters.azureresourcegroup}}    
    workspacename: ${{parameters.workspacename}}
    azureregion: ${{parameters.azureregion}}
    aksimagename: ${{parameters.aksimagename}}
    aks_service_name: ${{parameters.aks_service_name}}
    aks_name: ${{parameters.aks_name}}
    conda: ${{parameters.conda}}
    pylint_fail: False

- template: cleanuptask.yml
  parameters:
    azureSubscription: ${{parameters.azureSubscription}}
    conda: ${{parameters.conda}}
    azureresourcegroup: ${{parameters.azureresourcegroup}}
    doCleanup: ${{parameters.doCleanup}}



parameters:
  notebook: 01_DataPrep.ipynb  # defaults for any parameters that aren't specified
  location: "x"
  azureSubscription: 'x'
  conda: MLAKSDeployAML
  azure_subscription: 'x'
  azureresourcegroup: "dcibrg"
  workspacename: "dcibws"
  azureregion: "westus"
  aksimagename: "myimage"
  aks_name: "dcibaksname"
  aks_service_name: "dcibaksserv"
  python_path: "{{cookiecutter.project_name}}"
  num_epochs: 1
  max_total_runs: 1
  acr_name: "x"
  cluster_name: "x"
  storage_account_name: "xxxxxxx"
  timeoutInMinutes: 90
  sql_server_name: "x"
  sql_database_name: "x"
  sql_username: "x"
  sql_password: "x"
  container_name: "x"
  account_name: "x"
  account_key: "x"
  datastore_rg: "x"

steps:
- task: AzureCLI@1
  displayName: ${{parameters.notebook}}
  inputs:
    azureSubscription: ${{parameters.azureSubscription}}
    scriptLocation: inlineScript
    timeoutInMinutes: ${{parameters.timeoutInMinutes}}
    failOnStderr: True
    inlineScript: |
      source activate ${{parameters.conda}}
      export PYTHONPATH=${{parameters.python_path}}:${PYTHONPATH}      
      cd ${{parameters.location}}
      echo Execute ${{parameters.notebook}}
      papermill ${{parameters.notebook}} output.ipynb \
        --log-output \
        --no-progress-bar \
        -k ${{parameters.conda}} \
        -p subscription_id ${{parameters.azure_subscription}} \
        -p resource_group ${{parameters.azureresourcegroup}} \
        -p workspace_name ${{parameters.workspacename}} \
        -p workspace_region ${{parameters.azureregion}} \
        -p image_name ${{parameters.aksimagename}} \
        -p aks_name ${{parameters.aks_name}} \
        -p aks_location ${{parameters.azureregion}} \
        -p aks_service_name ${{parameters.aks_service_name}} \
        -p max_total_runs ${{parameters.max_total_runs}} \
        -p num_epochs ${{parameters.num_epochs}} \
        -p acr_resource_group ${{parameters.azureresourcegroup}} \
        -p acr_location ${{parameters.azureregion}} \
        -p acr_name ${{parameters.acr_name}} \
        -p cluster_name ${{parameters.cluster_name}} \
        -p storage_account_name ${{parameters.storage_account_name}} \
        -p container_name ${{parameters.container_name}} \
        -p account_name ${{parameters.account_name}} \
        -p account_key ${{parameters.account_key}} \
        -p datastore_rg ${{parameters.datastore_rg}} \
        -p sql_server_name ${{parameters.sql_server_name}} \
        -p sql_database_name ${{parameters.sql_database_name}} \
        -p sql_username ${{parameters.sql_username}} \
        -p sql_password '${{parameters.sql_password}}'



parameters:
  notebooks: 01_DataPrep.ipynb  # defaults for any parameters that aren't specified
  location: "x"
  azureSubscription: 'x'
  conda: MLAKSDeployAML
  azure_subscription: 'x'
  azureresourcegroup: "dcibrg"
  workspacename: "dcibws"
  azureregion: "westus"
  aksimagename: "myimage"
  aks_name: "dcibaksname"
  aks_service_name: "dcibaksserv"
  python_path: "{{cookiecutter.project_name}}"
  num_epochs: 1
  max_total_runs: 1
  acr_name: "x"
  cluster_name: "x"
  storage_account_name: "xxxxxxx"
  timeoutInMinutes: 90
  sql_server_name: "x"
  sql_database_name: "x"
  sql_username: "x"
  sql_password: "x"
  container_name: "x"
  account_name: "x"
  account_key: "x"
  datastore_rg: "x"

steps:
- task: AzureCLI@1
  displayName: Notebooks
  inputs:
    azureSubscription: ${{parameters.azureSubscription}}
    scriptLocation: inlineScript
    timeoutInMinutes: ${{parameters.timeoutInMinutes}}
    failOnStderr: True
    inlineScript: |
      source activate ${{parameters.conda}}
      export PYTHONPATH=${{parameters.python_path}}:${PYTHONPATH}      
      cd ${{parameters.location}}
      echo Execute ${{parameters.notebook}}
      for notebook in ${{parameters.notebooks}}; do papermill $notebook output.ipynb \
        --log-output \
        --no-progress-bar \
        -k python3 \
        -p subscription_id ${{parameters.azure_subscription}} \
        -p resource_group ${{parameters.azureresourcegroup}} \
        -p workspace_name ${{parameters.workspacename}} \
        -p workspace_region ${{parameters.azureregion}} \
        -p image_name ${{parameters.aksimagename}} \
        -p aks_name ${{parameters.aks_name}} \
        -p aks_location ${{parameters.azureregion}} \
        -p aks_service_name ${{parameters.aks_service_name}} \
        -p max_total_runs ${{parameters.max_total_runs}} \
        -p num_epochs ${{parameters.num_epochs}} \
        -p acr_resource_group ${{parameters.azureresourcegroup}} \
        -p acr_location ${{parameters.azureregion}} \
        -p acr_name ${{parameters.acr_name}} \
        -p cluster_name ${{parameters.cluster_name}} \
        -p storage_account_name ${{parameters.storage_account_name}} \
        -p container_name ${{parameters.container_name}} \
        -p account_name ${{parameters.account_name}} \
        -p account_key ${{parameters.account_key}} \
        -p datastore_rg ${{parameters.datastore_rg}} \
        -p sql_server_name ${{parameters.sql_server_name}} \
        -p sql_database_name ${{parameters.sql_database_name}} \
        -p sql_username ${{parameters.sql_username}} \
        -p sql_password '${{parameters.sql_password}}'; done


parameters:
  notebook: # defaults for any parameters that aren't specified
  location: "."
  azureSubscription: 'x'
  azure_subscription: 'x'
  timeoutInMinutes: 90

steps:
- task: AzureCLI@1
  displayName: ${{parameters.notebook}}
  inputs:
    azureSubscription: ${{parameters.azureSubscription}}
    scriptLocation: inlineScript
    timeoutInMinutes: ${{parameters.timeoutInMinutes}}
    failOnStderr: True
    inlineScript: |
      cd ${{parameters.location}}
      echo Execute ${{parameters.notebook}}
      pwd
      ls
      Rscript ./${{parameters.notebook}}


parameters:
  notebook: # defaults for any parameters that aren't specified
  location: "."
  azureSubscription: 'x'
  azure_subscription: 'x'
  timeoutInMinutes: 90

steps:
- bash: |
    cd ${{parameters.location}}
    echo Execute ${{parameters.notebook}}
    Rscript ./${{parameters.notebook}}
  timeoutInMinutes: ${{parameters.timeoutInMinutes}}
  displayName: ${{parameters.notebook}}

parameters:
  azureSubscription: 'AICAT-VB-E2E (989b90f7-da4f-41f9-84c9-44848802052d)'
  conda: MLAKSDeployAML
  azureresourcegroup: "-"
  doCleanup : true


steps:
- task: AzureCLI@1
  displayName: "Cleanup Task"
  condition:  and(always(), eq('${{parameters.doCleanup}}','true'))
  inputs:
    azureSubscription: ${{parameters.azureSubscription}}
    scriptLocation: inlineScript
    inlineScript: |
      echo Execute Resource Group Delete
      existResponse=$(az group exists -n ${{parameters.azureresourcegroup}})
      if [ "$existResponse" == "true" ]; then
        echo Deleting project resource group
        az group delete --name ${{parameters.azureresourcegroup}} --yes --no-wait
      else
        echo Project resource group did not exist
      fi
      echo Done Cleanup

# AI Architecture
#
# A Github Service Connection must also be created with the name "AIArchitecturesAndPractices-GitHub"
# https://docs.microsoft.com/en-us/azure/devops/pipelines/process/demands?view=azure-devops&tabs=yaml
#
# An Agent_Name Variable must be creating in the Azure DevOps UI.
# https://docs.microsoft.com/en-us/azure/devops/pipelines/process/variables?view=azure-devops&tabs=yaml%2Cbatch#secret-variables
#
# This must point to an Agent Pool, with a Self-Hosted Linux VM with a Docker.
# https://docs.microsoft.com/en-us/azure/devops/pipelines/agents/v2-linux?view=azure-devops

parameters:
  azureSubscription: ''
  azure_subscription: ''
  azureresourcegroup: ''
  workspacename: ''
  azureregion: westus2
  aksimagename: ''
  aks_name: ''
  aks_service_name: myimage
  conda: ''
  doCleanup: true
  flighting_release: false
  flighting_preview: false
  flighting_master: false
  fresh_install: false

steps:
- template: config_conda.yml
  parameters:
    conda_location: .
    azureSubscription: ${{parameters.azureSubscription}}
    conda: ai-architecture-template
    flighting_release: ${{parameters.flighting_release}}
    flighting_preview: ${{parameters.flighting_preview}}
    flighting_master: ${{parameters.flighting_master}}
    fresh_install: ${{parameters.fresh_install}}

- template: pytest_steps.yml
  parameters:
    azureSubscription: ${{parameters.azureSubscription}}
    azure_subscription: ${{parameters.azure_subscription}}
    azureresourcegroup: ${{parameters.azureresourcegroup}}    
    workspacename: aiarchtemplate
    conda: ai-architecture-template
    azureregion: ${{parameters.azureregion}}

- template: cleanuptask.yml
  parameters:
    azureSubscription: ${{parameters.azureSubscription}}
    azure_subscription: ${{parameters.azure_subscription}}
    conda: ai-architecture-template
    azureresourcegroup: ${{parameters.azureresourcegroup}}
    doCleanup: ${{parameters.doCleanup}}

# AI Architecture Template TODO: update tile
#
# A Github Service Connection must also be created with the name "AIArchitecturesAndPractices-GitHub"
# https://docs.microsoft.com/en-us/azure/devops/pipelines/process/demands?view=azure-devops&tabs=yaml
#
# An Agent_Name Variable must be creating in the Azure DevOps UI.
# https://docs.microsoft.com/en-us/azure/devops/pipelines/process/variables?view=azure-devops&tabs=yaml%2Cbatch#secret-variables
#
# This must point to an Agent Pool, with a Self-Hosted Linux VM with a Docker.
# https://docs.microsoft.com/en-us/azure/devops/pipelines/agents/v2-linux?view=azure-devops

parameters:
  azureSubscription: ''
  azure_subscription: ''
  azureresourcegroup: ''
  workspacename: ''
  azureregion: westus2
  aksimagename: myimage
  aks_name: akscluster
  aks_service_name: aksservice
  conda: ''
  doCleanup: true
  flighting_release: false
  flighting_preview: false
  flighting_master: false
  fresh_install: false
  sql_server_name: "x"
  sql_database_name: "x"
  sql_username: "x"
  sql_password: "x"
  datastore_rg: "x"
  container_name: "x"
  account_name: "x"
  account_key: "x"

steps:
- template: config_conda.yml
  parameters:
    conda_location: .
    azureSubscription: ${{parameters.azureSubscription}}
    conda: ${{parameters.conda}}
    flighting_release: ${{parameters.flighting_release}}
    flighting_preview: ${{parameters.flighting_preview}}
    flighting_master: ${{parameters.flighting_master}}
    fresh_install: ${{parameters.fresh_install}}

- template: pytest_steps.yml
  parameters:
    azureSubscription: ${{parameters.azureSubscription}}
    azure_subscription: ${{parameters.azure_subscription}}
    azureresourcegroup: ${{parameters.azureresourcegroup}}    
    workspacename: ${{parameters.workspacename}}
    conda: ${{parameters.conda}}
    azureregion: ${{parameters.azureregion}}
    sql_server_name: ${{parameters.sql_server_name}}
    sql_database_name: ${{parameters.sql_database_name}}
    sql_username: ${{parameters.sql_username}}
    sql_password: ${{parameters.sql_password}}
    aksimagename: ${{parameters.aksimagename}}
    aks_service_name: ${{parameters.aks_service_name}}
    aks_name: ${{parameters.aks_name}}
    datastore_rg: ${{parameters.datastore_rg}}
    container_name: ${{parameters.container_name}}
    account_name: ${{parameters.account_name}}
    account_key: ${{parameters.account_key}}

- template: cleanuptask.yml
  parameters:
    azureSubscription: ${{parameters.azureSubscription}}
    azure_subscription: ${{parameters.azure_subscription}}
    conda: ${{parameters.conda}}
    azureresourcegroup: ${{parameters.azureresourcegroup}}
    doCleanup: ${{parameters.doCleanup}}

  
parameters:
  conda_location: .
  azureSubscription: #
  conda: #
  backward_compatability: false
  backward_version: 1.0.2
  flighting_release: false
  flighting_preview: false
  flighting_master: false
  fresh_install: true
  update_conda: false
  update_conda_package: true
  ubuntu18: true
  off: false

steps:
- bash: echo "##vso[task.prependpath]/anaconda/bin"
  displayName: Add conda to PATH

- task: AzureCLI@1
  displayName: 'Update Conda'
  condition: eq('${{ parameters.update_conda }}', true)
  inputs:
    azureSubscription: ${{parameters.azureSubscription}}
    failOnStandardError: True
    scriptLocation: inlineScript
    inlineScript: |
      conda update --force-reinstall -y -n base -c defaults conda
      
- task: AzureCLI@1
  displayName: 'Create New Conda'
  condition: eq('${{ parameters.off }}', true)
  inputs:
    azureSubscription: ${{parameters.azureSubscription}}
    failOnStandardError: True
    scriptLocation: inlineScript
    inlineScript: |
      conda config --set notify_outdated_conda false

      conda env create --force --file ${{parameters.conda_location}}/environment.yml python=3.6
      source activate ${{parameters.conda}}
      python -m ipykernel install --prefix=/data/anaconda/envs/${{parameters.conda}} --name ${{parameters.conda}}

- task: AzureCLI@1
  displayName: 'Upgrade Existing or Create New Conda'
  condition: eq('${{ parameters.off }}', true)
  inputs:
    azureSubscription: ${{parameters.azureSubscription}}
    failOnStandardError: True
    scriptLocation: inlineScript
    inlineScript: |
      conda config --set notify_outdated_conda false
      conda env create --force --file ${{parameters.conda_location}}/environment.yml python=3.7.4
      source activate ${{parameters.conda}}
      python -m ipykernel install --prefix=/data/anaconda/envs/${{parameters.conda}} --name ${{parameters.conda}}

- task: AzureCLI@1
  displayName: 'U18 Upgrade Existing or Create New Conda'
  condition: eq('${{ parameters.ubuntu18 }}', true)
  inputs:
    azureSubscription: ${{parameters.azureSubscription}}
    failOnStandardError: True
    scriptLocation: inlineScript
    inlineScript: |
      conda config --set notify_outdated_conda false
      conda env create --force --file ${{parameters.conda_location}}/environment.yml python=3.7.4
      source activate ${{parameters.conda}}


- task: AzureCLI@1
  displayName: 'Upgrade AML SDK to latest release'
  condition: eq('${{ parameters.flighting_release }}', true)
  inputs:
    azureSubscription: ${{parameters.azureSubscription}}
    failOnStandardError: True
    scriptLocation: inlineScript
    inlineScript: |
      source activate ${{parameters.conda}}

      pip install -U azureml-core azureml-contrib-services azureml-pipeline
      
- task: AzureCLI@1
  displayName: 'Upgrade AML SDK to Candidate release'
  condition: eq('${{ parameters.flighting_preview }}', true)
  inputs:
    azureSubscription: ${{parameters.azureSubscription}}
    failOnStandardError: True
    scriptLocation: inlineScript
    inlineScript: |
      source activate ${{parameters.conda}}
      
      pip install -U azureml-core azureml-contrib-services azureml-pipeline \
        --extra-index-url https://azuremlsdktestpypi.azureedge.net/sdk-release/Candidate/604C89A437BA41BD942B4F46D9A3591D

- task: AzureCLI@1
  displayName: 'Upgrade AML SDK to master release'
  condition: eq('${{ parameters.flighting_master }}', true)
  inputs:
    azureSubscription: ${{parameters.azureSubscription}}
    failOnStandardError: True
    scriptLocation: inlineScript
    inlineScript: |
      source activate ${{parameters.conda}}   

      pip install -U "azureml-core<0.1.5" "azureml-contrib-services<0.1.5" "azureml-pipeline<0.1.5" \
        --extra-index-url https://azuremlsdktestpypi.azureedge.net/sdk-release/master/588E708E0DF342C4A80BD954289657CF

parameters:
  tenant: 72f988bf-86f1-41af-91ab-2d7cd011db47
  azureresourcegroup: "rmlrts"
  workspacename: "rmlrtsws"
  azureregion: "eastus"
  aksimagename: "myimage"
  aks_name: "rmlrtsaks"
  aks_service_name: "rmlrts"
  acr_name: "rmlrtsacr"
  CRAN: 'https://cloud.r-project.org'
  R_LIBS_USER: '$(Agent.BuildDirectory)/R/library'
  azure_subscription: #
  sp_appid: #
  sp_password: #
  
steps:
- script: sudo apt-get update && sudo apt-get install -y libxml2-dev libssl-dev
  displayName: "Install System Dependencies"

- bash: |
    echo "options(repos = '${{parameters.CRAN}}')" > ~/.Rprofile
    echo ".libPaths(c('${{parameters.R_LIBS_USER}}', .libPaths()))" >> ~/.Rprofile
    mkdir -p ${{parameters.R_LIBS_USER}}
  displayName: 'Setup R library directory'

- bash: |
    Rscript -e "pkgs <- c('remotes', 'rcmdcheck', 'drat', 'AzureGraph', 'AzureRMR', 'AzureContainers'); if(length(find.package(pkgs, quiet=TRUE)) != length(pkgs)) install.packages(pkgs)"
    Rscript -e "remotes::install_deps(dependencies=TRUE)"
  displayName: 'Installing package dependencies'

- bash: |
    sed -i -e 's/your AAD tenant here/${{parameters.tenant}}/g' resource_specs.R
    sed -i -e 's/your subscription here/${{parameters.azure_subscription}}/g' resource_specs.R
    sed -i -e 's/resource group name/${{parameters.azureresourcegroup}}/g' resource_specs.R
    sed -i -e 's/resource group location/${{parameters.azureregion}}/g' resource_specs.R
    sed -i -e 's/container registry name/${{parameters.acr_name}}/g' resource_specs.R
    sed -i -e 's/cluster name/${{parameters.aks_name}}/g' resource_specs.R
    sed -i -e 's/your ap id/${{parameters.sp_appid}}/g' resource_specs.R
    sed -i -e 's/stop("Must specify a password!")/"${{parameters.sp_password}}"/g' resource_specs.R
  displayName: 'Setup R parameters'

# AI Architecture Template TODO: update tile
#
# A Github Service Connection must also be created with the name "AIArchitecturesAndPractices-GitHub"
# https://docs.microsoft.com/en-us/azure/devops/pipelines/process/demands?view=azure-devops&tabs=yaml
#
# An Agent_Name Variable must be creating in the Azure DevOps UI.
# https://docs.microsoft.com/en-us/azure/devops/pipelines/process/variables?view=azure-devops&tabs=yaml%2Cbatch#secret-variables
#
# This must point to an Agent Pool, with a Self-Hosted Linux VM with a Docker.
# https://docs.microsoft.com/en-us/azure/devops/pipelines/agents/v2-linux?view=azure-devops

parameters:
  azureSubscription: ''
  azure_subscription: ''
  azureresourcegroup: ''
  workspacename: ''
  azureregion: westus2
  aksimagename: myimage
  aks_name: akscluster
  aks_service_name: aksservice
  conda: ''
  doCleanup: true
  flighting_release: false
  flighting_preview: false
  flighting_master: false
  fresh_install: false
  sql_server_name: "x"
  sql_database_name: "x"
  sql_username: "x"
  sql_password: "x"
  datastore_rg: "x"
  container_name: "x"
  account_name: "x"
  account_key: "x"

steps:
- template: config_conda.yml
  parameters:
    conda_location: .
    azureSubscription: ${{parameters.azureSubscription}}
    conda: ${{parameters.conda}}
    flighting_release: ${{parameters.flighting_release}}
    flighting_preview: ${{parameters.flighting_preview}}
    flighting_master: ${{parameters.flighting_master}}
    fresh_install: ${{parameters.fresh_install}}

- template: pytest_steps.yml
  parameters:
    azureSubscription: ${{parameters.azureSubscription}}
    azure_subscription: ${{parameters.azure_subscription}}
    azureresourcegroup: ${{parameters.azureresourcegroup}}    
    workspacename: ${{parameters.workspacename}}
    conda: ${{parameters.conda}}
    azureregion: ${{parameters.azureregion}}
    sql_server_name: ${{parameters.sql_server_name}}
    sql_database_name: ${{parameters.sql_database_name}}
    sql_username: ${{parameters.sql_username}}
    sql_password: ${{parameters.sql_password}}
    aksimagename: ${{parameters.aksimagename}}
    aks_service_name: ${{parameters.aks_service_name}}
    aks_name: ${{parameters.aks_name}}
    datastore_rg: ${{parameters.datastore_rg}}
    container_name: ${{parameters.container_name}}
    account_name: ${{parameters.account_name}}
    account_key: ${{parameters.account_key}}

- template: cleanuptask.yml
  parameters:
    azureSubscription: ${{parameters.azureSubscription}}
    azure_subscription: ${{parameters.azure_subscription}}
    conda: ${{parameters.conda}}
    azureresourcegroup: ${{parameters.azureresourcegroup}}
    doCleanup: ${{parameters.doCleanup}}

  
parameters:
  conda_location: .
  azureSubscription: #
  conda: #
  backward_compatability: false
  backward_version: 1.0.2
  flighting_release: false
  flighting_preview: false
  flighting_master: false
  fresh_install: true
  update_conda: false
  update_conda_package: true
  ubuntu18: true
  off: false

steps:
- bash: echo "##vso[task.prependpath]/anaconda/bin"
  displayName: Add conda to PATH

- task: AzureCLI@1
  displayName: 'Update Conda'
  condition: eq('${{ parameters.update_conda }}', true)
  inputs:
    azureSubscription: ${{parameters.azureSubscription}}
    failOnStandardError: True
    scriptLocation: inlineScript
    inlineScript: |
      conda update --force-reinstall -y -n base -c defaults conda
      
- task: AzureCLI@1
  displayName: 'Create New Conda'
  condition: eq('${{ parameters.off }}', true)
  inputs:
    azureSubscription: ${{parameters.azureSubscription}}
    failOnStandardError: True
    scriptLocation: inlineScript
    inlineScript: |
      conda config --set notify_outdated_conda false

      conda env create --force --file ${{parameters.conda_location}}/environment.yml python=3.6
      source activate ${{parameters.conda}}
      python -m ipykernel install --prefix=/data/anaconda/envs/${{parameters.conda}} --name ${{parameters.conda}}

- task: AzureCLI@1
  displayName: 'Upgrade Existing or Create New Conda'
  condition: eq('${{ parameters.off }}', true)
  inputs:
    azureSubscription: ${{parameters.azureSubscription}}
    failOnStandardError: True
    scriptLocation: inlineScript
    inlineScript: |
      conda config --set notify_outdated_conda false
      conda env create --force --file ${{parameters.conda_location}}/environment.yml python=3.7.4
      source activate ${{parameters.conda}}
      python -m ipykernel install --prefix=/data/anaconda/envs/${{parameters.conda}} --name ${{parameters.conda}}

- task: AzureCLI@1
  displayName: 'U18 Upgrade Existing or Create New Conda'
  condition: eq('${{ parameters.ubuntu18 }}', true)
  inputs:
    azureSubscription: ${{parameters.azureSubscription}}
    failOnStandardError: True
    scriptLocation: inlineScript
    inlineScript: |
      conda config --set notify_outdated_conda false
      conda env create --force --file ${{parameters.conda_location}}/environment.yml python=3.7.4
      source activate ${{parameters.conda}}


- task: AzureCLI@1
  displayName: 'Upgrade AML SDK to latest release'
  condition: eq('${{ parameters.flighting_release }}', true)
  inputs:
    azureSubscription: ${{parameters.azureSubscription}}
    failOnStandardError: True
    scriptLocation: inlineScript
    inlineScript: |
      source activate ${{parameters.conda}}

      pip install -U azureml-core azureml-contrib-services azureml-pipeline
      
- task: AzureCLI@1
  displayName: 'Upgrade AML SDK to Candidate release'
  condition: eq('${{ parameters.flighting_preview }}', true)
  inputs:
    azureSubscription: ${{parameters.azureSubscription}}
    failOnStandardError: True
    scriptLocation: inlineScript
    inlineScript: |
      source activate ${{parameters.conda}}
      
      pip install -U azureml-core azureml-contrib-services azureml-pipeline \
        --extra-index-url https://azuremlsdktestpypi.azureedge.net/sdk-release/Candidate/604C89A437BA41BD942B4F46D9A3591D

- task: AzureCLI@1
  displayName: 'Upgrade AML SDK to master release'
  condition: eq('${{ parameters.flighting_master }}', true)
  inputs:
    azureSubscription: ${{parameters.azureSubscription}}
    failOnStandardError: True
    scriptLocation: inlineScript
    inlineScript: |
      source activate ${{parameters.conda}}   

      pip install -U "azureml-core<0.1.5" "azureml-contrib-services<0.1.5" "azureml-pipeline<0.1.5" \
        --extra-index-url https://azuremlsdktestpypi.azureedge.net/sdk-release/master/588E708E0DF342C4A80BD954289657CF

parameters:
  tenant: 72f988bf-86f1-41af-91ab-2d7cd011db47
  azureresourcegroup: "rmlrts"
  workspacename: "rmlrtsws"
  azureregion: "eastus"
  aksimagename: "myimage"
  aks_name: "rmlrtsaks"
  aks_service_name: "rmlrts"
  acr_name: "rmlrtsacr"
  CRAN: 'https://cloud.r-project.org'
  R_LIBS_USER: '$(Agent.BuildDirectory)/R/library'
  azure_subscription: #
  sp_appid: #
  sp_password: #
  
steps:
- script: sudo apt-get update && sudo apt-get install -y libxml2-dev libssl-dev
  displayName: "Install System Dependencies"

- bash: |
    echo "options(repos = '${{parameters.CRAN}}')" > ~/.Rprofile
    echo ".libPaths(c('${{parameters.R_LIBS_USER}}', .libPaths()))" >> ~/.Rprofile
    mkdir -p ${{parameters.R_LIBS_USER}}
  displayName: 'Setup R library directory'

- bash: |
    Rscript -e "pkgs <- c('remotes', 'rcmdcheck', 'drat', 'AzureGraph', 'AzureRMR', 'AzureContainers'); if(length(find.package(pkgs, quiet=TRUE)) != length(pkgs)) install.packages(pkgs)"
    Rscript -e "remotes::install_deps(dependencies=TRUE)"
  displayName: 'Installing package dependencies'

- bash: |
    sed -i -e 's/your AAD tenant here/${{parameters.tenant}}/g' resource_specs.R
    sed -i -e 's/your subscription here/${{parameters.azure_subscription}}/g' resource_specs.R
    sed -i -e 's/resource group name/${{parameters.azureresourcegroup}}/g' resource_specs.R
    sed -i -e 's/resource group location/${{parameters.azureregion}}/g' resource_specs.R
    sed -i -e 's/container registry name/${{parameters.acr_name}}/g' resource_specs.R
    sed -i -e 's/cluster name/${{parameters.aks_name}}/g' resource_specs.R
    sed -i -e 's/your ap id/${{parameters.sp_appid}}/g' resource_specs.R
    sed -i -e 's/stop("Must specify a password!")/"${{parameters.sp_password}}"/g' resource_specs.R
  displayName: 'Setup R parameters'

parameters:
  azureSubscription: ''
  azure_subscription: ''
  location: submodules/DeployMLModelPipelines
  azureresourcegroup: dcibhpdl
  workspacename: dcibhpwsdl
  azureregion: westus2
  aksimagename: dcibhpaksdl
  aks_name: dcibhpaksdl
  aks_service_name: dcibhpaksdlapi
  conda: TorchDetectAML
  doCleanup: true
  python_path: "$(System.DefaultWorkingDirectory)/submodules/DeployMLModelPipelines"
  cluster_name: "aidltraincompute"
  acr_name: "aidltrainacr"
  flighting_release: false
  flighting_preview: false

steps:
- template: config_conda.yml
  parameters:
    conda_location: ${{parameters.location}}
    azureSubscription: ${{parameters.azureSubscription}}
    conda: ${{parameters.conda}}
    flighting_release: ${{parameters.flighting_release}}
    flighting_preview: ${{parameters.flighting_preview}}

- bash: |
    wget https://bostondata.blob.core.windows.net/builddata/Data.zip
    unzip Data.zip
    mv ./Data/JPEGImages ./scripts/
    mv ./Data/Annotations ./scripts/

- template: azpapermill.yml
  parameters:
    notebook: 00_AMLConfiguration.ipynb
    location: ${{parameters.location}}
    azureSubscription: ${{parameters.azureSubscription}}
    conda: ${{parameters.conda}}
    azure_subscription: ${{parameters.azure_subscription}}
    azureresourcegroup: ${{parameters.azureresourcegroup}}
    workspacename: ${{parameters.workspacename}}
    azureregion: ${{parameters.azureregion}}
    acr_name: ${{parameters.acr_name}}

- template: azpapermill.yml
  parameters:
    notebook: 01_PrepareTrainingScript.ipynb
    location: ${{parameters.location}}
    azureSubscription: ${{parameters.azureSubscription}}
    conda: ${{parameters.conda}}
    azure_subscription: ${{parameters.azure_subscription}}
    azureresourcegroup: ${{parameters.azureresourcegroup}}
    workspacename: ${{parameters.workspacename}}
    azureregion: ${{parameters.azureregion}}

- template: azpapermill.yml
  parameters:
    notebook: 02_PytorchEstimatorLocalRun.ipynb
    location: ${{parameters.location}}
    azureSubscription: ${{parameters.azureSubscription}}
    conda: ${{parameters.conda}}
    num_epochs: 1
    
- template: azpapermill.yml
  parameters:
    notebook: 03_BuildDockerImage.ipynb
    location: ${{parameters.location}}
    azureSubscription: ${{parameters.azureSubscription}}
    conda: ${{parameters.conda}}
    image_name: 'torchdet' 
    acr_resource_group: ${{parameters.azureresourcegroup}}
    acr_location: ${{parameters.azureregion}}
    acr_name: ${{parameters.acr_name}}
    
- template: azpapermill.yml
  parameters:
    notebook: 04_TuneHyperparameters.ipynb
    location: ${{parameters.location}}
    azureSubscription: ${{parameters.azureSubscription}}
    conda: ${{parameters.conda}}  
    num_epochs: 1
    max_total_runs: 2
    cluster_name: ${{parameters.cluster_name}}
    azureresourcegroup: ${{parameters.azureresourcegroup}}

- template: cleanuptask.yml
  parameters:
    azureSubscription: ${{parameters.azureSubscription}}
    conda: deployment_aml
    azureresourcegroup: ${{parameters.azureresourcegroup}}
    doCleanup: ${{parameters.doCleanup}}

steps:
  - script: |
      docker stop $(docker ps -a -q)
      docker rm $(docker ps -a -q)
      docker system prune -a -f
    displayName: 'Docker Clean'

steps:
- script: |
    docker stop $(docker ps -a -q)
    docker rm $(docker ps -a -q)
    docker system prune -a -f
  displayName: 'Clean Docker Resources on Machine'
