window.GALIntelligence={init:async()=>true,emit:async()=>({ok:true})};
const ACCEPTANCE_STATE={audience:'men',speed:'100-110',miss:'right',flight:'medium',goal:'fairways',budget:'middle',market:'US'};
const ACCEPTANCE_PRODUCTS=[{id:'GAL-DRV-0003',brand:'TaylorMade',model:'Qi4D Max',year:2026,brandId:null},{id:'GAL-DRV-0002',brand:'TaylorMade',model:'Qi4D LS',year:2026,brandId:null}];
const ACCEPTANCE_RESULTS=[{id:'GAL-DRV-0003',brand:'TaylorMade',model:'Qi4D Max',year:2026,fit:98.0,value:91.9,reasons:['Head intent fits your stated swing-speed range.','Directional bias is a strong match for your common miss.','Published launch/spin intent fits the flight you described.','Design priority aligns with what you want most from the tee.']},{id:'GAL-DRV-0002',brand:'TaylorMade',model:'Qi4D LS',year:2026,fit:84.0,value:81.0,reasons:['Secondary acceptance Driver.']}];
window.GAL_DRIVER_GUIDE_API={state:ACCEPTANCE_STATE,data:ACCEPTANCE_PRODUCTS,getResults:()=>ACCEPTANCE_RESULTS};
