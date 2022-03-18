@IsTest
public class AsyncJobTest {
	@Future
	private static void runAsyncAsEvent() {
		AsyncJob.executeAsync(getRecords(1), 'AsyncJobTestHandler');
		AsyncJob.executeAsync(getRecords(50), 'AsyncJobTestHandler');
	}

	private static List<Account> getRecords(Integer howMany) {
		List<Account> records = new List<Account>();
		for (Integer i = 0; i < howMany; i++) {
			records.add(new Account(Name = 'Account'));
		}
		return records;
	}

	@IsTest
	static void testQueueable() {
		Test.startTest();
		AsyncJob.executeAsync(getRecords(51), 'AsyncJobTestHandler');
		Test.stopTest();
		System.assertEquals(1, AsyncJobTestHandler.batchesProcessed, '1 Batch should have been handled in total');
		System.assertEquals(50, AsyncJobTestHandler.allCounter, '50 Records should have been handled in total');
		System.assertEquals(
			50,
			AsyncJobTestHandler.queueableCounter,
			'50 Records should have been handled as Queueable, 1 extra not executed in Unit Test'
		);
		System.assertEquals(0, AsyncJobTestHandler.batchCounter, 'No Records should have been handled as Batch');
	}

	@IsTest
	static void testOverflowToBatch() {
		Test.startTest();
		//use up queueable limit
		for (Integer i = 0; i < 50; i++) {
			AsyncJob.executeAsync(getRecords(1), 'AsyncJobTestHandler');
		}
		//expect batch
		AsyncJob.executeAsync(getRecords(10), 'AsyncJobTestHandler');
		Test.stopTest();

		System.assertEquals(60, AsyncJobTestHandler.allCounter, '60 Records should have been handled in total');
		System.assertEquals(50, AsyncJobTestHandler.queueableCounter, '50 Records should have been handled as Queueable');
		System.assertEquals(10, AsyncJobTestHandler.batchCounter, '10 Records should have been handled as Batch');
	}

	@IsTest
	static void testOverflowToEvent() {
		//use batch place on event queue
		runAsyncAsEvent();

		Test.startTest();

		Test.getEventBus().deliver();

		Test.stopTest();

		Test.getEventBus().deliver();

		System.assertEquals(1, AsyncJobTestHandler.allCounter, '1 Records should have been handled in total');
		System.assertEquals(1, AsyncJobTestHandler.queueableCounter, '1 Records should have been handled as Queueable');
		System.assertEquals(0, AsyncJobTestHandler.batchCounter, '0 Records should have been handled as Batch');

		List<AsyncApexJob> queueableJobs = [SELECT Id, Status FROM AsyncApexJob];
		System.assertEquals(2, queueableJobs.size(), 'First limit offset Queueable + Event should have re-scheduled with Queueable');
	}
}
