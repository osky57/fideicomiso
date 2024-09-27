#! /bin/sh 

cd /var/www/html/perroneinmobiliaria/programados/

DIRORIGEN=/home/desarrollo/perroneinmobiliaria/dump
DIRDESTINO=/home/desarrollo/perroneinmobiliaria/dump
DIRDESTINOBKP=/home/desarrollo/perroneinmobiliaria/dump/bkp

DAY=`date +%d`
MONTH=`date +%m`
YEAR=`date +%Y`

cd $DIRORIGEN

mv $DIRDESTINO/*.sql $DIRDESTINOBKP
mv $DIRDESTINO/*.gz  $DIRDESTINOBKP

find $DIRDESTINOBKP/*    -mtime +10 -exec rm -r -f {} \;

pg_dump inmobiliaria > /tmp/$YEAR$MONTH$DAY.perroneinmobiliaria.sql

tar -czf /tmp/$YEAR$MONTH$DAY.perroneinmobiliaria.tar.gz /var/www/html/perroneinmobiliaria/*

mv  /tmp/$YEAR$MONTH$DAY.perroneinmobiliaria.sql      $DIRDESTINO
mv  /tmp/$YEAR$MONTH$DAY.perroneinmobiliaria.tar.gz   $DIRDESTINO


