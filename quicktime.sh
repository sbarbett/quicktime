#!/bin/bash

# Quicktime: Generate start and end times for specified intervals (compatible with GNU and BSD/macOS).

usage() {
  echo "Usage: quicktime [hour|day|week|month] [--calendar] [--format FORMAT] [--utc]"
  exit 1
}

# Defaults
FORMAT="%Y-%m-%d %H:%M:%S"
CALENDAR=false
USE_TZ=""
INTERVAL=""
HAS_MILLISECONDS=false

# Detect OS
if date --version >/dev/null 2>&1; then
  DATE_CMD="gnu"
else
  DATE_CMD="bsd"
fi

# Parse arguments
while [[ $# -gt 0 ]]; do
  case "$1" in
    hour|day|week|month)
      INTERVAL="$1"
      shift
      ;;
    --calendar)
      CALENDAR=true
      shift
      ;;
    --format)
      FORMAT="$2"
      # Check if format contains milliseconds
      if [[ "$FORMAT" == *"SSS"* ]]; then
        HAS_MILLISECONDS=true
      fi
      # Convert user-friendly format to date command format
      FORMAT=${FORMAT//yyyy/%Y}
      FORMAT=${FORMAT//MM/%m}
      FORMAT=${FORMAT//dd/%d}
      FORMAT=${FORMAT//hh/%H}
      FORMAT=${FORMAT//mm/%M}
      FORMAT=${FORMAT//ss/%S}
      FORMAT=${FORMAT//SSS/%3N}
      shift 2
      ;;
    --utc)
      USE_TZ="-u"
      shift
      ;;
    *)
      usage
      ;;
  esac
done

# Validate required arguments
if [ -z "$INTERVAL" ]; then
  usage
fi

# Calculate times based on OS and interval
if [ "$CALENDAR" = true ]; then
  if [ "$DATE_CMD" = "gnu" ]; then
    # GNU date handling
    case "$INTERVAL" in
      hour)
        # Last hour (previous hour), start at 00 minutes
        LAST_HOUR=$(date $USE_TZ -d "1 hour ago" +"%Y-%m-%d %H:00:00")
        START="$LAST_HOUR"
        END=$(date $USE_TZ -d "$LAST_HOUR + 59 minutes 59 seconds" +"%Y-%m-%d %H:59:59")
        ;;
      day)
        # Yesterday, from 00:00:00 to 23:59:59
        YESTERDAY=$(date $USE_TZ -d "yesterday" +"%Y-%m-%d")
        START="$YESTERDAY 00:00:00"
        END="$YESTERDAY 23:59:59"
        ;;
      week)
        # Last week: previous Monday 00:00:00 to previous Sunday 23:59:59
        PREV_MONDAY=$(date $USE_TZ -d "last Monday" +"%Y-%m-%d")
        PREV_SUNDAY=$(date $USE_TZ -d "last Sunday" +"%Y-%m-%d")
        START="$PREV_MONDAY 00:00:00"
        END="$PREV_SUNDAY 23:59:59"
        ;;
      month)
        # Last month: first day of previous month 00:00:00 to last day of previous month 23:59:59
        FIRST_OF_PREV_MONTH=$(date $USE_TZ -d "$(date +%Y-%m-01) -1 month" +"%Y-%m-01")
        LAST_OF_PREV_MONTH=$(date $USE_TZ -d "$FIRST_OF_PREV_MONTH +1 month -1 day" +"%Y-%m-%d")
        START="$FIRST_OF_PREV_MONTH 00:00:00"
        END="$LAST_OF_PREV_MONTH 23:59:59"
        ;;
    esac
    
    # Format the dates for GNU
    START_FORMATTED=$(date $USE_TZ -d "$START" +"$FORMAT")
    END_FORMATTED=$(date $USE_TZ -d "$END" +"$FORMAT")
    
  else
    # BSD date handling
    case "$INTERVAL" in
      hour)
        # Get the current hour
        CURRENT_HOUR=$(date $USE_TZ +"%H")
        # Calculate the previous hour
        if [ "$CURRENT_HOUR" -eq 0 ]; then
          # If current hour is 0, previous hour is 23 of yesterday
          PREV_HOUR=23
          PREV_DAY=$(date $USE_TZ -v-1d +"%Y-%m-%d")
        else
          PREV_HOUR=$((CURRENT_HOUR - 1))
          PREV_DAY=$(date $USE_TZ +"%Y-%m-%d")
        fi
        # Format with leading zero if needed
        PREV_HOUR=$(printf "%02d" $PREV_HOUR)
        
        # Create the start and end times
        START="$PREV_DAY $PREV_HOUR:00:00"
        END="$PREV_DAY $PREV_HOUR:59:59"
        ;;
      day)
        # Yesterday
        YESTERDAY=$(date $USE_TZ -v-1d +"%Y-%m-%d")
        START="$YESTERDAY 00:00:00"
        END="$YESTERDAY 23:59:59"
        ;;
      week)
        # Get today's day of week (0=Sunday, 6=Saturday)
        DOW=$(date $USE_TZ +"%w")
        
        # Calculate days to go back to last Sunday
        if [ "$DOW" -eq 0 ]; then
          DAYS_TO_LAST_SUNDAY=7
        else
          DAYS_TO_LAST_SUNDAY="$DOW"
        fi
        
        # Calculate days to go back to last Monday
        DAYS_TO_LAST_MONDAY=$((DAYS_TO_LAST_SUNDAY + 6))
        
        # Get last Sunday and last Monday
        LAST_SUNDAY=$(date $USE_TZ -v-"$DAYS_TO_LAST_SUNDAY"d +"%Y-%m-%d")
        LAST_MONDAY=$(date $USE_TZ -v-"$DAYS_TO_LAST_MONDAY"d +"%Y-%m-%d")
        
        START="$LAST_MONDAY 00:00:00"
        END="$LAST_SUNDAY 23:59:59"
        ;;
      month)
        # Get current month and year
        CURRENT_MONTH=$(date $USE_TZ +"%m")
        CURRENT_YEAR=$(date $USE_TZ +"%Y")
        
        # Calculate previous month and year
        if [ "$CURRENT_MONTH" -eq 1 ]; then
          PREV_MONTH=12
          PREV_YEAR=$((CURRENT_YEAR - 1))
        else
          PREV_MONTH=$((CURRENT_MONTH - 1))
          PREV_YEAR="$CURRENT_YEAR"
        fi
        
        # Format with leading zero if needed
        PREV_MONTH=$(printf "%02d" $PREV_MONTH)
        
        # Determine the last day of the previous month
        case "$PREV_MONTH" in
          01|03|05|07|08|10|12) LAST_DAY=31 ;;
          04|06|09|11) LAST_DAY=30 ;;
          02)
            # Check for leap year
            if (( PREV_YEAR % 4 == 0 && (PREV_YEAR % 100 != 0 || PREV_YEAR % 400 == 0) )); then
              LAST_DAY=29
            else
              LAST_DAY=28
            fi
            ;;
        esac
        
        START="$PREV_YEAR-$PREV_MONTH-01 00:00:00"
        END="$PREV_YEAR-$PREV_MONTH-$LAST_DAY 23:59:59"
        ;;
    esac
    
    # Format the dates for BSD
    START_FORMATTED=$(date $USE_TZ -j -f "%Y-%m-%d %H:%M:%S" "$START" +"$FORMAT")
    END_FORMATTED=$(date $USE_TZ -j -f "%Y-%m-%d %H:%M:%S" "$END" +"$FORMAT")
  fi
else
  # Regular intervals (relative to current time)
  if [ "$DATE_CMD" = "gnu" ]; then
    CURRENT_TIME=$(date $USE_TZ +"%Y-%m-%d %H:%M:%S")
    
    case "$INTERVAL" in
      hour)
        START=$(date $USE_TZ -d "$CURRENT_TIME -1 hour" +"$FORMAT")
        END=$(date $USE_TZ +"$FORMAT")
        ;;
      day)
        START=$(date $USE_TZ -d "$CURRENT_TIME -1 day" +"$FORMAT")
        END=$(date $USE_TZ +"$FORMAT")
        ;;
      week)
        START=$(date $USE_TZ -d "$CURRENT_TIME -7 days" +"$FORMAT")
        END=$(date $USE_TZ +"$FORMAT")
        ;;
      month)
        START=$(date $USE_TZ -d "$CURRENT_TIME -30 days" +"$FORMAT")
        END=$(date $USE_TZ +"$FORMAT")
        ;;
    esac
  else
    case "$INTERVAL" in
      hour)
        START=$(date $USE_TZ -v-1H +"$FORMAT")
        END=$(date $USE_TZ +"$FORMAT")
        ;;
      day)
        START=$(date $USE_TZ -v-1d +"$FORMAT")
        END=$(date $USE_TZ +"$FORMAT")
        ;;
      week)
        START=$(date $USE_TZ -v-7d +"$FORMAT")
        END=$(date $USE_TZ +"$FORMAT")
        ;;
      month)
        START=$(date $USE_TZ -v-30d +"$FORMAT")
        END=$(date $USE_TZ +"$FORMAT")
        ;;
    esac
  fi
  
  # For non-calendar mode, START and END are already formatted
  START_FORMATTED="$START"
  END_FORMATTED="$END"
fi

# Add milliseconds only if the format explicitly includes them
if [ "$HAS_MILLISECONDS" = true ] && [ "$CALENDAR" = true ]; then
  if [[ "$END_FORMATTED" != *".999"* ]]; then
    # Only add if not already present
    END_FORMATTED="${END_FORMATTED}.999"
  fi
fi

# Output JSON
cat <<EOF
{
  "start": "$START_FORMATTED",
  "end": "$END_FORMATTED"
}
EOF

