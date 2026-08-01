import serial

ser = serial.Serial('/dev/ttyUSB1', 00)

while True:
    data = ser.read(1)
    print(f"{data[0]:02X}")
