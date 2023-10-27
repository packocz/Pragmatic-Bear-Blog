@IsTest
private class AccountHierarchyTest {
	private static AccountSelector accounts = AccountSelector.newInstance();

	private static List<Account> createAccounts(String name, String classification, Integer priority) {
		List<Account> accs = new List<Account>();
		for (Integer i = 0; i < 5; i++) {
			Account a = new Account(Name = name + i, Classification__c = classification, Priority__c = priority);
			accs.add(a);
		}
		return accs;
	}

	@TestSetup
	static void generateTestData() {
		//setting complete hierarchies in Test Setup is important to prevent unintended
		//test execution paths as all Batch Jobs are completed only at the end of TestSetup
		//and with Test.stopTest() (can't initiate them to run before or after Test.startTest)
		List<Account> accList1 = createAccounts('Hierarchy1', 'A', 1);
		List<Account> accList2 = createAccounts('Hierarchy2', 'C', 2);
		List<Account> accList3 = createAccounts('Hierarchy3', 'C', null);

		List<Account> allAccounts = new List<Account>();
		allAccounts.addAll(accList1);
		allAccounts.addAll(accList2);
		allAccounts.addAll(accList3);
		insert allAccounts;

		for (Integer i = 4; i > 0; i--) {
			accList1[i].ParentId = accList1[i - 1].Id;
			accList2[i].ParentId = accList2[i - 1].Id;
			accList3[i].ParentId = accList3[i - 1].Id;
		}

		update allAccounts;
	}

	@IsTest
	static void checkTestSetup() {
		assertUnchanged1();
		assertUnchanged2();
		assertUnchanged3();
	}

	@IsTest
	static void newTopLevelAccountNoValues() {
		Account newAccount = createAccounts('NewIndependentAccount', null, null)[0];

		Test.startTest();

		insert newAccount;

		Test.stopTest();

		List<Account> updatedNewAccount = accounts.selectById(new Set<Id>{ newAccount.Id });

		assertRootAccountId(updatedNewAccount, null);
		assertClassification(updatedNewAccount, null);
		assertPriority(updatedNewAccount, null);
	}

	@IsTest
	static void newTopLevelAccountWithValues() {
		Account newAccount = createAccounts('NewIndependentAccount', 'D', 5)[0];

		Test.startTest();

		insert newAccount;

		Test.stopTest();

		List<Account> updatedNewAccount = accounts.selectById(new Set<Id>{ newAccount.Id });

		assertRootAccountId(updatedNewAccount, null);
		assertClassification(updatedNewAccount, 'D');
		assertPriority(updatedNewAccount, 5);
	}

	@IsTest
	static void newTopLevelAccountForExistingHierarchy() {
		Account oldTopLevelAccount = accounts.selectByName(new Set<String>{ 'Hierarchy10' })[0];
		Account newTopLevelParent = createAccounts('NewTopLevelParent', 'D', 13)[0];
		insert newTopLevelParent;

		Test.startTest();

		oldTopLevelAccount.ParentId = newTopLevelParent.Id;
		update oldTopLevelAccount;

		Test.stopTest();

		List<Account> hierarchy1 = accounts.selectByNameLike('Hierarchy1%');
		List<Account> hierarchy2 = accounts.selectByNameLike('Hierarchy2%');
		List<Account> hierarchy3 = accounts.selectByNameLike('Hierarchy3%');
		List<Account> updatedNewTopLevelParent = accounts.selectById(new Set<Id>{ newTopLevelParent.Id });

		assertRootAccountId(hierarchy1, newTopLevelParent.Id);
		assertClassification(hierarchy1, newTopLevelParent.Classification__c);
		assertPriority(hierarchy1, Integer.valueOf(newTopLevelParent.Priority__c));

		assertUnchanged2();
		assertUnchanged3();

		assertRootAccountId(updatedNewTopLevelParent, null);
		assertClassification(updatedNewTopLevelParent, 'D');
		assertPriority(updatedNewTopLevelParent, 13);
	}

	@IsTest
	static void newChildAccountForExistingHierarchy() {
		Account existingAccount = accounts.selectByName(new Set<String>{ 'Hierarchy12' })[0];
		Account existingTopLevelAccount = accounts.selectByName(new Set<String>{ 'Hierarchy10' })[0];
		Account newChildAccount = createAccounts('NewChildAccount', null, null)[0];

		Test.startTest();

		newChildAccount.ParentId = existingAccount.Id;
		insert newChildAccount;

		Test.stopTest();

		List<Account> updatedNewChildAccount = accounts.selectById(new Set<Id>{ newChildAccount.Id });
		assertRootAccountId(updatedNewChildAccount, existingTopLevelAccount.Id);
		assertClassification(updatedNewChildAccount, existingAccount.Classification__c);
		assertPriority(updatedNewChildAccount, Integer.valueOf(existingAccount.Priority__c));
	}

	@IsTest
	static void newChildAccountForExistingHierarchyResettingToNull() {
		Account existingAccount = accounts.selectByName(new Set<String>{ 'Hierarchy34' })[0];
		Account existingTopLevelAccount = accounts.selectByName(new Set<String>{ 'Hierarchy30' })[0];

		Account newChildAccount = createAccounts('NewChildAccount', 'D', 20)[0];
		insert newChildAccount;

		Test.startTest();

		newChildAccount.ParentId = existingAccount.Id;
		update newChildAccount;

		Test.stopTest();

		List<Account> updatedNewChildAccount = accounts.selectById(new Set<Id>{ newChildAccount.Id });
		assertRootAccountId(updatedNewChildAccount, existingTopLevelAccount.Id);
		assertClassification(updatedNewChildAccount, 'C');
		assertPriority(updatedNewChildAccount, null);
	}

	@IsTest
	static void changeTopLevelClassification() {
		Account topLevelHierarchy1Account = accounts.selectByName(new Set<String>{ 'Hierarchy10' })[0];

		Test.startTest();

		topLevelHierarchy1Account.Classification__c = 'B';
		update topLevelHierarchy1Account;

		Test.stopTest();

		List<Account> hierarchy1 = accounts.selectByNameLike('Hierarchy1%');
		assertClassification(hierarchy1, 'B');
		assertPriority(hierarchy1, 1);

		assertUnchanged2();
		assertUnchanged3();
	}

	@IsTest
	static void changeTopLevelCurrentPartnerValue() {
		Account topLevelHierarchy1Account = accounts.selectByName(new Set<String>{ 'Hierarchy10' })[0];

		Test.startTest();

		topLevelHierarchy1Account.Priority__c = 10;
		update topLevelHierarchy1Account;

		Test.stopTest();

		List<Account> hierarchy1 = accounts.selectByNameLike('Hierarchy1%');
		assertPriority(hierarchy1, 10);
		assertClassification(hierarchy1, 'A');

		assertUnchanged2();
		assertUnchanged3();
	}

	@IsTest
	static void changeTopLevelAll() {
		Account topLevelHierarchy1Account = accounts.selectByName(new Set<String>{ 'Hierarchy10' })[0];

		Test.startTest();

		topLevelHierarchy1Account.Classification__c = 'D';
		topLevelHierarchy1Account.Priority__c = 15;
		update topLevelHierarchy1Account;

		Test.stopTest();

		List<Account> expectedChangedAccounts = accounts.selectByNameLike('Hierarchy1%');
		assertClassification(expectedChangedAccounts, 'D');
		assertPriority(expectedChangedAccounts, 15);

		assertUnchanged2();
		assertUnchanged3();
	}

	@IsTest
	static void multipleChangeTopLevel() {
		Account topLevelHierarchy1Account = accounts.selectByName(new Set<String>{ 'Hierarchy10' })[0];
		Account topLevelHierarchy2Account = accounts.selectByName(new Set<String>{ 'Hierarchy20' })[0];

		Test.startTest();

		topLevelHierarchy1Account.Classification__c = 'B';
		topLevelHierarchy2Account.Classification__c = 'D';
		update new List<Account>{ topLevelHierarchy1Account, topLevelHierarchy2Account };

		Test.stopTest();

		List<Account> hierarchy1 = accounts.selectByNameLike('Hierarchy1%');
		List<Account> hierarchy2 = accounts.selectByNameLike('Hierarchy2%');
		List<Account> hierarchy3 = accounts.selectByNameLike('Hierarchy3%');
		assertClassification(hierarchy1, 'B');
		assertPriority(hierarchy1, 1);
		assertPriority(hierarchy2, 2);
		assertPriority(hierarchy3, null);
		assertClassification(accounts.selectByNameLike('Hierarchy2%'), 'D');
		assertClassification(accounts.selectByNameLike('Hierarchy3%'), 'C');
	}

	@IsTest
	static void changeMiddleLevelClassification() {
		Account midLevelHierarchy1Account = accounts.selectByName(new Set<String>{ 'Hierarchy11' })[0];

		Test.startTest();

		midLevelHierarchy1Account.Classification__c = 'B';
		update midLevelHierarchy1Account;

		Test.stopTest();

		assertClassification(accounts.selectByName(new Set<String>{ 'Hierarchy10' }), 'A');
		assertClassification(accounts.selectByName(new Set<String>{ 'Hierarchy11', 'Hierarchy12', 'Hierarchy13', 'Hierarchy14' }), 'B');
		assertClassification(accounts.selectByNameNotLike('Hierarchy1%'), 'C');
		List<Account> hierarchy1 = accounts.selectByNameLike('Hierarchy1%');
		assertPriority(hierarchy1, 1);

		assertUnchanged2();
		assertUnchanged3();
	}

	@IsTest
	static void changeMiddleLevelPriority() {
		Account midLevelHierarchy1Account = accounts.selectByName(new Set<String>{ 'Hierarchy11' })[0];

		Test.startTest();

		midLevelHierarchy1Account.Priority__c = 10;
		update midLevelHierarchy1Account;

		Test.stopTest();

		assertPriority(accounts.selectByName(new Set<String>{ 'Hierarchy10' }), 1);
		assertPriority(accounts.selectByName(new Set<String>{ 'Hierarchy11', 'Hierarchy12', 'Hierarchy13', 'Hierarchy14' }), 10);
		List<Account> hierarchy1 = accounts.selectByNameLike('Hierarchy1%');
		assertClassification(hierarchy1, 'A');

		assertUnchanged2();
		assertUnchanged3();
	}

	@IsTest
	static void reparentClassification() {
		Account midLevelHierarchy1Account = accounts.selectByName(new Set<String>{ 'Hierarchy12' })[0];
		Account midLevelHierarchy2Account = accounts.selectByName(new Set<String>{ 'Hierarchy21' })[0];

		Test.startTest();

		midLevelHierarchy1Account.ParentId = midLevelHierarchy2Account.Id;
		update midLevelHierarchy1Account;

		Test.stopTest();

		assertReparentTest();
	}

	@IsTest
	static void reparentClassificationTriggeredByBatch() {
		Account midLevelHierarchy1Account = accounts.selectByName(new Set<String>{ 'Hierarchy12' })[0];
		Account midLevelHierarchy2Account = accounts.selectByName(new Set<String>{ 'Hierarchy21' })[0];

		Test.startTest();

		midLevelHierarchy1Account.ParentId = midLevelHierarchy2Account.Id;
		AsyncJob.executeAsync(
			new List<Account>{ midLevelHierarchy1Account },
			'AccountHierarchyAsyncJobTest',
			1,
			AsyncJob.Strategy.BATCH_ONLY
		);

		Test.stopTest();

		assertReparentTest();
	}

	@IsTest
	static void reparentClassificationTriggeredByQueueable() {
		Account midLevelHierarchy1Account = accounts.selectByName(new Set<String>{ 'Hierarchy12' })[0];
		Account midLevelHierarchy2Account = accounts.selectByName(new Set<String>{ 'Hierarchy21' })[0];

		Test.startTest();

		midLevelHierarchy1Account.ParentId = midLevelHierarchy2Account.Id;
		AsyncJob.executeAsync(
			new List<Account>{ midLevelHierarchy1Account },
			'AccountHierarchyAsyncJobTest',
			1,
			AsyncJob.Strategy.QUEUEABLE_ONLY
		);

		Test.stopTest();

		assertReparentTest();
	}

	@IsTest
	static void reparentClassificationTriggeredByFuture() {
		Account midLevelHierarchy1Account = accounts.selectByName(new Set<String>{ 'Hierarchy12' })[0];
		Account midLevelHierarchy2Account = accounts.selectByName(new Set<String>{ 'Hierarchy21' })[0];

		Test.startTest();

		AccountHierarchyAsyncJobTest.reparent(midLevelHierarchy1Account.Id, midLevelHierarchy2Account.Id);

		Test.stopTest();

		assertReparentTest();
	}

	private static void assertUnchanged1() {
		List<Account> hierarchy1 = accounts.selectByNameLike('Hierarchy1%');
		assertClassification(hierarchy1, 'A');
		assertPriority(hierarchy1, 1);
	}

	private static void assertUnchanged2() {
		List<Account> hierarchy2 = accounts.selectByNameLike('Hierarchy2%');
		assertClassification(hierarchy2, 'C');
		assertPriority(hierarchy2, 2);
	}

	private static void assertUnchanged3() {
		List<Account> hierarchy3 = accounts.selectByNameLike('Hierarchy3%');
		assertClassification(hierarchy3, 'C');
		assertPriority(hierarchy3, null);
	}

	private static void assertReparentTest() {
		Account topLevelHierarchy1Account = accounts.selectByName(new Set<String>{ 'Hierarchy10' })[0];
		Account topLevelHierarchy2Account = accounts.selectByName(new Set<String>{ 'Hierarchy20' })[0];
		List<Account> expectedChanged = accounts.selectByName(new Set<String>{ 'Hierarchy12', 'Hierarchy13', 'Hierarchy14' });
		List<Account> expectedNotChangedChildren = accounts.selectByName(new Set<String>{ 'Hierarchy11' });
		List<Account> expectedNotChangedTopLevel = accounts.selectByName(new Set<String>{ 'Hierarchy10' });

		assertRootAccountId(expectedChanged, topLevelHierarchy2Account.Id);
		assertClassification(expectedChanged, 'C');
		assertPriority(expectedChanged, 2);

		assertRootAccountId(expectedNotChangedChildren, topLevelHierarchy1Account.Id);
		assertClassification(expectedNotChangedChildren, 'A');
		assertPriority(expectedNotChangedChildren, 1);

		assertRootAccountId(expectedNotChangedTopLevel, null);
		assertClassification(expectedNotChangedTopLevel, 'A');
		assertPriority(expectedNotChangedTopLevel, 1);

		assertUnchanged2();
		assertUnchanged3();
	}

	@IsTest
	static void reparentMutlipleAccountsIntoSameHierarchy() {
		Account midLevelHierarchy1Account = accounts.selectByName(new Set<String>{ 'Hierarchy12' })[0];
		Account midLevelHierarchy2Account = accounts.selectByName(new Set<String>{ 'Hierarchy21' })[0];
		Account midLevelHierarchy3Account = accounts.selectByName(new Set<String>{ 'Hierarchy32' })[0];

		Test.startTest();

		midLevelHierarchy1Account.ParentId = midLevelHierarchy2Account.Id;
		midLevelHierarchy3Account.ParentId = midLevelHierarchy1Account.Id;
		update new List<Account>{ midLevelHierarchy1Account, midLevelHierarchy3Account };
		Test.stopTest();

		List<Account> expectedChangedToHierarchy2 = accounts.selectByName(
			new Set<String>{ 'Hierarchy12', 'Hierarchy13', 'Hierarchy14', 'Hierarchy32', 'Hierarchy33', 'Hierarchy34' }
		);
		List<Account> expectedNotChangedTopLevel = accounts.selectByName(new Set<String>{ 'Hierarchy10', 'Hierarchy30' });
		List<Account> expectedNotChangedChildrenHierarchy1 = accounts.selectByName(new Set<String>{ 'Hierarchy11' });
		List<Account> expectedNotChangedChildrenHierarchy3 = accounts.selectByName(new Set<String>{ 'Hierarchy31' });

		assertRootAccountId(expectedChangedToHierarchy2, midLevelHierarchy2Account.RootAccountId__c);
		assertRootAccountId(expectedNotChangedTopLevel, null);
		assertRootAccountId(expectedNotChangedChildrenHierarchy1, midLevelHierarchy1Account.RootAccountId__c);
		assertRootAccountId(expectedNotChangedChildrenHierarchy3, midLevelHierarchy3Account.RootAccountId__c);
	}

	private static void assertClassification(List<Account> accounts, String classification) {
		assertAccountField(accounts, Schema.Account.Classification__c, classification);
	}

	private static void assertPriority(List<Account> accounts, Integer value) {
		assertAccountField(accounts, Schema.Account.Priority__c, value);
	}

	private static void assertRootAccountId(List<Account> accounts, String expectedAccountId) {
		assertAccountField(accounts, Schema.Account.RootAccountId__c, expectedAccountId);
	}

	private static void assertAccountField(List<Account> accounts, SObjectField field, Object expectedValue) {
		for (Account acc : accounts) {
			Object currentValue = acc.get(field);
			System.assertEquals(
				expectedValue,
				currentValue,
				String.format('Unexpected {1} for {0}', new List<String>{ acc.Name, field.getDescribe().getName() })
			);
		}
	}
}
