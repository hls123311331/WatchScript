#!/bin/bash

	# Первый скрипт на публичную отправку данных на директорию Android.
	# С последующем заменением всех похожих файлов.
	# Работает с inotifywait - утилита для показа изменения файлов в определенной директории.
	# Должен удалять файл с устройства, который к нему привязан.
source /home/myScripts/Config.sh
sudo kill -9 "$clear_port"
sleep 2		#производиться очищение порта по PID для того, чтоб не отклонял запрос для Туннеля

clear
pgrep -f "WatchScript.sh" | wc -l

sudo mount /dev/D1/Music /mnt/Music
sudo mount /dev/D1/Foto /mnt/Foto
sudo mount /dev/D1/MetaData /mnt/MD

# scp -P "$P_Pub" "$file" "$Music_Influx"			# Отправка любого файла по публичному
# scp -P "$P_Local" "$file" "$Music_Influx"			# Отправка любого файла по локальному

clear

	status=$(systemctl is-active smbd)
        	if [ "$status" = "active" ]; then
                	systemctl status smbd
        	else
                	echo -e "SMBD isn't running \n\n " & exit
        	fi #Простая проверка - жив ли SMB, тобишь сетевые шары

echo -e "The scripts running.\n\n"

	if [ ! -f "/mnt/Music/test.txt" ]; then
		echo "test context" > /mnt/Music/test.txt
	fi

rsync -v -h -P -e "$P_local_rsync" /mnt/Music/test.txt "$Music_Influx"	#Тестовый файл на проверку отправки файлов
#scp -P "$P_local_scp" /mnt/Music/test.txt "$Music_Influx"		#Тестовый файл на проверку отправки файлов

inotifywait -m -r -e close_write,create,delete --format '%e %w%f' "$Music_Exodus" | while read -r action file;
do
	case "$action" in
		*CLOSE_WRITE*)
			rsync -v -h -P -e  "$P_local_rsync" "$file" "$Music_Influx"
			echo -e " \"$file\" is modify in dir == \"$Music_Exodus\".\n\n"
		;;
		*CREATE*)
			echo " \"$file\" New file in dir == \"$Music_Exodus\"."
		;;
		*DELETE*)
			ssh -p "$P_local_scp" "$Name_And" "rm -f \"$Music_del/$(basename "$file")\""
        		echo -e " \"$file\" is delete in dir == \"$Music_Exodus\".\n\n"
        	;;
	esac
done
