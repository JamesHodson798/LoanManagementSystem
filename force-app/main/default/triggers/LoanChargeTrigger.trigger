/***********************************************************************************************************
 *  Date:   14July25
 *  Author: James Hodson
 *  Desc:   Intercepts database operations on the Loan Charge obejct and calls the LoanChargeTriggerHandler.
 * *********************************************************************************************************/
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