package br.com.kerubin.dsl.mkl.generator

import br.com.kerubin.dsl.mkl.model.Entity

import static extension br.com.kerubin.dsl.mkl.generator.EntityUtils.*

class WebEntityCRUDComponentCSSGenerator extends GeneratorExecutor implements IGeneratorExecutor {
	
	new(BaseGenerator baseGenerator) {
		super(baseGenerator)
	}
	
	override generate() {
		generateFiles
	}
	
	def generateFiles() {
		entities.forEach[generateComponent]
	}
	
	def generateComponent(Entity entity) {
		val path = entity.getWebEntityPath
		val entityFile = path + entity.toEntityWebCRUDComponentName + '.css'
		generateFile(entityFile, entity.doGenerateEntityCssComponent)
	}
	
	def CharSequence doGenerateEntityCssComponent(Entity entity) {
		'''
		/* Write your CSS here. */
		
		'''
	}
	
}