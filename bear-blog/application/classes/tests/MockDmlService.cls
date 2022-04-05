@IsTest
public with sharing class MockDmlService implements System.StubProvider {
	public static Map<Id, SObject> insertedRecords = new Map<Id, SObject>();
	public static Map<Id, SObject> updatedRecords = new Map<Id, SObject>();
	public static Map<Id, SObject> deletedRecords = new Map<Id, SObject>();
	//not yet supported for insert
	private static Map<Id, List<String>> mockErrorsMessages = new Map<Id, List<String>>();
	private static Map<Id, List<String>> mockErrorsCodes = new Map<Id, List<String>>();

	public static void registerMockDmlError(Id recordId, List<String> errorMessages, List<String> errorCodes) {
		mockErrorsMessages.put(recordId, errorMessages);
		mockErrorsCodes.put(recordId, errorCodes);
	}

	public static Database.SaveResult mockSaveResult(Id recordId) {
		return mockSaveResult(recordId, true, new List<String>(), new List<String>());
	}

	public static Database.SaveResult mockSaveResult(Id recordId, Boolean success, List<String> messages, List<String> codes) {
		return (Database.SaveResult) JSON.deserialize(
			'{"success":' +
			success +
			',"id":"' +
			recordId +
			'"' +
			mockErrorsString(messages, codes) +
			'}',
			Database.SaveResult.class
		);
	}

	public static Database.DeleteResult mockDeleteResult(Id recordId) {
		return mockDeleteResult(recordId, true, new List<String>(), new List<String>());
	}

	public static Database.DeleteResult mockDeleteResult(Id recordId, Boolean success, List<String> messages, List<String> codes) {
		return (Database.DeleteResult) JSON.deserialize(
			'{"success":' +
			success +
			',"id":"' +
			recordId +
			'"' +
			mockErrorsString(messages, codes) +
			'}',
			Database.DeleteResult.class
		);
	}

	private static String mockErrorsString(List<String> messages, List<String> codes) {
		if (messages.isEmpty()) {
			return '';
		}
		String errorString = ',"errors":[';
		for (Integer i = 0; i < messages.size(); i++) {
			errorString += '{"message":"' + messages[i] + '","statusCode":"' + codes[i] + '"},';
		}
		errorString = errorString.removeEnd(',');
		errorString += ']';
		System.debug(errorString);
		return errorString;
	}
	public List<Database.SaveResult> databaseInsert(List<SObject> sObjectList, String errorMessageText) {
		return databasePartialInsert(sObjectList, errorMessageText);
	}

	public List<Database.SaveResult> databasePartialInsert(List<SObject> sObjectList, String errorMessageText) {
		SObjectType insertedSObjectType = sObjectList[0].getSObjectType();

		List<Database.SaveResult> saveResultList = new List<Database.SaveResult>();
		for (SObject insertedRecord : sObjectList) {
			Id newId = FakeId.build(insertedSObjectType);
			insertedRecord.Id = newId;
			insertedRecords.put(insertedRecord.Id, insertedRecord);
			saveResultList.add(mockSaveResult(newId));
		}
		return saveResultList;
	}

	public List<Database.SaveResult> databaseUpdate(List<SObject> sObjectList, String errorMessageText) {
		List<Database.SaveResult> saveResultList = new List<Database.SaveResult>();
		Map<Id, SObject> updatedRecordsMap = new Map<Id, SObject>();
		for (SObject updatedRecord : sObjectList) {
			Id recordId = updatedRecord.Id;
			if (mockErrorsMessages.containsKey(recordId)) {
				DmlException e = new DmlException();
				e.setMessage(String.join(mockErrorsMessages.get(recordId), ','));
				throw e;
			} else {
				updatedRecordsMap.put(recordId, updatedRecord);
				saveResultList.add(mockSaveResult(recordId));
			}
		}
		updatedRecords.putAll(updatedRecordsMap);
		return saveResultList;
	}

	public List<Database.SaveResult> databasePartialUpdate(List<SObject> sObjectList, String errorMessageText) {
		List<Database.SaveResult> saveResultList = new List<Database.SaveResult>();
		for (SObject updatedRecord : sObjectList) {
			Id recordId = updatedRecord.Id;
			if (mockErrorsMessages.containsKey(recordId)) {
				saveResultList.add(mockSaveResult(recordId, false, mockErrorsMessages.get(recordId), mockErrorsCodes.get(recordId)));
			} else {
				updatedRecords.put(recordId, updatedRecord);
				saveResultList.add(mockSaveResult(recordId));
			}
		}
		return saveResultList;
	}

	public List<Database.DeleteResult> databaseDelete(List<SObject> sObjectList, String errorMessageText) {
		List<Database.DeleteResult> deleteResultList = new List<Database.DeleteResult>();
		Map<Id, SObject> deletedRecordsMap = new Map<Id, SObject>();
		for (SObject deletedRecord : sObjectList) {
			Id recordId = deletedRecord.Id;

			if (mockErrorsMessages.containsKey(recordId)) {
				DmlException e = new DmlException();
				e.setMessage(String.join(mockErrorsMessages.get(recordId), ','));
				throw e;
			} else {
				deletedRecordsMap.put(recordId, deletedRecord);
				deleteResultList.add(mockDeleteResult(recordId));
			}
		}
		deletedRecords.putAll(deletedRecordsMap);
		return deleteResultList;
	}

	public List<Database.DeleteResult> databasePartialDelete(List<SObject> sObjectList, String errorMessageText) {
		List<Database.DeleteResult> deleteResultList = new List<Database.DeleteResult>();
		for (SObject deletedRecord : sObjectList) {
			Id recordId = deletedRecord.Id;
			if (mockErrorsMessages.containsKey(recordId)) {
				deleteResultList.add(mockDeleteResult(recordId, false, mockErrorsMessages.get(recordId), mockErrorsCodes.get(recordId)));
			} else {
				deletedRecords.put(recordId, deletedRecord);
				deleteResultList.add(mockDeleteResult(recordId));
			}
		}
		return deleteResultList;
	}

	public Object handleMethodCall(
		Object stubbedObject,
		String stubbedMethodName,
		Type returnType,
		List<Type> listOfParamTypes,
		List<String> listOfParamNames,
		List<Object> listOfArgs
	) {
		List<SObject> records = (List<SObject>) listOfArgs[0];
		String errorText = (String) listOfArgs[1];
		if ('databasePartialInsert'.equals(stubbedMethodName)) {
			return this.databasePartialInsert(records, errorText);
		} else if ('databasePartialUpdate'.equals(stubbedMethodName)) {
			return this.databasePartialUpdate(records, errorText);
		} else if ('databasePartialDelete'.equals(stubbedMethodName)) {
			return this.databasePartialDelete(records, errorText);
		} else if ('databaseInsert'.equals(stubbedMethodName)) {
			return this.databaseInsert(records, errorText);
		} else if ('databaseUpdate'.equals(stubbedMethodName)) {
			return this.databaseUpdate(records, errorText);
		} else if ('databaseDelete'.equals(stubbedMethodName)) {
			return this.databaseDelete(records, errorText);
		}
		throw new MockDmlServiceException('Unsupported Method Call: ' + stubbedMethodName);
	}

	private class MockDmlServiceException extends Exception {
	}
}
