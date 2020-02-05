package br.com.kerubin.dsl.mkl.generator.web.analitycs

import static br.com.kerubin.dsl.mkl.generator.Utils.*
import br.com.kerubin.dsl.mkl.generator.GeneratorExecutor
import br.com.kerubin.dsl.mkl.generator.IGeneratorExecutor
import br.com.kerubin.dsl.mkl.generator.BaseGenerator

class WebAnalitycsGenerator extends GeneratorExecutor implements IGeneratorExecutor {
	
	public static val SERVICE_NAME = 'analytics.service'
	public static val SERVICE_CLASS_NAME = 'AnalyticsService'
	
	public static val MODULE_NAME = 'analytics.module'
	public static val MODULE_CLASS_NAME = 'AnalyticsModule'
	
	new(BaseGenerator baseGenerator) {
		super(baseGenerator)
	}
	
	override generate() {
		if (service.hasWebAnalitycs) {
			generateFiles
		}
	}
	
	def generateFiles() {
		val path = webAnalitycsDir 
		path.doGenerate
	}
	
	def doGenerate(String path) {
		val fullPathService = path + '/' + SERVICE_NAME
		fullPathService.generateService
		
		val fullPathModule = path + '/' + MODULE_NAME
		fullPathModule.generateModule
	}
	
	def generateModule(String name) {
		val fileName = name + '.ts'
		generateFile(fileName, generateAnalitycsModule)
	}
	
	def generateService(String name) {
		val fileName = name + '.ts'
		generateFile(fileName, generateAnalitycsService)
	}
	
	def CharSequence generateAnalitycsService() {
		val id = service.webAnalitycsId
		val isOnlyInProduction = service.webAnalitycs.isOnlyInProductionEnabled
		
		'''
		«IF isOnlyInProduction»
		import { environment } from './../../environments/environment';
		«ENDIF»
		import { Injectable } from '@angular/core';
		
		const ID = '«id»';
		
		declare let gtag: Function;
		
		const CAN_EXECUTE = «IF isOnlyInProduction»environment.production«ELSE»true«ENDIF»;
		«IF !isOnlyInProduction»
		/**
		 * WARNING: ONLY IN PRODUCTION IS DISABLED, DEVELOPE MODE IS ALSO ENABLED.
		 */
		«ENDIF»
		
		@Injectable()
		export class «SERVICE_CLASS_NAME» {
		
		  constructor() { }
		  
			sendGTag(url: string) {
				if (CAN_EXECUTE && url) {
			    // Replaces the real uuid with a token "uuid"
			    // from: https://www.kerubin.com.br/contapagar/ba73db96-8766-4ab1-819c-28859f89add4
			    // to:   https://www.kerubin.com.br/contapagar/uuid
			    const index = url.lastIndexOf('/');
			    let pagePath = url;
			    if (index > -1) {
			      const id = url.substring(index + 1);
			      if (id && id.length > 32) { // length of ba73db96-8766-4ab1-819c-28859f89add4
			        const parts = id.split('-');
			        if (parts && parts.length === 5) {
			          pagePath = url.substring(0, index) + '/uuid';
			        }
			      }
			    }
				  gtag('config', ID, {'page_path': pagePath});
				}
			}
		
		  sendEvent(category: string, action: string, label: string, value: number = 0) {
		  	if (CAN_EXECUTE) {
		  	  gtag('event', action, {
		  	    'event_category': category,
		  	    'event_label': label,
		  	    'value': value
		  	  });
		  	}
		    
		  }
		}
		
		/*
		From: https://developers.google.com/analytics/devguides/collection/gtagjs/events
		- <action> é a string que aparecerá como a ação do evento nos relatórios de eventos do Google Analytics.
		- <category> é a string que aparecerá como a categoria do evento.
		- <label> é a string que aparecerá como o rótulo do evento.
		- <value> é um número inteiro não negativo que aparecerá como o valor do evento.
		
		*/

		
		'''
	}
	
	def CharSequence generateAnalitycsModule() {
		'''
		import { «SERVICE_CLASS_NAME» } from './«SERVICE_NAME»';
		import { NgModule } from '@angular/core';
		import { CommonModule } from '@angular/common';
		
		
		
		@NgModule({
		  declarations: [],
		  imports: [
		    CommonModule
		  ],
		  providers: [
		    «SERVICE_CLASS_NAME»
		  ]
		})
		export class «MODULE_CLASS_NAME» { 
			// Auto generated.
		}
		
		'''
	}
	
	
}