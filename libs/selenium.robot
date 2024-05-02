*** Settings ***

Library     SeleniumLibrary    timeout=5
Library     RequestsLibrary
Resource    toolkit.robot

*** Variables ***

${REPORT_URL}               https://REDACTED/rflogs/
${USE_GRID_BROWSER_URL}     https://REDACTED:4444
${USE_GRID}
${GRID_DOWNLOAD_PDFS}       ${True}
${GRID_LAST_DL_LIST}        @{Empty}
${USE_BROWSER_LANGUAGE}     fr

# Just a declaration, leave empty
${DEFAULT_BROWSER}

*** Keywords ***


Close All
    SeleniumLibrary.Close All Browsers


Click
    [Arguments]  ${Locator}  ${Timeout}=${None}  ${x}=0  ${y}=0

    TRY
         SeleniumLibrary.Scroll Element Into View  ${Locator}
    EXCEPT
        No Operation
    END

    IF  $Timeout is None
        Wait Until Page Contains Element    ${Locator}
    ELSE
        Wait Until Page Contains Element    ${Locator}    ${Timeout}
    END

    SeleniumLibrary.Scroll Element Into View  ${Locator}

    IF  int($x) != 0 or int($y) != 0
        SeleniumLibrary.Click Element At Coordinates    ${Locator}    ${x}    ${y}
    ELSE
        SeleniumLibrary.Click Element                   ${Locator}
    END


Click JS
    [Documentation]  Attempts clicking using javascript.
    [Arguments]  ${Locator}  ${Timeout}=${None}
    
    IF  $Timeout is None
        Wait Until Page Contains Element   ${Locator}
    ELSE
        Wait Until Page Contains Element   ${Locator}  ${Timeout}
    END

    ${ts}  Toolkit.Get Timestamp
    SeleniumLibrary.Assign Id To Element   ${Locator}  id${ts}
    SeleniumLibrary.Execute Javascript     document.getElementById('id${ts}').click();


Click Try
    [Documentation]  Clicks locator but doesn't fail in case of error.
    [Arguments]  ${Locator}  ${Timeout}=${None}

    Run Keyword And Return Status
    ...    Click  ${Locator}  ${Timeout}


Click If Element Exists
    [Arguments]  ${Locator}  ${timeout}=5

    ${exists}
    ...    Run Keyword And Return Status
    ...        Wait Until Page Contains Element  ${Locator}  ${timeout}

    IF  $exists
        Comment  Element seems to exist but it may not be possible to interact with
        ...      therefore, we will ignore any error

        ${click_result}  ${click_details}
        ...    Run Keyword And Ignore Error
        ...      Click  ${Locator}

        Log  Click result: ${click_result}
        Log  Click detail: ${click_details}
    END


Click If Element is Visible
    [Documentation]  Click element if it is immediately visible, does not fail the test otherwise.
    [Arguments]  ${Locator}    ${ScrollDown}=0

    IF  int($ScrollDown) > 0
        Scroll Down    ${ScrollDown}
    END

    ${x}  Get Element Visibility  ${Locator}
    IF  ${x}==${True}  
        Click  ${Locator}
    END


Delete Element
    [Documentation]  Obliterates an element from the DOM. No error Handling, will not fail if element does not exist.
    [Arguments]  ${Locator}
    
    ${ts}  Toolkit.Get Timestamp
    Run Keyword And Ignore Error  SeleniumLibrary.Assign Id To Element   ${Locator}  id${ts}
    Run Keyword And Ignore Error  SeleniumLibrary.Execute Javascript     document.getElementById('id${ts}').remove('id${ts}');


Download All Grid Files
    [Arguments]  ${destination_path}=${OUTPUT DIR}${/}download${/}

    ${file_list}  Get Grid Downloads List

    FOR  ${i}  IN  @{file_list}
        Download Grid File  ${i}  destination_path=${destination_path}
    END


Hide Element
    [Documentation]  Hides an element from the DOM. No error Handling, will not fail if element does not exist.
    [Arguments]  ${Locator}
    
    ${ts}  Toolkit.Get Timestamp
    Run Keyword And Ignore Error  SeleniumLibrary.Assign Id To Element   ${Locator}  id${ts}
    Run Keyword And Ignore Error  SeleniumLibrary.Execute Javascript     document.getElementById('id${ts}').style.display = 'none';


Element Text Should Be X Long
    [Arguments]  ${Locator}  ${x}
    ${txt}  Get Text  ${Locator}
    ${len}  Evaluate  len(str($txt))

    IF  int($len) != int($x)
        Fail  The text "${txt}" found on element "${Locator}" was ${len} character(s) long instead of ${x}.
    END
    

Enter Text
    [Arguments]  ${Locator}  ${Text}  ${Validate}=${True}

    Log  Entering "${Text}" into locator "${Locator}"
    Wait Until Page Contains Element                         ${Locator}
    Run Keyword And Return Status  Scroll Element Into View  ${Locator}

    Comment   Enter text (1/4)
    ${Status}  ${Msg}  
    ...  Run Keyword And Ignore Error
    ...  Wait Until Keyword Succeeds  10  0
    ...  Run Keywords
    ...       Clear Element Text      ${Locator}
    ...  AND  Input Text              ${Locator}  ${Text}

    Comment  Check text (1/4)
    ${tmp}  SeleniumLibrary.Get Value   ${Locator}

    IF  str($tmp) == str($Text) or bool($Validate) == False
        Return From Keyword    ${Text}
    END


Enter Text If Element Exists
    [Arguments]  ${Locator}  ${Text}  ${Timeout}=5

    ${exists}
    ...    Run Keyword And Return Status
    ...        Wait Until Page Contains Element  ${Locator}  ${Timeout}

    IF  $exists
        Enter Text  ${Locator}  ${Text}
    END


Enter Text JS
    [Arguments]  ${Locator}  ${Value}  ${Timeout}=${None}
    
    IF  $Timeout is None
        Wait Until Page Contains Element   ${Locator}
    ELSE
        Wait Until Page Contains Element   ${Locator}  ${Timeout}
    END

    ${ts}  Toolkit.Get Timestamp
    SeleniumLibrary.Assign Id To Element   ${Locator}  id${ts}
    SeleniumLibrary.Execute Javascript     document.getElementById('id${ts}').click();

    ${v}  replace string  ${Value}  "    \\"
    ${v}  replace string  ${v}      \\   \\\\
    Execute Javascript  document.getElementById('id${ts}').value = "${v}";


Enter Text Slowly
    [Documentation]  Enters text one character at a time, with a delay between each.
    [Arguments]  ${Locator}  ${Text}  ${Delay}=0.1
    Log  Typing slowly: "${Text}"

    Wait Until Page Contains Element  ${Locator}
    Clear Element Text                ${Locator}

    ${List}  Convert To List   ${Text}
    
    FOR  ${i}  IN  @{List}
        Input Text  ${Locator}  ${i}  clear=${False}
        Sleep  ${Delay}
    END


Get Browser Options Object
    [Arguments]      ${browser}  ${download_pdfs}=${GRID_DOWNLOAD_PDFS}  ${language}=${USE_BROWSER_LANGUAGE}
    [Documentation]  Returns the browser options object for the specified browser.
    
    ${options}    Evaluate    sys.modules['selenium.webdriver'].${{ $browser.title() }}Options()    sys
    Call Method   ${options}   add_argument   --ignore-certificate-errors

    ${dir_options}  Evaluate   dir($options)
    Log             Options available for ${browser}: ${dir_options}    level=DEBUG

    IF  $download_pdfs == ${True}
        IF  $browser.lower() == 'chrome' or $browser.lower() == 'edge'
            # CHROME AND EDGE
            ${other_options}    Create Dictionary    
            ...    plugins.always_open_pdf_externally=${True}
            ...    download.prompt_for_download=${False}

            Call Method   ${options}   add_experimental_option   prefs                  ${other_options}
            Call Method   ${options}   set_capability            se:downloadsEnabled    ${True}
            Call Method   ${options}   add_argument              --lang\=${language}

        ELSE IF  $browser.lower() == 'firefox'
            # FIREFOX
            Call Method   ${options}   set_preference   pdfjs.disabled                  ${True}
            Call Method   ${options}   set_capability   se:downloadsEnabled             ${True}
            Call Method   ${options}   set_preference   intl.accept_languages           ${language}
        ELSE
            FAIL    Unexpected browser: ${browser}
        END
    END
    
    RETURN  ${options}


Get Element Visibility
    [Documentation]  Returns element visibility (true or false).  
    [Arguments]  ${Locator}
    
    ${x}  Run Keyword And Return Status
    ...   Element Should Be Visible  ${Locator}
    
    RETURN    ${x} 


Get Grid Downloads List
    [Documentation]  Returns a list of the grid downloaded files for the current browser session.
    ...              Also memorizes the list in a global variable for use by "Download Latest Grid File"

    ${session_id}   SeleniumLibrary.Get Session Id
    ${grid_ep}      Set Variable                     ${USE_GRID_BROWSER_URL}/session/${session_id}/se/files
    ${response}     RequestsLibrary.GET              ${grid_ep}
    ${json_dict}    Evaluate                         $response.json()    json
    ${file_list}    Create List
    
    Collections.Log Dictionary  ${json_dict}
    
    # Iterate through the json dictionary and extract the file names
    FOR  ${i}  IN  @{json_dict}[value][names]
        Append To List  ${file_list}  ${i}
    END

    Set Global Variable  ${GRID_LAST_DL_LIST}  ${file_list}

    RETURN  ${file_list}


Grid Download Should Be Available
    [Documentation]  Checks if a file is available for download from the grid session's downloads. 
    ...              The file name must be exact. The browser session must still be active.
    [Arguments]  ${file_name}

    ${file_list}               Get Grid Downloads List
    List Should Contain Value  ${file_list}  ${file_name}
    ...   msg=File "${file_name}" was not found in the grid downloads list: ${file_list}


Download Grid File
    [Documentation]  Downloads a file from the grid session's downloads. The file name must be exact.
    ...              By default, the file will be saved to the output (report) directory under the "download" folder.
    ...              Returns the full path to the downloaded file.\n\n
    ...              The keyword "Get Grid Downloads List" may be used to get a list of available files.
    ...              Note that the browser session must still be active. Once the browser is closed, all 
    ...              files are deleted from Grid.
    [Arguments]  ${file_name}  ${timeout}=60  ${destination_path}=${OUTPUT DIR}${/}download${/}
    
    # https://www.selenium.dev/documentation/grid/configuration/cli_options/#dowloading-a-file
    ${session_id}   SeleniumLibrary.Get Session Id
    ${grid_ep}      Set Variable            ${USE_GRID_BROWSER_URL}/session/${session_id}/se/files
    ${payload}      Create Dictionary  name=${file_name}
    ${resp}         RequestsLibrary.POST    ${grid_ep}        json=${payload}
    ${file_b64}     Evaluate                $resp.json()['value']['contents']                    json
    ${file_bytes}   Evaluate                base64.b64decode($file_b64)                          base64
    ${file_object}  Evaluate                io.BytesIO($file_bytes)                              io
    ${file_bin}     Evaluate                zipfile.ZipFile($file_object, "r").read($file_name)  zipfile
    ${dest_file}    Evaluate                os.path.join($destination_path, $file_name)          os

    Create Binary File  ${dest_file}   ${file_bin}

    RETURN  ${dest_file}


Download Latest Grid File
    [Documentation]  Downloads the latest file from the grid session's downloads. 
    ...              Before using, call the keyword "Get Grid Downloads List" so there is a "before" list to compare to.
    ...              If there is more than one new file, only the first one found will be downloaded.
    ...              Returns the full path to the downloaded file.

    [Arguments]  ${timeout}=60  ${destination_path}=${OUTPUT DIR}${/}download${/}
    
    ${files_before}  Set Variable  ${GRID_LAST_DL_LIST}
    ${files_now}     Get Grid Downloads List
    
    FOR  ${i}  IN  @{files_now}
        Log  Checking if file is new: ${i}

        IF  not $i in $files_before
            Log  File is new: ${i}
            ${downloaded_file}  Download Grid File  ${i}  ${timeout}  ${destination_path}
            Return From Keyword  ${downloaded_file}
        END
    END


Go To Address ${URL}
    SeleniumLibrary.Go To    ${URL}
    SeleniumLibrary.Capture Page Screenshot


Grid Should Have ${number_of_files} Downloads Available
    ${files}  Get Grid Downloads List
    ${count}  Get Length  ${files}

    IF  int($count) != int($number_of_files)
        Fail  Expected ${number_of_files} files to be available, but found ${count}: ${files}
    END


One Of These Elements Should Be Visible
    [Arguments]  @{Strings}
    
    FOR  ${i}  IN  @{Strings}
        ${x}   Run Keyword And Return Status    Element Should Be Visible    ${i}
        Return From Keyword If      bool($x)    ${i}
    END
    
    Fail    None of these elements appeared: ${Strings}


Page Should Contain Any
    [Arguments]  @{Strings}
    
    FOR  ${i}  IN  @{Strings}
        ${Found}
        ...  Run Keyword And Return Status
        ...  Page Should Contain          ${i}
        Return From Keyword If  ${Found}  ${i}
    END
    Fail  The page should have contained at least one of these strings, but did not: ${Strings}


Page Should Contain Any Element
    [Arguments]  @{Strings}
    
    FOR  ${i}  IN  @{Strings}
        ${Found}
        ...  Run Keyword And Return Status
        ...  Page Should Contain Element  ${i}
        Return From Keyword If  ${Found}  ${i}
    END
    Fail  The page should have contained at least one of these elements, but did not: ${Strings}


Set Grid To Download PDFs
    [Documentation]  Sets the grid to download PDFs instead of displaying them. The default is to display them.
    ...              MUST BE CALLED BEFORE THE BROWSER IS STARTED.
    Set Test Variable  ${GRID_DOWNLOAD_PDFS}  ${True}


Set Grid To View PDFs
    [Documentation]  Sets the grid to display PDFs instead of downloading them. The default is to display them.
    ...              MUST BE CALLED BEFORE THE BROWSER IS STARTED.
    Set Test Variable  ${GRID_DOWNLOAD_PDFS}  ${False}


Select Browser
    [Arguments]  ${Browser}=${None}
    [Documentation]  Returns ${DEFAULT_BROWSER} unless it is empty, in which case it returns a random browser.
    
    # Return the browser specified directly in argument if there is one
    IF  $Browser is not None and $Browser != ''
        Return From Keyword  ${Browser}
    END

    # Return the browser if there is a default set in the global variable 
    # or return a random browser if no default is set
    IF  $DEFAULT_BROWSER is None or $DEFAULT_BROWSER == ''
        # Return a random browser
        ${browsers}  Create List  Firefox  Chrome  Edge
        
        # Get a random number from 0 to 2
        ${i}  Evaluate  random.randint(0, 2)
        Return From Keyword  ${browsers}[${i}]
    ELSE
        # Return the default browser
        Return From Keyword  ${DEFAULT_BROWSER}
    END


Set Browser
    [Arguments]  ${Browser}=${None}
    [Documentation]  Sets the default browser to be used by the keyword "Start New Browser".
    
    Set Global Variable  ${DEFAULT_BROWSER}  ${Browser}


Scroll Down
    [Arguments]  ${y}
    Execute Javascript  window.scrollBy(0, ${y})


Scroll Under 
    [Arguments]  ${Locator}  ${HowMuch}=200
    Run Keyword And Return Status
    ...    Scroll Element Into View  ${Locator}
    Scroll Down  ${HowMuch}


Select From Custom List
    [Arguments]      ${list_locator}  ${search_value}  ${item_locator}  ${answer_locator}  ${max_iterations}=99
    [Documentation]  - list_locator:   XPATH where to click to expand the list  
    ...              - search_value:   String value  
    ...              - item_locator:   XPATH to where the expanded items are, when shown  
    ...              - answer_locator: XPATH to confirm the correct answer is selected  

    ${current_selection}    Set Variable             ${Empty}
    Click                                            ${list_locator}
    SeleniumLibrary.wait until Element Is Visible    ${item_locator}

    FOR  ${i}  IN RANGE  ${max_iterations}
        # Get current selection
        ${list_items}   SeleniumLibrary.Get WebElements  ${item_locator}
        FOR  ${ii}  IN  @{list_items}
            ${current_selection}    SeleniumLibrary.Get Text  ${ii}
            log                     ${current_selection}
        END

        Log  Iteration #${i} looking for "${search_value}" 

        IF  $current_selection == $search_value
            # Click on the item and validate operation is succesful
            Click                                   ${ii} 
            Wait Until Element Is Not Visible       ${ii}
            Wait Until page Contains Element        ${answer_locator}

            # Return from keyword if the selection matches the search value
            Return From Keyword                     ${current_selection}

        ELSE
            # Set focus to the next item in the list
            SeleniumLibrary.Press Keys    None    ARROW_DOWN
        END
    END

    # If hasn't exited at this point, the value is not in the list
    Fail  Value "${search_value}" was not found in list ${list_locator}


Start Local Browser
    [Documentation]  Starts a local browser
    [Arguments]     ${URL}    ${use_browser}=${DEFAULT_BROWSER}
    
    Log  Starting local browser (${use_browser}) at URL: ${URL}
    ${browser}   Select Browser               ${use_browser}
    ${options}   Get Browser Options Object   ${browser}

    Open Browser  browser=${browser}  url=about:blank  options=${options}
    Maximize Browser Window
    Go To  ${URL}


Start New Browser
    [Arguments]      ${url}=about:blank
    
    IF  $USE_GRID and int($USE_GRID) == 1
        Start Remote Browser    ${url}
    ELSE
        Start Local Browser     ${url}
    END


Start Remote Browser
    [Documentation]  Starts a Selenium Grid remote browser
    [Arguments]  ${url}  ${use_browser}=${DEFAULT_BROWSER}    ${language}=${USE_BROWSER_LANGUAGE}
    
    Log  Starting remote browser (${use_browser}) at URL: ${URL}

    # Set browser either randomly, or to the default, or to the one specified in arguments
    ${browser}   Select Browser               ${use_browser}
    ${options}   Get Browser Options Object   ${browser}  

    # This may need more than one try, because there's a limited number of instances available
    Wait Until Keyword Succeeds  10x  10s
    ...    Open Browser  
    ...        about:blank   
    ...        remote_url=${USE_GRID_BROWSER_URL}    
    ...        browser=${browser}    
    ...        options=${options}  	
    
    ${session_id}  SeleniumLibrary.Get Session Id
    log            session_id: ${session_id}

    Run Keyword And Ignore Error 
    ...    Maximize Browser Window

    Go To  ${URL}


Wait Until Grid Download Is Available
    [Arguments]  ${file_name}  ${timeout}=60
    
    Wait Until Keyword Succeeds  ${timeout}  1
    ...   Grid Download Should Be Available  ${file_name}


Wait Until Grid Has X Downloads Available
    [Arguments]   ${expected_files}  ${timeout}=60

    Wait Until Keyword Succeeds       ${timeout}  1
    ...   Grid Should Have ${expected_files} Downloads Available


Wait Until Any Element Is Visible
    [Arguments]  @{Strings}  ${Timeout}=10

    FOR  ${i}  IN RANGE  ${Timeout}
        ${passfail}  ${return}  Run Keyword And Ignore Error
        ...    One Of These Elements Should Be Visible   @{Strings}
        Return From Keyword If     $passfail == 'PASS'   ${return}
        sleep  1
    END

    Fail  None of these elements appeared after ${Timeout} seconds: ${Strings}


Wait Until Page Contains Any
    [Arguments]  @{Strings}  ${Timeout}=10
    
    ${r}  Wait Until Keyword Succeeds  ${Timeout}  0
    ...   Page Should Contain Any      @{Strings}

    RETURN  ${r}


Wait Until Page Contains Any Element
    [Documentation]  Returns the name of the element found.
    [Arguments]  @{Strings}  ${Timeout}=10
    
    ${r}  Wait Until Keyword Succeeds  ${Timeout}  0
    ...   Page Should Contain Any Element  @{Strings}

    RETURN  ${r}


Wait Until User Closes Browser
    [Documentation]  Waits until the user closes the browser. NOT FOR USE IN REAL TEST CASES!
    [Arguments]      ${Open_Browser_If_Anything_In_This_Argument}=${None}
    [Tags]           robot:flatten

    # open a blank page if the argument is not empty
    IF  $Open_Browser_If_Anything_In_This_Argument is not None
        Open Browser  about:blank
    END

    # wait until the browser is closed
    Log to Console    \n\n*** Waiting for the browser to be closed. ***\n\n
    WHILE  True
        TRY
            TRY
                ${previous kw}
                ...    SeleniumLibrary.Register Keyword To Run On Failure   ${None}

                ${loc}  Get Location
                Sleep   1
            FINALLY
                Register Keyword To Run On Failure	${previous kw}
            END
        EXCEPT
            Log To Console  \nThe browser was closed
            RETURN
        END
        
    END