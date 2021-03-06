﻿///<reference path="node.d.ts" />
///<reference path="include.ts" />
///<reference path="io.ts" />

class PowerSupply extends Device {
    private powerDeviceDir = '/sys/class/power_supply/';
    public deviceName: string = 'legoev3-battery';

    get powerProperties(): any {
        return {
            currentNow: 'current_now',
            voltageNow: 'voltage_now',
            voltageMaxDesign: 'voltage_min_design',
            voltageMinDesign: 'voltage_max_design',
            technology: 'technology',
            type: 'type'
        };
    }

    constructor(deviceName: string) {
        super();

        if(deviceName != undefined)
            this.deviceName = deviceName;

        var rootPath: string;

        try {
            var availableDevices = fs.readdirSync(this.powerDeviceDir);


            if (availableDevices.indexOf(this.deviceName) == -1) {
                this.connected = false;
                return;
            }

            rootPath = path.join(this.powerDeviceDir, availableDevices[availableDevices.indexOf(this.deviceName)]);
        }

        catch (e) {
            console.log(e);
            this.connected = false;
            return;
        }

        this.connect(rootPath/*, [this.sensorProperties.portName]*/);
    }

    //PROPERTIES
    get currentNow(): number {
        return this.getNumber(this.powerProperties.currentNow);
    }

    get voltageNow(): number {
        return this.getNumber(this.powerProperties.voltageNow);
    }

    get voltageMaxDesign(): number {
        return this.getNumber(this.powerProperties.voltageMaxDesign);
    }

    get voltageMinDesign(): number {
        return this.getNumber(this.powerProperties.voltageMaxDesign);
    }

    get technology(): string {
        return this.getProperty(this.powerProperties.technology);
    }

    get type(): string {
        return this.getProperty(this.powerProperties.type);
    }

    get voltageVolts(): number {
        return this.voltageNow / 1000000;
    }

    get currentAmps(): number {
        return this.currentNow / 1000000;
    }

}


class LED extends Device {
    private ledDeviceDir = '/sys/class/leds/';
    public deviceName: string;

    get ledProperties(): any {
        return {
            maxBrightness: 'max_brightness',
            brightness: 'brightness',
            trgger: 'trigger'
        };
    }

    constructor(deviceName: string) {
        super();

        //if (deviceName != undefined)
        this.deviceName = deviceName;

        var rootPath: string;

        try {
            var availableDevices = fs.readdirSync(this.ledDeviceDir);


            if (availableDevices.indexOf(this.deviceName) == -1) {
                this.connected = false;
                return;
            }

            rootPath = path.join(this.ledDeviceDir, availableDevices[availableDevices.indexOf(this.deviceName)]);
        }

        catch (e) {
            console.log(e);
            this.connected = false;
            return;
        }

        this.connect(rootPath);
    }

    //PROPERTIES
    get maxBrightness(): number {
        return this.getNumber(this.ledProperties.maxBrightness);
    }


    get brightness(): number {
        return this.getNumber(this.ledProperties.brightness);
    }

    set brightness(value: number) {
        this.setNumber(this.ledProperties.brightness, value);
    }


    get trigger(): string {
        return this.getString(this.ledProperties.trigger);
    }

    set trigger(value: string) {
        this.setString(this.ledProperties.trigger, value);
    }

}