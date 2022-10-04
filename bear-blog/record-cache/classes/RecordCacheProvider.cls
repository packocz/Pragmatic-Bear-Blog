public abstract with sharing class RecordCacheProvider implements IRecordCacheProvider {
	protected Selector s;

	private void setSelector(Selector s) {
		this.s = s;
	}

	public static IRecordCacheProvider newInstance(Selector s, Type providerType) {
		RecordCacheProvider provider = (RecordCacheProvider) providerType.newInstance();
		provider.setSelector(s);
		return provider;
	}

	private static Set<Id> convertStringKeysToIds(Set<String> keys) {
		Set<Id> ids = new Set<Id>();
		for (String key : keys) {
			ids.add((Id) key);
		}
		return ids;
	}

	public static Map<String, List<SObject>> convertToStringMap(Map<Id, List<SObject>> recordsMap) {
		return (Map<String, List<SObject>>) JSON.deserialize(JSON.serialize(recordsMap), Map<String, List<SObject>>.class);
	}

	public virtual List<SObject> fetchRecords(Set<String> keys) {
		return fetchRecords(convertStringKeysToIds(keys));
	}

	public virtual List<SObject> fetchRecords(Set<Id> keys) {
		throw new RecordCacheProviderException('Unsupported call: fetchRecords; Not yet implemented!');
	}

	public virtual Map<String, List<SObject>> fetchRecordsMap(Set<String> keys) {
		return convertToStringMap(fetchRecordsMap(convertStringKeysToIds(keys)));
	}

	public virtual Map<Id, List<SObject>> fetchRecordsMap(Set<Id> keys) {
		return ListUtil.mapToListById(fetchRecords(keys), this.getKeyField());
	}

	public virtual String getUniqueCacheIdentifier() {
		String className = String.valueOf(this).split(':')[0];
		return className.left(10) + Math.abs(className.hashCode()); //key must be alphanumeric, hash is sometimes negative and toString adds "-"
	}

	public abstract SObjectField getKeyField();

	public class RecordCacheProviderException extends Exception {
	}
}
