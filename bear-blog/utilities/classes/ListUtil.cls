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

    public static Map<Id, List<sObject>> mapById(List<sObject> records, Schema.sObjectField keyIdField) {
        Map<Id, List<sObject>> result = new Map<Id, List<sObject>>();
        if (records == null || records.isEmpty()) {
            return result;
        }
        for (sObject record : records) {
            Id key = (Id) record.get(keyIdField);
            if (result.containsKey(key)) {
                result.get(key).add(record);
            } else {
                result.put(key, new List<sObject>{ record });
            }
        }
        return result;
    }
}
