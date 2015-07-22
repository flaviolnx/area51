#!/bin/bash 

####################################################################################
#      DELETE AWS GLACIER FILES
#      Depends python bot e aws
#
#      Created By Flávio Andrade
#
#      VERSION 0.0.3
#
#     - Adicionado função mtglacier em 14/07/2015
#     - Criado a função principal e o help em 20/07/2015
#
####################################################################################

# Generate a CSV With Timestamp UTC
function_csv(){
> /tmp/RAW.txt
> /tmp/RAW_parse.txt
> /tmp/file.txt
> /tmp/date_in.txt
> /tmp/date_out.txt
awk -F " " '{print $8";"$2}' $JOURNAL_DIR/$JOURNAL| sort |uniq >> $OUTPUT_DIR/RAW.txt
awk -F";" '{print $1}' $OUTPUT_DIR/RAW.txt >> $OUTPUT_DIR/file.txt
gawk -F";" '{print strftime ("%c",$2)}' $OUTPUT_DIR/RAW.txt >> $OUTPUT_DIR/date_in.txt 
paste -d ";" $OUTPUT_DIR/file.txt $OUTPUT_DIR/date_in.txt > $OUTPUT_DIR/$OUTPUT_FILE_CSV
rm -f $OUTPUT_DIR/file.txt $OUTPUT_DIR/date_in.txt $OUTPUT_DIR/RAW.txt
};


# Create a new parsed journal
function_new_journal(){

DATABASE=$(cat $SPREADSHEET_DIR/$SPREADSHEET | grep Remover | awk -F";" '{print $1}'| uniq)

 for HOSTNAME in $(cat $SPREADSHEET_DIR/$SPREADSHEET | grep Remover | awk -F";" '{print $2}' | uniq );do
  cat $JOURNAL_DIR/$JOURNAL |sort | uniq | grep $HOSTNAME | grep $DATABASE.$YEAR  >> $OUTPUT_DIR/$OUTPUT_JOURNAL;
 done
};



function_archive_ID(){

 for HOSTNAME in $(cat $SPREADSHEET | grep Remover | awk -F";" '{print $2}' | uniq );do
  cat $JOURNAL_DIR/$JOURNAL |sort | uniq | grep $HOSTNAME | grep $DATABASE.$YEAR | awk -F" " '{print $4";"$8";"}'  >> $OUTPUT_DIR/$OUTPUT_FILE;
 done
};

function_mtglacier(){
 
  for ARCHIVE_ID in $(awk -F";" '{print $2}' $OUTPUT_DIR/$OUTPUT_FILE) ; do
    echo "mtglacier purge-vault --config $CONF_FILE --filter "' +  $ARCHIVE_ID  - '" --vault $VAULT --journal $JOURNAL_DIR/$JOURNAL"
  done
};

function_mtglacier_journal(){
     echo "mtglacier purge-vault --config $CONF_FILE  --vault $VAULT --journal $OUTPUT_DIR/$OUTPUT_JOURNAL"
};

# codigo aws cli
function_aws_cli(){
  for ARCHIVE_ID in $(awk -F";" '{print $1}' $OUTPUT_DIR/$OUTPUT_FILE) ; do
   aws glacier delete-archive --region $REGION --account-id $ACCOUNT --vault-name $VAULT --archive-id "$ARCHIVE_ID"
  done
echo AWS
};

function_main(){

#CREATE THE CONSTRAINTS FOR A NEW DELETION JOB

 export AWS_SECRET_ACCESS_KEY=
 export AWS_ACCESS_KEY_ID=

 REGION=""
 ACCOUNT=""
 JOURNAL_DIR="/home/user"
 OUTPUT_DIR="/tmp"
 OUTPUT_FILE="del_list.txt"
 OUTPUT_JOURNAL="delete.journal"
 OUTPUT_FILE_CSV="journal.csv"
 CONF_FILE="/etc/glacier.conf"
 SPREADSHEET_DIR="/home/user/Documents"


#CREATE THE VARIABLES FOR A NEW DELETION JOB

 echo "Enter te location to remove"
 read SPREADSHEET
 echo "Year of remotion: "
 read YEAR
 echo " enter a vault to deletion"
 read VAULT
 echo "enter journal name"
 read JOURNAL
};

case "$1:$2" in

-mtglacier:--create-journal)
	function_main
	function_new_journal
	;;

-mtglacier:--del-journal)
	function_main
	function_mtglacier_journal
	;;

-mtglacier:--file-journal)
	function_main
	function_archive_ID
	;;

-mtglacier:--del-file)
	function_main
	function_mtglacier
	;;

-aws-cli:*)
	function_main
	function_archive_ID;
	function_aws_cli
	;;

-list:*)
	function_main
	function_csv
	;;

*.*|--help:*|-h:*)
echo "  -mtglacier - Use mtglacier format to delete files"
echo "    OPTIONS"
echo "    --create-journal - Create a parsed journal from the original"
echo "    --del-journal - delete files using a journal output"
echo "    --file-journal - Create a parsed file name journal to delete"
echo "    --del-file - Delete a file in a list"
echo "  -aws-cli - Use AWS-CLI format to delete Files"
echo "  -list - Generate a CSV list parsed by UTC"
;;

esac

exit 0
