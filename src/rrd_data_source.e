note
	description: "Rappresentazione di una sorgente dati (DS) in un file RRD"

class
	RRD_DATA_SOURCE

create
	make

feature {NONE} -- Inizializzazione

	make (a_name: STRING; a_type: STRING; a_heartbeat: INTEGER; a_min, a_max: STRING)
			-- Inizializza una sorgente dati.
		require
			nome_valido: a_name /= Void and then not a_name.is_empty
			tipo_valido: a_type /= Void and then (a_type.is_equal ("GAUGE") or a_type.is_equal ("COUNTER") or a_type.is_equal ("DERIVE") or a_type.is_equal ("ABSOLUTE"))
			heartbeat_positivo: a_heartbeat > 0
		do
			name := a_name
			type := a_type
			heartbeat := a_heartbeat
			min_value := a_min
			max_value := a_max
		ensure
			name_impostato: name = a_name
			type_impostato: type = a_type
		end

feature -- Accesso

	name: STRING
	type: STRING
	heartbeat: INTEGER
	min_value: STRING -- Usiamo STRING per gestire "U" (Unknown) o numeri puri
	max_value: STRING

	as_argument_string: STRING
			-- Stringa formattata per le API C (es. "DS:traffico:COUNTER:600:0:U")
		do
			Result := "DS:" + name + ":" + type + ":" + heartbeat.out + ":" + min_value + ":" + max_value
		end

invariant
	nome_valido: name /= Void and not name.is_empty
end