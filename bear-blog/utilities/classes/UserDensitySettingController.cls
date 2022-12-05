public with sharing class UserDensitySettingController {
    public static final String DEFAULT_DENSITY = 'VIEW_ONE'; //can't access programatically

    @AuraEnabled(cacheable=true)
    public static String getRunningUserUiDensitySetting() {
        Id runningUserId = UserInfo.getUserId();
        try {
            List<UserPreference> userDensityPreferences = [SELECT Value FROM UserPreference WHERE Preference = '108'];
            if (!userDensityPreferences.isEmpty()) {
                return userDensityPreferences[0].Value;
            }
            return DEFAULT_DENSITY;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
}
