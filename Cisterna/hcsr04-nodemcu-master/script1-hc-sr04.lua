-- boa precisao
-- minimo de 20cm

echoPin = 1
trigPin = 2

gpio.mode(echoPin, gpio.INT)
gpio.mode(trigPin, gpio.OUTPUT)

gpio.trig(echoPin, "up", 
    function(level, when)
        inicio = when
        gpio.trig(echoPin, "down", 
        function(level, when)
            fim = when
        end)
    end)
    
function trigger()            
    gpio.write(trigPin, gpio.LOW)
    tmr.delay(2)
    
    gpio.write(trigPin, gpio.HIGH)
    tmr.delay(10)
    gpio.write(trigPin, gpio.LOW)

end

            

function imprime()
    print("Inicio: " .. inicio)
    print("Fim: " .. fim)
    print("Distancia: " .. string.format("%.2f", ((fim-inicio)/2*0.034)))
end

tmr.alarm(
    0,
    1000, 
    0,
    trigger
)

tmr.alarm(
    1,
    2000,
    0,
    imprime
)





