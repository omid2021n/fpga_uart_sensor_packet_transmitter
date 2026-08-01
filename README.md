# fpga_uart_sensor_packet_transmitter
SystemVerilog FPGA design for transmitting six 12-bit sensor readings over UART as a structured 13-byte packet with synchronization byte and periodic transmission.


# FPGA UART Temperature Packet Transmitter (SystemVerilog)

## Overview

This project implements a packet-based UART transmitter in SystemVerilog for FPGA applications.

The design collects six 12-bit sensor values, packages them into a custom 13-byte data frame, and transmits the packet periodically through a UART serial interface to a PC.

The project includes:
- A configurable UART transmitter module
- A packet generator for multiple sensor channels
- Data snapshot logic to guarantee consistent transmission
- A simple serial communication protocol with synchronization byte

---

## Features

- Synthesizable SystemVerilog design
- UART 8N1 communication
  - 8 data bits
  - No parity
  - 1 stop bit
- Configurable system clock and baud rate
- Supports six 12-bit sensor readings
- Periodic packet transmission
- Custom packet format with synchronization byte (`0xAA`)
- Safe packet snapshot before transmission
- FPGA-friendly FSM-based implementation

---

## Project Structure

```
.
├── uart_tx.sv
│   └── UART transmitter module
│
├── uart_tx_package.sv
│   └── Packet generator and UART interface
│
└── README.md
```

---

# System Architecture

```
        Sensor 1 (12-bit)
        Sensor 2 (12-bit)
        Sensor 3 (12-bit)
        Sensor 4 (12-bit)
        Sensor 5 (12-bit)
        Sensor 6 (12-bit)
              |
              v
       Packet Generator
              |
              v
        UART TX Module
              |
              v
        FPGA TX Pin
              |
              v
        PC Serial Terminal
```

---

# UART Configuration

Default configuration:

| Parameter | Value |
|---|---|
| Clock frequency | 25 MHz |
| Baud rate | 9600 |
| Data bits | 8 |
| Stop bits | 1 |
| Parity | None |

---

# Packet Format

Each transmission contains **13 bytes**.

| Byte | Description |
|---|---|
| 0 | Synchronization byte `0xAA` |
| 1 | Sensor 1 upper 4 bits |
| 2 | Sensor 1 lower 8 bits |
| 3 | Sensor 2 upper 4 bits |
| 4 | Sensor 2 lower 8 bits |
| 5 | Sensor 3 upper 4 bits |
| 6 | Sensor 3 lower 8 bits |
| 7 | Sensor 4 upper 4 bits |
| 8 | Sensor 4 lower 8 bits |
| 9 | Sensor 5 upper 4 bits |
| 10 | Sensor 5 lower 8 bits |
| 11 | Sensor 6 upper 4 bits |
| 12 | Sensor 6 lower 8 bits |

---

## Example Packet

For sensor values:

```
temp1 = 1
temp2 = 2
temp3 = 3
temp4 = 4
temp5 = 5
temp6 = 6
```

The UART output is:

```
AA 00 01 00 02 00 03 00 04 00 05 00 06
```

---

# UART Transmitter Design

The UART transmitter uses a finite state machine:

```
        +-------+
        | IDLE  |
        +---+---+
            |
            v
        +-------+
        | SETUP |
        +---+---+
            |
            v
        +-------+
        | SEND  |
        +---+---+
            |
            v
        +-------+
        | STOP  |
        +---+---+
            |
            v
          IDLE
```

## States

### IDLE
- UART line stays high
- Waits for a new byte transmission request

### SETUP
- Generates the start bit

### SEND
- Sends data bits LSB first

### STOP
- Sends stop bit and returns to idle

---

# Packet Snapshot

Before transmission starts, the complete packet is copied into a snapshot register.

This prevents data corruption if sensor values change during UART transmission.

Example:

```
Sensor update:
     temp1,temp2,...temp6 change

Packet snapshot:
     [AA][T1][T2][T3][T4][T5][T6]

UART transmission:
     Always sends one consistent measurement set
```

---

# Simulation

A testbench can verify:

- UART timing
- Start and stop bits
- Correct byte ordering
- Packet transmission interval
- Data integrity

---

# Future Improvements

- Add SPI interface for MAX6675 temperature sensors
- Add CRC/checksum for communication reliability
- Increase baud rate
- Add configurable packet length
- Add UART receiver on FPGA for bidirectional communication

---

# Author

SystemVerilog FPGA UART communication project.


