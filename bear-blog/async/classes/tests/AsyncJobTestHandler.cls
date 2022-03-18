@IsTest
public class AsyncJobTestHandler extends AsyncJob {
	public static Integer queueableCounter = 0;
	public static Integer batchCounter = 0;
	public static Integer allCounter = 0;
	public static Integer batchesProcessed = 0;

	public override void handleBatch(List<sObject> records) {
		batchesProcessed++;
		for (sObject r : records) {
			allCounter++;
			if (System.isBatch()) {
				batchCounter++;
			} else if (System.isQueueable()) {
				queueableCounter++;
			}
		}
	}

	public override String toString() {
		return 'AsyncJobTestHandler';
	}
}
