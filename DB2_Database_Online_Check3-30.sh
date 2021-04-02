#!/bin/sh
inst_name=$1
db_name=$2
if [ -z ${inst_name} -o -z ${db_name} ] 
then
	echo "pls input instance name and db name"
else
	echo "==============================基础环境检查=============================="
	echo "==============================检查数据库版本和授权=============================="
	echo ""
	su - ${inst_name} -c "db2level ;db2licm -l"
	echo ""
	echo "==============================检查toor及其属组名称=============================="
	echo ""
	id toor
	echo ""
	echo "==============================检查数据库A/C/M/V属组及其名称 =============================="
	su - ${inst_name} -c "
	db2 get dbm cfg|grep -i SYSADM_GROUP;
	db2 get dbm cfg|grep -i SYSCTRL_GROUP;
	db2 get dbm cfg|grep -i SYSMON;
	db2 get dbm cfg|grep -i SYSMAINT"
	echo ""

	GROUP1=`su - ${inst_name} -c "db2 get dbm cfg|grep -i SYSADM_GROUP"|awk -F= '{print $2}'|sed '/^ *$/d'`
	if
    [ "${GROUP1}" == "" ];
	then
	echo "SYSADM_GROUP没有配置"
	else
	echo "SYSADM_GROUP :" `cat /etc/group |grep -i ${GROUP1}`
	fi 
    

	GROUP2=`su - ${inst_name} -c "db2 get dbm cfg|grep -i SYSCTRL_GROUP"|awk -F= '{print $2}'|sed '/^ *$/d'`
	if [ "${GROUP2}" == "" ]
	then
	echo "SYSCTRL_GROUP没有配置"
	else
	echo "SYSCTRL_GROUP :" `cat /etc/group |grep -i ${GROUP2}`
	fi


	GROUP3=`su - ${inst_name} -c "db2 get dbm cfg|grep -i SYSMON"|awk -F= '{print $2}'|sed '/^ *$/d'`
	if [ "${GROUP3}" == "" ]
	then
	echo "SYSMON没有配置"
	else
	echo "SYSMON :"  `cat /etc/group |grep -i ${GROUP3}`
	fi


	GROUP4=`su - ${inst_name} -c "db2 get dbm cfg|grep -i SYSMAINT"|awk -F= '{print $2}'|sed '/^ *$/d'`
	if [ "${GROUP4}" == "" ]
	then
	echo "SYSMAINT没有配置"
	else
	echo "SYSMAINT : "  `cat /etc/group |grep -i ${GROUP4}`
	fi

	echo ""
	echo "==============================检查dbqry用户是否创建=============================="
	echo "应用查询用户:" `id dbqry`
	
	echo ""
	echo "==============================检查应用用户及其属组名称=============================="
	os=`uname`
	if [ "$os" == "Linux" ]
	then
	read -p "Pls Input user id : "
	idname=$REPLY
	echo "应用用户" `id  ${idname} `
	else
	read idname?"Pls Input user id : "
	echo "应用用户" `id  ${idname} `
	fi
	
	echo ""
	echo "==============================检查数据库相关文件系统(名称、是否外置盘等)=============================="
	OS=`uname`
	if [ "${OS}" == AIX ];
		then
		df -sg
		else 
		df -h
	fi
	
	echo "==============================检查数据库字符集/端口=============================="
	su - ${inst_name} -c "db2 get db cfg for ${db_name}|grep -i  'Database code set'"
	su - ${inst_name} -c "db2 connect to ${db_name};db2 get dbm cfg|grep -i tcp"
	SVCENAMEname=`su - ${inst_name} -c "db2 get dbm cfg|grep -i tcp"|awk -F= '{print $2} '`
  	cat /etc/services |grep -w ${SVCENAMEname} 
	
	
	echo "==============================检查实例注册变量=============================="
	su - ${inst_name} -c "db2set -all"
	
	echo "==============================检查实例参数 =============================="
   su - ${inst_name} -c "
   db2 get dbm cfg|grep -i MON_HEAP_SZ         ;      
   db2 get dbm cfg|grep -i DISCOVER            ;      
   db2 get dbm cfg|grep -i DISCOVER_INST       ;      
   db2 get dbm cfg|grep -i DIAGPATH            ;      
   db2 get dbm cfg|grep -i AUTHENTICATION      ;      
   db2 get dbm cfg|grep -i SYSADM_GROUP        ;      
   db2 get dbm cfg|grep -i SYSCTRL_GROUP       ;      
   db2 get dbm cfg|grep -i SYSMAINT_GROUP      ;      
   db2 get dbm cfg|grep -i SYSMON_GROUP        ;      
   db2 get dbm cfg|grep -i HEALTH_MON          ;      
   db2 get dbm cfg|grep -i INSTANCE_MEMORY     ;      
   db2 get dbm cfg|grep -i SVCENAME            ;      
   db2 get dbm cfg|grep -i AUDIT_BUF_SZ"               
	
	echo "==============================检查数据库参数 =============================="  
	su - ${inst_name} -c "
	db2 get db cfg for ${db_name}|grep -i LOGFILSIZ         ;   
	db2 get db cfg for ${db_name}|grep -i LOGPRIMARY        ;
	db2 get db cfg for ${db_name}|grep -i LOGSECOND         ;
	db2 get db cfg for ${db_name}|grep -i LOCKTIMEOUT       ;
	db2 get db cfg for ${db_name}|grep -i LOCKLIST          ;
	db2 get db cfg for ${db_name}|grep -i NEWLOGPATH        ;
	db2 get db cfg for ${db_name}|grep -i DBHEAP            ;
	db2 get db cfg for ${db_name}|grep -i LOGBUFSZ          ;
	db2 get db cfg for ${db_name}|grep -i MIRRORLOGPATH     ;
	db2 get db cfg for ${db_name}|grep -i LOGARCHMETH1      ;
	db2 get db cfg for ${db_name}|grep -i AUTO_MAINT        ;
	db2 get db cfg for ${db_name}|grep -i AUTO_TBL_MAINT    ;
	db2 get db cfg for ${db_name}|grep -i AUTO_RUNSTATS     ;
	db2 get db cfg for ${db_name}|grep -i DISCOVER_DB       ;
	db2 get db cfg for ${db_name}|grep -i REC_HIS_RETENTN   ;
	db2 get db cfg for ${db_name}|grep -i TRACKMOD    "      

	echo "==============================检查数据库连接状态 =============================="   
	su - ${inst_name} -c "
	db2 connect to ${db_name}"  
	echo "==============================检查表空间名称、类型、页大小、大小 ==============================" 
	su - ${inst_name} -c "
	db2 connect to ${db_name};
	db2pd -d ${db_name} -tab "
	echo "==============================检查用户数据库权限 =============================="   
	su - ${inst_name} -c "
	db2 connect to ${db_name};
	db2 \"select GRANTEE,connectauth,bindaddauth,createtabauth,IMPLSCHEMAAUTH from sysibm.sysdbauth where GRANTEE='${inst_name}'\"
	db2 terminate"
	echo "==============================检查缓冲池名称、页大小、大小 =============================="   
	su - ${inst_name} -c "
	db2 connect to ${db_name};
	db2pd -d ${db_name} -buff "
	echo "==============================检查表空间状态 =============================="   
  	su - ${inst_name} -c "
	  db2 connect to ${db_name};
	db2 list tablespaces|egrep -i 'name|state'"
	echo "==============================检查Hadr状态 =============================="   
	su - ${inst_name} -c "
	db2 connect to ${db_name};
	db2pd -d ${db_name} -Hadr"
	echo "==============================PUBLIC权限回收的检查 =============================="   
	su - ${inst_name} -c "
	db2 connect to ${db_name};
	db2 \"select GRANTEE,connectauth,bindaddauth,createtabauth,IMPLSCHEMAAUTH from sysibm.sysdbauth where GRANTEE='public'\"
	db2 terminate"
	echo "==============================检查服务器网络权限认证 =============================="   
	su - ${inst_name} -c "
	db2 connect to ${db_name};
	db2 get dbm cfg|grep -i server_encrypt"
	echo "==============================检查数据库审计状态 =============================="   
	su - ${inst_name} -c "
	db2 connect to ${db_name};
	db2 \"select * from syscat.AUDITUSE \";
	db2audit describe"
	echo "==============================检查主备toor是否加载实例的db2profile  =============================="   
	cat /home/toor/.profile
	echo "==============================检查开机自启脚本 =============================="   
	if [ ${OS} == 'AIX' ];
	then
	cat /usr/sbin/cluster/events/startapp.sh
	else
	      cat /etc/rc.local
	fi
	echo "==============================确认/home/toor目录下是否上传数据库检查脚本 =============================="   
	ls -l /home/toor/db2_check     
fi       
         
         
         
         
         
         
         
         