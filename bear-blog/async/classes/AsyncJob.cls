public abstract with sharing class AsyncJob implements Queueable, Database.Batchable<sObject> {
	public static final Integer DEFAULT_BATCH_SIZE = 50;
	public static final Integer BATCHABLE_PREFERRED_SIZE = 5;

	public enum Strategy {
		PREFER_QUEUEABLE,
		QUEUEABLE_ONLY,
		PREFER_BATCH,
		BATCH_ONLY,
		EVENT_ONLY,
		NO_EVENT,
		NO_QUEUEABLE,
		NO_BATCH
	}

	public static AsyncJob newInstance(String className) {
		return (AsyncJob) Type.forName(className).newInstance();
	}

	public static Id executeAsync(List<SObject> records, String className) {
		return executeAsync(AsyncJob.newInstance(className).setRecords(records), Strategy.PREFER_QUEUEABLE);
	}

	public static Id executeAsync(List<SObject> records, String className, Integer batchSize, Strategy asyncStrategy) {
		return executeAsync(AsyncJob.newInstance(className).setRecords(records).setBatchSize(batchSize), asyncStrategy);
	}

	private static Id executeAsync(AsyncJob job, Strategy asyncStrategy) {
		if (job.records == null || job.records.isEmpty()) {
			System.debug(LoggingLevel.DEBUG, 'No records provided. Not running async job!');
			return null;
		}

		Long noOfBatches = Decimal.valueOf(job.records.size() / job.batchSize).round(System.RoundingMode.UP);
		if (
			asyncStrategy == Strategy.QUEUEABLE_ONLY ||
			asyncStrategy == Strategy.NO_BATCH ||
			(noOfBatches < BATCHABLE_PREFERRED_SIZE &&
			asyncStrategy != Strategy.BATCH_ONLY &&
			asyncStrategy != Strategy.NO_QUEUEABLE)
		) {
			return runPreferQueueable(job, asyncStrategy);
		}
		return runPreferBatch(job, asyncStrategy);
	}

	private static Id runPreferBatch(AsyncJob job, Strategy asyncStrategy) {
		if (isBatchAvailable()) {
			return runAsBatch(job);
		} else if (asyncStrategy == Strategy.BATCH_ONLY) {
			throw new AsyncJobException(
				String.format('Cannot run AsyncJob:{0} as Batch. Limit reached!', new List<String>{ job.handlerClassName })
			);
		} else if (isQueueableAvailable()) {
			return runAsQueueable(job);
		} else {
			return runAsEventIfPossibble(job, asyncStrategy);
		}
	}

	private static Id runPreferQueueable(AsyncJob job, Strategy asyncStrategy) {
		if (isQueueableAvailable()) {
			return runAsQueueable(job);
		} else if (asyncStrategy == Strategy.QUEUEABLE_ONLY) {
			throw new AsyncJobException(
				String.format('Cannot run AsyncJob:{0} as Queueable. Limit reached!', new List<String>{ job.handlerClassName })
			);
		}
		if (asyncStrategy != Strategy.NO_BATCH && isBatchAvailable()) {
			return runAsBatch(job);
		} else {
			return runAsEventIfPossibble(job, asyncStrategy);
		}
	}

	private static Id runAsEventIfPossibble(AsyncJob job, Strategy asyncStrategy) {
		if (asyncStrategy == Strategy.NO_EVENT) {
			throw new AsyncJobException(
				String.format('Cannot run AsyncJob:{0} as Queueable or Batch. Limits reached!', new List<String>{ job.handlerClassName })
			);
		}
		runAsEvent(job);
		return null;
	}

	private static Boolean isQueueableAvailable() {
		Integer queueableJobsLimit = Limits.getLimitQueueableJobs();
		Integer queueableJobsUsed = Limits.getQueueableJobs();
		Boolean queueableAvailable = queueableJobsLimit > queueableJobsUsed;
		System.debug(
			LoggingLevel.FINE,
			String.format(
				'AsyncJob Queueable available [{0}]; used: {1}, availalbe {2}',
				new List<String>{
					String.valueOf(queueableAvailable),
					String.valueOf(queueableJobsUsed),
					String.valueof(queueableJobsLimit)
				}
			)
		);
		return queueableAvailable;
	}

	private static Id runAsQueueable(AsyncJob job) {
		Id jobId = System.enqueueJob(job);
		System.debug(
			LoggingLevel.FINE,
			String.format(
				'AsyncJob executed as Queueable Job: {0} , using {1}, records count: {2}, batch size: {3}',
				new List<String>{ jobId, job.handlerClassName, String.valueOf(job.records.size()), String.valueOf(job.batchSize) }
			)
		);
		return jobId;
	}

	private static Boolean isBatchAvailable() {
		Boolean isNotExecutingBatchOrFuture = !System.isBatch() && !System.isFuture();
		Boolean isNotQueueableInTest = !System.isQueueable() || !Test.isRunningTest();
		//TO-DO: Check Flex Queue
		System.debug(
			LoggingLevel.FINE,
			String.format('AsyncJob Batch available [{0}];', new List<String>{ String.valueOf(isNotExecutingBatchOrFuture) })
		);
		return isNotExecutingBatchOrFuture && isNotQueueableInTest;
	}

	private static Id runAsBatch(AsyncJob job) {
		Id jobId = Database.executeBatch(job, job.batchSize);
		System.debug(
			LoggingLevel.FINE,
			String.format(
				'AsyncJob executed as Batch Job: {0} , using {1}, records count: {2}, batch size: {3}',
				new List<String>{ jobId, job.handlerClassName, String.valueOf(job.records.size()), String.valueOf(job.batchSize) }
			)
		);
		return jobId;
	}

	private static void runAsEvent(AsyncJob job) {
		Database.SaveResult publishResult = EventBus.publish(
			new AsyncJob__e(
				Payload__c = JSON.serialize(job.records),
				HandlerTypeName__c = job.handlerClassName,
				BatchSize__c = job.batchSize
			)
		);
		System.debug(
			LoggingLevel.FINE,
			String.format(
				'AsyncJob executed as Platform Event AsyncJob__e: using {0}, records count: {1}, batch size: {2}; {3}',
				new List<String>{
					job.handlerClassName,
					String.valueOf(job.records.size()),
					String.valueOf(job.batchSize),
					String.valueOf(publishResult)
				}
			)
		);
	}

	public Integer batchSize { get; protected set; }
	private List<SObject> recordsToProcess;

	public String handlerClassName {
		get {
			return this.toString();
		}
	}

	public List<SObject> records {
		get {
			return new List<SObject>(this.recordsToProcess);
		}
	}

	public AsyncJob() {
		this.batchSize = DEFAULT_BATCH_SIZE;
		this.recordsToProcess = new List<SObject>();
	}

	public AsyncJob setRecords(List<SObject> records) {
		this.recordsToProcess = records;
		return this;
	}

	public AsyncJob setBatchSize(Integer batchSize) {
		this.batchSize = batchSize;
		return this;
	}

	public abstract void handleBatch(List<SObject> records);
	/**
	 * Must override standard Object toString to return the full
	 * name of the class including any outer class. e.g. AsyncJobTest.TestHandler
	 *
	 * @return return the full name of the Class implementing the interface
	 */
	public abstract override String toString();

	/**
	 * Executed from Batchable finish method or after last handleBatch in Queueable. Sub-classes
	 * should maintain their own supporting data structures.
	 *
	 * !! Does not support Database.Stateful. If member variable persistence across "batches"
	 * is required use Queueable. Ideally NO_BATCH strategy which will fall back to Event when
	 * initialised from context without Queueable jobs left - from there Queueable is available.
	 */
	public virtual void onFinish() {
	}

	public Iterable<SObject> start(Database.BatchableContext bc) {
		return this.recordsToProcess;
	}

	public void execute(Database.BatchableContext context, List<sObject> listForProcessing) {
		try {
			this.handleBatch(listForProcessing);
		} catch (Exception e) {
			System.debug(
				LoggingLevel.ERROR,
				String.format(
					'AsyncJob-Batch:{0}, jobId [{1}], batchSize [{2}], records: [{3}]',
					new List<String>{
						this.handlerClassName,
						context.getJobId(),
						String.valueOf(this.batchSize),
						JSON.serializePretty(this.recordsToProcess)
					}
				)
			);
			//log
			throw new AsyncJobException(e);
		}
	}

	public void execute(QueueableContext context) {
		try {
			System.attachFinalizer(new AsyncJobFinalizer(this));
			handleBatchQueueable();
		} catch (Exception e) {
			System.debug(
				LoggingLevel.ERROR,
				String.format(
					'AsyncJob-Queueable:{0}, jobId [{1}], batchSize [{2}], records: [{3}]',
					new List<String>{
						this.handlerClassName,
						context.getJobId(),
						String.valueOf(this.batchSize),
						JSON.serializePretty(this.recordsToProcess)
					}
				)
			);
			//log
			throw new AsyncJobException(e);
		}
	}

	public void finish(Database.BatchableContext bc) {
		onFinish();
	}

	private void reQueueNotYetProcessedRecords(List<SObject> recordsToStillProcess) {
		if (Test.isRunningTest()) {
			System.debug(LoggingLevel.DEBUG, 'Re-queuing unprocessed reqcords/batches blocked in Unit Tests because of limits!');
			return;
		}
		Id jobId = System.enqueueJob(this.setRecords(recordsToStillProcess));
		System.debug(
			LoggingLevel.DEBUG,
			String.format(
				'AsyncJob Re-queued to continue processing as Queueable Job: {0} , using {1}, records count: {2}, batch size: {3}',
				new List<String>{
					jobId,
					this.handlerClassName,
					String.valueOf(recordsToStillProcess.size()),
					String.valueof(this.batchSize)
				}
			)
		);
	}

	private void handleBatchQueueable() {
		List<SObject> currentBatch = new List<SObject>();
		while (currentBatch.size() < this.batchSize && !this.recordsToProcess.isEmpty()) {
			currentBatch.add(this.recordsToProcess.remove(0));
		}
		this.handleBatch(currentBatch);

		if (this.recordsToProcess.isEmpty()) {
			onFinish();
		} else {
			reQueueNotYetProcessedRecords(this.recordsToProcess);
		}
	}

	private class AsyncJobFinalizer implements Finalizer {
		private AsyncJob process;
		private AsyncJobFinalizer(AsyncJob process) {
			this.process = process;
		}
		public void execute(FinalizerContext context) {
			Id asyncJob = context.getAsyncApexJobId();
			ParentJobResult result = context.getResult();
			Exception exceptionThrown = context.getException();
			if (result == ParentJobResult.UNHANDLED_EXCEPTION) {
				//log
			}
		}
	}

	private class AsyncJobException extends Exception {
	}
}
