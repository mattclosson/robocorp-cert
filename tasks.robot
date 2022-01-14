*** Settings ***
Documentation     Create and order a custom robot image and return a zip file of PDF receipts and images
Library           RPA.Browser.Selenium
Library           RPA.Tables
Library           RPA.HTTP
Library           RPA.PDF
Library           RPA.Archive
Library           RPA.Dialogs
Library           RPA.Robocorp.Vault
Library           Dialogs

*** Tasks ***
Order robots from RobotSpareBin Industries Inc
    Open RobotSpareBin
    Download CSV
    Fill the form with CSV data
    [Teardown]    Close The Browser

*** Keywords ***
Open RobotSpareBin
    ${url}=    Get Secret    url
    Open Available Browser    ${url}[url]

Download CSV
    ${url_input}=    Get Value From User    Add your CSV url:
    Download    ${url_input}    overwrite=True

Fill the form with CSV data
    ${robot_orders}=    Read table from CSV    orders.csv    header=True
    FOR    ${robot_order}    IN    @{robot_orders}
        Exit Modal
        Fill out the form for each order    ${robot_order}
        Wait Until Keyword Succeeds    10x    .1s    Click Preview
        Wait Until Keyword Succeeds    10x    .1s    Submit Order
        ${pdf}=    Get Receipt and Save as PDF    ${robot_order}[Order number]
        ${robot_image}=    Screenshot Robot Image    ${robot_order}[Order number]
        Add Robot Image to PDF    ${pdf}    ${robot_image}
        Next Order
    END
    Zip all receipts

Exit Modal
    Wait and Click Button    //*[@id="root"]/div/div[2]/div/div/div/div/div/button[1]

Fill out the form for each order
    [Arguments]    ${robot_order}
    Select From List By Index    id:head    ${robot_order}[Head]
    Select Radio Button    body    ${robot_order}[Body]
    Input Text    xpath:/html/body/div/div/div[1]/div/div[1]/form/div[3]/input    ${robot_order}[Legs]
    Input Text    address    ${robot_order}[Body]

Click Preview
    Click Button    Preview
    Wait Until Element Is Visible    id:robot-preview-image

Submit Order
    Click Button    Order
    Wait Until Element Is Visible    id:receipt

Get Receipt and Save as PDF
    [Arguments]    ${robot_order}
    ${order_receipt}=    Get Element Attribute    id:receipt    outerHTML
    Html To Pdf    ${order_receipt}    ${OUTPUT_DIR}${/}${robot_order}.pdf
    ${pdf}    Set Variable    ${OUTPUT_DIR}${/}${robot_order}.pdf
    [Return]    ${pdf}

Screenshot Robot Image
    [Arguments]    ${robot_order}
    Screenshot    id:robot-preview-image    ${CURDIR}${/}image_files${/}${robot_order}.png
    ${robot_image}=    Set Variable    ${CURDIR}${/}image_files${/}${robot_order}.png
    [Return]    ${robot_image}

Add Robot Image to PDF
    [Arguments]    ${pdf}    ${robot_image}
    Open Pdf    ${pdf}
    Add Watermark Image To Pdf    ${robot_image}    ${pdf}
    Close Pdf

Next Order
    Wait Until Page Contains Element    id:order-another
    Click Button    order-another

Zip all receipts
    Archive Folder With Zip    ${CURDIR}${/}output    ${OUTPUT_DIR}${/}recepts.zip

Close The Browser
    Close Browser
