@IsTest
public class FlexibleMock implements System.StubProvider {
	private Map<String, Map<Integer, Object>> mockMethodAndArgumentResults;

	public FlexibleMock() {
		this.mockMethodAndArgumentResults = new Map<String, Map<Integer, Object>>();
	}

	public Object stub(Type mockedType) {
		return Test.createStub(mockedType, this);
	}

	public FlexibleMock mockMethodCall(String methodName, List<Object> argumentList, Object returnValue) {
		Integer hashCode = argumentList.hashCode();
		System.debug(
			LoggingLevel.FINE,
			String.format(
				'Adding mock response to {0} with argument hashcode {1}',
				new List<String>{ methodName, String.valueOf(hashCode) }
			)
		);
		if (!this.mockMethodAndArgumentResults.containsKey(methodName)) {
			this.mockMethodAndArgumentResults.put(methodName, new Map<Integer, Object>{ hashCode => returnValue });
		} else {
			this.mockMethodAndArgumentResults.get(methodName).put(hashCode, returnValue);
		}
		return this;
	}

	@SuppressWarnings('PMD.ExcessiveParameterList')
	public Object handleMethodCall(
		Object stubbedObject,
		String stubbedMethodName,
		Type returnType,
		List<Type> listOfParamTypes,
		List<String> listOfParamNames,
		List<Object> listOfArgs
	) {
		Integer argumentHash = listOfArgs != null ? listOfArgs.hashCode() : null;
		System.debug(
			LoggingLevel.FINE,
			String.format(
				'Mock method call to {0} with argument hash code {1}',
				new List<String>{ stubbedMethodName, String.valueOf(argumentHash) }
			)
		);
		if (!this.mockMethodAndArgumentResults.containsKey(stubbedMethodName)) {
			throw new FlexibleMockException('Method mock results not registered: ' + stubbedMethodName);
		}
		Map<Integer, Object> methodMocks = this.mockMethodAndArgumentResults.get(stubbedMethodName);
		if (!methodMocks.containsKey(argumentHash)) {
			throw new FlexibleMockException(stubbedMethodName + ' mock results arguments not registered ' + argumentHash);
		}
		return methodMocks.get(argumentHash);
	}

	private class FlexibleMockException extends Exception {
	}
}
