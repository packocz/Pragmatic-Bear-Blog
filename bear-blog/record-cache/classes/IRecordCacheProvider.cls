public interface IRecordCacheProvider {
	List<SObject> fetchRecords(Set<String> keys);
	Map<String, List<SObject>> fetchRecordsMap(Set<String> keys);
	SObjectField getKeyField();
	String getUniqueCacheIdentifier();
}
