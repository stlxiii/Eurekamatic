*** Settings ***
Resource  ${EXECDIR}/libs/selenium.robot


*** Variables ***

${DEFAULT_BROWSER}         Edge
${EUREKA_URL}              http://ezproxy.usherbrooke.ca/login?url=https://nouveau.eureka.cc/access/ip/default.aspx?un=unisher1
${EUREKA_URL_POST_LOGIN}   https://nouveau-eureka-cc.ezproxy.usherbrooke.ca/Search/Reading
${EUREKA_URL_ADV_SEARCH}   https://nouveau-eureka-cc.ezproxy.usherbrooke.ca/Search/AdvancedMobile

*** Keywords ***

Get All Links
    ${all_urls}   Create List
    ${doc_links}  SeleniumLibrary.Get WebElements  //a[@class="docList-links"]

    FOR  ${link}   IN   @{doc_links}
        ${link_href}    Get Element Attribute  ${link}  href
        Append To List  ${all_urls}  ${link_href}
    END

    RETURN  ${all_urls}


Load Website And Login
    [Arguments]  ${eureka_username}  ${eureka_password}
    
    selenium.Start Local Browser    ${EUREKA_URL}

    selenium.Enter Text   username  ${eureka_username}
    selenium.Enter Text   password  ${eureka_password}
    selenium.Click        submit
    
    SeleniumLibrary.Wait Until Location Is    ${EUREKA_URL_POST_LOGIN}
    SeleniumLibrary.Go To                     ${EUREKA_URL_ADV_SEARCH}


Save Results   
    ${all_urls}   Get All Links
    FOR  ${url}  IN  @{all_urls}
        Log to console  ${url}
    END


Wait Until Results Are Loaded
    SeleniumLibrary.Wait Until Element Is Visible    
    ...    //body[@class="module-search resultmobile"]
    ...    5 minutes

    SeleniumLibrary.Wait Until Page Contains Element
    ...    //a[@class="docList-links"]
    ...    30 seconds

