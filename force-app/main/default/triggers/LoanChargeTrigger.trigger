/**
 * LoanChargeTrigger.trigger
 * @description Trigger for Loan_Charge__c object
 */
trigger LoanChargeTrigger on Loan_Charge__c (before insert, before update, after insert, after update, after delete) {
    
    if (Trigger.isBefore) {
        if (Trigger.isInsert) {
            LoanChargeTriggerHandler.handleBeforeInsert(Trigger.new);
        }
        
        if (Trigger.isUpdate) {
            LoanChargeTriggerHandler.handleBeforeUpdate(Trigger.new, Trigger.oldMap);
        }
    }
    
    if (Trigger.isAfter) {
        if (Trigger.isInsert) {
            LoanChargeTriggerHandler.handleAfterInsert(Trigger.new);
        }
        
        if (Trigger.isUpdate) {
            LoanChargeTriggerHandler.handleAfterUpdate(Trigger.new, Trigger.oldMap);
        }
        
        if (Trigger.isDelete) {
            LoanChargeTriggerHandler.handleAfterDelete(Trigger.old);
        }
    }
}