-- maior sensibilidade
-- menos precisao

echoPin = 1
trigPin = 2

gpio.mode(echoPin, gpio.INT)
gpio.mode(trigPin, gpio.OUTPUT)

gpio.trig(echoPin, "down", 
	function(level, when)
		fim = when
      tmr.alarm(
    0,
    1000,
    0,
    imprime
)

	end)
    
function trigger()            
	gpio.write(trigPin, gpio.LOW)
	tmr.delay(2)
	
	gpio.write(trigPin, gpio.HIGH)
	tmr.delay(10)
	gpio.write(trigPin, gpio.LOW)
    --tmr.delay(10)
	inicio = tmr.now()
end

            

function imprime()
	print("Inicio: " .. inicio)
	print("Fim: " .. fim)
	print("Distancia: " .. ((fim-inicio)/2*0.034))
        tmr.alarm(
    0,
    1000,
    0,
    trigger
)
end

tmr.alarm(
    0,
    1000,
    0,
    trigger
)


