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
