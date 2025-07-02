/**
 * @description Handler class for Loan__c triggers
 * @author Your Name
 * @date 2025
 */
public with sharing class LoanTriggerHandler {
    
    /**
     * @description Handles after insert operations
     * @param newLoans List of newly inserted Loan records
     */
    public static void handleAfterInsert(List<Loan__c> newLoans) {
        LoanChargeService.createReleaseCharges(newLoans);
        LoanBalanceService.updateLoanBalances(newLoans);
    }
    
    /**
     * @description Handles after update operations
     * @param newLoans List of updated Loan records
     * @param oldLoanMap Map of old Loan records
     */
    public static void handleAfterUpdate(List<Loan__c> newLoans, Map<Id, Loan__c> oldLoanMap) {
        List<Loan__c> loansWithTermChanges = new List<Loan__c>();
        
        // Identify loans with term changes
        for (Loan__c loan : newLoans) {
            Loan__c oldLoan = oldLoanMap.get(loan.Id);
            if (loan.Term__c != oldLoan.Term__c) {
                loansWithTermChanges.add(loan);
            }
        }
        
        if (!loansWithTermChanges.isEmpty()) {
            LoanChargeService.handleTermChanges(loansWithTermChanges, oldLoanMap);
        }
    }
}