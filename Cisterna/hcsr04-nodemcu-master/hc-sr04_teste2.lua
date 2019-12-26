echoPin = 1
trigPin = 2

gpio.mode(echoPin, gpio.INPUT)
gpio.mode(trigPin, gpio.OUTPUT)

    gpio.trig(echoPin, "up", 
    function(level, when)
        inicio = when
        gpio.trig(echoPin, "down", 
            function(level, when)
                fim = when
            end)
    end)
    

    gpio.write(trigPin, gpio.LOW)
    tmr.delay(2)
    gpio.write(trigPin, gpio.HIGH)
    tmr.delay(10)
    gpio.write(trigPin, gpio.LOW)
    tmr.delay(1000000)
    print("Distancia: " .. ((fim-inicio)/2*0.034))




                            
