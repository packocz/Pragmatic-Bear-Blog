public inherited sharing class RecordCacheStaticVariable extends RecordCache {
	private Map<String, List<SObject>> cache;

	private RecordCacheStaticVariable(IRecordCacheProvider provider) {
		super(provider);
		this.cache = new Map<String, List<SObject>>();
	}

	public override void clear() {
		this.cache.clear();
	}

	public override void remove(Set<String> keys) {
		for (String key : keys) {
			this.cache.remove(key);
		}
	}

	public override Set<String> getKeys() {
		return this.cache.keySet();
	}

	protected override Map<String, List<SObject>> getFromCache(Set<String> keys) {
		Map<String, List<SObject>> matchingResults = new Map<String, List<SObject>>();
		for (String requiredKey : keys) {
			List<SObject> matchingItems = (List<SObject>) this.cache.get(requiredKey);
			if (matchingItems != null) {
				matchingResults.put(requiredKey, matchingItems);
			}
		}
		return matchingResults;
	}

	protected override void cacheFetched(Map<String, List<SObject>> fetchedRecords) {
		for (String requiredKey : fetchedRecords.keySet()) {
			if (fetchedRecords.containsKey(requiredKey)) {
				this.cache.put(requiredKey, fetchedRecords.get(requiredKey));
			} else {
				this.cache.put(requiredKey, null);
			}
		}
	}

	public class Constructor implements RecordCache.IConstructable {
		public IRecordCache construct(IRecordCacheProvider provider) {
			return new RecordCacheStaticVariable(provider);
		}
	}
}
