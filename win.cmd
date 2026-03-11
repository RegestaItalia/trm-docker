@echo off
setlocal EnableDelayedExpansion

set "APPDATA_PATH=%APPDATA%"
set "DOCKER_VOLUME=trm_state"
set "DOCKER_INIT=%CD%\init"

:parse_args
if "%~1"=="" goto args_done

if "%~1"=="--docker-volume" (
    set "DOCKER_VOLUME=%~2"
    shift
    shift
    goto parse_args
)

if "%~1"=="--docker-init" (
    set "TMP=%~2"

    rem check if absolute path (drive letter like C:\)
    if "%TMP:~1,1%"==":" (
        set "DOCKER_INIT=%TMP%"
    ) else (
        set "DOCKER_INIT=%CD%\%TMP%"
    )

    shift
    shift
    goto parse_args
)

set "USER_ARGS=!USER_ARGS! %~1"
shift
goto parse_args

:args_done

set "BASE_ARGS=run --rm -it --platform linux/amd64 -v %DOCKER_VOLUME%:/var/lib/trm -v %APPDATA_PATH%:/appdata -e APPDATA=/appdata"

docker volume inspect %DOCKER_VOLUME% >nul 2>&1
set "VOLUME_EXISTS=%ERRORLEVEL%"

if not "%USER_ARGS%"=="" (
    docker %BASE_ARGS% abaptrm/docker trm %USER_ARGS%
    exit /b
)

if "%VOLUME_EXISTS%"=="0" (
    set /p REPLY=[win] Volume '%DOCKER_VOLUME%' already exists. Do you want to delete and recreate it? [y/N] 

    if /I "!REPLY!"=="Y" (
        echo [win] Deleting volume %DOCKER_VOLUME%
        docker volume rm %DOCKER_VOLUME% >nul

        echo [win] Creating volume %DOCKER_VOLUME%
        docker volume create %DOCKER_VOLUME% >nul

        docker %BASE_ARGS% -v "%DOCKER_INIT%:/installdata:ro" -e INSTALLDATA=/installdata abaptrm/docker trm
    ) else (
        docker %BASE_ARGS% abaptrm/docker trm
    )
) else (
    echo [win] Creating volume %DOCKER_VOLUME%
    docker volume create %DOCKER_VOLUME% >nul

    docker %BASE_ARGS% -v "%DOCKER_INIT%:/installdata:ro" -e INSTALLDATA=/installdata abaptrm/docker trm
)