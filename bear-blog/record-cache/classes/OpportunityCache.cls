public with sharing class OpportunityCache {
	private static Map<String, IRecordCache> cacheMap = new Map<String, IRecordCache>();

	public static IRecordCache getOpportunityCache(System.Type cacheType, IRecordCacheProvider provider) {
		String uniqueCachekey = cacheType.toString() + provider.getUniqueCacheIdentifier();
		if (!cacheMap.containsKey(uniqueCachekey)) {
			cacheMap.put(uniqueCachekey, RecordCache.getRecordCache(cacheType, provider));
		}
		return cacheMap.get(uniqueCachekey);
	}

	public static void clear() {
		for (IRecordCache opportunityCache : cacheMap.values()) {
			opportunityCache.clear();
		}
	}

	public static void remove(Set<Id> ids) {
		for (IRecordCache cache : cacheMap.values()) {
			cache.remove(new Set<String>((List<String>) new List<Id>(ids)));
		}
	}

	public static void removeBasedOnTriggerContext(Map<Id, Opportunity> triggerRecords) {
		Set<Id> accountIds = ListUtil.getUniqueIds(triggerRecords.values(), Opportunity.AccountId);
		remove(triggerRecords.keySet());
		remove(accountIds);
	}
}
