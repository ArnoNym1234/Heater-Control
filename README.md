# Heater-Control

Zur Steuerung eines Heizer (Ölradiator, Warmwasserspeiccher, ...) mit "wattgenauer" Leistungsvorgabe.

Ein Berry Script auf einem ESP32 mit Tasmota als Betriebsystem, Vorgabe der Leistung über MQTT aus dem IoBroker, aktuelle Werte per JSON String zurück an den MQTT Server zur Visualisierung.
