-- Firmware do NodeSala
-- informacao sobre o dht22
    -- power supply: 3.3V – 6V DC
    -- output signal: single-bus
    -- sensing element: polymer humidity capacitor & DS18B20
    -- measuring range: humidity 0-100% RH / temperature -40°C – 125°C
    -- accuracy: humidity ±2% / temperature ±0.2°C
    -- sensing period: ~2s
 
pino_presenca = 0
gpio.mode(pino_presenca, gpio.OUTPUT)
gpio.write(pino_presenca, gpio.HIGH)

pino_luz = 1 -- define o pino da iluminacao principal
pwm.setup(pino_luz, 512, 0) -- config. pino, freq. e duty
pwm.start(pino_luz)

pino_arcon = 2
gpio.mode(pino_arcon, gpio.OUTPUT)
gpio.write(pino_arcon, gpio.LOW) -- pino 2 do led vermelho - ar condicionado

pino_umidade = 3
gpio.mode(pino_umidade, gpio.OUTPUT)
gpio.write(pino_umidade, gpio.LOW) -- pino 3 do led verde - umidificador

pino_DHT22 = 4 -- seta o pino do DHT22

pino_pir = 5 -- seta o pino do PIR (Sensor de movimento)
gpio.mode(pino_pir, gpio.INPUT)

topico = {} -- fila de topicos
valor = {} -- fila de valores

function publica_topico ()
    if topico[1] ~= nil then -- primeiro topico da fila
        m:publish(topico[1], valor[1], 0, 0, function()
            print(topico[1] .. " : " .. valor[1])
            table.remove(topico, 1) -- remove topico e valor
            table.remove(valor, 1)
        end)
    end
end
    
function leDHT22()
    print("lendo DHT22...")
    status, temperatura, umidade, temp_decimal, umid_decimal = dht.read(pino_DHT22)
    table.insert(topico, "tccmrocha/sala/temperatura")
    table.insert(valor,  temperatura)
    table.insert(topico, "tccmrocha/sala/umidade")
    table.insert(valor,  umidade)  
    --[[
    tmr.alarm(
        3, 
        100, 
        tmr.ALARM_SINGLE,
        publica_topico
    )
---]]
end

function lePIR()
    print("lendo PIR...")
    presenca = gpio.read(pino_pir)
    if presenca == 0 then 
        gpio.write(pino_presenca, 1)
    else
        gpio.write(pino_presenca, 0) 
    end
    table.insert(topico, "tccmrocha/sala/presenca")
    table.insert(valor,  presenca)
    
    ---[[
    tmr.alarm(
        0, 
        500, 
        tmr.ALARM_AUTO,
        publica_topico
    )
---]]
end

m = mqtt.Client("node-sala", 120, "marcelo", "mrbf8051")

-- setup Last Will and Testament (optional)
-- Broker will publish a message with qos = 0, retain = 0, data = "offline" 
-- to topic "/lwt" if client don't send keepalive packet
m:lwt("/lwt", "offline", 0, 0)

m:on("connect", function(client) print ("connected") end)

m:on("offline", function(client) print ("offline") end)

-- on publish message receive event
m:on(
    "message", 
    function(client, topic, data) 
        print (topic .. " = " .. data)
        if topic == "tccmrocha/sala/umidificador" and data == "liga" then
            gpio.write(pino_umidade, gpio.HIGH)
        end
        if topic == "tccmrocha/sala/umidificador" and data == "desliga" then
            gpio.write(pino_umidade, gpio.LOW)
        end
        if topic == "tccmrocha/sala/arcondicionado" and data == "liga" then
            gpio.write(pino_arcon, gpio.HIGH)
        end
        if topic == "tccmrocha/sala/arcondicionado" and data == "desliga" then
            gpio.write(pino_arcon, gpio.LOW)
        end
        if topic == "tccmrocha/sala/luz" and data == "liga" then
            pwm.setduty(pino_luz, 1023)
        end
        if topic == "tccmrocha/sala/luz" and data == "desliga" then
            pwm.setduty(pino_luz, 0)
        end
        if topic == "tccmrocha/sala/luz/intensidade" then
            pwm.setduty(pino_luz, data)
        end
        if topic == "tccmrocha/all/pergunta" and data == "ping" then
            m:publish("tccmrocha/all/resposta/sala", wifi.sta.getip().." - Online", 0, 0, function() print("NodeMCU-Sala-OnLine") end)
        end
        
        
    end
)

host = "tccmrocha.webhop.me"
porta_mqtt = 1883

m:connect(
    host, 
    porta_mqtt, 
    0, 
    function(client)
        print("connected")
        client:subscribe("tccmrocha/sala/luz", 0, function(client) print("subscribe success") end)
        client:subscribe("tccmrocha/sala/luz/intensidade", 0, function(client) print("subscribe success") end)
        client:subscribe("tccmrocha/sala/arcondicionado", 0, function(client) print("subscribe success") end)
        client:subscribe("tccmrocha/sala/umidificador", 0, function(client) print("subscribe success") end)
        client:subscribe("tccmrocha/all/pergunta", 0, function(client) print("subscribe success") end)
        ---[[
        tmr.alarm(
            1, 
            30000, 
            tmr.ALARM_AUTO, 
            leDHT22
        )
        ---]]
        tmr.alarm(
            2, 
            1000, 
            tmr.ALARM_AUTO, 
            lePIR
        )
        ---]]
    end,
    function(client, reason)
     print("failed reason: " .. reason)
    end
)


m:close();
-- you can call m:connect again
