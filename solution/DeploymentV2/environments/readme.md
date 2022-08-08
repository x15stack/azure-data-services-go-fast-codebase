
This folder contains the configuration settings and feature flags that determine what a specific ADS Go Fast deployment will be comprised of. 

# Feature Templates Directory

- full_deployment
- basic_deployment
- full_deployment_no_purview
- functional_tests


# Vars Directory
Contains a folder for each deployment environment. These folders control the number of "Analytics Landing Zones" that can be deployed by the repository. You can use these folders to allow for multiple environments that will support your SDLC (eg. Development, UAT, Production) and you can also use them to allow for multiple hub / spoke production deployments within a decentralised analytics architecture (Eg, EDW, Finance-Analytics, Operations-Analytics etc.).

Within each of these folders is a file called "common_vars_values.jsonc". This file contains all of the configuration settings specific to a single Analytics Lockbox deployment. 
