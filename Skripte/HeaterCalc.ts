/********************************************************************************/
/*                          Ansteuerung des Heizers mit SSR                     */
/********************************************************************************/

var tempValHeater : number = 0.0;
var jsonHeater : string = "";

schedule('*/1 * * * * *', () =>         //im Sekundentakt ausführen
{ 
    let actPowerOut = getState('modbus.1.inputRegisters._Sum_W').val; //Einspeisung = negativ, Bezug = positiv
    let actSolarPower = getState('0_userdata.0.Gesamt_P_PV').val; //aktuelle Solarleistung

    if ((actPowerOut <= -10) && (actSolarPower >= 100)) //Einspeisung min. 10 W und PV Leistung min. 100 W
    {
        tempValHeater = tempValHeater + actPowerOut; //hier wird einfach die Leistung am Smartmeter addiert. Das Vorzeichen bringt der Wert ja mit

        if (tempValHeater < Math.max(-1*actSolarPower, -1500)) //Begrenzen der Leistung vom Heizer -> an die max. Leistung anpassen
        {
            tempValHeater = Math.max(-1*actSolarPower, -1500);
        }
    }

    //Heizer Vorgabe
    jsonHeater = '{"SP_Heizer" : ' + tempValHeater + '}'; //JSON String basteln
    setState('mqtt.0.cmnd.tasmota_3FDE20.POWER', jsonHeater); //hier den JSON String an Tasmota senden

});
