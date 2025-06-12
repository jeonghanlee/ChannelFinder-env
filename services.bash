#!/usr/bin/env bash
#
#  author  : Jeong Han Lee
#  email   : jeonghan.lee@gmail.com
#  version : 0.0.1


declare -g SC_RPATH;
#declare -g SC_NAME;
declare -g SC_TOP;
declare -g SC_TIME;

SC_RPATH="$(realpath "$0")";
#SC_NAME=${0##*/};
SC_TOP="${SC_RPATH%/*}"
SC_TIME="$(date +%y%m%d%H%M)"

SITE_CONFIG_PATH=${SC_TOP}/site-template

# Enable core dumps in case the JVM fails
ulimit -c unlimited

function pushdd { builtin pushd "$@" > /dev/null || exit; }
function popdd  { builtin popd  > /dev/null || exit; }


# shellcheck disable=SC2120
function end_elasticsearch
{
    local pas_top="$1";shift;
    if [ -z "$pas_top" ]; then
        pas_top="${SC_TOP}"
    fi

    pushdd "${pas_top}/elasticsearch"
    echo "<< Elasticsearch Stop"
    if [[ -f elasticsearch_pid ]]; then
        echo "We found its pid file"
        if command -v jsvc &> /dev/null; then
            echo "With jsvc, we stop the elasticsearch service"
            jsvc -stop -pidfile elasticsearch_pid org.elasticsearch.bootstrap.Elasticsearch
        else
            echo "The system doesn't have jsvc, so kill it"
            kill -9 `cat elasticsearch_pid`
        fi
    else
        es_pid=`ps -ef | grep "elasticsearch" | grep "java" |grep "pas-demo" | grep -v "grep" | awk '{print $2}'`
#echo "PID $es_pid found"
        if [ -n "$es_pid" ]; then
            echo "We found its pid $es_pid, stop it"
            kill -9 $es_pid
        else
            echo "No elasticsearch service to stop"
        fi
    fi
    sleep 1
    popdd
}

# shellcheck disable=SC2120
function start_elasticsearch
{
    local pas_top="$1";shift;
    if [ -z "$pas_top" ]; then
        pas_top="${SC_TOP}"
    fi

    local es_path_conf="${SITE_CONFIG_PATH}/es_path_conf"
    pushdd "${pas_top}/elasticsearch"
    echo ">> Elasticsearch Start as a daemon"
 #   mkdir -p plugins
    ES_JAVA_OPTS="-Xmx1G -Xms1G" ES_PATH_CONF="${es_path_conf}" bin/elasticsearch -d -p elasticsearch_pid  > /dev/null 2> /dev/null
    sleep 1
    popdd
}


function usage
{
    {
        echo "";
        echo "Usage    : $0  args"
        echo "";
        echo "              possbile args";
        echo "";
        echo "               startup   : startup all services in order";
        echo "               shutdown  : shutdown all services in order ";
        echo "               restartup : shutdown and startup";
        echo "               h         : this screen";
        echo "";
        echo " bash $0 startup "
        echo ""
        echo " The services : Elasticsearch"
        echo ""
    } 1>&2;
    exit 1;
}




case "$1" in

    startup|start)
	    start_elasticsearch
	    ;;
    shutdown|stop)
	    end_elasticsearch
	    ;;
    restart)
	    end_elasticsearch
	    start_elasticsearch
	    ;;
    start_es)
	    start_elasticsearch
        ;;
    stop_es)
	    end_elasticsearch
	    ;;
    h);;
    help)
        usage;
        ;;
    *)
	    usage;
    ;;
esac
