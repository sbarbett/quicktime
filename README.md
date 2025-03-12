# ⏳ quicktime

Not the video player. This is a simple shell script for quickly generating datetime ranges in ISO 8601 format. It works in both BSD-derived shell environments (macOS) and Linux.

## Overview

Quicktime generates start and end timestamps for various time intervals:
- The last hour
- The last day (24 hours)
- The last week (7 days)
- The last month (30 days)

It can also generate timestamps for calendar-based intervals:
- The previous hour (e.g., 10:00:00 to 10:59:59)
- The previous calendar day (yesterday, from 00:00:00 to 23:59:59)
- The previous calendar week (previous Monday through Sunday)
- The previous calendar month (e.g., February 1st 00:00:00 to February 28th 23:59:59)

## Installation

1. Download the script:
   ```bash
   curl -O https://raw.githubusercontent.com/sbarbett/quicktime/main/quicktime.sh
   ```

2. Make it executable:
   ```bash
   chmod +x quicktime.sh
   ```

3. Optionally, symbolically link it to your PATH:
   ```bash
   ln -s "$(pwd)/quicktime.sh" /usr/local/bin/quicktime
   ```

## Usage

```
quicktime [hour|day|week|month] [--calendar] [--format FORMAT] [--utc]
```

### Arguments

- `hour|day|week|month`: Required. Specifies the time interval to generate.
- `--calendar`: Optional. Use calendar-based intervals instead of relative time.
- `--format FORMAT`: Optional. Specify a custom output format (default: "yyyy-MM-dd HH:mm:ss").
- `--utc`: Optional. Use UTC time instead of local time.

### Format Specifiers

- `yyyy`: 4-digit year
- `MM`: 2-digit month (01-12)
- `dd`: 2-digit day (01-31)
- `hh` or `HH`: 2-digit hour (00-23)
- `mm`: 2-digit minute (00-59)
- `ss`: 2-digit second (00-59)
- `SSS`: 3-digit millisecond (000-999)

## Examples

### Relative Time Intervals

```bash
# Last hour
$ quicktime hour
{
  "start": "2025-03-12 13:01:41",
  "end": "2025-03-12 14:01:41"
}

# Last day (24 hours)
$ quicktime day
{
  "start": "2025-03-11 14:01:41",
  "end": "2025-03-12 14:01:41"
}

# Last week (7 days)
$ quicktime week
{
  "start": "2025-03-05 14:01:41",
  "end": "2025-03-12 14:01:41"
}

# Last month (30 days)
$ quicktime month
{
  "start": "2025-02-10 14:01:41",
  "end": "2025-03-12 14:01:41"
}
```

### Calendar-Based Intervals

```bash
# Previous hour
$ quicktime hour --calendar
{
  "start": "2025-03-12 13:00:00",
  "end": "2025-03-12 13:59:59"
}

# Previous day (yesterday)
$ quicktime day --calendar
{
  "start": "2025-03-11 00:00:00",
  "end": "2025-03-11 23:59:59"
}

# Previous calendar week (Monday-Sunday)
$ quicktime week --calendar
{
  "start": "2025-03-03 00:00:00",
  "end": "2025-03-09 23:59:59"
}

# Previous calendar month
$ quicktime month --calendar
{
  "start": "2025-02-01 00:00:00",
  "end": "2025-02-28 23:59:59"
}
```

### Custom Format

```bash
# Date only format
$ quicktime day --format "yyyy-MM-dd"
{
  "start": "2025-03-11",
  "end": "2025-03-12"
}

# With milliseconds
$ quicktime hour --calendar --format "yyyy-MM-dd HH:mm:ss.SSS"
{
  "start": "2025-03-12 13:00:00.000",
  "end": "2025-03-12 13:59:59.999"
}
```

### UTC Time

```bash
$ quicktime day --utc
{
  "start": "2025-03-11 14:01:41",
  "end": "2025-03-12 14:01:41"
}
```

## License

MIT
