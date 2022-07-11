using Microsoft.Azure.Management.Synapse;
using System;
using System.Collections.Generic;
using System.Threading.Tasks;
using FunctionApp.Authentication;
using FunctionApp.Models.Options;
using Microsoft.Extensions.Options;
using Microsoft.Rest;
using System.Net.Http.Headers;
using Newtonsoft.Json;
using Newtonsoft.Json.Linq;
using System.Net.Http;
using Azure.Analytics.Synapse.Artifacts;
using Azure.Core;
using Microsoft.Azure.Management.DataFactory.Models;
using System.Linq;
using FunctionApp.Functions;
using FunctionApp.DataAccess;
using System.IO;
using Microsoft.PowerBI.Api;
using Microsoft.Identity.Client;

namespace FunctionApp.Services
{
    public class PowerBIService
    {
        private readonly MicrosoftAzureServicesAppAuthenticationProvider _authProvider;
        private readonly IOptions<FunctionApp.Models.Options.ApplicationOptions> _options;
        private readonly TaskMetaDataDatabase _taskMetaDataDatabase;
        private readonly KeyVaultService _keyVaultService;

        public PowerBIService(MicrosoftAzureServicesAppAuthenticationProvider authProvider, IOptions<FunctionApp.Models.Options.ApplicationOptions> options, TaskMetaDataDatabase taskMetaDataDatabase, KeyVaultService keyVaultService)
        {
            _authProvider = authProvider;
            _options = options;
            _taskMetaDataDatabase = taskMetaDataDatabase;
            _keyVaultService = keyVaultService;
        }
        public async Task RefreshDataflow(string ClientId, string SecretName, string TenantId, string DataflowName, string WorkspaceId, string KeyVaultURL, Logging.Logging logging)
        {
            try
            {
                // get secret from keyvault using secretName
                var secret = await _keyVaultService.RetriveSecret(SecretName, KeyVaultURL, logging);
                // Make a client call if Access token is not available in cache
                var authenticationResult = await _authProvider.GetPowerBIRestApiToken(ClientId, secret, TenantId);

                TokenCredentials tokenCredentials = new TokenCredentials(authenticationResult, "Bearer");


                //the request requires a 'Refresh Request' stating 'yes'
                Microsoft.PowerBI.Api.Models.RefreshRequest refreshRequest;
                refreshRequest = new Microsoft.PowerBI.Api.Models.RefreshRequest("y");

                //defining the powerBI client with our token
                PowerBIClient powerBIClient = new PowerBIClient(new Uri("https://api.powerbi.com"), tokenCredentials);

                //defining our workspace / setting a blank guid for dataflowid 
                Guid workspaceId = Guid.Parse(WorkspaceId);
                Guid dataflowId;


                logging.LogInformation($"Attempting to find: {DataflowName}");
                try
                {
                    var dataflows = await powerBIClient.Dataflows.GetDataflowsAsync(workspaceId);
                    var dataflow = dataflows.Value.FirstOrDefault(x => x.Name == DataflowName);
                    dataflowId = dataflow.ObjectId;

                }
                catch (Exception e)
                {
                    Exception error = new Exception($"Error has occured finding: {DataflowName}");
                    logging.LogErrors(error);
                    logging.LogErrors(e);

                    throw error;
                }
                logging.LogInformation($"Attempting to refresh dataflow: {DataflowName}");
                try
                {
                    //await powerBIClient.Dataflows.RefreshDataflowAsync(workspace, dataflowId);
                    //if this is waiting until the refresh is complete we may want to remove the 'await'
                    await powerBIClient.Dataflows.RefreshDataflowAsync(workspaceId, dataflowId, refreshRequest);
                }
                catch (Exception e)
                {
                    Exception error = new Exception($"Error has occured refreshing dataflow: {DataflowName}");
                    logging.LogErrors(error);
                    logging.LogErrors(e);
                    throw error;
                }
                logging.LogInformation($"Dataflow {DataflowName} has been refreshed.");

            }
            catch (Exception e)
            {
                logging.LogErrors(e);
                logging.LogErrors(new Exception($"Initiation of Dataflow Refresh command failed for DataflowId: {DataflowName} and Workspace: {WorkspaceId}"));
                throw;

            }
        }
    }
}
