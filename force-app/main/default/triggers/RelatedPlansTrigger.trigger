trigger RelatedPlansTrigger on RelatedPlans__c (before insert) {
    
    
    map<string,set<string>> optionClassMap = new map<string,set<string>>();
    
    for(RelatedPlans__c rp:[select id,Name,Plan__c,Plan__r.productClasses__c,Option__c  from RelatedPlans__c]){
        
        if(optionClassMap.containsKey(rp.Option__c)){
            set<string> prodClassSet = optionClassMap.get(rp.Option__c);
            prodClassSet.add(rp.Plan__r.productClasses__c);
            optionClassMap.put(rp.Option__c,prodClassSet);
        }else{
            set<string> prodClassSet = new set<string>();
            prodClassSet.add(rp.Plan__r.productClasses__c);
            optionClassMap.put(rp.Option__c,prodClassSet);
        }
        
    }
    
    for(RelatedPlans__c so:trigger.new){
        if(optionClassMap.get(so.Option__c).contains(so.ProductClass__c))
            so.addError('Plan with \"'+so.ProductClass__c+'\" product class already exist for this option');
    }
}