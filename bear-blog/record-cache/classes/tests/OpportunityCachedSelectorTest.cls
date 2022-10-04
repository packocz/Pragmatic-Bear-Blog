@IsTest
private class OpportunityCachedSelectorTest {
	@TestSetup
	static void makeData() {
		List<Account> accs = new List<Account>{ new Account(Name = 'packocz'), new Account(Name = 'Pragmatic Bear') };
		insert accs;

		List<Opportunity> opps = new List<Opportunity>{
			new Opportunity(StageName = 'New', CloseDate = System.today(), Name = 'packo opp 1', AccountId = accs[0].Id),
			new Opportunity(StageName = 'New', CloseDate = System.today(), Name = 'packo opp 2', AccountId = accs[0].Id),
			new Opportunity(StageName = 'New', CloseDate = System.today(), Name = 'bear opp 1', AccountId = accs[1].Id)
		};
		insert opps;
	}

	@IsTest
	static void whenNonCachedSelectorUsed_allCallsResultToQuery() {
		List<Id> oppIds = new List<Id>(new Map<Id, Opportunity>([SELECT Id FROM Opportunity]).keySet());
		Integer queriesDoneBeforeTest = Limits.getQueries();

		OpportunitySelector s = new OpportunitySelector();
		//first call to get ALL records
		System.assertEquals(3, s.selectById(new Set<Id>(oppIds)).size(), 'All 3 created Opportunities should have been queried');
		//then get some records individually
		System.assertEquals(1, s.selectById(new Set<Id>{ oppIds[1] }).size(), 'One record matching an Ids should have been returned');
		System.assertEquals(1, s.selectById(new Set<Id>{ oppIds[0] }).size(), 'One record matching an Ids should have been returned');
		Integer queriesDoneAfterTest = Limits.getQueries();
		System.assertEquals(3, queriesDoneAfterTest - queriesDoneBeforeTest, 'Each call should have resulted in a new query');
	}

	@IsTest
	static void whenRecordCached_onlyOneQueryDone() {
		List<Id> oppIds = new List<Id>(new Map<Id, Opportunity>([SELECT Id FROM Opportunity]).keySet());
		Integer queriesDoneBeforeTest = Limits.getQueries();

		OpportunitySelector s = new OpportunityCachedSelector();
		//first call to get ALL records
		System.assertEquals(3, s.selectById(new Set<Id>(oppIds)).size(), 'All 3 created Opportunities should have been queried');
		//get recrod previously cached
		System.assertEquals(1, s.selectById(new Set<Id>{ oppIds[1] }).size(), 'One record matching an Ids should have been returned');
		Integer queriesDoneAfterTest = Limits.getQueries();
		System.assertEquals(1, queriesDoneAfterTest - queriesDoneBeforeTest, 'Only 1 query should have been performed');
	}

	@IsTest
	static void whenRecordNotCached_newQueryDone() {
		List<Id> oppIds = new List<Id>(new Map<Id, Opportunity>([SELECT Id FROM Opportunity]).keySet());
		Integer queriesDoneBeforeTest = Limits.getQueries();

		OpportunitySelector s = new OpportunityCachedSelector();
		//first call to get 2 of the records
		System.assertEquals(
			2,
			s.selectById(new Set<Id>{ oppIds[0], oppIds[1] }).size(),
			'2 of the created Opportunities should have been queried'
		);
		//get recrod not previously cached
		System.assertEquals(1, s.selectById(new Set<Id>{ oppIds[2] }).size(), 'One record matching an Ids should have been returned');
		Integer queriesDoneAfterTest = Limits.getQueries();
		System.assertEquals(2, queriesDoneAfterTest - queriesDoneBeforeTest, '2 separate queries should have been performed');
	}

	@IsTest
	static void whenOpportunityUpdated_cacheIsSkipped() {
		Opportunity testOpp = [SELECT Id, Name, StageName FROM Opportunity LIMIT 1];
		String newName = 'New Name for Opp';

		OpportunitySelector s = new OpportunityCachedSelector();
		Opportunity firstQueryOpp = s.selectById(new Set<Id>{ testOpp.Id })[0];

		update new Opportunity(Id = testOpp.Id, Name = newName);

		Opportunity postUpdateQueryOpp = s.selectById(new Set<Id>{ testOpp.Id })[0];
		System.assertEquals(newName, postUpdateQueryOpp.Name, 'The name of the opportunity was updated and cache should have been reset');
	}

	@IsTest
	static void whenOpportunityUpdated_cacheByAccountIdIsSkipped() {
		Account newAccountForOpp = [SELECT Id FROM Account WHERE Name = 'packocz' LIMIT 1];
		Opportunity testOpp = [SELECT Id, Name, StageName FROM Opportunity WHERE AccountId != :newAccountForOpp.Id LIMIT 1];

		OpportunitySelector s = new OpportunityCachedSelector();
		List<Opportunity> firstQueryOpps = s.selectByAccountId(new Set<Id>{ newAccountForOpp.Id }).get(newAccountForOpp.Id);
		System.assertEquals(2, firstQueryOpps.size(), 'First load should find 2 Opportunities for the Account');

		update new Opportunity(Id = testOpp.Id, AccountId = newAccountForOpp.Id);

		List<Opportunity> postUpdateQueryOpps = s.selectByAccountId(new Set<Id>{ newAccountForOpp.Id }).get(newAccountForOpp.Id);
		System.assertEquals(3, postUpdateQueryOpps.size(), 'A new Opportunity was added to the Account and cache should have been reset');
	}
}
