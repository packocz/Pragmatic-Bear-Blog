public with sharing class AccountHierarchy {
    private List<AccountHierarchyMember> hierarchies;
    private Map<Id, Map<SObjectField, Integer>> hierarchyFieldUpdatedAtLevel;

    public AccountHierarchy(List<Account> accounts) {
        this.hierarchies = organiseAccountsIntoHierarchies(accounts);
        this.hierarchyFieldUpdatedAtLevel = new Map<Id, Map<SObjectField, Integer>>();
    }

    public void updateHierarchy(Id accountId, Map<SObjectField, Object> fieldToNewValue) {
        for (AccountHierarchyMember hierarchy : this.hierarchies) {
            if (hierarchy.contains(accountId)) {
                AccountHierarchyMember requiredHierarchyBranch = hierarchy.get(accountId);
                Integer currentUpdateLevel = requiredHierarchyBranch.getLevel();
                Map<SObjectField, Object> fieldsToUpdate = filterUpdatedAtHigherLevel(
                    hierarchy.accountRecord.Id,
                    currentUpdateLevel,
                    fieldToNewValue
                );
                if (!fieldsToUpdate.isEmpty()) {
                    requiredHierarchyBranch.updateHierarchy(fieldsToUpdate);
                }
                break;
            }
        }
    }

    private Map<SObjectField, Object> filterUpdatedAtHigherLevel(
        Id topLevelAccountId,
        Integer currentUpdateLevel,
        Map<SObjectField, Object> fieldToNewValue
    ) {
        Map<SObjectField, Object> stillToUpdateFieldsToNewValue = new Map<SObjectField, Object>();
        Map<SObjectField, Integer> hierarchyUpdatedFields = hierarchyFieldUpdatedAtLevel.containsKey(topLevelAccountId)
            ? hierarchyFieldUpdatedAtLevel.get(topLevelAccountId)
            : new Map<SObjectField, Integer>();
        for (SObjectField updatedField : fieldToNewValue.keySet()) {
            if (!hierarchyUpdatedFields.containsKey(updatedField) || hierarchyUpdatedFields.get(updatedField) >= currentUpdateLevel) {
                stillToUpdateFieldsToNewValue.put(updatedField, fieldToNewValue.get(updatedField));
                hierarchyUpdatedFields.put(updatedField, currentUpdateLevel);
            } else {
                System.debug(
                    LoggingLevel.FINE,
                    updatedField.getDescribe().getName() +
                    ' already updated for ' +
                    topLevelAccountId +
                    ' at ' +
                    hierarchyUpdatedFields.get(updatedField)
                );
            }
        }
        hierarchyFieldUpdatedAtLevel.put(topLevelAccountId, hierarchyUpdatedFields);
        return stillToUpdateFieldsToNewValue;
    }

    public List<Account> getTopLevelAccounts() {
        List<Account> topLevelAccounts = new List<Account>();
        for (AccountHierarchyMember hierarchy : this.hierarchies) {
            topLevelAccounts.add(hierarchy.accountRecord);
        }
        return topLevelAccounts;
    }

    public List<Account> getUpdatedAccounts() {
        List<Account> allUpdatedAccounts = new List<Account>();
        for (AccountHierarchyMember hierarchy : this.hierarchies) {
            allUpdatedAccounts.addAll(hierarchy.getDirtyAccounts());
        }
        return allUpdatedAccounts;
    }

    public static List<AccountHierarchyMember> organiseAccountsIntoHierarchies(List<Account> accounts) {
        List<AccountHierarchyMember> hierarchies = new List<AccountHierarchyMember>();
        for (Account a : accounts) {
            AccountHierarchyMember newMember = new AccountHierarchyMember(a);
            Integer replaceIndex = null;
            for (Integer i = 0; i < hierarchies.size(); i++) {
                AccountHierarchyMember hierarchy = hierarchies[i];
                if (hierarchy.addChild(newMember)) {
                    replaceIndex = -1;
                    break;
                }
                if (newMember.addChild(hierarchy)) {
                    replaceIndex = i;
                    break;
                }
            }
            if (replaceIndex == null) {
                hierarchies.add(newMember);
            } else if (replaceIndex >= 0) {
                hierarchies[replaceIndex] = newMember;
            }
        }

        /* Reconcile hierarchy, i.e. order in which accounts were added could mean that separate
        branches of the same hierarchy could have formed. This will ensure that they are joined
        together */
        Integer index = 0;
        Integer index2 = 1;
        while (hierarchies.size() > index + 1) {
            AccountHierarchyMember firstMember = hierarchies[index];
            AccountHierarchyMember secondMember = hierarchies[index2];

            if (secondMember.addChild(firstMember)) {
                hierarchies.remove(index);
                index = 0;
                index2 = 1;
                continue;
            } else if (firstMember.addChild(secondMember)) {
                hierarchies.remove(index2);
                index = 0;
                index2 = 1;
                continue;
            }

            if (index2 < hierarchies.size() - 1) {
                index2++;
            } else {
                index++;
                index2 = index + 1;
            }
        }

        return hierarchies;
    }
}
