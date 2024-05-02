*** Settings ***
Resource  ${EXECDIR}/libs/eurekamatic.robot

Test Teardown    Close All Browsers

*** Variables ***
${USERNAME}
${PASSWORD}

*** Keywords ***

*** TEST Cases ***

DEBUG
    Load Website And Login    
    ...    ${USERNAME}    ${PASSWORD}
    Wait Until Results Are Loaded
    Save Results
