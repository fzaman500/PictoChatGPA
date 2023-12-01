import asyncio
from bleak import BleakScanner
from bleak import BleakClient
import time

generic_access_profile = '00001800-0000-1000-8000-00805f9b34fb'
generic_attribute_profile = '00001801-0000-1000-8000-00805f9b34fb'
nordic_uart_service = '6e400001-b5a3-f393-e0a9-e50e24dcca9e'
uart_rx = '6e400003-b5a3-f393-e0a9-e50e24dcca9e'
uart_tx = '6e400003-b5a3-f393-e0a9-e50e24dcca9e'

async def main():
    address = "CB:14:06:A6:96:54"
    async with BleakClient(address) as client:
        svcs = await client.get_services()
        for service in svcs:
            print(service)
        reading = await client.read_gatt_char(uart_rx)
        print(int.from_bytes(reading, byteorder='big'))
        await client.write_gatt_char(uart_tx, b"C", response=True)
        reading = await client.read_gatt_char(uart_rx)
        print(reading)
        print(int.from_bytes(reading, byteorder='big'))

asyncio.run(main())