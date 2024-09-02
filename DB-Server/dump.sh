#wget https://raw.githubusercontent.com/rentaropy/Ubuntu/main/DB-Server/dump.sh && nano ./dump.sh && chmod u+x ./dump.sh

mysql -u edogawa_user < $HOME/db_name.sql| grep -v "TABLE_SCHEMA" > $HOME/dump.log
awk '$0="file_"$0"=$HOME/"$0"_dump_$(date +%Y%m%d).sql"' $HOME/dump.log >  $HOME/dump.exe
awk '$0="mysqldump -u edogawa_user "$0" > $file_"$0  ' $HOME/dump.log >>  $HOME/dump.exe
awk '$0="create database if not exists "$0";"' $HOME/dump.log   >  $HOME/create_db.sql
chmod 700  $HOME/dump.exe
$HOME/dump.exe
find $HOME/edogawa*.sql  -mtime +3 -exec rm {} \;
file1=$HOME/edogawa*.sql
scp $file1 ubuntu@10.20.1.106:/home/ubuntu
