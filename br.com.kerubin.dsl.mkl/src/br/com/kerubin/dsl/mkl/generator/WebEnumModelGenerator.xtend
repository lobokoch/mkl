package br.com.kerubin.dsl.mkl.generator

import br.com.kerubin.dsl.mkl.model.Enumeration

import static extension br.com.kerubin.dsl.mkl.generator.EntityUtils.*

class WebEnumModelGenerator extends GeneratorExecutor implements IGeneratorExecutor {
	
	new(BaseGenerator baseGenerator) {
		super(baseGenerator)
	}
	
	override generate() {
		generateFiles
	}
	
	def generateFiles() {
		generateEnums
	}
	
	def generateEnums() {
		val path = service.webServiceEnumPath
		val fileName = path + service.toEnumModelName + '.ts'
		generateFile(fileName, doGenerateEnumModel)
	}
	
	
	def CharSequence doGenerateEnumModel() {
		'''
		«enums.map[it.generateEnum].join»
		'''		
	}
	
	def CharSequence generateEnum(Enumeration enumeration) {
		'''
		export interface «enumeration.toDtoName» {
			
		  label: string;
		  value: string;
		  
		}
		
		'''
	}
	
}