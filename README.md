![alt text](https://github.com/REMEDYNE/Sanctions.io/blob/master/sanctions.io_transparent_small.png?raw=true "Sanctions.io Logo")
# Program to use Sanctions.io API

## ZSANCTIONSIO is a template SAP ABAP report that implements the sanctions.io (https://sanctions.io) API to check persons and organizations against sanction lists.

To learn more about supported sanction lists and the API, visit https://sanctions.io
This report does not implement advanced features of the API like fuzzy search, matching country or date of birth, etc.

This report is provided as is and with no warranty under the 3-clause-BSD license, see https://opensource.org/licenses/BSD-3-Clause.
Redistribution and use, with or without modification, is permitted.
Copyright 2019 REMEDYNE GmbH.

Before using this report:
1. Create an RFC destination as described here:
https://remedyne.help/knowledgebase/configure-ssl-client-for-sanction-list-screening/
2. Sign-up for an API key on https://sanctions.io. A free trial is available.
3. This report does not perform an AUTHORITY-CHECK when executed: make sure you apply appropriate security mechanisms before deploying this.
4. This template report comes with no warranty. It has been used in several environments without problems, but running this check against large sets of data can have an impact on the performance of your SAP system.

To use this report:
Enter a table name and field name that contains names, e.g. business partner names such as LFA1-NAME1, and select the sanction list against which you want to run the check.
You can also enter a name and check whether the name is on a list.

In case of questions, contact *info@sanctions.io*
