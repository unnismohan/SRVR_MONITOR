#!/bin/bash
logger_info=$(basename $0)
####################################################################
#loading configs
####################################################################
if [ -s SRVR_MONITOR.properties ];then
        . SRVR_MONITOR.properties
else
        exit 1
fi
#####################################################################
#cheking for cmd_path
#####################################################################
if [ ! -d $cmd_path ];then
	mkdir -p $cmd_path
fi
######################################################################
logger()
{
	if [ "$loglevel" == "INFO" ];then
		if [ "$2" == "INFO" ];then
		       	echo "[$logger_info|$(date '+%F|%R|%3N')]|$1 " >> $logname
		fi
	else
		echo "[$logger_info|$(date '+%F|%R|%3N')]|$1 " >> $logname
	fi
}
#####################################################################
#Email Sender
#####################################################################
send_email()
{
	if [ ! -z "$email_to" ];then
                if [ -z "$email_subject" ];then
                        email_subject="SRVR MONITOR EMAIL Notification:$hostname|$servicename"
                fi
		if [ $old_status -eq 0 ] && [ $curr_status -eq 1 ];then 
			notifytype="WARNING"
		elif [ $old_status -eq 1 ] && [ $curr_status -eq 2 ];then
			notifytype="CRITICAL"
		elif [ $old_status -eq 2 ] && [ $curr_status -eq 0 ];then
			notifytype="RCOVERY"
		elif [ $old_status -eq 2 ] && [ $curr_status -eq 1 ];then
			notifytype="WARNING"
		elif [ $old_status -eq 0 ] && [ $curr_status -eq 2 ];then
			notifytype="CRITICAL"
		elif [ $old_status -eq 1 ] && [ $curr_status -eq 0 ];then
                        notifytype="RCOVERY"
		fi	
		bgcolor='brown'
		statu='Critical'
	        if [ $curr_status -eq 0 ];then
	        	bgcolor='green'
			statu='Normal'
	        elif [ $curr_status -eq 1 ];then
	                bgcolor='yellow'
			statu='Warning'
	        fi
		tim=$(date)
		body=$(echo '<html><body><p><font font="" color="DarkBlue" face="Arial Narrow, Times New Roman, Bookman Old Style, Book Antiqua, Garamond, Arial">Hi All,<br><br>Please Find the below SRVR MONITOR  notification.<br><br>Notification type :- '$notifytype'<br>Time :- '$tim'<br></font></p><table  border="1" cellpadding="0" cellspacing="0" width="50%"><tbody><tr bgcolor="'$bgcolor'"><td colspan="4" align="center" valign="center" width="100%"><p><font color="white" face="Times New Roman, Arial Narrow, Bookman Old Style, Book Antiqua, Garamond, Arial" size="3"><b>SERVICE NOTIFICATION</b></font></p></td></tr><tr nowrap="" align="center" bgcolor="gray" valign="center"><td><p><font color="Black" face="Times New Roman, Arial Narrow, Bookman Old Style, Book Antiqua, Garamond, Arial" size="2"><b>HOSTNAME</b></font></p></td><td><p><font color="Black" face="Times New Roman, Arial Narrow, Bookman Old Style, Book Antiqua, Garamond, Arial" size="2"><b>SERVICE</b></font></p></td><td><p><font color="Black" face="Times New Roman, Arial Narrow, Bookman Old Style, Book Antiqua, Garamond, Arial" size="2"><b>STATUS</b></font></p></td><td><p><font color="Black" face="Times New Roman, Arial Narrow, Bookman Old Style, Book Antiqua, Garamond, Arial" size="2"><b>ADDITIONAL INFO</b></font></p></td></tr><tr nowrap="" align="center" valign="center"><td><p><font color="DarkBlue" face="Times New Roman, Arial Narrow, Bookman Old Style, Book Antiqua, Garamond, Arial" size="2">'$hostname'</font></p></td><td><p><font color="DarkBlue" face="Times New Roman, Arial Narrow, Bookman Old Style, Book Antiqua, Garamond, Arial" size="2">'$servicename'</font></p></td><td><p><font color="DarkBlue" face="Times New Roman, Arial Narrow, Bookman Old Style, Book Antiqua, Garamond, Arial" size="2">'$statu'</font></p></td><td><p><font color="DarkBlue" face="Times New Roman, Arial Narrow, Bookman Old Style, Book Antiqua, Garamond, Arial" size="2">'$output'</font></p></td></tr></tbody></table><font font="" color="DarkBlue" face="Arial Narrow, Times New Roman, Bookman Old Style, Book Antiqua, Garamond, Arial"><p><font color="darkblue" face="Times New Roman, Arial Narrow, Bookman Old Style, Book Antiqua, Garamond, Arial" size="2.5"><br><b><font font="" color="Navy" face="Times New Roman, Bookman Old Style, Book Antiqua, Garamond, Arial"><br>Thanks &amp; Regards,<br>6d Technologies.</b><br><br><b><i>Note: </i></b>This is a System generated mail alert.</font></body></html>')
     	        if [ -z "$email_cc" ];then
			logger "Sending Email Notification for :- $hostname|$servicename" "INFO"
	        	echo "$body"|/usr/local/bin/mutt -e 'set content_type="text/html"' $email_to -s "$email_subject"
                else
			logger "Sending Email Notification for :- $hostname|$servicename" "INFO"
                        echo "$body"|/usr/local/bin/mutt -e 'set content_type="text/html"' $email_to  -c $email_cc  -s "$email_subject"
                fi
	else
		logger "email_to paremeter cannot be null for sending Email notification" "INFO"
	fi
}
######################################################################
#function setting background colour
######################################################################
bgcheck()
{
        if [ $host_i_state -eq 2 ];then
                bgcolor=red
                output='Critical !!'
        elif [ $host_i_state -eq 1 ];then
                bgcolor=yellow
                output='Warning !!'
        elif [ $host_i_state -eq 0 ];then
                bgcolor=green
                output=OK
        fi
}
################################################################################
#function validates whether check results are within service_validity_interval
################################################################################
check_time_diff()
{
	curr_time=$(date +%s)
	service_updated_time=$(cat $cmd_path/$host_i.$curr_service.cmd|awk -F'|' '{print $3}')
	if [ -z $service_updated_time ];then
		service_updated_time=$curr_time
		echo "$host_i_state|$description|$service_updated_time" >$cmd_path/$host_i.$curr_service.cmd
	fi
	service_time_diff=$(expr $curr_time - $service_updated_time)
	if [ $service_time_diff -gt $service_validity_interval ];then
		host_i_state=1
                bgcheck
                description='Last Status Update is before Service Validity Interval'			
	else
		bgcheck
	fi
}
##############################################################
#creates service host map for the first time
##############################################################
first_run()
{
	if [ ! -f $cmd_path/$host_i.$curr_service.cmd ];then
		logger "Configuring service $curr_service in the map for host :- $host_i" "INFO"
		touch $cmd_path/$host_i.$curr_service.cmd
	fi
}
###########################################################
#check the service result and describtion
###########################################################
service_check()
{
	if [ ! -f $cmd_path/$host_i.$curr_service.cmd ];then
                logger "Creating Service for the first Time !!!" "INFO"
                touch $cmd_path/$host_i.$curr_service.cmd
        fi	
	if [ -s $cmd_path/$host_i.$curr_service.cmd ];then
		host_i_state=$(cat $cmd_path/$host_i.$curr_service.cmd|awk -F'|' '{print $1}')
		description=$(cat $cmd_path/$host_i.$curr_service.cmd|awk -F'|' '{print $2}')
		check_time_diff		
	else
		host_i_state=1
		bgcheck
		description='No Notification received for this service yet'
			
	fi
}
###########################################################
#generates the table for the GUI
###########################################################
create_table()
{
	if [ "$1" == "start" ];then
		service_check
		echo '<li class="tileborder"><div class="tile_box"><div class="tile_box_content"><h3 class="headclr">HOST STATUS :- '$host_i' </h3><table class="tableclass"><thead class="theadclass"><tr class="theadtrclass"><th class="srvccls">SERVICE</th><th class="warncls">STATUS</th><th class="desccls">DESCRIPTION</th></tr></thead><tbody><tr><td>'$curr_service'</td><td bgcolor="'$bgcolor'">'$output'</td><td>'$description'</td></tr>'
	elif [ "$1" == "continue" ];then
		service_check
		echo '<tr><td>'$curr_service'</td><td bgcolor="'$bgcolor'">'$output'</td><td>'$description'</td></tr>'
	elif [ "$1" == "completed" ];then
		echo '</tbody></table></div></div></li>'
	fi
}
############################################################
#Main fuction for creating Interface (GUI)
###########################################################
web()
{
	if [ -s SRVR_MONITOR.properties ];then
		echo "Content-type: text/html"
		echo ""
#		echo '<html><head><meta charset="utf-8" /><meta http-equiv="refresh" content="10"><link href="style.css" rel="stylesheet" type="text/css" />'
		echo '<html><head><meta charset="utf-8" /><meta http-equiv="refresh" content="60">'
		echo "<style media="screen" type="text/css">"
		cat style.css
		cat main.css
		cat fonts.css
		echo "</style>"
		echo '<script type="text/javascript">'
		cat jquery.min.js
		echo '</script><title>SERVER MONITOR</title></head><body><header><div class="header"><ul><li><p class="MainHead">SERVER MONITOR</p></li></ul></div></header><div class="body_content"><div class="wrapper"><div id="main" role="main"><ul id="tiles">'
		. SRVR_MONITOR.properties
		for ((i=1;i<=$total_hosts;i++))
		do
			host_temp="host$i"
			service_temp="host"$i"_service_defenition[@]"
			host_i=${!host_temp}
			service_i=(${!service_temp})
			host_i_service_count=${#service_i[@]}
			for  ((j=0;j<$host_i_service_count;j++))
			do
				curr_service=${service_i[$j]}
				first_run
				if [ $j -eq 0 ];then
					create_table "start"	
				else
					create_table "continue"
				fi
			done
			create_table "completed"
		done
		echo "</ul></div></div></div>"
		echo '<script type="text/javascript">'
		cat jquery.imagesloaded.js 
		echo '</script><script type="text/javascript">'
		cat jquery.wookmark.js
		echo "</script>
<script type=\"text/javascript\">
            (function ($) {
                var \$tiles = \$('#tiles'),
                     \$handler = \$('li', \$tiles),
                     \$main = \$('#main'),
                     \$window = \$(window),
                     \$document = \$(document),
                     options = {
                         autoResize: true,
                         container: \$main,
                         offset: 20,
                         itemWidth: 1000
                     };
                function applyLayout() {
                    \$tiles.imagesLoaded(function () {
                        
                        if (\$handler.wookmarkInstance) {
                            \$handler.wookmarkInstance.clear();
                        }
                        \$handler = \$('li', \$tiles);
                        \$handler.wookmark(options);
                    });
                }
                applyLayout();
            })(jQuery);
            \$(window).scroll(
                    {
                        previousTop: 0
                    },
                        function () {
                            var currentTop = \$(window).scrollTop();
                            if (currentTop < 100) {
                                \$(\".header\").fadeIn(\"slow\");
                                \$(\"#scrollup\").fadeOut(\"slow\");
							} else {
                                \$(\".header\").fadeOut(\"slow\");
                                \$(\"#scrollup\").fadeIn(\"slow\");
                            }
                            this.previousTop = currentTop;
                        });            
</script></body></html>"
	fi
}
######################################################################
#Check for change in status
######################################################################
check_status_change()
{
	old_status=$(cat $cmd_path/$hostname.$servicename.old|awk -F'|' '{print $1}')
	curr_status=$(cat $cmd_path/$hostname.$servicename.cmd|awk -F'|' '{print $1}')
	logger "old_status :- $old_status | curr_status :- $curr_status" "DEBUG"
	if [ ! -z "$old_status" ] && [ ! -z "$curr_status" ];then
		if [ $old_status -ne $curr_status ];then
			logger "Change in Status for $hostname : $servicename" "DEBUG"
			if [ $email_notification_enabled -eq 1 ];then
				send_email
			fi
		fi 
	fi
}
#########################################################################
#receives and process the check results reached through HTTP POST
#########################################################################
notifier()
{
	read -n $CONTENT_LENGTH request_reached 
	if [ ! -z "$request_reached" ];then
		logger "Notify Request Reached : $request_reached" "DEBUG"
		servicename=$(echo "$request_reached"|awk -F'>|<' '{print $5}')
		hostname=$(echo "$request_reached"|awk -F'>|<' '{print $9}')
		state=$(echo "$request_reached"|awk -F'>|<' '{print $13}')
		output=$(echo "$request_reached"|awk -F'>|<' '{print $17}')
		if [ ! -z "$servicename" ] && [ ! -z "$hostname" ] && [ ! -z "$state" ] && [ ! -z "$output" ];then
			if [ -f $cmd_path/$hostname.$servicename.cmd ];then
				curr_time=$(date +%s)
				cp $cmd_path/$hostname.$servicename.cmd $cmd_path/$hostname.$servicename.old
				echo "$state|$output|$curr_time" >$cmd_path/$hostname.$servicename.cmd
				check_status_change
				if [ -s $cmd_path/$hostname.$servicename.cmd ];then
					logger "status updated for $hostname-$servicename" "DEBUG"
					echo "Content-type: $CONTENT_TYPE"
					echo "Connection: close"
					echo ""
					echo '<notifyresponse>Success<notifyresponse>'
				else
					logger "status updation failed for $hostname-$servicename" "INFO"
					echo "Content-type: $CONTENT_TYPE"
                                        echo "Connection: close"
                                        echo ""
                                        echo '<notifyresponse>Status updation Failed<notifyresponse>'
				fi
			else
				logger "Service :- $servicename not defined for $hostname" "INFO"
				echo "Content-type: $CONTENT_TYPE"
	                        echo "Connection: close"
        	                echo ""
               		        echo '<notifyresponse>Service Not Defined<notifyresponse>'
			fi
		else
			logger "invalid Request " "INFO"
			echo "Content-type: $CONTENT_TYPE"
                        echo "Connection: close"
                        echo ""
                        echo '<notifyresponse>invalid Request<notifyresponse>'
		fi
	else
		logger "Null Request " "INFO"
                        echo "Content-type: $CONTENT_TYPE"
                        echo "Connection: close"
                        echo ""
                        echo '<notifyresponse>Notify Request Null<notifyresponse>'
	fi

}
########################################################################################################
#main function switches to web gui if its http get and to notifier if its http post
########################################################################################################
case "$REQUEST_METHOD" in
	"GET")web
	;;
	"POST")notifier 
	;;	
esac 
