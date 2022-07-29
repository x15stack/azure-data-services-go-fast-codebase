function(GenerateArm="false",GFPIR="", SparkPoolName = "")
local name =  "GPL_ExecuteAndCheckFunctions_Primary_" + GFPIR;
local Wrapper = import '../static/partials/wrapper.libsonnet';
local ActivityName = "ExecuteAndCheckFunctions";

local Folder =  if(GenerateArm=="false") 
					then "ADS Go Fast/Data Movement/ExecuteAndCheckFunctions/" + GFPIR +"/"
					else "[concat('ADS Go Fast/Data Movement/ExecuteAndCheckFunctions/', parameters('integrationRuntimeShortName'), '/')]";

local pipeline = 
{
    "name": name,
    "properties": {
        "activities": [
            {
                "name": "Poll For Check Complete",
                "type": "Until",
                "dependsOn": [
                    {
                        "activity": "Execute Function",
                        "dependencyConditions": [
                            "Succeeded"
                        ]
                    }
                ],
                "userProperties": [],
                "typeProperties": {
                    "expression": {
                        "value": "@equals(\n    variables('CheckComplete'),\n    bool('true')\n)",
                        "type": "Expression"
                    },
                    "activities": [
                        {
                            "name": "Mark Check Function As Complete - Success",
                            "type": "SetVariable",
                            "dependsOn": [
                                {
                                    "activity": "Check Function",
                                    "dependencyConditions": [
                                        "Succeeded"
                                    ]
                                }
                            ],
                            "userProperties": [],
                            "typeProperties": {
                                "variableName": "CheckComplete",
                                "value": {
                                    "value": "@if(\n    equals(\n            activity('Check Function').output.Result,\n            'Success'\n        ),\n        bool('true'),\n        bool('false')\n    )",
                                    "type": "Expression"
                                }
                            }
                        },
                        {
                            "name": "Check Function",
                            "type": "AzureFunctionActivity",
                            "dependsOn": [],
                            "policy": {
                                "timeout": "7.00:00:00",
                                "retry": 0,
                                "retryIntervalInSeconds": 30,
                                "secureOutput": false,
                                "secureInput": false
                            },
                            "userProperties": [],
                            "typeProperties": {
                                "functionName": {
                                    "value": "@string(json(string(pipeline().parameters.TaskObject)).TMOptionals.FunctionToCheck)",
                                    "type": "Expression"
                                },
                                "method": "POST",
                                "body": {
                                    "value": "@activity('Execute Function').output",
                                    "type": "Expression"
                                }
                            },
                            "linkedServiceName": {
                                "referenceName": "SLS_AzureFunctionApp",
                                "type": "LinkedServiceReference"
                            }
                        },
                        {
                            "name": "Wait1",
                            "type": "Wait",
                            "dependsOn": [
                                {
                                    "activity": "Mark Check Function As Complete - Success",
                                    "dependencyConditions": [
                                        "Succeeded"
                                    ]
                                }
                            ],
                            "userProperties": [],
                            "typeProperties": {
                                "waitTimeInSeconds": 60
                            }
                        },
                        {
                            "name": "Failure due to Status",
                            "type": "Fail",
                            "dependsOn": [
                                {
                                    "activity": "Mark Check Function as Complete - Failed",
                                    "dependencyConditions": [
                                        "Succeeded"
                                    ]
                                }
                            ],
                            "userProperties": [],
                            "typeProperties": {
                                "message": "Check Function completed successfully - Status of returned object is 'Failed'",
                                "errorCode": "0"
                            }
                        },
                        {
                            "name": "Mark Check Function as Complete - Failed Function",
                            "type": "SetVariable",
                            "dependsOn": [
                                {
                                    "activity": "Check Function",
                                    "dependencyConditions": [
                                        "Failed"
                                    ]
                                }
                            ],
                            "userProperties": [],
                            "typeProperties": {
                                "variableName": "CheckComplete",
                                "value": {
                                    "value": "@bool('true')",
                                    "type": "Expression"
                                }
                            }
                        },
                        {
                            "name": "Mark Check Function as Complete - Failed",
                            "type": "SetVariable",
                            "dependsOn": [
                                {
                                    "activity": "Check Function",
                                    "dependencyConditions": [
                                        "Succeeded"
                                    ]
                                }
                            ],
                            "userProperties": [],
                            "typeProperties": {
                                "variableName": "CheckComplete",
                                "value": {
                                    "value": "@if(\n    equals(\n            activity('Check Function').output.Result,\n            'Failed'\n        ),\n        bool('true'),\n        bool('false')\n    )",
                                    "type": "Expression"
                                }
                            }
                        },
                        {
                            "name": "Failure due to execution error",
                            "type": "Fail",
                            "dependsOn": [
                                {
                                    "activity": "Mark Check Function as Complete - Failed Function",
                                    "dependencyConditions": [
                                        "Succeeded"
                                    ]
                                }
                            ],
                            "userProperties": [],
                            "typeProperties": {
                                "message": "Check Function execution failed",
                                "errorCode": "0"
                            }
                        }
                    ],
                    "timeout": "0.02:00:00"
                }
            },
            {
                "name": "Execute Function",
                "type": "AzureFunctionActivity",
                "dependsOn": [],
                "policy": {
                    "timeout": "7.00:00:00",
                    "retry": 0,
                    "retryIntervalInSeconds": 30,
                    "secureOutput": false,
                    "secureInput": false
                },
                "userProperties": [],
                "typeProperties": {
                    "functionName": {
                        "value": "@string(json(string(pipeline().parameters.TaskObject)).TMOptionals.FunctionToExecute)",
                        "type": "Expression"
                    },
                    "method": "POST",
                    "body": {
                        "value": "@pipeline().parameters.TaskObject",
                        "type": "Expression"
                    }
                },
                "linkedServiceName": {
                    "referenceName": "SLS_AzureFunctionApp",
                    "type": "LinkedServiceReference"
                }
            }
        ],
        "parameters": {
            "TaskObject": {
                "type": "object"
            }
        },
        "variables": {
            "CheckComplete": {
                "type": "Boolean",
                "defaultValue": false
            },
            "OutputMetaData": {
                "type": "String"
            }
        },
        "folder": {
            "name": Folder
        },
        "annotations": [],
        "lastPublishTime": "2022-04-06T03:50:37Z"
    },
    "type": "Microsoft.Synapse/workspaces/pipelines"
};
Wrapper(GenerateArm,pipeline)+{}