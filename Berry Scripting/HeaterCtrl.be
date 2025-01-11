#- ***************************************
    Holt Daten vom MQTT Server ab und steuert
    den Heizer mi PFM an
#- *************************************** -#


import webserver
import mqtt
import json


class HeaterCtrl : Driver
    var counter
    var CounterSum
    var SP_Modulation
    var SP_Heizer
    var TempDS #Temperature from DS18B20 over MQTT (Sensor)
    var PowerHeater #Leistung des Heizers in W
  
  
  def init()
    self.counter = 0;    #- initialize the counter -#
    self.CounterSum = 0;
    self.SP_Modulation = 0.0;
    self.SP_Heizer = 0.0;
    self.PowerHeater = 1500; #W
         
    # register fast_loop method
    tasmota.add_fast_loop(def () self.fast_loop() end)

    #subscriben!!!!!!!
    self.mqtt_subscribe()
  end
  

  #- this method receives events from buttons and displays values on main page -#
  def web_sensor()
    #- display the counter in its own line -#
    import string
    var msg = string.format(
        "{s}SP_Modulation{m}%.f %%{e}"..
        "{s}SP_Heizer{m}%.1f W{e}"..
        "{s}Temperatur{m}%.1f °C{e}", #..
        self.SP_Modulation, self.SP_Heizer, self.TempDS)
    tasmota.web_send_decimal(msg)
  end

  def webUpdate()
    import string
    print("webupdate...")
  end

  #subscribe mqtt
  def mqtt_subscribe()
    mqtt.subscribe("cmnd/#") # cmnd/# -> funzt!!!!
    print("subscribe")
  end


  #erzeugt ein PFM Signal - muss aller 10 ms ausgeführt werden
  def PFM_Generator(SP_Modulation)

    self.CounterSum = self.CounterSum + SP_Modulation;
    if self.CounterSum > 100
      self.CounterSum = self.CounterSum - 100;
      gpio.digital_write(gpio.pin(gpio.REL1), gpio.HIGH);
    else
      gpio.digital_write(gpio.pin(gpio.REL1), gpio.LOW);
    end
  end


  # Event was die Daten vom subscribe ausließt
  def mqtt_data(topic, idx, payload_s, payload_b)
    #print("topic: ", topic)
    #print("payload: ", payload_s)

    #if topic == 'cmnd/tasmota_Heater/POWER' #hier muss der richtige ESP32 ausgewählt werden
    #  print('try to subscribed!')
    #  self.mqtt_subscribe()
    #end

    var sensors = json.load(payload_s)
    self.SP_Heizer = real(sensors['SP_Heizer']) #read sensor data
    #print("SP_Heizer: ", self.SP_Heizer) #debug
    self.SP_Modulation = self.SP_Heizer / (self.PowerHeater / 100.0)  #calculate the PFM value -> 2500 W = 100 %

    return true
  end
  

  #- *************************************** -#
  def json_append()
    if !self.PFM_Generator return nil end
      import string
      var msg = string.format(",\"HeaterPower\":{\"PowerSP\":%.f}", self.SP_Modulation)
  
      tasmota.response_append(msg)
  end


  #- *************************************** -#
  def every_second()
    var sensors = json.load(tasmota.read_sensors()) #mqtt sensor string auslesen
    #print("DS18B20: ", sensors) 
    self.TempDS = real(sensors['DS18B20']['Temperature'])
    #print("Value: ", self.TempDS) #'DS18B20, Temperature'

  end


  #- *************************************** -#
  # -> Standard ist 50 ms -> gehe in Konsole und Eingabe: Sleep 10
  def fast_loop()
    # called at each iteration, and needs to be registered separately and explicitly
    if !self.PFM_Generator return nil end
      if self.SP_Heizer <= -10.0 # Leistungen größer 10 W
        self.PFM_Generator(self.SP_Modulation * -1.0);
        #print("SP_Mod: ", self.SP_Modulation)
    else
      self.PFM_Generator(0);
    end
  end

end


#- *************************************** -#
tasmota.add_driver(HeaterCtrl())                 # register driver
tasmota.add_fast_loop(HeaterCtrl.fast_loop())    # register a closure to capture the instance of the class as well as the method
