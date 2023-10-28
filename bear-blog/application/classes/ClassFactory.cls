/**
 * Inspired by https://github.dev/apex-enterprise-patterns/fflib-apex-common
 */
public inherited sharing virtual class ClassFactory {
	private static Map<Type, Object> interfaceToMockImplementation = new Map<Type, Object>();

	private static List<SObjectType> objectDependencyOrder = new List<SObjectType>{
		Lead.SObjectType,
		Account.SObjectType,
		Contact.SObjectType
	};

	public static Object newInstance(Type requestedType) {
		// Mock implementation?
		if (interfaceToMockImplementation.containsKey(requestedType)) {
			return interfaceToMockImplementation.get(requestedType);
		}

		return requestedType.newInstance();
	}

	public static fflib_ISObjectUnitOfWork newUnitOfWorkInstance() {
		return newUnitOfWorkInstance(objectDependencyOrder);
	}

	public static fflib_ISObjectUnitOfWork newUnitOfWorkInstance(List<SObjectType> sObjectList) {
		// Mock implementation?
		if (interfaceToMockImplementation.containsKey(fflib_ISObjectUnitOfWork.class)) {
			return (fflib_ISObjectUnitOfWork) interfaceToMockImplementation.get(fflib_ISObjectUnitOfWork.class);
		}

		return new UnitOfWork(sObjectList);
	}

	@TestVisible
	private static void setMock(Type interfaceType, Object mockImplementation) {
		interfaceToMockImplementation.put(interfaceType, mockImplementation);
	}
}
