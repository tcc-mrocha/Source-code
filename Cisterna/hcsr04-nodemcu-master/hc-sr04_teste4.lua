echoPin = 1
trigPin = 2

gpio.mode(echoPin, gpio.INPUT)
gpio.mode(trigPin, gpio.OUTPUT)


gpio.write(trigPin, gpio.LOW)
tmr.delay(2)
gpio.write(trigPin, gpio.HIGH)
tmr.delay(10)
gpio.write(trigPin, gpio.LOW)
    
inicio = tmr.now()
    
gpio.trig(echoPin, "low", 
    function(level, when)
        fim = when
        print("Inicio: " .. inicio)
        print("Fim: " .. fim)
        print("Distancia: " .. ((fim-inicio)/2*0.034))
        gpio.trig(echoPin, "up", 
            function(level, when) 
                print("foi....")
            end
        )
    end
)


