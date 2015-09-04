**Rueusable Ansible Code**

Before using this repo please refer to ...url.. to understand the standards that are applied to this code base.  If you don't adhere to the defined process, your code will not be able to merge into the master branch.

1. Each application/project should have variables stored in a file/files in a separate projects/<projectname> directory.  The code will look for the following file - projects/<project_prefix>/<c_type>_<env>.yml where c_type,env and project_prefix are variables that are supplied at the command line to ansible uing --extra-vars "env=XXX project_prefix=XXXXX c_type=XXXX". c_type nomniates the cloud infrastructure eg aws, cloudstack

2. Each environment file should provide suitable information that is required for creating instances in a cloud environment, as well as provisioning software to support the application

3. Define security group tasks for each cloud provider as <provider>_sec_groups.yml in the projects/<project_prefix> directory

4. All projects and roles must have a Readme.md file which must provide an overview of the project/role and related information, such as variable names.

