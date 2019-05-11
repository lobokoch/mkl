package br.com.kerubin.dsl.mkl.generator.web.others

import static br.com.kerubin.dsl.mkl.generator.Utils.*
import br.com.kerubin.dsl.mkl.generator.GeneratorExecutor
import br.com.kerubin.dsl.mkl.generator.IGeneratorExecutor
import br.com.kerubin.dsl.mkl.generator.BaseGenerator

class WebStylesGenerator extends GeneratorExecutor implements IGeneratorExecutor {
	
	
	new(BaseGenerator baseGenerator) {
		super(baseGenerator)
	}
	
	override generate() {
		generateFiles
	}
	
	def generateFiles() {
		val path = getWebSrcDir
		path.generateFiles
	}
	
	def generateFiles(String path) {
		val fileName = path + '/styles.css'
		generateFile(fileName, generateContent)
	}
	
	def CharSequence generateContent() {
		'''
		/* You can add global styles to this file, and also import other style files */
		body {
		  font-family: Arial, Helvetica, sans-serif;
		  color: #404c51;
		  margin: 0;
		}
		
		.acord {
		  padding: 0px 0px;
		}
		
		.kb-actions {
		  text-align: center;
		}
		
		.total-conta-paga {
		  color: blue;
		  font-weight: bold;
		  text-align: right;
		}
		
		.total-contas {
		  font-weight: bold;
		  text-align: right;
		}
		
		.conta-nao-paga {
		  /*color: red;*/
		  font-weight: bold;
		  text-align: right;
		}
		
		.total-conta-nao-paga {
		  color: red;
		  font-weight: bold;
		  text-align: right;
		}
		
		.show-b {
		  border: 1px solid red;
		}
		
		.label-l {
		  margin-left: 5px !important;
		}
		
		.label-r {
		  margin-right: 5px !important;
		}
		
		label {
		  font-weight: bold;
		}
		
		.invalid-message {
		  color: red;
		  /*font-weight: bold;*/
		}
		
		input.ng-invalid.ng-dirty {
		  border: 1px solid rgb(165, 0, 12) !important;
		}
		
		.sem-margens {
		  margin: 0px;
		  padding: 0px;
		  border: 0px;
		}
		
		.calendario {
		  width: 110px !important;
		}
		
		.read-only {
		  background-color: rgb(231, 231, 231) !important;
		}
		
		a, button {
		  margin-right: .25em !important;
		}
		
		.campo-destaque {
		  border-color: rgb(34, 122, 215) !important;
		  background-color: rgb(201, 225, 250) !important;
		  font-weight: bold;
		}
		
		.centro-pai {
		  height: 100%;
		  width: auto;
		  display: table;
		  margin: 0;
		}
		
		.centro-filho {
		  height: 100%;
		  width: auto;
		  display: table-cell;
		  vertical-align: bottom !important;
		}
		
		.kb-as-table {
		  height: 100%;
		  width: auto;
		  display: table;
		  margin: 0;
		}
		
		.kb-as-table-cell {
		  height: 100%;
		  width: auto;
		  display: table-cell;
		  vertical-align: bottom !important;
		}
		
		.kb-field-money {
		  text-align: right;
		}
		
		.kb-conta-valor-apagar {
		  font-weight: bold;
		  color: red !important;
		}
		
		.kb-conta-valor-pago {
		  font-weight: bold;
		  color: blue !important;
		}
		
		.kb-conta-paga {
		  /*text-decoration: line-through;*/
		  color: blue !important;
		}
		
		.kb-conta-vencida {
		  /*background-color:darkred !important;*/
		  color: red !important;
		  font-weight: bold;
		  /*text-decoration: overline;*/
		}
		
		.kb-conta-vence-hoje {
		  /*background-color: red !important;*/
		  color: red !important;
		  /*font-weight: bold;*/
		}
		
		.kb-conta-vence-amanha {
		  /*background-color: orange !important;*/
		  color: darkorange !important;
		  /*font-weight: bold;*/
		}
		
		.kb-conta-vence-esta-semana {
		  color: green !important;
		  /*font-weight: bold;*/
		}
		
		.kb-container {
		  /*float: left !important;*/
		  overflow: auto !important;
		}
		
		.clearfix:before,
		.clearfix:after {
		  display: table !important;
		  content: " " !important;
		}
		
		.clearfix:after {
		  clear: both !important;
		}
		
		
		
		/* Applays the "container" rule only from 1200px */
		@media (min-width: 1200px) {
		  .container {
		    margin: 0 auto;
		    width: 1170px;
		  }
		}
		
		
		.ui-autocomplete-dd .ui-autocomplete-dropdown.ui-corner-all{
		  position:absolute;
		  transform: translateX(-100%);
		}
		
		.criar-sua-conta {
		  margin-top: 10px;
		  font-size: 1.5em;
		  font-weight: bold;
		  text-align: center;
		}
		
		.primeiro-mes-gratis {
		  font-size: 1.2em;
		  background-color: orangered;
		  border: 1px solid black;
		  height: 50px;
		  line-height: 50px;
		  color: white;
		  text-align: center;
		}
		
		.newaccount-dropdown-icon {
		  z-index: 1000 !important;
		}
		
		#newaccount-dropdown .ui-dropdown {
		  width: 350px !important;
		  height: 39px !important;
		  left: -2px !important;
		}
		
		.sumField {
		  font-weight: bold;
		  text-align: right;
		}
		
		.kb-sum-footer {
		  background-color: rgb(219, 232, 239) !important;
		}
		
		/* Diminui os tamanho dos ícones */
		.ui-table, .ui-table .ui-table-tablewrapper table {
		  font-size: 12px !important;
		}
		
		.ui-button-icon-only  {
		    font-size: 11px !important;
		}
		
		.ui-button-info  {
		  /* Adjusts according to the caption */
		  width: auto !important;
		}
		
		.ui-panel-title {
		  font-size: 1em;
		  font-weight: bold !important;
		}
		
		.ui-spinner-button { /* Corrects sppinr margin right */
		  margin-right: 0px !important;
		}
		
		.kb-make-copies {
		  margin-left: 0px;
		  margin-top: 10px;
		  border-top: 1px solid gray;
		  border-bottom: 1px solid gray;
		}
		
		.ui-accordion-content {
		  width: 99.7% !important;
		}
		'''
	}
	
	
	
}