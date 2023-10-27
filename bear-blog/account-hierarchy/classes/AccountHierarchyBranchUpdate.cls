public with sharing class AccountHierarchyBranchUpdate extends AsyncJob {
	private static Set<Id> updatingInThisTransaction = new Set<Id>();
	private static Map<Id, Account> registeredAccounts = new Map<Id, Account>();
	private static Map<Id, Map<SObjectField, Object>> alreadyUpdatedInThisTransaction = new Map<Id, Map<SObjectField, Object>>();

	@TestVisible
	private static Integer batchSizeSetting; //allows override in tests without inserting custom settings
	private static Integer getBatchSize() {
		if (batchSizeSetting == null) {
			/*Decimal orgConfig = OrgSetting__c.getInstance().AccountHierarchy_UpdateBatchSize__c;
            System.debug(LoggingLevel.FINE, 'AccountHierarchyBranchUpdate batch size configured to: ' + orgConfig);
            batchSizeSetting = orgConfig == null ? 25 : Integer.valueOf(orgConfig);*/
			batchSizeSetting = 10;
		}
		return batchSizeSetting;
	}

	public static Boolean isAlreadyUpdated(Id accountId) {
		return updatingInThisTransaction.contains(accountId);
	}

	public static void registerUpdatedAccountFields(Account updateAccount) {
		if (updatingInThisTransaction.contains(updateAccount.Id)) {
			return;
		}
		Map<SObjectField, Object> updatedFields = filterAlreadyUpdated(updateAccount.Id, getRelevantFieldsMap(updateAccount));
		if (updatedFields.isEmpty()) {
			return;
		}
		registeredAccounts.put(
			updateAccount.Id,
			mergeAccount(
				registeredAccounts.containsKey(updateAccount.Id)
					? registeredAccounts.get(updateAccount.Id)
					: new Account(Id = updateAccount.Id),
				updatedFields
			)
		);
	}

	public static void registerUpdatedAccountFields(Account preUpdate, Account postUpdate) {
		Account accountForUpdate = new Account(Id = postUpdate.Id);

		Boolean isUpdated = false;
		if (preUpdate.Classification__c != postUpdate.Classification__c) {
			accountForUpdate.Classification__c = postUpdate.Classification__c;
			isUpdated = true;
		}
		if (preUpdate.Priority__c != postUpdate.Priority__c) {
			accountForUpdate.Priority__c = postUpdate.Priority__c;
			isUpdated = true;
		}
		if (preUpdate.ParentId != null && postUpdate.ParentId == null) {
			accountForUpdate.RootAccountId__c = postUpdate.Id;
			isUpdated = true;
		}
		if (isUpdated) {
			registerUpdatedAccountFields(accountForUpdate);
		}
	}

	public static void registerAllAccountFields(Account accountRecord) {
		Account accountForUpdate = new Account(Id = accountRecord.Id, RootAccountId__c = accountRecord.RootAccountId__c);

		//EMPTY fields would not be part of the provided record, set explicitly to NULL
		Map<SObjectField, Object> relevantFields = getRelevantFieldsMap(accountRecord);
		accountForUpdate.Classification__c = relevantFields.containsKey(Schema.Account.Classification__c)
			? accountRecord.Classification__c
			: null;
		accountForUpdate.Priority__c = relevantFields.containsKey(Schema.Account.Priority__c) ? accountRecord.Priority__c : null;

		registerUpdatedAccountFields(accountForUpdate);
	}

	public static void updateNewChildren(List<Account> newChildAccounts) {
		if (newChildAccounts.isEmpty()) {
			return;
		}
		Map<Id, Account> parentAccounts = new Map<Id, Account>(
			AccountSelector.newInstance().selectById(ListUtil.getUniqueIds(newChildAccounts, Account.ParentId))
		);
		for (Account newAccount : newChildAccounts) {
			if (parentAccounts.containsKey(newAccount.ParentId)) {
				/*could just pass parent, but this ensures only the new account is part of the updated and not
				 any pre-existing siblings. Non-interesting values for update are stripped */
				Account hierarchyValuesFromParent = parentAccounts.get(newAccount.ParentId);
				//pick the right Root Account depending if the heirarchy goes beyond parent
				hierarchyValuesFromParent.RootAccountId__c = hierarchyValuesFromParent.ParentId == null
					? hierarchyValuesFromParent.Id
					: hierarchyValuesFromParent.RootAccountId__c;
				hierarchyValuesFromParent.Id = newAccount.Id;
				//nulled fields will not be in the query results and must be added explicitly to be applied
				registerAllAccountFields(hierarchyValuesFromParent);
			}
		}
	}

	public static void updateRegisteredAccounts() {
		if (registeredAccounts.isEmpty()) {
			System.debug(LoggingLevel.FINE, 'AccountHierarchyBranchUpdate: No records registered!');
			return;
		}
		AsyncJob.executeAsync(registeredAccounts.values(), 'AccountHierarchyBranchUpdate', getBatchSize(), AsyncJob.Strategy.NO_BATCH);
		rememberAlreadyUpdated(registeredAccounts.values());
		registeredAccounts = new Map<Id, Account>();
	}

	private static Map<SObjectField, Object> filterAlreadyUpdated(Id accountId, Map<SObjectField, Object> updatedFields) {
		if (alreadyUpdatedInThisTransaction.containsKey(accountId)) {
			Map<SObjectField, Object> alreadyUpdatedFields = alreadyUpdatedInThisTransaction.get(accountId);
			for (SObjectField alreadyUpdatedField : alreadyUpdatedFields.keySet()) {
				if (updatedFields.containsKey(alreadyUpdatedField)) {
					Object alreadyUpdatedValue = alreadyUpdatedFields.get(alreadyUpdatedField);
					if (alreadyUpdatedValue == updatedFields.get(alreadyUpdatedField)) {
						updatedFields.remove(alreadyUpdatedField);
					}
				}
			}
		}
		return updatedFields;
	}

	private static void rememberAlreadyUpdated(List<Account> updatedAccounts) {
		for (Account a : updatedAccounts) {
			Map<SObjectField, Object> updatedValues = getRelevantFieldsMap(a);
			if (alreadyUpdatedInThisTransaction.containsKey(a.Id)) {
				alreadyUpdatedInThisTransaction.get(a.Id).putAll(updatedValues);
			} else {
				alreadyUpdatedInThisTransaction.put(a.Id, updatedValues);
			}
		}
	}

	private static Account mergeAccount(Account accountRecord, Map<SObjectField, Object> updatedFields) {
		for (SObjectField field : updatedFields.keySet()) {
			accountRecord.put(field, updatedFields.get(field));
		}
		return accountRecord;
	}

	private static Map<SObjectField, Object> getRelevantFieldsMap(Account updatedAccount) {
		Map<SObjectField, Object> updatedFields = new Map<SObjectField, Object>();
		Map<String, Object> populatedFields = updatedAccount.getPopulatedFieldsAsMap();
		if (populatedFields.containsKey('Classification__c')) {
			updatedFields.put(Schema.Account.Classification__c, populatedFields.get('Classification__c'));
		}
		if (populatedFields.containsKey('Priority__c')) {
			updatedFields.put(Schema.Account.Priority__c, populatedFields.get('Priority__c'));
		}
		if (populatedFields.containsKey('RootAccountId__c')) {
			updatedFields.put(Schema.Account.RootAccountId__c, populatedFields.get('RootAccountId__c'));
		}
		return updatedFields;
	}

	private List<Account> recordsForAsyncQuickUpdate;
	public AccountHierarchyBranchUpdate() {
		super();
		//playing it safe for number of accounts involved as building hierarchy can be complex
		this.batchSize = getBatchSize();
		this.recordsForAsyncQuickUpdate = new List<Account>();
	}

	public override void handleBatch(List<sObject> scope) {
		List<Account> updatedAccounts = (List<Account>) scope;
		//Scope only contains updated fields, need to re-retrieve to ensure we have accurant Hierarchy relationships
		List<Account> updatedAccountsAsTheyAreInDB = AccountSelector.newInstance()
			.selectById(ListUtil.getUniqueIds(scope, Schema.Account.Id));
		List<Account> childAccounts = AccountService.newInstance().findAllChildAccounts(updatedAccounts);
		List<Account> allAccounts = new List<Account>(updatedAccountsAsTheyAreInDB);
		allAccounts.addAll(childAccounts);

		AccountHierarchy hierarchy = new AccountHierarchy(allAccounts);

		for (Account updatedAccount : updatedAccounts) {
			hierarchy.updateHierarchy(updatedAccount.Id, getRelevantFieldsMap(updatedAccount));
		}

		List<Account> acountsNeedingDatabaseUdpate = hierarchy.getUpdatedAccounts();
		if (!acountsNeedingDatabaseUdpate.isEmpty()) {
			checkCanUpdateAccounts();
			if (acountsNeedingDatabaseUdpate.size() <= 200) {
				updatingInThisTransaction.addAll(ListUtil.getUniqueIds(acountsNeedingDatabaseUdpate, Schema.Account.Id));
				//Suppress Triggers
				update acountsNeedingDatabaseUdpate;
			} else {
				this.recordsForAsyncQuickUpdate.addAll(acountsNeedingDatabaseUdpate);
			}
		}
	}

	public override String toString() {
		return 'AccountHierarchyBranchUpdate';
	}

	public override void onFinish() {
		if (this.recordsForAsyncQuickUpdate != null && !this.recordsForAsyncQuickUpdate.isEmpty()) {
			AsyncJob.executeAsync(this.recordsForAsyncQuickUpdate, 'AccountQuickUpdate');
		}
	}

	private void checkCanUpdateAccounts() {
		if (!Schema.sObjectType.Account.isUpdateable()) {
			throw new AccountHierarchyBranchUpdateException(
				String.format(
					'Insufficient Access to Account object for User: {0}; Update Permission Required!',
					new List<String>{ UserInfo.getUserId() }
				)
			);
		}
	}

	private class AccountHierarchyBranchUpdateException extends Exception {
	}
}
