/**
 * @description Service class for managing loan charges
 */
public with sharing class LoanChargeService {
    
    private static final String RELEASE_CHARGE_TYPE = 'Release Charge';
    private static final String ADMIN_FEE_TYPE = 'Admin Fee';
    private static final String INTEREST_CHARGE_TYPE = 'Interest Charge';
    private static final String LEGAL_FEE_TYPE = 'Legal Fee';
    private static final Decimal RELEASE_CHARGE_AMOUNT = 500.00;
    private static final Decimal ADMIN_FEE_AMOUNT = 300.00;
    
    // Processing order priorities (lower number = higher priority)
    private static final Map<String, Integer> CHARGE_TYPE_PRIORITY = new Map<String, Integer>{
        ADMIN_FEE_TYPE => 1,
        LEGAL_FEE_TYPE => 2,
        INTEREST_CHARGE_TYPE => 3,
        RELEASE_CHARGE_TYPE => 4
    };
    
    /**
     * @description Assigns processing order to charges based on charge type
     * @param charges List of loan charges to assign processing order
     */
    public static void assignProcessingOrder(List<Loan_Charge__c> charges) {
        for (Loan_Charge__c charge : charges) {
            if (CHARGE_TYPE_PRIORITY.containsKey(charge.Charge_Type__c)) {
                charge.Processing_Order__c = CHARGE_TYPE_PRIORITY.get(charge.Charge_Type__c);
            } else {
                // Default priority for unknown charge types
                charge.Processing_Order__c = 99;
            }
        }
    }
    
    /**
     * @description Creates release charges for new loans
     * @param loans List of Loan records
     */
    public static void createReleaseCharges(List<Loan__c> loans) {
        List<Loan_Charge__c> releaseCharges = new List<Loan_Charge__c>();
        
        for (Loan__c loan : loans) {
            if (loan.Date_Loan_Issued__c != null && loan.Term__c != null) {
                Date releaseDate = loan.Date_Loan_Issued__c.addMonths(Integer.valueOf(loan.Term__c));
                
                Loan_Charge__c releaseCharge = new Loan_Charge__c(
                    Loan__c = loan.Id,
                    Charge_Type__c = RELEASE_CHARGE_TYPE,
                    Amount__c = RELEASE_CHARGE_AMOUNT,
                    Date__c = releaseDate,
                    Processing_Order__c = CHARGE_TYPE_PRIORITY.get(RELEASE_CHARGE_TYPE)
                );
                releaseCharges.add(releaseCharge);
            }
        }
        
        if (!releaseCharges.isEmpty()) {
            try {
                insert releaseCharges;
            } catch (Exception e) {
                // Log error and add to loan record
                for (Loan__c loan : loans) {
                    loan.addError('Failed to create release charge: ' + e.getMessage());
                }
            }
        }
    }
    
    /**
     * @description Handles term changes for loans
     * @param loansWithTermChanges List of loans with term changes
     * @param oldLoanMap Map of old loan values
     */
    public static void handleTermChanges(List<Loan__c> loansWithTermChanges, Map<Id, Loan__c> oldLoanMap) {
        Set<Id> loanIds = new Set<Id>();
        for (Loan__c loan : loansWithTermChanges) {
            loanIds.add(loan.Id);
        }
        
        // Get existing release charges
        Map<Id, Loan_Charge__c> releaseChargesByLoan = new Map<Id, Loan_Charge__c>();
        for (Loan_Charge__c charge : [
            SELECT Id, Loan__c, Date__c
            FROM Loan_Charge__c
            WHERE Loan__c IN :loanIds
            AND Charge_Type__c = :RELEASE_CHARGE_TYPE
        ]) {
            releaseChargesByLoan.put(charge.Loan__c, charge);
        }
        
        List<Loan_Charge__c> chargesToUpdate = new List<Loan_Charge__c>();
        List<Loan_Charge__c> adminFeesToInsert = new List<Loan_Charge__c>();
        
        for (Loan__c loan : loansWithTermChanges) {
            // Update release charge date
            if (releaseChargesByLoan.containsKey(loan.Id)) {
                Loan_Charge__c releaseCharge = releaseChargesByLoan.get(loan.Id);
                Date newReleaseDate = loan.Date_Loan_Issued__c.addMonths(Integer.valueOf(loan.Term__c));
                releaseCharge.Date__c = newReleaseDate;
                chargesToUpdate.add(releaseCharge);
            }
            
            // Create admin fee with proper processing order
            Loan_Charge__c adminFee = new Loan_Charge__c(
                Loan__c = loan.Id,
                Charge_Type__c = ADMIN_FEE_TYPE,
                Amount__c = ADMIN_FEE_AMOUNT,
                Date__c = Date.today(),
                Processing_Order__c = CHARGE_TYPE_PRIORITY.get(ADMIN_FEE_TYPE)
            );
            adminFeesToInsert.add(adminFee);
        }
        
        try {
            if (!chargesToUpdate.isEmpty()) {
                update chargesToUpdate;
            }
            if (!adminFeesToInsert.isEmpty()) {
                insert adminFeesToInsert;
            }
        } catch (Exception e) {
            for (Loan__c loan : loansWithTermChanges) {
                loan.addError('Failed to update charges for term change: ' + e.getMessage());
            }
        }
    }
    
    /**
     * @description Validates that only one release charge exists per loan
     * @param newCharges List of new loan charges
     */
    public static void validateReleaseCharges(List<Loan_Charge__c> newCharges) {
        Set<Id> loanIds = new Set<Id>();
        List<Loan_Charge__c> releaseCharges = new List<Loan_Charge__c>();
        
        // Collect loan IDs for release charges
        for (Loan_Charge__c charge : newCharges) {
            if (charge.Charge_Type__c == RELEASE_CHARGE_TYPE) {
                loanIds.add(charge.Loan__c);
                releaseCharges.add(charge);
            }
        }
        
        if (loanIds.isEmpty()) return;
        
        // Check for existing release charges
        Map<Id, Integer> existingReleaseCharges = new Map<Id, Integer>();
        for (AggregateResult ar : [
            SELECT Loan__c, COUNT(Id) chargeCount
            FROM Loan_Charge__c
            WHERE Loan__c IN :loanIds
            AND Charge_Type__c = :RELEASE_CHARGE_TYPE
            GROUP BY Loan__c
        ]) {
            existingReleaseCharges.put((Id)ar.get('Loan__c'), (Integer)ar.get('chargeCount'));
        }
        
        // Add errors for loans that already have release charges
        for (Loan_Charge__c charge : releaseCharges) {
            if (existingReleaseCharges.containsKey(charge.Loan__c) && 
                existingReleaseCharges.get(charge.Loan__c) > 0) {
                charge.addError('A loan can only have one Release Charge.');
            }
        }
    }
    
    /**
     * @description Handles release charge date adjustments for new charges
     * @param newCharges List of new loan charges
     */
    public static void handleReleaseChargeAdjustments(List<Loan_Charge__c> newCharges) {
        Set<Id> loanIds = new Set<Id>();
        List<Loan_Charge__c> nonReleaseCharges = new List<Loan_Charge__c>();
        
        // Collect non-release charges
        for (Loan_Charge__c charge : newCharges) {
            if (charge.Charge_Type__c != RELEASE_CHARGE_TYPE) {
                loanIds.add(charge.Loan__c);
                nonReleaseCharges.add(charge);
            }
        }
        
        if (loanIds.isEmpty()) return;
        
        // Get existing release charges
        Map<Id, Loan_Charge__c> releaseChargesByLoan = new Map<Id, Loan_Charge__c>();
        for (Loan_Charge__c charge : [
            SELECT Id, Loan__c, Date__c
            FROM Loan_Charge__c
            WHERE Loan__c IN :loanIds
            AND Charge_Type__c = :RELEASE_CHARGE_TYPE
        ]) {
            releaseChargesByLoan.put(charge.Loan__c, charge);
        }
        
        List<Loan_Charge__c> chargesToUpdate = new List<Loan_Charge__c>();
        
        for (Loan_Charge__c newCharge : nonReleaseCharges) {
            if (releaseChargesByLoan.containsKey(newCharge.Loan__c)) {
                Loan_Charge__c releaseCharge = releaseChargesByLoan.get(newCharge.Loan__c);
                
                // If new charge date is on or after release charge date, extend release charge by one month
                if (newCharge.Date__c >= releaseCharge.Date__c) {
                    releaseCharge.Date__c = releaseCharge.Date__c.addMonths(1);
                    chargesToUpdate.add(releaseCharge);
                }
            }
        }
        
        if (!chargesToUpdate.isEmpty()) {
            try {
                update chargesToUpdate;
            } catch (Exception e) {
                for (Loan_Charge__c charge : nonReleaseCharges) {
                    charge.addError('Failed to adjust release charge date: ' + e.getMessage());
                }
            }
        }
    }
}