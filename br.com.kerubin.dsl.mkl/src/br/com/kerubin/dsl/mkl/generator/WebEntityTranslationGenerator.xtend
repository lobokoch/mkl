package br.com.kerubin.dsl.mkl.generator

import br.com.kerubin.dsl.mkl.model.Entity

import static extension br.com.kerubin.dsl.mkl.generator.EntityUtils.*
import java.util.List

class WebEntityTranslationGenerator extends GeneratorExecutor implements IGeneratorExecutor {
	
	new(BaseGenerator baseGenerator) {
		super(baseGenerator)
	}
	
	override generate() {
		generateFiles
	}
	
	def generateFiles() {
		generateTranslationKeysForEntities
		generateTranslationService
	}
	
	def getDefaultTranslationFileName() {
		val path = service.webServiceI18nPath
		val fileName = path + I18N_DEF
		fileName 
	}
	
	def generateTranslationKeysForEntities() {
		val fileName = getDefaultTranslationFileName
		generateFile(fileName, doGenerateTranslationKeysForEntities)
	}
	
	def generateTranslationService() {
		val path = service.webServiceI18nPath
		val fileName = path + service.toTranslationServiceName + '.ts'
		generateFile(fileName, doGenerateTranslationService)
	}
	
	def CharSequence doGenerateTranslationKeysForEntities() {
		val List<String> keys = newArrayList
		entities.forEach[it.generateTranslationKeysForEntity(keys)]
		
		'''
		{
			«keys.map[it].join(',\r\n')»
		}
		'''
	}
	
	def void generateTranslationKeysForEntity(Entity entity, List<String> keys) {
		keys.add('"' + entity.translationKey + '": "' + entity.labelValue + '"')
		entity.slots.forEach[
			val key = it.translationKey
			keys.add('"' + key + '": "' + it.labelValue + '"')
			
			val keyGrid = it.translationKeyGrid
			keys.add('"' + keyGrid + '": "' + it.getLabelGridValue + '"')
			
			// Trata as chaves de enumeração.
			if (it.isEnum) {
				val enumerarion = it.asEnum
				enumerarion.items.forEach[ enumItem |
					val enumKey = key + '_' + enumItem.name.toLowerCase
					val enumValue = enumItem.valueStr ?: it.name
					keys.add('"' + enumKey + '": "' + enumValue + '"')
				]
			}
		]
	}
	
	def CharSequence doGenerateTranslationService() {
		val fileName = getDefaultTranslationFileName.replace('web/src-gen', 'src')
		
		'''
		import { HttpClientWithToken } from './../../../security/http-client-token';
		import { Injectable } from '@angular/core';
		
		@Injectable()
		export class «service.toTranslationServiceClassName» {
		
		  translations: Object;
		
		  constructor(private http: HttpClientWithToken) {
		    this.loadTranslations();
		  }
		
		  loadTranslations() {
		    this.http.get('«fileName»')
		    .toPromise()
		    .then(response => {
		      this.translations = response;
		    })
		    .catch(error => {
		      console.log(`Error loading translations: ${error}`);
		    });
		  }
		
		  public getTranslation(key: string): string {
		    const translation = this.translations[key];
		    if (translation) {
		      return translation;
		    }
		    return key;
		  }
		
		}
		'''
	}
	
}