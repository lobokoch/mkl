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
		
		/*html {
		  height: 100%;
		}*/
		
		body {
		  font-family: Arial, Helvetica, sans-serif;
		  color: #404c51;
		
		  margin: 0 auto;
		  padding: 0;
		  width: 100% !important;
		  min-height: 100vh !important;
		}
		
		.acord {
		  padding: 0px 0px;
		}
		
		.kb-actions {
		  text-align: center;
		}
		
		.kb-label-required {
		  margin-left: 2px;
		  font-weight: bold;
		  color: red;
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
		  /*background-color: rgb(231, 231, 231) !important;*/
		  background-color: #ececec !important;
		  color: #9b9b9b !important;
		}
		
		a, button {
		  margin-right: .25em !important;
		}
		
		/*a, .ui-button-text {
		  color: #fff !important;
		  width: 90px !important;
		  margin-right: 40px !important;
		  font-weight: bold;
		  border-radius: 3px;
		  font-size: large;
		}*/
		
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
		  background-color:darkred !important;
		  color: white !important;
		  /*font-weight: bold;*/
		  /*text-decoration: overline;*/
		}
		
		.kb-conta-vence-hoje /*:not(:last-child)*/ {
		  background-color: red !important;
		  /*color:white !important;*/
		  /*font-weight: bold;*/
		}
		
		.kb-conta-vence-amanha {
		  background-color: orange !important;
		  /*color: white !important;*/
		  /*font-weight: bold;*/
		}
		
		.kb-conta-vence-proximos-3-dias {
		  background-color: rgb(254, 253, 194) !important;
		}
		
		.kb-conta-vence-esta-semana {
		  background-color: rgb(224, 252, 160) !important;
		}
		
		.kb-conta-legenda {
		  margin-right: 5px;
		  padding-left: 5px;
		  padding-right: 5px;
		  border: 1px solid silver;
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
		    /*width: 1170px;*/
		    width: 100% !important;
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
		  font-size: 1em;
		  background-color: /*#1e94d2;*/  #4285f4;
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
		
		.teste .ui-accordion .ui-accordion-header  {
		  width: 100% !important;
		  border: 1px solid red;
		}
		.ui-accordion-content {
		  width: 99.7% !important;
		}
		
		/*
		.custom .ui-scrollpanel-wrapper {
		  border-right: 9px solid #f4f4f4 !important;
		}
		
		.custom .ui-scrollpanel-bar {
		  background-color: #1976d2 !important;
		  opacity: 1 !important;
		  transition: background-color .3s !important;
		}
		
		.custom .ui-scrollpanel-bar:hover {
		  background-color: #135ba1 !important;
		}
		*/
		
		.div-card {
		  float: left;
		  margin: 5px;
		}
		
		.div-card .ui-card {
		  padding: 10px !important;
		  display: table;
		  font-family: Arial, Helvetica, sans-serif;
		}
		
		.div-card .ui-card-header {
		  color: gray !important;
		  text-transform: uppercase;
		}
		
		.div-card .ui-card-content {
		  color: rgb(20, 38, 32) !important;
		  font-size: large;
		  font-weight: bold;
		}
		
		.div-card-pago .ui-card {
		  background-color: rgba(0, 206, 0, 0.4);
		}
		
		/* Begin Fluxo de Caixa */
		
		.div-card-credito .ui-card {
		  background-color: rgba(0, 191, 255, 0.4);
		  border: 1px solid rgba(0, 0, 255, 1);
		  min-width: 170px;
		}
		
		.div-card-debito .ui-card {
		  background-color: rgba(255, 0, 0, 0.5);
		  border: 1px solid rgba(255, 0, 0, 1);
		  min-width: 170px;
		}
		
		.div-card-saldo .ui-card {
		  background-color: rgba(0, 206, 0, 0.4);
		  border: 1px solid rgba(0, 206, 0, 1);
		  min-width: 170px;
		}
		
		.div-card-saldo-atual .ui-card {
		  background-color: rgba(255, 128, 0, 0.5);
		  border: 1px solid rgba(255, 165, 0, 1);
		  min-width: 170px;
		  /*margin-left: 20px;*/
		}
		
		@media screen and (max-width: 550px) {
		  .div-card-saldo-atual .ui-card {
		    margin-left: 20px;
		  }
		
		}
		/* End Fluxo de Caixa */
		
		/* BEGIN SALDO DE CRÉDITOS*/
		.saldo-critico .ui-card {
		  background-color: rgba(255, 0, 0, 0.5);
		  border: 1px solid rgba(255, 0, 0, 1);
		  min-width: 170px;
		}
		
		.saldo-baixo .ui-card {
		  background-color: rgba(255, 128, 0, 0.5);
		  border: 1px solid rgba(255, 165, 0, 1);
		  min-width: 170px;
		}
		
		.saldo-normal .ui-card {
		  background-color: rgba(0, 191, 255, 0.4);
		  border: 1px solid rgba(0, 0, 255, 1);
		  min-width: 170px;
		}
		
		.saldo-alto .ui-card {
		  background-color: rgba(0, 206, 0, 0.4);
		  border: 1px solid rgba(0, 206, 0, 1);
		  min-width: 170px;
		}
		
		
		/* END SALDO DE CRÉDITOS*/
		
		.div-card-7dias .ui-card {
		  background-color: rgba(192, 192, 192, 0.5);
		}
		
		.div-card-hoje .ui-card {
		  background-color: rgba(255, 128, 0, 0.5);
		}
		
		.div-card-amanha .ui-card {
		  background-color: rgba(255, 255, 128, 0.7);
		}
		
		.div-card-atraso .ui-card {
		  background-color: rgba(255, 0, 0, 0.5);
		}
		
		.dropdown-readonly .ui-dropdown .ui-dropdown-label, .dropdown-readonly .ui-dropdown .ui-dropdown-trigger  {
		  background-color: #ececec !important;
		  color: #9b9b9b !important;
		}
		
		.autocomplete-readonly .ui-autocomplete  {
		  background-color: #ececec !important;
		  color: #9b9b9b !important;
		}
		
		.calendar-readonly .ui-calendar .ui-inputtext  {
		  background-color: #ececec !important;
		  color: #9b9b9b !important;
		}
		
		.input-readonly input {
		  background-color: #ececec !important;
		  color: #9b9b9b !important;
		}
		
		/* Begin Fluxo de caixa */
		.kb-fin-credito { /* #0F009E */
		    color: rgb(15, 0, 158) !important;
		}
		
		.kb-fin-debito { /* #BB000F */
		  color: rgb(187, 0, 15) !important;
		}
		/* End Fluxo de caixa */
		
		.kb-form-panel-header {
		 /* background-color:  rgb(244, 244, 244);*/
		  padding: 3px;
		  margin-bottom: 0px;
		  font-weight: bold;
		}
		
		.hidden {
			display: none;
		}
		
		
		
		@media (min-width: 1200px) {
		  .container {
		    margin: 0 auto;
		    /*width: 1170px;*/
		    width: 100% !important;
		  }
		}
		
		/* Begin HOME*/
		.home-logo {
		  text-align: center;
		}
		
		.home-text-main {
		  font-size: 1.8rem;
		  font-weight: bold;
		  font-family: "Open Sans", "Helvetica Neue", sans-serif;
		  line-height: 110%;
		  color: #1e94d2 !important;
		  margin: 0 auto !important;
		  width: 100% !important;
		  text-align: center;
		}
		
		.home-btn-abrir-conta {
		  text-align: center !important;
		}
		
		.home-btn-abrir-conta .ui-button {
		  text-align: center;
		  height: 100px !important;
		  width: 90% !important;
		  font-weight: bold;
		  border-radius: 3px;
		  font-size: x-large;
		  margin: 0 auto !important;
		  margin-bottom: 20px !important;
		}
		
		.home-btn-entrar {
		  text-align: center !important;
		}
		
		.home-faq-header {
		  text-align: center;
		  margin-top: 0px !important;
		}
		
		@media screen and (min-width: 401px) { /* > que 400*/
		  .home-logo {
		    text-align: left;
		  }
		
		  .home-text-main {
		    font-size: 3rem;
		    width: 50% !important;
		  }
		
		  .home-btn-abrir-conta .ui-button {
		    width: 470px !important;
		  }
		
		  .home-faq-header {
		    text-align: left;
		  }
		
		}
		
		.home-btn-entrar .ui-button {
		  border: 1px solid silver;
		  height: 40px !important;
		
		 width: 120px !important;
		  /*margin-right: 40px !important;*/
		  font-weight: bold;
		  border-radius: 3px;
		  font-size: large;
		}
		
		
		
		.home-container {
		  background-color: #fff;
		  margin: 0 auto;
		  padding: 0;
		  width: 100% !important;
		  /*height: 100vh !important;*/
		  height: 100% !important;
		
		  clear: both;
		  overflow: auto;
		  float: left;
		}
		
		.home-blocks {
		  margin-top: 20px;
		  margin-bottom: 20px;
		}
		
		.home-text-blocks {
		  font-size: 1.5rem;
		  font-family: 'Netflix Sans', 'Helvetica Neue', Helvetica, Arial, sans-serif;
		  color: #1e94d2 !important;
		  margin: 0 auto !important;
		  width: 85% !important;
		}
		
		.home-separator {
		  margin: 20px !important;
		  padding: 0px !important;
		  height: 5px !important;
		  /*border-top: 1px solid #1e94d2;
		  border-bottom: 1px solid #1e94d2;*/
		  background-color: #1e94d2;
		}
		
		.home-faq {
		  font-size: larger;
		}
		
		.home-faq p {
		  margin-bottom: 20px !important;
		  color: #1e94d2 !important;
		}
		
		.home-footer {
		  text-align: center !important;
		  background-color: #1e94d2 !important;
		  color: #fff;
		  height: 100px;
		  margin-top: 5px;
		  border-top: 1px solid #2d487c;
		
		  float: left;
		}
		
		/* End HOME*/
		
		/* CUIDADO: Begin botões com link */
		
		a.ui-button:hover  {
		  background-color: #116fbf !important;
		  color: #fff !important;
		}
		
		a.ui-button-secondary:hover  {
		  background-color: #c8c8c8 !important;
		  color: #000 !important;
		}
		
		a.ui-button-success:hover {
		  background-color: #1c7e19 !important;
		}
		/* End botões com link*/
		
		/* Tooltip flickering https://github.com/primefaces/primeng/issues/8335 */
		.ui-tooltip {
		  pointer-events: none;
		}
				
		'''
	}
	
	
	
}