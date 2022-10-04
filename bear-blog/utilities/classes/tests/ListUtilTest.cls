@IsTest
private class ListUtilTest {
	static List<Id> contactIds = new List<Id>{
		FakeId.build(Contact.getSObjectType()),
		FakeId.build(Contact.getSObjectType()),
		FakeId.build(Contact.getSObjectType())
	};
	static List<Id> accountIds = new List<Id>{ FakeId.build(Account.getSObjectType()), FakeId.build(Account.getSObjectType()) };

	static List<Contact> contacts = new List<Contact>{
		new Contact(Id = contactIds[0], AccountId = accountIds[0], FirstName = 'Adam'),
		new Contact(Id = contactIds[1], AccountId = accountIds[0], FirstName = 'Adam'),
		new Contact(Id = contactIds[2], AccountId = accountIds[1], FirstName = 'Betty')
	};

	@IsTest
	static void testGetUniqueIds() {
		Set<Id> uniqueContactIds = ListUtil.getUniqueIds(contacts, Contact.Id);
		System.assertEquals(contactIds.size(), uniqueContactIds.size(), 'Incorrectly identified unique Contact Ids');
		System.assert(uniqueContactIds.containsAll(contactIds), 'Some Contact Ids are incorrect');

		Set<Id> uniqueAccountIds = ListUtil.getUniqueIds(contacts, Contact.AccountId);
		System.assertEquals(accountIds.size(), uniqueAccountIds.size(), 'Incorrectly identified unique Account Ids');
		System.assert(uniqueAccountIds.containsAll(accountIds), 'Some Account Ids are incorrect');

		Set<Id> emptyResult = ListUtil.getUniqueIds(new List<Contact>(), Contact.AccountId);
		System.assertEquals(0, emptyResult.size(), 'Method should be safe for empty list');

		emptyResult = ListUtil.getUniqueIds(null, Contact.AccountId);
		System.assertEquals(0, emptyResult.size(), 'Method should be safe for null list');
	}

	@IsTest
	static void testGetUniqueStrings() {
		List<Account> accounts = new List<Account>{
			new Account(Id = FakeId.build(Account.getSObjectType()), Name = 'Account Name 1'),
			new Account(Id = FakeId.build(Account.getSObjectType()), Name = 'Account Name 2'),
			new Account(Id = FakeId.build(Account.getSObjectType()), Name = 'Account Name 3'),
			new Account(Id = FakeId.build(Account.getSObjectType()), Name = 'Account Name 3')
		};

		Set<String> uniqueAccountNames = ListUtil.getUniqueStrings(accounts, Account.Name);
		System.assertEquals(3, uniqueAccountNames.size(), 'Incorrectly identified unique Account Names');

		Set<String> uniqueAccountIds = ListUtil.getUniqueStrings(accounts, Account.Id);
		System.assertEquals(4, uniqueAccountIds.size(), 'Incorrectly identified unique Account Ids');

		Set<Id> emptyResult = ListUtil.getUniqueIds(new List<Account>(), Account.Name);
		System.assertEquals(0, emptyResult.size(), 'Method should be safe for empty list');

		emptyResult = ListUtil.getUniqueIds(null, Account.Name);
		System.assertEquals(0, emptyResult.size(), 'Method should be safe for null list');
	}

	@IsTest
	static void testFilter() {
		List<Contact> filteredByContactId = (List<Contact>) ListUtil.filter(
			contacts,
			Contact.Id,
			new Set<Id>{ contactIds[0], contactIds[1] }
		);
		System.assertEquals(1, filteredByContactId.size(), '1 Contact should have remained in the list');
		System.assertEquals(contacts[2], filteredByContactId[0], 'Last Contact from list should have remained');

		List<Contact> emptyFilterResult = (List<Contact>) ListUtil.filter(contacts, Contact.Id, new Set<Id>());
		System.assertEquals(3, emptyFilterResult.size(), 'All Contacts should have remained in the list');
		System.assert((new Set<Contact>(emptyFilterResult)).containsAll(contacts), 'All Contacts should have remained in the listÇ');

		List<Contact> nullFilterResult = (List<Contact>) ListUtil.filter(contacts, Contact.Id, null);
		System.assertEquals(3, nullFilterResult.size(), 'All Contacts should have remained in the list');
		System.assert((new Set<Contact>(nullFilterResult)).containsAll(contacts), 'All Contacts should have remained in the listÇ');

		List<Contact> filteredByAccountId = (List<Contact>) ListUtil.filter(contacts, Contact.AccountId, new Set<Id>{ accountIds[0] });
		System.assertEquals(1, filteredByAccountId.size(), '1 Contacts should have remained in the list');
		System.assertEquals(contacts[2], filteredByAccountId[0], 'Last Contact from list should have remained');

		List<sObject> emptyResult = ListUtil.filter(new List<Contact>(), Contact.AccountId, new Set<Id>{ accountIds[0] });
		System.assertEquals(0, emptyResult.size(), 'Method should be safe for empty list');

		emptyResult = ListUtil.filter(null, Contact.AccountId, new Set<Id>{ accountIds[0] });
		System.assertEquals(0, emptyResult.size(), 'Method should be safe for null list');
	}

	@IsTest
	static void testGetIdFieldMap() {
		Map<Id, Id> contactToAccountId = ListUtil.getIdFieldMap(contacts, Contact.Id, Contact.AccountId);
		System.assertEquals(contactIds.size(), contactToAccountId.size(), 'Incorrectly constructed keyset of Contact Ids');
		for (Contact testContact : contacts) {
			System.assertEquals(testContact.AccountId, contactToAccountId.get(testContact.Id), 'Incorrectly mapped Contact to Account Id');
		}

		Map<Id, Id> emptyResult = ListUtil.getIdFieldMap(new List<Contact>(), Contact.Id, Contact.AccountId);
		System.assertEquals(0, emptyResult.size(), 'Method should be safe for empty list');

		emptyResult = ListUtil.getIdFieldMap(null, Contact.Id, Contact.AccountId);
		System.assertEquals(0, emptyResult.size(), 'Method should be safe for null list');
	}

	@IsTest
	static void testMapByKey() {
		Map<Object, Contact> accountToContacts = (Map<Object, Contact>) ListUtil.mapByKey(contacts, Contact.FirstName);
		System.assertEquals(accountIds.size(), accountToContacts.size(), 'Incorrectly constructed keyset of Account Ids');

		Map<Object, Contact> emptyResult = (Map<Object, Contact>) ListUtil.mapByKey(new List<Contact>(), Contact.FirstName);
		System.assertEquals(0, emptyResult.size(), 'Method should be safe for empty list');

		emptyResult = (Map<Object, Contact>) ListUtil.mapByKey(null, Contact.FirstName);
		System.assertEquals(0, emptyResult.size(), 'Method should be safe for null list');
	}

	@IsTest
	static void testMapById() {
		Map<Id, Contact> accountToContacts = (Map<Id, Contact>) ListUtil.mapById(contacts, Contact.AccountId);
		System.assertEquals(accountIds.size(), accountToContacts.size(), 'Incorrectly constructed keyset of Account Ids');

		Map<Id, Contact> emptyResult = (Map<Id, Contact>) ListUtil.mapById(new List<Contact>(), Contact.AccountId);
		System.assertEquals(0, emptyResult.size(), 'Method should be safe for empty list');

		emptyResult = (Map<Id, Contact>) ListUtil.mapById(null, Contact.AccountId);
		System.assertEquals(0, emptyResult.size(), 'Method should be safe for null list');
	}

	@IsTest
	static void testMapToListById() {
		Map<Id, List<Contact>> accountToContacts = ListUtil.mapToListById(contacts, Contact.AccountId);
		System.assertEquals(accountIds.size(), accountToContacts.size(), 'Incorrectly constructed keyset of Account Ids');
		System.assertEquals(2, accountToContacts.get(accountIds[0]).size(), 'Contact list for ' + accountIds[0] + ' is not correct');
		System.assertEquals(1, accountToContacts.get(accountIds[1]).size(), 'Contact list for ' + accountIds[1] + ' is not correct');

		Map<Id, List<Contact>> emptyResult = ListUtil.mapToListById(new List<Contact>(), Contact.AccountId);
		System.assertEquals(0, emptyResult.size(), 'Method should be safe for empty list');

		emptyResult = ListUtil.mapToListById(null, Contact.AccountId);
		System.assertEquals(0, emptyResult.size(), 'Method should be safe for null list');
	}
}
