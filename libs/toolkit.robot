*** Settings ***

Library     String
Library     OperatingSystem
Library     DateTime
Library     Collections
Library     Process

*** Variables ***



*** Keywords ***

Arguments Should Be Boolean
    [Documentation]  Fails if any of the arguments are not boolean.
    [Arguments]  @{args}
    
    VAR  ${is_ok}

    FOR  ${arg}  IN  @{args}
        Log  Testing if boolean: ${arg}

        ${is_ok}  Evaluate
        ...       type($arg) is bool

        IF  $is_ok == ${False}
            Fail  Argument should be a boolean. Argument ${arg} is ${{ type($arg) }}.
        END
    END


Arguments Should Be Boolean Or None
    [Documentation]  Fails if any of the arguments are not boolean. None values are also accepted.
    [Arguments]  @{args}
    
    VAR  ${is_ok}

    FOR  ${arg}  IN  @{args}
        Log  Testing if boolean: ${arg}

        ${is_ok}  Evaluate
        ...       type($arg) is bool or $arg is None

        IF  $is_ok == ${False}
            Fail  Argument should be a boolean or None. Argument ${arg} is ${{ type($arg) }}.
        END
    END


Document Test
    [Arguments]  ${key}  ${value}
    
    TRY
        Set Test Documentation
        ...    [${key}:"${value}"]${Space}
        ...    append=True
    EXCEPT
        Log  "Set Test Documentation" has failed. This is normal inside setup.
    END


File Should Contain
    [Arguments]  ${File}   @{Strings}
    
    #Get file
    ${c}  Get File  ${File}  encoding=SYSTEM  encoding_errors=replace
    Log   File "${File}" content:\n${c}
    
    #Check content
    FOR  ${i}  IN  @{Strings}
        Should Contain  ${c}  ${i}  msg=File "${File}" should have contained "${i}" but did not.  values=False
    END
    
    RETURN  ${c}


Get Random Name
    ${First}  Get Random Firstname
    ${Last}   Get Random Lastname
    
    RETURN  ${Last} ${First}


Get Random Firstname
    ${Rnd}   Generate Random String    15    [LETTERS]
    RETURN  ${Rnd}
    

Get Random Lastname
    ${Rnd}   Generate Random String  15        [LETTERS]
    RETURN  ${Rnd}


Get Random Email
    [Arguments]  ${Domain}=@ihopethisdomaindoesnotexistbuticantbebotheredtocheck.com

    ${ts}  Get Timestamp
    ${x}   Get Random Alphanumeric String    5

    RETURN  ${ts}.${x}${Domain}


Get Random Phone Number
    [Arguments]   ${IncludeDashes}=${True}

    IF  $IncludeDashes
        ${Rnd}   Generate Random String  10        [NUMBERS]
        ${Rnd}   Evaluate  '${Rnd[:3]}-${Rnd[3:6]}-${Rnd[6:]}'
    ELSE
        ${Rnd}   Generate Random String  10        [NUMBERS]
    END

    RETURN  ${Rnd}


Get Random Alphanumeric String
    [Arguments]  ${Length}=15
    
    ${r}  Evaluate  ''.join(random.choices(string.ascii_lowercase + string.digits, k=${Length}))

    RETURN  ${r}


Get Random String
    [Arguments]  ${Length}=15
    
    ${r}  Evaluate  ''.join(random.choices(string.ascii_lowercase, k=${Length}))
    RETURN  ${r}


Get Timestamp
    ${ts}   Get Current Date  result_format=epoch  
    ${ts}   Evaluate          str(int($ts))
    RETURN  ${ts}


Get URL Without Protocol
    [Documentation]  Returns the URL without the protocol (http:// or https://)
    [Arguments]  ${URL}
    
    VAR  ${new_url}  ${URL}

    ${new_url}  Replace String  ${new_url}  http://   ${EMPTY}
    ${new_url}  Replace String  ${new_url}  https://  ${EMPTY}
    ${new_url}  Replace String  ${new_url}  HTTP://   ${EMPTY}
    ${new_url}  Replace String  ${new_url}  HTTPS://  ${EMPTY}
    
    RETURN  ${new_url}


String Should Contain Approximative Time
    [Arguments]   ${Base_DateTime}  ${Text}  ${Prefix}=${Empty}  ${Hour_Minute_Separatpr}=h  ${Max_Delta_Minutes}=5

    VAR  ${matches_datetime}  ${False}
    VAR  @{time_deltas}       @{EMPTY}
    
    FOR  ${i}   IN RANGE  ${Max_Delta_Minutes}
        Append To List  ${time_deltas}  ${{ int($i) }}
        Append To List  ${time_deltas}  ${{ -int($i) }}
    END    

    FOR  ${i}  IN  @{time_deltas}
        ${modified_time}       Evaluate                 $Base_DateTime + datetime.timedelta(minutes=${i})     datetime
        ${modified_hours}      Datetime.Convert Date    ${modified_time}    %H
        ${modified_minutes}    Datetime.Convert Date    ${modified_time}    %M
        
        Log  Testing if string "${Prefix}${modified_hours}${Hour_Minute_Separatpr}${modified_minutes}" is in "${Text}"
        IF  '${Prefix}${modified_hours}${Hour_Minute_Separatpr}${modified_minutes}'.lower() in $Text.lower()
            RETURN
        END
    END

    Fail  The text "${Text}" did not contain any of the approximative times: (${time_deltas}) minutes from ${Base_DateTime}.