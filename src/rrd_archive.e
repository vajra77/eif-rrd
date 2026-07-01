note
	description: "Rappresentazione di un Round Robin Archive (RRA)"

class
	RRD_ARCHIVE

create
	make

feature {NONE} -- Inizializzazione

	make (a_cf: STRING; a_xff: REAL; a_steps, a_rows: INTEGER)
			-- Inizializza un archivio con la funzione di consolidamento (CF),
			-- il fattore XFiles (xff), i passi (steps) e le righe (rows).
		require
			cf_valido: a_cf /= Void and then (a_cf.is_equal ("AVERAGE") or a_cf.is_equal ("MAX") or a_cf.is_equal ("MIN") or a_cf.is_equal ("LAST"))
			xff_valido: a_xff >= 0.0 and a_xff <= 1.0
			steps_positivi: a_steps > 0
			rows_positivi: a_rows > 0
		do
			cf := a_cf
			xff := a_xff
			steps := a_steps
			rows := a_rows
		ensure
			cf_impostato: cf = a_cf
			xff_impostato: xff = a_xff
			steps_impostati: steps = a_steps
			rows_impostate: rows = a_rows
		end

feature -- Accesso

	cf: STRING
			-- Funzione di consolidamento (es. "AVERAGE")

	xff: REAL
			-- XFiles Factor (quota di intervalli sconosciuti tollerati)

	steps: INTEGER
			-- Numero di passi primari per riga di archivio

	rows: INTEGER
			-- Numero totale di righe memorizzate nell'archivio

	as_argument_string: STRING
			-- Rappresentazione in formato stringa per i tool RRD C (es. "RRA:AVERAGE:0.5:1:288")
		do
			Result := "RRA:" + cf + ":" + xff.out + ":" + steps.out + ":" + rows.out
		ensure
			risultato_valido: Result /= Void and not Result.is_empty
		end

invariant
	cf_presente: cf /= Void
	xff_nei_limiti: xff >= 0.0 and xff <= 1.0

end