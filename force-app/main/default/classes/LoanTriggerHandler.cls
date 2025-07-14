/***************************************************************************
 *  Date:   14July25
 *  Author: James Hodson
 *  Desc:   Handler class for the Loan triggers.
 * *************************************************************************/
public with sharing class LoanTriggerHandler {
    
    // Handles after insert operations on new loans to make sure the release charge is added and the loan balance is correct.
    public static void handleAfterInsert(List<Loan__c> newLoans) {
        LoanChargeService.createReleaseCharges(newLoans);
        LoanBalanceService.updateLoanBalances(newLoans);
    }
    
    // Handles after update operations of updated Loan records to check changes in the term. If so add the admin fee.
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