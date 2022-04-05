@IsTest
private class DmlServiceTest {
	@IsTest
	static void insertRecorsSavesWhenSomeCauseErrors() {
		List<Lead> leads = new List<Lead>();
		leads.add(new Lead(FirstName = 'FirstName', LastName = 'LastName', Company = 'Company'));
		leads.add(new Lead(FirstName = 'FirstName')); //won't save due to missing required field

		Test.startTest();

		DmlService.newInstance().databasePartialInsert(leads, 'LeadsInsertTest');
		//invoke logger

		Test.stopTest();

		List<Lead> insertedLeads = [SELECT Id, FirstName, LastName, Company FROM Lead];
		System.assertEquals(1, insertedLeads.size(), 'Only one of the Leads with filled in LastName should have been inserted');
		System.assertEquals(leads[0].LastName, insertedLeads[0].LastName, leads[0] + ' inserted incorrectly');
		//add logging asserts
	}

	@IsTest
	static void insertRecorsDoesNotSaveWhenSomeCauseErrors() {
		List<Lead> leads = new List<Lead>();
		leads.add(new Lead(FirstName = 'FirstName', LastName = 'LastName', Company = 'Company'));
		leads.add(new Lead(FirstName = 'FirstName')); //won't save due to missing required field

		Test.startTest();

		try {
			DmlService.newInstance().databaseInsert(leads, 'LeadsInsertTest');
			System.assert(false, 'Expected DML Exception to be thrown');
		} catch (DmlException e) {
			System.assert(true, 'Expected Exception thrown');
		}
		//invoke logger

		Test.stopTest();

		List<Lead> insertedLeads = [SELECT Id, FirstName, LastName, Company FROM Lead];
		System.assertEquals(0, insertedLeads.size(), 'Noneof the Leads should have been inserted');
		//add logging asserts
	}

	@IsTest
	static void updateRecorsSavesWhenSomeCauseErrors() {
		List<Lead> leads = new List<Lead>();
		leads.add(new Lead(FirstName = 'FirstName', LastName = 'LastName', Company = 'Company'));
		leads.add(new Lead(FirstName = 'FirstName', LastName = 'LastName', Company = 'Company2'));
		insert leads;

		Test.startTest();

		leads[0].LastName = 'NewName';
		leads[1].LastName = null; //won't save due to missing required field
		DmlService.newInstance().databasePartialUpdate(leads, 'LeadsUpdateTest');
		//invoke logger

		Test.stopTest();

		List<Lead> notUpdatedLeads = [SELECT Id, FirstName, LastName, Company FROM Lead WHERE LastName = 'LastName'];
		List<Lead> updatedLeads = [SELECT Id, FirstName, LastName, Company FROM Lead WHERE LastName = 'NewName'];
		System.assertEquals(1, notUpdatedLeads.size(), 'One lead should have stayed the same');
		System.assertEquals(1, updatedLeads.size(), 'One lead shoudl have been updated');
		//add logging asserts
	}

	@IsTest
	static void updateRecorsDoesNotSaveWhenSomeCauseErrors() {
		List<Lead> leads = new List<Lead>();
		leads.add(new Lead(FirstName = 'FirstName', LastName = 'LastName', Company = 'Company'));
		leads.add(new Lead(FirstName = 'FirstName', LastName = 'LastName', Company = 'Company2'));
		insert leads;

		Test.startTest();

		leads[0].LastName = 'NewName';
		leads[1].LastName = null; //won't save due to missing required field
		try {
			DmlService.newInstance().databaseUpdate(leads, 'LeadsUpdateTest');
			System.assert(false, 'Expected DML Exception to be thrown');
		} catch (DmlException e) {
			System.assert(true, 'Expected Exception thrown');
		}
		//invoke logger

		Test.stopTest();

		List<Lead> notUpdatedLeads = [SELECT Id, FirstName, LastName, Company FROM Lead WHERE LastName = 'LastName'];
		List<Lead> updatedLeads = [SELECT Id, FirstName, LastName, Company FROM Lead WHERE LastName = 'NewName'];
		System.assertEquals(2, notUpdatedLeads.size(), 'Both of the leads should have stayed the same');
		System.assertEquals(0, updatedLeads.size(), 'None of the leads shoudl have been updated');
		//add logging asserts
	}
}
