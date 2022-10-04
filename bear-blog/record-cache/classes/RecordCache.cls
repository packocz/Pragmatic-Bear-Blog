public abstract inherited sharing class RecordCache implements IRecordCache {
	public interface IConstructable {
		IRecordCache construct(IRecordCacheProvider provider);
	}

	private static Map<String, IRecordCache> cacheMap = new Map<String, IRecordCache>();

	protected IRecordCacheProvider provider;
	protected SObjectField keyField;

	protected RecordCache(IRecordCacheProvider provider) {
		this.provider = provider;
		this.keyField = provider.getKeyField();
	}

	public static IRecordCache getRecordCache(System.Type cacheType, IRecordCacheProvider provider) {
		String uniqueCachekey = cacheType.toString() + provider.getUniqueCacheIdentifier();
		if (!cacheMap.containsKey(uniqueCachekey)) {
			cacheMap.put(uniqueCachekey, newInstance(cacheType, provider));
		}
		return cacheMap.get(uniqueCachekey);
	}

	private static IRecordCache newInstance(System.Type cacheType, IRecordCacheProvider provider) {
		String constructorTypeName = String.valueOf(cacheType) + '.Constructor';
		Object constructorObject = Type.forName(constructorTypeName).newInstance();
		return ((RecordCache.IConstructable) constructorObject).construct(provider);
	}

	public static void clearAll() {
		cacheMap = new Map<String, IRecordCache>();
	}

	public abstract void clear();

	public abstract void remove(Set<String> keys);

	public abstract Set<String> getKeys();

	public List<SObject> getRecords(Set<String> keys) {
		List<SObject> matchingResults = new List<SObject>();
		for (List<SObject> cachedResult : getRecordsMap(keys).values()) {
			matchingResults.addAll(cachedResult);
		}
		return matchingResults;
	}

	public List<SObject> getRecords(Set<Id> keys) {
		return getRecords(convertToString(keys));
	}

	public Map<String, List<SObject>> getRecordsMap(Set<String> keys) {
		Map<String, List<SObject>> cachedResults = getFromCache(keys);
		Set<String> keysNotItCache = new Set<String>(keys);
		keysNotItCache.removeAll(cachedResults.keySet());
		if (!keysNotItCache.isEmpty()) {
			Map<String, List<SObject>> queriedRecords = this.provider.fetchRecordsMap(keysNotItCache);
			keysNotItCache.removeAll(queriedRecords.keySet());
			queriedRecords.putAll(getEmptyListsForKeysWithoutResults(keysNotItCache));
			cacheFetched(queriedRecords);
			cachedResults.putAll(queriedRecords);
		}
		return cachedResults;
	}

	public Map<Id, List<SObject>> getRecordsMap(Set<Id> keys) {
		return convertToIdMap(getRecordsMap(convertToString(keys)));
	}

	protected abstract Map<String, List<SObject>> getFromCache(Set<String> keys);
	protected abstract void cacheFetched(Map<String, List<SObject>> fetchedRecords);

	private Map<String, List<SObject>> getEmptyListsForKeysWithoutResults(Set<String> keys) {
		Map<String, List<SObject>> emptyResults = new Map<String, List<SObject>>();
		for (String key : keys) {
			emptyResults.put(key, new List<SObject>());
		}
		return emptyResults;
	}

	private static Set<Id> convertKeys(Set<String> keys) {
		Set<Id> ids = new Set<Id>();
		for (String key : keys) {
			ids.add((Id) key);
		}
		return ids;
	}

	private static Set<String> convertToString(Set<Id> ids) {
		return new Set<String>((List<String>) new List<Id>(ids));
	}

	public static Map<Id, List<SObject>> convertToIdMap(Map<String, List<SObject>> recordsMap) {
		return (Map<Id, List<SObject>>) JSON.deserialize(JSON.serialize(recordsMap), Map<Id, List<SObject>>.class);
	}
}
