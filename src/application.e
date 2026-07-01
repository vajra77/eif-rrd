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
			sample_data: LINKED_LIST [STRING]
		do
			-- 1. Setup e Creazione del file
			create my_rrd.make ("router_traffic.rrd", 300)
			create ds_network.make ("in_bytes", "GAUGE", 600, "0", "U") -- Usiamo GAUGE per semplicità di test numerico
			my_rrd.add_data_source (ds_network)
			create rra_hourly.make ("AVERAGE", 0.5, 1, 288)
			my_rrd.add_archive (rra_hourly)

			my_rrd.create_on_disk

			-- 2. Inserimento di un dato fittizio immediato
			create sample_data.make
			sample_data.extend ("1250.5")
			my_rrd.update ("N", sample_data)

			-- 3. CHIAMATA AL NUOVO FETCH
			my_rrd.fetch ("AVERAGE", "-1h", "N")
		end
end