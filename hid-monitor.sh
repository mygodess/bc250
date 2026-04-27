#!/usr/bin/bash

MY_VID="0483"
MY_PID="5750"
HID_DEV=""

# 트랩: 종료/재부팅 시그널 감지 시 즉시 전송
cleanup() {
    if [ -n "$HID_DEV" ] && [ -e "$HID_DEV" ]; then
        # 현재 시스템의 종료/재부팅 예약 상태 확인
        SYS_JOBS=$(systemctl list-jobs)

        if echo "$SYS_JOBS" | grep -q "reboot.target"; then
            # 재부팅 시 'R' (0x52) 전송
            printf "\x02\x52" > "$HID_DEV" 2>/dev/null
        elif echo "$SYS_JOBS" | grep -q -E "poweroff.target|halt.target|shutdown.target"; then
            # 전원 종료 시 'O' (0x4f) 전송
            printf "\x02\x4f" > "$HID_DEV" 2>/dev/null
        else
            # 기타 종료 시 'X' (0x58) 전송
            printf "\x02\x58" > "$HID_DEV" 2>/dev/null
        fi
        sync
    fi
    exit 0
}

# SIGTERM(서비스 종료 시)과 SIGINT(Ctrl+C)를 감지
trap cleanup SIGTERM SIGINT

while true; do
    # 1. 장치 검색 및 연결
    if [ ! -e "$HID_DEV" ]; then
        HID_DEV=""
        for dev in /sys/class/hidraw/hidraw*; do
            if grep -q "HID_ID=.*$MY_VID:.*$MY_PID" "$dev/device/uevent" 2>/dev/null; then
                HID_DEV="/dev/$(basename "$dev")"
                break
            fi
        done
        [ -z "$HID_DEV" ] && sleep 1 && continue
    fi

    # 2. [수신] STM32에서 'S'(0x53)가 들어오면 종료 실행
    # timeout을 주어 루프가 갇히지 않게 함
    RAW_DATA=$(timeout 0.5 dd if="$HID_DEV" bs=2 count=1 2>/dev/null | xxd -p)

    if [[ "$RAW_DATA" == "0253" ]]; then
        echo "Shutdown Signal Received from STM32."
        systemctl poweroff
    fi

    sleep 0.1
done

