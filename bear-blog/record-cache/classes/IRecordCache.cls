public interface IRecordCache {
	List<SObject> getRecords(Set<String> keys);
	Map<String, List<SObject>> getRecordsMap(Set<String> keys);
	void clear();
	void remove(Set<String> keys);
	Set<String> getKeys();
}
