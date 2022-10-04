public inherited sharing class ListUtil {
	public static Set<Id> getUniqueIds(List<sObject> records, Schema.sObjectField keyIdField) {
		Set<Id> result = new Set<Id>();
		if (records == null || records.isEmpty()) {
			return result;
		}
		for (sObject record : records) {
			Id key = (Id) record.get(keyIdField);
			if (key != null) {
				result.add(key);
			}
		}
		return result;
	}

	public static Set<String> getUniqueStrings(List<sObject> records, Schema.sObjectField keyStringField) {
		Set<String> result = new Set<String>();
		if (records == null || records.isEmpty()) {
			return result;
		}
		for (sObject record : records) {
			String key = (String) record.get(keyStringField);
			if (key != null) {
				result.add(key);
			}
		}
		return result;
	}

	public static List<sObject> filter(List<sObject> records, Schema.sObjectField filterIdField, Set<Id> filterIdValues) {
		List<sObject> result = new List<sObject>();
		if (records == null || records.isEmpty()) {
			return result;
		}
		if (filterIdValues == null || filterIdValues.isEmpty()) {
			return new List<sObject>(records);
		}
		for (sObject record : records) {
			Id key = (Id) record.get(filterIdField);
			if (!filterIdValues.contains(key)) {
				result.add(record);
			}
		}
		return result;
	}

	public static Map<Id, Id> getIdFieldMap(List<sObject> records, Schema.sObjectField keyIdField, Schema.sObjectField valueIdField) {
		Map<Id, Id> result = new Map<Id, Id>();
		if (records == null || records.isEmpty()) {
			return result;
		}
		for (sObject record : records) {
			Id key = (Id) record.get(keyIdField);
			if (key != null) {
				result.put(key, (Id) record.get(valueIdField));
			}
		}
		return result;
	}

	public static Map<Id, SObject> mapById(List<SObject> records, Schema.SObjectField keyIdField) {
		String recordObjectName = getFieldSObjectName(keyIdField);
		Map<Id, SObject> result = (Map<Id, SObject>) Type.forName('Map<Id, ' + recordObjectName + '>').newInstance();
		if (records == null || records.isEmpty()) {
			return result;
		}
		for (SObject record : records) {
			Id key = (Id) record.get(keyIdField);
			result.put(key, record);
		}
		return result;
	}

	public static Map<Object, SObject> mapByKey(List<SObject> records, Schema.SObjectField keyIdField) {
		String recordObjectName = getFieldSObjectName(keyIdField);
		Map<Object, SObject> result = (Map<Object, SObject>) Type.forName('Map<Object, ' + recordObjectName + '>').newInstance();
		if (records == null || records.isEmpty()) {
			return result;
		}
		for (SObject record : records) {
			Object key = record.get(keyIdField);
			result.put(key, record);
		}
		return result;
	}

	public static Map<Id, List<sObject>> mapToListById(List<sObject> records, Schema.sObjectField keyIdField) {
		Map<Id, List<sObject>> result = new Map<Id, List<sObject>>();
		Map<String, List<sObject>> mappedRecords = mapToListByKey(records, keyIdField);
		for (String key : mappedRecords.keySet()) {
			result.put((Id) key, mappedRecords.get(key));
		}
		return result;
	}

	public static Map<String, List<SObject>> mapToListByString(List<SObject> records, Schema.SObjectField keyStringField) {
		Map<String, List<SObject>> result = new Map<String, List<SObject>>();
		Map<Object, List<SObject>> mappedRecords = mapToListByObject(records, keyStringField);
		for (Object key : mappedRecords.keySet()) {
			result.put((String) key, mappedRecords.get(key));
		}
		return result;
	}

	public static Map<Object, List<SObject>> mapToListByObject(List<SObject> records, Schema.SObjectField keyField) {
		Map<Object, List<SObject>> result = new Map<Object, List<SObject>>();
		if (records == null || records.isEmpty()) {
			return result;
		}
		for (SObject record : records) {
			Object key = record.get(keyField);
			if (result.containsKey(key)) {
				result.get(key).add(record);
			} else {
				result.put(key, new List<SObject>{ record });
			}
		}
		return result;
	}

	public static Map<String, List<sObject>> mapToListByKey(List<sObject> records, Schema.sObjectField keyField) {
		Map<String, List<sObject>> result = new Map<String, List<sObject>>();
		if (records == null || records.isEmpty()) {
			return result;
		}
		for (sObject record : records) {
			String key = (String) record.get(keyField);
			if (result.containsKey(key)) {
				result.get(key).add(record);
			} else {
				result.put(key, new List<sObject>{ record });
			}
		}
		return result;
	}

	/**
	 * Gets the SObject name from SObject field reference by trying to add
	 * it to Account and getting the name from resulting exception. Potentially
	 * unstable if internal SF implementation fails
	 * https://salesforce.stackexchange.com/questions/32528/how-to-get-sobjecttype-for-a-given-schema-sobjectfield
	 */
	public static String getFieldSObjectName(SObjectField field) {
		try {
			new Account().put(field, null);
			return 'Account';
		} catch (SObjectException e) {
			return e.getMessage().substringBefore('.');
		}
	}
}
