#!/bin/ash
# set -x
START=`date +%s`
#INTERFACES=`ls /sys/class/net/`


while getopts "w:c:h" OPT; do
        case $OPT in
                "w") warn=$OPTARG;;
                "c") crit=$OPTARG;;
                "h") help;;
        esac
done


WARNING=$(echo "$warn * 1000000" | bc)
CRITICAL=$(echo "$crit * 1000000" | bc)

#which iftop > /dev/null 2>&1
#if [ $? != 0 ]; then
#        echo "Iftop not installed"
#        exit 1
#fi

IFTOP="/usr/bin/iftop"
PERFDATA=""
overloaded=""
ex_st=0
int=0
int_ol=0
for i in eth0;
do
        #IF_UP=`cat /sys/class/net/$i/operstate`
        if [ -e "/sys/class/net/$i/operstate"  ]; then
                IF_UP=`cat /sys/class/net/$i/operstate 2>&1`
        else
                continue
        fi
        if [ $IF_UP == "up" ] || [ $IF_UP == "unknown" ]; then
                INTERFACE=$i
                TMP_FILE="/tmp/int_${INTERFACE}_cache"

                $IFTOP -i $INTERFACE -n -t -s 2 > $TMP_FILE 2>&1
                if [ $? != 0 ]; then
                        rm -f $TMP_FILE
                        continue
                fi

                ##### TOTAL ########
                TOTAL=`cat $TMP_FILE | grep -i 'Total send and receive rate'| awk -F ":" '{print $2}'| awk '{print $1}'`
                ####################
                ##### SEND RATE ####
                SEND=`cat $TMP_FILE | grep -i 'Total send rate'| awk -F ":" '{print $2}'| awk '{print $1}'`
                ###################
                #### REC RATE #####
                REC=`cat $TMP_FILE | grep -i 'Total receive rate'| awk -F ":" '{print $2}'| awk '{print $1}'`
                ##################
                rm -f $TMP_FILE 2>&1



                metric=`echo "$TOTAL" | grep -Eo '[[:alpha:]]+'`
                TOTAL=${TOTAL/${metric}}
                TOTAL=`echo "$TOTAL" | sed 's/,/./'`

                if [ $metric == "Mb" ]; then
                        TOTAL=$(echo "$TOTAL * 1000000" | bc)
                elif [ $metric == "Kb" ]; then
                        TOTAL=$(echo "$TOTAL * 1000" | bc)
                elif [ $metric == "b" ]; then
                        TOTAL=$TOTAL
                else
                        TOTAL=$TOTAL
                fi
                TOTAL=${TOTAL%.*}

                metric=`echo "$SEND" | grep -Eo '[[:alpha:]]+'`
                SEND=${SEND/${metric}}
                SEND=`echo "$SEND" | sed 's/,/./'`

                if [ $metric == "Mb" ]; then
                        SEND=$(echo "$SEND * 1000000" | bc)
                elif [ $metric == "Kb" ]; then
                        SEND=$(echo "$SEND * 1000" | bc)
                elif [ $metric == "b" ]; then
                        SEND=$SEND
                else
                        SEND=$SEND
                fi
                SEND=${SEND%.*}

                metric=`echo "$REC" | grep -Eo '[[:alpha:]]+'`
                REC=${REC/${metric}}
                REC=`echo "$REC" | sed 's/,/./'`

                if [ $metric == "Mb" ]; then
                        REC=$(echo "$REC * 1000000" | bc)
                elif [ $metric == "Kb" ]; then
                        REC=$(echo "$REC * 1000" | bc)
                elif [ $metric == "b" ]; then
                        REC=$REC
                else
                        REC=$REC
                fi
                REC=${REC%.*}

		if [ -z $TOTAL ] ; then
			TOTAL=0
		fi
                if [ $TOTAL -ge $CRITICAL ]; then
                        overloaded="$overloaded $INTERFACE"
                        int_ol=$(echo "$int_ol + 1" | bc)
                        ex_st=2
                elif [ $TOTAL -lt $CRITICAL ] && [ $TOTAL -ge $WARNING ]; then
                        overloaded="$overloaded $INTERFACE"
                        int_ol=$(echo "$int_ol + 1" | bc)
                        if [ $ex_st -eq 0 ]; then
                                ex_st=1
                        fi
                elif [ $TOTAL -le $WARNING ]; then
                        if [ $ex_st -eq 0 ]; then
                                ex_st=0
                        fi
                else
                        echo 0 > /dev/null

                fi

                int=$(echo "$int + 1" | bc)
                PERFDATA="$PERFDATA Total_$INTERFACE=${TOTAL};${WARNING};${CRITICAL};0;${CRITICAL} Send_$INTERFACE=${SEND}; Receive_$INTERFACE=${REC};"

        elif [ $IF_UP == "down" ]; then
                echo 0 > /dev/null
        else
                echo 0 > /dev/null
        fi
done

END=`date +%s`
EXEC_TIME=$(($END-$START))
PERFDATA="$PERFDATA ExecTime=$EXEC_TIME;"

if [ $ex_st -eq 0 ]; then
        echo "OK: $int interfaces under expected load | $PERFDATA"
        exit $ex_st

elif [ $ex_st -eq 1 ]; then
        echo "Warning: $int_ol overloaded interfaces ($overloaded); $int interfaces OK | $PERFDATA"
        exit $ex_st
elif [ $ex_st -eq 2 ]; then
        echo "Critical: $int_ol overloaded interfaces ($overloaded); $int interfaces OK | $PERFDATA"
        exit $ex_st
else
        echo "Unknown: $int_ol overloaded interfaces ($overloaded). $int interfaces OK | $PERFDATA"
        exit 3
fi

