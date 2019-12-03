public class CreatePlanData {
    
    
    public void CreatePlanData(){
        StaticResource sr = [SELECT Id,Name,Body,SystemModStamp
                             FROM StaticResource 
                             WHERE Name = 'PocData'
                             LIMIT 1];
        
        list<Plan__c> planInsertList = new list<Plan__c>();
        list<Cost_Share__c> csInsertList = new list<Cost_Share__c>();
        Map<String, Schema.SObjectField> planFieldMap =  Plan__c.sObjectType.getDescribe().fields.getMap();     
        Map<String, Object> fullDataMap = (Map<String, Object>) JSON.deserializeUntyped(sr.Body.toString());        
        Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(JSON.serialize(fullDataMap.get('response')));       
        list<Object> docList = (list<Object>) JSON.deserializeUntyped(JSON.serialize(responseMap.get('docs')));
        list<object> csList = new list<object>();
        
        
        
        for(Object ob:docList){
            
            Map<String, Object> recMap = (Map<String, Object>)ob;
            
            Plan__c p = new Plan__c();
            
            // Set default fields and values
            p.Name = (string) recMap.get('udfplan_enterprisePlnNme');
            p.planExternalId__c = (string) recMap.get('objectId');
            
            
            for(Schema.SObjectField fieldName:planFieldMap.values()){
                
                string fieldJson = string.valueOf(fieldName).removeEnd('__c');
                if(recMap.containsKey(fieldJson)){
                    
                    string fieldType =string.valueOf(fieldName.getDescribe().getType()); 
                    if(fieldType=='MULTIPICKLIST')
                    {                        
                        string pickListValues;
                        if(string.valueof(fieldName)=='providerTier__c')
                            pickListValues = string.valueOf(recMap.get('providerTierDisplayNames'));
                        else
                            pickListValues = string.valueOf(recMap.get(fieldJson));
                        
                        string multiSelectString;
                        for(string pi:pickListValues.split(',')){
                            multiSelectString = multiSelectString + pi +';';
                        }
                        
                        if(string.valueof(fieldName)=='providerTier__c')
                            p.put('providerTier__c',multiSelectString.removeEnd(';').remove('null').remove('(').remove(')'));
                        else
                            p.put(fieldName,multiSelectString.removeEnd(';').remove('null').remove('(').remove(')'));
                    }
                    else if(fieldType=='DOUBLE')
                        p.put(fieldName,(decimal) recMap.get(fieldJson));
                    else if(fieldType=='PICKLIST')
                    {
                        
                        if(recMap.get(fieldJson)==true)
                            p.put(fieldName,'Yes');
                        else if(recMap.get(fieldJson)==false)
                            p.put(fieldName,'No'); 
                        else if(fieldJson=='planYear' || fieldJson=='state' || fieldJson=='productClasses')
                            p.put(fieldName,((list<object>) recMap.get(fieldJson))[0]);                                         
                        else
                            p.put(fieldName,recMap.get(fieldJson));                                     
                        
                    }
                    else if(fieldType=='Date')
                    {  
                        list<string> dateList = string.valueOf(recMap.get(fieldJson)).split('T');
                        p.put(fieldName,Date.valueOf(dateList[0]));
                    }
                    else
                        p.put(fieldName,recMap.get(fieldJson));
                } 
            }
            
            planInsertList.add(p);
            
            csList.addAll((list<Object>) JSON.deserializeUntyped(JSON.serialize(recMap.get('planCostShares'))));
            
        }
        
        
        try{
            insert planInsertList;
        }Catch(Exception e){
            system.debug('--exception--'+e);
        }
        
        
        
        for(object csOb: csList){
            
            Map<String, Object> csMap = (Map<String, Object>)csOb;
            
            Cost_Share__c  cs = new Cost_Share__c ();
            cs.Name = (string) csMap.get('costShareType');
            cs.format__c = (string) csMap.get('format');
            cs.costShareLevel__c=string.valueOf(csMap.get('costShareLevel'));
            cs.costShareType__c=string.valueOf(csMap.get('costShareType'));
            cs.providerTier__c= string.valueOf(csMap.get('providerTier'))!='NA'? string.valueOf(csMap.get('providerTier')):'In Network';
            cs.costShareTypeDesc__c=string.valueOf(csMap.get('costShareTypeDesc'));
            cs.default__c=integer.valueOf(csMap.get('default'));
            cs.from__c=integer.valueOf(csMap.get('from'));
            cs.intervalName__c=string.valueOf(csMap.get('intervalName'));
            cs.isRangeValidationEnforced__c=false;
            cs.isZeroAllowed__c=true;
            cs.max__c=integer.valueOf(csMap.get('max'));
            cs.min__c=integer.valueOf(csMap.get('min'));
            cs.plan__r=new Plan__c(planExternalId__c = string.valueOf(csMap.get('parentId')));
            cs.scale__c=integer.valueOf(csMap.get('scale'));
            cs.selectedValue__c=integer.valueOf(csMap.get('selectedValue'));
            cs.severityLevel__c=(string) csMap.get('severityLevel');
            cs.step__c=integer.valueOf(csMap.get('step'));
            cs.to__c=integer.valueOf(csMap.get('to'));
            csInsertList.add(cs);
        }
        
        try{
            Database.insert(csInsertList,false);
        }Catch(Exception e){
            system.debug('--exception-in cs-'+e);
        }
        
        
        
    }
    
    
    
}