#!/bin/bash
while :
do
	counter=1
	windows=()
	pids=()
	for result in $(wmctrl -lp | awk '{print substr($1,4) " " $3}')
	do
			if [ $((counter%2)) -eq 0 ]
			then
					pids[$((counter/2))]=$result
			else
					index=$((( counter + 1) / 2))
					windows[$index]="0x$result"
			fi
			((counter+=1))
	done
	total_windows=$((counter/2))
	concatenated_windows=""
	for window in "${windows[@]}"
	do
			concatenated_windows="$concatenated_windows|$window"
	done
	window_counter=1
	concatenated_windows=${concatenated_windows:1}
	for result in $(xwininfo -root -tree | egrep "$concatenated_windows" | awk '{print $1}' | tac)
	do
			volume=$((65536/total_windows*window_counter))
			for index in "${!windows[@]}"
			do
					if [[ "${windows[$index]}" = "${result}" ]]
					then
							for sink_input in $(pacmd list-sink-inputs | 
									awk -v pid=$((pids[$index])) '
									$1 == "index:" {idx = $2} 
									$1 == "application.process.id" && $3 == "\"" pid "\"" {print idx}
									')
							do
									pacmd set-sink-input-volume $sink_input $volume
							done
					fi
			done
			((window_counter+=1))
	done
done