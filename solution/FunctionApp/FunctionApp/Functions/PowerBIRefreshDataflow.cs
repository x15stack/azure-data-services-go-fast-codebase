/*-----------------------------------------------------------------------

 Copyright (c) Microsoft Corporation.
 Licensed under the MIT license.

-----------------------------------------------------------------------*/

using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Net.Http;
using System.Text.RegularExpressions;
using System.Threading.Tasks;
using FunctionApp.Authentication;
using FunctionApp.DataAccess;
using FunctionApp.Models;
using FunctionApp.Models.Options;
using FunctionApp.Services;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Azure.Management.Compute.Fluent;
using Microsoft.Azure.Management.Fluent;
using Microsoft.Azure.Management.ResourceManager.Fluent.Core;
using Microsoft.Azure.WebJobs;
using Microsoft.Azure.WebJobs.Extensions.Http;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;
using Newtonsoft.Json;
using Newtonsoft.Json.Linq;

namespace FunctionApp.Functions
{
    public class PowerBIRefreshDataflow
    {
        private readonly PowerBIService _powerBIService;
        private readonly ApplicationOptions _options;
        private Logging.Logging _funcAppLogger = new Logging.Logging();

        public PowerBIRefreshDataflow(IOptions<ApplicationOptions> options, PowerBIService powerBIService)
        {
            _powerBIService = powerBIService;
            _options = options?.Value;
        }
        [FunctionName("PowerBIRefreshDataflow")]
        public IActionResult Run([HttpTrigger(AuthorizationLevel.Anonymous, "post", Route = null)] HttpRequest req, ILogger log, ExecutionContext context)
        {
            var executionId = System.Guid.NewGuid();
            ActivityLogItem activityLogItem = new ActivityLogItem
            {
                LogSource = "AF",
                ExecutionUid = executionId
            };
            _funcAppLogger.InitializeLog(log, activityLogItem);

            string requestBody = new StreamReader(req.Body).ReadToEndAsync().Result;
            JObject taskObject = JsonConvert.DeserializeObject<JObject>(requestBody);
            string clientId = taskObject["Source"]["System"]["ClientId"].ToString();
            string secretName = taskObject["Source"]["System"]["ClientSecretName"].ToString();
            string tenantId = taskObject["Source"]["System"]["TenantId"].ToString();
            string dataflowName = taskObject["Source"]["DataflowName"].ToString();
            string workspaceId = taskObject["Source"]["WorkspaceId"].ToString();
            string keyvaultURL = taskObject["KeyVaultBaseUrl"].ToString();

            var result = (_powerBIService.RefreshDataflow(clientId, secretName, tenantId, dataflowName, workspaceId, keyvaultURL, _funcAppLogger).Result);

            if (!string.IsNullOrEmpty(result))
            {
                taskObject.Add(new JProperty("TransactionId", result));

                return new OkObjectResult(taskObject);
            }
            else
            {
                return new BadRequestObjectResult(new { Error = "Execution Failed: No result from dataflow refresh" });
            }



        }

    }
}
