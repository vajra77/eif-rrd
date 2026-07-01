class
	APPLICATION

create
	make

feature

	make
		local
			my_rrd: RRD_DATABASE
			ds_network: RRD_DATA_SOURCE
			rra_hourly: RRD_ARCHIVE
		do
			-- 1. Definiamo il database logico
			create my_rrd.make ("router_traffic.rrd", 300)

			-- 2. Definiamo le metriche da tracciare
			create ds_network.make ("in_bytes", "COUNTER", 600, "0", "U")
			my_rrd.add_data_source (ds_network)

			-- 3. Definiamo gli archivi storici
			create rra_hourly.make ("AVERAGE", 0.5, 1, 288) -- Punti ogni 5 min per 1 giorno
			my_rrd.add_archive (rra_hourly)

			-- 4. Creazione (per ora simulata)
			my_rrd.create_on_disk
		end
end