/*========================================================================================================
* @author Venkat Vishal Reddy Nakka, Deloitte
* @date 27/11/2019
* @description:  Container class for Apex methods to be called from React Application 
Modification Log:
------------------------------------------------------------------------------------
Developer         Mod Number  Date        Description
------------------------------------------------------------------------------------
Vishal Nakka      M-001       27/11/20198  Initial version
==========================================================================================================*/
global class PlanController {
    
    /**
    * Method createOptions
    * @author Venkat Vishal Reddy Nakka
    * @date 27/11/2019
    * @param string of option and related plans
    * @description : This method returns Option Id
    *                
    */  
    @RemoteAction
    global  static string createOptions(string optionsString) {
        
        set<id> planIdset = new set<id>();
        list<RelatedPlans__c> relatedplans = new list<RelatedPlans__c>();
        
        JSONParser parser = JSON.createParser(optionsString);
        while (parser.nextToken() != null) {
            if ((parser.getCurrentToken() == JSONToken.FIELD_NAME) && (parser.getText() == 'option')) {                
                parser.nextToken();
                planIdset.add(parser.getIdValue());                
            }
        }

        system.debug('--planIdset--'+planIdset);
        
        Option__c opt = new Option__c();
        opt.Name='Option';
        insert opt;
        
        for(string planId:planIdset){
            RelatedPlans__c rp = new RelatedPlans__c();
            rp.Option__c=opt.Id;
            rp.Plan__c=planId;
            relatedplans.add(rp);
        }
        
        try{
            insert relatedplans;
        }Catch(Exception e){
            system.debug('--exception in option--'+e);
        }
       return opt.Id;
    }
    
     /**
    * Method getPlanList
    * @author Venkat Vishal Reddy Nakka
    * @date 27/11/2019
    * @param string of searchkeys
    * @description : This method returns list of Plans               
    */  
    @RemoteAction
    global  static list<object> getPlanList(string searchKey) {
        Set<String> planfieldNames = Plan__c.sObjectType.getDescribe().fields.getMap().keySet();
        Set<String> plancostSharefieldNames = Cost_Share__c.sObjectType.getDescribe().fields.getMap().keySet();        
        string costShareQueryString = 'select '+ string.join(new list<string>(plancostSharefieldNames), ',') + ' from Cost_Shares__r';
        string query_String = 'select ' + string.join(new list<string>(planfieldNames), ',') +',(' + costShareQueryString +')'+' from Plan__c';                                      
        return (list<object>) getFormatedPlans(Database.query(query_String));
    }
    
     /**
    * Method getPlansOnSearch
    * @author Venkat Vishal Reddy Nakka
    * @date 27/11/2019
    * @param string of JSON with Plan name, Plan type and related Cost Shares with Min,Max values 
    * @description : This method returns list of Plans based on serch criteria of Cost Shares                
    */ 
    @RemoteAction
    global  static list<object> getPlansOnSearch(string searchJsonString) {
        
        set<string> planIdSet = new set<string>();        
        set<string> csTypes = new set<string>();
        Set<String> planfieldNames = Plan__c.sObjectType.getDescribe().fields.getMap().keySet();
        Set<String> costSharefieldNames = Cost_Share__c.sObjectType.getDescribe().fields.getMap().keySet();
        string costShareQueryString = 'select '+ string.join(new list<string>(costSharefieldNames), ',') + ' from Cost_Shares__r';
        string queryString = 'select ' + string.join(new list<string>(planfieldNames), ',') +',(' + costShareQueryString +')'+' from Plan__c where ID IN:';
        list<JSON2Apex.CostShares> csWrapList = new list<JSON2Apex.CostShares>();
        
        JSON2Apex jsonWrap = JSON2Apex.parse(searchJsonString); 
        string planName = '\'%' + jsonWrap.planName  + '%\'';
        for(JSON2Apex.CostShares csj:jsonWrap.costShares){
            csTypes.add(csj.costShareType);
            csWrapList.add(csj);            
        }
        
        for(Cost_Share__c cs:[select id,Name,costShareType__c,plan__c,min__c,max__c,selectedValue__c from Cost_Share__c 
                              where costShareType__c IN:csTypes])
        {                
                for(JSON2Apex.CostShares csw:csWrapList){
                    integer min = csw.min!=null?csw.min:0;
                    integer max = csw.max!=null?csw.max:0;
                    if((csw.costShareType).equals(cs.costShareType__c) && (Integer.valueOf(cs.selectedValue__c)>=min && Integer.valueOf(cs.selectedValue__c)<=max))
                        planIdSet.add(cs.plan__c);                    
                }                                                          
        }
        
        queryString +='planIdSet OR Name Like '+planName ; 
        return (list<object>) getFormatedPlans(Database.query(queryString));
    }
    
   
    /**
    * Method getFormatedPlans
    * @author Venkat Vishal Reddy Nakka
    * @date 27/11/2019
    * @param List of Plan records 
    * @description : This method returns list of Plans formated as required by react app
    *                
    */
    public static list<Plan> getFormatedPlans(list<Plan__c> planList){
        
        list<Plan> newplanList = new list<Plan>();        
        for(Plan__c pl:planList){    
            Plan p = new Plan();
            p.name = pl.Name;
            p.id=pl.Id;
            p.acaPlan=pl.acaPlan__c;
            p.applicableCoverageTiers=pl.applicableCoverageTiers__c!=null ? (pl.applicableCoverageTiers__c).split(';'):null;
            p.approvalProcessRequired=pl.approvalProcessRequired__c;
            p.chpReligiousIndicator=pl.chpReligiousIndicator__c;
            p.creditableCoverageType=pl.creditableCoverageType__c;
            p.isDeductibleAmountsCombinedOrSeparate=pl.isDeductibleAmountsCombinedOrSeparate__c!=null ? (pl.isDeductibleAmountsCombinedOrSeparate__c).split(';'):null;
            p.depAgeMax=integer.valueOf(pl.depAgeMax__c);
            p.depAgeWhen=pl.depAgeWhen__c;
            p.distributionChannels=pl.distributionChannels__c!=null ? (pl.distributionChannels__c).split(';'):null;
            p.endDate=string.valueOf(pl.endDate__c);
            p.startDate=string.valueOf(pl.startDate__c);
            p.employerContribution=pl.employerContribution__c;
            p.formularyName=pl.formularyName__c;
            p.fundingArrangements=pl.fundingArrangements__c!=null?(pl.fundingArrangements__c).split(';'):null;
            p.grandfatheredPlan=pl.grandfatheredPlan__c;
            p.isGrandmothered=pl.isGrandmothered__c;
            p.grpSizeMax=pl.grpSizeMax__c;
            p.grpSizeMin=pl.grpSizeMin__c;
            p.isHighDeductiblePlan=pl.isHighDeductiblePlan__c;
            p.hixMetalLevel=pl.hixMetalLevel__c!=null?(pl.hixMetalLevel__c).split(';'):null;
            p.hsaVendor=pl.hsaVendor__c;
            p.isIncludeCreditAmount=pl.isIncludeCreditAmount__c;
            p.isIncludeSecondaryMoop=pl.isIncludeSecondaryMoop__c;
            p.legalEntity=pl.udfplan_LegalEntity__c;
            p.marketingStatus=pl.marketingStatus__c;
            p.marketSegments=pl.marketSegments__c!=null?(pl.marketSegments__c).split(';'):null;
            p.memberFundings=pl.memberFundings__c!=null?(pl.memberFundings__c).split(';'):null;
            p.minEssentialCoverage=pl.minEssentialCoverage__c;
            p.minValueCoverage=pl.minValueCoverage__c;
            p.pcpRequired=pl.pcpRequired__c;
            p.planCoverageExceptions=pl.planCoverageExceptions__c;
            p.planDesign=pl.planDesign__c;
            p.planDueDate=string.valueOf(pl.planDueDate__c);
            p.productRegulatoryApproval=pl.productRegulatoryApproval__c!=null?(pl.productRegulatoryApproval__c).split(';'):null;
            p.productRegulatoryDate=string.valueOf(pl.productRegulatoryDate__c);
            p.planType=pl.planType__c;
            p.planYear=pl.planYear__c;
            p.Product=pl.Product__c;
            p.productClasses=pl.productClasses__c;
            p.productFamilies=pl.productFamilies__c;
            p.productTypes=pl.productTypes__c!=null?(pl.productTypes__c).split(';'):null;
            p.providerNetworks=pl.providerNetworks__c;
            p.providerNetworkLink=pl.providerNetworkLink__c;
            p.providerNetworkPhoneNumber=pl.providerNetworkPhoneNumber__c;
            p.providerTier=pl.providerTierDisplayNames__c!=null?(pl.providerTierDisplayNames__c).split(';'):null;
            p.religionPlanIndicator=pl.religionPlanIndicator__c;
            p.salesStatus=pl.salesStatus__c;
            p.sbcHeaderName=pl.sbcHeaderName__c;
            p.state=pl.state__c;
            p.planCostShares = getFormatedCostShares(pl.Cost_Shares__r);            
            newplanList.add(p);
        }        
        return newplanList; 
    }
    
    
    /**
    * Method getFormatedPlans
    * @author Venkat Vishal Reddy Nakka
    * @date 27/11/2019
    * @param List of Plan records 
    * @description : This method returns list of Plans formated as required by react app
    *                
    */
    public static list<CostShare> getFormatedCostShares(list<Cost_Share__c> csList){
        list<CostShare> newCostShareList = new list<CostShare>();        
        for(Cost_Share__c cs:csList){ 
            CostShare c = new CostShare();
            c.id=cs.Id;
            c.costShareLevel=cs.costShareLevel__c;
            c.costShareType=cs.costShareType__c;
            c.costShareTypeDesc=cs.costShareTypeDesc__c;
            c.defaultValue=integer.valueOf(cs.default__c);
            c.fromValue=integer.valueOf(cs.from__c);
            c.intervalName=cs.intervalName__c;
            c.isRangeValidationEnforced=cs.isRangeValidationEnforced__c;
            c.isZeroAllowed=cs.isZeroAllowed__c;
            c.max=integer.valueOf(cs.max__c);
            c.min=integer.valueOf(cs.min__c);
            c.plan=cs.plan__c;
            c.planService=cs.planService__c;
            c.productService=cs.productService__c;
            c.providerTier=cs.providerTier__c;
            c.scale=integer.valueOf(cs.scale__c);
            c.selectedValue=integer.valueOf(cs.selectedValue__c);
            c.severityLevel=cs.severityLevel__c;
            c.step=integer.valueOf(cs.step__c);
            c.to=integer.valueOf(cs.to__c);
            c.format=cs.format__c;
            newCostShareList.add(c);
        }
        return newCostShareList;
    }
    /**
    * Class Plan
    * @author Venkat Vishal Reddy Nakka
    * @date 27/11/2019
    * @description : This is a wrapper class for holding plan records
    *                
    */
    public class Plan{
        public string name;
        public string id;
		public string acaPlan;
		public list<string> applicableCoverageTiers;
		public string approvalProcessRequired;
		public string chpReligiousIndicator;
		public string creditableCoverageType;
		public list<string> isDeductibleAmountsCombinedOrSeparate;
		public integer depAgeMax;
		public string depAgeWhen;
		public list<string> distributionChannels;
		public string endDate;
		public string startDate;
		public string employerContribution;
		public string formularyName;
		public list<string> fundingArrangements;
		public string grandfatheredPlan;
		public string isGrandmothered;
		public string grpSizeMax;
		public string grpSizeMin;
		public string isHighDeductiblePlan;
		public list<string> hixMetalLevel;
		public string hsaVendor;
		public boolean isIncludeCreditAmount;
		public boolean isIncludeSecondaryMoop;
		public string legalEntity;
		public string marketingStatus;
		public list<string> marketSegments;
		public list<string> memberFundings;
		public string minEssentialCoverage;
		public string minValueCoverage;
		public string pcpRequired;
		public string planCoverageExceptions;
		public string planDesign;
		public string planDueDate;
		public list<string> productRegulatoryApproval;
		public string productRegulatoryDate;
		public string planType;
		public string planYear;
		public string Product;
		public string productClasses;
		public string productFamilies;
		public list<string> productTypes;
		public string providerNetworks;
		public string providerNetworkLink;
		public string providerNetworkPhoneNumber;
		public string providerTierDisplayNames;
		public list<string> providerTier;
		public string religionPlanIndicator;
		public string salesStatus;
		public string sbcHeaderName;
		public string state;
        public list<CostShare> planCostShares;        
    }
    
    /**
    * Class CostShares
    * @author Venkat Vishal Reddy Nakka
    * @date 27/11/2019
    * @description : This is a wrapper class for Cost Shares sent from user search
    *                
    */
    public class CostShare{
        public string id;
        public string costShareLevel;
        public string costShareType;
        public string costShareTypeDesc;
        public integer defaultValue;
        public integer fromValue;
        public string  intervalName;
        public boolean isRangeValidationEnforced;
        public boolean isZeroAllowed;
        public integer max;
        public integer min;
        public string plan;
        public string planService;
        public string productService;
        public string providerTier;
        public integer scale;
        public integer selectedValue;
        public string severityLevel;
        public integer step;
        public integer to;
        public string format;
    }
    /**
    * Class CostShareWrap
    * @author Venkat Vishal Reddy Nakka
    * @date 27/11/2019
    * @description : This is a wrapper class for Cost Shares sent from user search
    *                
    */
    public class CostShareWrap{
        public string name;
        public integer min;
        public integer max;
    }
    
    /**
    * Class CostShareWrap
    * @author Venkat Vishal Reddy Nakka
    * @date 27/11/2019
    * @description : This is a wrapper class for Cost Shares sent from user search
    *                
    */
    public class PlanWrap{
        public string id;
        public integer min;
        public integer max;
    }
}