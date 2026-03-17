@echo off
setlocal EnableDelayedExpansion

set DOCKER_VOLUME=trm_state
set HOST_CWD=%CD%
set DOCKER_INIT=%HOST_CWD%\init

set USER_ARGS=

:parse_args
if "%~1"=="" goto args_done

if "%~1"=="--docker-volume" (
    set DOCKER_VOLUME=%~2
    shift
    shift
    goto parse_args
)

if "%~1"=="--docker-init" (
    set ARG=%~2
    echo %ARG% | findstr /R "^[A-Za-z]:\\" >nul
    if %errorlevel%==0 (
        set DOCKER_INIT=%ARG%
    ) else (
        set DOCKER_INIT=%HOST_CWD%\%ARG%
    )
    shift
    shift
    goto parse_args
)

set USER_ARGS=%USER_ARGS% %1
shift
goto parse_args

:args_done

set BASE_ARGS=run --rm -it --platform linux/amd64 ^
-v %DOCKER_VOLUME%:/var/lib/trm ^
-v %APPDATA%:/appdata ^
-v %HOST_CWD%:/work ^
-w /work ^
-e APPDATA=/appdata

docker volume inspect %DOCKER_VOLUME% >nul 2>&1
if %errorlevel%==0 (
    if not "%USER_ARGS%"=="" goto run_user

    set /p REPLY=[windows] Volume '%DOCKER_VOLUME%' already exists. Delete and recreate it? [y/N] 
    if /I "%REPLY%"=="y" (
        echo [windows] Deleting volume %DOCKER_VOLUME%
        docker volume rm %DOCKER_VOLUME% >nul

        echo [windows] Creating volume %DOCKER_VOLUME%
        docker volume create %DOCKER_VOLUME% >nul

        docker %BASE_ARGS% ^
        -v %DOCKER_INIT%:/installdata:ro ^
        -e INSTALLDATA=/installdata ^
        abaptrm/docker trm
        goto end
    ) else (
        docker %BASE_ARGS% abaptrm/docker trm
        goto end
    )
) else (
    echo [windows] Creating volume %DOCKER_VOLUME%
    docker volume create %DOCKER_VOLUME% >nul

    docker %BASE_ARGS% ^
    -v %DOCKER_INIT%:/installdata:ro ^
    -e INSTALLDATA=/installdata ^
    abaptrm/docker trm
    goto end
)

:run_user
docker %BASE_ARGS% abaptrm/docker trm %USER_ARGS%

:end