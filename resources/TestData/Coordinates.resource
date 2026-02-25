*** Settings ***
Library    ../../resources/PythonLibrarys/RandomCoordinates.py
Variables  ../../resources/variables/TwoPoints.yaml

*** Keywords ***
Get Two Points Test Data
    IF    ${use_random}
        ${points}=    Generate Two Points
    ELSE
        ${points}=    Create Dictionary
        ...    start=${fixed_points['start']}
        ...    end=${fixed_points['end']}
    END

    &{case}=    Create Dictionary
    ...    start=${points['start']}
    ...    end=${points['end']}
    ...    tolerance=${tolerance}

    RETURN    ${case}