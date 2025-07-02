/**
 * @description Test class for Loan management functionality
 * @author Your Name
 * @date 2025
 */
@isTest
private class LoanManagementTest {
    
    /**
     * @description Test data setup method
     */
    @TestSetup
    static void setupTestData() {
        // Create test account (Person Account would be ideal, but using standard account for simplicity)
        Account testAccount = new Account(
            Name = 'Test Borrower',
            Type = 'Customer'
        );
        insert testAccount;
    }
    
    /**
     * @description Test creation of loan with automatic release charge
     */
    @isTest
    static void testLoanCreationWithReleaseCharge() {
        Account testAccount = [SELECT Id FROM Account LIMIT 1];
        
        Test.startTest();
        
        Loan__c testLoan = new Loan__c(
            Name = 'Test Loan 001',
            Account__c = testAccount.Id,
            Address__c = '123 Test Street, Test City',
            Gross_Loan_Amount__c = 100000.00,
            Date_Loan_Issued__c = Date.today(),
            Term__c = 12
        );
        insert testLoan;
        
        Test.stopTest();
        
        // Verify loan was created
        Loan__c insertedLoan = [
            SELECT Id, Name, Balance_of_the_Loan__c, Total_Charges_on_the_Loan__c
            FROM Loan__c
            WHERE Id = :testLoan.Id
        ];
        
        // Verify release charge was created
        List<Loan_Charge__c> releaseCharges = [
            SELECT Id, Charge_Type__c, Amount__c, Date__c
            FROM Loan_Charge__c
            WHERE Loan__c = :testLoan.Id
            AND Charge_Type__c = 'Release Charge'
        ];
        
        System.assertEquals(1, releaseCharges.size(), 'Should have exactly one release charge');
        System.assertEquals(500.00, releaseCharges[0].Amount__c, 'Release charge should be £500');
        
        Date expectedReleaseDate = Date.today().addMonths(12);
        System.assertEquals(expectedReleaseDate, releaseCharges[0].Date__c, 'Release date should be loan issue date + term');
        
        // Verify loan balance was updated
        System.assertEquals(100500.00, insertedLoan.Balance_of_the_Loan__c, 'Loan balance should include release charge');
        System.assertEquals(500.00, insertedLoan.Total_Charges_on_the_Loan__c, 'Total charges should equal release charge');
    }
    
    /**
     * @description Test bulk loan creation
     */
    @isTest
    static void testBulkLoanCreation() {
        Account testAccount = [SELECT Id FROM Account LIMIT 1];
        
        List<Loan__c> testLoans = new List<Loan__c>();
        for (Integer i = 1; i <= 200; i++) {
            testLoans.add(new Loan__c(
                Name = 'Bulk Test Loan ' + i,
                Account__c = testAccount.Id,
                Address__c = i + ' Bulk Test Street',
                Gross_Loan_Amount__c = 50000.00,
                Date_Loan_Issued__c = Date.today(),
                Term__c = 24
            ));
        }
        
        Test.startTest();
        insert testLoans;
        Test.stopTest();
        
        // Verify all loans have release charges
        List<Loan_Charge__c> releaseCharges = [
            SELECT Id, Loan__c
            FROM Loan_Charge__c
            WHERE Loan__c IN :testLoans
            AND Charge_Type__c = 'Release Charge'
        ];
        
        System.assertEquals(200, releaseCharges.size(), 'Should have 200 release charges');
        
        // Verify loan balances
        List<Loan__c> updatedLoans = [
            SELECT Id, Balance_of_the_Loan__c
            FROM Loan__c
            WHERE Id IN :testLoans
        ];
        
        for (Loan__c loan : updatedLoans) {
            System.assertEquals(50500.00, loan.Balance_of_the_Loan__c, 'Each loan balance should be gross amount + release charge');
        }
    }
    
    /**
     * @description Test prevention of multiple release charges
     */
    @isTest
    static void testPreventMultipleReleaseCharges() {
        Account testAccount = [SELECT Id FROM Account LIMIT 1];
        
        Loan__c testLoan = new Loan__c(
            Name = 'Test Loan for Multiple Release',
            Account__c = testAccount.Id,
            Gross_Loan_Amount__c = 75000.00,
            Date_Loan_Issued__c = Date.today(),
            Term__c = 18
        );
        insert testLoan;
        
        Test.startTest();
        
        // Try to create additional release charge
        Loan_Charge__c additionalReleaseCharge = new Loan_Charge__c(
            Loan__c = testLoan.Id,
            Charge_Type__c = 'Release Charge',
            Amount__c = 600.00,
            Date__c = Date.today().addMonths(20)
        );
        
        try {
            insert additionalReleaseCharge;
            System.assert(false, 'Should not allow multiple release charges');
        } catch (DmlException e) {
            System.assert(e.getMessage().contains('A loan can only have one Release Charge'), 
                         'Should prevent multiple release charges with appropriate error message');
        }
        
        Test.stopTest();
        
        // Verify only one release charge exists
        List<Loan_Charge__c> releaseCharges = [
            SELECT Id FROM Loan_Charge__c
            WHERE Loan__c = :testLoan.Id
            AND Charge_Type__c = 'Release Charge'
        ];
        
        System.assertEquals(1, releaseCharges.size(), 'Should still have exactly one release charge');
    }
    
    /**
     * @description Test adding new charges and release charge adjustment
     */
    @isTest
    static void testNewChargeAndReleaseChargeAdjustment() {
        Account testAccount = [SELECT Id FROM Account LIMIT 1];
        
        Loan__c testLoan = new Loan__c(
            Name = 'Test Loan for Charge Addition',
            Account__c = testAccount.Id,
            Gross_Loan_Amount__c = 80000.00,
            Date_Loan_Issued__c = Date.today(),
            Term__c = 12
        );
        insert testLoan;
        
        // Get the original release charge
        Loan_Charge__c originalReleaseCharge = [
            SELECT Id, Date__c
            FROM Loan_Charge__c
            WHERE Loan__c = :testLoan.Id
            AND Charge_Type__c = 'Release Charge'
        ];
        
        Date originalReleaseDate = originalReleaseCharge.Date__c;
        
        Test.startTest();
        
        // Add interest charge that falls on the same day as release charge
        Loan_Charge__c interestCharge = new Loan_Charge__c(
            Loan__c = testLoan.Id,
            Charge_Type__c = 'Interest Charge',
            Amount__c = 1500.00,
            Date__c = originalReleaseDate
        );
        insert interestCharge;
        
        Test.stopTest();
        
        // Verify release charge date was extended by one month
        Loan_Charge__c updatedReleaseCharge = [
            SELECT Id, Date__c
            FROM Loan_Charge__c
            WHERE Id = :originalReleaseCharge.Id
        ];
        
        Date expectedNewReleaseDate = originalReleaseDate.addMonths(1);
        System.assertEquals(expectedNewReleaseDate, updatedReleaseCharge.Date__c, 
                           'Release charge date should be extended by one month');
        
        // Verify loan balance was updated
        Loan__c updatedLoan = [
            SELECT Id, Balance_of_the_Loan__c, Total_Charges_on_the_Loan__c
            FROM Loan__c
            WHERE Id = :testLoan.Id
        ];
        
        System.assertEquals(82000.00, updatedLoan.Balance_of_the_Loan__c, 
                           'Loan balance should include both charges');
        System.assertEquals(2000.00, updatedLoan.Total_Charges_on_the_Loan__c, 
                           'Total charges should be release charge + interest charge');
    }
    
    /**
     * @description Test loan term modification and admin fee creation
     */
    @isTest
    static void testLoanTermModification() {
        Account testAccount = [SELECT Id FROM Account LIMIT 1];
        
        Loan__c testLoan = new Loan__c(
            Name = 'Test Loan for Term Modification',
            Account__c = testAccount.Id,
            Gross_Loan_Amount__c = 90000.00,
            Date_Loan_Issued__c = Date.today(),
            Term__c = 12
        );
        insert testLoan;
        
        // Get original release charge
        Loan_Charge__c originalReleaseCharge = [
            SELECT Id, Date__c
            FROM Loan_Charge__c
            WHERE Loan__c = :testLoan.Id
            AND Charge_Type__c = 'Release Charge'
        ];
        
        Test.startTest();
        
        // Modify loan term
        testLoan.Term__c = 24;
        update testLoan;
        
        Test.stopTest();
        
        // Verify release charge date was updated
        Loan_Charge__c updatedReleaseCharge = [
            SELECT Id, Date__c
            FROM Loan_Charge__c
            WHERE Id = :originalReleaseCharge.Id
        ];
        
        Date expectedNewReleaseDate = Date.today().addMonths(24);
        System.assertEquals(expectedNewReleaseDate, updatedReleaseCharge.Date__c, 
                           'Release charge date should reflect new term');
        
        // Verify admin fee was created
        List<Loan_Charge__c> adminFees = [
            SELECT Id, Amount__c, Date__c, Charge_Type__c
            FROM Loan_Charge__c
            WHERE Loan__c = :testLoan.Id
            AND Charge_Type__c = 'Admin Fee'
        ];
        
        System.assertEquals(1, adminFees.size(), 'Should have created one admin fee');
        System.assertEquals(300.00, adminFees[0].Amount__c, 'Admin fee should be £300');
        System.assertEquals(Date.today(), adminFees[0].Date__c, 'Admin fee date should be today');
        
        // Verify loan balance includes admin fee
        Loan__c updatedLoan = [
            SELECT Id, Balance_of_the_Loan__c, Total_Charges_on_the_Loan__c
            FROM Loan__c
            WHERE Id = :testLoan.Id
        ];
        
        System.assertEquals(90800.00, updatedLoan.Balance_of_the_Loan__c, 
                           'Loan balance should include release charge and admin fee');
        System.assertEquals(800.00, updatedLoan.Total_Charges_on_the_Loan__c, 
                           'Total charges should be release charge + admin fee');
    }
    
    /**
     * @description Test charge deletion and balance recalculation
     */
    @isTest
    static void testChargeDeleteAndBalanceRecalculation() {
        Account testAccount = [SELECT Id FROM Account LIMIT 1];
        
        Loan__c testLoan = new Loan__c(
            Name = 'Test Loan for Deletion',
            Account__c = testAccount.Id,
            Gross_Loan_Amount__c = 60000.00,
            Date_Loan_Issued__c = Date.today(),
            Term__c = 6
        );
        insert testLoan;
        
        // Add additional charges
        List<Loan_Charge__c> additionalCharges = new List<Loan_Charge__c>();
        additionalCharges.add(new Loan_Charge__c(
            Loan__c = testLoan.Id,
            Charge_Type__c = 'Legal Fee',
            Amount__c = 750.00,
            Date__c = Date.today().addDays(30)
        ));
        additionalCharges.add(new Loan_Charge__c(
            Loan__c = testLoan.Id,
            Charge_Type__c = 'Interest Charge',
            Amount__c = 1200.00,
            Date__c = Date.today().addDays(60)
        ));
        insert additionalCharges;
        
        // Verify initial balance
        Loan__c loanAfterCharges = [
            SELECT Id, Balance_of_the_Loan__c, Total_Charges_on_the_Loan__c
            FROM Loan__c
            WHERE Id = :testLoan.Id
        ];
        
        System.assertEquals(62450.00, loanAfterCharges.Balance_of_the_Loan__c, 
                           'Initial balance should include all charges');
        
        Test.startTest();
        
        // Delete one charge
        delete additionalCharges[0]; // Delete legal fee
        
        Test.stopTest();
        
        // Verify balance was recalculated
        Loan__c loanAfterDeletion = [
            SELECT Id, Balance_of_the_Loan__c, Total_Charges_on_the_Loan__c
            FROM Loan__c
            WHERE Id = :testLoan.Id
        ];
        
        System.assertEquals(61700.00, loanAfterDeletion.Balance_of_the_Loan__c, 
                           'Balance should be reduced after charge deletion');
        System.assertEquals(1700.00, loanAfterDeletion.Total_Charges_on_the_Loan__c, 
                           'Total charges should exclude deleted charge');
    }
    
    /**
     * @description Test error handling scenarios
     */
    @isTest
    static void testErrorHandling() {
        Test.startTest();
        
        // Test loan creation without required fields
        Loan__c invalidLoan = new Loan__c(
            Name = 'Invalid Loan'
            // Missing required fields
        );
        
        try {
            insert invalidLoan;
            System.assert(false, 'Should fail due to missing required fields');
        } catch (DmlException e) {
            System.assert(e.getMessage().contains('REQUIRED_FIELD_MISSING'), 
                         'Should fail with required field error');
        }
        
        Test.stopTest();
    }
}