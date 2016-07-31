#!/usr/bin/env ruby

require 'pry'
require 'nokogiri'
require 'axlsx'
require 'possibly'

SKIP_FILTER = true

VALID_MANUFACTURERS = [{id: "70049", name: "Fluke"}, {id: "70050", name: "Tektronix"}]
VALID_CATEGORIES1 = [ "EL.PRÜF", "INDOOR", "LABOR", "MECH.MESS", "MULTIMETER", "NETZ", 
										  "NETZGERÄTE", "OSZI", "OSZILLOSKO", "THERMO"]
VALID_CATEGORIES2 = [ "Analysator", "Batterie", "DC Quellen", 
											"Digital", "Druck/Luft", "Entfernung", 
											"Funktion", "Iso/Erdung", 
											"Kabel", "Kfz", "Leistungsm",
											"Logikanaly", "Messdaten", "Netzgeräte",
											"Oszibis500", "Osziüb4", "Osziüb500",
											"Partikel", "Photo", "Prozess",
											"SampOszi", "Schall", "Schwingung",
											"Scope", "Signal", "Source Smu",
											"Spannung", "Spektrum", "Spezial",
											"Stromzange", "Temperatur", "Timer/Coun",
											"Tisch", "Vde0100", "Vde0113",
											"Vde0701", "Wellenaus", "Wärmebild"]

filepath = ARGV.first
outputfile = ARGV[1] || filepath.split("/").last.split(".").first + ".xlsx"

doc = File.open(filepath) { |f| Nokogiri::XML(f) }
# doc = Nokogiri::HTML(open("http://www.threescompany.com/"))

valid_manu_ids = VALID_MANUFACTURERS.map{|val| val.values.first}
data = []

# parse xml file
doc.xpath("//ARTICLE").each do |article|
	liefnr = article.css("LIEFNR").first.content
	cat1 = article.css("CAT1").first.content
	cat2 = article.css("CAT2").first.content

	if SKIP_FILTER || valid_manu_ids.include?(liefnr) && VALID_CATEGORIES1.include?(cat1) && VALID_CATEGORIES2.include?(cat2)
		
		valid_manufac = VALID_MANUFACTURERS.select {|val| val[:id] == liefnr}.first
		if valid_manufac
			manufac = valid_manufac[:name]
		else
			manufac = liefnr
		end
		model = article.css("ARTNO").first.content
		headline = article.css("ARTKENN").first.content
		desc = Maybe(article.css("TEXT").first).content.or_else("")
		price = article.css("LISPRE").first.content
		price_type = "List price (discount on request)"

		if price == "0"
			price_type = "Price on request"
		end

		image = ""
		datasheet = ""

		article.css("FILES").first.css("FILE").each do |file|
			if file.attr("type") && file.attr("type") == "Bild"
				image = file.css("PATH").first.content
			end

			if file.attr("type") && file.attr("type") == "Datenblatt"
				datasheet = file.css("PATH").first.content
			end
		end

		features = "<ul>"
		article.css("DAT").each do |feature|
			features += "\n<li>" + feature.attr("type2") + ": " + feature.content + "</li>"
		end 
		features += "\n</ul>"
		desc = "<h3>" + headline + "</h3>\n" + desc + "\n\n<hr><h4>Features</h4>\n" + features


		# other attributes (nn for Rentog)
		art_id 	 = article.css("ARTID").first.content
		tax 		 = article.css("TAX").first.content
		bestand  = article.css("BESTAND").first.content
		zusatznr = article.css("ZUSARTNR").first.content
		preisanf = article.css("PREANF").first.content
		ean 		 = article.css("EAN").first.content
		

		data << [model, manufac, desc, "Sell", "Brand new", cat1, cat2, price, price_type, "worldwide", image, datasheet, "", art_id, tax, bestand, zusatznr, preisanf, ean]
	end
end


# export to excel

@p = Axlsx::Package.new
@wb = @p.workbook
@wb.add_worksheet(:name => "Devices") do |sheet|
	sheet.add_row ["model", "manufacturer", "description", "type", "condition", "main category", "sub category", "price", "price options", "shipment to", "images", "attachments", "-", "art_id", "tax", "bestand", "zusatznr", "preisanf", "ean"]

	data.each do |row|
		sheet.add_row row
	end
end

# save file
@p.serialize(outputfile)