*** Settings ***
Resource  ${EXECDIR}/libs/selenium.robot


*** Variables ***

${DEFAULT_BROWSER}         Edge
${EUREKA_URL}              http://ezproxy.usherbrooke.ca/login?url=https://nouveau.eureka.cc/access/ip/default.aspx?un=unisher1
${EUREKA_URL_POST_LOGIN}   https://nouveau-eureka-cc.ezproxy.usherbrooke.ca/Search/Reading
${EUREKA_URL_ADV_SEARCH}   https://nouveau-eureka-cc.ezproxy.usherbrooke.ca/Search/AdvancedMobile
${EUREKA_DOC_XPATH}        //div[@class="docContainer"]

*** Keywords ***

Download Article
    [Arguments]  ${link_dict}
    
    seleniumLibrary.Go To           ${link_dict}[url]
    Wait Until Element Is Visible   ${EUREKA_DOC_XPATH}
    ${article_text}                 Get Article Text
    ${article_html}                 seleniumLibrary.Get Source

    ${article_dict}  Create Dictionary  
    ...     url=${link_dict}[url]
    ...     source=${link_dict}[source]
    ...     title=${link_dict}[title]
    ...     date=${link_dict}[date]
    ...     text=${article_text}
    ...     html=${article_html}
    
    RETURN  ${article_dict}


Download All Articles
    [Arguments]  ${all_urls}

    ${articles_list}   Create List
    ${counter}         Evaluate     0

    FOR  ${url}  IN  @{all_urls}
        ${counter}       Evaluate  $counter + 1
        ${article_dict}  Download Article  ${url}
        Append To List   ${articles_list}  ${article_dict} 
    END

    ${output_dict}  Create Dictionary
    ...  articles=${articles_list}

    OperatingSystem.Remove File        ${OUTPUT_DIR}${/}articles.json
    OperatingSystem.Append To File     ${OUTPUT_DIR}${/}articles.json  ${{ json.dumps($output_dict) }}


Get Article Text
    VAR  ${article_text}
    ${article_text}  Get Elem Text  ${article_text}  //article

    RETURN  ${article_text}


Get All Links
    [Arguments]  ${previous_list}

    SeleniumLibrary.Press Keys   NONE    END
    Sleep  3 seconds  # TODO: just wait until the spinner is not visible. Need to figure out its xpath.

    ${all_urls}          Create List
    ${all_web_elements}  SeleniumLibrary.Get WebElements    //div[@class="docListItem msDocItem"][@id]

    # Get all links but only if there's more of them than specified
    IF  len($all_web_elements) > len($previous_list)
        FOR  ${link}   IN   @{all_web_elements}
            ${link_id}      Get Element Attribute    ${link}  id
            ${link_xpath}   Set Variable             //div[@class="docListItem msDocItem"][@id="${link_id}"]

            ${link_href}    Get Elem Attribute    ${Empty}  ${link_xpath}//a[@class="docList-links"]  href
            ${link_title}   Get Elem Text         ${Empty}  ${link_xpath}//a[@class="docList-links"]
            ${link_source}  Get Elem Text         ${Empty}  ${link_xpath}//span[@class="source-name"]
            ${link_date}    Get Elem Text         ${Empty}  ${link_xpath}//span[@class="details"]

            ${link_dict}    Create Dictionary
            ...  title=${link_title}
            ...  source=${link_source}
            ...  date=${link_date}
            ...  url=${link_href}
            
            IF  $link_href and $link_href != ''
                Append To List  ${all_urls}  ${link_dict}
            ELSE
                Log To Console  No href found for link id ${link_id}, skipping.
            END
            SeleniumLibrary.Press Keys   NONE     END
        END
    ELSE
        # If there's no new links, return the previous list
        RETURN  ${previous_list}
    END

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
    
    Log List  ${all_urls}
    RETURN    ${all_urls}


Get Elem Attribute
    [Arguments]  ${previous_result}  ${elem}  ${attr}
    
    IF  $previous_result != ''
        RETURN  ${previous_result}
    END

    TRY
        ${elem_text}  seleniumLibrary.Get Element Attribute  ${elem}  ${attr}
    EXCEPT
        ${elem_text}  Set Variable   ${EMPTY}
    END

    RETURN  ${elem_text}


Get Elem Text
    [Arguments]  ${previous_result}  ${elem}
    
    IF  $previous_result != ''
        RETURN  ${previous_result}
    END

    TRY
        ${elem_text}  seleniumLibrary.Get Text  ${elem}
    EXCEPT
        ${elem_text}  Set Variable   ${EMPTY}
    END

    RETURN  ${elem_text}


Load Website And Login
    [Arguments]  ${eureka_username}  ${eureka_password}
    
    SeleniumLibrary.Register Keyword To Run On Failure   No Operation
    selenium.Start Local Browser    ${EUREKA_URL}

    IF  $eureka_username and $eureka_password and $eureka_username != '' and $eureka_password != ''
        selenium.Enter Text   username  ${eureka_username}
        selenium.Enter Text   password  ${eureka_password}
        selenium.Click        submit
    END
    
    SeleniumLibrary.Wait Until Location Is    ${EUREKA_URL_POST_LOGIN}  5 minutes
    SeleniumLibrary.Go To                     ${EUREKA_URL_ADV_SEARCH}


Save Results
    ${all_urls}  Get All Links Until No More
    Download All Articles   ${all_urls}


Wait Until Results Are Loaded
    SeleniumLibrary.Wait Until Element Is Visible    
    ...    //body[@class="module-search resultmobile"]
    ...    5 minutes

    SeleniumLibrary.Wait Until Page Contains Element
    ...    //a[@class="docList-links"]
    ...    30 seconds

