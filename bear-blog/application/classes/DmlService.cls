public with sharing class DmlService {
	public static DmlService newInstance() {
		return (DmlService) ClassFactory.newInstance(DmlService.class);
	}

	/**
	 * Run database partial insert operation and prepare log errors for each failed record.
	 * @param sObjectList list of sobjects which will be inserted
	 * @param errorMessageText error message that will be visible in the log header
	 * @return DatabaseSave results for the insert operation
	 */
	public List<Database.SaveResult> databasePartialInsert(List<SObject> sObjectList, String errorMessageText) {
		String sobjectName = String.valueOf(sObjectList[0].getSObjectType());
		if (String.isBlank(errorMessageText)) {
			errorMessageText = sobjectName + ' DML Insert Error';
		}
		Database.SaveResult[] saveResultList = Database.insert(sObjectList, false);
		logErrors(sObjectList, saveResultList, 'INSERT', sobjectName, errorMessageText);
		return saveResultList;
	}

	/**
	 * Run database allOrNothing insert operation and prepare log errors for each failed record.
	 * @param sObjectList list of sobjects which will be inserted
	 * @param errorMessageText error message that will be visible in the log header
	 * @return DatabaseSave results for the insert operation
	 */
	public List<Database.SaveResult> databaseInsert(List<SObject> sObjectList, String errorMessageText) {
		String sobjectName = String.valueOf(sObjectList[0].getSObjectType());
		if (String.isBlank(errorMessageText)) {
			errorMessageText = sobjectName + ' DML Insert Error';
		}
		try {
			Database.SaveResult[] saveResultList = Database.insert(sObjectList, true);
			return saveResultList;
		} catch (System.DmlException e) {
			logErrors(sObjectList, e, 'INSERT', sobjectName, errorMessageText);
			throw e;
		}
	}

	/**
	 * Run database partial update operation and prepare log errors for each failed record.
	 * @param sObjectList list of sobjects which will be updated
	 * @param errorMessageText error message that will be visible in the log header
	 * @return DatabaseSave results for the udpate operation
	 */
	public List<Database.SaveResult> databasePartialUpdate(List<SObject> sObjectList, String errorMessageText) {
		String sobjectName = String.valueOf(sObjectList[0].getSObjectType());
		if (String.isBlank(errorMessageText)) {
			errorMessageText = sobjectName + ' DML Update Error';
		}
		List<Database.SaveResult> saveResultList = Database.update(sObjectList, false);
		logErrors(sObjectList, saveResultList, 'UDPATE', sobjectName, errorMessageText);
		return saveResultList;
	}

	/**
	 * Run database allOrNothing update operation and prepare log errors for each failed record.
	 * @param sObjectList list of sobjects which will be updated
	 * @param errorMessageText error message that will be visible in the log header
	 * @return DatabaseSave results for the udpate operation
	 */
	public List<Database.SaveResult> databaseUpdate(List<SObject> sObjectList, String errorMessageText) {
		String sobjectName = String.valueOf(sObjectList[0].getSObjectType());
		if (String.isBlank(errorMessageText)) {
			errorMessageText = sobjectName + ' DML Update Error';
		}
		try {
			Database.SaveResult[] saveResultList = Database.update(sObjectList, true);
			return saveResultList;
		} catch (System.DmlException e) {
			logErrors(sObjectList, e, 'UPDATE', sobjectName, errorMessageText);
			throw e;
		}
	}

	/**
	 * Run database partial delete operation and prepare log errors for each failed record.
	 * @param sObjectList list of sobjects which will be deleted
	 * @param errorMessageText error message that will be visible in the log header
	 * @return DatabaseSave results for the delete operation
	 */
	public List<Database.DeleteResult> databasePartialDelete(List<SObject> sObjectList, String errorMessageText) {
		String sobjectName = String.valueOf(sObjectList[0].getSObjectType());
		if (String.isBlank(errorMessageText)) {
			errorMessageText = sobjectName + ' DML Delete Error';
		}
		Database.DeleteResult[] deleteResultList = Database.delete(sObjectList, false);
		logErrors(sObjectList, deleteResultList, 'DELETE', sobjectName, errorMessageText);

		return deleteResultList;
	}

	/**
	 * Run database allOrNothing delete operation and prepare log errors for each failed record.
	 * @param sObjectList list of sobjects which will be deleted
	 * @param errorMessageText error message that will be visible in the log header
	 * @return DatabaseSave results for the delete operation
	 */
	public List<Database.DeleteResult> databaseDelete(List<SObject> sObjectList, String errorMessageText) {
		String sobjectName = String.valueOf(sObjectList[0].getSObjectType());
		if (String.isBlank(errorMessageText)) {
			errorMessageText = sobjectName + ' DML Delete Error';
		}
		try {
			Database.DeleteResult[] deleteResultList = Database.delete(sObjectList, true);
			return deleteResultList;
		} catch (System.DmlException e) {
			logErrors(sObjectList, e, 'DELETE', sobjectName, errorMessageText);
			throw e;
		}
	}

	private static void logErrors(
		List<SObject> records,
		List<Database.SaveResult> errorSaveResults,
		String operation,
		String objectName,
		String errorMessageText
	) {
		for (Integer i = 0; i < records.size(); i++) {
			SObject record = records[i];
			Database.SaveResult errorSaveResult = errorSaveResults[i];
			if (!errorSaveResult.isSuccess()) {
				logErrors(record, errorSaveResult.getErrors(), operation, objectName, errorMessageText);
			}
		}
	}

	private static void logErrors(
		List<SObject> records,
		List<Database.DeleteResult> errorDeleteResults,
		String operation,
		String objectName,
		String errorMessageText
	) {
		for (Integer i = 0; i < records.size(); i++) {
			SObject record = records[i];
			Database.DeleteResult errorDeleteResult = errorDeleteResults[i];
			if (!errorDeleteResult.isSuccess()) {
				logErrors(record, errorDeleteResult.getErrors(), operation, objectName, errorMessageText);
			}
		}
	}

	private static void logErrors(
		List<SObject> records,
		DmlException thrownDmlException,
		String operation,
		String objectName,
		String errorMessageText
	) {
		//log with your logger
	}

	private static void logErrors(
		SObject record,
		List<Database.Error> errors,
		String operation,
		String objectName,
		String errorMessageText
	) {
		for (Database.Error err : errors) {
			String errorMessageBody = String.format(
				'Apex DML {0} on {1} FAILED for Record [{2}]\nError [{3}:{4}]\nFields [{5}]',
				new List<String>{
					operation,
					objectName,
					String.valueOf(record),
					String.valueOf(err.getStatusCode()),
					err.getMessage(),
					err.getFields().toString()
				}
			);
			//log with your logger
		}
	}
}
