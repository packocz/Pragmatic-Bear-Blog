/**
 * Inspired by https://github.dev/apex-enterprise-patterns/fflib-apex-common
 */
public inherited sharing virtual class ClassFactory {
	private static Map<Type, Object> interfaceToMockImplementation = new Map<Type, Object>();

	public static Object newInstance(Type requestedType) {
		// Mock implementation?
		if (interfaceToMockImplementation.containsKey(requestedType)) {
			return interfaceToMockImplementation.get(requestedType);
		}

		return requestedType.newInstance();
	}

	@TestVisible
	private static void setMock(Type interfaceType, Object mockImplementation) {
		interfaceToMockImplementation.put(interfaceType, mockImplementation);
	}
}
