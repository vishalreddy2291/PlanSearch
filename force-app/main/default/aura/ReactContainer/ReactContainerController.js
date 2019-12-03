({
    handleMessage: function (component, event, helper) {
        var message = event.getParams();
        console.log('--message--'+JSON.stringify(message));
         var name = message.payload.name;
        console.log('--name--'+name);
       
        if(name === "navigateToPlan"){
            var navEvt = $A.get("e.force:navigateToSObject");
            navEvt.setParams({
                "recordId": message.payload.id,
                "slideDevName": "related"
            });
            navEvt.fire();
        }       
    },
    
    handleError: function (component, event, helper) {
        var error = event.getParams();
        console.log(error);
    },
    
    handlePlanIdSelect: function(component,event, helper) {
        var messageText = component.get('v.planDetailId');
        var message = {
            name: "Send To React",
            value: messageText
        };
        
        component.find('jsApp').message(message); // confusing
    }
})