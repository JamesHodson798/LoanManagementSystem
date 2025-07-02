/**
 * LoanTrigger.trigger
 * @description Trigger for Loan__c object
 */
trigger LoanTrigger on Loan__c (after insert, after update) {
    
    if (Trigger.isAfter) {
        if (Trigger.isInsert) {
            LoanTriggerHandler.handleAfterInsert(Trigger.new);
        }
        
        if (Trigger.isUpdate) {
            LoanTriggerHandler.handleAfterUpdate(Trigger.new, Trigger.oldMap);
        }
    }
}