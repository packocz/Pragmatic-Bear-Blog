trigger AsyncJob on AsyncJob__e(after insert) {
	for (AsyncJob__e event : Trigger.new) {
		String handlerClassName = event.HandlerTypeName__c;
		List<sObject> records = (List<sObject>) JSON.deserialize(event.Payload__c, List<sObject>.class);
		if (records == null || records.isEmpty()) {
			return;
		}
		AsyncJob.executeAsync(records, handlerClassName, Integer.valueOf(event.BatchSize__c), AsyncJob.Strategy.NO_EVENT);
	}
}
