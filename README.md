
# Salesforce LMA App Cockpit Clone

Original project: https://github.com/logiclinegmbh/lma-app-cockpit

This fork is a stripped-down, single-class version of the original. No fancy installer, no nice things.

Setup Instructions:
1) Set up an Email Service to point to the Apex class.
2) Manually set the "txt_Namespace__c" field on each of your Package__c records.
3) Configure your packages to send error emails to the email address created with the Email Service in step #1.