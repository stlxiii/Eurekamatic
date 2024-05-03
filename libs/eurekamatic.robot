*** Settings ***
Resource  ${EXECDIR}/libs/selenium.robot


*** Variables ***

${DEFAULT_BROWSER}         Edge
${EUREKA_URL}              http://ezproxy.usherbrooke.ca/login?url=https://nouveau.eureka.cc/access/ip/default.aspx?un=unisher1
${EUREKA_URL_POST_LOGIN}   https://nouveau-eureka-cc.ezproxy.usherbrooke.ca/Search/Reading
${EUREKA_URL_ADV_SEARCH}   https://nouveau-eureka-cc.ezproxy.usherbrooke.ca/Search/AdvancedMobile


*** Keywords ***

Get All Links
    [Arguments]          ${previous_list}

    
            Sleep  3 seconds  # TODO: just wait until the spinner is not visible. Need to figure out its xpath.

    ${all_urls}          Create List
    ${all_web_elements}  SeleniumLibrary.Get WebElements  //a[@class="docList-links"]

    # Get all links but only if there's more of them than specified
    IF  len($all_web_elements) > len($previous_list)
        FOR  ${link}   IN   @{all_web_elements}
            ${link_href}    Get Element Attribute  ${link}  href
            Append To List  ${all_urls}            ${link_href}      
            SeleniumLibrary.Press Keys   NONE    END
        END
    ELSE
        # If there's no new links, return the previous list
        RETURN  ${previous_list}
    END

    # Remove duplicates
    ${all_urls}     Evaluate  list(dict.fromkeys($all_urls)) 
    Log To Console  Found ${{ len($all_urls) }} links
    RETURN          ${all_urls}


Get All Links Until No More
    ${when_started}  DateTime.Get Current Date
    ${when_stop}     Datetime.Add Time To Date    ${when_started}    15 minutes
    ${all_urls}      Create List
    Log To Console   ${\n}Getting all links

    WHILE  True
        TRY
            ${all_urls_loop}  Get All Links   ${all_urls}
            ${how_many_new}   Evaluate        len($all_urls_loop) - len($all_urls)
            ${all_urls}       Set Variable    ${all_urls_loop}
            Log               We have ${how_many_new} new links

            IF  $how_many_new == 0
                Sleep              5 seconds
                ${last_time_urls}  Get All Links  ${all_urls_loop}
                RETURN             ${last_time_urls}
            END
            
            ${when_now}  DateTime.Get Current Date
            IF  $when_now > $when_stop
                RETURN  ${all_urls}
            END

        EXCEPT  EXCEPTION  AS  ${e}
            Log             Exception: ${e}
            Log To Console  Exception: ${e}
        END
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
    ${all_urls}  Get All Links Until No More
    Log List     ${all_urls}


Wait Until Results Are Loaded
    SeleniumLibrary.Wait Until Element Is Visible    
    ...    //body[@class="module-search resultmobile"]
    ...    5 minutes

    SeleniumLibrary.Wait Until Page Contains Element
    ...    //a[@class="docList-links"]
    ...    30 seconds

