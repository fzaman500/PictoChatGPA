import asyncio
from bleak import BleakScanner
from bleak import BleakClient

address = "CB:14:06:A6:96:54"
""""MODEL_NBR_UUID = "2A24"#"RD_URBN_887429230037"
async def main():
    devices = await BleakScanner.discover()
    for d in devices:
        print(d)
    

asyncio.run(main())"""


async def main(address):
    async with BleakClient(address) as client:
        print(client.services)
        #model_number = await client.read_gatt_char(MODEL_NBR_UUID)
        #print("Model Number: {0}".format("".join(map(chr, model_number))))

asyncio.run(main(address))