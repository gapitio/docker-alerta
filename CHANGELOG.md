## v2.1.0

### Fix

- remove twilio and sendgrid libraries. Add simple requests for sending mail and sms
- add and/or logic for tags in notification rules
- fix length of users, phone numbers/mails in notification groups to always use all listed mails/phone numbers without requiring the same amount of phone numbers and mails
- add filter for sent status in notification history
- add and/or logic for tags in escalation rules
- add removal of notes when alert is closed
- add more checks for trigger text to select the correct trigger text when there are more advanced triggers
- select correct users/notification rules in test of notification channel
- add notification send for sending custom mail, sms
- add notification rule history to track changes of notification rules
- remove option for repeat type in on-call
- add backend search for notification history
- fix authentication for export of reports
- add information dialogs and tooltips for notification and escalation
- add dialog for notification rules activate
- add information about which notification rules are activated/deactivated in buld deactivate/activate notification rules
- add confirm for closing dialogs when the data in the dialog is changed
- change time to utc when creating on calls
- add header and footer for notification/escalation dialogs

## v2.0.3

### Fix

- remove + 'd' from mylink bearer

## v2.0.2

### Feat

- add phone numbers and emails to notification groups

### Fix

- set default status(closed) when alerts are received for the first time with default normal severity(normal) when using ALERTA_ISA_16_2 alarm model
- add error handling of searhces for alerts. Instead of throwing error when a search fail, it is logged as info.

## v2.0.1

### Fix

- update api token for myLink channels 10 minutes before the token timeout

## v2.0.0

### Feat

- add text field to each trigger by merging advanced_notification, status and severity into triggers with text field
- add export of the top n offenders, flapping and standing reports
- add bulk activation/deactivation of notification rules

## v1.6.2

### Fix

- remove housekeeping script from docker alerta to remove expired history when the housekeeping is not deleting expired alerts

## v1.6.1

### Feat

- enable edit of emails when using LDAP
- add info about which version is running

### Fix

- add "unack" to the open status check to enable the ACK action when the alert status is "unack"
- remove unused notification channel types link_mobility and jira

## v1.6.0

### Feat

- add notification delay

### Fix

- remove null variables from excluded_tags in notification rules
- show correct count of notification history and fix pagination of notification history

## v1.5.1

### Feat

- add bulk note for alerts
- add excluded tags for notification rules
- add search for history view

### Fix

- remove/hide forbidden actions
- fix handling of actions in alerta ISA 18 2 alarm model

## v1.5.0

### Feat

- add notification history


## v1.4.3

### Fix

- check status without ignoring active status of notification rules


## v1.4.2

### Feat

- add mylink notification channel for new link mobility api


## v1.4.1

### Feat

- add searchable fields for notification rules


## v1.4.0

### Feat

- add reactivation of inactive rules
- add notification groups to use instead of user groups
- add status change as trigger for notification rules

### Fix

- fix pagination for notification rules
