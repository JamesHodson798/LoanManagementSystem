# Salesforce DX Project: Loan Management System

This Salesforce DX project implements a comprehensive Loan Management System for the Asset Management team at a finance firm. The solution includes custom objects, Apex triggers, and automated business logic for managing loan portfolios.

**Repository**: https://github.com/JamesHodson798/LoanManagementSystem

## Package Information

**Package Version**: 08cN10000002EOfIAM  
**Subscriber Package Version Id**: 04tN1000004c72zIAA  
**Package Installation URL**: https://login.salesforce.com/packaging/installPackage.apexp?p0=04tN1000004c72zIAA

**Installation**: This package version has been successfully promoted to released status and meets the minimum 75% code coverage requirement enforced starting in Winter '21.

## Installation Options

### Option 1: Package Installation URL
Navigate to the package installation URL in your Salesforce org:
```
https://login.salesforce.com/packaging/installPackage.apexp?p0=04tN1000004c72zIAA
```

### Option 2: Salesforce CLI
Use the following command to install the package:
```bash
sf package:install --package 04tN1000004c72zIAA --target-org your-org-alias
```

### Option 3: Deploy from Source
If you want to deploy the source code directly:
```bash
sfdx force:source:deploy --sourcepath force-app/main/default --targetusername your-org-alias
```

## Post-Installation Setup

After installing the package, you need to assign the appropriate permission set to access the application:

1. Navigate to **Setup** → **Users** → **Permission Sets**
2. Find and select the **Loan Management Admin** permission set
3. Click **Manage Assignments**
4. Add the relevant users to the permission set
5. The Loan Management app will now be available in the App Launcher

## Prerequisites

- Salesforce Developer Edition org (sign up at https://developer.salesforce.com/signup)
- Salesforce CLI installed and configured
- Git for version control

## Support Documentation

- [Salesforce Extensions Documentation](https://developer.salesforce.com/tools/vscode/)
- [Salesforce CLI Setup Guide](https://developer.salesforce.com/docs/atlas.en-us.sfdx_setup.meta/sfdx_setup/sfdx_setup_intro.htm)
- [Salesforce DX Developer Guide](https://developer.salesforce.com/docs/atlas.en-us.sfdx_dev.meta/sfdx_dev/sfdx_dev_intro.htm)
- [Salesforce CLI Command Reference](https://developer.salesforce.com/docs/atlas.en-us.sfdx_cli_reference.meta/sfdx_cli_reference/cli_reference.htm)