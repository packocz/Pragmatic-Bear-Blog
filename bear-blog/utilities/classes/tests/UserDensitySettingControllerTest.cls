@IsTest
private class UserDensitySettingControllerTest {
    @IsTest
    static void methodRespectsPreferences() {
        String densitySettingRetrieved = UserDensitySettingController.getRunningUserUiDensitySetting();

        System.Assert.isNotNull(densitySettingRetrieved, 'Contoller should be able to find a value');
    }
}
