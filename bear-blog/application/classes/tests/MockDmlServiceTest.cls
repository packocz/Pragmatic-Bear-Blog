@IsTest
private class MockDmlServiceTest {
	@IsTest
	static void testMockInsert() {
		ClassFactory.setMock(DmlService.class, (DmlService) Test.createStub(DmlService.class, new MockDmlService()));

		Test.startTest();

		Account a = new Account(Name = 'Test');
		DmlService.newInstance().databaseInsert(new List<Account>{ a }, 'None');

		Test.stopTest();

		System.assertEquals(1, MockDmlService.insertedRecords.size());
		Account mockInsertedAccount = (Account) MockDmlService.insertedRecords.values()[0];
		System.assert(String.isNotBlank(mockInsertedAccount.Id));
	}

	@IsTest
	static void testMockPartialInsert() {
		ClassFactory.setMock(DmlService.class, (DmlService) Test.createStub(DmlService.class, new MockDmlService()));

		Test.startTest();

		Account a = new Account(Name = 'Test');
		DmlService.newInstance().databasePartialInsert(new List<Account>{ a }, 'None');

		Test.stopTest();

		System.assertEquals(1, MockDmlService.insertedRecords.size());
		Account mockInsertedAccount = (Account) MockDmlService.insertedRecords.values()[0];
		System.assert(String.isNotBlank(mockInsertedAccount.Id));
	}

	@IsTest
	static void testMockUpdate() {
		ClassFactory.setMock(DmlService.class, (DmlService) Test.createStub(DmlService.class, new MockDmlService()));

		Test.startTest();

		Account a = new Account(Id = FakeId.build(Account.getSObjectType()));
		DmlService.newInstance().databaseUpdate(new List<Account>{ a }, 'None');

		Test.stopTest();

		System.assertEquals(1, MockDmlService.updatedRecords.size());
		System.assert(MockDmlService.updatedRecords.containsKey(a.Id));
	}

	@IsTest
	static void testMockPartialUpdateError() {
		ClassFactory.setMock(DmlService.class, (DmlService) Test.createStub(DmlService.class, new MockDmlService()));
		List<Account> accs = new List<Account>{
			new Account(Id = FakeId.build(Account.getSObjectType())),
			new Account(Id = FakeId.build(Account.getSObjectType()))
		};
		MockDmlService.registerMockDmlError(
			accs[0].Id,
			new List<String>{ 'Missng required field: Name' },
			new List<String>{ 'FIELD_CUSTOM_VALIDATION_EXCEPTION' }
		);

		Test.startTest();

		List<Database.SaveResult> results = DmlService.newInstance().databasePartialUpdate(accs, 'None');

		Test.stopTest();

		System.assertEquals(false, results[0].isSuccess(), 'First account should have failed to be updated');
		System.assertEquals(true, results[1].isSuccess(), 'Second account should have not failed to be updated');
		System.assertEquals(1, MockDmlService.updatedRecords.size());
		System.assert(MockDmlService.updatedRecords.containsKey(accs[1].Id));
	}

	@IsTest
	static void testMockUpdateError() {
		ClassFactory.setMock(DmlService.class, (DmlService) Test.createStub(DmlService.class, new MockDmlService()));
		List<Account> accs = new List<Account>{
			new Account(Id = FakeId.build(Account.getSObjectType())),
			new Account(Id = FakeId.build(Account.getSObjectType()))
		};
		MockDmlService.registerMockDmlError(
			accs[0].Id,
			new List<String>{ 'Missng required field: Name' },
			new List<String>{ 'FIELD_CUSTOM_VALIDATION_EXCEPTION' }
		);

		Test.startTest();
		try {
			List<Database.SaveResult> results = DmlService.newInstance().databaseUpdate(accs, 'None');
			System.assert(false, 'Expected a DML Exception to be thrown');
		} catch (DmlException e) {
			System.assert(true, 'Expected Exception was thrown');
		}

		Test.stopTest();

		System.assertEquals(0, MockDmlService.updatedRecords.size());
	}

	@IsTest
	static void testMockPartialUpdate() {
		ClassFactory.setMock(DmlService.class, (DmlService) Test.createStub(DmlService.class, new MockDmlService()));

		Test.startTest();

		Account a = new Account(Id = FakeId.build(Account.getSObjectType()));
		DmlService.newInstance().databasePartialUpdate(new List<Account>{ a }, 'None');

		Test.stopTest();

		System.assertEquals(1, MockDmlService.updatedRecords.size());
		System.assert(MockDmlService.updatedRecords.containsKey(a.Id));
	}

	@IsTest
	static void testMockDelete() {
		ClassFactory.setMock(DmlService.class, (DmlService) Test.createStub(DmlService.class, new MockDmlService()));

		Test.startTest();

		Account a = new Account(Id = FakeId.build(Account.getSObjectType()));
		DmlService.newInstance().databasePartialDelete(new List<Account>{ a }, 'None');

		Test.stopTest();

		System.assertEquals(1, MockDmlService.deletedRecords.size());
		System.assert(MockDmlService.deletedRecords.containsKey(a.Id));
	}
}
