public interface IUnitOfWork extends fflib_ISObjectUnitOfWork {
    List<Id> getNewOrUpdatedIds();
    List<Id> getNewOrUpdatedIds(List<SObjectType> objectTypes);
}
