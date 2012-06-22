rem Starts, stops, and restarts solr

pushd

set SOLR_ROOT=%CD%
set SOLR_DIR=%CD%\apache-solr-4.0-trunk\example
set JAVA_OPTIONS=-Xmx1024m -DSTOP.PORT=8079 -DSTOP.KEY=stopkey -jar start.jar
set JAVA_DEBUG_OPTIONS=-Xdebug -Xrunjdwp:transport=dt_socket,address=8998,server=y
set SOLR_OPTIONS=-Dsolr.solr.home=%CD%\dir_search_cores\
set LOG_FILE=%CD%\solr.log
set JAVA=java

goto %1

:run
        echo "Running Solr"
        cd %SOLR_DIR%
        %JAVA% %SOLR_OPTIONS% %JAVA_OPTIONS%
        popd
:start
        echo "Starting Solr"
        cd %SOLR_DIR%
        %JAVA% %SOLR_OPTIONS% %JAVA_OPTIONS% > %LOG_FILE% &
        popd
:debug
        echo "Debugging Solr"
        cd %SOLR_DIR%
        %JAVA% %SOLR_OPTIONS% %JAVA_DEBUG_OPTIONS% %JAVA_OPTIONS% > %LOG_FILE% &
        popd

:stop
        echo "Stopping Solr"
        cd %SOLR_DIR%
        %JAVA% %JAVA_OPTIONS% --stop
        popd
:restart
        %0 stop
        sleep 1
        %0 start
        popd
:-
        echo "Usage: $0 {run|start|stop|restart}" >&2
        exit 1
