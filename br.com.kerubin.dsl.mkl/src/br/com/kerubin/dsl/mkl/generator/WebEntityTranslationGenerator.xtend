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
		generateDefaultTranslationKeysForEntities
		generateDefaultTranslationModule
		generateTranslationService
	}
	
	def getDefaultTranslationFileName() {
		val path = service.webServiceI18nPath
		val fileName = path + I18N_DEF
		fileName 
	}
	
	def generateDefaultTranslationKeysForEntities() {
		val fileName = getDefaultTranslationFileName
		generateFile(fileName, doGenerateTranslationKeysForEntities)
	}
	
	def generateDefaultTranslationModule() {
		val fileName = getDefaultTranslationFileName + '.ts'
		generateFile(fileName, doGenerateDefaultTranslationModule)
	}
	
	def doGenerateDefaultTranslationModule() {
		'''
		export default '';
		'''
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
			«keys.map[mountKey].join(',\r')»
		}
		'''
	}
	
	def mountKey(String value) {
		'''«value»'''
	}
	
	/*def CharSequence doGenerateTranslationKeysForEntities() {
		val List<String> keys = newArrayList
		entities.forEach[it.generateTranslationKeysForEntity(keys)]
		
		'''
		[
			«keys.map[mountKey].join(',\r')»
		]
		'''
	}
	
	def mountKey(String value) {
		'''{«value»}'''
	}*/
	
	def void generateTranslationKeysForEntity(Entity entity, List<String> keys) {
		keys.add('"' + entity.translationKey + '": "' + entity.labelValue + '"')
		entity.slots.filter[!mapped].forEach[
			val key = it.translationKey
			keys.add('"' + key + '": "' + it.labelValue + '"')
			
			val keyGrid = it.translationKeyGrid
			keys.add('"' + keyGrid + '": "' + it.getLabelGridValue + '"')
			
			// Trata as chaves de enumeração.
			if (it.isEnum) {
				val enumerarion = it.asEnum
				enumerarion.items.forEach[ enumItem |
					val enumKey = key + '_' + enumItem.name.toLowerCase
                    val enumValue = if (enumItem.hasLabel) enumItem.label else enumItem.name
                    keys.add('"' + enumKey + '": "' + enumValue + '"')
				]
				if (it.optional) { // Enum opcional, precisa gerar um item para a opção null
					val enumKey = key + '_' + 'null'
					val enumValue = ''
					keys.add('"' + enumKey + '": "' + enumValue + '"')
				}
			}
		]
		
		
	}
	
	def CharSequence doGenerateTranslationService() {
		val fileName = getDefaultTranslationFileName.replace('web/src-gen', 'src')
		
		'''
		import { Injectable } from '@angular/core';
		import * as localTranslations from '«fileName»';
		
		@Injectable()
		export class «service.toTranslationServiceClassName» {
		
		  constructor() { }
		
		  public getTranslation(key: string): string {
		      if (localTranslations) {
		        const translation = (<any>localTranslations).default[key];
		        if (translation !== null) {
		          return translation;
		        }
		      }
		      return key;
		  }
		  
		  «getCalendarLocaleSettingsMethodName»(): any {
		      const pt: any = {
		        firstDayOfWeek: 0,
		        dayNames: ['Domingo', 'Segunda', 'Terça', 'Quarta', 'Quinta', 'Sexta', 'Sábado'],
		        dayNamesShort: ['Dom', 'Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sab'],
		        dayNamesMin: ['Do', 'Se', 'Te', 'Qu', 'Qu', 'Se', 'Sa'],
		        monthNames: ['Janeiro', 'Fevereiro', 'Março', 'Abril', 'Maio', 'Junho', 'Julho',
		          'Agosto', 'Setembro', 'Outubro', 'Novembro', 'Dezembro'],
		        monthNamesShort: ['Jan', 'Fev', 'Mar', 'Abr', 'Mai', 'Jun', 'Jul', 'Ago', 'Set', 'Out', 'Nov', 'Dez'],
		        today: 'Hoje',
		        clear: 'Limpar'
		      };
		  
		      return pt;
		    }
		
		}
		'''
	}
	
}