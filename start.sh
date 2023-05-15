#!/system/bin/sh
MODDIR=${0%/*}
sh $MODDIR/update.sh &
sh $MODDIR/control.sh &