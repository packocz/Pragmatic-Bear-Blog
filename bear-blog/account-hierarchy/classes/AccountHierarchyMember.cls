public with sharing class AccountHierarchyMember {
    public Account accountRecord { get; private set; }
    private List<AccountHierarchyMember> children;
    private AccountHierarchyMember parent;
    private Set<Id> allIds { get; private set; }
    private Boolean isChanged;
    private Boolean isTopLevelAccount {
        get {
            return this.accountRecord.ParentId == null;
        }
    }

    public AccountHierarchyMember(Account accountRecord) {
        this.accountRecord = accountRecord;
        this.children = new List<AccountHierarchyMember>();
        this.allIds = new Set<Id>{ accountRecord.Id };
        this.isChanged = false;
    }

    public Boolean contains(Id accountId) {
        System.debug(LoggingLevel.FINE, accountId + ' IN (' + this.allIds + ')');
        return this.allIds.contains(accountId);
    }

    public AccountHierarchyMember get(Id accountId) {
        if (this.accountRecord.Id == accountId) {
            return this;
        }
        for (AccountHierarchyMember child : this.children) {
            AccountHierarchyMember match = child.get(accountId);
            if (match != null) {
                return match;
            }
        }
        return null;
    }

    public List<Account> getDirtyAccounts() {
        List<Account> dirtyAccounts = new List<Account>();
        if (this.isChanged) {
            dirtyAccounts.add(this.accountRecord);
        }
        for (AccountHierarchyMember child : this.children) {
            dirtyAccounts.addAll(child.getDirtyAccounts());
        }
        return dirtyAccounts;
    }

    public Boolean isDirectParentTo(AccountHierarchyMember newAccountHierchyMember) {
        return this.accountRecord.Id == newAccountHierchyMember.accountRecord.ParentId;
    }

    public void setParent(AccountHierarchyMember parent) {
        this.parent = parent;
    }

    public Integer getLevel() {
        if (this.parent == null) {
            return 1;
        } else {
            return this.parent.getLevel() + 1;
        }
    }

    public Boolean addChild(AccountHierarchyMember newChildAccountHierarchyMember) {
        if (
            newChildAccountHierarchyMember.accountRecord.ParentId == null ||
            !this.contains(newChildAccountHierarchyMember.accountRecord.ParentId)
        ) {
            return false;
        }
        this.allIds.addAll(newChildAccountHierarchyMember.allIds);
        if (this.isDirectParentTo(newChildAccountHierarchyMember)) {
            newChildAccountHierarchyMember.setParent(this);
            this.children.add(newChildAccountHierarchyMember);
            System.debug(LoggingLevel.FINE, 'Added Direct: now all Ids: ' + this.allIds);
            return true;
        } else {
            for (AccountHierarchyMember existingChild : this.children) {
                if (existingChild.addChild(newChildAccountHierarchyMember)) {
                    System.debug(LoggingLevel.FINE, 'Added in Child: now all Ids: ' + this.allIds);
                    return true;
                }
            }
        }
        return false;
    }

    public void updateHierarchy(Map<SObjectField, Object> fieldToNewValue) {
        updateIfChanged(fieldToNewValue);
        for (AccountHierarchyMember child : this.children) {
            child.updateHierarchy(fieldToNewValue);
        }
    }

    private void updateIfChanged(Map<SObjectField, Object> fieldToNewValue) {
        Boolean isChangedThisTime = false;
        for (SObjectField field : fieldToNewValue.keySet()) {
            Object oldValue = this.accountRecord.get(field);
            Object newValue = fieldToNewValue.get(field);
            //Top Level Accounts should never have Root Account Id filled in
            if (field == Account.RootAccountId__c && this.isTopLevelAccount) {
                newValue = null;
            }
            if (oldValue != newValue) {
                this.accountRecord.put(field, newValue);
                isChangedThisTime = true;
            }
        }
        this.isChanged = this.isChanged || isChangedThisTime;
    }
}
