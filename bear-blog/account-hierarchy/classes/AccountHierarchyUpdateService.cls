public with sharing class AccountHierarchyUpdateService {
	private static AccountSelector accounts = AccountSelector.newInstance();

    public static void updateHierarchyValuesAfterUpdate(List<Account> newAccounts, Map<Id, Account> oldAccounts) {
        List<Account> newChildAccounts = new List<Account>();
        for (Account newAccount : newAccounts) {
            if (AccountHierarchyBranchUpdate.isAlreadyUpdated(newAccount.Id)) {
                continue;
            }
            if (newAccount.ParentId != null && newAccount.ParentId != oldAccounts.get(newAccount.Id).ParentId) {
                newChildAccounts.add(newAccount);
            } else {
                AccountHierarchyBranchUpdate.registerUpdatedAccountFields(oldAccounts.get(newAccount.Id), newAccount);
            }
        }
        updateNewChildren(newChildAccounts);
        AccountHierarchyBranchUpdate.updateRegisteredAccounts();
    }

    public static void updateAllHierarchyValuesAfterNewChildInsert(List<Account> newAccounts) {
        List<Account> newChildAccounts = new List<Account>();
        for (Account newAccount : newAccounts) {
            if (AccountHierarchyBranchUpdate.isAlreadyUpdated(newAccount.Id)) {
                continue;
            }
            if (newAccount.ParentId != null) {
                newChildAccounts.add(newAccount);
            }
        }
        updateNewChildren(newChildAccounts);
        AccountHierarchyBranchUpdate.updateRegisteredAccounts();
    }

    public static void updateRootAccountIdsAfterAccountDelete(Map<Id, Account> oldAccounts) {
        for (Account childAccount : accounts.selectByRootAccountId(oldAccounts.keySet())) {
            if (childAccount.ParentId == null) {
                //those that became new ultimate parents will propagate to their respective hierarchies
                AccountHierarchyBranchUpdate.registerUpdatedAccountFields(
                    new Account(Id = childAccount.Id, RootAccountId__c = childAccount.Id)
                );
            }
        }
        AccountHierarchyBranchUpdate.updateRegisteredAccounts();
    }

    private static void updateNewChildren(List<Account> newChildAccounts) {
        if (newChildAccounts.isEmpty()) {
            return;
        }
        Map<Id, Account> parentAccounts = new Map<Id, Account>(
            accounts.selectById(ListUtil.getUniqueIds(newChildAccounts, Account.ParentId))
        );
        for (Account newAccount : newChildAccounts) {
            if (parentAccounts.containsKey(newAccount.ParentId)) {
                /*could just pass parent, but this ensures only the new account is part of the updated and not
                 any pre-existing siblings. Non-interesting values for update are stripped in AccountHierarchyBranchUpdate */
                Account hierarchyValuesFromParent = parentAccounts.get(newAccount.ParentId);
                //pick the right Root Account depending if the heirarchy goes beyond parent
                hierarchyValuesFromParent.RootAccountId__c = hierarchyValuesFromParent.ParentId == null
                    ? hierarchyValuesFromParent.Id
                    : hierarchyValuesFromParent.RootAccountId__c;
                hierarchyValuesFromParent.Id = newAccount.Id;
                //nulled fields will not be in the query results and must be added explicitly to be applied
                AccountHierarchyBranchUpdate.registerAllAccountFields(hierarchyValuesFromParent);
            }
        }
    }
}
