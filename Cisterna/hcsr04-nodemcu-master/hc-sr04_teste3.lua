echoPin = 1
trigPin = 2
dados = {}
dados[0]=0
dados[1]=1
indice = 0


gpio.mode(echoPin, gpio.INPUT)
gpio.mode(trigPin, gpio.OUTPUT)

gpio.trig(echoPin, "both", 
    function(level, when)
        dados[indice] = when
        indice = indice + 1
    end)
        
function start()
    gpio.write(trigPin, gpio.LOW)
    tmr.delay(2)
        inicio = tmr.now()
    gpio.write(trigPin, gpio.HIGH)
    tmr.delay(10)
    gpio.write(trigPin, gpio.LOW)


end

tmr.alarm(
    1,
    2000,
    0,
    function()
        print("Distancia: " .. ((dados[1]-dados[0])/2*0.034))
    end
)

start()




                            
