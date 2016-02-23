# literate-invention

SRVR_MONITOR_1.sh is an apache cgi script which can be used for server monitoring and alert notification.

The current version supports 

      :- Graphical User Interface 
      :- Email alerts 
      :- Multiple hosts etc
      
SRVR_MONITOR.properties is the default configuration file.

Structure is some what same as nagios . 
 
Service notifiction form a different host can be updated using http over xml ( same as in nrdp in nagios).

sample xml format :- <notifyinfo><servicename>servicename</servicename><hostname>hostname</hostname><state>state</state><output>output</output></notifyinfo>
                  where state value varies from 
                                      0 meaning process OK
                                      1 meaning warning and 
                                      2 meaning critical
    
    style.css ,main.css ,jquery.wookmark.js ,jquery.imagesloaded.js,jquery.min.js, fonts.css these files need to pe kept in cgi-bin of apache along with the script  and the script requires permission to create folder and files.
