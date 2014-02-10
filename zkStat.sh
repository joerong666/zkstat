#!/bin/bash

#date

#192.168.3.171:2181,192.168.3.172:2181,192.168.3.173:2181
zk_server=`echo $1 |sed 's/,/ /g'`

op_type=$2

################################################
# result to be return is like this:
################################################
#
#	{
#		stat_date:"2013-01-22",
#		stat_datetime:"2013-01-22 12:25:25",
#		err_msg:"",
#		[
#			{
#				server:192.168.3.171:2181,
#				status:ok,
#				role:leader,
#				connection:10,
#				watch:89,
#				watched_node:64,
#				total_node:547
#				sent_times:1111111,
#				recv_times:2222222,
#				conn_detail:"",
#				watch_detail:"",
#				stat_detail:""
#			},
#			{
#				server:192.168.3.172:2181,
#				status:ok,
#				role:leader,
#				connection:10,
#				watch:89,
#				watched_node:64,
#				total_node:547
#				sent_times:1111111,
#				recv_times:2222222,
#				conn_detail:"",
#				watch_detail:"",
#				stat_detail:""
#			}
#		]
#	}
#
################################################
result=""
cmd=nc
if [ -z "`whereis $cmd |fgrep '/'`" ]; then
	result="{
				\"err_msg\":\"no $cmd command\",
				\"server_list\":[]
			}"

	echo $result;
	exit 1
fi

realtime_monitor()
{
	zs=$1
	zk=`echo $zs |sed 's/:/ /'`				

	server_info=""
	stat_datetime=`date +"%Y-%m-%d %T"`
	stat_date=`date +"%Y-%m-%d"`

	ruok_content=`echo ruok |$cmd $zk`
	cons_content=`echo cons	|$cmd $zk |sed 's/$/<BR>/' |grep ',sid='`
	wchs_content=`echo wchs	|$cmd $zk |sed 's/$/<BR>/'`
	wchc_content=`echo wchc	|$cmd $zk |sed 's/$/<BR>/'`
	stat_content=`echo stat	|$cmd $zk |sed 's/$/<BR>/'`

	if [ -z $ruok_content ]; then
		server_info="{
				\"server\":\"$zs\",
				\"stat_date\":\"$stat_date\",
				\"stat_datetime\":\"$stat_datetime\",
				\"status\":\"ERROR\",
				\"role\":\"\",
				\"connection\":\"\",
				\"watch\":\"\",
				\"watched_node\":\"\",
				\"total_node\":\"\",
				\"sent_times\":\"\",
				\"recv_times\":\"\",
				\"conn_detail\":\"\",
				\"watch_detail\":\"\",
				\"stat_detail\":\"\"
			}"
		return 1;
	fi

	cons_count=`echo $cons_content  |sed 's/<BR>/\n/g' |sed '/^\s*$/d' |wc -l`
	cons_detail=`echo $cons_content |sed 's/<BR>/\n/g' |sed '/^\s*$/d' \
				|awk -F '[:(=,)]' '{ print $10": "$1", send to server: "$6", receive from server: "$8"<BR>" }'`
	#echo $cons_content | sed 's/<BR>\s*/\n/g' |sed '/^\s*$/d'
	#echo $cons_count
	#echo $cons_detail  |sed 's/<BR>\s*/\n/g'  |sed '/^\s*$/d'	

	wchs_node_count=`echo $wchs_content |sed 's/<BR>/\n/g' |grep 'connections' |awk -F '[ :]' '{print $4}'`
	wchs_count=`echo $wchs_content  |sed 's/<BR>/\n/g' |grep 'Total watches' |awk -F '[ :]' '{print $NF}'`
	#echo $wchs_content |sed 's/<BR>/\n/g' | sed '/^\s*$/d'
	#echo $wchs_node_count
	#echo $wchs_count
	
	#echo $wchc_content |sed 's/<BR>\s*/\n/g;' |sed 's#^/#\t/#' |sed '/^\s*$/d'

	stat_mode=`echo $stat_content  |sed 's/<BR>/\n/g' |grep 'Mode:' |awk '{print $NF}'`
	stat_nodes=`echo $stat_content |sed 's/<BR>/\n/g' |grep 'Node count:' |awk '{print $NF}'`
	stat_recv=`echo $stat_content  |sed 's/<BR>/\n/g' |grep 'Received:' |awk '{print $NF}'`
	stat_sent=`echo $stat_content  |sed 's/<BR>/\n/g' |grep 'Sent:' |awk '{print $NF}'`
	#echo $stat_content  |sed 's/<BR>/\n/g'
	#echo $stat_mode
	#echo $stat_nodes
	#echo $stat_recv
	#echo $stat_sent

	server_info="{
		\"server\":\"$zs\",
		\"stat_date\":\"$stat_date\",
		\"stat_datetime\":\"$stat_datetime\",
		\"status\":\"OK\",
		\"role\":\"$stat_mode\",
		\"connection\":\"$cons_count\",
		\"watch\":\"$wchs_count\",
		\"watched_node\":\"$wchs_node_count\",
		\"total_node\":\"$stat_nodes\",
		\"sent_times\":\"$stat_sent\",
		\"recv_times\":\"$stat_recv\",
		\"conn_detail\":\"$cons_detail\",
		\"watch_detail\":\"$wchc_content\",
		\"stat_detail\":\"$stat_content\"
	}"
	return 0
}

stat_info=""
for z in $zk_server
do
	server_info=""
	realtime_monitor $z
	stat_info="$stat_info,$server_info"
done

stat_info=`echo $stat_info |sed 's/^,//'`
result="{
			\"err_msg\":\"\",
            \"server_list\":[$stat_info]
		}"
echo $result
#date
